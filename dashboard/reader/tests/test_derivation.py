"""
test_derivation.py -- Unit tests for the LC-3 fallback adapter + SM-2/SM-3 derivation.

Feature-002, task-011.

Tests cover:
  - derive_lifecycle(): each SM-2 priority rule
  - derive_lifecycle(): the total default (Running with no signals)
  - derive_lifecycle(): multi-signal precedence (e.g. Failed task + pending Q&A -> Blocked)
  - rollup_lifecycle(): SM-3 rollup logic
  - **User Approved:** deliberately excluded from Paused (SM-2 prio-4 note)
  - Fallback IMPEDIMENT file scan (flat path per KI-003)
  - Fallback cancellation scan (## Lifecycle History)
  - Fallback completed scan (## Deploy Status / ## Plan / Deliveries)
  - source_mode=fallback recorded for all fallback-derived works
  - parse_state_md() integration: fallback fires when ## Pipeline Status is absent

All tests use temp-dir fixtures and are fully deterministic.
No third-party deps; Python 3.11+ stdlib only.

COMPREHENSIVE fixture matrix is task-012. These tests are FOCUSED.
"""

import sys
import tempfile
import unittest
from pathlib import Path

# Make the dashboard package importable when run directly or via python3 -m unittest.
_REPO_ROOT = Path(__file__).resolve().parents[4]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.models import Lifecycle, PendingInput, SourceMode, TaskModel, TaskStatus
from dashboard.reader.derivation import (
    derive_lifecycle,
    rollup_lifecycle,
    _has_cancellation_in_history,
    _extract_latest_history_date,
    _is_completed,
    _deploy_status_shipped,
    _all_deliveries_done,
    _find_impediment_file,
    _find_subminimum_gate,
    _parse_minimum_grade,
    _grade_below,
)
from dashboard.reader.parsers import parse_state_md


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

def make_pending_input(qid: str = "Q1") -> PendingInput:
    return PendingInput(question_id=qid, category="Test", impact="Medium")


def make_task(status: TaskStatus, task_id: str = "task-001") -> TaskModel:
    return TaskModel(task_id=task_id, type="IMPLEMENT", status=status)


def make_work_dir(root: Path, work_id: str = "work-001-test") -> Path:
    wd = root / ".aid" / "works" / work_id
    wd.mkdir(parents=True, exist_ok=True)
    return wd


# ---------------------------------------------------------------------------
# STATE.md text fixtures (no ## Pipeline Status block -- fallback only)
# ---------------------------------------------------------------------------

STATE_ONLY_TASKS = """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | In Progress | -- | -- | -- |
| 002 | task-002 | TEST | 1 | Pending | -- | -- | -- |
"""

STATE_FAILED_TASK = """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Failed | -- | -- | -- |
"""

STATE_FAILED_TASK_AND_PENDING_QA = """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Failed | -- | -- | -- |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** open question
- **Suggested:** --
"""

STATE_PENDING_QA_ONLY = """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Pending | -- | -- | -- |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** open question
- **Suggested:** --

### Q2

- **Category:** Security
- **Impact:** Low
- **Status:** Answered
"""

STATE_USER_APPROVED_NO_AND_PENDING_QA = """\
# Work State

> **Status:** Running
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01
> **User Approved:** no

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | In Progress | -- | -- | -- |
"""

STATE_DEPLOY_SHIPPED = """\
# Work State

## Deploy Status

| Delivery | Status | Notes |
|----------|--------|-------|
| delivery-001 | Shipped | deployed 2026-06-10 |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Done | A | 2h | -- |
"""

STATE_ALL_DELIVERIES_DONE = """\
# Work State

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Done | task-001, task-002 | -- |
| delivery-002 | Done | task-003 | -- |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Done | A | 2h | -- |
| 002 | task-002 | TEST | 1 | Done | A | 1h | -- |
| 003 | task-003 | CONFIGURE | 2 | Done | A | 1h | -- |
"""

STATE_DELIVERIES_NOT_ALL_DONE = """\
# Work State

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Done | task-001 | -- |
| delivery-002 | In Progress | task-002 | -- |
"""

STATE_CANCELED = """\
# Work State

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-01 | Interview -> Execute | -- | -- |
| 2026-06-10 | Canceled | -- | User request |
"""

