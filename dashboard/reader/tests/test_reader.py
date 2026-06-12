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
    parse_execution_graph,
    parse_kb_state,
    parse_project_name,
    parse_requirements_md,
    parse_spec_md,
    parse_state_md,
    parse_task_short_name,
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


# ---------------------------------------------------------------------------
# Feature-009 (delivery-006) new parse rules
# ---------------------------------------------------------------------------

class TestPF2ObjectiveBlockquoteSkip(unittest.TestCase):
    """PF-2: Objective parser skips > _..._ status blockquote lines."""

    def _req_path(self, tmpdir: Path, content: str) -> Path:
        p = tmpdir / "REQUIREMENTS.md"
        p.write_text(content, encoding="utf-8")
        return p

    def test_single_blockquote_skipped(self):
        content = (
            "# Requirements\n\n"
            "## 1. Objective\n\n"
            "The real objective text.\n\n"
            "> _Status: Complete -- approved._\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._req_path(Path(d), content)
            _, _, objective, _ = parse_requirements_md(p)
        self.assertIsNotNone(objective)
        self.assertNotIn("> _Status:", objective)
        self.assertIn("real objective text", objective)

    def test_multiple_blockquotes_all_skipped(self):
        content = (
            "# Requirements\n\n"
            "## 1. Objective\n\n"
            "Objective body here.\n\n"
            "> _Status: Complete -- approved._\n"
            "> _Another status line._\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._req_path(Path(d), content)
            _, _, objective, _ = parse_requirements_md(p)
        self.assertIsNotNone(objective)
        self.assertNotIn("> _", objective)
        self.assertIn("Objective body here", objective)

    def test_no_blockquote_unchanged(self):
        content = (
            "# Requirements\n\n"
            "## 1. Objective\n\n"
            "Clean objective with no blockquote.\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._req_path(Path(d), content)
            _, _, objective, _ = parse_requirements_md(p)
        self.assertEqual(objective, "Clean objective with no blockquote.")

    def test_blockquote_only_objective_becomes_none(self):
        # If the entire body is blockquotes, objective should be None (stripped to empty)
        content = (
            "# Requirements\n\n"
            "## 1. Objective\n\n"
            "> _Status: Complete._\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._req_path(Path(d), content)
            _, _, objective, _ = parse_requirements_md(p)
        # After stripping all blockquote lines the body is blank -> objective=None
        self.assertIsNone(objective)


class TestPF3TaskShortName(unittest.TestCase):
    """PF-3: parse_task_short_name from task-NNN.md first line."""

    def _task_path(self, tmpdir: Path, content: str, filename: str = "task-016.md") -> Path:
        p = tmpdir / filename
        p.write_text(content, encoding="utf-8")
        return p

    def test_standard_title(self):
        content = "# task-016: Python thin server\n\nBody.\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._task_path(Path(d), content)
            sn, _ = parse_task_short_name(p)
        self.assertEqual(sn, "Python thin server")

    def test_trailing_period_stripped(self):
        content = "# task-016: Python thin server.\n\nBody.\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._task_path(Path(d), content)
            sn, _ = parse_task_short_name(p)
        self.assertEqual(sn, "Python thin server")

    def test_bare_task_id_no_title(self):
        # No colon -> no short_name
        content = "# task-007\n\nBody.\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._task_path(Path(d), content)
            sn, _ = parse_task_short_name(p)
        self.assertIsNone(sn)

    def test_absent_file(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "task-999.md"
            sn, br = parse_task_short_name(p)
        self.assertIsNone(sn)
        self.assertEqual(br, 0)

    def test_leading_blank_lines_skipped(self):
        content = "\n\n# task-001: Some title\n\nBody.\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._task_path(Path(d), content)
            sn, _ = parse_task_short_name(p)
        self.assertEqual(sn, "Some title")

    def test_zero_padded_task_number(self):
        content = "# task-001: First task title\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._task_path(Path(d), content)
            sn, _ = parse_task_short_name(p)
        self.assertEqual(sn, "First task title")


class TestPF4PhaseSingleSource(unittest.TestCase):
    """PF-4: phase derived SOLELY from ## Pipeline Status block."""

    def test_phase_from_pipeline_status(self):
        text = (
            "## Pipeline Status\n\n"
            "- **Lifecycle:** Running\n"
            "- **Phase:** Execute\n"
            "- **Active Skill:** aid-execute\n"
            "- **Updated:** 2026-06-11T00:00:00+00:00\n"
        )
        pw = parse_state_md(text)
        from dashboard.reader.models import Phase
        self.assertEqual(pw.phase, Phase.Execute)
        self.assertEqual(pw.source_mode.value, "normalized")

    def test_phase_absent_when_no_pipeline_status_block(self):
        # Bootstrap case: no ## Pipeline Status -> phase must be None (not "unknown")
        text = (
            "## Tasks Status\n\n"
            "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
            "| 1 | task-001 | IMPLEMENT | delivery-001 | In Progress | - | - | - |\n"
        )
        pw = parse_state_md(text)
        self.assertIsNone(pw.phase)
        self.assertEqual(pw.source_mode.value, "fallback")

    def test_no_secondary_phase_from_blockquote(self):
        # Legacy blockquote > **Phase:** Execute must NOT feed phase
        text = (
            "> **Phase:** Execute\n\n"
            "## Tasks Status\n\n"
            "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
            "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
        )
        pw = parse_state_md(text)
        # Phase must be None (no ## Pipeline Status block); the blockquote is ignored
        self.assertIsNone(pw.phase)


class TestPF5ExecutionGraph(unittest.TestCase):
    """PF-5: parse_execution_graph from PLAN.md (wave-map + prose fallback)."""

    def _plan_path(self, tmpdir: Path, content: str) -> Path:
        p = tmpdir / "PLAN.md"
        p.write_text(content, encoding="utf-8")
        return p

    def test_wavemap_primary_parse(self):
        content = (
            "### delivery-001 execution graph\n\n"
            "```wave-map\n"
            "delivery: 001\n"
            "wave 1: task-001\n"
            "wave 2: task-002, task-003\n"
            "```\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._plan_path(Path(d), content)
            lane_map, _ = parse_execution_graph(p)
        self.assertEqual(lane_map["task-001"], 1)
        self.assertEqual(lane_map["task-002"], 2)
        self.assertEqual(lane_map["task-003"], 2)

    def test_wavemap_multiple_deliveries(self):
        content = (
            "### delivery-001 execution graph\n\n"
            "```wave-map\n"
            "delivery: 001\n"
            "wave 1: task-001\n"
            "wave 2: task-002\n"
            "```\n\n"
            "### delivery-002 execution graph\n\n"
            "```wave-map\n"
            "delivery: 002\n"
            "wave 1: task-003\n"
            "wave 2: task-004\n"
            "```\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._plan_path(Path(d), content)
            lane_map, _ = parse_execution_graph(p)
        self.assertEqual(lane_map["task-001"], 1)
        self.assertEqual(lane_map["task-002"], 2)
        self.assertEqual(lane_map["task-003"], 1)
        self.assertEqual(lane_map["task-004"], 2)

    def test_legacy_prose_fallback(self):
        content = (
            "### delivery-001 execution graph\n"
            "- Wave 1: task-001\n"
            "- Wave 2 (parallel):\n"
            "  - feature-001 lane: task-002 -> task-003\n"
            "  - feature-002 lane: task-004\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._plan_path(Path(d), content)
            lane_map, _ = parse_execution_graph(p)
        self.assertEqual(lane_map["task-001"], 1)
        # task-002, task-003 in sub-bullet of Wave 2
        self.assertEqual(lane_map["task-002"], 2)
        self.assertEqual(lane_map["task-003"], 2)
        self.assertEqual(lane_map["task-004"], 2)

    def test_ungraphed_task_returns_none(self):
        content = (
            "### delivery-001 execution graph\n\n"
            "```wave-map\n"
            "delivery: 001\n"
            "wave 1: task-001\n"
            "```\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._plan_path(Path(d), content)
            lane_map, _ = parse_execution_graph(p)
        # task-999 not in wave-map -> absent from map -> lane = None via .get()
        self.assertIsNone(lane_map.get("task-999"))

    def test_absent_plan_returns_empty(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "PLAN.md"
            lane_map, br = parse_execution_graph(p)
        self.assertEqual(lane_map, {})
        self.assertEqual(br, 0)

    def test_delivery_from_state_wave_column(self):
        """PF-5c: delivery derived from STATE Wave 'delivery-NNN' (reader.py test)."""
        import tempfile as _tmp
        with _tmp.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "work-001-test"
            work.mkdir(parents=True)
            tasks_dir = work / "tasks"
            tasks_dir.mkdir()

            # Write STATE.md with Wave = delivery-002
            (work / "STATE.md").write_text(
                "## Pipeline Status\n\n"
                "- **Lifecycle:** Running\n"
                "- **Phase:** Execute\n"
                "- **Active Skill:** -\n"
                "- **Updated:** 2026-06-11\n\n"
                "## Tasks Status\n\n"
                "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
                "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
                "| 1 | task-001 | IMPLEMENT | delivery-002 | In Progress | - | - | - |\n",
                encoding="utf-8",
            )
            # Write a minimal PLAN.md with wave-map for delivery-002
            (work / "PLAN.md").write_text(
                "### delivery-002 execution graph\n\n"
                "```wave-map\n"
                "delivery: 002\n"
                "wave 3: task-001\n"
                "```\n",
                encoding="utf-8",
            )
            # Write task file
            (tasks_dir / "task-001.md").write_text(
                "# task-001: My task title\n\nBody.\n", encoding="utf-8"
            )
            from dashboard.reader import read_repo
            model = read_repo(root)
        work_model = model.works[0]
        t = work_model.tasks[0]
        self.assertEqual(t.delivery, 2)  # from STATE Wave delivery-002
        self.assertEqual(t.lane, 3)      # from PLAN wave-map wave 3
        self.assertEqual(t.short_name, "My task title")
        self.assertNotEqual(t.delivery, 0)  # no task with delivery=0


class TestPF6ProjectNameCommentStrip(unittest.TestCase):
    """PF-6: parse_project_name strips inline YAML comment."""

    def _settings_path(self, tmpdir: Path, content: str) -> Path:
        p = tmpdir / "settings.yml"
        p.write_text(content, encoding="utf-8")
        return p

    def test_inline_comment_stripped(self):
        content = "project:\n  name: AID  # set during /aid-config INIT\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._settings_path(Path(d), content)
            name, _ = parse_project_name(p)
        self.assertEqual(name, "AID")

    def test_quoted_value_with_comment(self):
        content = 'project:\n  name: "Foo Bar" # comment\n'
        with tempfile.TemporaryDirectory() as d:
            p = self._settings_path(Path(d), content)
            name, _ = parse_project_name(p)
        self.assertEqual(name, "Foo Bar")

    def test_plain_value_no_comment(self):
        content = "project:\n  name: MyProject\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._settings_path(Path(d), content)
            name, _ = parse_project_name(p)
        self.assertEqual(name, "MyProject")

    def test_real_settings_yml_format(self):
        # Simulates the actual settings.yml format in this repo
        content = (
            "project:\n"
            "  name: AID                          # set during /aid-config INIT\n"
            "  description: AI Integrated Development\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._settings_path(Path(d), content)
            name, _ = parse_project_name(p)
        self.assertEqual(name, "AID")


class TestTaskModelNewFields(unittest.TestCase):
    """Schema version 3: TaskModel carries short_name, delivery, lane fields."""

    def test_task_model_has_new_fields(self):
        from dashboard.reader.models import TaskModel, TaskStatus
        t = TaskModel(task_id="task-001", type="IMPLEMENT")
        self.assertIsNone(t.short_name)
        self.assertIsNone(t.delivery)
        self.assertIsNone(t.lane)

    def test_task_model_fields_settable(self):
        from dashboard.reader.models import TaskModel, TaskStatus
        t = TaskModel(
            task_id="task-001",
            type="IMPLEMENT",
            short_name="My task",
            delivery=2,
            lane=3,
        )
        self.assertEqual(t.short_name, "My task")
        self.assertEqual(t.delivery, 2)
        self.assertEqual(t.lane, 3)


class TestSchemaVersion3Serialization(unittest.TestCase):
    """Server serializes schema_version 3 with new task fields in deterministic order."""

    def test_python_server_emits_schema_3(self):
        import sys
        sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
        from dashboard.server import server as srv
        import tempfile as _tmp
        with _tmp.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "work-001-test"
            work.mkdir(parents=True)
            (work / "STATE.md").write_text(
                "## Pipeline Status\n\n"
                "- **Lifecycle:** Running\n"
                "- **Phase:** Execute\n"
                "- **Active Skill:** -\n"
                "- **Updated:** 2026-06-11\n\n"
                "## Tasks Status\n\n"
                "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
                "| --- | --- | --- | --- | --- | --- | --- | --- |\n"
                "| 1 | task-001 | IMPLEMENT | delivery-001 | In Progress | - | - | - |\n",
                encoding="utf-8",
            )
            from dashboard.reader import read_repo
            model = read_repo(root)
            body = srv.serialize_model(model)
        import json as _json
        data = _json.loads(body)
        self.assertEqual(data["schema_version"], 3)
        # Verify task shape has new fields
        task = data["model"]["works"][0]["tasks"][0]
        self.assertIn("short_name", task)
        self.assertIn("delivery", task)
        self.assertIn("lane", task)
        # delivery=1 (from delivery-001 wave), lane=None (no PLAN.md)
        self.assertEqual(task["delivery"], 1)
        self.assertIsNone(task["lane"])


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


class TestPF8ParseSpecMd(unittest.TestCase):
    """PF-8: parse_spec_md -- SPEC.md identity fallback (Lite-path).

    Covers:
      (i)  SPEC with Name+Description returns them correctly.
      (ii) SPEC with only H1 (no Name line) returns H1 as h1_title; title is None.
      (iii) *(pending)* seed -> None for both title and description.
      (iv) Integration: read_repo over the Lite fixture (work-006-lite-sample)
           asserts title==SPEC Name and description==SPEC Description (HT-2).
    """

    def _spec_path(self, tmpdir: Path, content: str) -> Path:
        p = tmpdir / "SPEC.md"
        p.write_text(content, encoding="utf-8")
        return p

    def test_name_and_description_returned(self):
        """(i) SPEC with Name+Description returns both."""
        content = (
            "# My Feature\n\n"
            "- **Name:** My Feature Name\n"
            "- **Description:** A short description.\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._spec_path(Path(d), content)
            title, desc, h1, br = parse_spec_md(p)
        self.assertEqual(title, "My Feature Name")
        self.assertEqual(desc, "A short description.")
        self.assertEqual(h1, "My Feature")
        self.assertGreater(br, 0)

    def test_h1_only_no_name_line(self):
        """(ii) SPEC with only H1 (no Name line) returns H1 as h1_title; title=None."""
        content = "# Dashboard Lite\n\nSome body text.\n"
        with tempfile.TemporaryDirectory() as d:
            p = self._spec_path(Path(d), content)
            title, desc, h1, br = parse_spec_md(p)
        self.assertIsNone(title)
        self.assertIsNone(desc)
        self.assertEqual(h1, "Dashboard Lite")

    def test_pending_placeholder_returns_none(self):
        """(iii) *(pending)* seed -> None for title and description."""
        content = (
            "# Pending Work\n\n"
            "- **Name:** *(pending)*\n"
            "- **Description:** *(pending)*\n"
        )
        with tempfile.TemporaryDirectory() as d:
            p = self._spec_path(Path(d), content)
            title, desc, h1, br = parse_spec_md(p)
        self.assertIsNone(title)
        self.assertIsNone(desc)
        self.assertEqual(h1, "Pending Work")

    def test_absent_file_returns_nones(self):
        """Missing SPEC.md returns all None, bytes_read=0."""
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "SPEC.md"
            title, desc, h1, br = parse_spec_md(p)
        self.assertIsNone(title)
        self.assertIsNone(desc)
        self.assertIsNone(h1)
        self.assertEqual(br, 0)

    def test_crlf_spec_h1_parsed(self):
        """CRLF SPEC.md (H1 only) -- h1_title parsed correctly (byte-parity with Node)."""
        content = b"# CRLF Title\r\n\r\nBody text.\r\n"
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "SPEC.md"
            p.write_bytes(content)
            title, desc, h1, br = parse_spec_md(p)
        self.assertIsNone(title)
        self.assertIsNone(desc)
        self.assertEqual(h1, "CRLF Title")

    def test_read_repo_lite_fixture_ht2(self):
        """(iv) HT-2: read_repo over work-006-lite-sample asserts title==Name and desc==Description."""
        # _REPO_ROOT is parents[4] of this file (the projects/ dir); AID root is parents[3]
        _aid_root = Path(__file__).resolve().parents[3]
        fixture_root = _aid_root / "dashboard" / "server" / "tests" / "fixtures" / "pt1-aid"
        if not fixture_root.is_dir():
            self.skipTest("pt1-aid fixture not found")

        from dashboard.reader import read_repo
        model = read_repo(fixture_root)

        lite_work = None
        for w in model.works:
            if w.work_id == "work-006-lite-sample":
                lite_work = w
                break

        if lite_work is None:
            self.skipTest("work-006-lite-sample not found in fixture")

        # Must have NO REQUIREMENTS.md (this is the Lite path)
        req_path = fixture_root / ".aid" / "work-006-lite-sample" / "REQUIREMENTS.md"
        self.assertFalse(req_path.exists(), "work-006-lite-sample must NOT have REQUIREMENTS.md")

        # Title comes from SPEC.md Name (not de-slug)
        self.assertEqual(lite_work.title, "Lite Sample Feature",
                         "title must equal SPEC Name field")

        # Description comes from SPEC.md Description
        self.assertEqual(lite_work.description,
                         "A minimal Lite-path work used to verify SPEC.md identity parsing.",
                         "description must equal SPEC Description field")

        # source_mode should be normalized (has ## Pipeline Status)
        from dashboard.reader.models import SourceMode
        self.assertEqual(lite_work.source_mode, SourceMode.Normalized)


# ---------------------------------------------------------------------------
# TestCreatedField: parse_state_md extracts 'created' from Lifecycle History
# ---------------------------------------------------------------------------

class TestCreatedField(unittest.TestCase):
    """PF-CR: parse_state_md extracts pw.created from ## Lifecycle History table.

    A row whose second column is 'Work created' (case-insensitive) yields
    created == the first-column date string.  Works without that row yield
    created is None.
    """

    _STATE_WITH_HISTORY = """\
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
| 001 | task-001 | IMPLEMENT | delivery-001 | Done | A | 1h | -- |

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|--------------------------|-------|-------|
| 2026-05-15 | Work created | -- | Initial creation |
| 2026-05-20 | Interview -> Specify | A | -- |
| 2026-06-01 | Specify -> Plan | A | -- |
"""

    _STATE_WITHOUT_HISTORY = """\
## Pipeline Status

- **Lifecycle:** Completed
- **Phase:** Deploy
- **Active Skill:** none
- **Updated:** 2026-06-12T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | delivery-001 | Done | A | 2h | -- |
"""

    _STATE_HISTORY_CASE_INSENSITIVE = """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Plan
- **Active Skill:** aid-plan
- **Updated:** 2026-06-11T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|--------------------------|-------|-------|
| 2026-04-01 | WORK CREATED | -- | case-insensitive check |
"""

    def test_created_extracted_from_lifecycle_history(self):
        """Work with 'Work created' row yields created == the date string."""
        pw = parse_state_md(self._STATE_WITH_HISTORY)
        self.assertEqual(pw.created, "2026-05-15",
                         "created must be the Date cell of the 'Work created' row")

    def test_created_is_none_without_history(self):
        """Work without ## Lifecycle History section yields created is None."""
        pw = parse_state_md(self._STATE_WITHOUT_HISTORY)
        self.assertIsNone(pw.created,
                          "created must be None when no Lifecycle History table is present")

    def test_created_case_insensitive_work_created(self):
        """'WORK CREATED' (all-caps) is still matched (case-insensitive)."""
        pw = parse_state_md(self._STATE_HISTORY_CASE_INSENSITIVE)
        self.assertEqual(pw.created, "2026-04-01",
                         "created extraction must be case-insensitive on 'Work created'")

    def test_created_takes_first_row_only(self):
        """If two rows match 'Work created', only the first date is taken."""
        content = """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-10T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|--------------------------|-------|-------|
| 2026-03-01 | Work created | -- | first |
| 2026-04-01 | Work created | -- | duplicate (should be ignored) |
"""
        pw = parse_state_md(content)
        self.assertEqual(pw.created, "2026-03-01",
                         "created must be taken from the FIRST matching 'Work created' row")

    def test_created_field_exposed_on_work_model(self):
        """read_repo propagates pw.created into WorkModel.created."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "work-001-cr"
            work.mkdir(parents=True)
            (work / "STATE.md").write_text(self._STATE_WITH_HISTORY, encoding="utf-8")
            model = read_repo(root)
        self.assertEqual(len(model.works), 1)
        self.assertEqual(model.works[0].created, "2026-05-15",
                         "WorkModel.created must be set from parsed pw.created")

    def test_created_none_propagated_when_absent(self):
        """read_repo sets WorkModel.created = None when no Lifecycle History."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "work-001-nocr"
            work.mkdir(parents=True)
            (work / "STATE.md").write_text(self._STATE_WITHOUT_HISTORY, encoding="utf-8")
            model = read_repo(root)
        self.assertEqual(len(model.works), 1)
        self.assertIsNone(model.works[0].created,
                          "WorkModel.created must be None when Lifecycle History is absent")


if __name__ == "__main__":
    unittest.main(verbosity=2)
