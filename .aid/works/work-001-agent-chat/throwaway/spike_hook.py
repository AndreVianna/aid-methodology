#!/usr/bin/env python3
"""
Purpose: THROWAWAY P0 spike hook -- the process whose blocking budget is being measured,
         and the act the woken turn performs. One file serves both hosts and both roles.

         What is measured is NOT "how long the process lives" but how long a host lets a
         hook block AND STILL HONOURS its continuation. A hook that survives 300 s whose
         message the host then ignores is worth exactly what one killed at 5 s is worth,
         which is why ABANDONED is a distinct outcome from KILLED.

         The block is a real socket read against the stub -- never `sleep`. Some hosts time
         out on silence rather than on runtime, and `sleep` would not exercise that. The
         stub is asked for `--after` = D + 30 so it can never return first, and the client
         deadline of D is what makes an unmolested hook return under its own power at
         exactly D.

         Invoke as an absolute interpreter path plus an absolute script path, with NO shell
         wrapper: the process the host spawns must be the process being measured, or the
         interpreter becomes an orphaned grandchild and "still alive" is unreadable.

         Deleted when the spike closes. Do not import, copy, or depend on this file.

Usage:   spike_hook.py --host claude|cursor --run <run id> [--url URL] [--after N]
                       [--deadline D] [--log PATH]
         spike_hook.py --act <run id> [--url URL] [--log PATH]

         --deadline D  the target block duration in seconds; the measurement's D
         --after N     what to ask the stub to wait (default: deadline + 30)
         --act <run>   perform the woken turn's single request and exit

Exit codes:
         0  the block completed on its own power (SURVIVED), or the act succeeded
         1  runtime failure (stub unreachable, log unwritable)
         2  usage error
"""
from __future__ import annotations

import argparse
import json
import os
import signal
import sys
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from types import FrameType
from typing import Any, TextIO

EXIT_OK = 0
EXIT_RUNTIME = 1
EXIT_USAGE = 2

# The default log directory is resolved from THIS FILE's location, not from the working
# directory. The scripts live in throwaway/, so the default is always throwaway/logs/
# however the host invokes them -- and a host spawning a hook does not promise any
# particular cwd. Resolving from cwd created a nested throwaway/throwaway/ the first time
# the scripts were run from inside their own directory.
_LOG_DIR = Path(__file__).resolve().parent / "logs"

BEAT_INTERVAL_S = 0.25

_t0 = time.monotonic()
_log_lock = threading.Lock()
_sink: TextIO | None = None
_run = ""
_deadline = 0.0
_terminal_written = threading.Event()


def _elapsed() -> float:
    return round(time.monotonic() - _t0, 6)


def _emit(event: str, **fields: Any) -> None:
    if _sink is None:
        return
    line = {
        "ts_wall": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "t_mono": _elapsed(),
        "run": _run,
        "proc": "hook",
        "machine": os.environ.get("SPIKE_MACHINE", "A"),
        "pid": os.getpid(),
        "event": event,
    }
    line.update(fields)
    with _log_lock:
        _sink.write(json.dumps(line, ensure_ascii=False) + "\n")
        _sink.flush()


def _on_signal(signum: int, _frame: FrameType | None) -> None:
    """POSIX only: record the kill instant exactly, from inside the process being timed.

    On Windows a terminated process gets no chance to write, so the last `beat` bounds the
    kill to within BEAT_INTERVAL_S and the reported number carries that resolution.
    """
    if not _terminal_written.is_set():
        _terminal_written.set()
        _emit("killed", d=_deadline, signal=signum,
              note=f"signal {signal.Signals(signum).name if signum in signal.Signals.__members__.values() else signum}")
    os._exit(EXIT_OK)


def _install_signal_handlers() -> None:
    for name in ("SIGTERM", "SIGINT", "SIGHUP"):
        sig = getattr(signal, name, None)
        if sig is None:
            continue  # Windows has no SIGHUP
        try:
            signal.signal(sig, _on_signal)
        except (ValueError, OSError):
            pass


