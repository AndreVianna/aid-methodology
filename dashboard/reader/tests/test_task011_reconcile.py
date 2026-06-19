"""
test_task011_reconcile.py -- Verification fixture for task-011 same-work reconcile.

Validates:
  1. Per-task State: most-advanced by SD-2 ordering (Done wins over In Progress, etc.)
  2. Work-level Pipeline State: copy with newest Updated timestamp wins.
  3. Equal-Updated tie-break: deterministic by branch-label (main first, then lexical).
  4. Derived views (tasks, pending_inputs, deliverables): union of all roots.
  5. Merge is ORDER-INDEPENDENT: shuffling root order -> identical result.
  6. Never throws on malformed / missing input (read-only / never-throws guarantee).
  7. state_text_cache fix (MEDIUM #3): holds the Pipeline-State winner's text, not last-wins.
  8. MEDIUM #3 fix: work_count after reconcile is 1 when same work_id on 2 roots.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import random
import sys
import tempfile
import unittest
from pathlib import Path

# Ensure the repo root is on sys.path so we can import dashboard.*
_REPO_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.models import TaskStatus, WorkModel, SourceMode
from dashboard.reader.reader import SD2_RANK, _reconcile_same_work, _sd2_rank


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> tuple[Path, Path]:
    """Return (repo_root, aid_dir) with minimal settings + manifest."""
    root = tmp
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    manifest = {
        "manifest_version": 1,
        "aid_version": "1.0.0",
        "installed_at": "2026-01-01T00:00:00Z",
        "tools": {"claude-code": {}},
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (aid / "settings.yml").write_text("project:\n  name: TestRepo\n", encoding="utf-8")
    return root, aid


_STATE_TEMPLATE = """\
## Pipeline State

- **Lifecycle:** {lifecycle}
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** {updated}
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
{task_rows}
"""

# Legacy (old-naming) state fixture for backwards compatibility test
_STATE_TEMPLATE_LEGACY = """\
## Pipeline Status

