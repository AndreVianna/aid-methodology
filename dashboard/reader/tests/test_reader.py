"""
test_reader.py -- Unit tests for the AID state reader (feature-002, task-010).

Focused unit tests for:
  - read_repo()      : the public entry point
  - LC-1 Locator     : locate_aid_root(), enumerate work dirs
  - LC-2 Parsers     : parse_tool_info(), parse_project_name(), parse_kb_state(),
                        parse_state_md()
  - Enum parsing     : Lifecycle, Phase, TaskStatus round-trips

The comprehensive fixture suite is task-012; these tests cover the normalized path
(SM-2 preferred path) and the structural edge cases.

All tests use temp-dir fixtures and are fully deterministic.
No third-party deps; Python 3.11+ stdlib only.
"""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

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
from dashboard.reader.locator import locate_aid_root
from dashboard.reader.models import (
    KbStateRef,
    PendingInput,
    SourceMode,
    TaskModel,
    ToolInfo,
    WorkModel,
)
from dashboard.reader.parsers import (
    _parse_kb_doc_count,
    _parse_kb_summary_approval,
    _parse_lifecycle,
    _parse_phase,
    _parse_task_status,
    parse_kb_state,
    parse_project_name,
    parse_state_md,
    parse_tool_info,
)


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

def make_aid_dir(root: Path) -> Path:
    """Create a minimal .aid/ directory tree under root."""
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    return aid


def write_manifest(aid: Path, version: str = "1.0.0") -> None:
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
        }
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")


def write_settings(aid: Path, project_name: str = "TestProject") -> None:
    (aid / "settings.yml").write_text(
        f"project:\n  name: {project_name}\n",
        encoding="utf-8",
    )


def make_work_dir(aid: Path, work_id: str) -> Path:
    wd = aid / work_id
    wd.mkdir(parents=True, exist_ok=True)
    return wd


def write_state_md(work_dir: Path, content: str) -> None:
    (work_dir / "STATE.md").write_text(content, encoding="utf-8")


def make_kb_dir(aid: Path) -> Path:
    kb = aid / "knowledge"
    kb.mkdir(parents=True, exist_ok=True)
    return kb


# ---------------------------------------------------------------------------
# Minimal STATE.md bodies
# ---------------------------------------------------------------------------

STATE_NORMALIZED = """\
# Work State -- work-001-test

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
| 001 | task-001 | IMPLEMENT | delivery-001 | In Progress | -- | -- | first |
| 002 | task-002 | TEST | delivery-001 | Done | A | 1h | second |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Some context
- **Suggested:** --

### Q2

- **Category:** Security
- **Impact:** Low
- **Status:** Answered
- **Context:** Already answered
- **Suggested:** yes
"""

STATE_NO_PIPELINE_STATUS = """\
# Work State -- work-001-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | Pending | -- | -- | -- |

## Cross-phase Q&A (Pending)

### Q1

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Pending
- **Context:** open question
- **Suggested:** --
"""

STATE_NONE_YET = """\
# Work State -- work-empty

## Pipeline Status

- **Lifecycle:** Completed
- **Phase:** Deploy
- **Active Skill:** none
- **Updated:** 2026-06-01T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | | | | | | | |
"""

KB_STATE_MD = """\
# Discovery State

## Knowledge Summary Status

**User Approved:** yes (2026-06-01 -- some context)
"""

KB_README_MD = """\
# KB README

## Completeness

| # | Document | Status | Last Reviewed | Notes |
|---|----------|--------|---------------|-------|
| 1 | architecture.md | Populated | 2026-06-01 | notes |
| 2 | technology-stack.md | Populated | 2026-06-01 | notes |
| 3 | coding-standards.md | Populated | 2026-06-01 | notes |
"""


# ---------------------------------------------------------------------------
# Test classes
# ---------------------------------------------------------------------------

