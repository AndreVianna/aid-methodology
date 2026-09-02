#!/usr/bin/env python3
"""
Purpose: THROWAWAY P0 spike stub -- one endpoint that waits, then answers. It is the
         arrival clock for every wake test: the caller chooses when the message arrives by
         choosing `after`, and the timer expiring IS the message being sent. There is no
         `send` operation and none is to be added -- a real send path belongs to Feature
         002, and building one here would produce the artifact most likely to be promoted.

         Deleted when the spike closes. Do not import, copy, or depend on this file.

Usage:   spike_stub_node.py [--port 8811] [--bind 127.0.0.1] [--max-wait 86400]
                            [--log throwaway/logs/stub-<port>.ndjson]

         GET /wait?after=<int seconds>&text=<str>&run=<run id>
           Sleeps `after` on the request's own thread, then responds 200 application/json
           with {"run", "text", "sent_at", "seq"}. Any other path is 404.

         For test 4, machine A binds 0.0.0.0 so one process serves the local waiter on
         loopback and the LAN peer on the routable address.

Exit codes:
         0  clean shutdown (SIGINT/SIGTERM)
         1  runtime failure -- including the port already being bound
         2  usage error
"""
from __future__ import annotations

import argparse
import json
import os
import socket
import sys
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, TextIO
from urllib.parse import parse_qs, urlparse

EXIT_OK = 0
EXIT_RUNTIME = 1
EXIT_USAGE = 2

# The default log directory is resolved from THIS FILE's location, not from the working
# directory. The scripts live in throwaway/, so the default is always throwaway/logs/
# however the host invokes them -- and a host spawning a hook does not promise any
# particular cwd. Resolving from cwd created a nested throwaway/throwaway/ the first time
# the scripts were run from inside their own directory.
_LOG_DIR = Path(__file__).resolve().parent / "logs"

# Per-process request counter. Starts at 1, increments once per request served, and resets
# when the stub restarts -- which is the point: a restarted stub shows as a counter going
# backwards rather than as a silent gap in the log.
_seq_lock = threading.Lock()
_seq = 0

_log_lock = threading.Lock()
_t0 = time.monotonic()


def _next_seq() -> int:
    global _seq
    with _seq_lock:
        _seq += 1
        return _seq


def _emit(sink: TextIO, event: str, run: str, **fields: Any) -> None:
    """Append one NDJSON line, flushed on write.

    fsync is deliberately not used: a process kill does not lose data already handed to
    the kernel, and syncing every line would perturb the thing being timed.
    """
    line = {
        "ts_wall": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "t_mono": round(time.monotonic() - _t0, 6),
        "run": run,
        "proc": "stub",
        "machine": os.environ.get("SPIKE_MACHINE", "A"),
        "pid": os.getpid(),
        "event": event,
    }
    line.update(fields)
    with _log_lock:
        sink.write(json.dumps(line, ensure_ascii=False) + "\n")
        sink.flush()


class _Handler(BaseHTTPRequestHandler):
    server_version = "spike-stub/0"
    sys_version = ""

    # Bound by main() before the server starts.
    log_sink: TextIO
    max_wait: int

    def do_GET(self) -> None:  # noqa: N802 -- BaseHTTPRequestHandler's contract
        parsed = urlparse(self.path)
        if parsed.path != "/wait":
            self._fail(404, "unknown path")
            return

        q = parse_qs(parsed.query)
        raw_after = q.get("after", ["0"])[0]
        text = q.get("text", [""])[0]
        # `run` is echoed rather than required. The spec's error list is exactly
        # {404 unknown path, 400 bad `after`}, so a missing run is not invented as a
        # third error here -- it logs and echoes as the empty string, which is visible in
        # the record rather than silently dropped.
        run = q.get("run", [""])[0]

        try:
            after = int(raw_after)
        except ValueError:
            self._fail(400, f"after is not an integer: {raw_after!r}", run=run)
            return
        if after < 0:
            self._fail(400, f"after is negative: {after}", run=run)
            return
        if after > self.max_wait:
            self._fail(400, f"after exceeds --max-wait {self.max_wait}: {after}", run=run)
            return

        seq = _next_seq()
        _emit(self.log_sink, "request", run, seq=seq, d=after,
              note=f"client={self.client_address[0]} text={text!r}")

        # The sleep is on this request's own thread, which is why the server is threading:
        # a single-threaded server would serialise the two waiters and fail test 4 for a
        # reason that has nothing to do with the wake.
        time.sleep(after)

        body = json.dumps({
            "run": run,
            "text": text,
            "sent_at": int(time.time() * 1000),
            "seq": seq,
        }).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        _emit(self.log_sink, "respond", run, seq=seq, d=after,
              note=f"client={self.client_address[0]}")

    def _fail(self, code: int, why: str, run: str = "") -> None:
        body = json.dumps({"error": why}).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        _emit(self.log_sink, "error", run, note=f"{code} {why}")

    def log_message(self, fmt: str, *args: Any) -> None:
        """Silence BaseHTTPRequestHandler's stderr chatter; the NDJSON log is the record."""
        return


def main() -> int:
    ap = argparse.ArgumentParser(description="THROWAWAY P0 spike stub node.")
    ap.add_argument("--port", type=int, default=8811,
                    help="listen port (default 8811 -- not 8787, the dashboard default, "
                         "and not 8799, which a documented local dashboard command uses)")
    ap.add_argument("--bind", default="127.0.0.1",
                    help="bind address (default 127.0.0.1; use 0.0.0.0 on machine A for test 4)")
    ap.add_argument("--max-wait", type=int, default=86400,
                    help="largest accepted `after` in seconds (default 86400)")
    ap.add_argument("--log", default=None,
                    help="NDJSON log path (default throwaway/logs/stub-<port>.ndjson)")
    args = ap.parse_args()

    if args.port < 1 or args.port > 65535:
        print(f"error: --port out of range: {args.port}", file=sys.stderr)
        return EXIT_USAGE
    if args.max_wait < 0:
        print(f"error: --max-wait must not be negative: {args.max_wait}", file=sys.stderr)
        return EXIT_USAGE

    log_path = Path(args.log) if args.log else _LOG_DIR / f"stub-{args.port}.ndjson"
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        sink = log_path.open("a", encoding="utf-8")
    except OSError as exc:
        print(f"error: cannot open log {log_path}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME

    _Handler.log_sink = sink
    _Handler.max_wait = args.max_wait

    # Fail loudly on a bound port. No fallback port: a stub that quietly moved would make
    # every run that targeted the original port a silent void.
    try:
        httpd = ThreadingHTTPServer((args.bind, args.port), _Handler)
    except OSError as exc:
        print(f"error: cannot bind {args.bind}:{args.port}: {exc}", file=sys.stderr)
        _emit(sink, "error", "", note=f"bind failed {args.bind}:{args.port}: {exc}")
        sink.close()
        return EXIT_RUNTIME

    httpd.daemon_threads = True
    _emit(sink, "start", "", note=f"bind={args.bind}:{args.port} max_wait={args.max_wait} "
                                  f"python={sys.version.split()[0]} host={socket.gethostname()}")
    print(f"spike stub listening on http://{args.bind}:{args.port}/wait  log={log_path}")
    print("  (THROWAWAY -- deleted when the spike closes)")
    try:
        httpd.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        _emit(sink, "end", "", note="shutdown")
        sink.close()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