- **Lifecycle:** {lifecycle}
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** {updated}
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
{task_rows}
"""


def _state_text(
    lifecycle: str = "Running",
    updated: str = "2026-06-10T12:00:00Z",
    tasks: list[tuple[str, str]] | None = None,
    use_legacy: bool = False,
) -> str:
    """Build a minimal STATE.md text."""
    template = _STATE_TEMPLATE_LEGACY if use_legacy else _STATE_TEMPLATE
    rows = ""
    for i, (task_id, state) in enumerate(tasks or []):
        rows += f"| {i+1:03d} | {task_id} | IMPLEMENT | delivery-001 | {state} | -- | -- | -- |\n"
    return template.format(lifecycle=lifecycle, updated=updated, task_rows=rows)


# ---------------------------------------------------------------------------
# Test 1: SD2_RANK encoding
# ---------------------------------------------------------------------------

class TestSD2Rank(unittest.TestCase):
    """SD-2 rank map is encoded correctly and matches the authoritative order."""

    def test_rank_map_present(self):
        self.assertIn("Done", SD2_RANK)
        self.assertIn("Canceled", SD2_RANK)
        self.assertIn("In Review", SD2_RANK)
        self.assertIn("In Progress", SD2_RANK)
        self.assertIn("Blocked", SD2_RANK)
        self.assertIn("Failed", SD2_RANK)
        self.assertIn("Pending", SD2_RANK)
        self.assertIn("Unknown", SD2_RANK)

    def test_rank_ordering(self):
        """Done(0) < Canceled(1) < In Review(2) < In Progress(3) < Blocked(4) < Failed(5) < Pending(6)."""
        self.assertLess(SD2_RANK["Done"],        SD2_RANK["Canceled"])
        self.assertLess(SD2_RANK["Canceled"],    SD2_RANK["In Review"])
        self.assertLess(SD2_RANK["In Review"],   SD2_RANK["In Progress"])
        self.assertLess(SD2_RANK["In Progress"], SD2_RANK["Blocked"])
        self.assertLess(SD2_RANK["Blocked"],     SD2_RANK["Failed"])
        self.assertLess(SD2_RANK["Failed"],      SD2_RANK["Pending"])
        self.assertLess(SD2_RANK["Pending"],     SD2_RANK["Unknown"])

    def test_sd2_rank_helper(self):
        self.assertEqual(_sd2_rank(TaskStatus.Done),       SD2_RANK["Done"])
        self.assertEqual(_sd2_rank(TaskStatus.Canceled),   SD2_RANK["Canceled"])
        self.assertEqual(_sd2_rank(TaskStatus.InReview),   SD2_RANK["In Review"])
        self.assertEqual(_sd2_rank(TaskStatus.InProgress), SD2_RANK["In Progress"])
        self.assertEqual(_sd2_rank(TaskStatus.Blocked),    SD2_RANK["Blocked"])
        self.assertEqual(_sd2_rank(TaskStatus.Failed),     SD2_RANK["Failed"])
        self.assertEqual(_sd2_rank(TaskStatus.Pending),    SD2_RANK["Pending"])
        self.assertEqual(_sd2_rank(TaskStatus.Unknown),    SD2_RANK["Unknown"])


# ---------------------------------------------------------------------------
# Test 2: per-task most-advanced State (unit, no filesystem)
# ---------------------------------------------------------------------------

class TestReconcilePerTaskState(unittest.TestCase):
    """_reconcile_same_work selects the most-advanced task State by SD-2."""

    def _make_wm(
        self,
        task_states: dict[str, str],
        updated: str = "2026-06-10T00:00:00Z",
        branch: str = "main",
    ) -> tuple[WorkModel, str, str]:
        from dashboard.reader.models import TaskModel
        tasks = [
            TaskModel(task_id=tid, type="IMPLEMENT", status=TaskStatus(st))
            for tid, st in task_states.items()
        ]
        wm = WorkModel(
            work_id="work-001-test",
            name="test",
            updated=updated,
            branch_label=branch,
            tasks=tasks,
        )
        return (wm, f"text-{branch}", f"label-{branch}")

    def test_done_beats_in_progress(self):
        copies = [
            self._make_wm({"task-001": "Done"},        updated="2026-06-10T10:00:00Z", branch="main"),
            self._make_wm({"task-001": "In Progress"}, updated="2026-06-10T09:00:00Z", branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.Done)

    def test_in_review_beats_blocked(self):
        copies = [
            self._make_wm({"task-001": "Blocked"},   updated="2026-06-10T10:00:00Z", branch="main"),
            self._make_wm({"task-001": "In Review"}, updated="2026-06-10T09:00:00Z", branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.InReview)

    def test_canceled_beats_failed(self):
        copies = [
            self._make_wm({"task-001": "Failed"},   updated="2026-06-10T10:00:00Z", branch="main"),
            self._make_wm({"task-001": "Canceled"}, updated="2026-06-10T09:00:00Z", branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.Canceled)

    def test_blocked_beats_failed(self):
        copies = [
            self._make_wm({"task-001": "Failed"},  updated="2026-06-10T10:00:00Z", branch="main"),
            self._make_wm({"task-001": "Blocked"}, updated="2026-06-10T09:00:00Z", branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.Blocked)

    def test_failed_beats_pending(self):
        copies = [
            self._make_wm({"task-001": "Pending"}, updated="2026-06-10T10:00:00Z", branch="main"),
            self._make_wm({"task-001": "Failed"},  updated="2026-06-10T09:00:00Z", branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.Failed)

    def test_all_sd2_pairs(self):
        """Exhaustive pairwise check: every state beats every less-advanced state."""
        states_ordered = ["Done", "Canceled", "In Review", "In Progress", "Blocked", "Failed", "Pending"]
        for i, more_adv in enumerate(states_ordered):
            for less_adv in states_ordered[i+1:]:
                with self.subTest(more_adv=more_adv, less_adv=less_adv):
                    copies = [
                        self._make_wm({"task-001": more_adv}, branch="main"),
                        self._make_wm({"task-001": less_adv}, branch="feat"),
                    ]
                    result, _, _ = _reconcile_same_work(copies)
                    self.assertEqual(
                        result.tasks[0].status.value, more_adv,
                        f"Expected {more_adv} to beat {less_adv}"
                    )

    def test_task_union_from_multiple_roots(self):
        """Tasks that appear on ONLY ONE root are included in the union."""
        copies = [
            self._make_wm({"task-001": "Done", "task-002": "In Progress"}, branch="main"),
            self._make_wm({"task-001": "In Progress", "task-003": "Blocked"}, branch="feat"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        task_ids = {t.task_id for t in result.tasks}
        self.assertIn("task-001", task_ids)
        self.assertIn("task-002", task_ids)
        self.assertIn("task-003", task_ids)

    def test_three_roots_task_state(self):
        """With 3 roots, the most-advanced across all three is selected."""
        copies = [
            self._make_wm({"task-001": "Pending"},     branch="main"),
            self._make_wm({"task-001": "In Progress"}, branch="feat-a"),
            self._make_wm({"task-001": "In Review"},   branch="feat-b"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.tasks[0].status, TaskStatus.InReview)


# ---------------------------------------------------------------------------
# Test 3: Pipeline State winner (newest Updated)
# ---------------------------------------------------------------------------

class TestReconcilePipelineStateWinner(unittest.TestCase):
    """_reconcile_same_work selects Pipeline State from the copy with newest Updated."""

    def _make_wm(
        self,
        lifecycle: str = "Running",
        updated: str = "2026-06-10T00:00:00Z",
        branch: str = "main",
        active_skill: str = "aid-execute",
        state_text: str = "",
    ) -> tuple[WorkModel, str, str]:
        from dashboard.reader.models import Lifecycle, Phase
        wm = WorkModel(
            work_id="work-001-test",
            name="test",
            lifecycle=Lifecycle(lifecycle),
            updated=updated,
            active_skill=active_skill,
            branch_label=branch,
        )
        return (wm, state_text or f"state-text-{branch}", f"label-{branch}")

    def test_newer_updated_wins(self):
        copies = [
            self._make_wm(lifecycle="Running",   updated="2026-06-10T09:00:00Z", branch="feat",
                          active_skill="aid-execute", state_text="text-older"),
            self._make_wm(lifecycle="Completed", updated="2026-06-10T12:00:00Z", branch="main",
                          active_skill="none", state_text="text-newer"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_wm.lifecycle.value, "Completed")
        self.assertEqual(result_text, "text-newer")

    def test_older_timestamp_does_not_win(self):
        copies = [
            self._make_wm(lifecycle="Completed", updated="2026-06-09T00:00:00Z", branch="main",
                          state_text="text-older"),
            self._make_wm(lifecycle="Running",   updated="2026-06-10T00:00:00Z", branch="feat",
                          state_text="text-newer"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_wm.lifecycle.value, "Running")
        self.assertEqual(result_text, "text-newer")

    def test_none_updated_loses_to_present(self):
        """A copy with no Updated timestamp always loses to one with a timestamp."""
        copies = [
            self._make_wm(lifecycle="Running",   updated="", branch="feat",
                          state_text="text-no-ts"),
            self._make_wm(lifecycle="Completed", updated="2026-01-01T00:00:00Z", branch="main",
                          state_text="text-with-ts"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_wm.lifecycle.value, "Completed")
        self.assertEqual(result_text, "text-with-ts")

    def test_three_copies_newest_wins(self):
        copies = [
            self._make_wm(updated="2026-06-10T09:00:00Z", branch="feat-a",
                          state_text="text-a"),
            self._make_wm(updated="2026-06-10T12:00:00Z", branch="main",
                          state_text="text-main"),
            self._make_wm(updated="2026-06-10T11:00:00Z", branch="feat-b",
                          state_text="text-b"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_text, "text-main")


# ---------------------------------------------------------------------------
# Test 4: Tie-break determinism (equal Updated)
# ---------------------------------------------------------------------------

class TestReconcileTieBreak(unittest.TestCase):
    """Equal Updated timestamps are broken by branch-label: 'main' sorts first."""

    def _make_wm(self, branch: str, updated: str = "2026-06-10T12:00:00Z",
                 lifecycle: str = "Running") -> tuple[WorkModel, str, str]:
        from dashboard.reader.models import Lifecycle
        wm = WorkModel(
            work_id="work-001-test",
            name="test",
            lifecycle=Lifecycle(lifecycle),
            updated=updated,
            branch_label=branch,
        )
        return (wm, f"text-{branch}", f"label-{branch}")

    def test_main_wins_on_tie(self):
        """When all Updated timestamps are equal, 'main' branch wins."""
        copies = [
            self._make_wm("feat-a"),
            self._make_wm("main"),
            self._make_wm("feat-b"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_text, "text-main")

    def test_tie_no_main_lexical(self):
        """When no 'main' branch, lexical sort determines the winner (a < b < z)."""
        copies = [
            self._make_wm("zzz-branch"),
            self._make_wm("aaa-branch"),
            self._make_wm("mmm-branch"),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        # 'aaa-branch' is lexically first (no 'main')
        self.assertEqual(result_text, "text-aaa-branch")

    def test_tie_both_none_updated_main_wins(self):
        """Both have no Updated; 'main' wins as the stable secondary key."""
        copies = [
            self._make_wm("feat-z", updated=""),
            self._make_wm("main",   updated=""),
        ]
        result_wm, result_text, _ = _reconcile_same_work(copies)
        self.assertEqual(result_text, "text-main")

    def test_order_independent_tie_break(self):
        """Same tie result regardless of input list order."""
        base = [
            self._make_wm("feat-a"),
            self._make_wm("main"),
            self._make_wm("feat-b"),
        ]
        result_a, text_a, _ = _reconcile_same_work(base)
        # Shuffle and re-run
        shuffled = list(base)
        shuffled.reverse()
        result_b, text_b, _ = _reconcile_same_work(shuffled)
        self.assertEqual(text_a, text_b)
        self.assertEqual(result_a.updated, result_b.updated)

    def test_two_copies_same_ts_main_always_wins(self):
        copies = [
            self._make_wm("feature-branch"),
            self._make_wm("main"),
        ]
        _, text, _ = _reconcile_same_work(copies)
        self.assertEqual(text, "text-main")

        copies_reversed = list(reversed(copies))
        _, text2, _ = _reconcile_same_work(copies_reversed)
        self.assertEqual(text2, "text-main")


# ---------------------------------------------------------------------------
# Test 5: Order independence
# ---------------------------------------------------------------------------

class TestReconcileOrderIndependence(unittest.TestCase):
    """Shuffling the input order produces identical reconcile output."""

    def _make_wm(
        self,
        task_states: dict[str, str],
        updated: str,
        branch: str,
    ) -> tuple[WorkModel, str, str]:
        from dashboard.reader.models import TaskModel
        tasks = [
            TaskModel(task_id=tid, type="IMPLEMENT", status=TaskStatus(st))
            for tid, st in task_states.items()
        ]
        wm = WorkModel(
            work_id="work-001-test",
            name="test",
            updated=updated,
            branch_label=branch,
            tasks=tasks,
        )
        return (wm, f"text-{branch}", f"label-{branch}")

    def test_shuffle_10_times_same_result(self):
        """10 different shuffles all produce the same reconciled model."""
        copies = [
            self._make_wm({"task-001": "Done",        "task-002": "Blocked"},  "2026-06-10T12:00:00Z", "main"),
            self._make_wm({"task-001": "In Progress", "task-003": "Pending"},  "2026-06-10T11:00:00Z", "feat-a"),
            self._make_wm({"task-001": "In Review",   "task-004": "Canceled"}, "2026-06-10T09:00:00Z", "feat-b"),
        ]
        baseline_wm, baseline_text, _ = _reconcile_same_work(copies)
        baseline_task_states = {t.task_id: t.status for t in baseline_wm.tasks}

        rng = random.Random(42)
        for i in range(10):
            shuffled = list(copies)
            rng.shuffle(shuffled)
            result_wm, result_text, _ = _reconcile_same_work(shuffled)
            result_task_states = {t.task_id: t.status for t in result_wm.tasks}
            with self.subTest(shuffle=i):
                self.assertEqual(result_text, baseline_text,
                                 f"Shuffle {i}: state_text mismatch")
                self.assertEqual(result_task_states, baseline_task_states,
                                 f"Shuffle {i}: task states mismatch")


# ---------------------------------------------------------------------------
# Test 6: Full integration fixture (filesystem-based, like the task spec)
# ---------------------------------------------------------------------------

class TestReconcileIntegration(unittest.TestCase):
    """Build a real filesystem fixture with same work_id on 2 roots and verify read_repo."""

    def setUp(self):
        import tempfile
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _build_worktree_fixture(
        self,
        main_tasks: list[tuple[str, str]],
        main_updated: str,
        wt_tasks: list[tuple[str, str]],
        wt_updated: str,
        work_id: str = "work-001-test-merge",
    ) -> Path:
        """Build root/.aid with work_id on main + a simulated second root.

        The second root is under tmp/worktree/ and is registered via the
        locator being called directly in tests (we can't do real git worktrees
        without git init). Instead we mock enumerate_worktree_roots directly.
        """
        root, aid = _make_repo(self.tmp)
        # Main root work
        work_main = aid / work_id
        work_main.mkdir(parents=True, exist_ok=True)
        (work_main / "STATE.md").write_text(
            _state_text(updated=main_updated, tasks=main_tasks),
            encoding="utf-8",
        )
        return root

    def test_same_work_on_two_roots_merges_to_one(self):
        """read_repo with a mocked second root returns 1 work model (not 2)."""
        root, aid = _make_repo(self.tmp)
        work_id = "work-001-merge"

        # Main root work
        work_main = aid / work_id
        work_main.mkdir(parents=True, exist_ok=True)
        (work_main / "STATE.md").write_text(
            _state_text(
                updated="2026-06-10T09:00:00Z",
                tasks=[("task-001", "In Progress"), ("task-002", "Pending")],
            ),
            encoding="utf-8",
        )

        # Simulate a second root with the same work_id (a worktree)
        wt_root = self.tmp / "worktree-feat"
        wt_aid = wt_root / ".aid"
        (wt_aid / work_id).mkdir(parents=True, exist_ok=True)
        (wt_aid / work_id / "STATE.md").write_text(
            _state_text(
                updated="2026-06-10T12:00:00Z",   # NEWER
                tasks=[("task-001", "Done"), ("task-003", "Blocked")],
            ),
            encoding="utf-8",
        )

        # Patch enumerate_worktree_roots to return both roots
        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[
                ("main",         aid),
                ("feat-branch",  wt_aid),
            ],
        ):
            model = read_repo(root)

        # After reconcile: EXACTLY 1 work model (not 2)
        self.assertEqual(len(model.works), 1,
                         f"Expected 1 work; got {len(model.works)}: {[w.work_id for w in model.works]}")
        self.assertEqual(model.read.work_count, 1)

        w = model.works[0]
        self.assertEqual(w.work_id, work_id)

        # Pipeline State: newer Updated wins (feat-branch had 2026-06-10T12:00:00Z)
        self.assertEqual(w.updated, "2026-06-10T12:00:00Z")

        # Per-task State: most-advanced
        task_map = {t.task_id: t.status for t in w.tasks}
        self.assertEqual(task_map["task-001"], TaskStatus.Done,
                         "task-001: Done beats In Progress")

        # Union: task-002 (only on main) and task-003 (only on feat) both present
        self.assertIn("task-002", task_map)
        self.assertIn("task-003", task_map)
        self.assertEqual(task_map["task-002"], TaskStatus.Pending)
        self.assertEqual(task_map["task-003"], TaskStatus.Blocked)

    def test_work_count_is_1_after_reconcile(self):
        """model.read.work_count reflects deduplicated count (1, not 2)."""
        root, aid = _make_repo(self.tmp)
        work_id = "work-002-count-check"
        (aid / work_id).mkdir(parents=True, exist_ok=True)
        (aid / work_id / "STATE.md").write_text(
            _state_text(updated="2026-06-01T00:00:00Z", tasks=[("task-001", "Pending")]),
            encoding="utf-8",
        )
        wt_root = self.tmp / "wt"
        wt_aid = wt_root / ".aid"
        (wt_aid / work_id).mkdir(parents=True, exist_ok=True)
        (wt_aid / work_id / "STATE.md").write_text(
            _state_text(updated="2026-06-02T00:00:00Z", tasks=[("task-001", "In Progress")]),
            encoding="utf-8",
        )

        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid), ("feat", wt_aid)],
        ):
            model = read_repo(root)

        self.assertEqual(model.read.work_count, 1)

    def test_state_text_cache_holds_winner(self):
        """MEDIUM #3 fix: state_text_cache maps work_id -> winner's text (newest Updated)."""
        from dashboard.reader.reader import _read_repo_full
        root, aid = _make_repo(self.tmp)
        work_id = "work-003-cache-fix"

        older_text = _state_text(
            updated="2026-06-09T00:00:00Z",
            tasks=[("task-001", "Pending")],
        )
        newer_text = _state_text(
            updated="2026-06-10T00:00:00Z",
            tasks=[("task-001", "Done")],
        )

        (aid / work_id).mkdir(parents=True, exist_ok=True)
        (aid / work_id / "STATE.md").write_text(older_text, encoding="utf-8")

        wt_root = self.tmp / "wt2"
        wt_aid = wt_root / ".aid"
        (wt_aid / work_id).mkdir(parents=True, exist_ok=True)
        (wt_aid / work_id / "STATE.md").write_text(newer_text, encoding="utf-8")

        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid), ("feat", wt_aid)],
        ):
            model, cache = _read_repo_full(root)

        # Cache must have the work_id key
        self.assertIn(work_id, cache)
        cached_text, _ = cache[work_id]
        # Winner is the one with newer Updated (feat branch / newer_text)
        self.assertIn("2026-06-10T00:00:00Z", cached_text,
                      "Cache should hold the text from the newest-Updated root")
        self.assertNotIn("2026-06-09T00:00:00Z", cached_text,
                         "Cache must NOT hold the older root's text")


