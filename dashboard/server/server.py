# dashboard/server/server.py
# Python thin server for the AID pipeline dashboard (feature-003, task-016).
#
# Stdlib-only. Binds 127.0.0.1 only -- never a wildcard or non-loopback address.
# Routes (closed allowlist):
#   GET /           -> static index.html from the assets dir sibling to server/
#   GET /api/model  -> read_repo(args.root) serialized as the DM-1 envelope
#   *               -> 404
#   non-GET         -> 405
#
# No write primitive anywhere in this file (NFR2).
# No agent/LLM import anywhere in this file (NFR7).
#
# Invocation (LC-1 spawn seam):
#   python3 server.py --root <repo-root> --host 127.0.0.1 --port <n>
#
# Python 3.11+ required. Zero third-party deps.

from __future__ import annotations

import argparse
import json
import signal
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# ---------------------------------------------------------------------------
# sys.path: add the dashboard/ parent so 'from reader import read_repo' works
# whether the server is run from any working directory.
# ---------------------------------------------------------------------------
_SERVER_DIR = Path(__file__).resolve().parent          # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                    # dashboard/
_ASSETS_DIR = _DASHBOARD_DIR                           # static assets live at dashboard/
_INDEX_HTML = _ASSETS_DIR / "index.html"

if str(_DASHBOARD_DIR) not in sys.path:
    sys.path.insert(0, str(_DASHBOARD_DIR))

from reader import read_repo  # noqa: E402  (inserted sys.path above)


# ---------------------------------------------------------------------------
# Serialization (DM-1 envelope, DM-2/DM-3 field order and rules)
# ---------------------------------------------------------------------------

def _ser_tool_info(obj) -> dict:
    """Serialize ToolInfo in declared field order."""
    return {
        "manifest_present": obj.manifest_present,
        "aid_version":      obj.aid_version,
        "installed_at":     obj.installed_at,
        "tools_installed":  list(obj.tools_installed),
    }


def _ser_kb_state(obj) -> dict | None:
    """Serialize KbStateRef in declared field order, or None if absent."""
    if obj is None:
        return None
    return {
        "summary_approved":  obj.summary_approved,
        "last_summary_date": obj.last_summary_date,
        "doc_count":         obj.doc_count,
    }


def _ser_repo_info(obj) -> dict:
    """Serialize RepoInfo in declared field order."""
    return {
        "project_name": obj.project_name,
        "aid_dir":      obj.aid_dir,
        "kb_state":     _ser_kb_state(obj.kb_state),
    }


def _ser_task(obj) -> dict:
    """Serialize TaskModel in declared field order."""
    return {
        "task_id":      obj.task_id,
        "type":         obj.type,
        "wave":         obj.wave,
        "status":       obj.status.value,
        "review_grade": obj.review_grade,
        "elapsed":      obj.elapsed,
        "notes":        obj.notes,
    }


def _ser_pending_input(obj) -> dict:
    """Serialize PendingInput in declared field order."""
    return {
        "question_id": obj.question_id,
        "category":    obj.category,
        "impact":      obj.impact,
        "context":     obj.context,
        "suggested":   obj.suggested,
    }


def _ser_work(obj) -> dict:
    """Serialize WorkModel in declared field order."""
    return {
        "work_id":       obj.work_id,
        "name":          obj.name,
        "lifecycle":     obj.lifecycle.value,
        "phase":         obj.phase.value if obj.phase is not None else None,
        "active_skill":  obj.active_skill,
        "updated":       obj.updated,
        "pause_reason":  obj.pause_reason,
        "block_reason":  obj.block_reason,
        "block_artifact": obj.block_artifact,
        "tasks":         [_ser_task(t) for t in obj.tasks],
        "pending_inputs": [_ser_pending_input(p) for p in obj.pending_inputs],
        "source_mode":   obj.source_mode.value,
    }


def _ser_read_meta(obj) -> dict:
    """Serialize ReadMeta in declared field order."""
    return {
        "read_at":        obj.read_at,
        "work_count":     obj.work_count,
        "fallback_works": list(obj.fallback_works),
        "parse_warnings": list(obj.parse_warnings),
        "bytes_read":     obj.bytes_read,
    }


