"""
test_task008_display_rename.py -- Unit tests for the feature-005 (display-rename)
server-side OP_TABLE additions: the NEW `task.rename` row and the FINALIZED
`pipeline.rename` argv-builder/arg-schema (task-008, work-017-cli-improvements,
delivery-001).

Exercises the pure argv-builder/validation logic directly, plus real-writer
`_dispatch_op` round-trips (bounded child-process spawn, no server/port --
mirrors test_task004_op_dispatch.py's own "no server spawn" convention).

Validates:
  1. OP_TABLE now carries 5 rows (the 4 feature-001 rows + task.rename); both
     pipeline.rename and task.rename carry a semantic_validate hook.
  2. `_validate_rename_value` / `_validate_task_rename_args` /
     `_validate_pipeline_rename_args`: newline/`|`/length-cap rejections;
     an EMPTY value is explicitly ALLOWED (clear-to-fallback, AC2).
  3. `_op_task_rename_argv`: empty args.value -> `--` null sentinel; non-empty
     value passed through verbatim; target.delivery_id forwarded only when
     present (mirrors _op_task_set_notes_argv).
  4. `_op_pipeline_rename_argv`: empty args.value -> `*(pending)*` null
     sentinel; non-empty value passed through verbatim.
  5. `_dispatch_op` end-to-end through the REAL writers:
     - task.rename: nested (per-task STATE.md frontmatter) AND flat (legacy
       5-column ### Tasks lifecycle table -- col 7 is written regardless of
       the authored header) layouts; empty value clears to `--`.
     - pipeline.rename: REQUIREMENTS.md Name bullet; empty value clears to
       `*(pending)*`.
  6. `_ser_task` emits display_name (already covered end-to-end in
     dashboard/reader/tests/test_task008_display_rename.py; re-asserted here
     for the server-serializer surface specifically).

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
# test_task004_op_dispatch.py / test_task006_settings_set_validation.py).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

import unittest.mock as mock

from dashboard.reader import read_repo
from dashboard.server import server as srv


class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(self.path, ignore_errors=True)


def _make_flat_work_legacy_table(root: Path, work_id: str) -> Path:
    """A FLAT-layout work with a LEGACY 5-column ### Tasks lifecycle table (no
    Name column authored yet) -- proves task.rename's flat write path (col
    idx 7) works even against a pre-feature-005 authored table."""
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


def _make_hierarchical_work(root: Path, work_id: str) -> Path:
    """A NESTED-layout work with a per-task STATE.md (task-004's ## Task State
    section) -- proves task.rename's nested write path (fm_key indirection)."""
    del_dir = root / ".aid" / "works" / work_id / "deliveries" / "delivery-001"
    task_dir = del_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (root / ".aid" / "works" / work_id / "STATE.md").write_text(
        "## Pipeline State\n\n- **Lifecycle:** Running\n", encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n- **State:** Executing\n", encoding="utf-8",
    )
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Nested task\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        "---\nstate: Pending\n---\n\n## Task State\n", encoding="utf-8",
    )
    return root / ".aid" / "works" / work_id


class TestOpTableTaskRenameRow(unittest.TestCase):
    def test_op_table_now_has_five_rows(self):
        # task-015 (feature-004) registers a 6th row, tools.update; task-019
        # (feature-007) registers a 7th/8th, connector.set/connector.remove;
        # task-021 (feature-010) registers a 9th/10th,
        # external-source.add/external-source.remove; task-025
        # (feature-009-pipeline-delete) registers an 11th, pipeline.delete --
        # on top of the 5 rows this test originally pinned -- see
        # test_task015_tools_update_ops.py / test_task019_connector_ops.py /
        # test_task021_external_source_ops.py / test_task025_pipeline_delete_
        # ops.py for their dedicated coverage.
        self.assertEqual(
            set(srv.OP_TABLE.keys()),
            {"task.set-notes", "pipeline.finish", "settings.set", "pipeline.rename", "task.rename",
             "tools.update", "connector.set", "connector.remove",
             "external-source.add", "external-source.remove", "pipeline.delete"},
        )

    def test_task_rename_row_shape(self):
        row = srv.OP_TABLE["task.rename"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "writeback-state.sh")
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row["status_map"])

    def test_pipeline_rename_row_now_carries_semantic_validate(self):
        row = srv.OP_TABLE["pipeline.rename"]
        self.assertTrue(callable(row["semantic_validate"]))


