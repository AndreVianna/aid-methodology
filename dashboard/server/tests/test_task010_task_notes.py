"""
test_task010_task_notes.py -- Server-side unit tests for the concrete task.set-notes
handler (task-010, feature-006-task-notes, delivery-001): the task_id superset
normalization ('task-NNN' or bare 'NNN' -> bare numeric, shared _dispatch_op logic),
the empty-value -> '--' null-sentinel substitution (argv-builder), and the
args.value semantic validation (<=1 KiB, rejects '|'/newline).

Mirrors test_task008_display_rename.py's / test_task004_op_dispatch.py's own
conventions: pure in-process dispatch logic (srv._dispatch_op / srv.OP_TABLE),
with REAL (fast, non-interactive) writer subprocess invocations against tmp-dir
fixtures. No server spawn, no port binding -- safe to run standalone.

The UI half (the "TASK NOTES" card + inline editor in home.html) is covered by
test_task010_task_notes_ui.py (static/DOM assertions, no browser). The Node twin
(server.mjs) parity for task_id normalization + the empty-value sentinel is
covered by test_task010_task_notes_cross_runtime_parity.py (sliced-module +
subprocess technique, mirroring test_write_enabled_cross_runtime_parity.py).

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
# test_task004_op_dispatch.py / test_task008_display_rename.py's own setup).
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


def _make_flat_work(root: Path, work_id: str, notes: str = "--") -> Path:
    """A minimal FLAT-layout work with a '### Tasks lifecycle' row for task-001,
    seeded with the given Notes cell (defaults to the null sentinel)."""
    work_dir = root / ".aid" / "works" / work_id
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text("# task-001\n", encoding="utf-8")
    (work_dir / "STATE.md").write_text(
        "---\n"
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "---\n\n"
        "# Work State\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        f"| task-001 | Pending | -- | -- | {notes} |\n",
        encoding="utf-8",
    )
    return work_dir


class TestOpTableTaskSetNotesRow(unittest.TestCase):
    def test_row_carries_semantic_validate(self):
        row = srv.OP_TABLE["task.set-notes"]
        self.assertIn("semantic_validate", row)
        self.assertTrue(callable(row["semantic_validate"]))

    def test_row_scope_and_writer_unchanged(self):
        row = srv.OP_TABLE["task.set-notes"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "writeback-state.sh")
        self.assertIsNone(row["status_map"])


class TestValidateTaskSetNotesArgs(unittest.TestCase):
    def test_empty_value_is_allowed(self):
        """Empty means clear-to-null (feature-006 AC) -- must NOT be rejected here."""
        self.assertIsNone(srv._validate_task_set_notes_args({"value": ""}))

    def test_plain_value_passes(self):
        self.assertIsNone(srv._validate_task_set_notes_args({"value": "blocked on upstream fix"}))

    def test_newline_rejected(self):
        err = srv._validate_task_set_notes_args({"value": "a\nb"})
        self.assertIsNotNone(err)

    def test_pipe_rejected(self):
        err = srv._validate_task_set_notes_args({"value": "a|b"})
        self.assertIsNotNone(err)

    def test_over_length_rejected(self):
        err = srv._validate_task_set_notes_args({"value": "x" * (srv._MAX_NOTES_VALUE_BYTES + 1)})
        self.assertIsNotNone(err)

    def test_at_length_cap_passes(self):
        self.assertIsNone(srv._validate_task_set_notes_args({"value": "x" * srv._MAX_NOTES_VALUE_BYTES}))


class TestOpTaskSetNotesArgv(unittest.TestCase):
    def test_empty_value_substitutes_null_sentinel(self):
        argv, _env = srv._op_task_set_notes_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": ""},
        )
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "--")

    def test_non_empty_value_passed_through(self):
        argv, _env = srv._op_task_set_notes_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": "hello"},
        )
        idx = argv.index("--value")
        self.assertEqual(argv[idx + 1], "hello")

    def test_delivery_id_forwarded_when_present(self):
        argv, _env = srv._op_task_set_notes_argv(
            Path("/work"), "/repo", {"task_id": "001", "delivery_id": "2"}, {"value": "x"},
        )
        self.assertIn("--delivery-id", argv)
        idx = argv.index("--delivery-id")
        self.assertEqual(argv[idx + 1], "2")

    def test_delivery_id_omitted_when_absent(self):
        argv, _env = srv._op_task_set_notes_argv(
            Path("/work"), "/repo", {"task_id": "001"}, {"value": "x"},
        )
        self.assertNotIn("--delivery-id", argv)

    def test_env_targets_resolved_work_dir(self):
        work_dir = Path("/resolved/work-017")
        _argv, env = srv._op_task_set_notes_argv(work_dir, "/repo", {"task_id": "001"}, {"value": "x"})
        self.assertEqual(env["AID_STATE_FILE"], str(work_dir / "STATE.md"))
        self.assertEqual(env["AID_WORK_DIR"], str(work_dir))


class TestDispatchTaskIdNormalization(unittest.TestCase):
    """target.task_id superset: 'task-NNN' or bare 'NNN' -> normalized bare numeric
    (feature-006 SPEC.md API Contracts -- reconciles feature-001's own regex-vs-
    example self-contradiction)."""

    def test_prefixed_task_id_accepted_and_round_trips(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-800-prefixed")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-800-prefixed", "task_id": "task-001"},
                 "args": {"value": "hello from prefixed id"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.set-notes"})
            self.assertIn("hello from prefixed id", (work_dir / "STATE.md").read_text(encoding="utf-8"))

    def test_bare_task_id_still_accepted(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-801-bare")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-801-bare", "task_id": "001"},
                 "args": {"value": "hello from bare id"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            self.assertIn("hello from bare id", (work_dir / "STATE.md").read_text(encoding="utf-8"))

    def test_malformed_task_id_is_still_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-802-bad", "task_id": "task-abc"},
                 "args": {"value": "x"}},
                str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_over_length_task_id_is_still_400(self):
        with _TmpRepo() as root:
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-803-bad", "task_id": "task-1234"},
                 "args": {"value": "x"}},
                str(root),
            )
            self.assertEqual(status, 400)


class TestTaskSetNotesEmptyValueClearsToNull(unittest.TestCase):
    """After task-010's argv-builder substitution, an empty args.value round-trips
    to a SUCCESSFUL write (200) with the '--' null sentinel -- NOT the exit-5 422
    the pre-task-010 argv-builder produced (see test_task011_dispatch_round_trip.py's
    updated exit-5 scenario, which now drives a DIFFERENT exit-5 path)."""

    def test_empty_value_writes_null_sentinel_and_succeeds(self):
        with _TmpRepo() as root:
            work_dir = _make_flat_work(root, "work-804-clear", notes="had some notes")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-804-clear", "task_id": "001"},
                 "args": {"value": ""}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.set-notes"})
            content = (work_dir / "STATE.md").read_text(encoding="utf-8")
            self.assertIn("| task-001 | Pending | -- | -- | -- |", content)
            self.assertNotIn("had some notes", content)


def _make_nested_work_unresolvable_delivery(root: Path, work_id: str) -> Path:
    """A NESTED-layout work (deliveries/ wrapper, no BLUEPRINT.md -- is_flat_layout()
    is false) whose task-001 DETAIL.md carries NO '**Source:**' bullet -- mirrors
    test_task011_dispatch_round_trip.py's fixture of the same name (in-process
    duplicate so this exit-5 path is also verified WITHOUT a live socket / server
    spawn, safe to run locally per this repo's port-binding-test constraint)."""
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
        "# task-001: Nested task (no Source line)\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        "---\nstate: Pending\n---\n\n## Task State\n", encoding="utf-8",
    )
    return root / ".aid" / "works" / work_id


