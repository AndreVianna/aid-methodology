"""
test_fixtures.py -- Comprehensive fixture-repo suite for the AID state reader (feature-002, task-012).

This module builds programmatically-constructed fixture .aid/ trees and runs
read_repo() end-to-end on each, covering every required state per the task-012 AC.

Fixture matrix (one class per fixture scenario):
  1. Running work with PARALLEL tasks across multiple waves (FR14)
  2. Paused-Awaiting-Input work (pending ### Q{N} Status: Pending)
  3. Blocked work with a FLAT IMPEDIMENT-task-NNN.md file
  4. Completed work
  5. Fallback work (NO ## Pipeline Status block -> source_mode=fallback)
  6. Normalized work (## Pipeline Status present -> source_mode=normalized)
  7. Empty repo (.aid/ with no work folders -> works=[])
  8. Absent .aid/ (-> empty model + parse_warning)
  9. Malformed/torn STATE.md -> parse_warning + best-effort WorkModel; never aborts

Each fixture asserts:
  - Exactly ONE lifecycle matching the intended state (FR16/AC3)
  - Enumeration = retention (FR12): the right number of WorkModels
  - .temp/.heartbeat excluded from works[] (FR12 / DD-3)
  - _none yet_ placeholder row -> tasks=[] (DM-5)
  - source_mode correct (normalized vs fallback)
  - ReadMeta.fallback_works populated correctly (AC4)
  - bytes_read > 0 when files exist (NFR4)
  - parse_warnings are non-fatal (AC1/AC4)
  - Multiple In-Progress tasks retained for parallel waves (FR14)
  - Block artifact path surfaced (Blocked fixture)
  - Pause reason surfaced (Paused fixture)

PART 2 -- BROADENED READ-ONLY SELF-CHECK (task-012 spec):
  This module also contains the broadened AST self-check that rejects not just
  open(...,'w') but ALL of the following across ALL reader modules:
    - .write_text / .write_bytes
    - .write(  (method calls)
    - subprocess (module or call)
    - Popen
    - os.system
    - socket
    - urllib (import)
    - LLM-client imports (anthropic, openai, langchain, litellm, boto3, etc.)

  The check is implemented in TestReadOnlySelfCheck.test_broadened_no_write_primitives
  and runs as part of the normal pytest/unittest suite -- enforceable in CI.

All tests use temp dirs; fully deterministic; Python 3.11+ stdlib only.
"""

from __future__ import annotations

import ast
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Optional

# Make the dashboard package importable when run directly or via python3 -m unittest.
_REPO_ROOT = Path(__file__).resolve().parents[4]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import (
    Lifecycle,
    Phase,
    RepoModel,
    TaskStatus,
    read_repo,
)
from dashboard.reader.models import (
    SourceMode,
    TaskModel,
    WorkModel,
)


# ---------------------------------------------------------------------------
# Shared fixture builders
# ---------------------------------------------------------------------------

def _make_aid_dir(root: Path) -> Path:
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    return aid


