"""
test_task069_detail_parser.py -- Unit tests for LC-TR TaskDetail sub-parsers (task-069).

Tests:
  - parse_quick_check_findings: DR-2 -- ## Quick Check Findings -> ### task-NNN -> **Findings:**
  - parse_delivery_gate: DR-3 -- ## Delivery Gates -> ### delivery-NNN grade/tier/timestamp
  - parse_deferred_issues: DR-4 -- delivery-NNN-issues.md filter to Source task == task_id
  - parse_log_availability: DR-5 -- stat .aid/.temp/dashboard.log + .aid/.heartbeat/
  - read_repo_detail: LC-TR entry point -- detail-only, always-on path untouched
  - TaskDetail model: correct shape, all fields populated
  - Torn-read tolerance: missing/malformed blocks -> parse_warnings + best-effort (never throws)
  - Clean task: empty findings list (not an error)
  - No TaskDetail on bare read_repo() call (NFR4, DD-1)

Python 3.11+ stdlib only. No third-party deps. All tests use temp dirs.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Optional

# Make the dashboard package importable when run directly or via python3 -m pytest.
_REPO_ROOT = Path(__file__).resolve().parents[4]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import (
    read_repo,
    read_repo_detail,
)
from dashboard.reader.models import (
    DeferredIssue,
    Finding,
    LogAvailability,
    RawStateRef,
    TaskDetail,
    TaskLedger,
)
from dashboard.reader.parsers import (
    parse_deferred_issues,
    parse_delivery_gate,
    parse_log_availability,
    parse_quick_check_findings,
)


# ---------------------------------------------------------------------------
# Fixture helpers
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


def _write_settings(aid: Path, project_name: str = "test-project") -> None:
    (aid / "settings.yml").write_text(
        f"project:\n  name: {project_name}\n", encoding="utf-8"
    )


def _make_work_dir(aid: Path, work_id: str) -> Path:
    work = aid / "works" / work_id
    work.mkdir(parents=True, exist_ok=True)
    return work


def _write_state_yml(work_dir: Path, content: str) -> None:
    (work_dir / "STATE.yml").write_text(content, encoding="utf-8")


# Standalone per-task STATE.yml `quick_check` snippets (work-009-refactor
# task-016: was a shared '## Quick Check Findings' -> '### task-NNN' ->
# '**Findings:**' bullet block spanning MULTIPLE tasks in one document --
# retired, SPEC.md sec:D-4. The retargeted parse_quick_check_findings reads
# ONE top-level `quick_check` key per call -- there is no more per-task
# section lookup inside a shared document, so each task now needs its OWN
# document (exactly what a real per-task STATE.yml is).
TASK_001_QUICK_CHECK_YML = """\
quick_check:
  reviewer_tier: Small (quick check always uses Small tier)
  findings:
    - severity: CRITICAL
      description: Missing null check
      source: reader.py:42
      disposition: Fixed-on-spot
    - severity: HIGH
      description: Stale comment in derivation
      source: derivation.py:88
      disposition: Deferred-to-gate
"""

TASK_002_CLEAN_QUICK_CHECK_YML = """\
quick_check:
  reviewer_tier: Small (quick check always uses Small tier)
  findings: []
"""

# The work-root STATE.yml for the TestReadRepoDetail integration fixture: a
# FLAT layout (BLUEPRINT.md + tasks/task-NNN/DETAIL.md, on disk -- see setUp)
# with a `tasks_lifecycle` mapping for task-001/task-002. Deliberately has NO
# `quick_check` / `delivery_gate.grade` sub-keys -- reader.py's DETAIL pass
# reuses THIS SAME work-root cached text for parse_quick_check_findings /
# parse_delivery_gate (DR-1/NFR4, no re-read), and those keys only ever exist
# in a PER-TASK / PER-DELIVERY STATE.yml the DETAIL pass never re-reads --
# the "pre-existing staleness preserved, not repaired" both retargeted
# parsers' docstrings document (SPEC.md sec:L-12).
FLAT_WORK_STATE_YML = """\
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-13T00:00:00Z'
tasks_lifecycle:
  task-001:
    state: Done
    review: A+
    elapsed: 1h
    notes: --
  task-002:
    state: Done
    review: --
    elapsed: 2h
    notes: --