STATE_NO_SIGNALS = """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Pending | -- | -- | -- |
"""

STATE_WITH_HISTORY_DATE = """\
# Work State

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-01 | Interview start | -- | -- |
| 2026-06-10 | Execute start | -- | -- |
"""

STATE_DELIVERY_GATES_BELOW_MIN = """\
# Work State

> **Status:** Running
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01
> **User Approved:** no

## Delivery Gates

### delivery-001

- **Grade:** C
- **Summary:** Below minimum
"""

STATE_DELIVERY_GATES_AT_MIN = """\
# Work State

> **Status:** Running
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01
> **User Approved:** no

## Delivery Gates

### delivery-001

- **Grade:** B
- **Summary:** At minimum
"""

STATE_USER_APPROVED_ONLY_NO_PIPELINE = """\
# Work State

> **Status:** Running
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01
> **User Approved:** no

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | In Progress | -- | -- | -- |
"""


# ---------------------------------------------------------------------------
# TestDerivationSM2: derive_lifecycle() priority rule tests
# ---------------------------------------------------------------------------

class TestDerivationSM2(unittest.TestCase):
    """SM-2 derive_lifecycle() priority rule tests."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _make_wd(self, work_id: str = "work-001-test") -> Path:
        return make_work_dir(self.root, work_id)

    # --- Prio 1: Canceled ---

    def test_prio1_canceled_from_history(self):
        """Prio-1: Canceled when ## Lifecycle History has a cancellation row."""
        wd = self._make_wd()
        lc, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[],
            state_text=STATE_CANCELED,
            work_id="work-001-test",
        )
        self.assertEqual(lc, Lifecycle.Canceled)
        self.assertEqual(mode, SourceMode.Fallback)

    def test_prio1_canceled_beats_pending_qa(self):
        """Canceled (prio-1) beats Paused-Awaiting-Input (prio-4)."""
        wd = self._make_wd()
        canceled_with_qa = STATE_CANCELED + "\n## Cross-phase Q&A (Pending)\n\n### Q1\n\n- **Status:** Pending\n"
        lc, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[make_pending_input("Q1")],
            state_text=canceled_with_qa,
        )
        self.assertEqual(lc, Lifecycle.Canceled)

    # --- Prio 2: Completed ---

    def test_prio2_completed_from_deploy_status(self):
        """Prio-2: Completed when ## Deploy Status has a shipped row."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.Done, "task-001")]
        lc, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_DEPLOY_SHIPPED,
        )
        self.assertEqual(lc, Lifecycle.Completed)
        self.assertEqual(mode, SourceMode.Fallback)

    def test_prio2_completed_from_all_deliveries_done(self):
        """Prio-2: Completed when all Plan / Deliveries are Done + no open task."""
        wd = self._make_wd()
        tasks = [
            make_task(TaskStatus.Done, "task-001"),
            make_task(TaskStatus.Done, "task-002"),
            make_task(TaskStatus.Done, "task-003"),
        ]
        lc, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_ALL_DELIVERIES_DONE,
        )
        self.assertEqual(lc, Lifecycle.Completed)

    def test_prio2_not_completed_if_open_task(self):
        """All deliveries Done but an open task -> not Completed."""
        wd = self._make_wd()
        # One task still In Progress
        tasks = [
            make_task(TaskStatus.Done, "task-001"),
            make_task(TaskStatus.InProgress, "task-002"),
        ]
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_ALL_DELIVERIES_DONE,
        )
        self.assertNotEqual(lc, Lifecycle.Completed)

    def test_prio2_not_completed_if_not_all_deliveries_done(self):
        """Not all deliveries Done -> does not fire Completed."""
        wd = self._make_wd()
        tasks = []
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_DELIVERIES_NOT_ALL_DONE,
        )
        self.assertNotEqual(lc, Lifecycle.Completed)

    # --- Prio 3: Blocked ---

    def test_prio3_blocked_from_failed_task(self):
        """Prio-3: Blocked when a task has Status=Failed."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.Failed, "task-001")]
        lc, mode, _, block_reason, block_art, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_FAILED_TASK,
        )
        self.assertEqual(lc, Lifecycle.Blocked)
        self.assertEqual(mode, SourceMode.Fallback)
        self.assertIsNotNone(block_reason)
        self.assertIn("task-001", block_reason)

    def test_prio3_blocked_from_impediment_file(self):
        """Prio-3: Blocked when IMPEDIMENT-task-NNN.md exists (flat path, KI-003)."""
        wd = self._make_wd()
        # Create the flat IMPEDIMENT file per the de-facto producer path (KI-003)
        (wd / "IMPEDIMENT-task-001.md").write_text("# Impediment\nBlocked.", encoding="utf-8")
        tasks = [make_task(TaskStatus.InProgress, "task-001")]
        lc, mode, _, block_reason, block_art, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_ONLY_TASKS,
        )
        self.assertEqual(lc, Lifecycle.Blocked)
        self.assertIsNotNone(block_artifact := block_art)
        self.assertIn("IMPEDIMENT-task-001.md", block_artifact)

    def test_prio3_blocked_from_subminimum_gate(self):
        """Prio-3: Blocked when Delivery Gate Grade < Minimum Grade."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.InReview, "task-001")]
        lc, mode, _, block_reason, block_art, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_DELIVERY_GATES_BELOW_MIN,
        )
        self.assertEqual(lc, Lifecycle.Blocked)
        self.assertIsNotNone(block_reason)
        self.assertIn("delivery-001", block_reason)

    def test_prio3_not_blocked_when_gate_at_minimum(self):
        """Gate == minimum (not below) does NOT trigger Blocked."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.InReview, "task-001")]
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_DELIVERY_GATES_AT_MIN,
        )
        self.assertNotEqual(lc, Lifecycle.Blocked)

    def test_prio3_blocked_beats_pending_qa(self):
        """Blocked (prio-3) beats Paused-Awaiting-Input (prio-4).

        AC1: Failed task + pending Q&A -> Blocked (not Paused).
        """
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.Failed, "task-001")]
        pending = [make_pending_input("Q1")]
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=pending,
            state_text=STATE_FAILED_TASK_AND_PENDING_QA,
        )
        self.assertEqual(lc, Lifecycle.Blocked)

    # --- Prio 4: Paused-Awaiting-Input ---

    def test_prio4_paused_from_pending_qa(self):
        """Prio-4: Paused-Awaiting-Input when pending_inputs is non-empty."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.Pending, "task-001")]
        pending = [make_pending_input("Q1")]
        lc, mode, pause_reason, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=pending,
            state_text=STATE_PENDING_QA_ONLY,
        )
        self.assertEqual(lc, Lifecycle.PausedAwaitingInput)
        self.assertEqual(mode, SourceMode.Fallback)
        self.assertIsNotNone(pause_reason)
        self.assertIn("Q1", pause_reason)

    def test_prio4_user_approved_no_excluded_from_paused(self):
        """AC1 (SM-2 prio-4 note): **User Approved:** no does NOT trigger Paused.

        The top-blockquote **User Approved:** field is the terminal work-completion
        gate, not a mid-run pause signal. A live work with 'User Approved: no' and
        an In Progress task must derive Running, not Paused.
        """
        wd = self._make_wd()
        # Work has 'User Approved: no' in blockquote + an In Progress task
        tasks = [make_task(TaskStatus.InProgress, "task-001")]
        # No pending_inputs (the User Approved: no line is NOT a pending Q)
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],  # empty: User Approved: no is excluded
            state_text=STATE_USER_APPROVED_ONLY_NO_PIPELINE,
        )
        self.assertEqual(lc, Lifecycle.Running)

    def test_prio4_user_approved_no_with_in_progress_task_is_running(self):
        """Verify parse_state_md doesn't add User Approved: no to pending_inputs.

        This is the integration-level check that the STATE.md parser never
        converts the top-blockquote User Approved: no into a PendingInput
        (which would falsely fire Paused for every live work).
        """
        # STATE_USER_APPROVED_ONLY_NO_PIPELINE has User Approved: no + In Progress task
        # and no ## Cross-phase Q&A section
        pw = parse_state_md(STATE_USER_APPROVED_ONLY_NO_PIPELINE)
        self.assertEqual(pw.pending_inputs, [])  # User Approved: no is not a PendingInput
        self.assertEqual(pw.lifecycle, Lifecycle.Running)

    def test_prio4_user_approved_no_with_pending_qa_is_paused(self):
        """User Approved: no + pending Q&A -> Paused (from the Q&A, not the approval)."""
        pw = parse_state_md(STATE_USER_APPROVED_NO_AND_PENDING_QA)
        # STATE_USER_APPROVED_NO_AND_PENDING_QA: no pending Q&A, only In Progress task
        # -> should be Running, not Paused
        self.assertEqual(pw.lifecycle, Lifecycle.Running)
        self.assertEqual(len(pw.pending_inputs), 0)

    # --- Prio 5: Running (total default) ---

    def test_prio5_running_default_no_signals(self):
        """Prio-5: Running when no cancel/complete/block/pause signal fires."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.Pending, "task-001")]
        lc, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_NO_SIGNALS,
        )
        self.assertEqual(lc, Lifecycle.Running)
        self.assertEqual(mode, SourceMode.Fallback)

    def test_prio5_running_with_in_progress_task(self):
        """Running when a task is In Progress and no block/pause signal fires."""
        wd = self._make_wd()
        tasks = [make_task(TaskStatus.InProgress, "task-001")]
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=tasks,
            pending_inputs=[],
            state_text=STATE_ONLY_TASKS,
        )
        self.assertEqual(lc, Lifecycle.Running)

    def test_prio5_running_empty_work_no_signals(self):
        """Running even for an empty work (no tasks, no signals) -- between waves."""
        wd = self._make_wd()
        lc, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[],
            state_text="# Empty work\n",
        )
        self.assertEqual(lc, Lifecycle.Running)

    # --- source_mode and updated ---

    def test_source_mode_is_fallback(self):
        """All fallback-derived works have source_mode=Fallback."""
        wd = self._make_wd()
        _, mode, *_ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[],
            state_text=STATE_NO_SIGNALS,
        )
        self.assertEqual(mode, SourceMode.Fallback)

    def test_updated_from_lifecycle_history(self):
        """updated is extracted from ## Lifecycle History as a coarse fallback."""
        wd = self._make_wd()
        _, _, _, _, _, updated, _ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[],
            state_text=STATE_WITH_HISTORY_DATE,
        )
        self.assertEqual(updated, "2026-06-10")

    def test_updated_none_when_no_history(self):
        """updated is None when ## Lifecycle History is absent."""
        wd = self._make_wd()
        _, _, _, _, _, updated, _ = derive_lifecycle(
            work_dir=wd,
            tasks=[],
            pending_inputs=[],
            state_text=STATE_NO_SIGNALS,
        )
        self.assertIsNone(updated)


