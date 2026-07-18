"""
test_task004_op_dispatch.py -- Unit tests for the POST op-router + closed OP_TABLE +
`op.status_map or DEFAULT_MAP` dispatch (task-004, feature-001-write-infrastructure,
delivery-001).

Exercises the pure dispatch logic (`_dispatch_op`, `OP_TABLE`, `HOME_OP_TABLE`,
`DEFAULT_MAP`, `_map_exit_code`, `_validate_args`, the 4 argv-builders, `_run_writer`)
directly via `dashboard.server.server`, with REAL (fast, non-interactive) writer
subprocess invocations against tmp-dir fixtures. No server spawn, no port binding --
safe to run standalone (mirrors test_task002_resolve_work_dir.mjs's own "no server
spawn" convention).

The full HTTP-level round-trip (do_POST -> _serve_op/_serve_home_op over a real
socket, both twins) is task-011's "Foundation parity + dispatch round-trip suite"
mandate; this file covers the dispatch/argv/status-map LOGIC task-004 introduces.

Validates:
  1. OP_TABLE seeds exactly the 4 feature-001-owned rows (a 5th, task.rename, was
     added by feature-005/task-008); HOME_OP_TABLE was empty at task-004 time and
     now seeds feature-003's project.add/project.remove rows (task-013) -- see
     test_task013_project_registry_ops.py for their own dedicated coverage.
  2. DEFAULT_MAP resolves the documented exit-code -> (status, error) rows, with an
     unknown exit code falling back to (500, 'write-failed').
  3. `op.status_map or DEFAULT_MAP`: a row with no status_map uses DEFAULT_MAP
     unchanged; a row WITH one uses its own map instead (OP-SM).
  4. Unknown/missing 'op' -> 400 'bad-request' before any child spawn.
  5. Malformed 'target'/'args' shape -> 400 'bad-request'.
  6. A pipeline-scoped op resolves target.work_id via resolve_work_dir; unresolved
     work_id -> 404 'not-found' (WT-1).
  7. task.set-notes requires target.task_id (missing -> 400, never silently reinterpreted).
  8. Each of the 4 seeded ops round-trips through its REAL writer script end-to-end
     (settings.set, pipeline.rename, task.set-notes, pipeline.finish [value fixed
     to 'Completed', client args ignored]).
  9. A writer's own semantic-validation failure (invalid --path) maps through
     DEFAULT_MAP to 422 'invalid-value'.
 10. Success envelope is exactly {"ok": true, "op": "<op>"}; failure envelope is
     {"ok": false, "op", "error", "detail"}.

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
# Make the dashboard package importable regardless of CWD (mirrors test_server_py.py).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv


class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(self.path, ignore_errors=True)


def _make_settings_repo(root: Path) -> Path:
    """<root>/.aid/settings.yml with a project.name to overwrite."""
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text("project:\n  name: old-name\n", encoding="utf-8")
    return aid


def _make_flat_work(root: Path, work_id: str) -> Path:
    """A minimal FLAT-layout work (BLUEPRINT.md + tasks/task-NNN/DETAIL.md, no
    deliveries/ wrapper) with a ### Tasks lifecycle row for task-001, plus a
    REQUIREMENTS.md Name bullet -- enough for task.set-notes / pipeline.finish /
    pipeline.rename to all round-trip against the same fixture."""
    work_dir = root / ".aid" / "works" / work_id
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text("# task-001\n", encoding="utf-8")
    (work_dir / "REQUIREMENTS.md").write_text(
        "# Requirements\n\n- **Name:** Old Name\n", encoding="utf-8",
    )
    (work_dir / "STATE.md").write_text(
        "---\n"
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "---\n\n"
        "# Work State\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        "| task-001 | Pending | -- | -- | -- |\n",
        encoding="utf-8",
    )
    return work_dir


class TestOpTableShape(unittest.TestCase):
    """OP_TABLE / HOME_OP_TABLE / DEFAULT_MAP static shape (no I/O)."""

    def test_op_table_seeds_the_four_feature001_rows(self):
        # work-017 task-008 (feature-005) registers a 5th row, task.rename;
        # task-015 (feature-004) registers a 6th, tools.update -- on top of the
        # 4 feature-001-owned rows this test originally pinned -- see
        # test_task008_display_rename.py / test_task015_tools_update_ops.py for
        # their dedicated coverage.
        self.assertEqual(
            set(srv.OP_TABLE.keys()),
            {"task.set-notes", "pipeline.finish", "settings.set", "pipeline.rename", "task.rename", "tools.update"},
        )

    def test_home_op_table_seeds_the_two_feature003_rows(self):
        # feature-001 owned no home-scoped rows itself (this test originally
        # pinned HOME_OP_TABLE == {}) -- feature-003 (task-013) registered
        # project.add/project.remove; feature-004's tools.update-self
        # (task-015) adds a 3rd row on top of those 2 -- see
        # test_task015_tools_update_ops.py for its dedicated coverage.
        self.assertEqual(
            set(srv.HOME_OP_TABLE.keys()), {"project.add", "project.remove", "tools.update-self"}
        )

    def test_home_op_table_rows_declare_scope_argv_builder_and_spawn(self):
        for op, row in srv.HOME_OP_TABLE.items():
            with self.subTest(op=op):
                self.assertEqual(row["scope"], "home")
                self.assertIn("arg_schema", row)
                self.assertTrue(callable(row["build_argv"]))
                self.assertTrue(callable(row["spawn"]))

    def test_op_table_rows_declare_scope_writer_schema_argv_builder(self):
        for op, row in srv.OP_TABLE.items():
            with self.subTest(op=op):
                self.assertIn(row["scope"], ("task", "pipeline", "project"))
                # Every row is either co-vendored-writer-backed ('writer', a
                # .sh script under dashboard/scripts/) or aid-CLI-backed (a
                # 'spawn' override -- KI-004's shared resolver, e.g.
                # tools.update -- with no 'writer' key at all).
                if "writer" in row:
                    self.assertTrue(row["writer"].endswith(".sh"))
                else:
                    self.assertTrue(callable(row["spawn"]))
                self.assertIn("arg_schema", row)
                self.assertTrue(callable(row["build_argv"]))

    def test_default_map_rows(self):
        self.assertEqual(srv.DEFAULT_MAP[1], (404, "not-found"))
        self.assertEqual(srv.DEFAULT_MAP[2], (409, "busy"))
        self.assertEqual(srv.DEFAULT_MAP[4], (422, "invalid-value"))
        self.assertEqual(srv.DEFAULT_MAP[5], (422, "invalid-value"))
        self.assertEqual(srv.DEFAULT_MAP[3], (500, "write-failed"))
        self.assertEqual(srv.DEFAULT_MAP[6], (500, "write-failed"))

    def test_map_exit_code_unknown_exit_falls_back(self):
        self.assertEqual(srv._map_exit_code(42, None), (500, "write-failed"))

    def test_map_exit_code_uses_default_map_when_row_has_none(self):
        self.assertEqual(srv._map_exit_code(4, None), (422, "invalid-value"))

    def test_map_exit_code_uses_row_status_map_when_present(self):
        """OP-SM: op.status_map or DEFAULT_MAP -- a present map overrides, not merges."""
        override = {1: (401, "custom-unauthorized")}
        self.assertEqual(srv._map_exit_code(1, override), (401, "custom-unauthorized"))
        # An exit code absent from the OVERRIDE map still falls back to the
        # fixed (500, write-failed) sentinel, NOT to DEFAULT_MAP's own row for
        # that code (the override fully replaces DEFAULT_MAP for this op).
        self.assertEqual(srv._map_exit_code(2, override), (500, "write-failed"))


class TestValidateArgs(unittest.TestCase):
    def test_missing_required_arg(self):
        err = srv._validate_args({"value": {"required": True}}, {})
        self.assertIsNotNone(err)
        self.assertIn("value", err)

    def test_wrong_type_arg(self):
        err = srv._validate_args({"value": {"required": True}}, {"value": 123})
        self.assertIsNotNone(err)

    def test_valid_args_pass(self):
        err = srv._validate_args({"value": {"required": True}}, {"value": "ok"})
        self.assertIsNone(err)

    def test_empty_schema_always_passes(self):
        self.assertIsNone(srv._validate_args({}, {"anything": "ignored"}))


class TestDispatchOpRequestShape(unittest.TestCase):
    """400-class request-shape rejections -- never reach a child spawn."""

    def test_unknown_op_is_400(self):
        status, body = srv._dispatch_op(srv.OP_TABLE, {"op": "nope"}, "/does/not/matter")
        self.assertEqual(status, 400)
        parsed = json.loads(body)
        self.assertEqual(parsed, {"ok": False, "op": "nope", "error": "bad-request", "detail": "unknown or missing 'op'"})

    def test_missing_op_is_400(self):
        status, body = srv._dispatch_op(srv.OP_TABLE, {}, "/does/not/matter")
        self.assertEqual(status, 400)
        self.assertIsNone(json.loads(body)["op"])

    def test_non_object_target_is_400(self):
        status, _ = srv._dispatch_op(
            srv.OP_TABLE, {"op": "settings.set", "target": "not-an-object", "args": {"path": "project.name", "value": "x"}},
            "/does/not/matter",
        )
        self.assertEqual(status, 400)

    def test_non_object_args_is_400(self):
        status, _ = srv._dispatch_op(srv.OP_TABLE, {"op": "settings.set", "args": "nope"}, "/does/not/matter")
        self.assertEqual(status, 400)

    def test_invalid_delivery_id_shape_is_400(self):
        status, _ = srv._dispatch_op(
            srv.OP_TABLE,
            {"op": "task.set-notes", "target": {"work_id": "work-1", "task_id": "001", "delivery_id": "abc"}, "args": {"value": "x"}},
            "/does/not/matter",
        )
        self.assertEqual(status, 400)

    def test_missing_work_id_for_pipeline_scoped_op_is_400(self):
        status, _ = srv._dispatch_op(srv.OP_TABLE, {"op": "pipeline.rename", "args": {"value": "x"}}, "/does/not/matter")
        self.assertEqual(status, 400)

    def test_task_scoped_op_requires_task_id(self):
        status, body = srv._dispatch_op(
            srv.OP_TABLE, {"op": "task.set-notes", "target": {"work_id": "work-1"}, "args": {"value": "x"}},
            "/does/not/matter",
        )
        self.assertEqual(status, 400)
        self.assertIn("task_id", json.loads(body)["detail"])


class TestDispatchOpWorkIdResolution(unittest.TestCase):
    """Pipeline-scoped ops resolve target.work_id via resolve_work_dir (WT-1)."""

    def test_unresolvable_work_id_is_404_not_found(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.rename", "target": {"work_id": "work-000-nope"}, "args": {"value": "x"}},
                str(root),
            )
            self.assertEqual(status, 404)
            self.assertEqual(json.loads(body)["error"], "not-found")


class TestOpWriterRoundTrips(unittest.TestCase):
    """Each of the 4 feature-001-owned ops end-to-end through its REAL writer script."""

    def test_settings_set_success(self):
        with _TmpRepo() as root:
            aid = _make_settings_repo(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.name", "value": "new-name"}}, str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "settings.set"})
            self.assertIn("new-name", (aid / "settings.yml").read_text(encoding="utf-8"))

    def test_settings_set_writer_semantic_failure_maps_to_422(self):
        """An out-of-allowlist --path is now caught by the server's OWN pre-validation
        (task-006's `semantic_validate` hook, added ahead of this test's original writer-
        exit-4 path) -> 422 'invalid-value' without a child spawn. write-setting.sh
        independently re-validates the same rule as a second line of defense (see
        test_task006_settings_set_validation.py) -- this test only pins the status."""
        with _TmpRepo() as root:
            _make_settings_repo(root)
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "not.allowed", "value": "x"}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_pipeline_rename_success_and_unknown_work_id_404(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-500-demo")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-500-demo"}, "args": {"value": "New Name"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.rename"})
            self.assertIn("New Name", (work_dir / "REQUIREMENTS.md").read_text(encoding="utf-8"))

    def test_task_set_notes_success_and_missing_task_id_400(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-501-demo")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes", "target": {"work_id": "work-501-demo", "task_id": "001"}, "args": {"value": "hello"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.set-notes"})
            self.assertIn("hello", (work_dir / "STATE.md").read_text(encoding="utf-8"))

    def test_pipeline_finish_fixes_value_to_completed_ignoring_client_args(self):
        """The op takes no lifecycle argument -- args (even if supplied) are ignored."""
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-502-demo")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.finish", "target": {"work_id": "work-502-demo"}, "args": {"value": "Blocked"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.finish"})
            content = (work_dir / "STATE.md").read_text(encoding="utf-8")
            self.assertIn("lifecycle: Completed", content)
            self.assertNotIn("lifecycle: Blocked", content)


class TestOpEnvelopes(unittest.TestCase):
    """Success/failure envelope shape (API Contracts)."""

    def test_ok_body_shape(self):
        self.assertEqual(json.loads(srv._op_ok_body("settings.set")), {"ok": True, "op": "settings.set"})

    def test_fail_body_shape(self):
        parsed = json.loads(srv._op_fail_body("settings.set", "bad-request", "oops"))
        self.assertEqual(parsed, {"ok": False, "op": "settings.set", "error": "bad-request", "detail": "oops"})

    def test_fail_detail_truncated_to_1kib(self):
        long_detail = "x" * 5000
        parsed = json.loads(srv._op_fail_body("op", "write-failed", long_detail))
        self.assertLessEqual(len(parsed["detail"].encode("utf-8")), 1024)


class TestRouteRegex(unittest.TestCase):
    def test_r_op_matches_per_repo_op_path(self):
        m = srv._R_OP.match("/r/deadbeef/api/op")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "deadbeef")

    def test_r_op_does_not_match_api_model(self):
        self.assertIsNone(srv._R_OP.match("/r/deadbeef/api/model"))


if __name__ == "__main__":
    unittest.main()