class TestValidateRenameValue(unittest.TestCase):
    def test_empty_value_is_allowed(self):
        """Empty means clear-to-fallback (AC2) -- must NOT be rejected here."""
        self.assertIsNone(srv._validate_rename_value(""))

    def test_plain_value_passes(self):
        self.assertIsNone(srv._validate_rename_value("Wire up the rename dispatch"))

    def test_newline_rejected(self):
        err = srv._validate_rename_value("a\nb")
        self.assertIsNotNone(err)

    def test_pipe_rejected(self):
        err = srv._validate_rename_value("a|b")
        self.assertIsNotNone(err)

    def test_backslash_rejected(self):
        """delivery-001 gate finding: a literal backslash used to reach the writer's
        `awk -v value=...` vector, where awk's escape-reprocessing could turn `\t`/`\n`
        into a real TAB/newline and corrupt REQUIREMENTS.md / the STATE table. Reject it
        here (same KI-001-class guard `_validate_settings_set_args` already applies),
        even though the writers now read the value via ENVIRON (immune to that
        reprocessing)."""
        err = srv._validate_rename_value("a\\b")
        self.assertIsNotNone(err)

    def test_over_length_rejected(self):
        err = srv._validate_rename_value("x" * (srv._MAX_RENAME_VALUE_LEN + 1))
        self.assertIsNotNone(err)

    def test_at_length_cap_passes(self):
        self.assertIsNone(srv._validate_rename_value("x" * srv._MAX_RENAME_VALUE_LEN))

    def test_task_and_pipeline_wrappers_delegate(self):
        self.assertIsNone(srv._validate_task_rename_args({"value": "ok"}))
        self.assertIsNotNone(srv._validate_task_rename_args({"value": "a\nb"}))
        self.assertIsNone(srv._validate_pipeline_rename_args({"value": "ok"}))
        self.assertIsNotNone(srv._validate_pipeline_rename_args({"value": "a|b"}))


class TestOpTaskRenameArgv(unittest.TestCase):
    def test_empty_value_substitutes_null_sentinel(self):
        argv, env = srv._op_task_rename_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": ""},
        )
        self.assertIn("--", argv)
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "--")

    def test_non_empty_value_passed_through(self):
        argv, _env = srv._op_task_rename_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": "New label"},
        )
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "New label")

    def test_delivery_id_forwarded_when_present(self):
        argv, _env = srv._op_task_rename_argv(
            Path("/work"), "/repo", {"task_id": "001", "delivery_id": "2"}, {"value": "x"},
        )
        self.assertIn("--delivery-id", argv)
        self.assertIn("2", argv)

    def test_delivery_id_omitted_when_absent(self):
        argv, _env = srv._op_task_rename_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": "x"},
        )
        self.assertNotIn("--delivery-id", argv)

    def test_env_targets_resolved_work_dir(self):
        work_dir = Path("/resolved/work")
        _argv, env = srv._op_task_rename_argv(work_dir, "/repo", {"task_id": "001"}, {"value": "x"})
        self.assertEqual(env["AID_STATE_FILE"], str(work_dir / "STATE.md"))
        self.assertEqual(env["AID_WORK_DIR"], str(work_dir))


class TestOpPipelineRenameArgv(unittest.TestCase):
    def test_empty_value_substitutes_null_sentinel(self):
        argv, _env = srv._op_pipeline_rename_argv(Path("/work"), "/repo", {}, {"value": ""})
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "*(pending)*")

    def test_non_empty_value_passed_through(self):
        argv, _env = srv._op_pipeline_rename_argv(Path("/work"), "/repo", {}, {"value": "New Title"})
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "New Title")

    def test_env_targets_resolved_requirements_file(self):
        work_dir = Path("/resolved/work")
        _argv, env = srv._op_pipeline_rename_argv(work_dir, "/repo", {}, {"value": "x"})
        self.assertEqual(env["AID_REQUIREMENTS_FILE"], str(work_dir / "REQUIREMENTS.md"))


class TestTaskRenameDispatchRealWriterFlat(unittest.TestCase):
    """task.rename end-to-end through the REAL writeback-state.sh, flat layout,
    against a LEGACY 5-column ### Tasks lifecycle table."""

    def test_rename_writes_name_column_on_legacy_table(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work_legacy_table(root, "work-700-flat")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-700-flat", "task_id": "001"},
                    "args": {"value": "Renamed flat task"},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.rename"})
            content = (work_dir / "STATE.md").read_text(encoding="utf-8")
            self.assertIn("Renamed flat task", content)

    def test_empty_rename_writes_null_sentinel(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work_legacy_table(root, "work-701-flat")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-701-flat", "task_id": "001"},
                    "args": {"value": ""},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.rename"})
            content = (work_dir / "STATE.md").read_text(encoding="utf-8")
            self.assertIn("| task-001 | Pending | -- | -- | -- | -- |", content)


class TestTaskRenameDispatchRealWriterNested(unittest.TestCase):
    """task.rename end-to-end through the REAL writeback-state.sh, nested
    layout -- proves the fm_key (name -> display_name) indirection."""

    def test_rename_writes_display_name_frontmatter_key(self):
        with _TmpRepo() as root:
            work_dir = _make_hierarchical_work(root, "work-702-nested")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-702-nested", "delivery_id": "1", "task_id": "001"},
                    "args": {"value": "Renamed nested task"},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.rename"})
            content = (
                work_dir / "deliveries" / "delivery-001" / "tasks" / "task-001" / "STATE.md"
            ).read_text(encoding="utf-8")
            # A value containing a space is not "bare-word-safe" (WB_SET_FRONTMATTER_AWK),
            # so it is emitted as a single-quoted YAML scalar -- see wb_set_frontmatter's
            # own doc comment in writeback-state.sh.
            self.assertIn("display_name: 'Renamed nested task'", content)
            self.assertNotIn("\nname:", content, "must never write a literal 'name:' key")


class TestPipelineRenameDispatchRealWriter(unittest.TestCase):
    def test_rename_writes_requirements_name_bullet(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work_legacy_table(root, "work-703-pipeline")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-703-pipeline"}, "args": {"value": "New Title"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.rename"})
            content = (work_dir / "REQUIREMENTS.md").read_text(encoding="utf-8")
            self.assertIn("- **Name:** New Title", content)

    def test_empty_rename_writes_pending_placeholder(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work_legacy_table(root, "work-704-pipeline")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-704-pipeline"}, "args": {"value": ""}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.rename"})
            content = (work_dir / "REQUIREMENTS.md").read_text(encoding="utf-8")
            self.assertIn("- **Name:** *(pending)*", content)