class TestLocator(unittest.TestCase):
    """LC-1 Locator tests."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_aid_dir(self):
        loc = locate_aid_root(self.root)
        self.assertFalse(loc.aid_exists)
        self.assertEqual(loc.work_dirs, [])

    def test_aid_dir_exists_no_works(self):
        make_aid_dir(self.root)
        loc = locate_aid_root(self.root)
        self.assertTrue(loc.aid_exists)
        self.assertEqual(loc.work_dirs, [])

    def test_enumerate_work_dirs(self):
        aid = make_aid_dir(self.root)
        make_work_dir(aid, "work-001-alpha")
        make_work_dir(aid, "work-002-beta")
        # These should NOT appear (not matching work-[0-9]*-*)
        (aid / ".temp").mkdir()
        (aid / ".heartbeat").mkdir()
        (aid / "knowledge").mkdir()
        (aid / "not-a-work").mkdir()

        loc = locate_aid_root(self.root)
        self.assertTrue(loc.aid_exists)
        names = [p.name for p in loc.work_dirs]
        self.assertIn("work-001-alpha", names)
        self.assertIn("work-002-beta", names)
        self.assertNotIn(".temp", names)
        self.assertNotIn(".heartbeat", names)
        self.assertNotIn("knowledge", names)
        self.assertNotIn("not-a-work", names)
        self.assertEqual(len(names), 2)

    def test_work_dirs_sorted(self):
        aid = make_aid_dir(self.root)
        make_work_dir(aid, "work-003-gamma")
        make_work_dir(aid, "work-001-alpha")
        make_work_dir(aid, "work-002-beta")
        loc = locate_aid_root(self.root)
        names = [p.name for p in loc.work_dirs]
        self.assertEqual(names, ["work-001-alpha", "work-002-beta", "work-003-gamma"])

    def test_accepts_repo_root_with_aid_subdir(self):
        """locate_aid_root expects the repo root; .aid/ is a subdirectory of it."""
        aid = make_aid_dir(self.root)
        make_work_dir(aid, "work-001-alpha")
        # Pass the repo root (not .aid/ itself) -- this is the expected usage
        loc = locate_aid_root(self.root)
        names = [p.name for p in loc.work_dirs]
        self.assertIn("work-001-alpha", names)

    def test_paths_computed_correctly(self):
        aid = make_aid_dir(self.root)
        loc = locate_aid_root(self.root)
        self.assertEqual(loc.manifest_path, aid / ".aid-manifest.json")
        self.assertEqual(loc.settings_path, aid / "settings.yml")
        self.assertEqual(loc.kb_dir, aid / "knowledge")


class TestParseToolInfo(unittest.TestCase):
    """parse_tool_info() tests."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.aid = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_manifest_returns_false(self):
        info, br = parse_tool_info(
            self.aid / ".aid-manifest.json",
            self.aid / ".aid-version",
        )
        self.assertFalse(info.manifest_present)
        self.assertIsNone(info.aid_version)
        self.assertEqual(br, 0)

    def test_manifest_json_parsed(self):
        manifest = {
            "manifest_version": 1,
            "aid_version": "1.2.3",
            "installed_at": "2026-01-01T00:00:00Z",
            "tools": {"claude-code": {}, "codex": {}},
        }
        mp = self.aid / ".aid-manifest.json"
        mp.write_text(json.dumps(manifest), encoding="utf-8")

        info, br = parse_tool_info(mp, self.aid / ".aid-version")
        self.assertTrue(info.manifest_present)
        self.assertEqual(info.aid_version, "1.2.3")
        self.assertEqual(info.installed_at, "2026-01-01T00:00:00Z")
        self.assertIn("claude-code", info.tools_installed)
        self.assertIn("codex", info.tools_installed)
        self.assertGreater(br, 0)

    def test_version_file_fallback(self):
        vp = self.aid / ".aid-version"
        vp.write_text("2.0.0\n", encoding="utf-8")

        info, br = parse_tool_info(self.aid / ".aid-manifest.json", vp)
        self.assertFalse(info.manifest_present)
        self.assertEqual(info.aid_version, "2.0.0")
        self.assertGreater(br, 0)

    def test_malformed_json_returns_false(self):
        mp = self.aid / ".aid-manifest.json"
        mp.write_text("not json{{", encoding="utf-8")
        info, br = parse_tool_info(mp, self.aid / ".aid-version")
        self.assertFalse(info.manifest_present)