def _block(url: str, after: int, deadline: float) -> tuple[bool, str]:
    """Block on a real socket read. Returns (returned_under_own_power, note)."""
    result: dict[str, Any] = {}

    def _request() -> None:
        full = f"{url}?after={after}&run={_run}&text=wake"
        try:
            with urllib.request.urlopen(full, timeout=deadline) as resp:
                result["body"] = resp.read().decode("utf-8", "replace")[:200]
        except urllib.error.URLError as exc:
            # A client-side timeout at `deadline` is the EXPECTED path: the stub was asked
            # for deadline+30, so it cannot have answered. That is the hook returning under
            # its own power, not a failure.
            result["err"] = str(exc)
        except Exception as exc:  # noqa: BLE001 -- the record wants whatever happened
            result["err"] = f"{type(exc).__name__}: {exc}"

    worker = threading.Thread(target=_request, daemon=True)
    worker.start()

    # Heartbeat from the main thread while the worker blocks, so a killed process's last
    # beat bounds the kill instant even where no signal is deliverable.
    next_beat = time.monotonic()
    while worker.is_alive():
        now = time.monotonic()
        if now >= next_beat:
            _emit("beat", d=deadline)
            next_beat = now + BEAT_INTERVAL_S
        time.sleep(min(0.05, BEAT_INTERVAL_S))
    worker.join(timeout=1.0)
    return ("err" in result, json.dumps(result)[:300])


def _act_command(run: str) -> str:
    """The exact command the woken turn must run, built from this process's own facts.

    sys.executable and __file__ are used rather than anything the operator types, so the
    command cannot pick up a PATH shim. On this spike's first target machine `python` on PATH
    was a pyenv-win python.bat, which would have made the act a grandchild of cmd.exe.

    Separators are normalised to forward slashes. Windows accepts them everywhere, and the host
    may well run this through bash -- Claude Code does on Windows, reporting /usr/bin/bash. Inside
    double quotes bash preserves a backslash, so the native form would survive intact; unquoted it
    would NOT, because bash eats each backslash and
    "C:\\Users\\a\\spike_hook.py" collapses to "C:Usersaspike_hook.py". That failure reads as a
    missing file rather than as a mangled path, so it is worth not depending on the agent
    reproducing the quoting exactly.
    """
    exe = str(sys.executable).replace("\\", "/")
    me = str(Path(__file__).resolve()).replace("\\", "/")
    return f'"{exe}" "{me}" --act {run}'


def _wake(schema: str, run: str) -> int:
    """Hand the host something that makes it run one more turn. Returns the process exit code.

    This is the whole wake. The hook blocking proves only that the host TOLERATED a long
    hook; it proves nothing about waking. The host has to be told to continue, and told what
    to do, or the turn never happens and no `act` is ever written -- which is indistinguishable
    in the log from a host that refused to wake.

    Two conventions are offered because the hosts document different ones and this spike exists
    partly to find out which each honours:
      claude -- JSON on stdout with decision=block; the documented Stop-hook shape, where
                `reason` is fed to the model instead of the turn ending.
      exit2  -- the instruction on stderr with exit status 2, the other documented convention
                for a hook that wants to interrupt and be heard.
      none   -- emit nothing, the control: any `act` under `none` means something OTHER than
                this payload woke the host, and the run is not evidence for the payload.
    """
    instruction = (
        "A message arrived on the chat channel. Do not stop yet. "
        "Run exactly this command, then stop:\n" + _act_command(run)
    )
    if schema == "none":
        _emit("wake", note="schema=none; nothing emitted (control)")
        return EXIT_OK
    if schema == "exit2":
        _emit("wake", note=f"schema=exit2; stderr+exit2; cmd={_act_command(run)}")
        print(instruction, file=sys.stderr)
        return 2
    payload = {"decision": "block", "reason": instruction}
    _emit("wake", note=f"schema=claude; stdout json; cmd={_act_command(run)}")
    print(json.dumps(payload))
    return EXIT_OK


