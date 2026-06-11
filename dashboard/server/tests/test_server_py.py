"""
test_server_py.py -- Self-check and behavioral tests for dashboard/server/server.py
                     (feature-003, task-016).

Assertions:
  (a) Source contains no 0.0.0.0/wildcard bind token (LC-S bind-address invariant).
  (b) Source contains no write/append/remove primitive and no agent/LLM import (NFR2/NFR7).
  (c) GET /api/model returns the DM-1 envelope (schema_version:1, generated_by:"python",
      model with works sorted by work_id).
  (d) GET on an unknown path -> 404; POST -> 405.
  (e) U+2028/U+2029 post-process: both chars are escaped in the JSON output.
  (f) works array is sorted by work_id ascending (DM-3).

All tests are deterministic, use temp-dir .aid fixtures, and stop the server cleanly.
Python 3.11+ stdlib only. Zero third-party deps.
"""

import json
import os
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

# Make dashboard package importable regardless of working directory.
_REPO_ROOT = Path(__file__).resolve().parents[4]  # AID/
_DASHBOARD_DIR = Path(__file__).resolve().parents[3]  # AID/dashboard/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as _server_module


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

def _make_minimal_aid(root: Path) -> None:
    """Create a minimal .aid/ structure so read_repo() returns a real model."""
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    settings = aid / "settings.yml"
    settings.write_text("project:\n  name: test-project\n", encoding="utf-8")


def _make_aid_with_works(root: Path, work_ids: list) -> None:
    """Create .aid/ with multiple work folders in a non-sorted order on disk."""
    _make_minimal_aid(root)
    aid = root / ".aid"
    for wid in work_ids:
        wdir = aid / wid
        wdir.mkdir(parents=True, exist_ok=True)
        state = wdir / "STATE.md"
        state.write_text(
            "# Work State\n\n## Pipeline Status\n\nLifecycle: Running\n\n"
            "## Tasks Status\n\n| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- |\n",
            encoding="utf-8",
        )




class _ServerThread:
    """Context manager that starts the server in a background thread and stops it."""

    def __init__(self, aid_root: str) -> None:
        self._aid_root = aid_root
        self._httpd = None
        self._thread = None
        self.port = None

    def __enter__(self) -> "_ServerThread":
        import socket
        # Pick a free port
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            self.port = s.getsockname()[1]

        self._httpd = _server_module.ThreadingHTTPServer(
            ("127.0.0.1", self.port), _server_module._DashboardHandler
        )
        self._httpd.aid_root = self._aid_root
        self._thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        self._thread.start()
        # Wait until the port is accepting
        self._wait_ready()
        return self

    def _wait_ready(self) -> None:
        import socket
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

    def get(self, path: str) -> tuple:
        """Return (status_code, body_bytes, headers)."""
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url)
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read(), dict(resp.headers)
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read(), {}

    def post(self, path: str) -> tuple:
        """Return (status_code, body_bytes)."""
        url = f"http://127.0.0.1:{self.port}{path}"
        req = urllib.request.Request(url, data=b"", method="POST")
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()


# ---------------------------------------------------------------------------
# Tests: source-level invariants (a) and (b)
# ---------------------------------------------------------------------------