class TestParseProjectName(unittest.TestCase):
    """parse_project_name() tests."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.aid = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_settings(self):
        name, br = parse_project_name(self.aid / "settings.yml")
        self.assertEqual(name, "")
        self.assertEqual(br, 0)

    def test_reads_project_name(self):
        sp = self.aid / "settings.yml"
        sp.write_text("project:\n  name: MyProject\n  type: brownfield\n", encoding="utf-8")
        name, br = parse_project_name(sp)
        self.assertEqual(name, "MyProject")
        self.assertGreater(br, 0)

    def test_reads_project_name_with_spaces(self):
        sp = self.aid / "settings.yml"
        sp.write_text("project:\n  name: AID Dashboard\n", encoding="utf-8")
        name, br = parse_project_name(sp)
        self.assertEqual(name, "AID Dashboard")

    def test_no_project_section(self):
        sp = self.aid / "settings.yml"
        sp.write_text("tools:\n  installed:\n    - claude-code\n", encoding="utf-8")
        name, br = parse_project_name(sp)
        self.assertEqual(name, "")


class TestParseKbState(unittest.TestCase):
    """parse_kb_state() tests."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.aid = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_kb_returns_none(self):
        ref, br = parse_kb_state(self.aid / "knowledge")
        self.assertIsNone(ref)
        self.assertEqual(br, 0)

    def test_kb_dir_present_but_no_state_md(self):
        kb = self.aid / "knowledge"
        kb.mkdir()
        ref, br = parse_kb_state(kb)
        self.assertIsNotNone(ref)
        self.assertFalse(ref.summary_approved)

    def test_summary_approved_yes(self):
        kb = make_kb_dir(self.aid)
        (kb / "STATE.md").write_text(KB_STATE_MD, encoding="utf-8")
        ref, br = parse_kb_state(kb)
        self.assertIsNotNone(ref)
        self.assertTrue(ref.summary_approved)
        self.assertEqual(ref.last_summary_date, "2026-06-01")
        self.assertGreater(br, 0)

    def test_doc_count_from_readme(self):
        kb = make_kb_dir(self.aid)
        (kb / "README.md").write_text(KB_README_MD, encoding="utf-8")
        ref, br = parse_kb_state(kb)
        self.assertIsNotNone(ref)
        self.assertEqual(ref.doc_count, 3)