"""

# delivery-NNN-issues.md content -- UNCHANGED format (a plain markdown table
# in its own dedicated file, never a STATE file; parse_deferred_issues is
# out of this refactor's scope). Filename/delivery number matches the flat
# layout's hardcoded wave="delivery-001" (reader.py _read_work_flat), not
# the pre-refactor fixture's "delivery-009" (see TestReadRepoDetail.setUp).
ISSUES_MD = """\
# Deferred [HIGH] Issues

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| --- | --- | --- | --- |
| task-001 | [HIGH] | Stale comment in derivation | Open |
| task-001 | [HIGH] | Another deferred issue | Resolved |
| task-002 | [HIGH] | Task-002 issue | Open |
"""


# ---------------------------------------------------------------------------
# DR-2: parse_quick_check_findings tests
# ---------------------------------------------------------------------------

class TestParseQuickCheckFindings(unittest.TestCase):
    """Tests for DR-2: the per-task STATE.yml `quick_check` mapping (SPEC.md
    sec:D-4). (work-009-refactor task-016: was a shared '## Quick Check
    Findings' -> '### task-NNN' -> '**Findings:**' bullet block -- retired;
    the retargeted parser reads ONE top-level `quick_check` key per call,
    so `task_id` is decorative (warning text only), not a section selector.)"""

    def test_finds_critical_and_high_findings(self):
        """task-001 has [CRITICAL] and [HIGH] findings."""
        warnings = []
        findings = parse_quick_check_findings(TASK_001_QUICK_CHECK_YML, "task-001", warnings)
        self.assertEqual(len(findings), 2)

        # First finding: [CRITICAL]
        f0 = findings[0]
        self.assertEqual(f0.severity, "[CRITICAL]")
        self.assertIn("null check", f0.description)
        self.assertEqual(f0.location, "reader.py:42")
        self.assertEqual(f0.disposition, "Fixed-on-spot")
        # reviewer_tier is the verbatim value from the `reviewer_tier` key
        self.assertIn("Small", f0.reviewer_tier)

        # Second finding: [HIGH]
        f1 = findings[1]
        self.assertEqual(f1.severity, "[HIGH]")
        self.assertIn("derivation", f1.description)
        self.assertEqual(f1.location, "derivation.py:88")
        self.assertEqual(f1.disposition, "Deferred-to-gate")
        self.assertIn("Small", f1.reviewer_tier)

    def test_clean_task_returns_empty_list(self):
        """A `quick_check` with an empty `findings` list -- clean task is not
        an error. (work-009-refactor task-016: was task-002's own '### task-
        002' block in a shared multi-task document -- retired; each task now
        needs its OWN standalone per-task document, TASK_002_CLEAN_QUICK_CHECK_YML.)"""
        warnings = []
        findings = parse_quick_check_findings(TASK_002_CLEAN_QUICK_CHECK_YML, "task-002", warnings)
        self.assertEqual(findings, [])
        self.assertEqual(warnings, [])

    def test_task_not_present_returns_empty_list(self):
        """No `quick_check` key at all -> empty list. (work-009-refactor
        task-016: was 'a task with no block under a shared multi-task
        section' -- retired; the retargeted parser reads ONE top-level
        `quick_check` key unconditionally, so `task_id` no longer selects
        among sections -- it is now identical in effect to
        test_missing_section_returns_empty_list, kept as an explicit,
        separately-named regression guard.)"""
        warnings = []
        findings = parse_quick_check_findings("state: Pending\n", "task-999", warnings)
        self.assertEqual(findings, [])

    def test_missing_section_returns_empty_list(self):
        """STATE.yml with no `quick_check` key -> empty list + no error."""
        text = "lifecycle: Running\n"
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(findings, [])

    def test_unknown_severity_tag_becomes_minor(self):
        """A `severity: LOW` (or any unknown) value -> [MINOR] neutral, never
        throws. (work-009-refactor task-016: was a bracketed '[LOW]' bullet
        under a '## Quick Check Findings' block -- retired, SPEC.md sec:D-4.)"""
        text = (
            "quick_check:\n"
            "  reviewer_tier: Small\n"
            "  findings:\n"
            "    - severity: LOW\n"
            "      description: Cosmetic issue\n"
            "      source: file.py:10\n"
            "      disposition: Fixed-on-spot\n"
        )
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].severity, "[MINOR]")
        self.assertEqual(findings[0].location, "file.py:10")

    def test_location_absent_is_null(self):
        """Entry without a `source` key -> location is None."""
        text = (
            "quick_check:\n"
            "  reviewer_tier: Small\n"
            "  findings:\n"
            "    - severity: HIGH\n"
            "      description: No location here\n"
            "      disposition: Deferred-to-gate\n"
        )
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertIsNone(findings[0].location)
        self.assertEqual(findings[0].disposition, "Deferred-to-gate")

    def test_disposition_absent_is_null(self):
        """Entry without a `disposition` key -> disposition is None."""
        text = (
            "quick_check:\n"
            "  reviewer_tier: Small\n"
            "  findings:\n"
            "    - severity: HIGH\n"
            "      description: No disposition\n"
            "      source: file.py:1\n"
        )
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertIsNone(findings[0].disposition)
        self.assertEqual(findings[0].location, "file.py:1")

    def test_empty_state_text_returns_empty_list(self):
        """Empty STATE.yml text -> empty list, no exception."""
        warnings = []
        findings = parse_quick_check_findings("", "task-001", warnings)
        self.assertEqual(findings, [])

    def test_reviewer_tier_on_finding(self):
        """reviewer_tier is copied from the `quick_check.reviewer_tier` key
        onto each Finding."""
        text = (
            "quick_check:\n"
            "  reviewer_tier: Medium\n"
            "  findings:\n"
            "    - severity: HIGH\n"
            "      description: Something bad\n"
        )
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        # reviewer_tier is the verbatim `reviewer_tier` value (may include parens)
        self.assertIn("Medium", findings[0].reviewer_tier)


# ---------------------------------------------------------------------------
# DR-3: parse_delivery_gate tests
# ---------------------------------------------------------------------------

class TestParseDeliveryGate(unittest.TestCase):
    """Tests for DR-3: ## Delivery Gates -> ### delivery-NNN grade/tier/timestamp."""

    def test_parses_grade_tier_timestamp(self):
        """A per-delivery STATE.yml's `delivery_gate` mapping has grade/
        reviewer_tier/gate_timestamp sub-keys (work-009-refactor task-016:
        was a '## Delivery Gates' -> '### delivery-NNN' bullet block --
        retired, SPEC.md sec:D-4). NOTE: real production `delivery_gate`
        content only ever carries `issue_list` (D-4) -- these sub-keys are
        never actually authored there; this test exercises the FUNCTION's
        own read mechanics in isolation, per its docstring's "pre-existing
        staleness preserved, not repaired" note (parsers.py parse_delivery_gate)."""
        text = (
            "delivery_gate:\n"
            "  grade: A+ (cycle 1)\n"
            "  reviewer_tier: Large (complexity score 14)\n"
            "  gate_timestamp: '2026-06-13T10:00:00Z'\n"
        )
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-009", warnings
        )
        self.assertEqual(grade, "A+")
        self.assertEqual(reviewer_tier, "Large")
        self.assertEqual(timestamp, "2026-06-13T10:00:00Z")
        self.assertEqual(warnings, [])

    def test_missing_delivery_returns_all_none(self):
        """No `delivery_gate` key at all -> grade/tier/ts all None (the
        delivery_id parameter no longer selects among multiple sections --
        the function reads ONE top-level `delivery_gate` key, delivery_id is
        used only in warning text)."""
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            "lifecycle: Running\n", "delivery-999", warnings
        )
        self.assertIsNone(grade)
        self.assertIsNone(reviewer_tier)
        self.assertIsNone(timestamp)

    def test_missing_section_returns_all_none(self):
        """STATE.yml with no `delivery_gate` key -> all None."""
        text = "lifecycle: Running\n"
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-001", warnings
        )
        self.assertIsNone(grade)
        self.assertIsNone(reviewer_tier)
        self.assertIsNone(timestamp)

    def test_empty_text_returns_all_none(self):
        """Empty text -> all None, no exception."""
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate("", "delivery-001", warnings)
        self.assertIsNone(grade)
        self.assertIsNone(reviewer_tier)
        self.assertIsNone(timestamp)

    def test_grade_verbatim_first_word(self):
        """Grade is the first word of the `grade` value (verbatim, never
        re-graded). (work-009-refactor task-016: was a '**Grade:**' bullet
        line -- retired.)"""
        text = (
            "delivery_gate:\n"
            "  grade: B+ (cycle 3)\n"
            "  reviewer_tier: Small (score 2)\n"
            "  gate_timestamp: '2026-01-01T00:00:00Z'\n"
        )
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-001", warnings
        )
        self.assertEqual(grade, "B+")
        self.assertEqual(reviewer_tier, "Small")

    # -----------------------------------------------------------------------
    # FIX 2 (pre-refactor): singular '## Delivery Gate' fallback for the
    # flat/lite promoted layout. RETIRED (work-009-refactor task-016): the
    # retargeted parse_delivery_gate reads ONE top-level `delivery_gate` key
    # unconditionally -- there is no more "plural vs singular section" or
    # "delivery_id-scoped fallback" distinction to test; delivery_id is
    # accepted only for warning text. The three tests below are KEPT (their
    # assertions still hold) but reinterpreted: they now prove the SIMPLER,
    # single-key-read behavior rather than the retired fallback mechanism.
    # -----------------------------------------------------------------------

    def test_singular_delivery_gate_fallback_when_no_plural_section(self):
        """A `delivery_gate` mapping with grade/reviewer_tier/gate_timestamp
        parses regardless of the `delivery_id` argument passed (no more
        per-delivery section lookup, SPEC.md sec:D-4)."""
        text = (
            "delivery_state: Executing\n"
            "delivery_gate:\n"
            "  reviewer_tier: Small\n"
            "  grade: A+\n"
            "  issue_list: []\n"
            "  gate_timestamp: '2026-07-08T12:00:00Z'\n"
        )
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-001", warnings
        )
        self.assertEqual(grade, "A+")
        self.assertEqual(reviewer_tier, "Small")
        self.assertEqual(timestamp, "2026-07-08T12:00:00Z")
        self.assertEqual(warnings, [])

    def test_singular_fallback_only_applies_to_delivery_001(self):
        """delivery_id is now decorative (warning text only) -- a
        `delivery_gate` mapping parses the SAME regardless of which
        delivery_id string is passed (the retired fallback's "only
        delivery-001" scoping no longer exists to test)."""
        text = (
            "delivery_gate:\n"
            "  reviewer_tier: Small\n"
            "  grade: A+\n"
            "  gate_timestamp: '2026-07-08T12:00:00Z'\n"
        )
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-002", warnings
        )
        self.assertEqual(grade, "A+")
        self.assertEqual(reviewer_tier, "Small")
        self.assertEqual(timestamp, "2026-07-08T12:00:00Z")

    # test_plural_section_present_suppresses_singular_fallback: REMOVED
    # (work-009-refactor task-016). It proved FIX 2's plural-vs-singular
    # '## Delivery Gates' / '## Delivery Gate' section-precedence rule --
    # both markdown constructs, and the whole competing-sections mechanism,
    # are retired by SPEC.md sec:D-4 (one `delivery_gate` key, no section
    # lookup at all). Nothing to retarget: the two sibling tests immediately
    # above already cover the retargeted single-key-read behavior.