class TestSourceInvariants(unittest.TestCase):
    """Grep-level self-checks on server.py source (mirrors feature-002 reader pattern)."""

    @classmethod
    def setUpClass(cls):
        src_path = Path(_server_module.__file__).resolve()
        cls.source = src_path.read_text(encoding="utf-8")

    # (a) No wildcard bind token
    def test_no_wildcard_bind_0000(self):
        self.assertNotIn("0.0.0.0", self.source,
                         "server.py MUST NOT contain the literal 0.0.0.0")

    def test_no_inaddr_any(self):
        self.assertNotIn("INADDR_ANY", self.source,
                         "server.py MUST NOT reference INADDR_ANY")

    def test_no_double_colon_bind(self):
        # '::' as a bind address (not as a slice or annotation)
        # We check for the specific string patterns that would constitute a wildcard bind.
        # Slice/type-annotation '::' is fine; bind('::') is the forbidden pattern.
        self.assertNotIn('(":: "', self.source)
        self.assertNotIn("('::'", self.source)
        self.assertNotIn('("::", ', self.source)

    # (b) No write/append/remove primitive
    def test_no_open_write(self):
        self.assertNotIn('open(', self.source.replace("# ", ""),
                         "server.py must not use open() (read index.html via Path.read_bytes only)")

    def test_no_os_remove(self):
        self.assertNotIn("os.remove", self.source)
        self.assertNotIn("os.unlink", self.source)

    def test_no_shutil_write(self):
        self.assertNotIn("shutil", self.source)

    def test_no_write_flag(self):
        # No open(..., 'w') or open(..., 'a') or open(..., 'wb') or open(..., 'ab')
        import re
        matches = re.findall(r"open\s*\(.*?['\"][wWaA][bB+]?['\"]", self.source)
        self.assertEqual(matches, [],
                         f"server.py must not open files for writing; found: {matches}")

    # (b) No agent/LLM import
    def test_no_anthropic_import(self):
        self.assertNotIn("anthropic", self.source)

    def test_no_openai_import(self):
        self.assertNotIn("openai", self.source)

    def test_no_agent_dispatch_import(self):
        self.assertNotIn("agent_dispatch", self.source)
        self.assertNotIn("agent-dispatch", self.source)


# ---------------------------------------------------------------------------
# Tests: route behavior (c) and (d)
# ---------------------------------------------------------------------------