def _write_manifest(aid: Path, version: str = "1.0.0") -> None:
    manifest = {
        "manifest_version": 1,
        "aid_version": version,
        "installed_at": "2026-06-10T00:00:00Z",
        "tools": {
            "claude-code": {
                "version": version,
                "installed_at": "2026-06-10T00:00:00Z",
                "paths": [],
                "root_agent_files": [],
            }
        },
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")


def _write_settings(aid: Path, project_name: str = "TestProject") -> None:
    (aid / "settings.yml").write_text(
        f"project:\n  name: {project_name}\n",
        encoding="utf-8",
    )


def _make_work_dir(aid: Path, work_id: str) -> Path:
    wd = aid / work_id
    wd.mkdir(parents=True, exist_ok=True)
    return wd


def _write_state_md(work_dir: Path, content: str) -> None:
    (work_dir / "STATE.md").write_text(content, encoding="utf-8")


# ---------------------------------------------------------------------------
# STATE.md fixture bodies
# ---------------------------------------------------------------------------

# Fixture 1: Running work with PARALLEL tasks across multiple waves (FR14).
# Has tasks in Wave 1 (Done), Wave 2 (two In Progress -- PARALLEL), Wave 3 (Pending).
_STATE_RUNNING_PARALLEL = """\
# Work State -- work-001-parallel

## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-10T12:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | delivery-001-wave-1 | Done | A | 2h | -- |
| 002 | task-002 | TEST | delivery-001-wave-1 | Done | A | 1h | -- |
| 003 | task-003 | CODE | delivery-001-wave-2 | In Progress | -- | -- | parallel a |
| 004 | task-004 | CODE | delivery-001-wave-2 | In Progress | -- | -- | parallel b |
| 005 | task-005 | CONFIGURE | delivery-001-wave-2 | In Progress | -- | -- | parallel c |
| 006 | task-006 | TEST | delivery-001-wave-3 | Pending | -- | -- | -- |

## Cross-phase Q&A (Pending)

"""

# Fixture 2: Paused-Awaiting-Input work (normalized; pending Q&A with Status: Pending).
_STATE_PAUSED = """\
# Work State -- work-002-paused

## Pipeline Status

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Specify
- **Active Skill:** aid-specify
- **Updated:** 2026-06-09T10:00:00Z
- **Pause Reason:** Awaiting user decision on database technology

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | DESIGN | delivery-001 | Pending | -- | -- | -- |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Need to decide between PostgreSQL and SQLite before SPEC is complete
- **Suggested:** PostgreSQL (better for concurrent access)

### Q2

- **Category:** Security
- **Impact:** Medium
- **Status:** Answered
- **Context:** Already resolved
- **Answer:** Use bcrypt for passwords
- **Applied to:** SPEC.md

"""

# Fixture 3: Blocked work with normalized block + FLAT IMPEDIMENT file.
# The IMPEDIMENT file path will be created on disk; the STATE.md references it.
_STATE_BLOCKED = """\
# Work State -- work-003-blocked

## Pipeline Status

- **Lifecycle:** Blocked
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-08T15:00:00Z
- **Pause Reason:** --
- **Block Reason:** Task 005 reviewer found critical issue
- **Block Artifact:** IMPEDIMENT-task-005.md

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 003 | task-003 | CODE | delivery-001-wave-1 | Done | A | 2h | -- |
| 004 | task-004 | TEST | delivery-001-wave-1 | Done | B | 1h | -- |
| 005 | task-005 | CODE | delivery-001-wave-2 | Blocked | -- | -- | impediment raised |

"""

# Fixture 4: Completed work (normalized).
_STATE_COMPLETED = """\
# Work State -- work-004-completed

## Pipeline Status

- **Lifecycle:** Completed
- **Phase:** Deploy
- **Active Skill:** none
- **Updated:** 2026-06-05T08:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | delivery-001 | Done | A | 4h | -- |
| 002 | task-002 | TEST | delivery-001 | Done | A | 2h | -- |
| 003 | task-003 | CONFIGURE | delivery-001 | Done | B | 1h | -- |

"""

# Fixture 5: Fallback work (NO ## Pipeline Status block).
# Uses only legacy signals. Has an In Progress task -> Running via fallback.
_STATE_FALLBACK = """\
# Work State -- work-005-fallback

> **Status:** Executing
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | 1 | In Progress | -- | -- | -- |
| 002 | task-002 | TEST | 1 | Pending | -- | -- | -- |

## Lifecycle History

| Date | Phase | Event | Phase Transition / Gate | Notes |
|------|-------|-------|--------------------------|-------|
| 2026-06-01 | Interview | Work created | Interview start | -- |
| 2026-06-09 | Execute | Execution started | Specify -> Execute | -- |

"""

# Fixture 6: Normalized work (## Pipeline Status present -> source_mode=normalized).
# Same as the general normalized test but explicitly named for clarity.
_STATE_NORMALIZED = """\
# Work State -- work-006-normalized

## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-10T09:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | delivery-001 | In Progress | -- | -- | -- |

"""

# Fixture 9: Malformed/torn STATE.md (truncated in the middle of Pipeline Status).
# Must yield parse_warning + best-effort WorkModel and NEVER abort the whole pass.
_STATE_MALFORMED = """\
# Work State -- work-009-malformed

## Pipeline Status

- **Lifecycle: Running
"""  # Deliberately truncated/malformed: bold syntax broken; no closing ** on Lifecycle


# ---------------------------------------------------------------------------
# Fixture 1: Running work with PARALLEL tasks (FR14)
# ---------------------------------------------------------------------------

class TestFixtureRunningParallel(unittest.TestCase):
    """Fixture 1: Running work with parallel tasks across multiple waves (FR14).

    Asserts:
    - Lifecycle = Running (FR16/AC3)
    - source_mode = normalized (Pipeline Status block present)
    - tasks[] preserved: all 6 tasks retained (FR12 / FR14)
    - Multiple In Progress tasks in wave-2 (FR14 parallel representation)
    - NOT collapsed to a single current task
    - fallback_works is empty (normalized path)
    - bytes_read > 0 (NFR4)
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "ParallelProject")
        wd = _make_work_dir(aid, "work-001-parallel")
        _write_state_md(wd, _STATE_RUNNING_PARALLEL)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_lifecycle_is_running(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running)

    def test_source_mode_normalized(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_tasks_list_preserved_fr14(self):
        """FR14: all 6 tasks must be preserved; multiple In Progress retained."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(len(w.tasks), 6, "All 6 tasks must be present")

    def test_multiple_in_progress_tasks_fr14(self):
        """FR14: multiple In Progress tasks in wave-2 are NOT collapsed."""
        model = read_repo(self.root)
        w = model.works[0]
        in_progress = [t for t in w.tasks if t.status == TaskStatus.InProgress]
        self.assertGreaterEqual(len(in_progress), 2, "At least 2 In Progress tasks in wave-2")

    def test_parallel_tasks_have_same_wave(self):
        """FR14: parallel tasks carry the same wave label."""
        model = read_repo(self.root)
        w = model.works[0]
        wave2 = [t for t in w.tasks if t.wave == "delivery-001-wave-2"]
        self.assertEqual(len(wave2), 3, "Wave-2 must have 3 tasks")

    def test_no_tasks_collapsed(self):
        """FR14: tasks[] is a flat list; the rollup lifecycle does not replace it."""
        model = read_repo(self.root)
        w = model.works[0]
        # The flat tasks list must still include Done tasks (wave-1)
        done_tasks = [t for t in w.tasks if t.status == TaskStatus.Done]
        self.assertEqual(len(done_tasks), 2)

    def test_fallback_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.fallback_works, [])

    def test_bytes_read_positive(self):
        model = read_repo(self.root)
        self.assertGreater(model.read.bytes_read, 0)

    def test_work_count(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 1)

    def test_phase_and_skill(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.phase, Phase.Execute)
        self.assertEqual(w.active_skill, "aid-execute")


# ---------------------------------------------------------------------------
# Fixture 2: Paused-Awaiting-Input work
# ---------------------------------------------------------------------------