# ---------------------------------------------------------------------------
# Test 7: Never throws on malformed input
# ---------------------------------------------------------------------------

class TestReconcileNeverThrows(unittest.TestCase):
    """_reconcile_same_work and the full read path never throw on bad input."""

    def test_empty_copies_is_not_called_but_survives_single_copy(self):
        """Single-element list: trivial pass-through."""
        wm = WorkModel(work_id="work-001-x", name="x", updated=None, branch_label="main")
        result_wm, text, label = _reconcile_same_work([(wm, "text", "label")])
        self.assertEqual(result_wm.work_id, "work-001-x")

    def test_none_updated_on_all_copies_does_not_throw(self):
        """All copies have None updated: still returns deterministically."""
        wm1 = WorkModel(work_id="work-001-y", name="y", updated=None, branch_label="main")
        wm2 = WorkModel(work_id="work-001-y", name="y", updated=None, branch_label="feat")
        result_wm, _, _ = _reconcile_same_work([(wm1, "t1", "l1"), (wm2, "t2", "l2")])
        # main should win (secondary tie-break)
        self.assertIsNotNone(result_wm)

    def test_unknown_task_status_does_not_throw(self):
        """Tasks with Unknown status are handled (ranked as least advanced)."""
        from dashboard.reader.models import TaskModel
        tasks_a = [TaskModel(task_id="task-001", type="X", status=TaskStatus.Unknown)]
        tasks_b = [TaskModel(task_id="task-001", type="X", status=TaskStatus.Pending)]
        wm_a = WorkModel(work_id="w", name="w", updated="2026-01-01T00:00:00Z",
                         branch_label="main", tasks=tasks_a)
        wm_b = WorkModel(work_id="w", name="w", updated="2026-01-01T00:00:00Z",
                         branch_label="feat", tasks=tasks_b)
        result, _, _ = _reconcile_same_work(
            [(wm_a, "ta", "la"), (wm_b, "tb", "lb")]
        )
        # Pending(6) beats Unknown(7)
        self.assertEqual(result.tasks[0].status, TaskStatus.Pending)

    def test_malformed_state_md_on_disk_does_not_throw(self):
        """read_repo with a truncated STATE.md on one root never throws."""
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            root_, aid = _make_repo(root)
            work_id = "work-001-bad"
            (aid / work_id).mkdir(parents=True, exist_ok=True)
            (aid / work_id / "STATE.md").write_text(
                "## Pipeline Status\n\n- **Lifecycle",  # truncated
                encoding="utf-8",
            )
            model = read_repo(root)
        self.assertIsNotNone(model)
        # Should NOT raise; may have parse_warnings

    def test_missing_state_md_on_one_root_does_not_throw(self):
        """read_repo when STATE.md is absent on the second root never throws."""
        import tempfile
        import unittest.mock as mock
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            root_, aid = _make_repo(root)
            work_id = "work-001-nostate"

            # Main root has STATE.md
            (aid / work_id).mkdir(parents=True, exist_ok=True)
            (aid / work_id / "STATE.md").write_text(
                _state_text(updated="2026-06-10T00:00:00Z", tasks=[("task-001", "Done")]),
                encoding="utf-8",
            )

            # Second root has no STATE.md
            wt_aid = Path(d) / "wt" / ".aid"
            (wt_aid / work_id).mkdir(parents=True, exist_ok=True)
            # Deliberately omit STATE.md

            with mock.patch(
                "dashboard.reader.reader.enumerate_worktree_roots",
                return_value=[("main", aid), ("feat", wt_aid)],
            ):
                model = read_repo(root)

        self.assertIsNotNone(model)
        # Should not raise; work should still be present


