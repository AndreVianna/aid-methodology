# dashboard/server/server.py
# Python multi-repo server for the AID dashboard (feature-010, delivery-008).
#
# Stdlib-only. Binds 127.0.0.1 only -- never a wildcard or non-loopback address (SEC-1).
#
# Routes (NEW closed allowlist -- replaces feature-003 two-route server):
#   GET /                       -> CLI-home index.html from $AID_CODE_HOME/dashboard/index.html
#   GET /api/home               -> build DM-2 model -> 200 JSON
#   GET /r/<id>/home.html       -> $AID_CODE_HOME/dashboard/home.html (CLI template; gated on <repo>/.aid/)
#   GET /r/<id>/kb.html         -> <repo(id)>/.aid/knowledge/kb.html   (SEC-2 by construction)
#   GET /r/<id>/api/model       -> read_repo(repo(id)) -> DM-1 envelope
#   POST /r/<id>/api/op         -> _serve_op: closed OP_TABLE write/operation dispatch
#                                  (feature-001 task-004; 403 when not write_enabled)
#   POST /api/op                -> _serve_home_op: home-level op dispatch (HOME_OP_TABLE
#                                  carries feature-003's project.add/project.remove rows;
#                                  feature-004's tools.update-self row is still pending)
#   *                           -> 404
#   other POST / PUT/DELETE/PATCH/HEAD -> 405
#
# Registry: two-tier union of $AID_STATE_HOME/registry.yml (primary) and $HOME/.aid/registry.yml
#   (user fallback) -- mirrors _registry_read_raw_union in bin/aid.  Per-user collapse when both
#   resolve to the same path.  mtime+size-keyed id->path map cache (NFR4).
# SEC-3 (refined, feature-001 task-004): no IN-PROCESS write/append/remove primitive
#   anywhere in this file -- every mutation is delegated to a co-vendored writer script
#   (writeback-state.sh / write-setting.sh / write-requirement.sh, dashboard/scripts/)
#   spawned via subprocess.run() with an argv ARRAY (never shell=True, never a
#   concatenated command string). See OP_TABLE below.
# No agent/LLM import anywhere (SEC-4). Writer children are shell scripts, never an
#   agent/LLM import (SEC-4 holds for the dispatched child too).
# CAN-1 site 3: stored path used verbatim (no realpath/resolve -- SEC-2/DD-5).
# Host-header allowlist (anti-DNS-rebinding) + X-Content-Type-Options/CSP response
#   headers on every response, enforced before routing (SEC-6).
#
# Invocation:
#   python3 server.py --host 127.0.0.1 --port <n> [--allow-writes]
#   --allow-writes: fail-safe write gate (feature-001 task-001) -- absent => read-only;
#   a fixed token appended only by bin/aid's spawn policy, never read from request/config/env.
#   When absent, POST /r/<id>/api/op and POST /api/op both 403 "read-only" (task-004).
#
# AID_HOME (state home) resolution for registry.yml:
#   1. AID_HOME environment variable if set and non-empty (bin/aid always passes AID_HOME=$AID_STATE_HOME).
#   2. Self-locate fallback (direct invocation without env): server.py -> server/ -> dashboard/ -> parent.
#
# Code/static asset resolution (index.html, VERSION, lib/tools-catalog.txt):
#   Always self-located from _DASHBOARD_DIR / _DASHBOARD_DIR.parent ($AID_CODE_HOME),
#   independent of AID_HOME. These are shipped install-tree assets, NOT per-machine state.
#
# Python 3.11+ required. Zero third-party deps.

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import signal
import subprocess
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

from reader import read_repo, read_repo_detail, resolve_work_dir  # noqa: E402  (inserted sys.path above)
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


_MSYS_DRIVE_PATH = re.compile(r"^/([A-Za-z])(/.*)?$")


def _native_fs_path(path: str, is_windows: "bool | None" = None) -> str:
    """Map an MSYS/Git-Bash absolute path ('/c/Users/x') to a native-Windows
    drive path ('C:/Users/x') FOR FILESYSTEM ACCESS ONLY (KI-008).

    `aid projects add`/`remove` run under bash (KI-004: the dashboard spawns
    `bash bin/aid`), which canonicalizes and stores the MSYS form
    '/<drive>/rest' in registry.yml. Native-Windows Python cannot resolve that
    form, so a project registered via the dashboard would render with no
    metadata (name/version None). This maps it back to the native drive form so
    the reader's `<path>/.aid/...` reads resolve.

    SYNTACTIC only -- never touches the disk, follows a symlink, or
    realpath-resolves -- so the CAN-1/DD-5 "no realpathSync" security intent is
    preserved. Applied ONLY at the reader's filesystem boundary; the id-hash and
    the displayed/echoed path (and the bash-backed write ops, which already
    accept '/c/...') stay verbatim. NO-OP off Windows (on POSIX, '/c/foo' is a
    real absolute path) and NO-OP on an already-native 'C:/...' input. The twin
    of server.mjs's nativeFsPath(). `is_windows` is an injectable seam so the
    Linux CI suite can exercise the Windows branch."""
    if is_windows is None:
        is_windows = os.name == "nt"
    if not is_windows:
        return path
    m = _MSYS_DRIVE_PATH.match(path)
    if m:
        return f"{m.group(1).upper()}:{m.group(2) or '/'}"
    return path


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
# Two-tier registry union (mirrors _registry_read_raw_union in bin/aid)
# ---------------------------------------------------------------------------

def _reg_stat_key(path: Path) -> tuple | None:
    """Return (mtime_ns, size) or None if file is absent or unreadable."""
    try:
        st = path.stat()
        return (st.st_mtime_ns, st.st_size)
    except OSError:
        return None


def _load_union_repos(aid_home: str) -> tuple[list[str], list[str], Path, Path | None]:
    """Return (repos, warnings, primary_path, fallback_path_or_None).

    Mirrors _registry_read_raw_union from bin/aid (non-pruning raw union):
      primary  = aid_home/registry.yml  (= AID_STATE_HOME/registry.yml)
      fallback = $HOME/.aid/registry.yml

    Per-user collapse: when aid_home resolves to the same path as $HOME/.aid,
    read primary only (single tier, no double-read / double-count).

    Otherwise: union primary + fallback, deduped by path (preserving order of
    first occurrence -- equivalent to sort -u on a combined stream since the
    CLI does sort -u, but we use dict.fromkeys to maintain insertion order AND
    avoid duplicates, which is a safe superset: distinct-path dedup).

    The fallback file is gracefully absent (NFR10): missing = treat as empty.
    """
    primary_path = Path(aid_home) / "registry.yml"

    # Determine the user-tier path.
    user_home = os.environ.get("HOME", "")
    user_aid_path = os.path.join(user_home, ".aid") if user_home else ""

    # Per-user collapse: aid_home IS the user tier -- single-tier, no double-read.
    # Compare resolved strings (aid_home is verbatim; user_aid_path is computed).
    # Use os.path.normpath for the comparison ONLY (not stored -- CAN-1 / DD-5).
    is_per_user = bool(
        user_aid_path
        and os.path.normpath(aid_home) == os.path.normpath(user_aid_path)
    )

    if is_per_user:
        # Single tier: read primary only.
        repos, warnings = load_registry(primary_path)
        return repos, warnings, primary_path, None

    # Global / shared install: union primary + $HOME/.aid fallback.
    fallback_path: Path | None = Path(user_aid_path) / "registry.yml" if user_aid_path else None

    primary_repos, primary_warnings = load_registry(primary_path)
    fallback_repos, fallback_warnings = (
        load_registry(fallback_path) if fallback_path is not None else ([], [])
    )

    # Dedup by path, preserving first-occurrence order (mirrors sort -u semantics
    # for sets; sort -u is stable on sorted input so order matches sorted paths).
    seen: dict[str, None] = dict.fromkeys(primary_repos)
    for p in fallback_repos:
        seen.setdefault(p, None)
    repos = list(seen.keys())
    warnings = primary_warnings + fallback_warnings

    return repos, warnings, primary_path, fallback_path


# ---------------------------------------------------------------------------
# mtime+size-keyed registry cache (NFR4 / DD-1 SS 3.4)
#
# Cache key: (primary_stat_key, fallback_stat_key).
# A change in either tier's mtime/size invalidates the cache.  The path-set is
# NOT stored or compared separately: any path-set change requires editing the
# registry.yml which changes mtime or size, so stat-keying is sufficient.
# ---------------------------------------------------------------------------

_cache_key: tuple | None = None          # (primary_stat_key, fallback_stat_key)
_cache_id_map: dict[str, str] = {}       # id -> canon_path
_cache_warnings: list[str] = []
_cache_lock = threading.Lock()


def _get_id_map(aid_home: str) -> tuple[dict[str, str], list[str]]:
    """Return (id_map, warnings), rebuilding only when either registry tier changes.

    Uses the two-tier union (_load_union_repos) and keys the cache on
    (primary_mtime_ns+size, fallback_mtime_ns+size).  A stat change in either
    tier triggers a full rebuild.
    """
    global _cache_key, _cache_id_map, _cache_warnings

    # Stat both tiers (O(1) each, before taking the lock).
    primary_path = Path(aid_home) / "registry.yml"
    user_home = os.environ.get("HOME", "")
    user_aid_path = os.path.join(user_home, ".aid") if user_home else ""
    is_per_user = bool(
        user_aid_path
        and os.path.normpath(aid_home) == os.path.normpath(user_aid_path)
    )

    primary_stat = _reg_stat_key(primary_path)
    if is_per_user or not user_aid_path:
        fallback_stat = None
    else:
        fallback_stat = _reg_stat_key(Path(user_aid_path) / "registry.yml")

    probe_key = (primary_stat, fallback_stat)

    with _cache_lock:
        # Fast path: stat key unchanged -> return cached result.
        if _cache_key is not None and _cache_key == probe_key:
            return _cache_id_map, list(_cache_warnings)

        # Rebuild.
        repos, warnings, _, _ = _load_union_repos(aid_home)
        _cache_id_map = build_id_map(repos)
        _cache_warnings = warnings
        _cache_key = probe_key
        return _cache_id_map, list(_cache_warnings)


# ---------------------------------------------------------------------------
# Route parse (DD-1 SS 3.3 -- CRITICAL: use \A..\Z, NOT ^..$)
# ---------------------------------------------------------------------------

# CRITICAL: Python's $ also matches just before a trailing '\n', so use \Z.
_R = re.compile(r"\A/r/([0-9a-f]{8,})/(home\.html|kb\.html|api/model)\Z")

_LEAF_ALLOWLIST = frozenset({"home.html", "kb.html"})

