# dashboard/server/server.py
# Python multi-repo server for the AID dashboard (feature-010, delivery-008).
#
# Stdlib-only. Binds 127.0.0.1 only -- never a wildcard or non-loopback address (SEC-1).
#
# Routes (NEW closed allowlist -- replaces feature-003 two-route server):
#   GET /                       -> CLI-home index.html from $AID_HOME/dashboard/index.html
#   GET /api/home               -> build DM-2 model -> 200 JSON
#   GET /r/<id>/home.html       -> <repo(id)>/.aid/dashboard/home.html  (SEC-2 by construction)
#   GET /r/<id>/kb.html         -> <repo(id)>/.aid/dashboard/kb.html    (SEC-2 by construction)
#   GET /r/<id>/api/model       -> read_repo(repo(id)) -> DM-1 envelope
#   *                           -> 404
#   non-GET                     -> 405
#
# Registry: $AID_HOME/registry.yml line-scan; mtime+size-keyed id->path map cache (NFR4).
# No write/append/remove primitive anywhere (SEC-3).
# No agent/LLM import anywhere (SEC-4).
# CAN-1 site 3: stored path used verbatim (no realpath/resolve -- SEC-2/DD-5).
#
# Invocation:
#   python3 server.py --host 127.0.0.1 --port <n>
#
# AID_HOME resolution (env-or-self-locate):
#   1. AID_HOME environment variable if set and non-empty.
#   2. Self-locate: server.py -> server/ -> dashboard/ -> $AID_HOME.
#
# Python 3.11+ required. Zero third-party deps.

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import signal
import sys
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# ---------------------------------------------------------------------------
# sys.path: add dashboard/ parent so 'from reader import read_repo' works
# regardless of working directory.
# ---------------------------------------------------------------------------
_SERVER_DIR = Path(__file__).resolve().parent    # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent              # dashboard/

if str(_DASHBOARD_DIR) not in sys.path:
    sys.path.insert(0, str(_DASHBOARD_DIR))

from reader import read_repo  # noqa: E402  (inserted sys.path above)
from reader.parsers import _strip_yaml_inline_comment  # noqa: E402  (shared PF-6 rule)


# ---------------------------------------------------------------------------
# Registry line-scan (DD-REG-FMT / SS 5.2)
# ---------------------------------------------------------------------------

_ITEM = re.compile(r"^\s*-\s+(.*\S)\s*$")


def load_registry(reg_path: Path) -> tuple[list[str], list[str]]:
    """Return (repos, parse_warnings). Absent file -> ([], []). Never raises.

    CAN-1 site 3: paths returned verbatim as stored -- NO realpath/resolve (DD-5).
    """
    warnings: list[str] = []
    try:
        text = reg_path.read_text(encoding="utf-8", errors="surrogateescape")
    except FileNotFoundError:
        return [], []   # absent == empty (NFR10)
    except OSError as exc:
        return [], [f"registry unreadable ({exc}); empty best-effort"]
    repos: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("schema:"):
            val = stripped.split(":", 1)[1].strip()
            if val.isdigit() and int(val) > 1:
                warnings.append(
                    f"registry schema {val} newer than reader (expected 1); read best-effort"
                )
            continue
        if stripped == "repos:" or stripped.startswith("repos:"):
            continue
        m = _ITEM.match(line)
        if m:
            # CAN-1 site 3: verbatim stored path (no normalization, no realpath)
            repos.append(m.group(1))
    return repos, warnings


# ---------------------------------------------------------------------------
# DD-1 id derivation (sha256(CAN-1(path))[:8], collision-lengthen)
# ---------------------------------------------------------------------------

def repo_id(canon_path: str) -> str:
    """Derive the full sha256 hex for a stored CAN-1 path (no trailing newline)."""
    return hashlib.sha256(canon_path.encode("utf-8")).hexdigest()


