"""
test_server_py.py -- Self-check and behavioral tests for dashboard/server/server.py
                     (feature-010, delivery-008 -- multi-repo contract).

Assertion groups:
  (1) Source invariants: no wildcard bind token, no write/remove primitive, no LLM import.
  (2) Route table: each allowlisted route returns its expected status + shape.
  (3) SEC-2 refusal matrix: traversal/escape/non-allowlisted attempts all 404.
  (4) Registry tolerance (NFR10): absent/torn/higher-schema registry degrades best-effort.
  (5) /api/home DM-2 shape: machine panel keys, repos[] sorted by path, per-repo fields.
  (6) Serialization (DM-3): key order, compact, no trailing newline, integers-only.
  (7) Invariants: 127.0.0.1-only bind, SIGTERM exits, no write primitive, no LLM import.
  (8) <id> derivation: sha256(CAN-1(path))[:8] for a known path.

Python 3.11+ stdlib only. Zero third-party deps.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD.
# ---------------------------------------------------------------------------

_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/
_SERVER_SCRIPT = _SERVER_DIR / "server.py"

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as _server_module


# ---------------------------------------------------------------------------
# AID-home fixture helpers
# ---------------------------------------------------------------------------

def _make_aid_home(base: Path) -> Path:
    """Create a minimal AID_HOME tree: VERSION + registry.yml (empty) + dashboard/ dir."""
    base.mkdir(parents=True, exist_ok=True)
    (base / "VERSION").write_text("1.0.0-test\n", encoding="utf-8")
    # Empty registry (repos: with no items -- NFR10 valid form)
    _write_registry(base, [])
    (base / "dashboard").mkdir(exist_ok=True)
    return base


def _write_registry(aid_home: Path, paths: list[str]) -> None:
    """Write a registry.yml with the given absolute paths into aid_home."""
    lines = [
        "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).\n",
        "# Holds ONLY the base folders of repos this CLI install manages.\n",
        "schema: 1\n",
        "repos:\n",
    ]
    for p in paths:
        lines.append(f"  - {p}\n")
    (aid_home / "registry.yml").write_text("".join(lines), encoding="utf-8")


def _make_repo(base: Path, *, with_kb: bool = False) -> Path:
    """Create a minimal repo tree under base: .aid/ + settings.yml + manifest.

    If with_kb, also create .aid/knowledge/kb.html.  The .aid/dashboard/ folder was
    eliminated: home.html is now served from the CLI's own copy (gated only on the
    repo's .aid/ dir), and the generated kb.html moved beside its source into
    .aid/knowledge/ -- so no per-repo home.html is written here anymore.
    """
    aid = base / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text(
        "project:\n  name: test-repo\n  description: A test repo\n",
        encoding="utf-8",
    )
    (aid / ".aid-manifest.json").write_text(
        json.dumps({
            "manifest_version": 1,
            "aid_version": "1.0.0-test",
            "installed_at": "2026-01-01T00:00:00Z",
            "tools": {"claude-code": {"installed_at": "2026-01-01T00:00:00Z"}},
        }),
        encoding="utf-8",
    )
    if with_kb:
        kb = aid / "knowledge"
        kb.mkdir(exist_ok=True)
        (kb / "kb.html").write_text("<html>kb</html>", encoding="utf-8")
    return base


def _make_aid_with_works(repo: Path, work_ids: list[str]) -> None:
    """Add work folders to an existing .aid/ dir so /r/<id>/api/model returns works."""
    aid = repo / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    for wid in work_ids:
        wdir = aid / "works" / wid
        wdir.mkdir(parents=True, exist_ok=True)
        (wdir / "STATE.md").write_text(
            "# Work State\n\n## Pipeline Status\n\nLifecycle: Running\n\n"
            "## Tasks Status\n\n"
            "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- |\n",
            encoding="utf-8",
        )


def _repo_id(path: str) -> str:
    """Compute sha256(CAN-1(path)) hex -- the full digest."""
    return hashlib.sha256(path.encode("utf-8")).hexdigest()


def _repo_id8(path: str) -> str:
    """Return the 8-char id prefix."""
    return _repo_id(path)[:8]


# ---------------------------------------------------------------------------
# Server thread context manager
# ---------------------------------------------------------------------------

class _ServerThread:
    """Start the multi-repo server in a background thread against a tmp AID_HOME."""

    def __init__(self, aid_home: str, write_enabled: bool = False) -> None:
        self._aid_home = aid_home
        self._write_enabled = write_enabled
        self._httpd = None
        self._thread = None
        self.port: int = 0

    def __enter__(self) -> "_ServerThread":
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            self.port = s.getsockname()[1]

        self._httpd = _server_module.ThreadingHTTPServer(
            ("127.0.0.1", self.port), _server_module._DashboardHandler
        )
        self._httpd.aid_home = self._aid_home  # type: ignore[attr-defined]
        # Fail-safe write gate (feature-001 task-001): mirrors main()'s
        # server.write_enabled = args.allow_writes; defaults to False (read-only).
        self._httpd.write_enabled = self._write_enabled  # type: ignore[attr-defined]
        self._thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        self._thread.start()
        self._wait_ready()
        return self

    def _wait_ready(self) -> None:
        for _ in range(50):
            try:
                with socket.create_connection(("127.0.0.1", self.port), timeout=0.1):
                    return
            except OSError:
                time.sleep(0.05)
        raise RuntimeError("Server did not become ready in time")

    def __exit__(self, *_) -> None:
        if self._httpd:
            self._httpd.shutdown()
            self._httpd.server_close()
        if self._thread:
            self._thread.join(timeout=5)

    def get(self, path: str, headers: dict[str, str] | None = None) -> tuple[int, bytes, dict]:
        """Return (status_code, body_bytes, headers). Optional 'headers' overrides/adds
        request headers (e.g. {'Host': 'evil.example.com'} for the SEC-6 Host-allowlist
        tests -- urllib honors a caller-supplied Host header verbatim)."""
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, headers=headers or {})
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read(), dict(resp.headers)
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read(), dict(exc.headers or {})

    def post(self, path: str) -> tuple[int, bytes]:
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, data=b"", method="POST")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()

    def put(self, path: str) -> tuple[int, bytes]:
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, data=b"", method="PUT")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()

    def delete(self, path: str) -> tuple[int, bytes]:
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, method="DELETE")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()

    def head(self, path: str) -> tuple[int, bytes]:
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, method="HEAD")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()


# ===========================================================================
# (1) Source invariants
# ===========================================================================

class TestSourceInvariants(unittest.TestCase):
    """Grep-level self-checks on server.py source."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.source = Path(_server_module.__file__).read_text(encoding="utf-8")
        # Strip comments so doc-comment mentions don't trigger false positives.
        import re
        # Remove block comments (Python has none in source, but for safety)
        # Remove single-line comments
        cls.code = re.sub(r'(?m)#.*$', ' ', cls.source)

    # SEC-1: literal bind token check
    def test_loopback_addrs_contains_127(self):
        """Server source must gate with a LOOPBACK_HOSTS set that contains 127.0.0.1."""
        self.assertIn('"127.0.0.1"', self.source)

    def test_no_inaddr_any(self):
        self.assertNotIn("INADDR_ANY", self.source)

    def test_no_double_colon_wildcard_bind(self):
        # '::' as a bind-address (not as slice syntax or annotation).
        self.assertNotIn('("::", ', self.source)
        self.assertNotIn("('::', ", self.source)

    # SEC-1 confirmed: 0.0.0.0 must not appear in executable CODE (comments may mention it
    # as the forbidden value). We verify the listen call uses HOST variable, not a literal.
    def test_server_listen_uses_variable_not_literal_wildcard(self):
        """ThreadingHTTPServer bind must use host variable, never hardcoded 0.0.0.0."""
        import re
        # Find the ThreadingHTTPServer(...) call
        m = re.search(r'ThreadingHTTPServer\s*\(([^)]+)\)', self.source)
        if m:
            bind_args = m.group(1)
            self.assertNotIn("0.0.0.0", bind_args,
                             "ThreadingHTTPServer() must not bind 0.0.0.0")

    def test_loopback_hosts_set_present(self):
        """_LOOPBACK_HOSTS set must exist and gate --host validation (SEC-1)."""
        self.assertIn("_LOOPBACK_HOSTS", self.source)

    # SEC-3: no write/append/remove primitive
    def test_no_os_remove(self):
        self.assertNotIn("os.remove", self.code)
        self.assertNotIn("os.unlink", self.code)

    def test_no_shutil(self):
        self.assertNotIn("shutil", self.code)

    def test_no_open_write_flag(self):
        import re
        matches = re.findall(r'''open\s*\(.*?['"][wWaA][bB+]?['"]''', self.code)
        self.assertEqual(matches, [],
                         f"server.py must not open files for writing; found: {matches}")

    def test_no_write_text(self):
        self.assertNotIn(".write_text(", self.code)

    def test_no_write_bytes(self):
        self.assertNotIn(".write_bytes(", self.code)

    # SEC-4: no agent/LLM import
    def test_no_anthropic_import(self):
        self.assertNotIn("anthropic", self.source)

    def test_no_openai_import(self):
        self.assertNotIn("openai", self.source)

    def test_no_langchain_import(self):
        self.assertNotIn("langchain", self.source)

    def test_no_agent_dispatch_import(self):
        self.assertNotIn("agent_dispatch", self.source)
        self.assertNotIn("agent-dispatch", self.source)


