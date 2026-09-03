#!/usr/bin/env python3
"""
Purpose: THROWAWAY P0 spike probe -- the EXTERNAL observer that distinguishes a dead hook
         from a live but ignored one. It exists for exactly one reason: KILLED and
         ABANDONED are different findings, and the hook cannot report its own death.

         It watches the run log for that run's `proc: hook` / `event: start` line, takes
         the pid from it, then samples that pid's liveness on the same cadence the hook
         beats on, appending `probe` lines to the same file. The thing being measured must
         not be the thing doing the measuring.

         Deleted when the spike closes. Do not import, copy, or depend on this file.

Usage:   spike_probe.py --run <run id> [--log PATH] [--interval-ms 250]
                        [--arm-timeout 900]

         Run it BEFORE arming the host, in its own terminal. It waits for the hook's start
         line, so the order within a few seconds does not matter.

Exit codes:
         0  the watched pid died, or the run ended
         1  runtime failure (log unwritable)
         2  usage error
         3  gave up waiting for the hook's start line (--arm-timeout exceeded)

         --arm-timeout is generous on purpose. Arming spans a human registering a hook in a
         host tool's UI and then prompting a session, which does not fit in a minute; the
         original 60 s default meant the probe expired before the hook could ever fire, and
         the run failed for a reason that had nothing to do with the host. Waiting costs
         nothing here -- an unarmed probe only watches.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
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
EXIT_NO_HOOK = 3

TERMINAL_EVENTS = {"end", "killed", "abandoned"}

_t0 = time.monotonic()


def _emit(sink: TextIO, run: str, event: str, **fields: Any) -> None:
    line = {
        "ts_wall": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "t_mono": round(time.monotonic() - _t0, 6),
        "run": run,
        "proc": "probe",
        "machine": os.environ.get("SPIKE_MACHINE", "A"),
        "pid": os.getpid(),
        "event": event,
    }
    line.update(fields)
    sink.write(json.dumps(line, ensure_ascii=False) + "\n")
    sink.flush()


def _pid_alive_posix(pid: int) -> bool:
    """POSIX: signal 0 checks existence and permission and is never delivered.

    A zombie still answers yes, which is correct here -- the distinction that matters is
    "the host killed it" versus "the host left it running and ignored it", and a zombie is
    neither.
    """
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # exists, owned by someone else
    except OSError:
        return False
    return True


def _pid_alive_windows(pid: int) -> bool:
    """Windows: OpenProcess + GetExitCodeProcess. NEVER os.kill.

    This function exists because `os.kill(pid, 0)` is NOT a liveness probe on Windows. CPython
    has no signal concept there: for any sig other than CTRL_C_EVENT / CTRL_BREAK_EVENT it opens
    the process and calls TerminateProcess(handle, sig). So `os.kill(pid, 0)` KILLS the target
    with exit code 0 -- the probe would have terminated the hook at its first sample, 250 ms in,
    and the run log would have read KILLED(0.25): the probe killing the very process it exists to
    observe, recorded as the host doing it. A wrong number that looks entirely plausible.

    PROCESS_QUERY_LIMITED_INFORMATION (0x1000) is used rather than PROCESS_QUERY_INFORMATION
    because it is granted across integrity levels, so the probe can watch a hook the host spawned
    without needing to be elevated.
    """
    import ctypes
    from ctypes import wintypes

    STILL_ACTIVE = 259
    PROCESS_QUERY_LIMITED_INFORMATION = 0x1000

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
    if not handle:
        return False  # gone, or never existed
    try:
        code = wintypes.DWORD()
        if not kernel32.GetExitCodeProcess(handle, ctypes.byref(code)):
            return False
        return code.value == STILL_ACTIVE
    finally:
        kernel32.CloseHandle(handle)


def _pid_alive(pid: int) -> bool:
    if sys.platform == "win32":
        return _pid_alive_windows(pid)
    return _pid_alive_posix(pid)


def _scan_for_hook_start(path: Path, run: str) -> tuple[int, float] | None:
    """Return (pid, d) from that run's hook start line, or None if not present yet."""
    if not path.exists():
        return None
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    rec = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                if rec.get("run") == run and rec.get("proc") == "hook" and rec.get("event") == "start":
                    pid = rec.get("pid")
                    if isinstance(pid, int):
                        return pid, float(rec.get("d") or 0.0)
    except OSError:
        return None
    return None


