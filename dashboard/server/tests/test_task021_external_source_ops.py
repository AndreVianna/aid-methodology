"""
test_task021_external_source_ops.py -- "External-sources reader/model +
external-source.add/remove ops" (task-021, feature-010-external-sources-list,
delivery-003, work-017-cli-improvements) -- Python twin.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. OP_TABLE shape: external-source.add / external-source.remove rows carry
     the expected scope ("project" -- no work_id), writer
     ("write-external-source.sh"), arg_schema keys, and semantic_validate
     hooks; no per-op status_map override (relies on feature-001's generic
     DEFAULT_MAP, which already matches write-external-source.sh's canonical
     0/1/2/3/4 exit alphabet).
  2. Pure semantic validation (_validate_external_source_args): length bounds
     (1-2048), newline/'|' rejection, URL-or-whitespace-free-path/glob shape.
  3. Argv builders (_op_external_source_add_argv /
     _op_external_source_remove_argv): argv is an array (never a shell
     string), --file is server-built from served_root (never the request
     body), --op is fixed per row.
  4. Full _dispatch_op round-trips through the REAL co-vendored
     write-external-source.sh writer (bash) -- 200 happy paths for add/remove,
     404 remove-target-absent, and 422 'invalid-value' short-circuits BEFORE
     any child spawn for a semantically invalid request.
  5. target: {} (present-but-empty) request shape -- no target.work_id is ever
     consumed by either op (project-scoped, feature-002 settings.set envelope
     precedent).
  6. Reader-visibility: after a real dispatch_op round trip, the reader's
     parse_external_sources() wrapper sees exactly the written entry
     (joint task-020/task-021 verification, feature-010 AC2).

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` directly -- no `_ServerThread` socket bind
anywhere -- so the whole file is safe to run locally per the project's
port-binding-server-test constraint. All classes were exercised directly as
part of this task's own verification pass.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD (mirrors the other
# task-0NN suites' own sys.path setup).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv
from dashboard.reader.parsers import parse_external_sources


class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(str(self.path), ignore_errors=True)


def _seed_external_sources_md(root: Path) -> Path:
    """Seed a minimal, lint-shape-clean external-sources.md registry (the
    writer requires the file to already exist -- exit 3 'file not found'
    otherwise, per write-external-source.sh's own contract)."""
    kb_dir = root / ".aid" / "knowledge"
    kb_dir.mkdir(parents=True, exist_ok=True)
    ext_file = kb_dir / "external-sources.md"
    ext_file.write_text(
        "---\nsources:\n  - (none)\n---\n\n"
        "## Sources\n\n"
        "No external documentation was provided during discovery. All knowledge was "
        "derived from repository content only. If external documentation becomes "
        "available, re-run discovery or add paths during Q&A.\n",
        encoding="utf-8",
    )
    return ext_file


# ===========================================================================
# (1) OP_TABLE shape
# ===========================================================================

class TestOpTableExternalSourceRows(unittest.TestCase):
    def test_external_source_add_row_shape(self):
        row = srv.OP_TABLE["external-source.add"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["writer"], "write-external-source.sh")
        self.assertIn("value", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["value"]["required"])
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row.get("status_map"))

    def test_external_source_remove_row_shape(self):
        row = srv.OP_TABLE["external-source.remove"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["writer"], "write-external-source.sh")
        self.assertIn("value", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["value"]["required"])
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row.get("status_map"))


# ===========================================================================
# (2) Pure semantic validation
# ===========================================================================

class TestValidateExternalSourceArgs(unittest.TestCase):
    def test_valid_url_passes(self):
        self.assertIsNone(srv._validate_external_source_args({"value": "https://example.com/doc"}))

    def test_valid_http_url_passes(self):
        self.assertIsNone(srv._validate_external_source_args({"value": "http://example.com/doc"}))

    def test_valid_whitespace_free_path_passes(self):
        self.assertIsNone(srv._validate_external_source_args({"value": "docs/reference.md"}))

    def test_valid_glob_passes(self):
        self.assertIsNone(srv._validate_external_source_args({"value": "docs/**/*.md"}))

    def test_empty_value_rejected(self):
        err = srv._validate_external_source_args({"value": ""})
        self.assertIsNotNone(err)

    def test_overlong_value_rejected(self):
        err = srv._validate_external_source_args({"value": "x" * 2049})
        self.assertIsNotNone(err)

    def test_value_at_max_length_passes(self):
        self.assertIsNone(srv._validate_external_source_args({"value": "x" * 2048}))

    def test_value_with_newline_rejected(self):
        err = srv._validate_external_source_args({"value": "a\nb"})
        self.assertIsNotNone(err)

    def test_value_with_pipe_rejected(self):
        err = srv._validate_external_source_args({"value": "a|b"})
        self.assertIsNotNone(err)

    def test_value_with_space_rejected(self):
        err = srv._validate_external_source_args({"value": "a path with spaces"})
        self.assertIsNotNone(err)

    def test_value_with_tab_rejected(self):
        err = srv._validate_external_source_args({"value": "a\tb"})
        self.assertIsNotNone(err)

    def test_url_with_embedded_space_rejected(self):
        err = srv._validate_external_source_args({"value": "https://example.com/a b"})
        self.assertIsNotNone(err)