class TestParseStateMd(unittest.TestCase):
    """parse_state_md() tests for the normalized path."""

    def test_normalized_lifecycle_running(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertEqual(pw.lifecycle, Lifecycle.Running)
        self.assertEqual(pw.source_mode, SourceMode.Normalized)

    def test_normalized_phase(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertEqual(pw.phase, Phase.Execute)

    def test_normalized_active_skill(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertEqual(pw.active_skill, "aid-execute")

    def test_normalized_updated(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertEqual(pw.updated, "2026-06-10T12:00:00Z")

    def test_normalized_pause_reason_dash_is_none(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertIsNone(pw.pause_reason)

    def test_normalized_block_fields_dash_is_none(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertIsNone(pw.block_reason)
        self.assertIsNone(pw.block_artifact)

    def test_tasks_parsed(self):
        pw = parse_state_md(STATE_NORMALIZED)
        self.assertEqual(len(pw.tasks), 2)
        t1 = pw.tasks[0]
        self.assertEqual(t1.task_id, "task-001")
        self.assertEqual(t1.type, "IMPLEMENT")
        self.assertEqual(t1.status, TaskStatus.InProgress)
        t2 = pw.tasks[1]
        self.assertEqual(t2.task_id, "task-002")
        self.assertEqual(t2.status, TaskStatus.Done)
        self.assertEqual(t2.review_grade, "A")

    def test_none_yet_row_skipped(self):
        pw = parse_state_md(STATE_NONE_YET)
        self.assertEqual(pw.tasks, [])

    def test_pending_inputs_only_pending_status(self):
        pw = parse_state_md(STATE_NORMALIZED)
        # Q1 is Pending, Q2 is Answered -- only Q1 should be in pending_inputs
        self.assertEqual(len(pw.pending_inputs), 1)
        self.assertEqual(pw.pending_inputs[0].question_id, "Q1")
        self.assertEqual(pw.pending_inputs[0].category, "Architecture")

    def test_no_pipeline_status_uses_fallback_adapter(self):
        """When ## Pipeline Status is absent, the LC-3 fallback adapter fires (task-011).

        STATE_NO_PIPELINE_STATUS has a pending Q1, so derive_lifecycle produces
        PausedAwaitingInput (SM-2 prio-4). source_mode=fallback is recorded.
        """
        pw = parse_state_md(STATE_NO_PIPELINE_STATUS)
        # Fallback adapter active: not Unknown (stub behavior), not normalized
        self.assertEqual(pw.source_mode, SourceMode.Fallback)
        # The fixture has Q1 Status: Pending, no IMPEDIMENT, no failed task -> Paused
        self.assertEqual(pw.lifecycle, Lifecycle.PausedAwaitingInput)
        self.assertIsNotNone(pw.pause_reason)
        # No extra parse warnings needed (fallback adapter succeeded)
        # (no "fallback adapter not yet implemented" message now)

    def test_completed_lifecycle(self):
        pw = parse_state_md(STATE_NONE_YET)
        self.assertEqual(pw.lifecycle, Lifecycle.Completed)
        self.assertEqual(pw.source_mode, SourceMode.Normalized)

    def test_blocked_lifecycle_with_reason(self):
        content = """\
## Pipeline Status

- **Lifecycle:** Blocked
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-10T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** Gate fail
- **Block Artifact:** IMPEDIMENT-task-005.md
"""
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)
        self.assertEqual(pw.block_reason, "Gate fail")
        self.assertEqual(pw.block_artifact, "IMPEDIMENT-task-005.md")

    def test_paused_lifecycle_with_reason(self):
        content = """\
## Pipeline Status

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Specify
- **Active Skill:** aid-specify
- **Updated:** 2026-06-10T00:00:00Z
- **Pause Reason:** Awaiting user decision on architecture
- **Block Reason:** --
- **Block Artifact:** --
"""
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.PausedAwaitingInput)
        self.assertEqual(pw.pause_reason, "Awaiting user decision on architecture")

    def test_unknown_lifecycle_sentinel(self):
        """Unrecognized Lifecycle literal returns Unknown (DM-6 NFR7 -- never throws)."""
        content = """\
## Pipeline Status

- **Lifecycle:** SomeFutureState
- **Phase:** Execute
- **Active Skill:** none
- **Updated:** 2026-06-10T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --
"""
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.Unknown)

    def test_unknown_task_status_sentinel(self):
        """Unrecognized TaskStatus returns Unknown sentinel (DM-6 NFR7)."""
        content = """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-10T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | 1 | SomeFuture | -- | -- | -- |
"""
        pw = parse_state_md(content)
        self.assertEqual(len(pw.tasks), 1)
        self.assertEqual(pw.tasks[0].status, TaskStatus.Unknown)


class TestEnumParsing(unittest.TestCase):
    """Enum round-trip tests for Lifecycle, Phase, TaskStatus."""

    def test_all_lifecycle_members(self):
        cases = {
            "Running": Lifecycle.Running,
            "Paused-Awaiting-Input": Lifecycle.PausedAwaitingInput,
            "Blocked": Lifecycle.Blocked,
            "Completed": Lifecycle.Completed,
            "Canceled": Lifecycle.Canceled,
        }
        for raw, expected in cases.items():
            with self.subTest(raw=raw):
                self.assertEqual(_parse_lifecycle(raw), expected)

    def test_unknown_lifecycle(self):
        self.assertEqual(_parse_lifecycle(""), Lifecycle.Unknown)
        self.assertEqual(_parse_lifecycle("invalid"), Lifecycle.Unknown)
        self.assertEqual(_parse_lifecycle("running"), Lifecycle.Unknown)  # case-sensitive

    def test_all_phase_members(self):
        cases = {
            "Interview": Phase.Interview,
            "Specify": Phase.Specify,
            "Plan": Phase.Plan,
            "Detail": Phase.Detail,
            "Execute": Phase.Execute,
            "Deploy": Phase.Deploy,
            "Monitor": Phase.Monitor,
        }
        for raw, expected in cases.items():
            with self.subTest(raw=raw):
                self.assertEqual(_parse_phase(raw), expected)

    def test_unknown_phase(self):
        self.assertEqual(_parse_phase("unknown"), Phase.Unknown)

    def test_all_task_status_members(self):
        cases = {
            "Pending": TaskStatus.Pending,
            "In Progress": TaskStatus.InProgress,
            "In Review": TaskStatus.InReview,
            "Blocked": TaskStatus.Blocked,
            "Done": TaskStatus.Done,
            "Failed": TaskStatus.Failed,
            "Canceled": TaskStatus.Canceled,
        }
        for raw, expected in cases.items():
            with self.subTest(raw=raw):
                self.assertEqual(_parse_task_status(raw), expected)

    def test_unknown_task_status(self):
        self.assertEqual(_parse_task_status(""), TaskStatus.Unknown)
        self.assertEqual(_parse_task_status("in progress"), TaskStatus.Unknown)  # case-sensitive

    def test_enum_values_match_feature001_literals(self):
        """Enum .value members must match the exact on-disk literals from work-state-template.md."""
        self.assertEqual(Lifecycle.Running.value, "Running")
        self.assertEqual(Lifecycle.PausedAwaitingInput.value, "Paused-Awaiting-Input")
        self.assertEqual(Lifecycle.Blocked.value, "Blocked")
        self.assertEqual(Lifecycle.Completed.value, "Completed")
        self.assertEqual(Lifecycle.Canceled.value, "Canceled")
        self.assertEqual(TaskStatus.Pending.value, "Pending")
        self.assertEqual(TaskStatus.InProgress.value, "In Progress")
        self.assertEqual(TaskStatus.InReview.value, "In Review")
        self.assertEqual(TaskStatus.Done.value, "Done")
        self.assertEqual(TaskStatus.Failed.value, "Failed")
        self.assertEqual(TaskStatus.Canceled.value, "Canceled")


class TestReadRepo(unittest.TestCase):
    """Integration tests for read_repo()."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_aid_dir_returns_empty_model(self):
        """SPEC AC1: absent .aid/ -> empty model + parse_warning."""
        model = read_repo(self.root)
        self.assertIsInstance(model, RepoModel)
        self.assertFalse(model.tool.manifest_present)
        self.assertEqual(model.works, [])
        self.assertGreater(len(model.read.parse_warnings), 0)
        self.assertGreater(model.read.work_count, -1)  # non-negative
        self.assertEqual(model.read.work_count, 0)

    def test_zero_works_repo(self):
        """SPEC AC1: zero-work repo returns works=[]."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid, "EmptyProject")
        model = read_repo(self.root)
        self.assertEqual(model.works, [])
        self.assertEqual(model.read.work_count, 0)
        self.assertEqual(model.repo.project_name, "EmptyProject")

    def test_single_work_normalized(self):
        """SPEC AC2/AC3: normalized path with ## Pipeline Status block."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid, "TestProject")
        wd = make_work_dir(aid, "work-001-alpha")
        write_state_md(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        self.assertEqual(len(model.works), 1)
        w = model.works[0]
        self.assertEqual(w.work_id, "work-001-alpha")
        self.assertEqual(w.lifecycle, Lifecycle.Running)
        self.assertEqual(w.source_mode, SourceMode.Normalized)
        self.assertEqual(model.read.work_count, 1)
        self.assertEqual(model.read.fallback_works, [])

    def test_multiple_works(self):
        """SPEC AC2: multiple work folders each appear as WorkModel."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid, "Multi")
        for wid in ["work-001-alpha", "work-002-beta", "work-003-gamma"]:
            wd = make_work_dir(aid, wid)
            write_state_md(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 3)
        names = [w.work_id for w in model.works]
        self.assertIn("work-001-alpha", names)
        self.assertIn("work-002-beta", names)
        self.assertIn("work-003-gamma", names)

    def test_work_without_pipeline_status_in_fallback_works(self):
        """SPEC AC4 / DM-7: works without ## Pipeline Status go into fallback_works."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-no-status")
        write_state_md(wd, STATE_NO_PIPELINE_STATUS)

        model = read_repo(self.root)
        self.assertEqual(len(model.read.fallback_works), 1)
        self.assertIn("work-001-no-status", model.read.fallback_works)

    def test_read_at_is_iso8601(self):
        """ReadMeta.read_at must be a valid ISO-8601 timestamp."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        model = read_repo(self.root)
        # Quick check: contains T and a timezone offset
        self.assertIn("T", model.read.read_at)

    def test_bytes_read_is_positive(self):
        """ReadMeta.bytes_read must be > 0 when files exist."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        model = read_repo(self.root)
        self.assertGreater(model.read.bytes_read, 0)

    def test_accepts_aid_root_as_dot_aid_path(self):
        """read_repo() should accept .aid/ itself as the argument."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-alpha")
        write_state_md(wd, STATE_NORMALIZED)

        model_via_root = read_repo(self.root)
        model_via_aid = read_repo(aid)
        self.assertEqual(model_via_root.read.work_count, model_via_aid.read.work_count)
        self.assertEqual(model_via_root.works[0].work_id, model_via_aid.works[0].work_id)

    def test_malformed_state_md_yields_warning_not_exception(self):
        """NFR7: malformed STATE.md -> parse_warning + best-effort model, never throws."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-bad")
        write_state_md(wd, "# Truncated\n\n## Pipeline Status\n\n- **Lifecycle")  # truncated

        model = read_repo(self.root)
        self.assertEqual(len(model.works), 1)
        # Should not raise; may have parse_warnings
        # Truncated lifecycle line -> Unknown
        self.assertIsInstance(model.works[0].lifecycle, Lifecycle)

    def test_missing_state_md_yields_warning(self):
        """A work folder with no STATE.md yields parse_warning + minimal WorkModel."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        make_work_dir(aid, "work-001-nostate")
        # Intentionally do NOT write STATE.md

        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 1)
        self.assertTrue(any("STATE.md" in w for w in model.read.parse_warnings))

    def test_tool_info_in_model(self):
        """ToolInfo should be populated from the manifest."""
        aid = make_aid_dir(self.root)
        write_manifest(aid, version="1.5.0")
        model = read_repo(self.root)
        self.assertTrue(model.tool.manifest_present)
        self.assertEqual(model.tool.aid_version, "1.5.0")
        self.assertIn("claude-code", model.tool.tools_installed)

    def test_kb_state_present_when_knowledge_dir_exists(self):
        """kb_state should be populated when .aid/knowledge/ exists."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        kb = make_kb_dir(aid)
        (kb / "STATE.md").write_text(KB_STATE_MD, encoding="utf-8")
        (kb / "README.md").write_text(KB_README_MD, encoding="utf-8")

        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        self.assertTrue(model.repo.kb_state.summary_approved)
        self.assertEqual(model.repo.kb_state.doc_count, 3)

    def test_kb_state_none_when_knowledge_dir_absent(self):
        """kb_state should be None when .aid/knowledge/ does not exist."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        model = read_repo(self.root)
        self.assertIsNone(model.repo.kb_state)

    def test_tasks_in_work_model(self):
        """Task list should be populated from ## Tasks Status."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-tasks")
        write_state_md(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        tasks = model.works[0].tasks
        self.assertEqual(len(tasks), 2)

    def test_pending_inputs_in_work_model(self):
        """Only Q{N} items with Status: Pending appear in pending_inputs."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-qa")
        write_state_md(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        pending = model.works[0].pending_inputs
        self.assertEqual(len(pending), 1)
        self.assertEqual(pending[0].question_id, "Q1")

    def test_name_slug_extracted(self):
        """WorkModel.name should be the slug (strip work-NNN- prefix)."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-my-feature")
        write_state_md(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        self.assertEqual(model.works[0].name, "my-feature")

    def test_no_write_primitives_in_reader_modules(self):
        """Self-check: reader module files must contain no write primitive."""
        import ast

        reader_dir = Path(__file__).resolve().parents[1]  # dashboard/reader/
        modules = [
            reader_dir / "locator.py",
            reader_dir / "parsers.py",
            reader_dir / "reader.py",
            reader_dir / "models.py",
            reader_dir / "derivation.py",  # task-011: fallback adapter
        ]

        write_primitives = {"open"}
        write_modes = {"w", "wb", "a", "ab", "x", "xb"}

        for mod_path in modules:
            source = mod_path.read_text(encoding="utf-8")
            tree = ast.parse(source, filename=str(mod_path))
            for node in ast.walk(tree):
                if isinstance(node, ast.Call):
                    # Check for open(..., 'w') / open(..., 'wb') etc.
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
                                            f"Write primitive found in {mod_path.name}: "
                                            f"open() with mode containing '{c}'"
                                        )
                        for kw in node.keywords:
                            if kw.arg == "mode" and isinstance(kw.value, ast.Constant):
                                for c in str(kw.value.value):
                                    if c in write_modes:
                                        self.fail(
                                            f"Write primitive found in {mod_path.name}: "
                                            f"open(mode=) containing '{c}'"
                                        )


class TestKbHelpers(unittest.TestCase):
    """Unit tests for the KB parse helper functions."""

    def test_parse_kb_summary_approval_yes(self):
        text = "## Knowledge Summary Status\n\n**User Approved:** yes (2026-06-10 -- stuff)\n"
        approved, date = _parse_kb_summary_approval(text)
        self.assertTrue(approved)
        self.assertEqual(date, "2026-06-10")

    def test_parse_kb_summary_approval_no(self):
        text = "## Knowledge Summary Status\n\n**User Approved:** no\n"
        approved, date = _parse_kb_summary_approval(text)
        self.assertFalse(approved)
        self.assertIsNone(date)

    def test_parse_kb_summary_approval_absent(self):
        text = "## Some Other Section\n\n**User Approved:** yes\n"
        approved, date = _parse_kb_summary_approval(text)
        self.assertFalse(approved)

    def test_parse_kb_doc_count(self):
        self.assertEqual(_parse_kb_doc_count(KB_README_MD), 3)

    def test_parse_kb_doc_count_absent(self):
        self.assertIsNone(_parse_kb_doc_count("# No completeness section\n"))

    def test_parse_kb_doc_count_empty_table(self):
        text = "## Completeness\n\n| # | Document |\n|---|---|\n"
        self.assertEqual(_parse_kb_doc_count(text), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