# ---------------------------------------------------------------------------
# DR-4: parse_deferred_issues tests
# ---------------------------------------------------------------------------

class TestParseDeferredIssues(unittest.TestCase):
    """Tests for DR-4: parse delivery-NNN-issues.md filtered to Source task == task_id."""

    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)

    def tearDown(self):
        self.tmpdir.cleanup()

    def _write_issues(self, content: str) -> Path:
        p = self.root / "delivery-009-issues.md"
        p.write_text(content, encoding="utf-8")
        return p

    def test_filters_to_task_id(self):
        """Only rows where Source task == task-001 are returned."""
        p = self._write_issues(ISSUES_MD)
        warnings = []
        issues = parse_deferred_issues(p, "task-001", warnings)
        self.assertEqual(len(issues), 2)
        for issue in issues:
            self.assertEqual(issue.source_task, "task-001")
        self.assertEqual(issues[0].severity, "[HIGH]")
        self.assertIn("Stale", issues[0].description)
        self.assertEqual(issues[0].status, "Open")
        self.assertEqual(issues[1].status, "Resolved")

    def test_absent_file_returns_empty_list(self):
        """Missing issues file -> empty list (not an error)."""
        p = self.root / "delivery-999-issues.md"
        warnings = []
        issues = parse_deferred_issues(p, "task-001", warnings)
        self.assertEqual(issues, [])
        self.assertEqual(warnings, [])

    def test_task_with_no_issues_returns_empty(self):
        """task with no matching rows -> empty list."""
        p = self._write_issues(ISSUES_MD)
        warnings = []
        issues = parse_deferred_issues(p, "task-099", warnings)
        self.assertEqual(issues, [])

    def test_case_insensitive_match(self):
        """Source task comparison is case-insensitive."""
        content = """\
| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| --- | --- | --- | --- |
| Task-001 | [HIGH] | Issue | Open |
"""
        p = self._write_issues(content)
        warnings = []
        issues = parse_deferred_issues(p, "task-001", warnings)
        self.assertEqual(len(issues), 1)

    def test_malformed_table_best_effort(self):
        """Torn/malformed table -> best-effort (skips invalid rows, no exception)."""
        content = """\
| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-001 | [HIGH] | Good row | Open |
| only-two-cols | oops |
| task-001 | [HIGH] | Another good | Resolved |
"""
        p = self._write_issues(content)
        warnings = []
        issues = parse_deferred_issues(p, "task-001", warnings)
        # Should get the two valid rows (3-col row is skipped by cols < 4 guard)
        self.assertEqual(len(issues), 2)