def _act(url: str, run: str) -> int:
    """The woken turn's single request -- the machine-readable witness that a turn ran.

    `after=0` is the same code path as a wait that has expired, which is why the endpoint
    needs no separate `send`.
    """
    full = f"{url}?after=0&run={run}&text=act"
    try:
        with urllib.request.urlopen(full, timeout=30) as resp:
            body = resp.read().decode("utf-8", "replace")[:200]
    except Exception as exc:  # noqa: BLE001
        _emit("error", note=f"act failed: {type(exc).__name__}: {exc}")
        print(f"error: act request failed: {exc}", file=sys.stderr)
        return EXIT_RUNTIME
    _emit("act", note=body)
    print(body)
    return EXIT_OK


def main() -> int:
    global _sink, _run, _deadline

    ap = argparse.ArgumentParser(description="THROWAWAY P0 spike hook / act.")
    ap.add_argument("--host", choices=("claude", "cursor"),
                    help="which host arrangement this hook is registered in")
    ap.add_argument("--run", help="run id, e.g. T3-060-b; appears on every log line")
    ap.add_argument("--act", metavar="RUN",
                    help="perform the woken turn's single request for RUN and exit")
    ap.add_argument("--url", default="http://127.0.0.1:8811/wait",
                    help="stub endpoint (default http://127.0.0.1:8811/wait)")
    ap.add_argument("--after", type=int, default=None,
                    help="what to ask the stub to wait (default: deadline + 30)")
    ap.add_argument("--deadline", type=float, default=30.0,
                    help="target block duration D in seconds (default 30)")
    ap.add_argument("--wake-schema", choices=("claude", "exit2", "none"), default="claude",
                    help="how to ask the host for one more turn once the block ends "
                         "(default claude: JSON decision=block on stdout)")
    ap.add_argument("--log", default=None,
                    help="NDJSON log path (default throwaway/logs/<run>.ndjson)")
    args = ap.parse_args()

    run = args.act or args.run
    if not run:
        print("error: one of --run or --act is required", file=sys.stderr)
        return EXIT_USAGE
    if not args.act and not args.host:
        print("error: --host is required when blocking (omit only with --act)", file=sys.stderr)
        return EXIT_USAGE
    if args.deadline <= 0:
        print(f"error: --deadline must be positive: {args.deadline}", file=sys.stderr)
        return EXIT_USAGE

    _run = run
    log_path = Path(args.log) if args.log else _LOG_DIR / f"{run}.ndjson"
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        _sink = log_path.open("a", encoding="utf-8")
    except OSError as exc:
        print(f"error: cannot open log {log_path}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME

    try:
        if args.act:
            return _act(args.url, run)

        # Arm once per run. Without the sentinel a host that fires its stop hook again
        # after the woken turn would start a second block and silently corrupt the run.
        armed = log_path.parent / f"{run}.armed"
        try:
            fd = os.open(str(armed), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            _emit("void", d=args.deadline, note="already armed for this run; not re-blocking")
            print(f"already armed for run {run}; not re-blocking", file=sys.stderr)
            return EXIT_OK
        with os.fdopen(fd, "w") as fh:
            fh.write(f"{os.getpid()}\n")

        _deadline = args.deadline
        after = args.after if args.after is not None else int(args.deadline) + 30
        _install_signal_handlers()

        _emit("start", d=args.deadline,
              note=f"host={args.host} url={args.url} after={after} "
                   f"python={sys.version.split()[0]} platform={sys.platform}")

        own_power, note = _block(args.url, after, args.deadline)

        if not _terminal_written.is_set():
            _terminal_written.set()
            if own_power:
                # Returned at D on its own. Whether this is SURVIVED or ABANDONED is not
                # this process's call -- it depends on whether an act follows within 120 s,
                # which only the stub's log can show. The classification is made when the
                # record is written, from both logs.
                _emit("end", d=args.deadline, note=f"returned under own power at deadline; {note}")
                # Blocking is not waking. The host must now be told to run a turn, or no act
                # can ever be written and ABANDONED becomes unfalsifiable.
                return _wake(args.wake_schema, run)
            else:
                _emit("error", d=args.deadline,
                      note=f"stub answered before the deadline -- run is VOID; {note}")
                print("VOID: the stub returned before the client deadline", file=sys.stderr)
        return EXIT_OK
    finally:
        if _sink is not None:
            _sink.close()


if __name__ == "__main__":
    sys.exit(main())