class TestSemanticValidationShortCircuitsRename(unittest.TestCase):
    """A rename semantic-validation failure -> 422, never reaching the writer
    (mirrors test_task006_settings_set_validation.py's short-circuit proof)."""

    def test_task_rename_newline_value_is_422(self):
        with _TmpRepo() as root:
            _make_flat_work_legacy_table(root, "work-705-flat")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-705-flat", "task_id": "001"},
                    "args": {"value": "a\nb"},
                },
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_pipeline_rename_pipe_value_is_422(self):
        with _TmpRepo() as root:
            _make_flat_work_legacy_table(root, "work-706-flat")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-706-flat"}, "args": {"value": "a|b"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


def _read_task0_display_name(root: Path) -> "str | None":
    """Read back works[0].tasks[0].display_name via the REAL reader (round-trip
    proof: what task.rename just wrote through writeback-state.sh is exactly
    what read_repo()/parse_task_state_md or parse_tasks_lifecycle_md then
    parses back -- not just a raw-text substring match)."""
    aid = root / ".aid"
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        model = read_repo(root)
    return model.works[0].tasks[0].display_name


class TestTaskRenameWriteReadRoundTrip(unittest.TestCase):
    """The value task.rename writes through the REAL writer is read back
    byte-identical (after YAML quote-stripping) by the REAL reader twin --
    closes the loop between the writer-quoting test above and the parser
    unit tests in test_task008_display_rename.py (reader side)."""

    def test_flat_round_trip(self):
        with _TmpRepo() as root:
            _make_flat_work_legacy_table(root, "work-707-flat-roundtrip")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-707-flat-roundtrip", "task_id": "001"},
                    "args": {"value": "Round trip flat"},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(_read_task0_display_name(root), "Round trip flat")

    def test_flat_empty_clears_to_none(self):
        with _TmpRepo() as root:
            _make_flat_work_legacy_table(root, "work-708-flat-roundtrip")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-708-flat-roundtrip", "task_id": "001"},
                    "args": {"value": ""},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertIsNone(_read_task0_display_name(root))

    def test_nested_round_trip(self):
        with _TmpRepo() as root:
            _make_hierarchical_work(root, "work-709-nested-roundtrip")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-709-nested-roundtrip", "delivery_id": "1", "task_id": "001"},
                    "args": {"value": "Round trip nested"},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(_read_task0_display_name(root), "Round trip nested")

    def test_nested_empty_clears_to_none(self):
        with _TmpRepo() as root:
            _make_hierarchical_work(root, "work-710-nested-roundtrip")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "task.rename",
                    "target": {"work_id": "work-710-nested-roundtrip", "delivery_id": "1", "task_id": "001"},
                    "args": {"value": ""},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertIsNone(_read_task0_display_name(root))


class TestSerTaskDisplayName(unittest.TestCase):
    def test_ser_task_field_order_includes_display_name(self):
        class _Obj:
            pass

        obj = _Obj()
        obj.task_id = "task-001"
        obj.type = "IMPLEMENT"
        obj.wave = "delivery-001"

        class _Status:
            value = "Done"

        obj.status = _Status()
        obj.review_grade = None
        obj.elapsed = None
        obj.notes = None
        obj.short_name = "Some task"
        obj.delivery = 1
        obj.lane = None
        obj.display_name = "Renamed task"

        serialized = srv._ser_task(obj)
        self.assertEqual(serialized["display_name"], "Renamed task")
        self.assertEqual(list(serialized.keys())[-1], "display_name")


if __name__ == "__main__":
    unittest.main()