# ---------------------------------------------------------------------------
# Test 8: Distinct works are NOT merged
# ---------------------------------------------------------------------------

class TestReconcileDistinctWorks(unittest.TestCase):
    """Works with different work_ids are NOT merged — each keeps its own model."""

    def test_two_different_work_ids_not_merged(self):
        """work-001 and work-002 must remain distinct after read_repo."""
        import tempfile
        import unittest.mock as mock
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            root_, aid = _make_repo(root)

            for wid in ["work-001-alpha", "work-002-beta"]:
                (aid / wid).mkdir(parents=True, exist_ok=True)
                (aid / wid / "STATE.md").write_text(
                    _state_text(updated="2026-06-10T00:00:00Z", tasks=[("task-001", "Done")]),
                    encoding="utf-8",
                )

            with mock.patch(
                "dashboard.reader.reader.enumerate_worktree_roots",
                return_value=[("main", aid)],
            ):
                model = read_repo(root)

        self.assertEqual(len(model.works), 2)
        work_ids = {w.work_id for w in model.works}
        self.assertIn("work-001-alpha", work_ids)
        self.assertIn("work-002-beta", work_ids)


# ---------------------------------------------------------------------------
# Test 9: source_mode propagation
# ---------------------------------------------------------------------------

class TestReconcileSourceMode(unittest.TestCase):
    """source_mode is Normalized if any copy is Normalized."""

    def _make_wm(self, mode: SourceMode, branch: str) -> tuple[WorkModel, str, str]:
        wm = WorkModel(
            work_id="work-001-sm",
            name="sm",
            source_mode=mode,
            updated="2026-01-01T00:00:00Z",
            branch_label=branch,
        )
        return (wm, f"text-{branch}", f"label-{branch}")

    def test_normalized_wins_over_fallback(self):
        copies = [
            self._make_wm(SourceMode.Fallback,   "feat"),
            self._make_wm(SourceMode.Normalized, "main"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.source_mode, SourceMode.Normalized)

    def test_all_fallback_stays_fallback(self):
        copies = [
            self._make_wm(SourceMode.Fallback, "feat"),
            self._make_wm(SourceMode.Fallback, "main"),
        ]
        result, _, _ = _reconcile_same_work(copies)
        self.assertEqual(result.source_mode, SourceMode.Fallback)


if __name__ == "__main__":
    unittest.main(verbosity=2)