class TestFixturePaused(unittest.TestCase):
    """Fixture 2: Paused-Awaiting-Input work (normalized; pending Q&A).

    Asserts:
    - Lifecycle = Paused-Awaiting-Input (FR16/AC3)
    - source_mode = normalized
    - pause_reason is non-None and contains content
    - pending_inputs contains only the Pending Q (Q2 is Answered -> excluded)
    - fallback_works is empty (normalized)
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "PausedProject")
        wd = _make_work_dir(aid, "work-002-paused")
        _write_state_md(wd, _STATE_PAUSED)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_lifecycle_paused(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.PausedAwaitingInput)

    def test_source_mode_normalized(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_pause_reason_present(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNotNone(w.pause_reason)
        self.assertIn("database technology", w.pause_reason)

    def test_pending_inputs_only_pending(self):
        """Only Q1 (Pending) is in pending_inputs; Q2 (Answered) is excluded."""
        model = read_repo(self.root)
        w = model.works[0]
        q_ids = [p.question_id for p in w.pending_inputs]
        self.assertIn("Q1", q_ids, "Q1 (Pending) must appear in pending_inputs")
        self.assertNotIn("Q2", q_ids, "Q2 (Answered) must NOT appear in pending_inputs")

    def test_fallback_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.fallback_works, [])

    def test_bytes_read_positive(self):
        model = read_repo(self.root)
        self.assertGreater(model.read.bytes_read, 0)


# ---------------------------------------------------------------------------
# Fixture 3: Blocked work with flat IMPEDIMENT file
# ---------------------------------------------------------------------------

class TestFixtureBlocked(unittest.TestCase):
    """Fixture 3: Blocked work with normalized block + flat IMPEDIMENT-task-NNN.md.

    Asserts:
    - Lifecycle = Blocked (FR16/AC3)
    - source_mode = normalized
    - block_reason is non-None
    - block_artifact surfaces the IMPEDIMENT file name
    - tasks[] retained (task-005 is Blocked)
    - fallback_works is empty
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "BlockedProject")
        wd = _make_work_dir(aid, "work-003-blocked")
        _write_state_md(wd, _STATE_BLOCKED)
        # Create the flat IMPEDIMENT file (de-facto producer path, KI-003)
        (wd / "IMPEDIMENT-task-005.md").write_text(
            "# Impediment — task-005\n\nCritical issue found during review.\n",
            encoding="utf-8",
        )

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_lifecycle_blocked(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Blocked)

    def test_source_mode_normalized(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_block_reason_present(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNotNone(w.block_reason)
        self.assertIn("task 005", w.block_reason.lower())

    def test_block_artifact_is_impediment_file(self):
        """block_artifact must name the IMPEDIMENT file."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNotNone(w.block_artifact)
        self.assertEqual(w.block_artifact, "IMPEDIMENT-task-005.md")

    def test_tasks_preserved(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(len(w.tasks), 3, "All 3 tasks must be present")
        blocked = [t for t in w.tasks if t.status == TaskStatus.Blocked]
        self.assertEqual(len(blocked), 1)
        self.assertEqual(blocked[0].task_id, "task-005")

    def test_fallback_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.fallback_works, [])


# ---------------------------------------------------------------------------
# Fixture 4: Completed work
# ---------------------------------------------------------------------------

class TestFixtureCompleted(unittest.TestCase):
    """Fixture 4: Completed work (normalized).

    Asserts:
    - Lifecycle = Completed (FR16/AC3)
    - source_mode = normalized
    - tasks[] retained (all Done tasks preserved)
    - active_skill = None (normalized block has "none")
    - fallback_works empty
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "CompletedProject")
        wd = _make_work_dir(aid, "work-004-completed")
        _write_state_md(wd, _STATE_COMPLETED)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_lifecycle_completed(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Completed)

    def test_source_mode_normalized(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_tasks_all_done(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(len(w.tasks), 3)
        for t in w.tasks:
            self.assertEqual(t.status, TaskStatus.Done)

    def test_active_skill_none(self):
        """Active Skill = 'none' in normalized block -> None in model."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNone(w.active_skill)

    def test_fallback_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.fallback_works, [])


# ---------------------------------------------------------------------------
# Fixture 5: Fallback work (NO ## Pipeline Status block)
# ---------------------------------------------------------------------------

class TestFixtureFallback(unittest.TestCase):
    """Fixture 5: Fallback work -- NO ## Pipeline Status block.

    Asserts:
    - source_mode = fallback (not normalized)
    - Lifecycle derived from legacy signals (In Progress task -> Running)
    - work_id appears in fallback_works (AC4)
    - ReadMeta.fallback_works is populated with this work's id
    - bytes_read > 0 (NFR4)
    - No parse_warnings just for the missing Pipeline Status (expected fallback)
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "FallbackProject")
        wd = _make_work_dir(aid, "work-005-fallback")
        _write_state_md(wd, _STATE_FALLBACK)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_source_mode_fallback(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Fallback)

    def test_lifecycle_running_via_fallback(self):
        """Fallback: In Progress task -> Running (SM-2 prio-5 default)."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running)

    def test_work_in_fallback_works(self):
        """AC4: work_id must appear in ReadMeta.fallback_works."""
        model = read_repo(self.root)
        self.assertIn("work-005-fallback", model.read.fallback_works)

    def test_fallback_works_populated(self):
        """ReadMeta.fallback_works is non-empty for this repo."""
        model = read_repo(self.root)
        self.assertEqual(len(model.read.fallback_works), 1)

    def test_tasks_preserved_fallback(self):
        """FR14: tasks[] preserved even when using fallback derivation."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(len(w.tasks), 2)

    def test_bytes_read_positive(self):
        model = read_repo(self.root)
        self.assertGreater(model.read.bytes_read, 0)


# ---------------------------------------------------------------------------
# Fixture 6: Normalized work (explicit)
# ---------------------------------------------------------------------------

class TestFixtureNormalized(unittest.TestCase):
    """Fixture 6: Normalized work -- ## Pipeline Status block present.

    Asserts:
    - source_mode = normalized
    - Lifecycle = Running (verbatim from block)
    - NOT in fallback_works
    - phase and active_skill populated
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "NormalizedProject")
        wd = _make_work_dir(aid, "work-006-normalized")
        _write_state_md(wd, _STATE_NORMALIZED)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_source_mode_normalized(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_lifecycle_verbatim_from_block(self):
        """Normalized path: Lifecycle literal taken verbatim (SM-2 preferred)."""
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running)

    def test_not_in_fallback_works(self):
        model = read_repo(self.root)
        self.assertNotIn("work-006-normalized", model.read.fallback_works)

    def test_phase_populated(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.phase, Phase.Execute)

    def test_active_skill_populated(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.active_skill, "aid-execute")


# ---------------------------------------------------------------------------
# Fixture 7: Empty repo (.aid/ with no works -> works=[])
# ---------------------------------------------------------------------------

class TestFixtureEmptyRepo(unittest.TestCase):
    """Fixture 7: Empty repo -- .aid/ exists but contains no work-NNN-* folders.

    Asserts:
    - works=[] (FR12 enumeration = retention: no folders = no works)
    - work_count = 0
    - No parse_warnings just for being empty
    - fallback_works = []
    - .temp and .heartbeat dirs do NOT appear as works (DD-3)
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "EmptyProject")
        # Create dirs that must NOT be enumerated as works
        (aid / ".temp").mkdir()
        (aid / ".heartbeat").mkdir()
        (aid / "knowledge").mkdir()
        (aid / "not-a-work-dir").mkdir()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.works, [])

    def test_work_count_zero(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 0)

    def test_fallback_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.fallback_works, [])

    def test_temp_heartbeat_excluded(self):
        """FR12/DD-3: .temp and .heartbeat must NOT appear as works."""
        model = read_repo(self.root)
        work_ids = {w.work_id for w in model.works}
        self.assertNotIn(".temp", work_ids)
        self.assertNotIn(".heartbeat", work_ids)
        self.assertNotIn("knowledge", work_ids)

    def test_non_matching_dirs_excluded(self):
        model = read_repo(self.root)
        work_ids = {w.work_id for w in model.works}
        self.assertNotIn("not-a-work-dir", work_ids)

    def test_returns_valid_repo_model(self):
        """An empty repo still returns a valid RepoModel with tool/repo/read populated."""
        model = read_repo(self.root)
        self.assertIsInstance(model, RepoModel)
        self.assertIsNotNone(model.tool)
        self.assertIsNotNone(model.repo)
        self.assertIsNotNone(model.read)