def _run_ended(path: Path, run: str) -> str | None:
    """Return the terminal event name if this run already has one, else None."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    rec = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                if (rec.get("run") == run and rec.get("proc") == "hook"
                        and rec.get("event") in TERMINAL_EVENTS):
                    return str(rec["event"])
    except OSError:
        return None
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="THROWAWAY P0 spike probe.")
    ap.add_argument("--run", required=True, help="which run to watch, e.g. T3-060-b")
    ap.add_argument("--log", default=None,
                    help="NDJSON log path (default throwaway/logs/<run>.ndjson -- the same "
                         "file the hook resolves for that run)")
    ap.add_argument("--interval-ms", type=int, default=250,
                    help="sampling cadence in milliseconds (default 250, matching the hook's beat)")
    ap.add_argument("--arm-timeout", type=float, default=900.0,
                    help="seconds to wait for the hook's start line before giving up (default 60)")
    args = ap.parse_args()

    if args.interval_ms < 10:
        print(f"error: --interval-ms too small: {args.interval_ms}", file=sys.stderr)
        return EXIT_USAGE

    log_path = Path(args.log) if args.log else _LOG_DIR / f"{args.run}.ndjson"
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        sink = log_path.open("a", encoding="utf-8")
    except OSError as exc:
        print(f"error: cannot open log {log_path}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME

    interval = args.interval_ms / 1000.0
    try:
        _emit(sink, args.run, "start",
              note=f"watching for hook start; interval_ms={args.interval_ms} log={log_path}")
        print(f"probe waiting for run {args.run}'s hook start line in {log_path} ...")

        deadline = time.monotonic() + args.arm_timeout
        found: tuple[int, float] | None = None
        while time.monotonic() < deadline:
            found = _scan_for_hook_start(log_path, args.run)
            if found:
                break
            time.sleep(interval)

        if not found:
            _emit(sink, args.run, "void",
                  note=f"no hook start line for this run within {args.arm_timeout}s")
            print(f"error: no hook start line for run {args.run} within {args.arm_timeout}s",
                  file=sys.stderr)
            return EXIT_NO_HOOK

        pid, d = found
        _emit(sink, args.run, "probe", pid_watched=pid, d=d, alive=True,
              note=f"acquired hook pid {pid}")
        print(f"probe watching pid {pid} (D={d}s) every {args.interval_ms}ms")

        # Sample until the pid goes, or the hook writes its own terminal line. Both exits
        # are normal; which one happened is what separates KILLED from SURVIVED/ABANDONED.
        while True:
            alive = _pid_alive(pid)
            _emit(sink, args.run, "probe", pid_watched=pid, d=d, alive=alive)
            if not alive:
                _emit(sink, args.run, "end", pid_watched=pid, d=d,
                      note=f"watched pid {pid} is gone")
                print(f"pid {pid} gone at t_mono={round(time.monotonic() - _t0, 3)}s")
                return EXIT_OK
            ended = _run_ended(log_path, args.run)
            if ended:
                _emit(sink, args.run, "end", pid_watched=pid, d=d,
                      note=f"hook wrote terminal event {ended!r} while pid still alive")
                print(f"hook ended ({ended}) with pid {pid} still alive")
                return EXIT_OK
            time.sleep(interval)
    except KeyboardInterrupt:
        _emit(sink, args.run, "void", note="probe interrupted by operator")
        return EXIT_OK
    finally:
        sink.close()


if __name__ == "__main__":
    sys.exit(main())