class TestExit5UnresolvableDeliveryStillReachable(unittest.TestCase):
    """The empty-value -> '--' sentinel substitution closes OFF the 'empty --value'
    exit-5 path for task.set-notes, but DEFAULT_MAP's exit-5 -> 422 row is still
    reachable via the OTHER documented exit-5 path (feature-006 SPEC.md API
    Contracts: 'unresolvable delivery ... resolve_delivery_for_task_mode'), proven
    here in-process (no socket -- mirrors test_task011_dispatch_round_trip.py's own,
    live-socket, version of this same scenario)."""

    def test_unresolvable_delivery_is_422_invalid_value(self):
        with _TmpRepo() as root:
            _make_nested_work_unresolvable_delivery(root, "work-808-nodelivery")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-808-nodelivery", "task_id": "001"},
                 "args": {"value": "hi"}},
                str(root),
            )
            self.assertEqual(status, 422, body)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


class TestTaskSetNotesSemanticValidation422(unittest.TestCase):
    """Pipe / newline / oversize args.value 422s at the server's pre-validation --
    never reaches a child spawn."""

    def test_pipe_in_value_is_422(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-805-pipe")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-805-pipe", "task_id": "001"},
                 "args": {"value": "a|b"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_newline_in_value_is_422(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-806-newline")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-806-newline", "task_id": "001"},
                 "args": {"value": "a\nb"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_oversize_value_is_422(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-807-oversize")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-807-oversize", "task_id": "001"},
                 "args": {"value": "x" * (srv._MAX_NOTES_VALUE_BYTES + 1)}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


if __name__ == "__main__":
    unittest.main(verbosity=2)