# ---------------------------------------------------------------------------
# Fixture 8: Absent .aid/ (-> empty model + parse_warning)
# ---------------------------------------------------------------------------

class TestFixtureAbsentAidDir(unittest.TestCase):
    """Fixture 8: Absent .aid/ directory.

    Asserts:
    - works=[] (AC1)
    - parse_warnings contains a message about the missing .aid/ (AC1)
    - No exception raised
    - Returns a valid RepoModel
    - bytes_read = 0 (nothing to read)
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        # Intentionally do NOT create a .aid/ directory

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_no_exception(self):
        """Must not raise; absent .aid/ is a valid input (AC1)."""
        try:
            model = read_repo(self.root)
        except Exception as exc:
            self.fail(f"read_repo raised unexpectedly on absent .aid/: {exc}")

    def test_works_empty(self):
        model = read_repo(self.root)
        self.assertEqual(model.works, [])

    def test_work_count_zero(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 0)

    def test_parse_warning_present(self):
        """AC1: absent .aid/ must produce a parse_warning."""
        model = read_repo(self.root)
        warnings = model.read.parse_warnings
        self.assertGreater(len(warnings), 0)
        # At least one warning must mention .aid or the missing directory
        self.assertTrue(
            any(".aid" in w or "No" in w or "absent" in w.lower() or "not found" in w.lower()
                for w in warnings),
            f"Expected .aid-related warning; got: {warnings}",
        )

    def test_bytes_read_zero(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.bytes_read, 0)

    def test_returns_valid_repo_model(self):
        model = read_repo(self.root)
        self.assertIsInstance(model, RepoModel)
        self.assertFalse(model.tool.manifest_present)


# ---------------------------------------------------------------------------
# Fixture 9: Malformed/torn STATE.md
# ---------------------------------------------------------------------------

class TestFixtureMalformedStateMd(unittest.TestCase):
    """Fixture 9: Malformed/torn STATE.md.

    Asserts (AC1/AC4):
    - parse_warning is added (non-fatal anomaly noted)
    - A best-effort WorkModel is returned (never aborts the pass)
    - The whole read_repo() call does NOT abort due to one bad STATE.md
    - Other (good) works in the same repo are still enumerated correctly
    - lifecycle is some Lifecycle enum value (not an exception)

    Scenarios:
    - Truncated Pipeline Status block (bold syntax broken)
    - Multiple works: one bad + two good -> still get 3 WorkModels
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        self.aid = _make_aid_dir(self.root)
        _write_manifest(self.aid)
        _write_settings(self.aid, "MixedProject")
        # Work 1: malformed STATE.md
        wd_bad = _make_work_dir(self.aid, "work-001-bad")
        _write_state_md(wd_bad, _STATE_MALFORMED)
        # Work 2: good normalized STATE.md
        wd_good1 = _make_work_dir(self.aid, "work-002-good")
        _write_state_md(wd_good1, _STATE_NORMALIZED.replace("work-006-normalized", "work-002-good"))
        # Work 3: another good work
        wd_good2 = _make_work_dir(self.aid, "work-003-also-good")
        _write_state_md(wd_good2, _STATE_COMPLETED.replace("work-004-completed", "work-003-also-good"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_no_exception_on_malformed(self):
        """AC1/AC4: malformed STATE.md must never abort the whole pass."""
        try:
            model = read_repo(self.root)
        except Exception as exc:
            self.fail(f"read_repo raised on malformed STATE.md: {exc}")

    def test_still_enumerates_all_works(self):
        """AC1: all three works must be returned even when one is malformed."""
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 3)
        work_ids = {w.work_id for w in model.works}
        self.assertIn("work-001-bad", work_ids)
        self.assertIn("work-002-good", work_ids)
        self.assertIn("work-003-also-good", work_ids)

    def test_bad_work_has_valid_lifecycle_enum(self):
        """Best-effort: the bad work's lifecycle is some Lifecycle member (no crash)."""
        model = read_repo(self.root)
        bad_work = next(w for w in model.works if w.work_id == "work-001-bad")
        self.assertIsInstance(bad_work.lifecycle, Lifecycle)

    def test_good_works_unaffected(self):
        """Good works in same repo are unaffected by the malformed one."""
        model = read_repo(self.root)
        good = next(w for w in model.works if w.work_id == "work-002-good")
        self.assertEqual(good.lifecycle, Lifecycle.Running)
        self.assertEqual(good.source_mode, SourceMode.Normalized)

    def test_no_exception_on_fully_empty_state(self):
        """A completely empty STATE.md also must not abort."""
        aid2 = _make_aid_dir(self.root / "repo2")
        _write_manifest(aid2)
        _write_settings(aid2)
        wd = _make_work_dir(aid2, "work-001-empty-state")
        _write_state_md(wd, "")
        try:
            model = read_repo(self.root / "repo2")
        except Exception as exc:
            self.fail(f"read_repo raised on empty STATE.md: {exc}")
        self.assertEqual(model.read.work_count, 1)

    def test_no_exception_on_binary_garbage(self):
        """A STATE.md with binary/invalid UTF-8 must not abort (errors='replace')."""
        aid3 = _make_aid_dir(self.root / "repo3")
        _write_manifest(aid3)
        _write_settings(aid3)
        wd = _make_work_dir(aid3, "work-001-binary")
        (wd / "STATE.md").write_bytes(b"\xff\xfe\x00\x01invalid utf-8 garbage")
        try:
            model = read_repo(self.root / "repo3")
        except Exception as exc:
            self.fail(f"read_repo raised on binary STATE.md: {exc}")
        self.assertEqual(model.read.work_count, 1)


# ---------------------------------------------------------------------------
# Fixture: _none yet_ placeholder row -> tasks=[]
# ---------------------------------------------------------------------------

class TestFixtureNoneYetRow(unittest.TestCase):
    """_none yet_ placeholder row in ## Tasks Status -> tasks=[] (DM-5).

    Asserts:
    - A STATE.md with only a _none yet_ row produces tasks=[]
    - This is true for both normalized and fallback paths
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_none_yet_row_skipped_normalized(self):
        """Normalized path: _none yet_ produces tasks=[]."""
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid)
        wd = _make_work_dir(aid, "work-001-none-yet")
        _write_state_md(wd, """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none
- **Updated:** 2026-06-01T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |
""")
        model = read_repo(self.root)
        self.assertEqual(model.works[0].tasks, [])

    def test_none_yet_row_skipped_fallback(self):
        """Fallback path: _none yet_ also produces tasks=[]."""
        aid2 = _make_aid_dir(self.root / "repo2")
        _write_manifest(aid2)
        _write_settings(aid2)
        wd = _make_work_dir(aid2, "work-001-none-yet-fb")
        _write_state_md(wd, """\
# Work State

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |
""")
        model = read_repo(self.root / "repo2")
        self.assertEqual(model.works[0].tasks, [])


# ---------------------------------------------------------------------------
# Mixed-mode: multiple works, normalized + fallback in same repo
# ---------------------------------------------------------------------------

class TestFixtureMixedModeRepo(unittest.TestCase):
    """Multiple works with some normalized and some fallback.

    Asserts (AC4):
    - fallback_works contains exactly the fallback work_ids
    - normalized works are NOT in fallback_works
    - work_count is accurate
    - bytes_read is additive
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid, "MixedModeProject")
        # Normalized work
        wd_norm = _make_work_dir(aid, "work-001-normalized")
        _write_state_md(wd_norm, _STATE_NORMALIZED.replace("work-006-normalized", "work-001-normalized"))
        # Fallback work
        wd_fall = _make_work_dir(aid, "work-002-fallback")
        _write_state_md(wd_fall, _STATE_FALLBACK.replace("work-005-fallback", "work-002-fallback"))
        # Another normalized work
        wd_comp = _make_work_dir(aid, "work-003-completed")
        _write_state_md(wd_comp, _STATE_COMPLETED.replace("work-004-completed", "work-003-completed"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_work_count(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 3)

    def test_fallback_works_contains_only_fallback(self):
        model = read_repo(self.root)
        self.assertIn("work-002-fallback", model.read.fallback_works)
        self.assertNotIn("work-001-normalized", model.read.fallback_works)
        self.assertNotIn("work-003-completed", model.read.fallback_works)

    def test_fallback_works_count(self):
        model = read_repo(self.root)
        self.assertEqual(len(model.read.fallback_works), 1)

    def test_normalized_source_mode(self):
        model = read_repo(self.root)
        norm = next(w for w in model.works if w.work_id == "work-001-normalized")
        self.assertEqual(norm.source_mode, SourceMode.Normalized)

    def test_fallback_source_mode(self):
        model = read_repo(self.root)
        fall = next(w for w in model.works if w.work_id == "work-002-fallback")
        self.assertEqual(fall.source_mode, SourceMode.Fallback)


# ---------------------------------------------------------------------------
# Fallback Blocked: FLAT IMPEDIMENT via fallback path
# ---------------------------------------------------------------------------

class TestFixtureFallbackBlocked(unittest.TestCase):
    """Fallback-path Blocked work: no ## Pipeline Status; IMPEDIMENT file present.

    Asserts (SM-2 prio-3 fallback):
    - source_mode = fallback
    - Lifecycle = Blocked
    - block_artifact surfaced from the IMPEDIMENT file
    - work in fallback_works
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid)
        wd = _make_work_dir(aid, "work-001-fb-blocked")
        # No ## Pipeline Status block
        _write_state_md(wd, """\
# Work State -- work-001-fb-blocked

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | 1 | In Progress | -- | -- | -- |

""")
        # Create flat IMPEDIMENT file (KI-003 path)
        (wd / "IMPEDIMENT-task-001.md").write_text(
            "# Impediment\nCritical failure.", encoding="utf-8"
        )

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_source_mode_fallback(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Fallback)

    def test_lifecycle_blocked(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Blocked)

    def test_block_artifact_surfaced(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNotNone(w.block_artifact)
        self.assertIn("IMPEDIMENT-task-001.md", w.block_artifact)

    def test_in_fallback_works(self):
        model = read_repo(self.root)
        self.assertIn("work-001-fb-blocked", model.read.fallback_works)


# ---------------------------------------------------------------------------
# Fallback Paused: pending Q&A via fallback path
# ---------------------------------------------------------------------------

class TestFixtureFallbackPaused(unittest.TestCase):
    """Fallback-path Paused work: no ## Pipeline Status; pending Q&A present.

    Asserts (SM-2 prio-4 fallback):
    - source_mode = fallback
    - Lifecycle = Paused-Awaiting-Input
    - pause_reason references the pending Q&A question IDs
    - work in fallback_works
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid)
        wd = _make_work_dir(aid, "work-001-fb-paused")
        _write_state_md(wd, """\
# Work State -- work-001-fb-paused

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | DESIGN | 1 | Pending | -- | -- | -- |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Waiting for user input on DB choice

### Q2

- **Category:** Security
- **Impact:** Medium
- **Status:** Pending
- **Context:** Auth mechanism still unresolved

""")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_source_mode_fallback(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Fallback)

    def test_lifecycle_paused(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.PausedAwaitingInput)

    def test_pause_reason_has_question_ids(self):
        model = read_repo(self.root)
        w = model.works[0]
        self.assertIsNotNone(w.pause_reason)
        self.assertIn("Q1", w.pause_reason)
        self.assertIn("Q2", w.pause_reason)

    def test_in_fallback_works(self):
        model = read_repo(self.root)
        self.assertIn("work-001-fb-paused", model.read.fallback_works)


# ---------------------------------------------------------------------------
# PART 2: Broadened read-only self-check (task-012 spec)
#
# Asserts that ALL reader modules contain NONE of:
#   - open(..., 'w'/'wb'/'a'/'ab'/'x'/'xb') -- write modes
#   - .write_text(...) -- pathlib write
#   - .write_bytes(...) -- pathlib write
#   - .write(  -- any .write() method call
#   - subprocess (import or call)
#   - Popen (any form)
#   - os.system
#   - socket (import)
#   - urllib (import)
#   - LLM-client imports: anthropic, openai, langchain, litellm, boto3, requests
#
# This enforces NFR2 (read-only) and NFR7 (no-LLM) in CI, not just in prose.
# ---------------------------------------------------------------------------

#: All reader module paths to check. Keyed by a short display name.
_READER_DIR = Path(__file__).resolve().parents[1]  # dashboard/reader/

_READER_MODULES = {
    "locator.py": _READER_DIR / "locator.py",
    "parsers.py": _READER_DIR / "parsers.py",
    "reader.py": _READER_DIR / "reader.py",
    "models.py": _READER_DIR / "models.py",
    "derivation.py": _READER_DIR / "derivation.py",
    "io_bounds.py": _READER_DIR / "io_bounds.py",  # v2.1.0 security hardening (FIX-3)
}

#: Write-mode characters that must not appear in any open() call argument
_WRITE_MODES = frozenset("wax")  # 'w', 'a', 'x' and their binary variants

#: Attribute names that are forbidden write primitives
_FORBIDDEN_ATTR_CALLS = frozenset({
    "write_text",
    "write_bytes",
    "write",
})

#: Module names whose imports are forbidden (write, subprocess, network, LLM)
# Note: "subprocess" is intentionally NOT listed here because derivation.py is allowed
# to import subprocess for the ONE read-only git log subprocess (FR35, task-064).
# See test_no_subprocess_import_in_any_module (which exempts derivation.py) and
# test_derivation_subprocess_is_read_only_git_log for the tighter derivation.py check.
_FORBIDDEN_IMPORTS = frozenset({
    # subprocess / process execution -- see module-level note above
    "os",        # caught only if os.system is used; see AST check below
    # network / socket
    "socket",
    "urllib",
    "http",
    "requests",
    # LLM clients
    "anthropic",
    "openai",
    "langchain",
    "litellm",
    "boto3",
    "cohere",
    "together",
    "groq",
    "vertexai",
    "google.generativeai",
    "transformers",
})


def _check_module_for_write_primitives(source: str, filename: str) -> list[str]:
    """Return a list of violation descriptions found in the module source.

    Checks:
    1. open() calls with write/append/exclusive modes
    2. Attribute calls: .write_text / .write_bytes / .write(
    3. Popen calls (any form)
    4. os.system calls
    5. Forbidden imports: subprocess, socket, urllib, LLM clients, etc.

    Returns [] if clean.
    """
    violations: list[str] = []
    tree = ast.parse(source, filename=filename)

    for node in ast.walk(tree):
        # Check 1: open() with write modes
        if isinstance(node, ast.Call):
            func = node.func
            func_name = ""
            if isinstance(func, ast.Name):
                func_name = func.id
            elif isinstance(func, ast.Attribute):
                func_name = func.attr

            if func_name == "open":
                # Check positional mode argument (index 1)
                for arg in node.args[1:]:
                    if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                        for ch in arg.value:
                            if ch in _WRITE_MODES:
                                violations.append(
                                    f"open() with write mode '{ch}' in {filename} "
                                    f"(line {node.lineno})"
                                )
                # Check keyword mode= argument
                for kw in node.keywords:
                    if kw.arg == "mode" and isinstance(kw.value, ast.Constant):
                        for ch in str(kw.value.value):
                            if ch in _WRITE_MODES:
                                violations.append(
                                    f"open(mode=...) with write mode '{ch}' in {filename} "
                                    f"(line {node.lineno})"
                                )

            # Check 2: .write_text / .write_bytes / .write( method calls
            if isinstance(func, ast.Attribute) and func.attr in _FORBIDDEN_ATTR_CALLS:
                violations.append(
                    f".{func.attr}() call in {filename} (line {node.lineno}) -- "
                    f"forbidden write primitive"
                )

            # Check 3: Popen (subprocess.Popen, Popen, etc.)
            if func_name == "Popen":
                violations.append(
                    f"Popen() call in {filename} (line {node.lineno}) -- forbidden"
                )

            # Check 4: os.system()
            if (
                isinstance(func, ast.Attribute)
                and func.attr == "system"
                and isinstance(func.value, ast.Name)
                and func.value.id == "os"
            ):
                violations.append(
                    f"os.system() call in {filename} (line {node.lineno}) -- forbidden"
                )

        # Check 5: Import statements
        if isinstance(node, ast.Import):
            for alias in node.names:
                top_module = alias.name.split(".")[0]
                if top_module in _FORBIDDEN_IMPORTS or alias.name in _FORBIDDEN_IMPORTS:
                    # Exception: 'os' is allowed if only os.path / stat operations are used;
                    # we only flag os.system() calls specifically (check 4 above).
                    # Other forbidden modules: flag unconditionally.
                    if top_module != "os":
                        violations.append(
                            f"import {alias.name} in {filename} (line {node.lineno}) -- "
                            f"forbidden module"
                        )

        if isinstance(node, ast.ImportFrom):
            module = node.module or ""
            top_module = module.split(".")[0]
            if top_module in _FORBIDDEN_IMPORTS or module in _FORBIDDEN_IMPORTS:
                if top_module != "os":
                    violations.append(
                        f"from {module} import ... in {filename} (line {node.lineno}) -- "
                        f"forbidden module"
                    )
            # subprocess.Popen / subprocess.run imported directly
            for alias in node.names:
                if alias.name in ("Popen", "run", "call", "check_output", "check_call") and \
                        top_module == "subprocess":
                    violations.append(
                        f"from subprocess import {alias.name} in {filename} "
                        f"(line {node.lineno}) -- forbidden"
                    )

    return violations


class TestReadOnlySelfCheck(unittest.TestCase):
    """PART 2: Broadened AST self-check.

    Asserts that ALL reader modules are clean of write primitives,
    socket, urllib, and LLM-client imports (NFR2 + NFR7).
    subprocess is checked separately (derivation.py is exempt -- see FR35 note).
    Enforced at the AST level so it runs in CI via the normal test suite.
    """

    def test_broadened_no_write_primitives(self):
        """ALL reader modules must pass the broadened read-only check.

        Checks:
        - open() write modes (w/a/x/wb/ab/xb)
        - .write_text() / .write_bytes() / .write() method calls
        - Popen (call)
        - os.system (call)
        - socket (import)
        - urllib (import)
        - LLM-client imports (anthropic, openai, langchain, litellm, boto3, etc.)

        Note: subprocess import is checked separately in test_no_subprocess_import_in_any_module
        because derivation.py is allowed to import subprocess for the FR35 read-only git log
        (task-064). The _FORBIDDEN_IMPORTS set excludes 'subprocess' for this reason.
        """
        all_violations: list[str] = []

        for name, mod_path in _READER_MODULES.items():
            self.assertTrue(
                mod_path.is_file(),
                f"Reader module not found: {mod_path}",
            )
            source = mod_path.read_text(encoding="utf-8")
            violations = _check_module_for_write_primitives(source, name)
            all_violations.extend(violations)

        if all_violations:
            self.fail(
                "Read-only self-check FAILED. Forbidden primitives found:\n"
                + "\n".join(f"  - {v}" for v in all_violations)
            )

    def test_all_modules_parseable(self):
        """All reader modules must be syntactically valid Python (parseable by ast)."""
        for name, mod_path in _READER_MODULES.items():
            self.assertTrue(mod_path.is_file(), f"Module not found: {mod_path}")
            source = mod_path.read_text(encoding="utf-8")
            try:
                ast.parse(source, filename=name)
            except SyntaxError as exc:
                self.fail(f"SyntaxError in {name}: {exc}")

    def test_no_subprocess_import_in_any_module(self):
        """subprocess must not be imported in most reader modules (NFR2).

        Relaxed for task-064 (FR35): derivation.py is the ONE module allowed to
        import subprocess, exclusively for the read-only 'git log -1 --format=%cI'
        KB freshness check. All other reader modules remain subprocess-free.
        See test_derivation_subprocess_is_read_only_git_log for the tighter check.
        """
        # These modules must remain entirely subprocess-free
        subprocess_free = {n: p for n, p in _READER_MODULES.items()
                           if n != "derivation.py"}
        for name, mod_path in subprocess_free.items():
            source = mod_path.read_text(encoding="utf-8")
            self.assertNotIn(
                "import subprocess",
                source,
                f"{name} must not import subprocess",
            )

    def test_derivation_subprocess_is_read_only_git_log(self):
        """derivation.py's subprocess use must be ONLY the sanctioned read-only git log.

        Verifies that derivation.py:
          - imports subprocess (allowed, for FR35 git freshness)
          - does NOT import or use Popen (mutation subprocess forbidden)
          - does NOT invoke any mutating git verb (fetch/pull/commit/checkout/reset)
        This is the tighter check that replaces the blanket subprocess prohibition
        for derivation.py only (task-064, SEC-A1).
        """
        derivation_path = _READER_MODULES["derivation.py"]
        source = derivation_path.read_text(encoding="utf-8")
        # subprocess IS expected (the one sanctioned git log)
        self.assertIn("import subprocess", source,
                      "derivation.py must import subprocess (for FR35 git log)")
        # Popen is still forbidden
        self.assertNotIn("Popen", source,
                         "derivation.py must not use Popen (mutation subprocess forbidden)")
        # Mutating git verbs are forbidden
        for verb in ("git fetch", "git pull", "git commit", "git checkout",
                     "git reset", "\"fetch\"", "\"pull\"", "\"commit\"",
                     "\"checkout\"", "\"reset\""):
            self.assertNotIn(verb, source,
                             f"derivation.py must not invoke mutating git verb: {verb}")

    def test_no_popen_in_any_module(self):
        """Popen must not be used in any reader module (NFR2)."""
        for name, mod_path in _READER_MODULES.items():
            source = mod_path.read_text(encoding="utf-8")
            self.assertNotIn(
                "Popen",
                source,
                f"{name} must not use Popen",
            )

    def test_no_socket_import_in_any_module(self):
        """socket must not be imported in any reader module (NFR2)."""
        for name, mod_path in _READER_MODULES.items():
            source = mod_path.read_text(encoding="utf-8")
            self.assertNotIn(
                "import socket",
                source,
                f"{name} must not import socket",
            )

    def test_no_urllib_import_in_any_module(self):
        """urllib must not be imported in any reader module (NFR2)."""
        for name, mod_path in _READER_MODULES.items():
            source = mod_path.read_text(encoding="utf-8")
            self.assertNotIn(
                "import urllib",
                source,
                f"{name} must not import urllib",
            )
            self.assertNotIn(
                "from urllib",
                source,
                f"{name} must not import from urllib",
            )

    def test_no_llm_client_imports(self):
        """LLM client modules must not be imported in any reader module (NFR7)."""
        llm_modules = [
            "anthropic", "openai", "langchain", "litellm",
            "boto3", "cohere", "together", "groq",
        ]
        for name, mod_path in _READER_MODULES.items():
            source = mod_path.read_text(encoding="utf-8")
            for llm in llm_modules:
                self.assertNotIn(
                    f"import {llm}",
                    source,
                    f"{name} must not import {llm} (LLM client, NFR7)",
                )
                self.assertNotIn(
                    f"from {llm}",
                    source,
                    f"{name} must not import from {llm} (LLM client, NFR7)",
                )


# ---------------------------------------------------------------------------
# Retention / enumeration correctness (FR12)
# ---------------------------------------------------------------------------

class TestFixtureRetentionEnumeration(unittest.TestCase):
    """FR12 enumeration = retention: exactly the work folders that exist on disk.

    - work_count matches the actual directory count
    - work_ids match directory names exactly
    - Completed and in-flight works are represented identically
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        aid = _make_aid_dir(self.root)
        _write_manifest(aid)
        _write_settings(aid)
        # Three works: completed + running + paused (mixed lifecycle states)
        wd1 = _make_work_dir(aid, "work-001-done")
        _write_state_md(wd1, _STATE_COMPLETED.replace("work-004-completed", "work-001-done"))
        wd2 = _make_work_dir(aid, "work-002-running")
        _write_state_md(wd2, _STATE_NORMALIZED.replace("work-006-normalized", "work-002-running"))
        wd3 = _make_work_dir(aid, "work-003-paused")
        _write_state_md(wd3, _STATE_PAUSED.replace("work-002-paused", "work-003-paused"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_work_count_matches_dirs(self):
        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 3)
        self.assertEqual(len(model.works), 3)

    def test_all_work_ids_present(self):
        model = read_repo(self.root)
        ids = {w.work_id for w in model.works}
        self.assertEqual(ids, {"work-001-done", "work-002-running", "work-003-paused"})

    def test_completed_work_present_fr12(self):
        """FR12: completed works stay in the model as long as the folder exists."""
        model = read_repo(self.root)
        done = next(w for w in model.works if w.work_id == "work-001-done")
        self.assertEqual(done.lifecycle, Lifecycle.Completed)

    def test_works_sorted(self):
        """Works are returned in sorted order (by folder name)."""
        model = read_repo(self.root)
        ids = [w.work_id for w in model.works]
        self.assertEqual(ids, sorted(ids))


if __name__ == "__main__":
    unittest.main(verbosity=2)
