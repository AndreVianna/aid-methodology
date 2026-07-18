"""
test_task006_settings_set_validation.py -- Unit tests for the settings.set semantic
arg-schema finalization (task-006, feature-002-project-header-edit, delivery-001).

Exercises `_validate_settings_set_args` directly (pure function, no I/O) plus a few
`_dispatch_op` round-trips proving the pre-validation short-circuits BEFORE any writer
child is spawned (a 422 for an invalid request even when .aid/settings.yml is entirely
absent -- if the writer had been invoked instead, a missing settings file surfaces as
exit 3 -> 500 'write-failed', not 422; see write-setting.sh's "settings file not found"
path).

The writer's OWN (redundant, belt-and-suspenders) validation is already covered by
test_task004_op_dispatch.py's real-writer round-trips; this file is scoped to the NEW
server-side semantic pre-validation task-006 adds ahead of that spawn.

Validates:
  1. Closed args.path allowlist: the 3 allowed paths pass the path-shape check; any
     other value is rejected with a path-naming error message.
  2. review.minimum_grade: ^[A-F][+-]?$ enforced (valid/invalid grade strings).
  3. project.name / project.description: reject an embedded newline / double-quote /
     backslash (KI-001 output-charset guard), applied identically to both paths.
  4. project.name: empty value rejected (required); project.description: empty value
     allowed (clears it).
  5. `_dispatch_op` maps a semantic-validation failure to 422 'invalid-value' WITHOUT
     spawning the writer (proven via a settings-file-absent fixture).
  6. OP_TABLE["settings.set"] carries the semantic_validate hook; pipeline.finish
     (the one feature-001-owned row with no client-forwarded value) still does not
     (this op-specific extension is not applied broadly). NOTE: task.set-notes has
     since gained its own semantic_validate hook (work-017 task-010, feature-006) --
     see test_task010_task_notes.py -- so it is no longer asserted hook-less here.

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
# Make the dashboard package importable regardless of CWD (mirrors
# test_task004_op_dispatch.py / test_server_py.py).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv


class _TmpRepo:
    """Context manager: a scratch repo root (deliberately WITHOUT .aid/), cleaned up
    on exit -- proves the pre-validation never needs settings.yml to exist."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(self.path, ignore_errors=True)


class TestValidateSettingsSetArgsPathAllowlist(unittest.TestCase):
    def test_allowed_paths_pass_the_path_check(self):
        for path in ("project.name", "project.description"):
            with self.subTest(path=path):
                self.assertIsNone(srv._validate_settings_set_args({"path": path, "value": "ok"}))
        self.assertIsNone(
            srv._validate_settings_set_args({"path": "review.minimum_grade", "value": "A"})
        )

    def test_disallowed_path_is_rejected(self):
        err = srv._validate_settings_set_args({"path": "project.type", "value": "x"})
        self.assertIsNotNone(err)
        self.assertIn("path", err)


class TestValidateSettingsSetArgsGrade(unittest.TestCase):
    def test_valid_grades_pass(self):
        for grade in ("A+", "A", "A-", "B+", "C", "D-", "F"):
            with self.subTest(grade=grade):
                self.assertIsNone(
                    srv._validate_settings_set_args({"path": "review.minimum_grade", "value": grade})
                )

    def test_invalid_grades_are_rejected(self):
        for grade in ("Z", "A++", "a", "", "A B", "G-"):
            with self.subTest(grade=grade):
                err = srv._validate_settings_set_args({"path": "review.minimum_grade", "value": grade})
                self.assertIsNotNone(err)


class TestValidateSettingsSetArgsNameDescriptionCharset(unittest.TestCase):
    def test_newline_rejected(self):
        for path in ("project.name", "project.description"):
            with self.subTest(path=path):
                err = srv._validate_settings_set_args({"path": path, "value": "a\nb"})
                self.assertIsNotNone(err)

    def test_double_quote_rejected(self):
        for path in ("project.name", "project.description"):
            with self.subTest(path=path):
                err = srv._validate_settings_set_args({"path": path, "value": 'a"b'})
                self.assertIsNotNone(err)

    def test_backslash_rejected(self):
        for path in ("project.name", "project.description"):
            with self.subTest(path=path):
                err = srv._validate_settings_set_args({"path": path, "value": "a\\b"})
                self.assertIsNotNone(err)

    def test_plain_value_passes(self):
        for path in ("project.name", "project.description"):
            with self.subTest(path=path):
                self.assertIsNone(srv._validate_settings_set_args({"path": path, "value": "My Project"}))


class TestValidateSettingsSetArgsEmptyValue(unittest.TestCase):
    def test_empty_name_rejected(self):
        err = srv._validate_settings_set_args({"path": "project.name", "value": ""})
        self.assertIsNotNone(err)

    def test_empty_description_allowed(self):
        self.assertIsNone(srv._validate_settings_set_args({"path": "project.description", "value": ""}))


class TestSemanticValidationShortCircuitsBeforeWriterSpawn(unittest.TestCase):
    """A semantic-validation failure -> 422 even with NO .aid/settings.yml on disk --
    proving the pre-validation short-circuits ahead of the writer spawn (a missing
    settings file would otherwise surface as the writer's own exit 3 -> 500)."""

    def test_bad_path_is_422_with_no_settings_file_present(self):
        with _TmpRepo() as root:
            self.assertFalse((root / ".aid").exists())
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "not.allowed", "value": "x"}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_bad_grade_is_422_with_no_settings_file_present(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "settings.set", "args": {"path": "review.minimum_grade", "value": "Z"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_empty_name_is_422_with_no_settings_file_present(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.name", "value": ""}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_charset_violation_is_422_with_no_settings_file_present(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "settings.set", "args": {"path": "project.description", "value": 'has "quote"'}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


class TestOpTableSettingsSetSemanticHook(unittest.TestCase):
    def test_settings_set_row_carries_the_semantic_validate_hook(self):
        self.assertTrue(callable(srv.OP_TABLE["settings.set"]["semantic_validate"]))

    def test_other_rows_carry_no_semantic_validate_hook(self):
        # pipeline.rename / task.rename DO carry a semantic_validate hook as of
        # work-017 task-008 (feature-005) -- see test_task008_display_rename.py.
        # task.set-notes DOES too as of work-017 task-010 (feature-006) -- see
        # test_task010_task_notes.py. pipeline.finish is the only remaining row
        # with no per-op semantic validation (it forwards no client value at all).
        for op in ("pipeline.finish",):
            with self.subTest(op=op):
                self.assertIsNone(srv.OP_TABLE[op].get("semantic_validate"))


if __name__ == "__main__":
    unittest.main()