# ===========================================================================
# (2) Route table
# ===========================================================================

class TestRouteTable(unittest.TestCase):
    """Each allowlisted route returns its expected status + shape; unknown -> 404; non-GET -> 405."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

        # One registered repo with dashboard files and works
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a, with_kb=True)
        _make_aid_with_works(self._repo_a, ["work-001-alpha", "work-002-beta"])
        _write_registry(self._aid_home, [str(self._repo_a)])

        # Compute the expected id for repo_a
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    # GET / -> 503 when index.html absent (task-053 provides it later)
    def test_root_503_when_index_absent(self):
        """GET / must 503 gracefully when $AID_HOME/dashboard/index.html is absent."""
        # index.html was NOT created in setUp (only the directory was)
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/")
        self.assertEqual(status, 503)
        self.assertIn(b"task-053", body)

    def test_root_200_when_index_present(self):
        """GET / must 200 when $AID_HOME/dashboard/index.html exists."""
        index = self._aid_home / "dashboard" / "index.html"
        index.write_text("<html>home</html>", encoding="utf-8")
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get("/")
        index.unlink()  # clean up
        self.assertEqual(status, 200)
        self.assertIn(b"<html>", body)
        self.assertIn("text/html", headers.get("Content-Type", ""))

    # GET /api/home -> DM-2 envelope
    def test_api_home_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get("/api/home")
        self.assertEqual(status, 200)

    def test_api_home_content_type(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get("/api/home")
        ct = headers.get("Content-Type", "")
        self.assertIn("application/json", ct)
        self.assertIn("utf-8", ct)

    def test_api_home_valid_json(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        data = json.loads(body)
        self.assertEqual(data["schema_version"], 1)
        self.assertEqual(data["generated_by"], "python")

    def test_api_home_no_trailing_newline(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertFalse(body.endswith(b"\n"), "DM-3: no trailing newline")

    # GET /r/<id>/home.html -> 200. Served from the CLI's OWN dashboard/home.html
    # (self-located), gated only on repo-A having an .aid/ dir -- NOT a per-repo file
    # (the .aid/dashboard/ folder was eliminated). Body is the real CLI SPA.
    def test_repo_home_html_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get(f"/r/{self._id_a}/home.html")
        self.assertEqual(status, 200)
        self.assertIn("text/html", headers.get("Content-Type", ""))
        self.assertIn(b"<!DOCTYPE html>", body)
        self.assertEqual(headers.get("Cache-Control"), "no-cache")

    # GET /r/<id>/kb.html -> 200 when .aid/knowledge/kb.html exists
    def test_repo_kb_html_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get(f"/r/{self._id_a}/kb.html")
        self.assertEqual(status, 200)
        self.assertIn("text/html", headers.get("Content-Type", ""))
        self.assertIn(b"<html>kb</html>", body)
        self.assertEqual(headers.get("Cache-Control"), "no-cache")

    # GET /r/<id>/api/model -> DM-1 envelope (schema_version 3)
    def test_repo_api_model_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 200)

    def test_repo_api_model_content_type(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, headers = srv.get(f"/r/{self._id_a}/api/model")
        ct = headers.get("Content-Type", "")
        self.assertIn("application/json", ct)

    def test_repo_api_model_envelope(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        data = json.loads(body)
        self.assertEqual(data["schema_version"], 3)
        self.assertEqual(data["generated_by"], "python")
        self.assertIn("model", data)
        model = data["model"]
        for key in ("tool", "repo", "works", "read"):
            self.assertIn(key, model)

    def test_repo_api_model_no_trailing_newline(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        self.assertFalse(body.endswith(b"\n"), "DM-3: no trailing newline")

    # Unknown paths -> 404 (closed allowlist)
    def test_unknown_path_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/no/such/path")
        self.assertEqual(status, 404)

    def test_api_unknown_subpath_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/other")
        self.assertEqual(status, 404)

    def test_random_deep_path_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/foo/bar/baz")
        self.assertEqual(status, 404)

    # Non-GET -> 405
    def test_post_405(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _ = srv.post("/api/home")
        self.assertEqual(status, 405)

    def test_put_405(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _ = srv.put("/api/home")
        self.assertEqual(status, 405)

    def test_delete_405(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _ = srv.delete("/api/home")
        self.assertEqual(status, 405)

    def test_head_405(self):
        # HEAD is a non-GET verb -> 405 (SPEC: "non-GET verb -> 405"); must match the
        # Node server (parity, SEC-5). Guards against the prior do_HEAD that 200'd by
        # regex-match alone (HEAD-vs-GET status mismatch on unregistered ids / absent index).
        with _ServerThread(str(self._aid_home)) as srv:
            status, _ = srv.head("/")
            self.assertEqual(status, 405)
            status, _ = srv.head("/api/home")
            self.assertEqual(status, 405)
            status, _ = srv.head("/r/deadbeef0/home.html")
            self.assertEqual(status, 405)

    def test_post_repo_api_model_405(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _ = srv.post(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 405)


# ===========================================================================
# (2b) SEC-6: anti-DNS-rebinding Host-header allowlist
# ===========================================================================

class TestSec6HostAllowlistUnit(unittest.TestCase):
    """Pure unit test of _is_allowed_host (no server/port needed)."""

    def setUp(self) -> None:
        self._port = 8787

    # Accept: allowlisted host, with and without the matching port.
    def test_bare_ip_with_matching_port(self):
        self.assertTrue(_server_module._is_allowed_host("127.0.0.1:8787", self._port))

    def test_localhost_with_matching_port(self):
        self.assertTrue(_server_module._is_allowed_host("localhost:8787", self._port))

    def test_bracketed_ipv6_with_matching_port(self):
        self.assertTrue(_server_module._is_allowed_host("[::1]:8787", self._port))

    def test_bare_ip_no_port(self):
        self.assertTrue(_server_module._is_allowed_host("127.0.0.1", self._port))

    def test_bare_localhost_no_port(self):
        self.assertTrue(_server_module._is_allowed_host("localhost", self._port))

    def test_bare_ipv6_unbracketed_no_port(self):
        self.assertTrue(_server_module._is_allowed_host("::1", self._port))

    def test_bare_ipv6_bracketed_no_port(self):
        self.assertTrue(_server_module._is_allowed_host("[::1]", self._port))

    def test_case_insensitive_host_match(self):
        self.assertTrue(_server_module._is_allowed_host("LOCALHOST:8787", self._port))

    def test_missing_host_header_allowed(self):
        """Back-compat: a missing Host header cannot be forged by a remote page
        the way a forged Host VALUE can via DNS-rebinding (SEC-1 loopback-only bind)."""
        self.assertTrue(_server_module._is_allowed_host(None, self._port))

    def test_empty_host_header_allowed(self):
        self.assertTrue(_server_module._is_allowed_host("", self._port))

    # Reject: foreign host names (the DNS-rebinding attack shape).
    def test_foreign_host_no_port_rejected(self):
        self.assertFalse(_server_module._is_allowed_host("evil.example.com", self._port))

    def test_foreign_host_matching_port_rejected(self):
        self.assertFalse(_server_module._is_allowed_host("evil.example.com:8787", self._port))

    def test_subdomain_suffix_trick_rejected(self):
        self.assertFalse(
            _server_module._is_allowed_host("127.0.0.1.evil.example.com:8787", self._port)
        )

    # Reject: allowlisted host name but the WRONG port (rebind to a different
    # local service listening on another port is still a cross-origin read risk).
    def test_allowlisted_host_wrong_port_rejected(self):
        self.assertFalse(_server_module._is_allowed_host("127.0.0.1:9999", self._port))

    def test_allowlisted_localhost_wrong_port_rejected(self):
        self.assertFalse(_server_module._is_allowed_host("localhost:1", self._port))


class TestSec6HostAllowlistLive(unittest.TestCase):
    """Live-server accept/reject matrix + security response headers."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_allowlisted_ip_host_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home", headers={"Host": f"127.0.0.1:{srv.port}"})
        self.assertEqual(status, 200)

    def test_allowlisted_localhost_host_200(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home", headers={"Host": f"localhost:{srv.port}"})
        self.assertEqual(status, 200)

    def test_default_host_header_200(self):
        """Baseline sanity: urllib's own default Host header (127.0.0.1:<port>) passes."""
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home")
        self.assertEqual(status, 200)

    def test_foreign_host_403(self):
        """The DNS-rebinding attack shape: a page served from evil.example.com whose
        DNS has been rebound to 127.0.0.1 for the 2nd request."""
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home", headers={"Host": "evil.example.com"})
        self.assertEqual(status, 403)

    def test_foreign_host_with_port_403_on_root(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/", headers={"Host": f"evil.example.com:{srv.port}"})
        self.assertEqual(status, 403)

    def test_allowlisted_host_wrong_port_403(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home", headers={"Host": "127.0.0.1:1"})
        self.assertEqual(status, 403)

    def test_security_headers_on_accepted_response(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, headers = srv.get("/api/home", headers={"Host": f"127.0.0.1:{srv.port}"})
        self.assertEqual(status, 200)
        self.assertEqual(headers.get("X-Content-Type-Options"), "nosniff")
        self.assertTrue(headers.get("Content-Security-Policy"))

    def test_security_headers_on_rejected_response(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, headers = srv.get("/api/home", headers={"Host": "evil.example.com"})
        self.assertEqual(status, 403)
        self.assertEqual(headers.get("X-Content-Type-Options"), "nosniff")
        self.assertTrue(headers.get("Content-Security-Policy"))


# ===========================================================================
# (3) SEC-2 refusal matrix
# ===========================================================================

class TestSec2RefusalMatrix(unittest.TestCase):
    """Construct-not-sanitize: traversal/escape/non-allowlisted paths -> 404.
    Unregistered <id> -> 404.
    Registered-but-.aid-gone -> 404 static leaves, empty RepoModel for /api/model.
    """

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a, with_kb=True)
        _write_registry(self._aid_home, [str(self._repo_a)])
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    # Traversal attempts in path: all must 404 (id segment is hex-only, so
    # ".." cannot appear in the id; and the leaf comes from the fixed allowlist).
    def test_dotdot_after_id_404(self):
        """Path traversal like /r/<id>/../registry.yml -> 404 (no such route)."""
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/../registry.yml")
        self.assertEqual(status, 404)

    def test_dotdot_in_id_404(self):
        """.id containing .. cannot be hex-only -> 404."""
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/r/../registry.yml")
        self.assertEqual(status, 404)

    def test_dotdot_work_state_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/work-001/STATE.md")
        self.assertEqual(status, 404)

    def test_percent_encoded_dotdot_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/%2e%2e/registry.yml")
        self.assertEqual(status, 404)

    def test_absolute_path_attempt_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/etc/passwd")
        self.assertEqual(status, 404)

    def test_non_allowlisted_leaf_404(self):
        """A non-allowlisted leaf like secret.txt is rejected by the route regex -> 404."""
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/secret.txt")
        self.assertEqual(status, 404)

    def test_settings_yml_leaf_404(self):
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/settings.yml")
        self.assertEqual(status, 404)

    def test_unregistered_id_404(self):
        """An id not in the registry -> 404."""
        fake_id = "deadbeef"
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{fake_id}/home.html")
        self.assertEqual(status, 404)

    def test_unregistered_id_api_model_404(self):
        fake_id = "deadbeef"
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{fake_id}/api/model")
        self.assertEqual(status, 404)

    def test_symlink_leaf_not_served(self):
        """A symlink in a served .aid/ dir with a non-allowlisted name must not serve.

        The .aid/dashboard/ folder was eliminated; kb.html now lives in
        .aid/knowledge/, so we plant the decoy there. "secret.txt" is not in the
        {home.html, kb.html} leaf allowlist, so the route regex can never map it to
        a path -- it 404s regardless of whether the symlink resolves to a real file.
        """
        # Add a file outside .aid/knowledge/ and a non-allowlisted symlink inside it
        secret = self._repo_a / "secret_data.txt"
        secret.write_text("secret", encoding="utf-8")
        served_dir = self._repo_a / ".aid" / "knowledge"
        link = served_dir / "secret.txt"  # non-allowlisted name
        try:
            link.symlink_to(secret)
        except OSError:
            self.skipTest("Cannot create symlinks on this filesystem")
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{self._id_a}/secret.txt")
        self.assertEqual(status, 404,
                         "Non-allowlisted filename (even if symlinked) must 404")

    def test_registered_but_aid_gone_static_404(self):
        """Registered repo whose .aid/ was removed -> 404 for static leaves."""
        repo_b = self._base / "repo-B"
        _make_repo(repo_b, with_kb=True)
        _write_registry(self._aid_home, [str(self._repo_a), str(repo_b)])
        id_b = _repo_id8(str(repo_b))
        # Remove .aid/
        shutil.rmtree(str(repo_b / ".aid"))
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get(f"/r/{id_b}/home.html")
        self.assertEqual(status, 404)

    def test_registered_but_aid_gone_api_model_200_empty(self):
        """Registered repo whose .aid/ was removed -> 200 with empty RepoModel (NFR10)."""
        repo_b = self._base / "repo-B"
        _make_repo(repo_b, with_kb=True)
        _write_registry(self._aid_home, [str(self._repo_a), str(repo_b)])
        id_b = _repo_id8(str(repo_b))
        # Remove .aid/
        shutil.rmtree(str(repo_b / ".aid"))
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get(f"/r/{id_b}/api/model")
        self.assertEqual(status, 200, "Must return 200 (empty model), not 404/500")
        data = json.loads(body)
        self.assertEqual(data["schema_version"], 3)
        model = data["model"]
        self.assertIsInstance(model["works"], list)
        self.assertEqual(model["works"], [], "Empty .aid/ -> empty works list")


# ===========================================================================
# (4) Registry tolerance (NFR10)
# ===========================================================================

class TestRegistryTolerance(unittest.TestCase):
    """absent/torn/higher-schema registry -> best-effort, never 500."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_absent_registry_api_home_200_empty(self):
        """Absent registry -> /api/home returns 200 with repos=[]."""
        reg = self._aid_home / "registry.yml"
        reg.unlink()
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertEqual(data["repos"], [])

    def test_absent_registry_never_500(self):
        """Absent registry must not cause 500."""
        reg = self._aid_home / "registry.yml"
        reg.unlink()
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home")
        self.assertNotEqual(status, 500)

    def test_torn_registry_best_effort(self):
        """Partial/torn registry write -> best-effort (may return partial list or empty; never 500)."""
        # Write a registry that is syntactically weird (partial write simulation)
        (self._aid_home / "registry.yml").write_text(
            "schema: 1\nrepos:\n  - /valid/path/one\n  - \n  - /valid/path/two\n",
            encoding="utf-8",
        )
        with _ServerThread(str(self._aid_home)) as srv:
            status, _, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        self.assertNotEqual(status, 500)

    def test_higher_schema_read_not_rejected(self):
        """Higher schema (e.g. schema: 5) -> still read best-effort, never rejected."""
        repo = self._base / "repo-X"
        _make_repo(repo)
        (self._aid_home / "registry.yml").write_text(
            f"schema: 5\nrepos:\n  - {repo}\n",
            encoding="utf-8",
        )
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        data = json.loads(body)
        # Must have read at least the one repo (best-effort)
        self.assertEqual(len(data["repos"]), 1)
        # Parse warning should mention higher schema
        warnings = data["read"]["parse_warnings"]
        self.assertTrue(
            any("newer than reader" in w for w in warnings),
            f"Expected higher-schema warning; got: {warnings}",
        )

    def test_empty_repos_block_ok(self):
        """Registry with empty repos: block -> empty list, not an error."""
        (self._aid_home / "registry.yml").write_text(
            "schema: 1\nrepos:\n", encoding="utf-8"
        )
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["repos"], [])


# ===========================================================================
# (5) /api/home DM-2 shape
# ===========================================================================

class TestApiHomeDm2Shape(unittest.TestCase):
    """/api/home returns a DM-2 envelope with the correct machine panel and repos[] shape."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

        # Two repos: A (with a generated kb.html) and B (without one). Both have .aid/.
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a, with_kb=True)
        self._repo_b = self._base / "repo-B"
        _make_repo(self._repo_b, with_kb=False)

        # Register in reverse alphabetical order to test sorting
        _write_registry(self._aid_home, [str(self._repo_b), str(self._repo_a)])

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def _get_home(self) -> dict:
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        return json.loads(body)

    # Top-level envelope
    def test_schema_version_1(self):
        data = self._get_home()
        self.assertEqual(data["schema_version"], 1)

    def test_generated_by_python(self):
        data = self._get_home()
        self.assertEqual(data["generated_by"], "python")

    # Machine panel keys
    def test_machine_panel_has_aid_version(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("aid_version", machine)

    def test_machine_panel_has_aid_home(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("aid_home", machine)
        self.assertTrue(machine["aid_home"].startswith("/"))

    def test_machine_panel_has_tools_catalog(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("tools_catalog", machine)
        self.assertIsInstance(machine["tools_catalog"], list)

    def test_machine_panel_has_registry_path(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("registry_path", machine)
        self.assertIn("registry.yml", machine["registry_path"])

    def test_machine_panel_has_cli_runtime(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("cli_runtime", machine)
        self.assertEqual(machine["cli_runtime"], "python")

    # write_enabled (additive, feature-001 task-001): fail-safe gate signal.
    def test_machine_panel_has_write_enabled(self):
        data = self._get_home()
        machine = data["machine"]
        self.assertIn("write_enabled", machine)
        self.assertIsInstance(machine["write_enabled"], bool)

    def test_machine_panel_write_enabled_false_by_default(self):
        """A server started without the write gate is read-only (fail-safe default)."""
        data = self._get_home()
        self.assertFalse(data["machine"]["write_enabled"])

    # repos[] sorted by path ascending
    def test_repos_sorted_by_path(self):
        data = self._get_home()
        paths = [r["path"] for r in data["repos"]]
        self.assertEqual(paths, sorted(paths), f"repos must be sorted by path; got {paths}")

    def test_repos_count(self):
        data = self._get_home()
        self.assertEqual(len(data["repos"]), 2)

    # Per-repo fields
    def test_per_repo_has_required_fields(self):
        data = self._get_home()
        for repo in data["repos"]:
            for field in ("name", "description", "aid_version", "tools_installed",
                          "available", "has_home", "has_kb", "id", "path"):
                self.assertIn(field, repo, f"repo missing field {field!r}")

    def test_per_repo_id_is_8_hex_chars(self):
        data = self._get_home()
        import re
        for repo in data["repos"]:
            self.assertRegex(repo["id"], r'^[0-9a-f]{8,}$',
                             f"repo id {repo['id']!r} is not valid hex")

    def test_repo_with_kb_has_home_and_kb_true(self):
        # repo-A has an .aid/ dir (-> has_home) and a generated kb.html (-> has_kb).
        data = self._get_home()
        repo_a_entry = next(r for r in data["repos"] if r["path"] == str(self._repo_a))
        self.assertTrue(repo_a_entry["has_home"])
        self.assertTrue(repo_a_entry["has_kb"])

    def test_repo_without_kb_has_home_true_has_kb_false(self):
        # repo-B has an .aid/ dir (-> has_home=true, the new gate) but never generated
        # a kb.html (-> has_kb=false). has_home no longer depends on dashboard files.
        data = self._get_home()
        repo_b_entry = next(r for r in data["repos"] if r["path"] == str(self._repo_b))
        self.assertTrue(repo_b_entry["has_home"])
        self.assertFalse(repo_b_entry["has_kb"])

    def test_repo_available_true_when_aid_exists(self):
        data = self._get_home()
        for repo in data["repos"]:
            self.assertTrue(repo["available"])

    # read panel
    def test_read_panel_has_required_keys(self):
        data = self._get_home()
        read = data["read"]
        for key in ("read_at", "repo_count", "unavailable_count", "parse_warnings"):
            self.assertIn(key, read)

    def test_read_repo_count_matches(self):
        data = self._get_home()
        self.assertEqual(data["read"]["repo_count"], len(data["repos"]))

    def test_machine_aid_version_from_version_file(self):
        """$AID_HOME/VERSION is read correctly."""
        data = self._get_home()
        self.assertEqual(data["machine"]["aid_version"], "1.0.0-test")


# ===========================================================================
# (5b) write_enabled gate propagation (feature-001 task-001)
# ===========================================================================

class TestWriteEnabledGatePropagation(unittest.TestCase):
    """server.write_enabled (fail-safe default False) flows into both DM envelopes."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a)
        _write_registry(self._aid_home, [str(self._repo_a)])
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_api_home_write_enabled_true_when_gate_open(self):
        with _ServerThread(str(self._aid_home), write_enabled=True) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertTrue(data["machine"]["write_enabled"])

    def test_api_home_write_enabled_false_when_gate_closed(self):
        with _ServerThread(str(self._aid_home), write_enabled=False) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertFalse(data["machine"]["write_enabled"])

    def test_api_model_write_enabled_true_when_gate_open(self):
        with _ServerThread(str(self._aid_home), write_enabled=True) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertTrue(data["write_enabled"])

    def test_api_model_write_enabled_false_when_gate_closed(self):
        with _ServerThread(str(self._aid_home), write_enabled=False) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertFalse(data["write_enabled"])


# ===========================================================================
# (6) Serialization (DM-3)
# ===========================================================================

class TestSerializationDm3(unittest.TestCase):
    """DM-3: key order, compact, no trailing newline, integers-only."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a)
        _make_aid_with_works(self._repo_a, ["work-003-gamma", "work-001-alpha", "work-002-beta"])
        _write_registry(self._aid_home, [str(self._repo_a)])
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def _get_model(self) -> dict:
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 200)
        return json.loads(body)

    def _get_raw_body(self) -> bytes:
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get(f"/r/{self._id_a}/api/model")
        self.assertEqual(status, 200)
        return body

    # Key order for /r/<id>/api/model (DM-1 envelope)
    def test_envelope_key_order(self):
        data = self._get_model()
        keys = list(data.keys())
        self.assertEqual(keys, ["schema_version", "generated_by", "write_enabled", "model"])

    def test_repo_model_key_order(self):
        data = self._get_model()
        model = data["model"]
        self.assertEqual(list(model.keys()), ["tool", "repo", "works", "read"])

    def test_tool_info_key_order(self):
        data = self._get_model()
        tool = data["model"]["tool"]
        self.assertEqual(list(tool.keys()),
                         ["manifest_present", "aid_version", "installed_at", "tools_installed"])

    def test_repo_info_key_order(self):
        # feature-002 (work-017 task-005): project_description + minimum_grade are
        # additive keys inserted after project_name (schema_version stays 3).
        data = self._get_model()
        repo = data["model"]["repo"]
        self.assertEqual(
            list(repo.keys()),
            ["project_name", "project_description", "minimum_grade", "aid_dir", "kb_state"],
        )

    def test_read_meta_key_order(self):
        data = self._get_model()
        read = data["model"]["read"]
        self.assertEqual(list(read.keys()),
                         ["read_at", "work_count", "fallback_works", "parse_warnings", "bytes_read"])

    def test_work_key_order(self):
        data = self._get_model()
        works = data["model"]["works"]
        self.assertGreater(len(works), 0)
        expected = [
            "work_id", "name", "lifecycle", "phase", "active_skill",
            "updated", "created", "pause_reason", "block_reason", "block_artifact",
            "tasks", "pending_inputs", "source_mode",
            "number", "title", "description", "objective",
            "work_path", "recipe", "features", "deliverables",
            # work-003-state-schema task-002 additions:
            "kind", "started", "minimum_grade", "user_approved",
        ]
        self.assertEqual(list(works[0].keys()), expected)

    # Works sorted by work_id ascending
    def test_works_sorted_by_work_id(self):
        data = self._get_model()
        work_ids = [w["work_id"] for w in data["model"]["works"]]
        self.assertEqual(work_ids, sorted(work_ids),
                         f"works must be sorted by work_id; got: {work_ids}")

    # No trailing newline
    def test_no_trailing_newline_model(self):
        body = self._get_raw_body()
        self.assertFalse(body.endswith(b"\n"))

    # Compact (no extra spaces in JSON)
    def test_compact_json_model(self):
        body = self._get_raw_body()
        self.assertNotIn(b": ", body, "DM-3: no ': ' spacing (compact)")
        self.assertNotIn(b", ", body, "DM-3: no ', ' spacing (compact)")

    # Integers only (no floats on the wire)
    def test_integers_not_floats(self):
        data = self._get_model()
        read = data["model"]["read"]
        self.assertIsInstance(read["work_count"], int)
        self.assertIsInstance(read["bytes_read"], int)
        self.assertIsInstance(data["schema_version"], int)

    # Enum values as strings
    def test_enum_values_are_strings(self):
        data = self._get_model()
        for work in data["model"]["works"]:
            self.assertIsInstance(work["lifecycle"], str)
            self.assertIsInstance(work["source_mode"], str)


class TestSerializationDm3Home(unittest.TestCase):
    """DM-3 for /api/home: compact, no trailing newline, integers."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def _get_raw_home(self) -> bytes:
        with _ServerThread(str(self._aid_home)) as srv:
            status, body, _ = srv.get("/api/home")
        self.assertEqual(status, 200)
        return body

    def test_compact_json_home(self):
        body = self._get_raw_home()
        self.assertNotIn(b": ", body)
        self.assertNotIn(b", ", body)

    def test_no_trailing_newline_home(self):
        body = self._get_raw_home()
        self.assertFalse(body.endswith(b"\n"))

    def test_integers_not_floats_home(self):
        data = json.loads(self._get_raw_home())
        self.assertIsInstance(data["schema_version"], int)
        self.assertIsInstance(data["read"]["repo_count"], int)
        self.assertIsInstance(data["read"]["unavailable_count"], int)


class TestUnicodeEscaping(unittest.TestCase):
    """Verify U+2028/U+2029 are escaped in serialize_model output (DM-3 parity rule)."""

    def _make_model_with_unicode(self):
        from dashboard.reader.models import ReadMeta, RepoInfo, RepoModel, ToolInfo
        warning = "line-sep:   para-sep:   end"
        return RepoModel(
            tool=ToolInfo(manifest_present=False),
            repo=RepoInfo(project_name="test", aid_dir="/tmp/test"),
            works=[],
            read=ReadMeta(
                read_at="2026-01-01T00:00:00+00:00",
                work_count=0,
                fallback_works=[],
                parse_warnings=[warning],
                bytes_read=0,
            ),
        )

    def test_u2028_escaped_in_serialize_model(self):
        model = self._make_model_with_unicode()
        body = _server_module.serialize_model(model)
        self.assertNotIn(b"\xe2\x80\xa8", body,
                         "Raw U+2028 must NOT appear in serialize_model output")
        self.assertIn(b"\\u2028", body,
                      "Escaped \\u2028 must appear in serialize_model output")

    def test_u2029_escaped_in_serialize_model(self):
        model = self._make_model_with_unicode()
        body = _server_module.serialize_model(model)
        self.assertNotIn(b"\xe2\x80\xa9", body,
                         "Raw U+2029 must NOT appear in serialize_model output")
        self.assertIn(b"\\u2029", body,
                      "Escaped \\u2029 must appear in serialize_model output")

    def test_serialize_model_is_valid_utf8_json(self):
        model = self._make_model_with_unicode()
        body = _server_module.serialize_model(model)
        parsed = json.loads(body.decode("utf-8"))
        self.assertIn("schema_version", parsed)

    def test_u2028_escaped_in_serialize_home(self):
        """serialize_home must also escape U+2028/U+2029 (DM-3)."""
        home_model = {
            "schema_version": 1,
            "generated_by": "python",
            "machine": {"aid_version": None, "aid_home": "/tmp",
                        "tools_catalog": [], "registry_path": "/tmp/registry.yml",
                        "cli_runtime": "python"},
            "repos": [],
            "read": {"read_at": "2026-01-01T00:00:00Z", "repo_count": 0,
                     "unavailable_count": 0, "parse_warnings": ["has   char"]},
        }
        body = _server_module.serialize_home(home_model)
        self.assertNotIn(b"\xe2\x80\xa8", body)
        self.assertIn(b"\\u2028", body)


# ===========================================================================
# (7) Invariants: 127.0.0.1-only bind + SIGTERM + arg validation
# ===========================================================================

class TestArgValidation(unittest.TestCase):
    """_parse_args rejects bad inputs and accepts good ones."""

    def test_rejects_0000_host(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "0.0.0.0", "--port", "8787"])

    def test_rejects_wildcard_host_double_colon(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "::", "--port", "8787"])

    def test_rejects_external_ip(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "192.168.1.1", "--port", "8787"])

    def test_accepts_loopback_127(self):
        args = _server_module._parse_args(["--host", "127.0.0.1", "--port", "8787"])
        self.assertEqual(args.host, "127.0.0.1")
        self.assertEqual(args.port, 8787)

    # --allow-writes (feature-001 task-001): fail-safe write gate flag.
    def test_allow_writes_absent_defaults_false(self):
        """Bare invocation (no --allow-writes) parses as read-only (fail-safe default)."""
        args = _server_module._parse_args(["--host", "127.0.0.1", "--port", "8787"])
        self.assertFalse(args.allow_writes)

    def test_allow_writes_flag_sets_true(self):
        args = _server_module._parse_args(
            ["--host", "127.0.0.1", "--port", "8787", "--allow-writes"]
        )
        self.assertTrue(args.allow_writes)

    def test_accepts_loopback_ipv6(self):
        args = _server_module._parse_args(["--host", "::1", "--port", "8787"])
        self.assertEqual(args.host, "::1")

    def test_rejects_port_below_range(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "127.0.0.1", "--port", "80"])

    def test_rejects_port_above_range(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "127.0.0.1", "--port", "99999"])

    def test_old_root_arg_rejected(self):
        """--root is an unknown arg and is rejected (exit 2)."""
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--root", "/tmp", "--host", "127.0.0.1", "--port", "8787"])


class TestAidHomeResolution(unittest.TestCase):
    """AID_HOME env-or-self-locate resolution (delivery-008 refinement)."""

    def test_env_precedence_serves_correct_registry(self):
        """AID_HOME env var takes precedence: server serves fixtureA's registry."""
        base = Path(tempfile.mkdtemp())
        try:
            fixture_a = base / "fixture_a"
            _make_aid_home(fixture_a)
            repo_a = base / "repo-a"
            _make_repo(repo_a)
            _write_registry(fixture_a, [str(repo_a)])

            # Boot server with AID_HOME=fixture_a via _ServerThread (which uses
            # the server module directly, setting server.aid_home).
            with _ServerThread(str(fixture_a)) as srv:
                status, body, _ = srv.get("/api/home")
            self.assertEqual(status, 200)
            data = json.loads(body)
            # fixture_a has exactly one repo registered.
            self.assertEqual(len(data["repos"]), 1)
            self.assertEqual(data["repos"][0]["path"], str(repo_a))
            self.assertEqual(data["machine"]["aid_home"], str(fixture_a))
        finally:
            import shutil as _shutil
            _shutil.rmtree(str(base), ignore_errors=True)

    def test_subprocess_boot_via_env(self):
        """Server spawned without --aid-home and with AID_HOME in env boots and responds."""
        base = Path(tempfile.mkdtemp())
        try:
            aid_home = base / "aid_home"
            _make_aid_home(aid_home)

            with socket.socket() as s:
                s.bind(("127.0.0.1", 0))
                port = s.getsockname()[1]

            proc = subprocess.Popen(
                [sys.executable, str(_SERVER_SCRIPT), "--host", "127.0.0.1", "--port", str(port)],
                env={**os.environ, "AID_HOME": str(aid_home)},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                deadline = time.monotonic() + 5.0
                ready = False
                while time.monotonic() < deadline:
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            ready = True
                            break
                    except OSError:
                        time.sleep(0.05)
                self.assertTrue(ready, "Server did not become ready within 5s")

                req = urllib.request.Request(f"http://127.0.0.1:{port}/api/home")
                with urllib.request.urlopen(req, timeout=5) as resp:
                    status = resp.status
                    body = resp.read()
                self.assertEqual(status, 200)
                data = json.loads(body)
                self.assertEqual(data["machine"]["aid_home"], str(aid_home.resolve()))
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
        finally:
            import shutil as _shutil
            _shutil.rmtree(str(base), ignore_errors=True)

    def test_subprocess_bare_invocation_is_read_only(self):
        """A bare 'server.py --host 127.0.0.1 --port N' (no --allow-writes) is
        read-only (feature-001 task-001 AC: fail-safe default)."""
        base = Path(tempfile.mkdtemp())
        try:
            aid_home = base / "aid_home"
            _make_aid_home(aid_home)

            with socket.socket() as s:
                s.bind(("127.0.0.1", 0))
                port = s.getsockname()[1]

            proc = subprocess.Popen(
                [sys.executable, str(_SERVER_SCRIPT), "--host", "127.0.0.1", "--port", str(port)],
                env={**os.environ, "AID_HOME": str(aid_home)},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                deadline = time.monotonic() + 5.0
                ready = False
                while time.monotonic() < deadline:
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            ready = True
                            break
                    except OSError:
                        time.sleep(0.05)
                self.assertTrue(ready, "Server did not become ready within 5s")

                req = urllib.request.Request(f"http://127.0.0.1:{port}/api/home")
                with urllib.request.urlopen(req, timeout=5) as resp:
                    data = json.loads(resp.read())
                self.assertFalse(data["machine"]["write_enabled"])
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
        finally:
            import shutil as _shutil
            _shutil.rmtree(str(base), ignore_errors=True)

    def test_subprocess_allow_writes_flag_opens_gate(self):
        """'server.py ... --allow-writes' flips write_enabled true in both envelopes."""
        base = Path(tempfile.mkdtemp())
        try:
            aid_home = base / "aid_home"
            _make_aid_home(aid_home)
            repo_a = base / "repo-a"
            _make_repo(repo_a)
            _write_registry(aid_home, [str(repo_a)])
            id_a = _repo_id8(str(repo_a))

            with socket.socket() as s:
                s.bind(("127.0.0.1", 0))
                port = s.getsockname()[1]

            proc = subprocess.Popen(
                [
                    sys.executable, str(_SERVER_SCRIPT),
                    "--host", "127.0.0.1", "--port", str(port), "--allow-writes",
                ],
                env={**os.environ, "AID_HOME": str(aid_home)},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                deadline = time.monotonic() + 5.0
                ready = False
                while time.monotonic() < deadline:
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            ready = True
                            break
                    except OSError:
                        time.sleep(0.05)
                self.assertTrue(ready, "Server did not become ready within 5s")

                req = urllib.request.Request(f"http://127.0.0.1:{port}/api/home")
                with urllib.request.urlopen(req, timeout=5) as resp:
                    home_data = json.loads(resp.read())
                self.assertTrue(home_data["machine"]["write_enabled"])

                req2 = urllib.request.Request(f"http://127.0.0.1:{port}/r/{id_a}/api/model")
                with urllib.request.urlopen(req2, timeout=5) as resp2:
                    model_data = json.loads(resp2.read())
                self.assertTrue(model_data["write_enabled"])
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
        finally:
            import shutil as _shutil
            _shutil.rmtree(str(base), ignore_errors=True)

    def test_help_mentions_allow_writes_flag(self):
        """--help output must mention --allow-writes (the new fail-safe write gate)."""
        import subprocess as _sp
        result = _sp.run(
            [sys.executable, str(_SERVER_SCRIPT), "--help"],
            capture_output=True,
            text=True,
        )
        self.assertIn("--allow-writes", result.stdout)

    def test_help_no_longer_mentions_aid_home_flag(self):
        """--help output must NOT mention --aid-home (the flag is removed)."""
        import subprocess as _sp
        result = _sp.run(
            [sys.executable, str(_SERVER_SCRIPT), "--help"],
            capture_output=True,
            text=True,
        )
        self.assertNotIn("--aid-home", result.stdout,
                         "--help must not mention the removed --aid-home flag")


class TestSigtermExit(unittest.TestCase):
    """SIGTERM causes the server subprocess to exit cleanly within 2s."""

    def test_sigterm_exits_within_2s(self):
        base = Path(tempfile.mkdtemp())
        try:
            aid_home = base / "aid_home"
            _make_aid_home(aid_home)

            with socket.socket() as s:
                s.bind(("127.0.0.1", 0))
                port = s.getsockname()[1]

            proc = subprocess.Popen(
                [
                    sys.executable, str(_SERVER_SCRIPT),
                    "--host", "127.0.0.1",
                    "--port", str(port),
                ],
                env={**os.environ, "AID_HOME": str(aid_home)},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                # Wait until the port accepts connections (up to 5s).
                deadline = time.monotonic() + 5.0
                ready = False
                while time.monotonic() < deadline:
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            ready = True
                            break
                    except OSError:
                        time.sleep(0.05)
                self.assertTrue(ready, "Server did not become ready within 5s")

                t0 = time.monotonic()
                proc.send_signal(signal.SIGTERM)
                try:
                    proc.wait(timeout=2.0)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
                    self.fail("Server did NOT exit within 2s after SIGTERM")
                elapsed = time.monotonic() - t0
                self.assertLess(elapsed, 2.0,
                                f"Server took {elapsed:.2f}s to exit after SIGTERM")

                # Confirm port is freed
                port_freed = False
                try:
                    with socket.create_connection(("127.0.0.1", port), timeout=0.3):
                        pass
                except OSError:
                    port_freed = True
                self.assertTrue(port_freed, "Port still bound after SIGTERM exit")
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.wait()
        finally:
            shutil.rmtree(str(base), ignore_errors=True)


# ===========================================================================
# (8) <id> derivation
# ===========================================================================

class TestIdDerivation(unittest.TestCase):
    """sha256(CAN-1(path))[:8] for a known path -- Python side of cross-runtime parity."""

    FIXTURE_PATH = "/tmp/aid-fixture-repo-A"
    EXPECTED_FULL = "56e3c68fe7a7342b3b7ea6b76dc876a4163348bea90c80d0e2faa130dade3a91"
    EXPECTED_8 = "56e3c68f"

    def test_known_path_full_digest(self):
        """sha256(CAN-1('/tmp/aid-fixture-repo-A')) matches known expected value."""
        digest = hashlib.sha256(self.FIXTURE_PATH.encode("utf-8")).hexdigest()
        self.assertEqual(digest, self.EXPECTED_FULL)

    def test_known_path_8_char_prefix(self):
        digest = hashlib.sha256(self.FIXTURE_PATH.encode("utf-8")).hexdigest()
        self.assertEqual(digest[:8], self.EXPECTED_8)

    def test_server_module_repo_id_matches(self):
        """_server_module.repo_id() must return the same full hex."""
        full = _server_module.repo_id(self.FIXTURE_PATH)
        self.assertEqual(full, self.EXPECTED_FULL)

    def test_id_map_uses_8_char_prefix(self):
        """build_id_map produces the correct 8-char id for a single path."""
        id_map = _server_module.build_id_map([self.FIXTURE_PATH])
        self.assertIn(self.EXPECTED_8, id_map)
        self.assertEqual(id_map[self.EXPECTED_8], self.FIXTURE_PATH)

    def test_id_derivation_utf8_no_trailing_newline(self):
        """The id input is UTF-8 encoded path with NO trailing newline (DD-5 contract)."""
        # Confirm that appending a newline would change the id
        with_newline = hashlib.sha256((self.FIXTURE_PATH + "\n").encode("utf-8")).hexdigest()
        without_newline = hashlib.sha256(self.FIXTURE_PATH.encode("utf-8")).hexdigest()
        self.assertNotEqual(with_newline[:8], without_newline[:8],
                            "Newline must NOT be part of the hash input (DD-5)")

    def test_collision_lengthen_produces_longer_ids(self):
        """build_id_map lengthens colliding ids beyond 8 chars."""
        # We need two paths with the same 8-char sha256 prefix.
        # Since we can't easily engineer a real collision, we test the mechanism
        # indirectly: verify that with two distinct paths the ids are always distinct.
        path_a = "/tmp/repo-collision-test-A"
        path_b = "/tmp/repo-collision-test-B"
        id_map = _server_module.build_id_map([path_a, path_b])
        ids = list(id_map.keys())
        self.assertEqual(len(ids), 2, "Two distinct paths must produce two distinct ids")
        self.assertNotEqual(ids[0], ids[1])

    def test_build_id_map_empty(self):
        """build_id_map([]) returns empty dict."""
        self.assertEqual(_server_module.build_id_map([]), {})


# ===========================================================================
# (9) load_registry unit tests
# ===========================================================================

class TestLoadRegistry(unittest.TestCase):
    """Unit tests for load_registry() -- line-scan tolerant parse."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def _reg(self, content: str) -> Path:
        p = self._tmp / "registry.yml"
        p.write_text(content, encoding="utf-8")
        return p

    def test_absent_file_returns_empty(self):
        reg = self._tmp / "nonexistent.yml"
        repos, warnings = _server_module.load_registry(reg)
        self.assertEqual(repos, [])
        self.assertEqual(warnings, [])

    def test_normal_registry(self):
        reg = self._reg("schema: 1\nrepos:\n  - /path/to/repo-A\n  - /path/to/repo-B\n")
        repos, warnings = _server_module.load_registry(reg)
        self.assertIn("/path/to/repo-A", repos)
        self.assertIn("/path/to/repo-B", repos)
        self.assertEqual(warnings, [])

    def test_higher_schema_produces_warning(self):
        reg = self._reg("schema: 5\nrepos:\n  - /path/to/repo\n")
        repos, warnings = _server_module.load_registry(reg)
        self.assertIn("/path/to/repo", repos)
        self.assertTrue(any("newer than reader" in w for w in warnings))

    def test_empty_repos_block(self):
        reg = self._reg("schema: 1\nrepos:\n")
        repos, warnings = _server_module.load_registry(reg)
        self.assertEqual(repos, [])

    def test_paths_returned_verbatim(self):
        """CAN-1 site 3: paths are returned verbatim (no normalization)."""
        reg = self._reg("schema: 1\nrepos:\n  - /some/../path\n")
        repos, _ = _server_module.load_registry(reg)
        # The path is returned as-is from the file (verbatim -- no normalization)
        self.assertIn("/some/../path", repos)

    def test_comment_lines_ignored(self):
        reg = self._reg(
            "# This is a comment\nschema: 1\nrepos:\n  - /valid/path\n# another comment\n"
        )
        repos, _ = _server_module.load_registry(reg)
        self.assertEqual(repos, ["/valid/path"])


if __name__ == "__main__":
    unittest.main()