# ---------------------------------------------------------------------------
# DR-5: parse_log_availability tests
# ---------------------------------------------------------------------------

class TestParseLogAvailability(unittest.TestCase):
    """Tests for DR-5: stat .aid/.temp/dashboard.log + .aid/.heartbeat/."""

    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        self.aid_dir = self.root / ".aid"
        self.aid_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        self.tmpdir.cleanup()

    def test_task_logs_always_none(self):
        """task_logs is always 'none' (DM-4: AID persists no per-task log)."""
        logs = parse_log_availability(self.aid_dir)
        self.assertEqual(logs.task_logs, "none")

    def test_server_log_absent(self):
        """server_log_present=False when .aid/.temp/dashboard.log does not exist."""
        logs = parse_log_availability(self.aid_dir)
        self.assertFalse(logs.server_log_present)

    def test_server_log_present(self):
        """server_log_present=True when .aid/.temp/dashboard.log exists."""
        temp_dir = self.aid_dir / ".temp"
        temp_dir.mkdir()
        log_file = temp_dir / "dashboard.log"
        log_file.write_text("server log line\n", encoding="utf-8")
        logs = parse_log_availability(self.aid_dir)
        self.assertTrue(logs.server_log_present)

    def test_heartbeat_absent(self):
        """heartbeat_present=False when .aid/.heartbeat/ does not exist."""
        logs = parse_log_availability(self.aid_dir)
        self.assertFalse(logs.heartbeat_present)

    def test_heartbeat_present(self):
        """heartbeat_present=True when .aid/.heartbeat/ exists as a directory."""
        hb_dir = self.aid_dir / ".heartbeat"
        hb_dir.mkdir()
        logs = parse_log_availability(self.aid_dir)
        self.assertTrue(logs.heartbeat_present)

    def test_log_availability_model_shape(self):
        """LogAvailability has the correct field shape."""
        logs = parse_log_availability(self.aid_dir)
        self.assertIsInstance(logs, LogAvailability)
        self.assertIsInstance(logs.server_log_present, bool)
        self.assertIsInstance(logs.heartbeat_present, bool)
        self.assertEqual(logs.task_logs, "none")