# POST /r/<id>/api/op route (feature-001 task-004; separate from the GET-only _R above).
_R_OP = re.compile(r"\A/r/([0-9a-f]{8,})/api/op\Z")


# ---------------------------------------------------------------------------
# SEC-6: anti-DNS-rebinding Host-header allowlist + security response headers
# (mirrors server.mjs -- keep the two in lockstep)
# ---------------------------------------------------------------------------

# Restrictive CSP for the fully self-contained dashboard: every page inlines
# its own CSS/JS and never fetches an external origin (same-origin /api/*
# polling only). 'unsafe-inline' is required because the shipped HTML has no
# nonce/hash infrastructure for its inline <script>/<style> blocks; data: is
# allowed for img-src/font-src for any future inlined asset -- there are none
# today, so this does not widen the current attack surface.
_CSP_HEADER = (
    "default-src 'self'; script-src 'self' 'unsafe-inline'; "
    "style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; "
    "connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
)

_ALLOWED_HOST_LITERALS = frozenset({"127.0.0.1", "localhost", "[::1]"})
_ALLOWED_BARE_HOSTS = frozenset({"127.0.0.1", "localhost", "::1", "[::1]"})


def _is_allowed_host(host_header: str | None, port: int) -> bool:
    """True iff host_header names THIS server's own loopback bind (127.0.0.1,
    localhost, or ::1/[::1]), with or without an explicit port; when a port is
    present it must match the server's actual listen port.

    A MISSING/empty Host header is allowed -- conservative back-compat: the
    server only ever binds loopback (SEC-1), so an absent header cannot be
    forged by a remote page the way a forged Host VALUE can via DNS-rebinding
    (a rebind attack needs a Host value that resolves attacker DNS -> 127.0.0.1;
    it cannot make a browser omit Host entirely).
    """
    if not host_header:
        return True
    h = host_header.strip()
    if h == "":
        return True
    h_lower = h.lower()

    # Bare literal forms (no port) -- checked first so the colon-based
    # host/port split below never has to special-case bracket-less IPv6.
    if h_lower in _ALLOWED_BARE_HOSTS:
        return True

    if h[0] == "[":
        # Bracketed IPv6 literal: [::1] or [::1]:<port>
        close_idx = h.find("]")
        if close_idx == -1:
            return False
        host_part = h[:close_idx + 1].lower()
        rest = h[close_idx + 1:]
        port_part = rest[1:] if rest.startswith(":") else None
    else:
        colon_idx = h.rfind(":")
        if colon_idx == -1 or not h[colon_idx + 1:].isdigit():
            return False
        host_part = h[:colon_idx].lower()
        port_part = h[colon_idx + 1:]

    if host_part not in _ALLOWED_HOST_LITERALS:
        return False
    return port_part is not None and int(port_part) == port


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


def _read_aid_version() -> str | None:
    """Read VERSION from the code home ($AID_CODE_HOME/VERSION). None if absent.

    The VERSION file is a code/static asset shipped with the install tree, NOT a
    per-machine state artifact. It lives at $AID_CODE_HOME/VERSION, resolved via
    self-location: _DASHBOARD_DIR.parent is $AID_CODE_HOME.
    """
    try:
        return (_DASHBOARD_DIR.parent / "VERSION").read_text(encoding="utf-8").strip() or None
    except Exception:
        return None


def _tools_catalog() -> list[str]:
    """Read manageable-tool catalog from the code home (best-effort).

    The catalog file is a code/static asset shipped with the install tree, NOT a
    per-machine state artifact. It lives at $AID_CODE_HOME/lib/tools-catalog.txt,
    resolved via self-location: _DASHBOARD_DIR.parent is $AID_CODE_HOME.
    """
    # Aid's manageable tools: the five host tools aid add knows how to install
    # (antigravity, claude-code, codex, copilot-cli, cursor). We read the catalog
    # from the install tree if a catalog file is present, else fall back to the
    # static known list.
    catalog_path = _DASHBOARD_DIR.parent / "lib" / "tools-catalog.txt"
    if catalog_path.is_file():
        try:
            lines = catalog_path.read_text(encoding="utf-8").splitlines()
            return [l.strip() for l in lines if l.strip() and not l.strip().startswith("#")]
        except Exception:
            pass
    # Static fallback -- the known aid-manageable tools (kept byte-identical to the Node twin).
    return ["antigravity", "claude-code", "codex", "copilot-cli", "cursor"]


def build_home_model(
    aid_home: str,
    reg_path: Path,
    id_map: dict[str, str],
    warnings: list[str],
    runtime: str,
    write_enabled: bool = False,
) -> dict:
    """Build the DM-2 /api/home model. Never raises (NFR10).

    write_enabled (additive, feature-001 task-001): echoes the server's fail-safe
    write gate so the UI can hide controls the server would refuse (403). Defaults
    to False (fail-safe) when the caller does not pass the server's actual state.
    """
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    unavailable = 0

    # Build unsorted first, then sort by path (PT-1 determinism).
    repo_entries: list[dict] = []
    for rid, canon_path in id_map.items():
        # FS access uses the native-drive form (KI-008); id + displayed path stay verbatim.
        fs_path = _native_fs_path(canon_path)
        try:
            aid_dir = Path(fs_path) / ".aid"
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
            "pipeline_count":        None,
            "pipelines_in_progress": None,
        }

        if available:
            try:
                entry["name"], entry["description"] = _read_settings(fs_path)
            except Exception:
                pass
            try:
                entry["aid_version"], entry["tools_installed"] = _read_manifest(fs_path)
            except Exception:
                pass
            try:
                # home.html is a data-free CLI template served from $AID_CODE_HOME
                # (not a per-repo file); the opt-in signal that this repo has a
                # dashboard is simply that it is AID-initialized (.aid/ exists).
                entry["has_home"] = aid_dir.is_dir()
            except Exception:
                pass
            try:
                # kb.html is the generated KB summary, now beside its source in
                # .aid/knowledge/ (the .aid/dashboard/ folder was eliminated).
                entry["has_kb"] = (aid_dir / "knowledge" / "kb.html").is_file()
            except Exception:
                pass
            # Pipeline counts (FR27 home summary): total works + how many are Running.
            # The CLI home is load-once, so a per-project read_repo here is paid once
            # per page load, not per poll. Best-effort: never raise (NFR10).
            try:
                _rm = read_repo(fs_path)
                _works = getattr(_rm, "works", []) or []
                entry["pipeline_count"] = len(_works)
                entry["pipelines_in_progress"] = sum(
                    1 for _w in _works if getattr(_w, "lifecycle", None) == "Running"
                )
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
            "aid_version":    _read_aid_version(),
            "aid_home":       aid_home,
            "tools_catalog":  _tools_catalog(),
            "registry_path":  str(reg_path),
            "cli_runtime":    runtime,
            "write_enabled":  write_enabled,
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


def _ser_kb_baseline(obj) -> dict | None:
    """Serialize KbBaseline in declared field order, or None if absent."""
    if obj is None:
        return None
    return {
        "branch":   obj.branch,
        "tip_date": obj.tip_date,
    }


def _ser_doc_freshness(obj) -> dict:
    """Serialize one DocFreshness entry in declared field order (task-042/task-043)."""
    return {
        "doc":             obj.doc,
        "verdict":         obj.verdict,
        "suspect_sources": list(obj.suspect_sources),
    }


def _ser_kb_state(obj) -> dict | None:
    """Serialize KbStateRef in declared field order (DM-A3, task-064), or None if absent.

    Field order (DM-3 deterministic):
      retained: summary_approved, last_summary_date, doc_count
      new (task-064): status, summary_present, kb_baseline
      new (task-042/task-043): doc_freshness, suspect_count
      new (work-003-state-schema task-002): source_mode, kb_status, kb_grade,
        last_kb_review
    No schema_version bump (DM-A3).
    """
    if obj is None:
        return None
    return {
        "summary_approved":  obj.summary_approved,
        "last_summary_date": obj.last_summary_date,
        "doc_count":         obj.doc_count,
        "status":            obj.status.value if hasattr(obj.status, "value") else str(obj.status),
        "summary_present":   obj.summary_present,
        "kb_baseline":       _ser_kb_baseline(obj.kb_baseline),
        "doc_freshness":     [_ser_doc_freshness(d) for d in (obj.doc_freshness or [])],
        "suspect_count":     obj.suspect_count if isinstance(obj.suspect_count, int) else 0,
        "source_mode":       obj.source_mode.value if hasattr(obj.source_mode, "value") else str(obj.source_mode),
        "kb_status":         obj.kb_status,
        "kb_grade":          obj.kb_grade,
        "last_kb_review":    obj.last_kb_review,
    }


def _ser_repo_info(obj) -> dict:
    """Serialize RepoInfo in declared field order.

    feature-002 (work-017 task-005): project_description + minimum_grade are
    additive keys inserted after project_name (schema_version stays 3 --
    DM-A3/RC-2 no-bump precedent).
    """
    return {
        "project_name":        obj.project_name,
        "project_description": obj.project_description,
        "minimum_grade":       obj.minimum_grade,
        "aid_dir":             obj.aid_dir,
        "kb_state":            _ser_kb_state(obj.kb_state),
    }


def _ser_task(obj) -> dict:
    """Serialize TaskModel in declared field order (schema_version 3; display_name
    is an additive feature-005 field, no schema_version bump -- DM-A3/RC-2 precedent)."""
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
        "display_name": obj.display_name,
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
    """Serialize WorkModel in declared field order.

    Field order ends with the work-003-state-schema task-002 additions:
    kind, started, minimum_grade, user_approved.
    """
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
        "kind":           obj.kind,
        "started":        obj.started,
        "minimum_grade":  obj.minimum_grade,
        "user_approved":  obj.user_approved,
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


# ---------------------------------------------------------------------------
# TaskDetail serializers (LC-SD, task-070)
# Field order mirrors reader.mjs _build* functions for DM-2 key-order parity.
# ---------------------------------------------------------------------------

def _ser_finding(obj) -> dict:
    """Serialize Finding in declared field order (mirrors _buildFinding in reader.mjs)."""
    return {
        "severity":      obj.severity,
        "description":   obj.description,
        "location":      obj.location,
        "disposition":   obj.disposition,
        "reviewer_tier": obj.reviewer_tier,
    }


def _ser_deferred_issue(obj) -> dict:
    """Serialize DeferredIssue in declared field order (mirrors _buildDeferredIssue)."""
    return {
        "source_task": obj.source_task,
        "severity":    obj.severity,
        "description": obj.description,
        "status":      obj.status,
    }