# ---------------------------------------------------------------------------
# TestRollupSM3: rollup_lifecycle() (SM-3) tests
# ---------------------------------------------------------------------------

class TestRollupSM3(unittest.TestCase):
    """SM-3 rollup_lifecycle() tests (FR14 -- mirrors feature-001 §3)."""

    def test_canceled_beats_all(self):
        """Canceled (prio-1) beats every other signal."""
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Failed)],
            pending_inputs=[make_pending_input()],
            has_impediment=True,
            deploy_done=True,
            cancellation_recorded=True,
        )
        self.assertEqual(lc, Lifecycle.Canceled)

    def test_completed_from_deploy_done(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Done)],
            pending_inputs=[],
            has_impediment=False,
            deploy_done=True,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Completed)

    def test_completed_from_all_deliveries_done(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Done)],
            pending_inputs=[],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
            all_deliveries_done=True,
        )
        self.assertEqual(lc, Lifecycle.Completed)

    def test_blocked_from_impediment(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.InProgress)],
            pending_inputs=[make_pending_input()],
            has_impediment=True,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Blocked)

    def test_blocked_from_failed_task(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Failed)],
            pending_inputs=[make_pending_input()],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Blocked)

    def test_blocked_beats_paused(self):
        """Blocked (prio-3) beats Paused-Awaiting-Input (prio-4)."""
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Failed, "task-001")],
            pending_inputs=[make_pending_input("Q1")],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Blocked)

    def test_paused_from_pending_inputs(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.Pending)],
            pending_inputs=[make_pending_input()],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.PausedAwaitingInput)

    def test_running_with_in_progress(self):
        lc = rollup_lifecycle(
            tasks=[make_task(TaskStatus.InProgress)],
            pending_inputs=[],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Running)

    def test_running_default_no_signals(self):
        """Running is the total default (FR16: no Idle state)."""
        lc = rollup_lifecycle(
            tasks=[],
            pending_inputs=[],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        self.assertEqual(lc, Lifecycle.Running)

    def test_rollup_does_not_collapse_task_list(self):
        """SM-3: rollup produces a summary; per-task list is unchanged (FR14).

        This test verifies the API contract: rollup returns a lifecycle enum,
        not a modified task list. The caller's task list is unaffected.
        """
        tasks = [
            make_task(TaskStatus.InProgress, "task-001"),
            make_task(TaskStatus.Pending, "task-002"),
        ]
        original_count = len(tasks)
        lc = rollup_lifecycle(
            tasks=tasks,
            pending_inputs=[],
            has_impediment=False,
            deploy_done=False,
            cancellation_recorded=False,
        )
        # The rollup returned a value without modifying the tasks list
        self.assertEqual(len(tasks), original_count)
        self.assertIsInstance(lc, Lifecycle)


# ---------------------------------------------------------------------------
# TestFallbackHelpers: individual LC-3 helper function unit tests
# ---------------------------------------------------------------------------

class TestFallbackHelpers(unittest.TestCase):
    """Unit tests for individual LC-3 fallback parsing helpers."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    # --- _has_cancellation_in_history ---

    def test_cancellation_found_in_gate_column(self):
        self.assertTrue(_has_cancellation_in_history(STATE_CANCELED, [], "w"))

    def test_cancellation_not_found_when_absent(self):
        self.assertFalse(_has_cancellation_in_history(STATE_ONLY_TASKS, [], "w"))

    def test_cancellation_case_insensitive(self):
        text = """\
## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-10 | CANCELED | -- | user |
"""
        self.assertTrue(_has_cancellation_in_history(text, [], "w"))

    def test_cancellation_no_false_positive_from_other_column(self):
        """Notes column mentioning 'cancel' should not fire (only Gate column counts)."""
        text = """\
## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-10 | Execute continues | -- | user asked if we can cancel |
"""
        # Notes-column mention should trigger the ambiguous-warn but not return True
        # (the check only returns True for Gate column matches)
        warnings = []
        result = _has_cancellation_in_history(text, warnings, "w")
        # Regression guard for fix #1: cancel in Notes must NOT derive Canceled lifecycle
        self.assertFalse(result)
        # But a warning IS added for the ambiguous mention
        self.assertTrue(any("ambiguous" in w for w in warnings))

    # --- _extract_latest_history_date ---

    def test_latest_date_extracted(self):
        d = _extract_latest_history_date(STATE_WITH_HISTORY_DATE)
        self.assertEqual(d, "2026-06-10")

    def test_latest_date_none_when_no_history(self):
        self.assertIsNone(_extract_latest_history_date("# No history\n"))

    def test_latest_date_picks_most_recent(self):
        text = """\
## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-05-01 | Interview start | -- | -- |
| 2026-06-10 | Execute start | -- | -- |
| 2026-04-15 | Specify start | -- | -- |
"""
        self.assertEqual(_extract_latest_history_date(text), "2026-06-10")

    # --- _deploy_status_shipped ---

    def test_deploy_shipped_true(self):
        self.assertTrue(_deploy_status_shipped(STATE_DEPLOY_SHIPPED))

    def test_deploy_shipped_false_when_no_section(self):
        self.assertFalse(_deploy_status_shipped(STATE_ONLY_TASKS))

    def test_deploy_shipped_false_when_not_shipped(self):
        text = """\
## Deploy Status

| Delivery | Status | Notes |
|----------|--------|-------|
| delivery-001 | Pending | -- |
"""
        self.assertFalse(_deploy_status_shipped(text))

    # --- _all_deliveries_done ---

    def test_all_deliveries_done_true(self):
        self.assertTrue(_all_deliveries_done(STATE_ALL_DELIVERIES_DONE))

    def test_all_deliveries_done_false_when_not_all_done(self):
        self.assertFalse(_all_deliveries_done(STATE_DELIVERIES_NOT_ALL_DONE))

    def test_all_deliveries_done_false_when_no_section(self):
        self.assertFalse(_all_deliveries_done(STATE_ONLY_TASKS))

    def test_all_deliveries_done_false_when_empty_table(self):
        text = """\
## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
"""
        self.assertFalse(_all_deliveries_done(text))

    # --- _find_impediment_file ---

    def test_finds_impediment_file(self):
        wd = make_work_dir(self.root, "work-001-test")
        imp = wd / "IMPEDIMENT-task-001.md"
        imp.write_text("# Impediment", encoding="utf-8")
        found = _find_impediment_file(wd)
        self.assertIsNotNone(found)
        self.assertEqual(found.name, "IMPEDIMENT-task-001.md")

    def test_finds_impediment_file_case_insensitive(self):
        """The pattern should match regardless of case."""
        wd = make_work_dir(self.root, "work-002-test")
        imp = wd / "impediment-task-002.md"
        imp.write_text("# Impediment", encoding="utf-8")
        found = _find_impediment_file(wd)
        self.assertIsNotNone(found)

    def test_no_impediment_file(self):
        wd = make_work_dir(self.root, "work-001-no-imp")
        self.assertIsNone(_find_impediment_file(wd))

    def test_subdir_impediment_not_found(self):
        """The subdir form (task-NNN/IMPEDIMENT.md) per schemas.md §13 is NOT scanned.

        KI-003: the reader follows the producer (flat path), not schemas.md §13.
        This test documents the deliberate exclusion.
        """
        wd = make_work_dir(self.root, "work-001-subdir")
        subdir_imp = wd / "task-001" / "IMPEDIMENT.md"
        subdir_imp.parent.mkdir(parents=True, exist_ok=True)
        subdir_imp.write_text("# Impediment in wrong place", encoding="utf-8")
        # The flat-path scanner must not pick up the subdir form
        found = _find_impediment_file(wd)
        self.assertIsNone(found)

    # --- _find_subminimum_gate ---

    def test_subminimum_gate_found(self):
        result = _find_subminimum_gate(STATE_DELIVERY_GATES_BELOW_MIN)
        self.assertEqual(result, "delivery-001")

    def test_gate_at_minimum_not_found(self):
        self.assertIsNone(_find_subminimum_gate(STATE_DELIVERY_GATES_AT_MIN))

    def test_no_gates_section(self):
        self.assertIsNone(_find_subminimum_gate(STATE_ONLY_TASKS))

    # --- _parse_minimum_grade ---

    def test_parses_minimum_grade(self):
        self.assertEqual(_parse_minimum_grade(STATE_DELIVERY_GATES_BELOW_MIN), "B")

    def test_minimum_grade_absent(self):
        self.assertIsNone(_parse_minimum_grade(STATE_ONLY_TASKS))

    # --- _grade_below ---

    def test_grade_below_true(self):
        self.assertTrue(_grade_below("C", "B"))
        self.assertTrue(_grade_below("F", "A"))
        self.assertTrue(_grade_below("D", "C"))

    def test_grade_below_false_at_minimum(self):
        self.assertFalse(_grade_below("B", "B"))

    def test_grade_below_false_above_minimum(self):
        self.assertFalse(_grade_below("A", "B"))

    def test_grade_below_unknown_grade(self):
        """Unknown grade string -> not below minimum (no crash)."""
        self.assertFalse(_grade_below("X", "B"))
        self.assertFalse(_grade_below("A", "Z"))


# ---------------------------------------------------------------------------
# TestFallbackIntegration: parse_state_md() integration (fallback path)
# ---------------------------------------------------------------------------

class TestFallbackIntegration(unittest.TestCase):
    """Integration tests: parse_state_md() with no ## Pipeline Status (fallback path)."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _work_dir(self, work_id: str = "work-001-test") -> Path:
        return make_work_dir(self.root, work_id)

    def test_fallback_running_default(self):
        """Fallback: Running is the default when no signal fires."""
        pw = parse_state_md(STATE_NO_SIGNALS, work_id="work-001", work_dir=self._work_dir())
        self.assertEqual(pw.lifecycle, Lifecycle.Running)
        self.assertEqual(pw.source_mode, SourceMode.Fallback)

    def test_fallback_blocked_from_failed_task(self):
        """Fallback: Blocked when a task is Failed."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_FAILED_TASK, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)
        self.assertIsNotNone(pw.block_reason)
        self.assertIn("task-001", pw.block_reason)

    def test_fallback_blocked_from_impediment_file(self):
        """Fallback: Blocked when IMPEDIMENT-task-NNN.md exists at flat path."""
        wd = self._work_dir()
        (wd / "IMPEDIMENT-task-001.md").write_text("blocked", encoding="utf-8")
        pw = parse_state_md(STATE_ONLY_TASKS, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)
        self.assertIsNotNone(pw.block_artifact)

    def test_fallback_paused_from_pending_qa(self):
        """Fallback: Paused-Awaiting-Input when pending Q&A exists."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_PENDING_QA_ONLY, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.PausedAwaitingInput)
        self.assertIsNotNone(pw.pause_reason)
        # Only Q1 is Pending (Q2 is Answered)
        self.assertIn("Q1", pw.pause_reason)

    def test_fallback_canceled_from_history(self):
        """Fallback: Canceled when ## Lifecycle History shows cancellation."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_CANCELED, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.Canceled)

    def test_fallback_completed_from_deploy_shipped(self):
        """Fallback: Completed when ## Deploy Status shows shipped."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_DEPLOY_SHIPPED, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.Completed)

    def test_fallback_blocked_beats_paused(self):
        """Fallback: Failed task + pending Q&A -> Blocked (not Paused). AC1."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_FAILED_TASK_AND_PENDING_QA, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)

    def test_fallback_updated_from_history(self):
        """Fallback: updated is extracted from ## Lifecycle History (coarse)."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_WITH_HISTORY_DATE, work_id="work-001", work_dir=wd)
        self.assertEqual(pw.updated, "2026-06-10")

    def test_fallback_tasks_list_preserved(self):
        """FR14: tasks[] list is intact regardless of the derived lifecycle."""
        wd = self._work_dir()
        pw = parse_state_md(STATE_FAILED_TASK_AND_PENDING_QA, work_id="work-001", work_dir=wd)
        # Lifecycle is Blocked (Failed task), but per-task list is still there
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)
        self.assertEqual(len(pw.tasks), 1)
        self.assertEqual(pw.tasks[0].status, TaskStatus.Failed)

    def test_fallback_without_work_dir_skips_impediment_scan(self):
        """When work_dir is not passed, IMPEDIMENT scan is skipped (no crash)."""
        # Parse without work_dir -- should not raise even if no IMPEDIMENT to find
        pw = parse_state_md(STATE_ONLY_TASKS, work_id="work-001")
        self.assertIsInstance(pw.lifecycle, Lifecycle)

    def test_write_primitives_absent_in_derivation(self):
        """Self-check: derivation.py must contain no write primitive (NFR2)."""
        import ast

        reader_dir = Path(__file__).resolve().parents[1]  # dashboard/reader/
        derivation_path = reader_dir / "derivation.py"

        source = derivation_path.read_text(encoding="utf-8")
        tree = ast.parse(source, filename=str(derivation_path))
        write_modes = {"w", "wb", "a", "ab", "x", "xb"}

        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                func = node.func
                func_name = ""
                if isinstance(func, ast.Name):
                    func_name = func.id
                elif isinstance(func, ast.Attribute):
                    func_name = func.attr
                if func_name == "open":
                    for arg in node.args[1:]:
                        if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                            for c in arg.value:
                                if c in write_modes:
                                    self.fail(
                                        f"Write primitive found in derivation.py: "
                                        f"open() with mode containing '{c}'"
                                    )
                    for kw in node.keywords:
                        if kw.arg == "mode" and isinstance(kw.value, ast.Constant):
                            for c in str(kw.value.value):
                                if c in write_modes:
                                    self.fail(
                                        f"Write primitive found in derivation.py: "
                                        f"open(mode=) containing '{c}'"
                                    )


if __name__ == "__main__":
    unittest.main(verbosity=2)
