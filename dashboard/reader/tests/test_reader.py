"""
test_reader.py -- Unit tests for the AID state reader (feature-002, task-010).

Focused unit tests for:
  - read_repo()      : the public entry point
  - LC-1 Locator     : locate_aid_root(), enumerate work dirs
  - LC-2 Parsers     : parse_tool_info(), parse_project_name(), parse_project_settings(),
                        parse_minimum_grade(), parse_kb_state(), parse_state_md()
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
    parse_minimum_grade,
    parse_project_name,
    parse_project_settings,
    parse_requirements_md,
    parse_spec_md,
    parse_state_md,
    parse_task_short_name,
    parse_tasks_lifecycle_md,
    parse_tool_info,
)
from dashboard.reader.state_schema import parse_state_document


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
    """Create a work directory inside the .aid/works/ container (work-016).

    Works are direct subfolders of .aid/works/ -- the container is the
    discovery selector, so the folder name is not a visibility filter.
    """
    wd = aid / "works" / work_id
    wd.mkdir(parents=True, exist_ok=True)
    return wd


def write_state_yml(work_dir: Path, content: str) -> None:
    """Write the work-root STATE.yml (work-009-refactor task-016: was
    write_state_md / STATE.md -- SPEC.md sec:D-1 retargets the state-file
    read path to a single STATE.yml document per work)."""
    (work_dir / "STATE.yml").write_text(content, encoding="utf-8")


def make_flat_work(aid: Path, work_id: str, state_yaml: str, task_ids: "list[str]") -> Path:
    """Build a full FLATTENED single-delivery layout work (feature-001):
    work-root BLUEPRINT.md + STATE.yml + tasks/task-NNN/DETAIL.md for each
    task_id -- the ONLY layout `read_repo()` populates a real, non-empty
    tasks[] list for (`_read_work_flat`, reader.py). A bare work dir with
    only a STATE.yml (no BLUEPRINT.md / tasks/ dir) routes to the legacy
    monolithic parse instead, whose `parse_state_md()` never populates
    tasks[] at all -- see test_derivation.py's
    test_fallback_no_markdown_text_never_populates_tasks for that invariant."""
    wd = make_work_dir(aid, work_id)
    (wd / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
        "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
        encoding="utf-8",
    )
    write_state_yml(wd, state_yaml)
    for task_id in task_ids:
        task_dir = wd / "tasks" / task_id
        task_dir.mkdir(parents=True)
        (task_dir / "DETAIL.md").write_text(
            f"# {task_id}: Demo task\n\n**Type:** IMPLEMENT\n", encoding="utf-8"
        )
    return wd


def make_kb_dir(aid: Path) -> Path:
    kb = aid / "knowledge"
    kb.mkdir(parents=True, exist_ok=True)
    return kb


# ---------------------------------------------------------------------------
# Minimal STATE.yml bodies (work-009-refactor task-016: were markdown STATE.md
# bodies with a '## Pipeline Status' section, a '## Tasks Status' table and a
# '## Cross-phase Q&A' section -- all three retired, SPEC.md sec:D-4). Each
# below keeps the SAME model/payload values the markdown fixture asserted,
# expressed as the flat layout's top-level scalar keys + `qa` sequence.
# `pw.tasks` is never populated by parse_state_md() itself regardless of
# input format (tasks live in `tasks_lifecycle` / per-task files, read one
# level up by reader.py) -- see make_flat_work() above for the fixture shape
# that DOES exercise a real, non-empty tasks[] through read_repo().
# ---------------------------------------------------------------------------

STATE_NORMALIZED = """\
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-10T12:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
qa:
  - id: 1
    category: Architecture
    impact: High
    state: Pending
    context: Some context
    suggested: --
  - id: 2
    category: Security
    impact: Low
    state: Answered
    context: Already answered
    suggested: 'yes'
"""

# tasks_lifecycle mapping matching STATE_NORMALIZED's former '## Tasks Status'
# table -- fed to make_flat_work() by the tests that need a real, non-empty
# tasks[] through read_repo() (task-001 In Progress, task-002 Done/A/1h).
STATE_NORMALIZED_WITH_TASKS = STATE_NORMALIZED + """\
tasks_lifecycle:
  task-001:
    state: In Progress
    review: --
    elapsed: --
    notes: first
  task-002:
    state: Done
    review: A
    elapsed: 1h
    notes: second