def build_id_map(repos: list[str]) -> dict[str, str]:
    """Build {id -> canon_path} map with collision-lengthen (DD-1 SS 3.5).

    Each id starts as the first 8 hex chars of sha256(CAN-1(path)).
    If two paths share the 8-char prefix, we lengthen all colliders to the
    shortest prefix L > 8 at which every member of the group is distinct.
    """
    # Compute full digests for all paths.
    full_digests = {path: repo_id(path) for path in repos}

    # Assign 8-char ids.
    assignments: dict[str, str] = {}  # id -> path (first pass, may have collisions)
    for path, digest in full_digests.items():
        assignments.setdefault(digest[:8], path)

    # Find collision groups.
    prefix_to_paths: dict[str, list[str]] = {}
    for path, digest in full_digests.items():
        prefix_to_paths.setdefault(digest[:8], []).append(path)

    result: dict[str, str] = {}
    for prefix8, paths in prefix_to_paths.items():
        if len(paths) == 1:
            result[prefix8] = paths[0]
        else:
            # Collision: lengthen to shortest unique prefix L > 8.
            for L in range(9, 65):
                prefixes = [full_digests[p][:L] for p in paths]
                if len(set(prefixes)) == len(paths):
                    for p in paths:
                        result[full_digests[p][:L]] = p
                    break
    return result


# ---------------------------------------------------------------------------
# mtime+size-keyed registry cache (NFR4 / DD-1 SS 3.4)
# ---------------------------------------------------------------------------

_cache_key: tuple | None = None          # (mtime_ns, size)
_cache_id_map: dict[str, str] = {}       # id -> canon_path
_cache_warnings: list[str] = []
_cache_lock = threading.Lock()


def _get_id_map(reg_path: Path) -> tuple[dict[str, str], list[str]]:
    """Return (id_map, warnings), rebuilding only when registry mtime+size changes."""
    global _cache_key, _cache_id_map, _cache_warnings

    # One stat per request (O(1)).
    try:
        st = reg_path.stat()
        key = (st.st_mtime_ns, st.st_size)
    except FileNotFoundError:
        key = None   # absent == empty

    with _cache_lock:
        if key == _cache_key:
            return _cache_id_map, _cache_warnings
        # Rebuild.
        if key is None:
            _cache_id_map = {}
            _cache_warnings = []
        else:
            repos, warnings = load_registry(reg_path)
            _cache_id_map = build_id_map(repos)
            _cache_warnings = warnings
        _cache_key = key
        return _cache_id_map, list(_cache_warnings)


# ---------------------------------------------------------------------------
# Route parse (DD-1 SS 3.3 -- CRITICAL: use \A..\Z, NOT ^..$)
# ---------------------------------------------------------------------------

# CRITICAL: Python's $ also matches just before a trailing '\n', so use \Z.
_R = re.compile(r"\A/r/([0-9a-f]{8,})/(home\.html|kb\.html|api/model)\Z")

_LEAF_ALLOWLIST = frozenset({"home.html", "kb.html"})


# ---------------------------------------------------------------------------
# /api/home builder (DM-2)
# ---------------------------------------------------------------------------

def _read_settings(repo_path: str) -> tuple[str | None, str | None]:
    """Read name/description from <repo>/.aid/settings.yml; tolerant parse."""
    try:
        settings = (Path(repo_path) / ".aid" / "settings.yml").read_text(
            encoding="utf-8", errors="surrogateescape"
        )
        name: str | None = None
        description: str | None = None
        in_project = False
        for line in settings.splitlines():
            stripped = line.strip()
            if stripped == "project:" or stripped.startswith("project:"):
                in_project = True
                continue
            if in_project:
                if stripped.startswith("name:"):
                    val = _strip_yaml_inline_comment(stripped[len("name:"):]).strip().strip('"').strip("'")
                    name = val if val else None
                elif stripped.startswith("description:"):
                    val = _strip_yaml_inline_comment(stripped[len("description:"):]).strip().strip('"').strip("'")
                    description = val if val else None
                elif stripped and not stripped.startswith("#") and not line.startswith(" "):
                    in_project = False
        return name, description
    except Exception:
        return None, None


def _read_manifest(repo_path: str) -> tuple[str | None, list[str]]:
    """Read aid_version/tools from <repo>/.aid/.aid-manifest.json; tolerant parse."""
    try:
        data = json.loads(
            (Path(repo_path) / ".aid" / ".aid-manifest.json").read_bytes()
        )
        aid_version = data.get("aid_version")
        if isinstance(aid_version, str):
            aid_version = aid_version.strip() or None
        else:
            aid_version = None
        tools_raw = data.get("tools", {})
        tools_installed = sorted(tools_raw.keys()) if isinstance(tools_raw, dict) else []
        return aid_version, tools_installed
    except Exception:
        return None, []