# ---------------------------------------------------------------------------
# LC-TR integration: read_repo_detail tests
# ---------------------------------------------------------------------------

class TestReadRepoDetail(unittest.TestCase):
    """Integration tests for read_repo_detail() LC-TR entry point.
    (work-009-refactor task-016: the fixture is now a FLAT layout --
    BLUEPRINT.md + tasks/task-NNN/DETAIL.md -- since a bare monolithic
    STATE.yml's parse_state_md() never populates pw.tasks at all (SPEC.md
    L-3); the flat layout's hardcoded wave="delivery-001" (reader.py
    _read_work_flat) is why the issues file below is "delivery-001-issues.md",
    not the pre-refactor fixture's "delivery-009".)"""

    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        self.aid = _make_aid_dir(self.root)
        _write_manifest(self.aid)
        _write_settings(self.aid, project_name="test-detail")
        # Create a FLAT-layout work folder with a STATE.yml
        self.work_dir = _make_work_dir(self.aid, "work-001-test")
        (self.work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
        for tid in ("task-001", "task-002"):
            task_dir = self.work_dir / "tasks" / tid
            task_dir.mkdir(parents=True, exist_ok=True)
            (task_dir / "DETAIL.md").write_text(
                f"# {tid}\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
            )
        _write_state_yml(self.work_dir, FLAT_WORK_STATE_YML)
        # Write issues file (delivery-001: the flat layout's hardcoded wave)
        issues_path = self.work_dir / "delivery-001-issues.md"
        issues_path.write_text(ISSUES_MD, encoding="utf-8")

    def tearDown(self):
        self.tmpdir.cleanup()

    def test_no_detail_returns_empty_dict(self):
        """read_repo_detail with no detail_task_ids -> details={} (NFR4, DD-1)."""
        model, details = read_repo_detail(self.root)
        self.assertEqual(details, {})

    def test_none_detail_task_ids_returns_empty_dict(self):
        """read_repo_detail with detail_task_ids=None -> details={} (NFR4, DD-1)."""
        model, details = read_repo_detail(self.root, detail_task_ids=None)
        self.assertEqual(details, {})

    def test_bare_read_repo_no_task_detail(self):
        """read_repo() (always-on) does NOT return any TaskDetail; TaskModel unchanged."""
        from dashboard.reader import read_repo
        model = read_repo(self.root)
        # Works and tasks are present as expected TaskModel objects
        self.assertEqual(len(model.works), 1)
        work = model.works[0]
        self.assertEqual(len(work.tasks), 2)
        # No 'details' attribute on RepoModel (NFR4)
        self.assertFalse(hasattr(work, "details"))
        self.assertFalse(hasattr(model, "details"))

    def test_detail_populated_for_requested_task(self):
        """read_repo_detail populates TaskDetail for requested task_id."""
        model, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        self.assertIn("work-001-test/task-001", details)
        td = details["work-001-test/task-001"]
        self.assertIsInstance(td, TaskDetail)
        self.assertEqual(td.task_id, "task-001")

    def test_findings_populated(self):
        """TaskDetail.findings is ALWAYS [] via read_repo_detail's real call
        chain: it reuses the work-ROOT cached state_text (DR-1/NFR4, no
        re-read), which never carries a `quick_check` key (that lives only
        in a per-task STATE.yml this pass never opens) -- the retargeted
        parse_quick_check_findings' documented "pre-existing staleness
        preserved, not repaired" (SPEC.md L-12). (work-009-refactor task-016:
        was 'parsed from ## Quick Check Findings' -- retired; per-task
        `quick_check` mechanics in isolation are covered by
        TestParseQuickCheckFindings above.)"""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(td.findings, [])

    def test_clean_task_findings_empty(self):
        """task-002 has empty Findings -> findings=[] (not an error)."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-002"],
        )
        td = details["work-001-test/task-002"]
        self.assertEqual(td.findings, [])

    def test_ledger_delivery_id_resolved(self):
        """TaskLedger.delivery_id resolved from the task's `delivery` field --
        for a FLAT-layout work that is ALWAYS 'delivery-001' (reader.py
        _read_work_flat hardcodes delivery=1; there is no deliveries/
        wrapper to enumerate a real delivery number from). (work-009-
        refactor task-016: was 'delivery-009', the pre-refactor monolithic
        fixture's authored Wave column -- retired, since a bare monolithic
        STATE.yml's tasks are now always [], SPEC.md L-3.)"""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(td.ledger.delivery_id, "delivery-001")

    def test_ledger_grade_verbatim(self):
        """TaskLedger.grade/reviewer_tier/gate_timestamp are ALWAYS None via
        the real read_repo_detail call chain: `delivery_gate` in a flat
        work's STATE.yml only ever carries `issue_list` (SPEC.md sec:D-4),
        never grade/reviewer_tier/gate_timestamp sub-keys -- the retargeted
        parse_delivery_gate's own "pre-existing staleness preserved, not
        repaired" (SPEC.md L-12). (work-009-refactor task-016: was verbatim
        from a '## Delivery Gates' bullet block -- retired; the function's
        own read mechanics in isolation are covered by TestParseDeliveryGate
        above.)"""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertIsNone(td.ledger.grade)
        self.assertIsNone(td.ledger.reviewer_tier)
        self.assertIsNone(td.ledger.gate_timestamp)

    def test_ledger_deferred_issues_filtered(self):
        """TaskLedger.deferred_issues filtered to Source task == task_id."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        # Only task-001 rows (2 rows in ISSUES_MD)
        self.assertEqual(len(td.ledger.deferred_issues), 2)
        for issue in td.ledger.deferred_issues:
            self.assertEqual(issue.source_task, "task-001")

    def test_raw_state_populated(self):
        """TaskDetail.raw_state has text/byte_len/path from already-read
        STATE.yml (work-009-refactor task-016: was 'STATE.md' -- retired)."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertIsNotNone(td.raw_state)
        self.assertIsInstance(td.raw_state, RawStateRef)
        self.assertIn("lifecycle: Running", td.raw_state.text)
        self.assertGreater(td.raw_state.byte_len, 0)
        self.assertIn("STATE.yml", td.raw_state.path)

    def test_logs_task_logs_always_none(self):
        """LogAvailability.task_logs is always 'none'."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertIsNotNone(td.logs)
        self.assertEqual(td.logs.task_logs, "none")
        self.assertIsInstance(td.logs.server_log_present, bool)
        self.assertIsInstance(td.logs.heartbeat_present, bool)

    def test_details_sorted_by_key(self):
        """details dict keys are sorted ascending by composite 'work_id/task_id'."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=[
                "work-001-test/task-002",
                "work-001-test/task-001",
            ],
        )
        keys = list(details.keys())
        self.assertEqual(keys, sorted(keys))

    def test_invalid_composite_key_adds_warning(self):
        """Invalid detail_task_ids key -> parse_warning, no crash."""
        model, details = read_repo_detail(
            self.root,
            detail_task_ids=["invalid-no-slash"],
        )
        self.assertEqual(details, {})
        self.assertTrue(
            any("invalid key" in w for w in model.read.parse_warnings),
            f"Expected 'invalid key' warning; got: {model.read.parse_warnings}",
        )

    def test_absent_work_dir_raw_state_empty(self):
        """Non-existent work_id -> raw_state.text='', parse_warning added."""
        model, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-999-nonexistent/task-001"],
        )
        td = details.get("work-999-nonexistent/task-001")
        # Should still produce a TaskDetail with empty raw_state
        self.assertIsNotNone(td)
        self.assertEqual(td.raw_state.text, "")
        # A warning about missing STATE.yml (work-009-refactor task-016:
        # was "STATE.md" -- retired, reader.py's STATE_FILENAME constant)
        self.assertTrue(
            any("STATE.yml" in w for w in model.read.parse_warnings),
            f"Expected STATE.yml warning; got: {model.read.parse_warnings}",
        )

    def test_unassociated_task_ledger_delivery_null(self):
        """Task with no delivery -> delivery_id=None, grade=None. A bare
        monolithic STATE.yml (no BLUEPRINT.md/deliveries/ wrapper) always
        yields tasks=[] now (parse_state_md never populates pw.tasks,
        SPEC.md L-3), so task-010 is never found in work_model.tasks
        regardless of content -- delivery_id stays None categorically, the
        SAME outcome this test names ('no delivery wave') for a now-
        different, simpler reason. (work-009-refactor task-016: was a
        bullet-heading STATE.md with an embedded task table -- retired.)"""
        state_no_delivery = (
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: --\n"
            "updated: '2026-06-13T00:00:00Z'\n"
        )
        work2 = _make_work_dir(self.aid, "work-002-nodelivery")
        _write_state_yml(work2, state_no_delivery)

        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-002-nodelivery/task-010"],
        )
        td = details["work-002-nodelivery/task-010"]
        self.assertIsNone(td.ledger.delivery_id)
        self.assertIsNone(td.ledger.grade)
        self.assertEqual(td.ledger.deferred_issues, [])

    def test_absent_issues_file_deferred_issues_empty(self):
        """Absent delivery-NNN-issues.md -> deferred_issues=[] (not an error)."""
        # Use a task in work-001-test but without the issues file
        issues_file = self.work_dir / "delivery-001-issues.md"
        issues_file.unlink()
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(td.ledger.deferred_issues, [])

    def test_always_on_path_not_producing_details(self):
        """Always-on read_repo() (bare call) produces NO TaskDetail (NFR4, DD-1)."""
        model = read_repo(self.root)
        # The works' tasks remain as plain TaskModel; no 'details' on the model
        self.assertEqual(len(model.works), 1)
        work = model.works[0]
        for task in work.tasks:
            self.assertFalse(hasattr(task, "details"))
            self.assertFalse(hasattr(task, "findings"))
            self.assertFalse(hasattr(task, "ledger"))
            self.assertFalse(hasattr(task, "raw_state"))
            self.assertFalse(hasattr(task, "logs"))

    def test_multiple_tasks_independent(self):
        """Multiple task_ids in detail_task_ids -> each gets its own
        TaskDetail. (work-009-refactor task-016: findings are ALWAYS []
        via the real call chain now -- see test_findings_populated's
        docstring -- so both tasks' independence is proven via task_id
        instead of a since-retired findings-count contrast.)"""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=[
                "work-001-test/task-001",
                "work-001-test/task-002",
            ],
        )
        self.assertIn("work-001-test/task-001", details)
        self.assertIn("work-001-test/task-002", details)
        self.assertEqual(details["work-001-test/task-001"].task_id, "task-001")
        self.assertEqual(details["work-001-test/task-002"].task_id, "task-002")
        self.assertEqual(details["work-001-test/task-001"].findings, [])
        self.assertEqual(details["work-001-test/task-002"].findings, [])