def _ser_repo_model(obj) -> dict:
    """Serialize RepoModel in declared field order; works sorted by work_id (DM-3)."""
    return {
        "tool":  _ser_tool_info(obj.tool),
        "repo":  _ser_repo_info(obj.repo),
        "works": [_ser_work(w) for w in sorted(obj.works, key=lambda w: w.work_id)],
        "read":  _ser_read_meta(obj.read),
    }


def serialize_model(model) -> bytes:
    """Serialize a RepoModel to the DM-1 envelope bytes.

    Compact, UTF-8, no trailing newline, no BOM.
    U+2028/U+2029 post-processed to the escaped canonical form so output is
    byte-identical to the Node server (which applies the same post-process).
    """
    envelope = {
        "schema_version": 1,
        "generated_by":   "python",
        "model":          _ser_repo_model(model),
    }
    raw = json.dumps(envelope, separators=(",", ":"), ensure_ascii=False)
    # DM-3 parity: neither Node JSON.stringify nor Python json.dumps(ensure_ascii=False)
    # escapes U+2028/U+2029 by default (both emit raw bytes). This post-process produces
    # the escaped canonical form both servers agree on (PT-1 / R7).
    raw = raw.replace('\u2028', '\\u2028').replace('\u2029', '\\u2029')
    return raw.encode("utf-8")


# ---------------------------------------------------------------------------
# HTTP handler
# ---------------------------------------------------------------------------

class _DashboardHandler(BaseHTTPRequestHandler):
    """Request handler for the AID dashboard server."""

    # suppress default per-request log noise on stdout; errors go to stderr
    def log_message(self, fmt, *args):  # type: ignore[override]
        pass

    def log_error(self, fmt, *args):  # type: ignore[override]
        sys.stderr.write("server error: " + (fmt % args) + "\n")

    # ---- routing -----------------------------------------------------------

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]  # strip query string

        if path == "/":
            self._serve_index()
        elif path == "/api/model":
            self._serve_model()
        else:
            self._send_plain(404, b"Not Found")

    def do_HEAD(self) -> None:  # noqa: N802
        # HEAD mirrors GET but with no body (browsers may issue HEAD for /api/model)
        path = self.path.split("?", 1)[0]
        if path in ("/", "/api/model"):
            self.send_response(200)
            self.end_headers()
        else:
            self._send_plain(404, b"Not Found")

    def do_POST(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_PUT(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_DELETE(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_PATCH(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    # ---- route handlers ----------------------------------------------------

    def _serve_index(self) -> None:
        if not _INDEX_HTML.is_file():
            self._send_plain(404, b"index.html not yet available (task-019 builds it)")
            return
        try:
            data = _INDEX_HTML.read_bytes()
        except OSError as exc:
            sys.stderr.write(f"server: index.html read error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _serve_model(self) -> None:
        try:
            model = read_repo(self.server.aid_root)  # type: ignore[attr-defined]
            body = serialize_model(model)
        except Exception as exc:
            sys.stderr.write(f"server: /api/model error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    # ---- helpers -----------------------------------------------------------

    def _send_plain(self, code: int, body: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

_LOOPBACK_HOSTS = {"127.0.0.1", "::1"}


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="server.py",
        description="AID pipeline dashboard thin server (feature-003).",
    )
    parser.add_argument("--root",  required=True, help="Repo root (contains .aid/)")
    parser.add_argument("--host",  required=True, help="Bind host (must be 127.0.0.1 or ::1)")
    parser.add_argument("--port",  required=True, type=int, help="TCP port 1024..65535")
    args = parser.parse_args(argv)

    # Validate host: reject any non-loopback value (LC-1 spawn seam, DM-3 invariant)
    if args.host not in _LOOPBACK_HOSTS:
        parser.error(
            f"--host must be a loopback address (127.0.0.1 or ::1); got: {args.host!r}"
        )

    # Validate port range
    if not (1024 <= args.port <= 65535):
        parser.error(f"--port must be in 1024..65535; got: {args.port}")

    return args


def main(argv: list[str] | None = None) -> None:
    args = _parse_args(argv)

    # Bind before any slow work (LC-1 readiness contract)
    server = ThreadingHTTPServer((args.host, args.port), _DashboardHandler)
    # Attach the repo root so the handler can reach it without a global
    server.aid_root = args.root  # type: ignore[attr-defined]

    # Clean exit on SIGTERM (LC-1 section 4 "clean exit on signal")
    def _handle_sigterm(signum, frame):  # noqa: ANN001
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGTERM, _handle_sigterm)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