def _ser_task_ledger(obj) -> dict:
    """Serialize TaskLedger in declared field order (mirrors _buildTaskLedger)."""
    return {
        "delivery_id":     obj.delivery_id,
        "grade":           obj.grade,
        "reviewer_tier":   obj.reviewer_tier,
        "gate_timestamp":  obj.gate_timestamp,
        "deferred_issues": [_ser_deferred_issue(d) for d in (obj.deferred_issues or [])],
    }


def _ser_raw_state_ref(obj) -> "dict | None":
    """Serialize RawStateRef in declared field order (mirrors _buildRawStateRef), or None."""
    if obj is None:
        return None
    return {
        "text":     obj.text,
        "byte_len": obj.byte_len,
        "path":     obj.path,
    }


def _ser_log_availability(obj) -> "dict | None":
    """Serialize LogAvailability in declared field order (mirrors _buildLogAvailability), or None."""
    if obj is None:
        return None
    return {
        "task_logs":          obj.task_logs,
        "server_log_present": obj.server_log_present,
        "heartbeat_present":  obj.heartbeat_present,
    }


def _ser_task_detail(obj) -> dict:
    """Serialize TaskDetail in declared field order (mirrors _buildTaskDetail in reader.mjs).

    Field order: task_id, findings, ledger, raw_state, logs
    """
    return {
        "task_id":  obj.task_id,
        "findings": [_ser_finding(f) for f in (obj.findings or [])],
        "ledger":   _ser_task_ledger(obj.ledger),
        "raw_state": _ser_raw_state_ref(obj.raw_state),
        "logs":     _ser_log_availability(obj.logs),
    }


def _parse_detail_param(query_string: str) -> list[str]:
    """Parse ?detail=<work_id>/<task_id>[,...] from a raw query string.

    Returns a list of composite 'work_id/task_id' strings (URL-decoded,
    trimmed, empties dropped). Returns [] for missing or empty ?detail=.
    """
    if not query_string:
        return []
    from urllib.parse import parse_qs, unquote_plus  # stdlib, safe to import here
    parsed = parse_qs(query_string, keep_blank_values=False)
    raw_vals = parsed.get("detail", [])
    if not raw_vals:
        return []
    # parse_qs joins multi-value but we only take the first occurrence
    raw = raw_vals[0]
    keys = [k.strip() for k in raw.split(",")]
    return [k for k in keys if k]


def _dm3_post_process(raw: str) -> bytes:
    """Apply DM-3 U+2028/U+2029 escaping and encode to UTF-8.

    Both Python json.dumps(ensure_ascii=False) and Node JSON.stringify emit raw
    U+2028/U+2029 bytes by default. The canonical form is the ESCAPED form (PT-1/R7).
    """
    raw = raw.replace(chr(0x2028), '\\u2028').replace(chr(0x2029), '\\u2029')
    return raw.encode("utf-8")


def serialize_model(model, write_enabled: bool = False) -> bytes:
    """Serialize a RepoModel to the DM-1 envelope bytes (feature-003 compatible).

    NFR4: bare /r/<id>/api/model call (no ?detail=) is byte-for-byte unchanged --
    the 'details' key is OMITTED entirely (not present) when details is None/not supplied.

    write_enabled (additive, feature-001 task-001): echoes the server's fail-safe
    write gate at the envelope top level (beside 'generated_by'). Defaults to False
    (fail-safe) when the caller does not pass the server's actual state.
    """
    envelope = {
        "schema_version": 3,
        "generated_by":   "python",
        "write_enabled":  write_enabled,
        "model":          _ser_repo_model(model),
    }
    raw = json.dumps(envelope, separators=(",", ":"), ensure_ascii=False)
    return _dm3_post_process(raw)


def serialize_model_with_details(model, details: dict, write_enabled: bool = False) -> bytes:
    """Serialize a RepoModel with a TaskDetail map appended (LC-SD, task-070).

    'details' is the LAST envelope key (after 'model'), present ONLY when ?detail= was supplied.
    Keys are sorted ascending (DM-2 key-order parity) -- the caller (read_repo_detail) returns
    them already sorted, but we re-sort here to be defensive.
    schema_version stays at 3 (RC-2 no-bump decision).

    write_enabled: see serialize_model() -- same additive top-level key, same fail-safe default.
    """
    sorted_details = {k: _ser_task_detail(v) for k, v in sorted(details.items())}
    envelope = {
        "schema_version": 3,
        "generated_by":   "python",
        "write_enabled":  write_enabled,
        "model":          _ser_repo_model(model),
        "details":        sorted_details,
    }
    raw = json.dumps(envelope, separators=(",", ":"), ensure_ascii=False)
    return _dm3_post_process(raw)


def serialize_home(home_model: dict) -> bytes:
    """Serialize the DM-2 /api/home model to bytes (DM-3 rules)."""
    raw = json.dumps(home_model, separators=(",", ":"), ensure_ascii=False)
    return _dm3_post_process(raw)


# ---------------------------------------------------------------------------
# Write / operation dispatch (feature-001-write-infrastructure, task-004)
#
# POST /r/<id>/api/op -> _serve_op (per-repo) / POST /api/op -> _serve_home_op (home).
# Order enforced by the handlers below: SEC-6 Host allowlist (do_POST, unchanged) ->
# write gate (write_enabled, 403 "read-only") -> body parse (400 "bad-request") ->
# closed OP_TABLE lookup (400 "bad-request" for unknown/missing op) -> target/arg
# shape validation (400) -> pipeline-scoped work_id resolution via resolve_work_dir
# (404 "not-found") -> writer spawn (argv ARRAY, never shell) -> exit-code -> HTTP
# status via the op's effective map (`op.status_map or DEFAULT_MAP`, OP-SM).
#
# The server never interprets a client-supplied path or command: OP_TABLE is a
# closed, static dict; each row names a fixed writer script and an argv-builder
# that only ever fills placeholders from validated, server-resolved values (never
# echoes a raw client path). SEC-3/SEC-4 hold: no in-process fs mutation, no
# agent/LLM import; the child is always a co-vendored shell script.
# ---------------------------------------------------------------------------

_MAX_BODY_BYTES = 64 * 1024   # 64 KiB request-body cap (API Contracts)
_MAX_DETAIL_BYTES = 1024      # 1 KiB failure 'detail' cap (writer stderr)

# Writers are co-vendored with the dashboard unit and self-located from the
# server's own install-tree location (_DASHBOARD_DIR = $AID_CODE_HOME/dashboard/),
# never from AID_HOME (per-machine state) -- same rationale as home.html
# (bin/aid ~line 1196 `assets_dir="$AID_CODE_HOME/dashboard"`).
_WRITER_DIR = _DASHBOARD_DIR / "scripts"

# $AID_CODE_HOME/bin/aid: the shared aid-CLI resolver's target (KI-004, feature-003
# project.add/remove; feature-004 tools.update/tools.update-self reuse this SAME
# anchor). Self-located via _DASHBOARD_DIR.parent -- the identical anchor
# _read_aid_version() / _tools_catalog() already use for VERSION / tools-catalog.txt.
# Never co-vendored (bin/aid already ships in the CLI package) and never resolved
# from AID_HOME (a code asset, not per-machine state).
_AID_CLI_PATH = _DASHBOARD_DIR.parent / "bin" / "aid"

# DEFAULT_MAP: writer exit code -> (http_status, error_class). Derived from
# writeback-state.sh's exit alphabet (0 ok / 1 missing-artifact / 2 lock-contention /
# 3 empty-or-unverifiable-write / 4 invalid-value / 5 missing-arg / 6 malformed
# STATE.md); write-setting.sh / write-requirement.sh reuse the SAME alphabet and
# never emit 2 (reserved for lock contention). An OP_TABLE row's OPTIONAL
# `status_map` field overrides this per-op (OP-SM foundation contract for
# features 003/004's `aid`-CLI-backed ops).
DEFAULT_MAP: dict[int, tuple[int, str]] = {
    1: (404, "not-found"),
    2: (409, "busy"),
    4: (422, "invalid-value"),
    5: (422, "invalid-value"),
    3: (500, "write-failed"),
    6: (500, "write-failed"),
}
_DEFAULT_FALLBACK = (500, "write-failed")   # any other/unknown exit code

_RE_WORK_ID_SHAPE = re.compile(r"^work-[0-9]+")
_RE_DELIVERY_ID = re.compile(r"\A\d{1,3}\Z")
# target.task_id (feature-006-task-notes, task-010): a deliberate SUPERSET that
# accepts both the prefixed 'task-NNN' form (what TaskModel.task_id -- and so
# home.html's task.task_id -- actually carries, e.g. "task-008") and the bare
# 'NNN' form (feature-001's own stated regex), reconciling feature-001's own
# regex-vs-example self-contradiction (SPEC.md API Contracts). The captured
# group is the bare numeric id, normalized in _dispatch_op below BEFORE any
# argv-builder runs -- writeback-state.sh's --task-id expects a bare number
# (base-10 arithmetic on it, write_task_field_flat line ~827).
_RE_TASK_ID_TARGET = re.compile(r"\A(?:task-)?(\d{1,3})\Z")


def _map_exit_code(
    exit_code: int,
    status_map: "dict[int, tuple[int, str]] | None",
    default_status: "tuple[int, str] | None" = None,
) -> tuple[int, str]:
    """Resolve the op's effective status map (`op.status_map or DEFAULT_MAP`, OP-SM)
    and map exit_code -> (http_status, error_class). An exit code absent from the
    effective map falls back to `default_status` if the row supplied one (the
    per-op 'status_map_default' extension, feature-004: `aid update`'s exit
    alphabet is not individually enumerable, so every non-zero/non-timeout exit
    must collapse to ONE 'update-failed' class rather than the generic
    'write-failed'), else the shared _DEFAULT_FALLBACK (500, 'write-failed') --
    DEFAULT_MAP's own '3/6/*' catch-all row.
    """
    effective = status_map if status_map else DEFAULT_MAP
    fallback = default_status if default_status is not None else _DEFAULT_FALLBACK
    return effective.get(exit_code, fallback)


def _parse_op_body(raw: bytes) -> "tuple[dict | None, str | None]":
    """Parse a POST op-request body. Returns (parsed_dict, None) on success, or
    (None, error_detail) on malformed JSON / a non-object top level (400 'bad-request').
    """
    try:
        parsed = json.loads(raw.decode("utf-8"))
    except Exception as exc:
        return None, f"malformed JSON body: {exc}"
    if not isinstance(parsed, dict):
        return None, "body must be a JSON object"
    return parsed, None