# ---------------------------------------------------------------------------
# Torn-read tolerance tests
# ---------------------------------------------------------------------------

class TestTornReadTolerance(unittest.TestCase):
    """Torn/missing blocks -> parse_warnings + best-effort; never throws (NFR7)."""

    def test_torn_findings_block_no_exception(self):
        """Partial/incomplete `quick_check.findings` entry -> never throws.
        (work-009-refactor task-016: was a truncated bullet -- retired,
        SPEC.md sec:D-4.)"""
        text = (
            "quick_check:\n"
            "  reviewer_tier: Small\n"
            "  findings:\n"
            "    - severity: HIGH\n"
        )
        warnings = []
        # Should not raise
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertIsNotNone(findings)

    def test_torn_delivery_gate_no_exception(self):
        """Partial `delivery_gate` mapping (grade only) -> best-effort, no
        exception. (work-009-refactor task-016: was a bullet-heading
        '## Delivery Gates' block -- retired, SPEC.md sec:D-4.)"""
        text = (
            "delivery_gate:\n"
            "  grade: A+\n"
        )
        warnings = []
        grade, tier, ts = parse_delivery_gate(text, "delivery-001", warnings)
        self.assertEqual(grade, "A+")
        self.assertIsNone(tier)
        self.assertIsNone(ts)

    def test_torn_issues_file_no_exception(self):
        """Incomplete issues file -> best-effort rows, no exception."""
        import tempfile
        with tempfile.TemporaryDirectory() as tmpdir:
            p = Path(tmpdir) / "issues.md"
            p.write_text("| Source task | Severity |\n", encoding="utf-8")
            warnings = []
            issues = parse_deferred_issues(p, "task-001", warnings)
            self.assertIsNotNone(issues)


if __name__ == "__main__":
    unittest.main()