class TestRoutes(unittest.TestCase):
    """Behavioral tests for the server's HTTP routes."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        _make_minimal_aid(Path(self._tmpdir))

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    # (c) GET /api/model returns DM-1 envelope
    def test_api_model_200(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get("/api/model")
        self.assertEqual(status, 200)

    def test_api_model_content_type(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get("/api/model")
        ct = headers.get("Content-Type", "")
        self.assertIn("application/json", ct)
        self.assertIn("utf-8", ct)

    def test_api_model_envelope_schema_version(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        data = json.loads(body)
        self.assertEqual(data.get("schema_version"), 1)

    def test_api_model_envelope_generated_by(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        data = json.loads(body)
        self.assertEqual(data.get("generated_by"), "python")

    def test_api_model_has_model_key(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        data = json.loads(body)
        self.assertIn("model", data)

    def test_api_model_model_has_required_keys(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        model = json.loads(body)["model"]
        for key in ("tool", "repo", "works", "read"):
            self.assertIn(key, model)

    def test_api_model_no_trailing_newline(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        self.assertFalse(body.endswith(b"\n"),
                         "DM-3: no trailing newline in JSON output")

    # (d) Unknown path -> 404; POST -> 405
    def test_unknown_path_404(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/no/such/path")
        self.assertEqual(status, 404)

    def test_api_unknown_subpath_404(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/other")
        self.assertEqual(status, 404)

    def test_post_405(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body = srv.post("/api/model")
        self.assertEqual(status, 405)

    def test_post_root_405(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body = srv.post("/")
        self.assertEqual(status, 405)

    # GET / -> 404 when index.html absent (task-019 builds it), not a server error
    def test_root_404_when_no_index(self):
        # index.html is NOT present in our test fixture
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/")
        self.assertIn(status, (200, 404),
                      "GET / must return 200 (if index.html present) or 404 (if absent)")


# ---------------------------------------------------------------------------
# Tests: works sorted by work_id (f)
# ---------------------------------------------------------------------------

class TestWorksSorted(unittest.TestCase):
    """Verify that works in /api/model are sorted by work_id ascending (DM-3)."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        # Create works in reverse sort order so an unsorted impl would fail
        _make_aid_with_works(Path(self._tmpdir), [
            "work-003-gamma",
            "work-001-alpha",
            "work-002-beta",
        ])

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_works_sorted_by_work_id(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        self.assertEqual(status, 200)
        model = json.loads(body)["model"]
        work_ids = [w["work_id"] for w in model["works"]]
        self.assertEqual(work_ids, sorted(work_ids),
                         f"works must be sorted by work_id; got: {work_ids}")


# ---------------------------------------------------------------------------
# Tests: U+2028/U+2029 post-processing (e)
# ---------------------------------------------------------------------------

class TestUnicodeEscaping(unittest.TestCase):
    """Verify U+2028/U+2029 are escaped in serialize_model output (DM-3 parity rule).

    We inject U+2028/U+2029 directly into a RepoModel parse_warnings string and call
    serialize_model() directly.  We do NOT rely on YAML settings.yml because YAML parsers
    treat U+2028/U+2029 as line-break characters, stripping them before they reach the model.
    """

    def _make_model_with_unicode(self):
        """Return a RepoModel whose parse_warnings contain U+2028 and U+2029."""
        from dashboard.reader.models import ReadMeta, RepoInfo, RepoModel, ToolInfo
        # Build warning string with actual U+2028 and U+2029 chars using Python unicode escapes
        warning = "line-sep: \u2028 para-sep: \u2029 end"
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
        # Raw U+2028 in UTF-8: e2 80 a8 -- must NOT appear in output
        self.assertNotIn(b"\xe2\x80\xa8", body,
                         "Raw U+2028 must NOT appear in serialize_model output")
        # Escaped form \u2028 (6 ASCII chars) must appear
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
        text = body.decode("utf-8")
        parsed = json.loads(text)
        self.assertIn("schema_version", parsed)


# ---------------------------------------------------------------------------
# Tests: serialization shape (key order, DM-3)
# ---------------------------------------------------------------------------

class TestSerializationShape(unittest.TestCase):
    """Verify key order matches declared field order from models.py."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        _make_aid_with_works(Path(self._tmpdir), ["work-001-test"])

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _get_model(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get("/api/model")
        return json.loads(body)

    def test_repo_model_key_order(self):
        data = self._get_model()
        model = data["model"]
        keys = list(model.keys())
        self.assertEqual(keys, ["tool", "repo", "works", "read"])

    def test_tool_info_key_order(self):
        data = self._get_model()
        tool = data["model"]["tool"]
        keys = list(tool.keys())
        self.assertEqual(keys, ["manifest_present", "aid_version", "installed_at", "tools_installed"])

    def test_repo_info_key_order(self):
        data = self._get_model()
        repo = data["model"]["repo"]
        keys = list(repo.keys())
        self.assertEqual(keys, ["project_name", "aid_dir", "kb_state"])

    def test_read_meta_key_order(self):
        data = self._get_model()
        read = data["model"]["read"]
        keys = list(read.keys())
        self.assertEqual(keys, ["read_at", "work_count", "fallback_works", "parse_warnings", "bytes_read"])

    def test_work_model_key_order(self):
        data = self._get_model()
        works = data["model"]["works"]
        self.assertTrue(len(works) > 0, "Expected at least one work")
        work_keys = list(works[0].keys())
        expected = [
            "work_id", "name", "lifecycle", "phase", "active_skill",
            "updated", "pause_reason", "block_reason", "block_artifact",
            "tasks", "pending_inputs", "source_mode",
        ]
        self.assertEqual(work_keys, expected)

    def test_numbers_are_integers(self):
        """DM-3: no floats on the wire."""
        data = self._get_model()
        read = data["model"]["read"]
        self.assertIsInstance(read["work_count"], int)
        self.assertIsInstance(read["bytes_read"], int)
        self.assertIsInstance(data["schema_version"], int)

    def test_enum_values_are_strings(self):
        """Lifecycle and TaskStatus must serialize as their .value strings."""
        data = self._get_model()
        for work in data["model"]["works"]:
            self.assertIsInstance(work["lifecycle"], str)
            self.assertIsInstance(work["source_mode"], str)


# ---------------------------------------------------------------------------
# Tests: arg validation
# ---------------------------------------------------------------------------

class TestArgValidation(unittest.TestCase):
    """Verify _parse_args rejects bad inputs."""

    def test_rejects_0000_host(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--root", "/tmp", "--host", "0.0.0.0", "--port", "8787"])

    def test_rejects_wildcard_host(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--root", "/tmp", "--host", "::", "--port", "8787"])

    def test_accepts_loopback(self):
        args = _server_module._parse_args(["--root", "/tmp", "--host", "127.0.0.1", "--port", "8787"])
        self.assertEqual(args.host, "127.0.0.1")
        self.assertEqual(args.port, 8787)

    def test_rejects_port_below_range(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--root", "/tmp", "--host", "127.0.0.1", "--port", "80"])

    def test_missing_root_arg(self):
        with self.assertRaises(SystemExit):
            _server_module._parse_args(["--host", "127.0.0.1", "--port", "8787"])


if __name__ == "__main__":
    unittest.main()