"""

# No `lifecycle` key at all -- the LC-3 fallback branch (source_mode=Fallback).
STATE_NO_PIPELINE_STATUS = """\
qa:
  - id: 1
    category: Requirements
    impact: Medium
    state: Pending
    context: open question
    suggested: --
"""

STATE_NONE_YET = """\
lifecycle: Completed
phase: Execute
active_skill: none
updated: '2026-06-01T00:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
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
        """work-016 container contract: EVERY direct subfolder of .aid/works/ is a
        work (name-independent), and the non-work siblings that live BESIDE works/
        under .aid/ are excluded structurally -- not by any ^work-[0-9]+- name match.
        """
        aid = make_aid_dir(self.root)
        make_work_dir(aid, "work-001-alpha")
        make_work_dir(aid, "work-002-beta")
        # A numberless / arbitrarily-named subfolder of .aid/works/ IS still a work
        # (the reported symptom cannot recur -- visibility no longer depends on the name).
        make_work_dir(aid, "numberless-work")
        # These live BESIDE works/ under .aid/ (NOT inside works/), so a plain
        # "all subfolders of .aid/works/" enumeration excludes them structurally.
        (aid / ".temp").mkdir()
        (aid / ".heartbeat").mkdir()
        (aid / "knowledge").mkdir()
        (aid / "not-a-work").mkdir()

        loc = locate_aid_root(self.root)
        self.assertTrue(loc.aid_exists)
        names = [p.name for p in loc.work_dirs]
        self.assertIn("work-001-alpha", names)
        self.assertIn("work-002-beta", names)
        self.assertIn("numberless-work", names)  # name-independent discovery
        self.assertNotIn(".temp", names)
        self.assertNotIn(".heartbeat", names)
        self.assertNotIn("knowledge", names)
        self.assertNotIn("not-a-work", names)  # sibling of works/, not inside it
        self.assertEqual(len(names), 3)

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
        info, br = parse_tool_info(self.aid / ".aid-manifest.json")
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

        info, br = parse_tool_info(mp)
        self.assertTrue(info.manifest_present)
        self.assertEqual(info.aid_version, "1.2.3")
        self.assertEqual(info.installed_at, "2026-01-01T00:00:00Z")
        self.assertIn("claude-code", info.tools_installed)
        self.assertIn("codex", info.tools_installed)
        self.assertGreater(br, 0)

    def test_version_file_no_longer_read(self):
        # The retired .aid/.aid-version marker is no longer consulted: with no
        # manifest, aid_version is None even if the legacy marker is present.
        vp = self.aid / ".aid-version"
        vp.write_text("2.0.0\n", encoding="utf-8")

        info, br = parse_tool_info(self.aid / ".aid-manifest.json")
        self.assertFalse(info.manifest_present)
        self.assertIsNone(info.aid_version)
        self.assertEqual(br, 0)

    def test_malformed_json_returns_false(self):
        mp = self.aid / ".aid-manifest.json"
        mp.write_text("not json{{", encoding="utf-8")
        info, br = parse_tool_info(mp)
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