def _op_ok_body(op: str) -> bytes:
    """Success envelope: {"ok": true, "op": "<op>"} (API Contracts)."""
    return json.dumps({"ok": True, "op": op}, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def _truncate_detail(text: str) -> str:
    """Bound a failure 'detail' string to <= 1 KiB (API Contracts)."""
    encoded = text.encode("utf-8")
    if len(encoded) <= _MAX_DETAIL_BYTES:
        return text
    return encoded[:_MAX_DETAIL_BYTES].decode("utf-8", errors="ignore")


def _op_fail_body(op: "str | None", error: str, detail: str) -> bytes:
    """Failure envelope: {"ok": false, "op": <op|None>, "error": "<class>", "detail": "<=1KiB"}."""
    envelope = {"ok": False, "op": op, "error": error, "detail": _truncate_detail(detail)}
    return json.dumps(envelope, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def _resolve_bash_exe() -> str:
    """Resolve bash's ABSOLUTE path via a hand-rolled PATH-order search (SEC-3:
    this file has a blanket ban on the stdlib module that provides which())
    rather than passing the bare string "bash" to subprocess.run(). On Windows,
    CreateProcess's own search order checks the System32 directory BEFORE
    consuming the PATH env var's entries -- and Windows 10+ ships a WSL-launcher
    stub at C:\\Windows\\System32\\bash.exe. A bare "bash" argv[0] therefore
    silently resolves to that WSL stub (which cannot see a "C:/..." host path)
    instead of Git-Bash, even when Git-Bash appears earlier in PATH. This walks
    PATH ourselves in order (matching this script's own portability
    expectations) and sidesteps CreateProcess's fixed system-dir-first order.
    Mirrors resolveBashExe() in server.mjs exactly.
    """
    path_env = os.environ.get("PATH", "")
    exe_names = ("bash.exe", "bash.EXE") if sys.platform == "win32" else ("bash",)
    for directory in path_env.split(os.pathsep):
        if not directory:
            continue
        for exe_name in exe_names:
            candidate = os.path.join(directory, exe_name)
            if os.path.isfile(candidate):
                return candidate
    return "bash"  # fall back to bare name; subprocess.run reports ENOENT if truly absent


_BASH_EXE = _resolve_bash_exe()


def _run_writer(writer_name: str, argv: list[str], env_overrides: dict[str, str]) -> tuple[int, str]:
    """Spawn a co-vendored writer script via `bash <writer> <argv...>` -- an argv
    ARRAY, never shell=True / a concatenated command string (SEC-3/SEC-4 injection
    defense). Returns (exit_code, stderr_text). Never raises: an exec failure
    (writer missing, bash missing, timeout) is reported as exit 3 (the
    'empty/unverifiable write' class -> 500 write-failed) with the exception text
    as detail, so a broken install degrades to a clean HTTP error instead of a
    stack trace.
    """
    writer_path = _WRITER_DIR / writer_name
    child_env = dict(os.environ)
    child_env.update(env_overrides)
    bash_exe = _BASH_EXE
    try:
        # .as_posix() (not str()): on Windows, an MSYS/Git-Bash `bash.exe` mangles a
        # backslash-separated argv element (its own CreateProcess/argv-conversion
        # layer treats '\x' sequences as escapes), silently corrupting the script
        # path. Forward-slash form is accepted identically by bash on every platform.
        proc = subprocess.run(
            [bash_exe, writer_path.as_posix(), *argv],
            env=child_env,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return proc.returncode, proc.stderr or ""
    except Exception as exc:  # noqa: BLE001 -- never raises; reported as a write failure
        return 3, str(exc)


def _posix_argv_path(path_str: str) -> str:
    """Forward-slash form of a path-like ARGV element passed to the bash child
    (never for an env-var value) -- the same MSYS/Git-Bash argv-mangling
    mitigation _run_writer's docstring applies to a writer-script-path / --file
    element. No-op on POSIX (os.sep == '/'); on Windows, backslashes are swapped
    for forward slashes so bash.exe's own argv-parsing layer cannot mangle it.
    """
    return path_str.replace(os.sep, "/") if os.sep != "/" else path_str


_DEFAULT_AID_CLI_TIMEOUT = 30   # seconds; fast registry ops (project.add/remove,
# feature-003). A row's optional 'aid_cli_timeout' overrides this (feature-004's
# tools.update/tools.update-self need a much longer ceiling).

# A subprocess.run(timeout=...) kill is reported with this out-of-band sentinel --
# never a real aid-CLI exit code (0..255) -- so a per-op status_map row can
# distinguish a timeout from a normal exit (feature-004 maps it to 504
# 'timed-out'; this feature's own status_map has no entry for it, so it falls
# through to the (500, 'write-failed') catch-all, the correct fallback here too).
_AID_CLI_TIMEOUT_EXIT = -1


def _run_aid_cli(
    argv: list[str], env_overrides: dict[str, str], timeout: int = _DEFAULT_AID_CLI_TIMEOUT
) -> tuple[int, str]:
    """Shared aid-CLI resolver + argv-array child dispatch (KI-004): spawn the
    shipped `aid` CLI via `bash <bin/aid> <argv...>` -- an argv ARRAY, never
    shell=True / a concatenated command string (SEC-3/SEC-4). Self-locates
    $AID_CODE_HOME/bin/aid via _AID_CLI_PATH (_DASHBOARD_DIR.parent -- the
    identical self-location _read_aid_version()/_tools_catalog() already use).
    No OS branch, no bundled-Windows-shim alternative, no PATH fallback, no
    co-vendoring (bin/aid already ships in the CLI package). Single reusable
    unit: feature-003 (project.add/remove) and feature-004 (tools.update/
    tools.update-self) both call this, never re-inventing their own spawn.

    env_overrides is applied on top of a copy of the current environment (same
    convention as _run_writer) -- callers set ONLY AID_HOME (never
    AID_CODE_HOME; bin/aid self-locates that from its own BASH_SOURCE[0],
    bin/aid L45-52).

    Returns (exit_code, stderr_text). Never raises: an exec failure (aid
    missing, bash missing) is reported as exit 3 (mirrors _run_writer's own
    convention); a timeout is reported as _AID_CLI_TIMEOUT_EXIT (never a real
    0..255 exit code).
    """
    child_env = dict(os.environ)
    child_env.update(env_overrides)
    bash_exe = _BASH_EXE
    try:
        proc = subprocess.run(
            [bash_exe, _AID_CLI_PATH.as_posix(), *argv],
            env=child_env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return proc.returncode, proc.stderr or ""
    except subprocess.TimeoutExpired as exc:
        stderr = exc.stderr if isinstance(exc.stderr, str) else ""
        return _AID_CLI_TIMEOUT_EXIT, stderr
    except Exception as exc:  # noqa: BLE001 -- never raises; reported as a write failure
        return 3, str(exc)


def _spawn_writer(row: dict, argv: list[str], env_overrides: dict[str, str]) -> tuple[int, str]:
    """Default OP_TABLE spawn: run the row's co-vendored writer script
    (dashboard/scripts/) via _run_writer. A row may override this via an
    optional 'spawn' field (e.g. _spawn_aid_cli) for ops backed by a different
    child (KI-004: the aid CLI)."""
    return _run_writer(row["writer"], argv, env_overrides)


def _spawn_aid_cli(row: dict, argv: list[str], env_overrides: dict[str, str]) -> tuple[int, str]:
    """OP_TABLE 'spawn' override for aid-CLI-backed ops (KI-004 shared
    resolver): spawn $AID_CODE_HOME/bin/aid via _run_aid_cli instead of a
    co-vendored writer script. An optional per-row 'aid_cli_timeout' (seconds)
    overrides the default (feature-004's tools.update/tools.update-self need a
    longer ceiling than the fast registry ops this feature introduces)."""
    timeout = row.get("aid_cli_timeout", _DEFAULT_AID_CLI_TIMEOUT)
    return _run_aid_cli(argv, env_overrides, timeout)


def _validate_args(schema: dict, args: dict) -> "str | None":
    """Schema-level (shape-only) arg validation: required-key presence + string
    type. Returns an error message on violation, else None. Deeper SEMANTIC
    validation (enum membership, grade format, forbidden charset) is the writer's
    own job -- it returns exit 4/5, mapped to 422 'invalid-value' by DEFAULT_MAP;
    this function only prevents a malformed REQUEST from ever reaching a child
    spawn (400 'bad-request').
    """
    for key, spec in schema.items():
        if spec.get("required") and key not in args:
            return f"missing required arg '{key}'"
        if key in args and not isinstance(args[key], str):
            return f"arg '{key}' must be a string"
    return None


# ---- OP_TABLE argv-builders (feature-001-owned rows; see SPEC.md API Contracts) ----
# Each builder has signature (work_dir, served_root, target, args) -> (argv, env_overrides).
# work_dir is the resolve_work_dir() result (None for scope="project"/"home" ops);
# served_root is the resolved repo canon_path (per-repo ops) or aid_home (home ops --
# feature-003's project.add/remove pass it through as the child's AID_HOME env
# override, KI-004). Builders never echo a raw client path EXCEPT feature-003's
# project.add, a documented exception (SPEC.md API Contracts "Rationale for
# accepting a body path"): a not-yet-registered folder has no id to resolve, so
# registration is intrinsically path-driven; the path is pre-validated
# (_validate_project_add_args) and only ever handed to the aid CLI argv, never
# used to read/serve a file directly.

_TASK_NOTES_NULL_SENTINEL = "--"


def _op_task_set_notes_argv(work_dir: Path, served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """task.set-notes -> writeback-state.sh [--delivery-id <d>] --task-id <t> --field Notes --value <v>.

    Empty args.value means "clear notes" (feature-006-task-notes, "clear notes"
    semantic): writeback-state.sh's mode_field dies exit 5 on a literally empty
    --value ('--value is required with --task-id --field'), so an empty value is
    substituted with the '--' null sentinel before spawn -- the same sentinel
    task.rename already uses (_TASK_RENAME_NULL_SENTINEL), and the value the
    reader's NULL_SENTINELS set already maps back to None.
    """
    value = args["value"]
    if value == "":
        value = _TASK_NOTES_NULL_SENTINEL
    argv: list[str] = []
    delivery_id = target.get("delivery_id")
    if delivery_id:
        argv += ["--delivery-id", str(delivery_id)]
    argv += ["--task-id", str(target.get("task_id")), "--field", "Notes", "--value", value]
    env = {"AID_STATE_FILE": str(work_dir / "STATE.md"), "AID_WORK_DIR": str(work_dir)}
    return argv, env


# task.set-notes semantic (args.value) validation (feature-006-task-notes, task-010):
# <=1 KiB, rejects '|'/newline -- mirrors writeback-state.sh's mode_field guards
# (lines 733/738) so a bad value 422s before any child spawn. An empty string is
# explicitly ALLOWED (clear-to-null; the argv-builder above substitutes the '--'
# sentinel, never forwarding "" literally to the writer).
_MAX_NOTES_VALUE_BYTES = 1024  # 1 KiB cap (API Contracts: args.value <= 1 KiB)


def _validate_task_set_notes_args(args: dict) -> "str | None":
    value = args["value"]
    if "\n" in value:
        return "'value' cannot contain a newline"
    if "|" in value:
        return "'value' cannot contain '|' (reserved column separator)"
    # A literal backslash reaches writeback-state.sh's write_task_field_flat awk
    # vector; even though that vector now reads the value via ENVIRON (immune to
    # awk -v escape-reprocessing), reject it here too -- same KI-001-class guard
    # _validate_settings_set_args already applies (delivery-001 gate finding).
    if "\\" in value:
        return "'value' cannot contain a backslash (\\)"
    if len(value.encode("utf-8")) > _MAX_NOTES_VALUE_BYTES:
        return f"'value' exceeds max length ({_MAX_NOTES_VALUE_BYTES} bytes)"
    return None


def _op_pipeline_finish_argv(work_dir: Path, served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """pipeline.finish -> writeback-state.sh --pipeline --field Lifecycle --value Completed.

    Value is FIXED to 'Completed' -- the op takes no lifecycle argument and forwards
    no other of writeback-state.sh's Lifecycle enum values (general pipeline-lifecycle
    editing stays closed per REQUIREMENTS Sec 5.2). args is accepted but ignored.
    """
    argv = ["--pipeline", "--field", "Lifecycle", "--value", "Completed"]
    env = {"AID_STATE_FILE": str(work_dir / "STATE.md"), "AID_WORK_DIR": str(work_dir)}
    return argv, env


def _op_settings_set_argv(work_dir: "Path | None", served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """settings.set (project-scoped; no work_id) -> write-setting.sh --path <p> --value <v>
    --file <served-root>/.aid/settings.yml."""
    # .as_posix(): this is an ARGV element (not env) -- see _run_writer's MSYS note.
    settings_file = (Path(served_root) / ".aid" / "settings.yml").as_posix()
    argv = ["--path", args["path"], "--value", args["value"], "--file", settings_file]
    return argv, {}


# settings.set semantic (per-path) arg validation (feature-002, task-006): the closed
# args.path allowlist + per-path value rules the finalized arg-schema pins (SPEC.md
# API Contracts). Same alphabet as write-setting.sh's own (redundant, belt-and-suspenders)
# checks -- the writer remains the ultimate authority on what reaches settings.yml, but
# pre-validating here lets an invalid request 422 cleanly (API Contracts: "the server
# pre-validates for a clean status") without ever spawning a child.
_RE_GRADE = re.compile(r"^[A-F][+-]?$")
_SETTINGS_SET_PATH_ALLOWLIST = frozenset({"project.name", "project.description", "review.minimum_grade"})


def _validate_settings_set_args(args: dict) -> "str | None":
    """Semantic validation for the settings.set op (task-006). Returns an error message
    on violation, else None. Called AFTER the generic shape check (_validate_args), so
    args['path']/args['value'] are guaranteed present strings by the time this runs.
    """
    path = args["path"]
    value = args["value"]
    if path not in _SETTINGS_SET_PATH_ALLOWLIST:
        return "'path' must be one of: " + ", ".join(sorted(_SETTINGS_SET_PATH_ALLOWLIST))
    if path == "review.minimum_grade":
        if not _RE_GRADE.match(value):
            return "'value' must match ^[A-F][+-]?$ (e.g. A, A-, B+, F)"
        return None
    # project.name / project.description share the KI-001 output-charset guard.
    if "\n" in value:
        return "'value' cannot contain a newline"
    if '"' in value:
        return "'value' cannot contain a double-quote (\")"
    if "\\" in value:
        return "'value' cannot contain a backslash (\\)"
    if path == "project.name" and value == "":
        return "'value' is required for project.name (cannot be empty)"
    return None


_PIPELINE_RENAME_NULL_SENTINEL = "*(pending)*"


def _op_pipeline_rename_argv(work_dir: Path, served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """pipeline.rename -> write-requirement.sh --field Name --value <v>
    (env AID_REQUIREMENTS_FILE=<resolved-work-dir>/REQUIREMENTS.md).

    Empty args.value means clear-to-fallback (AC2): write-requirement.sh needs a
    non-empty bullet value, so an empty value is substituted with the
    '*(pending)*' null sentinel before spawn -- the exact placeholder
    parse_requirements_md's _re_name/_PENDING_PLACEHOLDER already maps back to
    title=None (parsers.py), which home.html's de-slug fallback then renders.
    """
    value = args["value"]
    if value == "":
        value = _PIPELINE_RENAME_NULL_SENTINEL
    argv = ["--field", "Name", "--value", value]
    env = {"AID_REQUIREMENTS_FILE": str(work_dir / "REQUIREMENTS.md")}
    return argv, env


_TASK_RENAME_NULL_SENTINEL = "--"


def _op_task_rename_argv(work_dir: Path, served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """task.rename -> writeback-state.sh [--delivery-id <d>] --task-id <t> --field Name --value <v>
    (env AID_STATE_FILE/AID_WORK_DIR=<resolved-work-dir>).

    Empty args.value means clear-to-fallback (AC2): writeback-state.sh dies exit 5
    on a literally empty --value ('--value is required with --task-id --field',
    fired before mode_field/layout detection ever runs), so an empty value is
    substituted with the '--' null sentinel before spawn -- the same sentinel
    mode_field/write_task_field_flat write for a cleared cell, and the value the
    reader's _is_null/_NULL_SENTINELS set already maps back to None.
    """
    value = args["value"]
    if value == "":
        value = _TASK_RENAME_NULL_SENTINEL
    argv: list[str] = []
    delivery_id = target.get("delivery_id")
    if delivery_id:
        argv += ["--delivery-id", str(delivery_id)]
    argv += ["--task-id", str(target.get("task_id")), "--field", "Name", "--value", value]
    env = {"AID_STATE_FILE": str(work_dir / "STATE.md"), "AID_WORK_DIR": str(work_dir)}
    return argv, env


# feature-005 (work-017 task-008) shared args.value semantic validation for
# task.rename / pipeline.rename: a single-line, length-capped string. Mirrors
# (belt-and-suspenders) the same charset guard both writers already enforce
# (write-requirement.sh rejects \n/| -> exit 4; writeback-state.sh mode_field
# rejects \n/| -> exit 4) -- an empty string is explicitly ALLOWED here (it means
# clear-to-fallback, AC2); the argv-builders substitute each writer's null
# sentinel for an empty value before spawn, never forwarding "" literally.
_MAX_RENAME_VALUE_LEN = 200


def _validate_rename_value(value: str) -> "str | None":
    if "\n" in value:
        return "'value' cannot contain a newline"
    if "|" in value:
        return "'value' cannot contain '|' (reserved column separator)"
    # A literal backslash reaches write-requirement.sh's / writeback-state.sh's
    # awk vectors; even though both now read the value via ENVIRON (immune to
    # awk -v escape-reprocessing), reject it here too -- same KI-001-class guard
    # _validate_settings_set_args already applies (delivery-001 gate finding).
    if "\\" in value:
        return "'value' cannot contain a backslash (\\)"
    if len(value) > _MAX_RENAME_VALUE_LEN:
        return f"'value' exceeds max length ({_MAX_RENAME_VALUE_LEN} chars)"
    return None


def _validate_task_rename_args(args: dict) -> "str | None":
    return _validate_rename_value(args["value"])


def _validate_pipeline_rename_args(args: dict) -> "str | None":
    return _validate_rename_value(args["value"])


# ---------------------------------------------------------------------------
# feature-003-project-registry (task-013): project.add / project.remove --
# home-scoped ops backed by the shared aid-CLI resolver (KI-004), registered
# into HOME_OP_TABLE below. See SPEC.md API Contracts for the full citation
# trail this section implements.
# ---------------------------------------------------------------------------

_MAX_PROJECT_PATH_LEN = 4096   # chars (API Contracts: args.path length <= 4096)


def _is_absolute_path(value: str) -> bool:
    """Cross-runtime-STABLE absolute-path check -- deliberately NOT delegating
    to os.path.isabs() on Windows. Python 3.13 changed ntpath.isabs() to
    require a drive letter for an absolute verdict (a bare '/foo' now returns
    False), while Node's path.isAbsolute() -- server.mjs's own check, unchanged
    -- still treats a leading '/' or '\\' as absolute on Windows (matching
    every Python version before 3.13 too). Left as os.path.isabs() this
    validation would silently diverge between the two twins (and even between
    Python minor versions) for the exact same input; this hand-reimplements
    Node's path.win32.isAbsolute() algorithm (leading '/'/'\\', OR a drive
    letter + ':' + separator, e.g. 'C:\\'/'C:/') so both twins agree
    regardless of which Python minor version (3.11..3.13+) is installed. On
    POSIX (os.sep == '/'), unaffected by this Windows-only skew -- delegates
    to os.path.isabs() (posixpath: startswith('/')) unchanged.
    """
    if os.sep != "\\":
        return os.path.isabs(value)
    if not value:
        return False
    first = value[0]
    if first in ("/", "\\"):
        return True
    if len(value) > 2 and value[1] == ":" and value[2] in ("/", "\\") and first.isalpha():
        return True
    return False


def _validate_project_add_args(args: dict) -> "str | None":
    """project.add PRE-dispatch (shape/charset) validation: args.path must be
    non-empty, free of NUL/newline/other control chars, <=4096 chars, and
    absolute (_is_absolute_path -- a POSIX '/' or a Windows drive/UNC root). A
    relative path is rejected rather than silently resolved against the
    SERVER's own cwd -- meaningless under --remote and not the browser user's
    cwd (SPEC.md API Contracts). Wired as the 'pre_validate' hook (400
    'bad-request'), NOT 'semantic_validate' (422) -- this is malformed-REQUEST
    shape/charset validation, not a semantic value-domain check; the `aid` CLI
    remains the sole authority on path existence / AID-project-ness (surfaced
    via its own exit 2 -> 422 'invalid-value', _PROJECT_OP_STATUS_MAP below).
    """
    value = args["path"]
    if value == "":
        return "'path' is required (cannot be empty)"
    if any(ord(ch) < 0x20 or ord(ch) == 0x7F for ch in value):
        return "'path' cannot contain NUL, a newline, or another control character"
    if len(value) > _MAX_PROJECT_PATH_LEN:
        return f"'path' exceeds max length ({_MAX_PROJECT_PATH_LEN} chars)"
    if not _is_absolute_path(value):
        return "'path' must be an absolute path"
    return None


def _op_project_add_argv(work_dir: "Path | None", served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """project.add -> bash $AID_CODE_HOME/bin/aid projects add <validated-path>
    (KI-004 shared resolver, spawned via _spawn_aid_cli). env
    AID_HOME=<server aid_home> (served_root here IS aid_home -- home scope) so
    the child resolves the SAME registry union /api/home enumerates;
    AID_CODE_HOME is NOT exported (bin/aid self-locates it, bin/aid L45-52). No
    --local/--shared/--verbose (tier selection is the CLI's own
    _aid_resolve_tier)."""
    argv = ["projects", "add", _posix_argv_path(args["path"])]
    env = {"AID_HOME": served_root}
    return argv, env


def _resolve_project_remove_target(served_root: str, target: dict) -> "str | None":
    """project.remove pre-dispatch target resolution (wired as the
    'resolve_target' hook): target.id must be a current key of the server's
    id_map (built from served_root == aid_home) -- returns the id_map-resolved
    canonical path VERBATIM (SEC-2), never a body-supplied path. None (-> caller
    404s 'not-found') on a missing, non-string, empty, or unknown id."""
    target_id = target.get("id")
    if not isinstance(target_id, str) or not target_id:
        return None
    id_map, _warnings = _get_id_map(served_root)
    return id_map.get(target_id)


def _op_project_remove_argv(work_dir: "Path | None", served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """project.remove -> bash $AID_CODE_HOME/bin/aid projects remove
    <id_map-resolved-path> (never a body-supplied path -- target['_resolved_path']
    is set by _resolve_project_remove_target, SEC-2). env
    AID_HOME=<server aid_home>."""
    argv = ["projects", "remove", _posix_argv_path(target["_resolved_path"])]
    env = {"AID_HOME": served_root}
    return argv, env


# Fail-open guard (feature-003, API Contracts "Fail-open guard"): aid projects
# add/remove are fail-open by design -- a shared-tier write needing unavailable
# elevation prints an UNCONDITIONAL 'WARN: aid: ...' (or the _aid_priv_run
# real-probe 'ERROR: aid: ...' line that precedes it) to stderr and still exits
# 0. The dashboard passes no --verbose, so on THIS invocation shape every
# emitted 'WARN: aid:' line is an unconditional degrade signal (the only
# benign WARN -- the user-tier-fallback notice -- is itself --verbose-gated).
_RE_AID_FAIL_OPEN = re.compile(r"(?m)^(?:WARN|ERROR): aid:")


def _post_verify_project_add(
    exit_code: int, stderr_text: str, target: dict, args: dict, served_root: str
) -> "tuple[int, str, str] | None":
    """Post-dispatch fail-open guard for project.add (wired as the
    'post_verify' hook): an exit-0 'WARN: aid:' (or 'ERROR: aid:') line means
    the write degraded to a no-op (fail-open) rather than landing -- surfaced
    as 500 'write-unverified', never a phantom 200. Returns None (no override --
    proceed to the normal exit-code mapping) on a verified-clean exit or any
    non-zero exit (already handled by status_map)."""
    if exit_code == 0 and _RE_AID_FAIL_OPEN.search(stderr_text):
        return 500, "write-unverified", stderr_text.strip()
    return None


def _post_verify_project_remove(
    exit_code: int, stderr_text: str, target: dict, args: dict, served_root: str
) -> "tuple[int, str, str] | None":
    """Post-dispatch fail-open guard for project.remove (wired as the
    'post_verify' hook): corroborated CANONICALISATION-FREE (the resolved path
    is the verbatim id_map value, SEC-2) -- re-loads the union and requires
    that exact string to now be absent. A 'WARN: aid:'/'ERROR: aid:' line OR
    the path still present in the re-loaded union means the write degraded to
    a no-op -> 500 'write-unverified'."""
    if exit_code != 0:
        return None
    fail_open = bool(_RE_AID_FAIL_OPEN.search(stderr_text))
    if not fail_open:
        resolved_path = target.get("_resolved_path")
        repos, _warnings, _primary, _fallback = _load_union_repos(served_root)
        if resolved_path is not None and resolved_path in repos:
            fail_open = True
    if fail_open:
        return 500, "write-unverified", stderr_text.strip()
    return None


# project.add/remove share one status_map: the `aid`-CLI exit alphabet (0 ok,
# 2 = user/validation error for every `aid projects` failure) differs from
# writeback-state.sh's DEFAULT_MAP (where 2 = lock contention). Any other
# non-zero exit (including _AID_CLI_TIMEOUT_EXIT / the exec-failure sentinel 3)
# falls through to _DEFAULT_FALLBACK (500 'write-failed'), matching the API
# Contracts row "other non-zero -> 500 write-failed".
_PROJECT_OP_STATUS_MAP: dict[int, tuple[int, str]] = {
    2: (422, "invalid-value"),
}


# ---------------------------------------------------------------------------
# feature-004-update-tools (task-015): tools.update / tools.update-self --
# reuse the SAME shared aid-CLI resolver task-013 introduced (KI-004, not
# re-invented); no new spawn mechanism, no new resolver. See SPEC.md API
# Contracts for the full citation trail this section implements.
# ---------------------------------------------------------------------------


def _validate_no_args(args: dict) -> "str | None":
    """Shared semantic_validate hook for feature-004's argument-free ops
    (tools.update, tools.update-self): a non-empty args object is a 422
    'invalid-value' (SPEC.md API Contracts arg-schema convention) -- neither op
    accepts --force/--dry-run/per-tool knobs in v1 (D4). Absent/empty args
    (the {} arg_schema on both rows lets any object through _validate_args
    unexamined) passes here."""
    if args:
        return "this op accepts no arguments"
    return None


def _op_tools_update_argv(work_dir: "Path | None", served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """tools.update (per-repo, PROJECT-scoped; no work_id) -> bash
    $AID_CODE_HOME/bin/aid update --target <served-root> (KI-004 shared
    resolver, spawned via _spawn_aid_cli). served_root here IS the repo's own
    canon_path -- resolved solely from <id> via id_map by _serve_op (SEC-2),
    never from target.work_id. env AID_HOME=<server aid_home>: since
    served_root is the REPO path here (not aid_home), _dispatch_op stashes the
    server's own state home into target['_aid_home'] before calling this
    builder (mirrors project.remove's target['_resolved_path'] smuggling
    pattern -- build_argv's call signature is frozen at (work_dir, served_root,
    target, args) across every OP_TABLE row, so this is the only pass-through
    available) so `aid update`'s self-update-if-stale preamble / registry
    reads resolve the SAME state home the dashboard itself uses; AID_CODE_HOME
    is NOT exported (bin/aid self-locates it, bin/aid L45-52)."""
    argv = ["update", "--target", _posix_argv_path(served_root)]
    env = {"AID_HOME": target["_aid_home"]}
    return argv, env


def _op_tools_update_self_argv(work_dir: "Path | None", served_root: str, target: dict, args: dict) -> tuple[list[str], dict[str, str]]:
    """tools.update-self (home; no <id>, no work_id) -> bash
    $AID_CODE_HOME/bin/aid update self (KI-004 shared resolver, spawned via
    _spawn_aid_cli). served_root here IS aid_home (home scope, mirrors
    project.add/project.remove exactly). env AID_HOME=<server aid_home>;
    AID_CODE_HOME NOT exported."""
    argv = ["update", "self"]
    env = {"AID_HOME": served_root}
    return argv, env


# tools.update / tools.update-self share one status_map (feature-004): unlike
# project.add/remove's enumerable 0/2 `aid`-CLI alphabet, `aid update`'s exit
# codes are not individually enumerable here -- the server controls the entire
# argv, so `aid`'s own usage-error exits (e.g. the tool-positional reject,
# `bin/aid` line 3054-3062) are not reachable through this closed surface
# (API Contracts) -- so EVERY non-zero, non-timeout exit collapses to the
# single 'update-failed' class via the row's 'status_map_default' (the OP-SM
# default-status extension _map_exit_code supports), rather than falling
# through to the shared _DEFAULT_FALLBACK's generic 'write-failed'. Only the
# out-of-band timeout sentinel (_AID_CLI_TIMEOUT_EXIT, never a real 0..255
# exit) gets its own explicit row, mapping to 504 'timed-out'.
_TOOLS_UPDATE_STATUS_MAP: dict[int, tuple[int, str]] = {
    _AID_CLI_TIMEOUT_EXIT: (504, "timed-out"),
}
_TOOLS_UPDATE_STATUS_DEFAULT: tuple[int, str] = (500, "update-failed")

# 600s (10 min): a generous ceiling for `aid update`/`aid update self`, which can
# fetch + install every configured tool profile (or the channel CLI package) --
# far longer than the 30s default sized for the fast registry ops above.
_TOOLS_UPDATE_TIMEOUT = 600


# OP_TABLE: closed static dict seeded by feature-001 (the 4 feature-001-owned rows).
# 'scope': "task" (work_id + task_id required) | "pipeline" (work_id required) |
# "project" (no work_id -- settings.set targets the served root directly) |
# "home" (HOME_OP_TABLE rows below -- no work_id, no per-repo <id>; feature-003's
# project.add/remove).
# 'status_map': None -> dispatcher uses DEFAULT_MAP (OP-SM); a later feature's row
# may set its own {exit -> (status, error)} map for the `aid`-CLI exit alphabet
# (feature-003's _PROJECT_OP_STATUS_MAP is the first such override).
OP_TABLE: dict[str, dict] = {
    "task.set-notes": {
        "scope": "task",
        "writer": "writeback-state.sh",
        "arg_schema": {"value": {"required": True}},
        "build_argv": _op_task_set_notes_argv,
        "semantic_validate": _validate_task_set_notes_args,
        "status_map": None,
    },
    "pipeline.finish": {
        "scope": "pipeline",
        "writer": "writeback-state.sh",
        "arg_schema": {},
        "build_argv": _op_pipeline_finish_argv,
        "status_map": None,
    },
    "settings.set": {
        "scope": "project",
        "writer": "write-setting.sh",
        "arg_schema": {"path": {"required": True}, "value": {"required": True}},
        "build_argv": _op_settings_set_argv,
        "semantic_validate": _validate_settings_set_args,
        "status_map": None,
    },
    "pipeline.rename": {
        "scope": "pipeline",
        "writer": "write-requirement.sh",
        "arg_schema": {"value": {"required": True}},
        "build_argv": _op_pipeline_rename_argv,
        "semantic_validate": _validate_pipeline_rename_args,
        "status_map": None,
    },
    "task.rename": {
        "scope": "task",
        "writer": "writeback-state.sh",
        "arg_schema": {"value": {"required": True}},
        "build_argv": _op_task_rename_argv,
        "semantic_validate": _validate_task_rename_args,
        "status_map": None,
    },
    "tools.update": {
        "scope": "project",
        "arg_schema": {},
        "build_argv": _op_tools_update_argv,
        "semantic_validate": _validate_no_args,
        "spawn": _spawn_aid_cli,
        "aid_cli_timeout": _TOOLS_UPDATE_TIMEOUT,
        "status_map": _TOOLS_UPDATE_STATUS_MAP,
        "status_map_default": _TOOLS_UPDATE_STATUS_DEFAULT,
    },
}

# HOME_OP_TABLE: feature-003 (project.add/project.remove, task-013) registers
# the first two home-scoped rows below; feature-004 (task-015) adds
# tools.update-self. Every OTHER op dispatched through _serve_home_op is
# 'unknown' -> 400.
HOME_OP_TABLE: dict[str, dict] = {
    "project.add": {
        "scope": "home",
        "arg_schema": {"path": {"required": True}},
        "build_argv": _op_project_add_argv,
        "pre_validate": _validate_project_add_args,
        "spawn": _spawn_aid_cli,
        "post_verify": _post_verify_project_add,
        "status_map": _PROJECT_OP_STATUS_MAP,
    },
    "project.remove": {
        "scope": "home",
        "arg_schema": {},
        "build_argv": _op_project_remove_argv,
        "resolve_target": _resolve_project_remove_target,
        "spawn": _spawn_aid_cli,
        "post_verify": _post_verify_project_remove,
        "status_map": _PROJECT_OP_STATUS_MAP,
    },
    "tools.update-self": {
        "scope": "home",
        "arg_schema": {},
        "build_argv": _op_tools_update_self_argv,
        "semantic_validate": _validate_no_args,
        "spawn": _spawn_aid_cli,
        "aid_cli_timeout": _TOOLS_UPDATE_TIMEOUT,
        "status_map": _TOOLS_UPDATE_STATUS_MAP,
        "status_map_default": _TOOLS_UPDATE_STATUS_DEFAULT,
    },
}


def _dispatch_op(
    op_table: dict, parsed: dict, served_root: "str | None", aid_home: "str | None" = None
) -> tuple[int, bytes]:
    """Validate + dispatch a parsed op-request body against op_table.

    served_root is the resolved repo canon_path (per-repo ops) or aid_home (home
    ops). Never spawns a writer child before every schema/shape check below has
    passed (no client-controlled bytes reach subprocess argv unvalidated).

    aid_home (task-015 extension, KI-004-adjacent): the server's own state home,
    needed ONLY by a PROJECT-scoped op whose served_root is a repo canon_path
    rather than aid_home (feature-004's tools.update) so its build_argv can still
    set AID_HOME=<aid_home> in the child env. Defaults to served_root when the
    caller omits it -- the correct value for every existing call site (home-scope
    ops already pass served_root == aid_home; other project/task/pipeline-scope
    ops never read it).
    """
    op = parsed.get("op")
    if not isinstance(op, str) or op not in op_table:
        return 400, _op_fail_body(op if isinstance(op, str) else None, "bad-request", "unknown or missing 'op'")

    row = op_table[op]

    target = parsed.get("target")
    if target is None:
        target = {}
    if not isinstance(target, dict):
        return 400, _op_fail_body(op, "bad-request", "'target' must be an object")
    # Stash the resolved aid_home into target (mirrors project.remove's
    # target['_resolved_path'] smuggling pattern below) so a build_argv can read
    # it despite build_argv's frozen (work_dir, served_root, target, args)
    # signature -- harmless for every op that never reads this key.
    target["_aid_home"] = aid_home if aid_home is not None else served_root

    args = parsed.get("args")
    if args is None:
        args = {}
    if not isinstance(args, dict):
        return 400, _op_fail_body(op, "bad-request", "'args' must be an object")

    delivery_id = target.get("delivery_id")
    if delivery_id is not None and not _RE_DELIVERY_ID.match(str(delivery_id)):
        return 400, _op_fail_body(op, "bad-request", "invalid target.delivery_id")
    task_id_raw = target.get("task_id")
    if task_id_raw is not None:
        task_id_match = _RE_TASK_ID_TARGET.match(str(task_id_raw))
        if not task_id_match:
            return 400, _op_fail_body(op, "bad-request", "invalid target.task_id")
        # Normalize the prefixed 'task-NNN' form to the bare numeric id BEFORE any
        # argv-builder runs, so every "task"-scoped op (task.set-notes, task.rename)
        # sees the same bare value regardless of which form the client sent.
        target["task_id"] = task_id_match.group(1)

    scope = row["scope"]
    work_dir: "Path | None" = None
    if scope in ("task", "pipeline"):
        work_id = target.get("work_id")
        if not isinstance(work_id, str) or not _RE_WORK_ID_SHAPE.match(work_id):
            return 400, _op_fail_body(op, "bad-request", "missing or invalid target.work_id")
        if scope == "task" and not task_id_raw:
            return 400, _op_fail_body(op, "bad-request", "this op requires target.task_id")
        work_dir = resolve_work_dir(served_root, work_id)
        if work_dir is None:
            return 404, _op_fail_body(op, "not-found", f"no worktree holds work_id '{work_id}'")

    # Optional per-op target resolution hook (feature-003, KI-004-adjacent
    # extension point): a row with one resolves target.<field> against
    # served_root (e.g. project.remove's target.id -> id_map) BEFORE any arg
    # validation / child spawn; None means "not found" (404), never a generic
    # 400 -- the target genuinely does not name a current server-side resource.
    resolve_target = row.get("resolve_target")
    if resolve_target is not None:
        resolved = resolve_target(served_root, target)
        if resolved is None:
            return 404, _op_fail_body(op, "not-found", "target.id not found in the registry")
        target["_resolved_path"] = resolved

    arg_err = _validate_args(row["arg_schema"], args)
    if arg_err is not None:
        return 400, _op_fail_body(op, "bad-request", arg_err)

    # Optional per-op PRE-dispatch (shape/charset) validation hook (feature-003):
    # distinct from semantic_validate below -- this maps to 400 'bad-request' (a
    # malformed REQUEST, e.g. project.add's non-absolute/over-length/control-char
    # path), never 422 (a well-formed request the writer would reject on VALUE
    # grounds).
    pre_validate = row.get("pre_validate")
    if pre_validate is not None:
        pre_err = pre_validate(args)
        if pre_err is not None:
            return 400, _op_fail_body(op, "bad-request", pre_err)

    # Optional per-op semantic (value-level) validation hook (task-006's OP-SM-style
    # extension point): a row with one 422s a request the writer would reject anyway,
    # ahead of any child spawn; a row without one skips straight to build_argv/spawn.
    semantic_validate = row.get("semantic_validate")
    if semantic_validate is not None:
        semantic_err = semantic_validate(args)
        if semantic_err is not None:
            return 422, _op_fail_body(op, "invalid-value", semantic_err)

    argv, env_overrides = row["build_argv"](work_dir, served_root, target, args)
    spawn_fn = row.get("spawn", _spawn_writer)
    exit_code, stderr_text = spawn_fn(row, argv, env_overrides)

    # Optional per-op post-dispatch verification hook (feature-003 fail-open
    # guard, KI-004-adjacent extension point): overrides the normal exit-code
    # mapping when an apparently-clean exit actually degraded to a no-op (e.g. a
    # shared-tier registry write that fails open with a stderr WARN yet still
    # exits 0).
    post_verify = row.get("post_verify")
    if post_verify is not None:
        override = post_verify(exit_code, stderr_text, target, args, served_root)
        if override is not None:
            ov_status, ov_error_class, ov_detail = override
            return ov_status, _op_fail_body(op, ov_error_class, ov_detail)

    if exit_code == 0:
        return 200, _op_ok_body(op)
    status, error_class = _map_exit_code(exit_code, row.get("status_map"), row.get("status_map_default"))
    return status, _op_fail_body(op, error_class, stderr_text.strip())


# ---------------------------------------------------------------------------
# HTTP handler
# ---------------------------------------------------------------------------

class _DashboardHandler(BaseHTTPRequestHandler):
    """Request handler for the AID multi-repo dashboard server (feature-010)."""

    def log_message(self, fmt, *args):  # type: ignore[override]
        pass  # suppress default per-request log noise

    def log_error(self, fmt, *args):  # type: ignore[override]
        sys.stderr.write("server error: " + (fmt % args) + "\n")

    # ---- SEC-6: security response headers on every response ---------------
    # send_response() is the one call every response path makes (directly or
    # via _send_plain()) before end_headers(), so overriding it here applies
    # the headers uniformly without touching every route handler.

    def send_response(self, code, message=None):  # type: ignore[override]
        super().send_response(code, message)
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", _CSP_HEADER)

    # ---- SEC-6: anti-DNS-rebinding Host-header allowlist -------------------

    def _reject_bad_host(self) -> bool:
        """Reject requests whose Host header does not name this server's own
        loopback bind (SEC-6). Checked BEFORE any routing/method dispatch, on
        every verb. Returns True if a 403 was already sent (caller must
        return immediately) or False if the request may proceed.
        """
        host_header = self.headers.get("Host")
        port: int = self.server.server_port  # type: ignore[attr-defined]
        if not _is_allowed_host(host_header, port):
            self._send_plain(403, b"403 Forbidden (untrusted Host header)")
            return True
        return False

    # ---- method dispatch ---------------------------------------------------

    def do_GET(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        # Split path and query string; route on path only (closed allowlist).
        # The raw query string is threaded to _serve_repo_model for ?detail= parsing (task-070).
        parts = self.path.split("?", 1)
        path = parts[0]
        query_string = parts[1] if len(parts) > 1 else ""
        self._route_get(path, query_string)

    def do_HEAD(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        # HEAD is a non-GET verb -> 405 (SPEC route table: "non-GET verb -> 405",
        # NFR2 no write surface). Matches the Node server, which has no HEAD branch and
        # falls through to its non-GET 405 path (SEC-5 cross-runtime parity). The prior
        # 200-by-regex-match was both a HEAD-vs-GET status mismatch (it 200'd unregistered
        # ids and an absent index.html that GET 404s/503s) and a Python<->Node divergence.
        self._send_plain(405, b"Method Not Allowed")

    def do_POST(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        path = self.path.split("?", 1)[0]
        if path == "/api/op":
            self._serve_home_op()
            return
        m = _R_OP.match(path)
        if m:
            self._serve_op(m.group(1))
            return
        self._send_plain(405, b"Method Not Allowed")

    def do_PUT(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        self._send_plain(405, b"Method Not Allowed")

    def do_DELETE(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        self._send_plain(405, b"Method Not Allowed")

    def do_PATCH(self) -> None:  # noqa: N802
        if self._reject_bad_host():
            return
        self._send_plain(405, b"Method Not Allowed")

    # ---- router ------------------------------------------------------------

    def _route_get(self, path: str, query_string: str = "") -> None:
        if path == "/":
            self._serve_cli_home()
            return
        if path == "/api/home":
            self._serve_api_home()
            return
        m = _R.match(path)
        if m:
            rid, leaf = m.group(1), m.group(2)
            self._serve_repo_route(rid, leaf, query_string)
            return
        self._send_plain(404, b"Not Found")

    # ---- route handlers ----------------------------------------------------

    def _serve_cli_home(self) -> None:
        """GET / -> $AID_CODE_HOME/dashboard/index.html (code asset, self-located).

        index.html is a CODE asset shipped with the install tree -- it resolves from
        the server's own location (_DASHBOARD_DIR), NOT from the per-machine state home.
        _DASHBOARD_DIR = server.py/../ = $AID_CODE_HOME/dashboard/.
        """
        index_html = _DASHBOARD_DIR / "index.html"
        if not index_html.is_file():
            # Graceful 503: the file is genuinely missing from the install tree.
            # This should not happen in a healthy install; run 'aid update' to repair.
            body = b"503 dashboard index.html missing from install tree; run 'aid update' to repair"
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
            aid_home: str = self.server.aid_home  # type: ignore[attr-defined]
            id_map, warnings = _get_id_map(aid_home)
            # registry_path in the machine block shows the primary (state-home) path.
            reg_path = Path(aid_home) / "registry.yml"
            model = build_home_model(
                aid_home=aid_home,
                reg_path=reg_path,
                id_map=id_map,
                warnings=warnings,
                runtime="python",
                write_enabled=getattr(self.server, "write_enabled", False),
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

    def _serve_repo_route(self, rid: str, leaf: str, query_string: str = "") -> None:
        """Handle /r/<id>/{home.html,kb.html,api/model}."""
        aid_home: str = self.server.aid_home  # type: ignore[attr-defined]
        id_map, _ = _get_id_map(aid_home)

        canon_path = id_map.get(rid)
        if canon_path is None:
            self._send_plain(404, b"Not Found")
            return

        if leaf in _LEAF_ALLOWLIST:
            self._serve_static_leaf(canon_path, leaf)
        else:
            # leaf == "api/model"
            self._serve_repo_model(canon_path, query_string)

    def _serve_static_leaf(self, canon_path: str, leaf: str) -> None:
        """Serve a dashboard leaf (home.html | kb.html) for a repo.

        home.html is a DATA-FREE CLI TEMPLATE -- byte-identical across all repos, it
        derives the repo from the URL and pulls every value live from ./api/model. So
        it is served from the installed CLI's OWN copy ($AID_CODE_HOME/dashboard/
        home.html, self-located via _DASHBOARD_DIR) -- always current with the running
        server -- NOT from a per-repo copy (which drifted across CLI versions and was
        the cause of "updated the CLI but the dashboard is stale"). The repo just needs
        to be AID-initialized (.aid/ exists) to gate access.

        kb.html is a per-repo GENERATED artifact -- the summarize skill bakes the KB
        docs into it -- and lives beside its source at .aid/knowledge/kb.html (the
        .aid/dashboard/ folder was eliminated). Served from the repo copy (SEC-2: path
        constructed as registry[id]/.aid/knowledge/kb.html; a broken symlink there
        fails is_file() -> 404).
        """
        # FS access uses the native-drive form (KI-008); SEC-2 already resolved
        # canon_path from <id> via id_map (never the request body) upstream.
        fs_path = _native_fs_path(canon_path)
        # The leaf is from the fixed allowlist {home.html, kb.html} -- not from the request.
        if leaf == "home.html":
            # Opt-in gate: only AID-initialized repos expose a dashboard.
            if not (Path(fs_path) / ".aid").is_dir():
                self._send_plain(404, b"Not Found")
                return
            file_path = _DASHBOARD_DIR / "home.html"
            if not file_path.is_file():
                # home.html genuinely missing from the install tree; repair via 'aid update'.
                self._send_plain(
                    503,
                    b"503 dashboard home.html missing from install tree; run 'aid update' to repair",
                )
                return
        else:
            # kb.html (per-repo generated leaf): served from .aid/knowledge/.
            file_path = Path(fs_path) / ".aid" / "knowledge" / leaf
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
        # home.html is CLI-served and changes across CLI versions; kb.html changes on
        # re-summarize. Force revalidation so an updated CLI/summary shows without a
        # manual hard-refresh (this simple server has no ETag, so revalidate == re-send).
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _serve_repo_model(self, canon_path: str, query_string: str = "") -> None:
        """GET /r/<id>/api/model -> read_repo(repo(id)) -> DM-1 envelope.

        If .aid/ is gone: empty RepoModel (NFR10), NOT 404/500.

        LC-SD (task-070): when ?detail=<work_id>/<task_id>[,...] is present, calls
        read_repo_detail and appends a 'details' map to the envelope. The 'details'
        key is OMITTED entirely when ?detail= is not supplied (NFR4 byte-identical
        bare-poll path). schema_version stays at 3 (RC-2 no-bump decision).
        """
        detail_keys = _parse_detail_param(query_string)
        write_enabled = getattr(self.server, "write_enabled", False)
        # FS access uses the native-drive form (KI-008); canon_path was SEC-2-resolved upstream.
        fs_path = _native_fs_path(canon_path)
        try:
            if detail_keys:
                model, details = read_repo_detail(fs_path, detail_keys)
                body = serialize_model_with_details(model, details, write_enabled)
            else:
                model = read_repo(fs_path)
                body = serialize_model(model, write_enabled)
        except Exception as exc:
            sys.stderr.write(f"server: /r/<id>/api/model error: {exc}\n")
            self._send_plain(500, b"Internal Server Error")
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _serve_op(self, rid: str) -> None:
        """POST /r/<id>/api/op -- per-repo write/operation dispatch (feature-001 task-004).

        Order: write gate (403 'read-only') -> repo id resolution (404 'not-found') ->
        body parse (400 'bad-request') -> OP_TABLE dispatch (_dispatch_op). SEC-6
        (_reject_bad_host) already ran in do_POST before this is reached.
        """
        if not getattr(self.server, "write_enabled", False):
            self._send_json(403, _op_fail_body(
                None, "read-only",
                "write endpoints disabled (server not spawned with --allow-writes)",
            ))
            return

        aid_home: str = self.server.aid_home  # type: ignore[attr-defined]
        id_map, _ = _get_id_map(aid_home)
        canon_path = id_map.get(rid)
        if canon_path is None:
            self._send_json(404, _op_fail_body(None, "not-found", "unknown repo id"))
            return

        raw = self._read_body()
        if raw is None:
            self._send_json(400, _op_fail_body(None, "bad-request", "body exceeds 64 KiB or is unreadable"))
            return
        parsed, err = _parse_op_body(raw)
        if parsed is None:
            self._send_json(400, _op_fail_body(None, "bad-request", err or "malformed body"))
            return

        status, body = _dispatch_op(OP_TABLE, parsed, canon_path, aid_home=aid_home)
        self._send_json(status, body)

    def _serve_home_op(self) -> None:
        """POST /api/op -- home-level write/operation dispatch (feature-001 task-004).

        feature-001 seeds no home-scoped rows itself; feature-003 (task-013)
        registers project.add/project.remove into HOME_OP_TABLE, and feature-004
        (tools.update-self) adds its own row next. Any OTHER op is 'unknown' ->
        400 -- the gate/body-parsing/dispatch plumbing is wired so each feature
        only needs to add its own HOME_OP_TABLE row(s).
        """
        if not getattr(self.server, "write_enabled", False):
            self._send_json(403, _op_fail_body(
                None, "read-only",
                "write endpoints disabled (server not spawned with --allow-writes)",
            ))
            return

        raw = self._read_body()
        if raw is None:
            self._send_json(400, _op_fail_body(None, "bad-request", "body exceeds 64 KiB or is unreadable"))
            return
        parsed, err = _parse_op_body(raw)
        if parsed is None:
            self._send_json(400, _op_fail_body(None, "bad-request", err or "malformed body"))
            return

        aid_home: str = self.server.aid_home  # type: ignore[attr-defined]
        status, body = _dispatch_op(HOME_OP_TABLE, parsed, aid_home)
        self._send_json(status, body)

    # ---- helpers -----------------------------------------------------------

    def _send_plain(self, code: int, body: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_json(self, code: int, body: bytes) -> None:
        """Send a JSON op-response envelope (used by _serve_op / _serve_home_op)."""
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self) -> "bytes | None":
        """Read the POST body, enforcing the 64 KiB cap (API Contracts).

        Returns None (caller sends 400) when Content-Length is missing/invalid/
        negative/over the cap, or the read itself fails.
        """
        try:
            length = int(self.headers.get("Content-Length", "0") or "0")
        except ValueError:
            return None
        if length < 0 or length > _MAX_BODY_BYTES:
            return None
        try:
            return self.rfile.read(length)
        except Exception:
            return None


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
    parser.add_argument(
        "--allow-writes",
        action="store_true",
        default=False,
        help=(
            "Enable write/operation endpoints (fail-safe default: read-only when absent). "
            "A fixed token appended by bin/aid's spawn policy -- never read from "
            "request/config/env (SEC-1 posture unaffected)."
        ),
    )
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

    # Resolve the STATE home (aid_home) WITHOUT following symlinks, to byte-match the
    # Node server (DD-5/SEC-5). aid_home is used ONLY for state: registry.yml + registry_path
    # in the /api/home machine block. Code assets resolve from _DASHBOARD_DIR (self-located).
    #   (1) AID_HOME env var verbatim if set and non-empty (Node uses process.env.AID_HOME as-is;
    #       bin/aid always passes AID_HOME=$AID_STATE_HOME so (1) is the normal path).
    #   (2) Fallback for direct invocation without env: self-locate via os.path
    #       (NOT Path.resolve(), which realpath-follows symlinks and would diverge from
    #       Node's join(__dirname, "..", "..") on a symlinked AID_HOME -> parity break).
    aid_home = os.environ.get("AID_HOME") or os.path.abspath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    )

    # Bind before any slow work (LC-1 readiness contract).
    server = ThreadingHTTPServer((args.host, args.port), _DashboardHandler)
    server.aid_home = aid_home  # type: ignore[attr-defined]
    # Fail-safe write gate (feature-001 task-001): absent --allow-writes -> read-only.
    server.write_enabled = args.allow_writes  # type: ignore[attr-defined]

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