def _read_aid_version(aid_home: str) -> str | None:
    """Read $AID_HOME/VERSION (trimmed). None if absent."""
    try:
        return (Path(aid_home) / "VERSION").read_text(encoding="utf-8").strip() or None
    except Exception:
        return None


def _tools_catalog(aid_home: str) -> list[str]:
    """Read manageable-tool catalog from $AID_HOME (best-effort)."""
    # Aid's manageable tools: well-known fixed list (claude-code, codex, cursor).
    # The catalog is the set of tools aid add knows how to install; we read it
    # from the install tree if a catalog file is present, else fall back to the
    # static known list.
    catalog_path = Path(aid_home) / "lib" / "tools-catalog.txt"
    if catalog_path.is_file():
        try:
            lines = catalog_path.read_text(encoding="utf-8").splitlines()
            return [l.strip() for l in lines if l.strip() and not l.strip().startswith("#")]
        except Exception:
            pass
    # Static fallback -- the known aid-manageable tools.
    return ["claude-code", "codex", "cursor"]


def build_home_model(
    aid_home: str,
    reg_path: Path,
    id_map: dict[str, str],
    warnings: list[str],
    runtime: str,
) -> dict:
    """Build the DM-2 /api/home model. Never raises (NFR10)."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    unavailable = 0

    # Build unsorted first, then sort by path (PT-1 determinism).
    repo_entries: list[dict] = []
    for rid, canon_path in id_map.items():
        try:
            aid_dir = Path(canon_path) / ".aid"
            available = aid_dir.is_dir()
        except Exception:
            available = False

        entry: dict = {
            "path":           canon_path,
            "id":             rid,
            "available":      available,
            "name":           None,
            "description":    None,
            "aid_version":    None,
            "tools_installed": [],
            "has_home":       False,
            "has_kb":         False,
        }

        if available:
            try:
                entry["name"], entry["description"] = _read_settings(canon_path)
            except Exception:
                pass
            try:
                entry["aid_version"], entry["tools_installed"] = _read_manifest(canon_path)
            except Exception:
                pass
            try:
                entry["has_home"] = (aid_dir / "dashboard" / "home.html").is_file()
            except Exception:
                pass
            try:
                entry["has_kb"] = (aid_dir / "dashboard" / "kb.html").is_file()
            except Exception:
                pass

            # Folder-basename fallback for name.
            if not entry["name"]:
                try:
                    entry["name"] = Path(canon_path).name or None
                except Exception:
                    pass
        else:
            unavailable += 1

        repo_entries.append(entry)

    # Sort by path ascending (PT-1 determinism).
    repo_entries.sort(key=lambda e: e["path"])

    model: dict = {
        "schema_version": 1,
        "generated_by":   runtime,
        "machine": {
            "aid_version":    _read_aid_version(aid_home),
            "aid_home":       aid_home,
            "tools_catalog":  _tools_catalog(aid_home),
            "registry_path":  str(reg_path),
            "cli_runtime":    runtime,
        },
        "repos": repo_entries,
        "read": {
            "read_at":          now,
            "repo_count":       len(repo_entries),
            "unavailable_count": unavailable,
            "parse_warnings":   warnings,
        },
    }
    return model


# ---------------------------------------------------------------------------
# Serialization (DM-3 -- identical to feature-003 for both /api/home and /api/model)
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
    """Serialize TaskModel in declared field order (schema_version 3)."""
    return {
        "task_id":      obj.task_id,
        "type":         obj.type,
        "wave":         obj.wave,
        "status":       obj.status.value,
        "review_grade": obj.review_grade,
        "elapsed":      obj.elapsed,
        "notes":        obj.notes,
        "short_name":   obj.short_name,
        "delivery":     obj.delivery,
        "lane":         obj.lane,
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


def _ser_feature_ref(obj) -> dict:
    """Serialize FeatureRef in declared field order."""
    return {
        "number": obj.number,
        "name":   obj.name,
    }


def _ser_deliverable_ref(obj) -> dict:
    """Serialize DeliverableRef in declared field order."""
    return {
        "number":     obj.number,
        "name":       obj.name,
        "task_count": obj.task_count,
    }


def _ser_work(obj) -> dict:
    """Serialize WorkModel in declared field order."""
    return {
        "work_id":        obj.work_id,
        "name":           obj.name,
        "lifecycle":      obj.lifecycle.value,
        "phase":          obj.phase.value if obj.phase is not None else None,
        "active_skill":   obj.active_skill,
        "updated":        obj.updated,
        "created":        obj.created,
        "pause_reason":   obj.pause_reason,
        "block_reason":   obj.block_reason,
        "block_artifact": obj.block_artifact,
        "tasks":          [_ser_task(t) for t in obj.tasks],
        "pending_inputs": [_ser_pending_input(p) for p in obj.pending_inputs],
        "source_mode":    obj.source_mode.value,
        "number":         obj.number,
        "title":          obj.title,
        "description":    obj.description,
        "objective":      obj.objective,
        "work_path":      obj.work_path,
        "recipe":         obj.recipe,
        "features":       [_ser_feature_ref(f) for f in (obj.features or [])],
        "deliverables":   [_ser_deliverable_ref(d) for d in (obj.deliverables or [])],
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


def _dm3_post_process(raw: str) -> bytes:
    """Apply DM-3 U+2028/U+2029 escaping and encode to UTF-8.

    Both Python json.dumps(ensure_ascii=False) and Node JSON.stringify emit raw
    U+2028/U+2029 bytes by default. The canonical form is the ESCAPED form (PT-1/R7).
    """
    raw = raw.replace(chr(0x2028), '\\u2028').replace(chr(0x2029), '\\u2029')
    return raw.encode("utf-8")


def serialize_model(model) -> bytes:
    """Serialize a RepoModel to the DM-1 envelope bytes (feature-003 compatible)."""
    envelope = {
        "schema_version": 3,
        "generated_by":   "python",
        "model":          _ser_repo_model(model),
    }
    raw = json.dumps(envelope, separators=(",", ":"), ensure_ascii=False)
    return _dm3_post_process(raw)


def serialize_home(home_model: dict) -> bytes:
    """Serialize the DM-2 /api/home model to bytes (DM-3 rules)."""
    raw = json.dumps(home_model, separators=(",", ":"), ensure_ascii=False)
    return _dm3_post_process(raw)


# ---------------------------------------------------------------------------
# HTTP handler
# ---------------------------------------------------------------------------

class _DashboardHandler(BaseHTTPRequestHandler):
    """Request handler for the AID multi-repo dashboard server (feature-010)."""

    def log_message(self, fmt, *args):  # type: ignore[override]
        pass  # suppress default per-request log noise

    def log_error(self, fmt, *args):  # type: ignore[override]
        sys.stderr.write("server error: " + (fmt % args) + "\n")

    # ---- method dispatch ---------------------------------------------------

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]  # strip query string
        self._route_get(path)

    def do_HEAD(self) -> None:  # noqa: N802
        # HEAD is a non-GET verb -> 405 (SPEC route table: "non-GET verb -> 405",
        # NFR2 no write surface). Matches the Node server, which has no HEAD branch and
        # falls through to its non-GET 405 path (SEC-5 cross-runtime parity). The prior
        # 200-by-regex-match was both a HEAD-vs-GET status mismatch (it 200'd unregistered
        # ids and an absent index.html that GET 404s/503s) and a Python<->Node divergence.
        self._send_plain(405, b"Method Not Allowed")

    def do_POST(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_PUT(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_DELETE(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    def do_PATCH(self) -> None:  # noqa: N802
        self._send_plain(405, b"Method Not Allowed")

    # ---- router ------------------------------------------------------------

    def _route_get(self, path: str) -> None:
        if path == "/":
            self._serve_cli_home()
            return
        if path == "/api/home":
            self._serve_api_home()
            return
        m = _R.match(path)
        if m:
            rid, leaf = m.group(1), m.group(2)
            self._serve_repo_route(rid, leaf)
            return
        self._send_plain(404, b"Not Found")

    # ---- route handlers ----------------------------------------------------

    def _serve_cli_home(self) -> None:
        """GET / -> $AID_HOME/dashboard/index.html (task-053 lands the real file)."""
        # server.aid_home is the resolved $AID_HOME set at startup.
        index_html = Path(self.server.aid_home) / "dashboard" / "index.html"  # type: ignore[attr-defined]
        if not index_html.is_file():
            # Graceful 503 -- task-053 lands index.html; do NOT crash.
            body = b"503 CLI home not yet available (task-053 will provide index.html)"
            self.send_response(503)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        try:
            data = index_html.read_bytes()
        except OSError as exc:
            sys.stderr.write(f"server: index.html read error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _serve_api_home(self) -> None:
        """GET /api/home -> DM-2 model."""
        try:
            reg_path = Path(self.server.aid_home) / "registry.yml"  # type: ignore[attr-defined]
            id_map, warnings = _get_id_map(reg_path)
            model = build_home_model(
                aid_home=self.server.aid_home,  # type: ignore[attr-defined]
                reg_path=reg_path,
                id_map=id_map,
                warnings=warnings,
                runtime="python",
            )
            body = serialize_home(model)
        except Exception as exc:
            sys.stderr.write(f"server: /api/home error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _serve_repo_route(self, rid: str, leaf: str) -> None:
        """Handle /r/<id>/{home.html,kb.html,api/model}."""
        reg_path = Path(self.server.aid_home) / "registry.yml"  # type: ignore[attr-defined]
        id_map, _ = _get_id_map(reg_path)

        canon_path = id_map.get(rid)
        if canon_path is None:
            self._send_plain(404, b"Not Found")
            return

        if leaf in _LEAF_ALLOWLIST:
            self._serve_static_leaf(canon_path, leaf)
        else:
            # leaf == "api/model"
            self._serve_repo_model(canon_path)

    def _serve_static_leaf(self, canon_path: str, leaf: str) -> None:
        """SEC-2: served path constructed as registry[id]/.aid/dashboard/<leaf>."""
        # The leaf is from the fixed allowlist {home.html, kb.html} -- not from the request.
        file_path = Path(canon_path) / ".aid" / "dashboard" / leaf
        if not file_path.is_file():
            self._send_plain(404, b"Not Found")
            return
        try:
            data = file_path.read_bytes()
        except OSError as exc:
            sys.stderr.write(f"server: static leaf read error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _serve_repo_model(self, canon_path: str) -> None:
        """GET /r/<id>/api/model -> read_repo(repo(id)) -> DM-1 envelope.

        If .aid/ is gone: empty RepoModel (NFR10), NOT 404/500.
        """
        try:
            model = read_repo(canon_path)
            body = serialize_model(model)
        except Exception as exc:
            sys.stderr.write(f"server: /r/<id>/api/model error: {exc}\n")
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
        description="AID multi-repo dashboard server (feature-010, delivery-008).",
    )
    parser.add_argument("--host",     required=True, help="Bind host (must be 127.0.0.1 or ::1)")
    parser.add_argument("--port",     required=True, type=int, help="TCP port 1024..65535")
    args = parser.parse_args(argv)

    # SEC-1: reject any non-loopback host (never 0.0.0.0/wildcard, never config-read)
    if args.host not in _LOOPBACK_HOSTS:
        parser.error(
            f"--host must be a loopback address (127.0.0.1 or ::1); got: {args.host!r}"
        )

    if not (1024 <= args.port <= 65535):
        parser.error(f"--port must be in 1024..65535; got: {args.port}")

    return args


def main(argv: list[str] | None = None) -> None:
    args = _parse_args(argv)

    # Resolve aid_home WITHOUT following symlinks, to byte-match the Node server (DD-5/SEC-5):
    #   (1) AID_HOME env var verbatim if set and non-empty (Node uses process.env.AID_HOME as-is);
    #   (2) else self-locate LOGICALLY: server.py -> server/ -> dashboard/ -> $AID_HOME, via
    #       os.path (NOT Path.resolve(), which realpath-follows symlinks and would diverge from
    #       Node's join(__dirname, "..", "..") on a symlinked $AID_HOME -> machine.aid_home /
    #       machine.registry_path parity break).
    aid_home = os.environ.get("AID_HOME") or os.path.abspath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    )

    # Bind before any slow work (LC-1 readiness contract).
    server = ThreadingHTTPServer((args.host, args.port), _DashboardHandler)
    server.aid_home = aid_home  # type: ignore[attr-defined]

    # Clean exit on SIGTERM.
    def _handle_sigterm(signum, frame):  # noqa: ANN001
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, _handle_sigterm)

    sys.stderr.write(
        f"server.py: listening on http://{args.host}:{args.port} (aid_home={aid_home})\n"
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