class TestParseProjectSettings(unittest.TestCase):
    """parse_project_settings() tests (feature-002, work-017 task-005)."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.aid = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_settings(self):
        name, description, br = parse_project_settings(self.aid / "settings.yml")
        self.assertEqual(name, "")
        self.assertIsNone(description)
        self.assertEqual(br, 0)

    def test_reads_name_and_description(self):
        sp = self.aid / "settings.yml"
        sp.write_text(
            "project:\n  name: MyProject\n  description: A test project\n  type: brownfield\n",
            encoding="utf-8",
        )
        name, description, br = parse_project_settings(sp)
        self.assertEqual(name, "MyProject")
        self.assertEqual(description, "A test project")
        self.assertGreater(br, 0)

    def test_description_absent_is_none(self):
        sp = self.aid / "settings.yml"
        sp.write_text("project:\n  name: MyProject\n", encoding="utf-8")
        name, description, br = parse_project_settings(sp)
        self.assertEqual(name, "MyProject")
        self.assertIsNone(description)

    def test_description_before_name(self):
        # Order within the block shouldn't matter -- both are captured regardless
        # of which scalar comes first.
        sp = self.aid / "settings.yml"
        sp.write_text(
            "project:\n  description: A test project\n  name: MyProject\n",
            encoding="utf-8",
        )
        name, description, br = parse_project_settings(sp)
        self.assertEqual(name, "MyProject")
        self.assertEqual(description, "A test project")

    def test_real_settings_yml_format_with_comment(self):
        # Simulates the actual settings.yml format in this repo (inline comment on name:).
        content = (
            "project:\n"
            "  name: AID                          # set during /aid-config INIT\n"
            "  description: AI Integrated Development\n"
        )
        sp = self.aid / "settings.yml"
        sp.write_text(content, encoding="utf-8")
        name, description, br = parse_project_settings(sp)
        self.assertEqual(name, "AID")
        self.assertEqual(description, "AI Integrated Development")

    def test_quoted_description_with_comment(self):
        content = 'project:\n  name: MyProject\n  description: "Foo Bar" # comment\n'
        sp = self.aid / "settings.yml"
        sp.write_text(content, encoding="utf-8")
        name, description, br = parse_project_settings(sp)
        self.assertEqual(description, "Foo Bar")

    def test_no_project_section(self):
        sp = self.aid / "settings.yml"
        sp.write_text("tools:\n  installed:\n    - claude-code\n", encoding="utf-8")
        name, description, br = parse_project_settings(sp)
        self.assertEqual(name, "")
        self.assertIsNone(description)

    def test_parse_project_name_wrapper_matches(self):
        # parse_project_name remains a thin wrapper: same name result as
        # parse_project_settings()[0], for existing callers/tests.
        sp = self.aid / "settings.yml"
        sp.write_text("project:\n  name: MyProject\n  description: Desc\n", encoding="utf-8")
        name_only, br_only = parse_project_name(sp)
        name_combined, _description, br_combined = parse_project_settings(sp)
        self.assertEqual(name_only, name_combined)
        self.assertEqual(br_only, br_combined)


class TestParseMinimumGrade(unittest.TestCase):
    """parse_minimum_grade() tests (feature-002, work-017 task-005).

    Global review.minimum_grade -- a SEPARATE 'review:'-section scan from
    parse_project_settings's 'project:'-section scan (a real settings.yml has
    'tools:' between them, so the project-section break-on-next-top-level-key
    logic cannot reach 'review:').
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.aid = Path(self.tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_absent_settings(self):
        grade, br = parse_minimum_grade(self.aid / "settings.yml")
        self.assertIsNone(grade)
        self.assertEqual(br, 0)

    def test_reads_minimum_grade(self):
        sp = self.aid / "settings.yml"
        sp.write_text("review:\n  minimum_grade: A+\n", encoding="utf-8")
        grade, br = parse_minimum_grade(sp)
        self.assertEqual(grade, "A+")
        self.assertGreater(br, 0)

    def test_no_review_section(self):
        sp = self.aid / "settings.yml"
        sp.write_text("project:\n  name: MyProject\n", encoding="utf-8")
        grade, br = parse_minimum_grade(sp)
        self.assertIsNone(grade)

    def test_real_settings_yml_layout_tools_between_project_and_review(self):
        # Real settings.yml has 'tools:' between 'project:' and 'review:' --
        # this is the exact hazard that makes reusing the project-section scan
        # impossible (SPEC.md UI Specs / Layers & Components).
        content = (
            "project:\n"
            "  name: AID\n"
            "  description: AI Integrated Development\n"
            "tools:\n"
            "  installed:\n"
            "    - claude-code\n"
            "review:\n"
            "  minimum_grade: A+   # owner directive\n"
        )
        sp = self.aid / "settings.yml"
        sp.write_text(content, encoding="utf-8")
        grade, br = parse_minimum_grade(sp)
        self.assertEqual(grade, "A+")

    def test_strips_inline_comment(self):
        sp = self.aid / "settings.yml"
        sp.write_text(
            "review:\n  minimum_grade: A+   # owner directive 2026-06-27\n",
            encoding="utf-8",
        )
        grade, br = parse_minimum_grade(sp)
        self.assertEqual(grade, "A+")

    def test_quoted_value(self):
        sp = self.aid / "settings.yml"
        sp.write_text('review:\n  minimum_grade: "A-"\n', encoding="utf-8")
        grade, br = parse_minimum_grade(sp)
        self.assertEqual(grade, "A-")


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

    def test_tasks_lifecycle_parsed(self):
        """Task cells now come from parse_tasks_lifecycle_md's `tasks_lifecycle`
        mapping (was: test_tasks_parsed via parse_state_md's '## Tasks Status'
        table -- deleted, sec:L-3: parse_state_md() never populates pw.tasks
        at all any more, see test_derivation.py's
        test_fallback_no_markdown_text_never_populates_tasks). This is the
        function reader.py's _read_work_flat actually calls for task cells."""
        tasks_lifecycle, warnings = parse_tasks_lifecycle_md(STATE_NORMALIZED_WITH_TASKS)
        self.assertEqual(warnings, [])
        self.assertEqual(len(tasks_lifecycle), 2)
        t1 = tasks_lifecycle["task-001"]
        self.assertEqual(t1.state, TaskStatus.InProgress)
        t2 = tasks_lifecycle["task-002"]
        self.assertEqual(t2.state, TaskStatus.Done)
        self.assertEqual(t2.review, "A")

    def test_no_tasks_lifecycle_key_yields_empty_mapping(self):
        """was test_none_yet_row_skipped ('_none yet_' placeholder row). The
        placeholder-row convention has no meaning once tasks are a mapping,
        not a table -- absence of the whole `tasks_lifecycle` key is the
        equivalent 'no tasks yet' shape, and yields an empty mapping."""
        tasks_lifecycle, _warnings = parse_tasks_lifecycle_md(STATE_NONE_YET)
        self.assertEqual(tasks_lifecycle, {})

    def test_pending_inputs_only_pending_status(self):
        pw = parse_state_md(STATE_NORMALIZED)
        # Q1 is Pending, Q2 is Answered -- only Q1 should be in pending_inputs
        self.assertEqual(len(pw.pending_inputs), 1)
        self.assertEqual(pw.pending_inputs[0].question_id, "Q1")
        self.assertEqual(pw.pending_inputs[0].category, "Architecture")

    def test_no_lifecycle_key_is_a_safe_noop_fallback(self):
        """Content-level update (task-016), was 'no_pipeline_status_uses_
        fallback_adapter': when the `lifecycle` key is absent, the LC-3
        fallback adapter fires (source_mode=Fallback) -- but it can no
        longer derive PausedAwaitingInput from THIS document's own `qa`
        entries (parse_state_md() reads `qa` -> pending_inputs AFTER the
        fallback branch has already returned; see test_derivation.py's
        test_fallback_pending_qa_signal_is_a_noop_via_parse_state_md for the
        exact ordering). It degrades to the safe no-op (Running), and
        pw.pending_inputs is populated afterward regardless."""
        pw = parse_state_md(STATE_NO_PIPELINE_STATUS)
        self.assertEqual(pw.source_mode, SourceMode.Fallback)
        self.assertEqual(pw.lifecycle, Lifecycle.Running)
        self.assertIsNone(pw.pause_reason)
        self.assertEqual(len(pw.pending_inputs), 1, "qa is still read, just too late to inform lifecycle")

    def test_completed_lifecycle(self):
        pw = parse_state_md(STATE_NONE_YET)
        self.assertEqual(pw.lifecycle, Lifecycle.Completed)
        self.assertEqual(pw.source_mode, SourceMode.Normalized)

    def test_blocked_lifecycle_with_reason(self):
        content = (
            "lifecycle: Blocked\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            "updated: '2026-06-10T00:00:00Z'\n"
            "pause_reason: --\n"
            "block_reason: Gate fail\n"
            "block_artifact: IMPEDIMENT-task-005.md\n"
        )
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.Blocked)
        self.assertEqual(pw.block_reason, "Gate fail")
        self.assertEqual(pw.block_artifact, "IMPEDIMENT-task-005.md")

    def test_paused_lifecycle_with_reason(self):
        content = (
            "lifecycle: Paused-Awaiting-Input\n"
            "phase: Specify\n"
            "active_skill: aid-specify\n"
            "updated: '2026-06-10T00:00:00Z'\n"
            "pause_reason: Awaiting user decision on architecture\n"
            "block_reason: --\n"
            "block_artifact: --\n"
        )
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.PausedAwaitingInput)
        self.assertEqual(pw.pause_reason, "Awaiting user decision on architecture")

    def test_unknown_lifecycle_sentinel(self):
        """Unrecognized Lifecycle literal returns Unknown (DM-6 NFR7 -- never throws)."""
        content = (
            "lifecycle: SomeFutureState\n"
            "phase: Execute\n"
            "active_skill: none\n"
            "updated: '2026-06-10T00:00:00Z'\n"
            "pause_reason: --\n"
            "block_reason: --\n"
            "block_artifact: --\n"
        )
        pw = parse_state_md(content)
        self.assertEqual(pw.lifecycle, Lifecycle.Unknown)

    def test_unknown_task_status_sentinel(self):
        """Unrecognized TaskStatus returns Unknown sentinel (DM-6 NFR7) --
        was via parse_state_md's '## Tasks Status' table, now via
        parse_tasks_lifecycle_md's `tasks_lifecycle` mapping (the function
        that actually owns task-status parsing post-refactor)."""
        content = (
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            "updated: '2026-06-10T00:00:00Z'\n"
            "pause_reason: --\n"
            "block_reason: --\n"
            "block_artifact: --\n"
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: SomeFuture\n"
        )
        tasks_lifecycle, _warnings = parse_tasks_lifecycle_md(content)
        self.assertEqual(len(tasks_lifecycle), 1)
        self.assertEqual(tasks_lifecycle["task-001"].state, TaskStatus.Unknown)


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
        # Faithful numbered pipeline; ends at Execute.
        cases = {
            "Describe": Phase.Describe,
            "Define": Phase.Define,
            "Specify": Phase.Specify,
            "Plan": Phase.Plan,
            "Detail": Phase.Detail,
            "Execute": Phase.Execute,
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
        """SPEC AC2/AC3: normalized path with a `lifecycle:` key present."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid, "TestProject")
        wd = make_work_dir(aid, "work-001-alpha")
        write_state_yml(wd, STATE_NORMALIZED)

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
            write_state_yml(wd, STATE_NORMALIZED)

        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 3)
        names = [w.work_id for w in model.works]
        self.assertIn("work-001-alpha", names)
        self.assertIn("work-002-beta", names)
        self.assertIn("work-003-gamma", names)

    def test_work_without_lifecycle_key_in_fallback_works(self):
        """SPEC AC4 / DM-7: was 'without ## Pipeline Status'. A document
        carrying no `lifecycle` key at all (absent/truncated) is the ONLY
        thing that still routes to fallback_works -- there is no more
        markdown section to be absent (sec:D-1/D-4)."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-no-status")
        write_state_yml(wd, STATE_NO_PIPELINE_STATUS)

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
        write_state_yml(wd, STATE_NORMALIZED)

        model_via_root = read_repo(self.root)
        model_via_aid = read_repo(aid)
        self.assertEqual(model_via_root.read.work_count, model_via_aid.read.work_count)
        self.assertEqual(model_via_root.works[0].work_id, model_via_aid.works[0].work_id)

    def test_truncated_state_yml_yields_warning_not_exception(self):
        """NFR7 / new degradation-path assertion (task-016): a STATE.yml torn
        mid-write (e.g. by a power loss during the writer's atomic-mv window)
        -- one clean key, one tab-indented line (a D-3 reject -> warning,
        skipped), one line cut off mid-value with no trailing newline --
        still parses to a best-effort model. Never raises; the torn/rejected
        lines are reported as parse_warnings, the clean key before them is
        still honored, and the read stops there rather than fabricating
        data past the tear."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-bad")
        write_state_yml(
            wd,
            "lifecycle: Running\n"
            "\tactive_skill: aid-execute\n"  # tab-indented -- D-3 reject
            "phase: Ex"  # cut off mid-value, no trailing newline
        )

        model = read_repo(self.root)
        self.assertEqual(len(model.works), 1)
        w = model.works[0]
        self.assertIsInstance(w.lifecycle, Lifecycle)
        self.assertEqual(w.lifecycle, Lifecycle.Running, "the clean key before the tear still reads")
        self.assertIsNone(w.active_skill, "the tab-indented reject never resolves a value")
        self.assertEqual(w.phase, Phase.Unknown, "the torn value degrades to Unknown, never raises")
        self.assertTrue(
            any("work-001-bad" in warn and "tab" in warn for warn in model.read.parse_warnings),
            "the tab-indentation reject must be reported as a parse_warning naming the file",
        )

    def test_unknown_key_degradation_path(self):
        """New degradation-path assertion (task-016): an unrecognized
        top-level key (forward-compat -- e.g. authored by a NEWER writer
        version) is silently ignored. Parsing is otherwise unaffected: every
        recognized sibling key still resolves, and no exception, no warning
        and no corruption of neighboring keys results from the one this
        reader does not know about."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-future-key")
        write_state_yml(
            wd,
            "lifecycle: Running\n"
            "phase: Execute\n"
            "some_future_field_this_reader_does_not_know_about: surprise\n"
            "active_skill: aid-execute\n",
        )

        model = read_repo(self.root)
        self.assertEqual(len(model.works), 1)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running)
        self.assertEqual(w.phase, Phase.Execute)
        self.assertEqual(w.active_skill, "aid-execute")

    def test_missing_state_yml_yields_warning(self):
        """A work folder with no STATE.yml yields parse_warning + minimal WorkModel."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        make_work_dir(aid, "work-001-nostate")
        # Intentionally do NOT write STATE.yml

        model = read_repo(self.root)
        self.assertEqual(model.read.work_count, 1)
        self.assertTrue(any("STATE.yml" in w for w in model.read.parse_warnings))

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
        """Task list should be populated from `tasks_lifecycle` (flat layout;
        was '## Tasks Status' -- sec:D-4. A bare monolithic work never
        populates tasks[] any more regardless of format, so this needs the
        full flat-layout fixture -- see make_flat_work())."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        make_flat_work(aid, "work-001-tasks", STATE_NORMALIZED_WITH_TASKS,
                        task_ids=["task-001", "task-002"])

        model = read_repo(self.root)
        tasks = model.works[0].tasks
        self.assertEqual(len(tasks), 2)
        self.assertEqual(tasks[0].status, TaskStatus.InProgress)
        self.assertEqual(tasks[1].status, TaskStatus.Done)
        self.assertEqual(tasks[1].review_grade, "A")

    def test_pending_inputs_in_work_model(self):
        """Only qa[] entries with state: Pending appear in pending_inputs."""
        aid = make_aid_dir(self.root)
        write_manifest(aid)
        write_settings(aid)
        wd = make_work_dir(aid, "work-001-qa")
        write_state_yml(wd, STATE_NORMALIZED)

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
        write_state_yml(wd, STATE_NORMALIZED)

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
            reader_dir / "io_bounds.py",   # v2.1.0 security hardening (FIX-3)
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
    """PF-4: phase derived SOLELY from the top-level `phase:` key (was: SOLELY
    from the '## Pipeline Status' block -- sec:D-4 retires the block into
    that one key; the single-source property itself is unchanged)."""

    def test_phase_from_lifecycle_key_present(self):
        text = (
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            "updated: '2026-06-11T00:00:00+00:00'\n"
        )
        pw = parse_state_md(text)
        from dashboard.reader.models import Phase
        self.assertEqual(pw.phase, Phase.Execute)
        self.assertEqual(pw.source_mode.value, "normalized")

    def test_phase_absent_when_no_lifecycle_key(self):
        # Bootstrap case: no `lifecycle` key at all -> phase must be None (not "unknown")
        text = (
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: In Progress\n"
        )
        pw = parse_state_md(text)
        self.assertIsNone(pw.phase)
        self.assertEqual(pw.source_mode.value, "fallback")

    def test_no_secondary_phase_from_legacy_prose(self):
        """A stray legacy-shaped '> **Phase:** Execute' blockquote LINE inside
        an otherwise `lifecycle`-absent document must not feed phase -- there
        is no more prose scan to accidentally pick it up (was: the same
        property against a legacy markdown blockquote)."""
        text = (
            "> **Phase:** Execute\n\n"
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: In Progress\n"
        )
        pw = parse_state_md(text)
        # Phase must be None (no `phase` key); the stray blockquote line is
        # a malformed-line reject (D-3), never a value source.
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

    def test_delivery_from_state_wave_column_is_now_unreachable(self):
        """PF-5c, content-level update (work-009-refactor task-016): the
        original PF-5c fixture used the pre-feature-001 monolithic layout --
        a bare work dir (no BLUEPRINT.md, a flat 'tasks/task-NNN.md' file
        rather than 'tasks/task-NNN/DETAIL.md') whose single state file
        carried an embedded '## Tasks Status' table with a Wave column. That
        table -- a DERIVED, non-authoritative view -- is exactly what
        SPEC.md sec:L-3 deletes ('_parse_tasks_line ... nothing to
        retarget', sec:D-2/SP-3): parse_state_md() never populates pw.tasks
        for ANY input, markdown or YAML (see test_derivation.py's
        test_fallback_no_markdown_text_never_populates_tasks). This specific
        monolithic-plus-embedded-table shape therefore has no successor --
        the flat layout's tasks_lifecycle mapping has no Wave/delivery
        column at all (delivery is always the flat layout's single implicit
        delivery-001, hardcoded in reader.py's _read_work_flat), and the
        hierarchical layout gets its delivery number from the folder name,
        never from a state-file column. This test now asserts the resulting
        (accepted, spec-scoped) degradation directly: the monolithic path
        yields zero tasks, not a delivery/lane-enriched one."""
        import tempfile as _tmp
        with _tmp.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "works" / "work-001-test"
            work.mkdir(parents=True)
            tasks_dir = work / "tasks"
            tasks_dir.mkdir()

            (work / "STATE.yml").write_text(
                "lifecycle: Running\n"
                "phase: Execute\n"
                "updated: '2026-06-11'\n",
                encoding="utf-8",
            )
            (work / "PLAN.md").write_text(
                "### delivery-002 execution graph\n\n"
                "```wave-map\n"
                "delivery: 002\n"
                "wave 3: task-001\n"
                "```\n",
                encoding="utf-8",
            )
            # Legacy flat task file (tasks/task-NNN.md, not tasks/task-NNN/DETAIL.md
            # -- the pre-feature-001 shape this fixture always used).
            (tasks_dir / "task-001.md").write_text(
                "# task-001: My task title\n\nBody.\n", encoding="utf-8"
            )
            from dashboard.reader import read_repo
            model = read_repo(root)
        work_model = model.works[0]
        self.assertEqual(work_model.tasks, [],
                          "the monolithic path never populates tasks[] any more -- "
                          "not a regression this task introduces, a pre-existing "
                          "mechanism this refactor's YAML conversion made permanently "
                          "unreachable (accepted by SPEC.md sec:L-3)")


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
        """Content-level update (task-016): the original fixture used the
        monolithic layout's embedded '## Tasks Status' Wave column, now
        permanently unreachable for tasks[] (see
        test_delivery_from_state_wave_column_is_now_unreachable above). The
        FLAT layout is the real mechanism that produces a non-empty tasks[]
        with delivery=1 (flat's hardcoded single implicit delivery) and
        lane=None (no PLAN.md) -- the exact pair this test always asserted."""
        import sys
        sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
        from dashboard.server import server as srv
        import tempfile as _tmp
        with _tmp.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            make_flat_work(
                aid, "work-001-test",
                "lifecycle: Running\n"
                "phase: Execute\n"
                "updated: '2026-06-11'\n"
                "tasks_lifecycle:\n"
                "  task-001:\n"
                "    state: In Progress\n",
                task_ids=["task-001"],
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
        # delivery=1 (flat layout's single implicit delivery), lane=None (no PLAN.md)
        self.assertEqual(task["delivery"], 1)
        self.assertIsNone(task["lane"])


class TestKbHelpers(unittest.TestCase):
    """Unit tests for the KB parse helper functions."""

    def test_parse_kb_summary_approval_yes(self):
        text = "## Knowledge Summary Status\n\n**User Approved:** yes (2026-06-10 -- stuff)\n"
        approved, date, mode = _parse_kb_summary_approval(text)
        self.assertTrue(approved)
        self.assertEqual(date, "2026-06-10")
        self.assertEqual(mode, SourceMode.Fallback,
                          "legacy-prose-only (no frontmatter) -> source_mode=Fallback")

    def test_parse_kb_summary_approval_no(self):
        text = "## Knowledge Summary Status\n\n**User Approved:** no\n"
        approved, date, mode = _parse_kb_summary_approval(text)
        self.assertFalse(approved)
        self.assertIsNone(date)
        self.assertEqual(mode, SourceMode.Fallback)

    def test_parse_kb_summary_approval_absent(self):
        text = "## Some Other Section\n\n**User Approved:** yes\n"
        approved, date, mode = _parse_kb_summary_approval(text)
        self.assertFalse(approved)
        self.assertEqual(mode, SourceMode.Fallback)

    def test_parse_kb_summary_approval_frontmatter_first(self):
        """work-003-state-schema task-002: frontmatter summary_approved/last_summary
        win over any legacy prose present, and source_mode=Normalized."""
        text = (
            "---\n"
            "summary_approved: yes\n"
            "last_summary: \"2026-07-01\"\n"
            "---\n"
            "## Knowledge Summary Status\n\n"
            "**User Approved:** no\n"  # legacy prose says no -- frontmatter must win
        )
        fm, _warnings = parse_state_document(text, allow_frontmatter_fence=True)
        approved, date, mode = _parse_kb_summary_approval(text, fm)
        self.assertTrue(approved, "frontmatter summary_approved must win over legacy prose")
        self.assertEqual(date, "2026-07-01")
        self.assertEqual(mode, SourceMode.Normalized)

    def test_parse_kb_summary_approval_yesno_normalization(self):
        """yes/no/true/false (case-insensitive) all normalize to the same bool."""
        for token, expected in (("YES", True), ("true", True), ("No", False), ("FALSE", False)):
            text = f"---\nsummary_approved: {token}\n---\n"
            fm, _warnings = parse_state_document(text, allow_frontmatter_fence=True)
            approved, _date, mode = _parse_kb_summary_approval(text, fm)
            self.assertEqual(approved, expected, f"token {token!r} must normalize to {expected}")
            self.assertEqual(mode, SourceMode.Normalized)

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
        req_path = fixture_root / ".aid" / "works" / "work-006-lite-sample" / "REQUIREMENTS.md"
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
    """PF-CR: parse_state_md extracts pw.created from the `lifecycle_history`
    sequence (was: the '## Lifecycle History' markdown table -- sec:D-4
    converts it to an authored YAML sequence; the extraction rule itself is
    unchanged, see parsers.py parse_state_md's docstring "the first entry
    ... whose event is 'Work created'").

    An entry whose `event` is 'Work created' (case-insensitive) yields
    created == that entry's `date` string.  Works without such an entry
    yield created is None.
    """

    _STATE_WITH_HISTORY = """\
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-10T12:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
lifecycle_history:
  - date: '2026-05-15'
    event: Work created
    grade: --
    notes: Initial creation
  - date: '2026-05-20'
    event: Define -> Specify
    grade: A
  - date: '2026-06-01'
    event: Specify -> Plan
    grade: A
"""

    _STATE_WITHOUT_HISTORY = """\
lifecycle: Completed
phase: Execute
active_skill: none
updated: '2026-06-12T00:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
"""

    _STATE_HISTORY_CASE_INSENSITIVE = """\
lifecycle: Running
phase: Plan
active_skill: aid-plan
updated: '2026-06-11T00:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
lifecycle_history:
  - date: '2026-04-01'
    event: WORK CREATED
    notes: case-insensitive check
"""

    def test_created_extracted_from_lifecycle_history(self):
        """Work with a 'Work created' entry yields created == its date string."""
        pw = parse_state_md(self._STATE_WITH_HISTORY)
        self.assertEqual(pw.created, "2026-05-15",
                         "created must be the date field of the 'Work created' entry")

    def test_created_is_none_without_history(self):
        """Work without a `lifecycle_history` key yields created is None."""
        pw = parse_state_md(self._STATE_WITHOUT_HISTORY)
        self.assertIsNone(pw.created,
                          "created must be None when lifecycle_history is absent")

    def test_created_case_insensitive_work_created(self):
        """'WORK CREATED' (all-caps) is still matched (case-insensitive)."""
        pw = parse_state_md(self._STATE_HISTORY_CASE_INSENSITIVE)
        self.assertEqual(pw.created, "2026-04-01",
                         "created extraction must be case-insensitive on 'Work created'")

    def test_created_takes_first_entry_only(self):
        """If two entries match 'Work created', only the first date is taken."""
        content = (
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            "updated: '2026-06-10T00:00:00Z'\n"
            "pause_reason: --\n"
            "block_reason: --\n"
            "block_artifact: --\n"
            "lifecycle_history:\n"
            "  - date: '2026-03-01'\n"
            "    event: Work created\n"
            "    notes: first\n"
            "  - date: '2026-04-01'\n"
            "    event: Work created\n"
            "    notes: duplicate (should be ignored)\n"
        )
        pw = parse_state_md(content)
        self.assertEqual(pw.created, "2026-03-01",
                         "created must be taken from the FIRST matching 'Work created' entry")

    def test_created_field_exposed_on_work_model(self):
        """read_repo propagates pw.created into WorkModel.created."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "works" / "work-001-cr"
            work.mkdir(parents=True)
            (work / "STATE.yml").write_text(self._STATE_WITH_HISTORY, encoding="utf-8")
            model = read_repo(root)
        self.assertEqual(len(model.works), 1)
        self.assertEqual(model.works[0].created, "2026-05-15",
                         "WorkModel.created must be set from parsed pw.created")

    def test_created_none_propagated_when_absent(self):
        """read_repo sets WorkModel.created = None when lifecycle_history is absent."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            aid = root / ".aid"
            work = aid / "works" / "work-001-nocr"
            work.mkdir(parents=True)
            (work / "STATE.yml").write_text(self._STATE_WITHOUT_HISTORY, encoding="utf-8")
            model = read_repo(root)
        self.assertEqual(len(model.works), 1)
        self.assertIsNone(model.works[0].created,
                          "WorkModel.created must be None when lifecycle_history is absent")


if __name__ == "__main__":
    unittest.main(verbosity=2)