# ===========================================================================
# (3) Argv builders
# ===========================================================================

class TestExternalSourceAddArgvBuilder(unittest.TestCase):
    def test_argv_is_list_with_op_add(self):
        argv, env = srv._op_external_source_add_argv(
            None, "/repo/root", {}, {"value": "https://example.com/doc"},
        )
        self.assertIsInstance(argv, list)
        self.assertEqual(argv[0], "--op")
        self.assertEqual(argv[1], "add")
        self.assertIn("--value", argv)
        self.assertEqual(argv[argv.index("--value") + 1], "https://example.com/doc")
        self.assertIn("--file", argv)
        file_idx = argv.index("--file")
        self.assertTrue(argv[file_idx + 1].endswith(".aid/knowledge/external-sources.md"))
        self.assertEqual(env, {})

    def test_file_never_taken_from_args_body(self):
        """--file is ALWAYS server-built from served_root, never echoed from a
        client-supplied field (SEC-2)."""
        argv, _ = srv._op_external_source_add_argv(
            None, "/repo/root", {}, {"value": "https://example.com/doc", "file": "/evil/path"},
        )
        file_idx = argv.index("--file")
        self.assertNotIn("/evil/path", argv[file_idx + 1])


class TestExternalSourceRemoveArgvBuilder(unittest.TestCase):
    def test_argv_is_list_with_op_remove(self):
        argv, env = srv._op_external_source_remove_argv(
            None, "/repo/root", {}, {"value": "https://example.com/doc"},
        )
        self.assertIsInstance(argv, list)
        self.assertEqual(argv[0], "--op")
        self.assertEqual(argv[1], "remove")
        self.assertIn("--value", argv)
        self.assertIn("--file", argv)
        file_idx = argv.index("--file")
        self.assertTrue(argv[file_idx + 1].endswith(".aid/knowledge/external-sources.md"))
        self.assertEqual(env, {})


# ===========================================================================
# (4) Full _dispatch_op round-trips through the REAL write-external-source.sh
#     writer
# ===========================================================================

class TestExternalSourceOpsRealWriterRoundTrips(unittest.TestCase):
    def test_add_success(self):
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {}, "args": {"value": "https://example.com/doc"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "external-source.add"})
            ext_file = root / ".aid" / "knowledge" / "external-sources.md"
            text = ext_file.read_text(encoding="utf-8")
            self.assertIn("https://example.com/doc", text)
            self.assertNotIn("- (none)", text)

    def test_add_is_reader_visible(self):
        """Joint task-020/task-021 verification (feature-010 AC2): after a
        real dispatch, the reader's parse_external_sources() wrapper sees
        exactly the written entry."""
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {}, "args": {"value": "https://example.com/doc"}},
                str(root),
            )
            self.assertEqual(status, 200)
            kb_dir = root / ".aid" / "knowledge"
            self.assertEqual(parse_external_sources(kb_dir), ["https://example.com/doc"])

    def test_add_semantic_failure_maps_to_422_before_spawn(self):
        """An invalid value (embedded space) never reaches the writer (422
        'invalid-value')."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {}, "args": {"value": "a b c"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")
            # Proof no spawn happened: the registry file was never created/touched.
            self.assertFalse((root / ".aid" / "knowledge" / "external-sources.md").exists())

    def test_remove_success(self):
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {}, "args": {"value": "https://example.com/doc"}},
                str(root),
            )
            self.assertEqual(status, 200)

            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.remove", "target": {}, "args": {"value": "https://example.com/doc"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "external-source.remove"})
            kb_dir = root / ".aid" / "knowledge"
            self.assertEqual(parse_external_sources(kb_dir), [])

    def test_remove_absent_value_maps_to_404(self):
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.remove", "target": {}, "args": {"value": "https://example.com/never-added"}},
                str(root),
            )
            self.assertEqual(status, 404)
            self.assertEqual(json.loads(body)["error"], "not-found")

    def test_remove_semantic_failure_maps_to_422_before_spawn(self):
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.remove", "target": {}, "args": {"value": "bad value"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


# ===========================================================================
# (5) target: {} envelope shape -- no work_id consumed
# ===========================================================================

class TestExternalSourceOpsProjectScoped(unittest.TestCase):
    def test_missing_target_key_defaults_to_empty_and_still_dispatches(self):
        """The op does not require 'target' in the body at all (defaults to {})."""
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "args": {"value": "https://example.com/doc"}},
                str(root),
            )
            self.assertEqual(status, 200)

    def test_target_with_work_id_is_ignored_not_consumed(self):
        """scope='project' never triggers work_id resolution (unlike 'task'/'pipeline')."""
        with _TmpRepo() as root:
            _seed_external_sources_md(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "external-source.add",
                    "target": {"work_id": "work-999-does-not-exist"},
                    "args": {"value": "https://example.com/doc"},
                },
                str(root),
            )
            # Must NOT 404 (which would mean work_id resolution was attempted).
            self.assertEqual(status, 200)


if __name__ == "__main__":
    unittest.main()
