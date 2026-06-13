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
    work = aid / work_id
    work.mkdir(parents=True, exist_ok=True)
    return work


def _write_state_md(work_dir: Path, content: str) -> None:
    (work_dir / "STATE.md").write_text(content, encoding="utf-8")


# STATE.md snippet with ## Quick Check Findings block
FINDINGS_STATE_MD = """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-13T00:00:00Z

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 1 | task-001 | IMPLEMENT | delivery-009 | Done | A+ | 1h | -- |
| 2 | task-002 | IMPLEMENT | delivery-009 | Done | -- | 2h | -- |

## Delivery Gates

### delivery-009

- **Reviewer Tier:** Large (complexity score 14)
- **Grade:** A+ (cycle 1)
- **Timestamp:** 2026-06-13T10:00:00Z

## Quick Check Findings

> One block per task.

### task-001

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**
  - [CRITICAL] Missing null check — {reader.py:42} — Fixed-on-spot
  - [HIGH] Stale comment in derivation — {derivation.py:88} — Deferred-to-gate

### task-002

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-10 | Work created | -- | Initial scaffold |
"""

# delivery-NNN-issues.md content
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
    """Tests for DR-2: ## Quick Check Findings -> ### task-NNN -> **Findings:** bullets."""

    def test_finds_critical_and_high_findings(self):
        """task-001 has [CRITICAL] and [HIGH] findings."""
        warnings = []
        findings = parse_quick_check_findings(FINDINGS_STATE_MD, "task-001", warnings)
        self.assertEqual(len(findings), 2)

        # First finding: [CRITICAL]
        f0 = findings[0]
        self.assertEqual(f0.severity, "[CRITICAL]")
        self.assertIn("null check", f0.description)
        self.assertEqual(f0.location, "reader.py:42")
        self.assertEqual(f0.disposition, "Fixed-on-spot")
        # reviewer_tier is the verbatim value from **Reviewer Tier:** line
        self.assertIn("Small", f0.reviewer_tier)

        # Second finding: [HIGH]
        f1 = findings[1]
        self.assertEqual(f1.severity, "[HIGH]")
        self.assertIn("derivation", f1.description)
        self.assertEqual(f1.location, "derivation.py:88")
        self.assertEqual(f1.disposition, "Deferred-to-gate")
        self.assertIn("Small", f1.reviewer_tier)

    def test_clean_task_returns_empty_list(self):
        """task-002 has an empty Findings list -- clean task is not an error."""
        warnings = []
        findings = parse_quick_check_findings(FINDINGS_STATE_MD, "task-002", warnings)
        self.assertEqual(findings, [])
        self.assertEqual(warnings, [])

    def test_task_not_present_returns_empty_list(self):
        """A task with no block under ## Quick Check Findings -> empty list."""
        warnings = []
        findings = parse_quick_check_findings(FINDINGS_STATE_MD, "task-999", warnings)
        self.assertEqual(findings, [])

    def test_missing_section_returns_empty_list(self):
        """STATE.md with no ## Quick Check Findings -> empty list + no error."""
        text = "## Pipeline Status\n\n- **Lifecycle:** Running\n"
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(findings, [])

    def test_unknown_severity_tag_becomes_minor(self):
        """[LOW] or unknown bracketed tag -> [MINOR] neutral, never throws."""
        text = """\
## Quick Check Findings

### task-001

- **Reviewer Tier:** Small
- **Findings:**
  - [LOW] Cosmetic issue -- {file.py:10} -- Fixed-on-spot
"""
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].severity, "[MINOR]")
        self.assertEqual(findings[0].location, "file.py:10")

    def test_location_absent_is_null(self):
        """Bullet without {file:line} -> location is None."""
        text = """\
## Quick Check Findings

### task-001

- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] No location here -- Deferred-to-gate
"""
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertIsNone(findings[0].location)
        self.assertEqual(findings[0].disposition, "Deferred-to-gate")

    def test_disposition_absent_is_null(self):
        """Bullet without disposition token -> disposition is None."""
        text = """\
## Quick Check Findings

### task-001

- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] No disposition -- {file.py:1}
"""
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        self.assertIsNone(findings[0].disposition)
        self.assertEqual(findings[0].location, "file.py:1")

    def test_empty_state_text_returns_empty_list(self):
        """Empty STATE.md text -> empty list, no exception."""
        warnings = []
        findings = parse_quick_check_findings("", "task-001", warnings)
        self.assertEqual(findings, [])

    def test_reviewer_tier_on_finding(self):
        """reviewer_tier is copied from the block's **Reviewer Tier:** onto each Finding."""
        text = """\
## Quick Check Findings

### task-001

- **Reviewer Tier:** Medium
- **Findings:**
  - [HIGH] Something bad
"""
        warnings = []
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertEqual(len(findings), 1)
        # reviewer_tier is the verbatim value from **Reviewer Tier:** (may include parens)
        self.assertIn("Medium", findings[0].reviewer_tier)


# ---------------------------------------------------------------------------
# DR-3: parse_delivery_gate tests
# ---------------------------------------------------------------------------

class TestParseDeliveryGate(unittest.TestCase):
    """Tests for DR-3: ## Delivery Gates -> ### delivery-NNN grade/tier/timestamp."""

    def test_parses_grade_tier_timestamp(self):
        """delivery-009 gate block has Grade, Reviewer Tier, Timestamp."""
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            FINDINGS_STATE_MD, "delivery-009", warnings
        )
        self.assertEqual(grade, "A+")
        self.assertEqual(reviewer_tier, "Large")
        self.assertEqual(timestamp, "2026-06-13T10:00:00Z")
        self.assertEqual(warnings, [])

    def test_missing_delivery_returns_all_none(self):
        """delivery-999 not present -> grade/tier/ts all None."""
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            FINDINGS_STATE_MD, "delivery-999", warnings
        )
        self.assertIsNone(grade)
        self.assertIsNone(reviewer_tier)
        self.assertIsNone(timestamp)

    def test_missing_section_returns_all_none(self):
        """STATE.md with no ## Delivery Gates -> all None."""
        text = "## Pipeline Status\n\n- **Lifecycle:** Running\n"
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
        """Grade is the first word of the **Grade:** value (verbatim, never re-graded)."""
        text = """\
## Delivery Gates

### delivery-001

- **Grade:** B+ (cycle 3)
- **Reviewer Tier:** Small (score 2)
- **Timestamp:** 2026-01-01T00:00:00Z
"""
        warnings = []
        grade, reviewer_tier, timestamp = parse_delivery_gate(
            text, "delivery-001", warnings
        )
        self.assertEqual(grade, "B+")
        self.assertEqual(reviewer_tier, "Small")


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
    """Integration tests for read_repo_detail() LC-TR entry point."""

    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        self.aid = _make_aid_dir(self.root)
        _write_manifest(self.aid)
        _write_settings(self.aid, project_name="test-detail")
        # Create a work folder with STATE.md
        self.work_dir = _make_work_dir(self.aid, "work-001-test")
        _write_state_md(self.work_dir, FINDINGS_STATE_MD)
        # Write issues file
        issues_path = self.work_dir / "delivery-009-issues.md"
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
        """TaskDetail.findings parsed from ## Quick Check Findings."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(len(td.findings), 2)
        self.assertEqual(td.findings[0].severity, "[CRITICAL]")
        self.assertEqual(td.findings[1].severity, "[HIGH]")

    def test_clean_task_findings_empty(self):
        """task-002 has empty Findings -> findings=[] (not an error)."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-002"],
        )
        td = details["work-001-test/task-002"]
        self.assertEqual(td.findings, [])

    def test_ledger_delivery_id_resolved(self):
        """TaskLedger.delivery_id resolved from task's wave (delivery-009)."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(td.ledger.delivery_id, "delivery-009")

    def test_ledger_grade_verbatim(self):
        """TaskLedger.grade is verbatim from ## Delivery Gates (never re-graded)."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertEqual(td.ledger.grade, "A+")
        self.assertEqual(td.ledger.reviewer_tier, "Large")
        self.assertEqual(td.ledger.gate_timestamp, "2026-06-13T10:00:00Z")

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
        """TaskDetail.raw_state has text/byte_len/path from already-read STATE.md."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=["work-001-test/task-001"],
        )
        td = details["work-001-test/task-001"]
        self.assertIsNotNone(td.raw_state)
        self.assertIsInstance(td.raw_state, RawStateRef)
        self.assertIn("## Pipeline Status", td.raw_state.text)
        self.assertGreater(td.raw_state.byte_len, 0)
        self.assertIn("STATE.md", td.raw_state.path)

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
        # A warning about missing STATE.md
        self.assertTrue(
            any("STATE.md" in w for w in model.read.parse_warnings),
            f"Expected STATE.md warning; got: {model.read.parse_warnings}",
        )

    def test_unassociated_task_ledger_delivery_null(self):
        """Task with no delivery wave -> delivery_id=None, grade=None."""
        # Write STATE.md with a task that has no delivery wave
        state_no_delivery = """\
## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** --
- **Updated:** 2026-06-13T00:00:00Z

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 1 | task-010 | IMPLEMENT | -- | In Progress | -- | -- | -- |

## Delivery Gates

## Quick Check Findings

### task-010

- **Reviewer Tier:** Small
- **Findings:**

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-10 | Work created | -- | Initial |
"""
        work2 = _make_work_dir(self.aid, "work-002-nodelivery")
        _write_state_md(work2, state_no_delivery)

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
        issues_file = self.work_dir / "delivery-009-issues.md"
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
        """Multiple task_ids in detail_task_ids -> each gets its own TaskDetail."""
        _, details = read_repo_detail(
            self.root,
            detail_task_ids=[
                "work-001-test/task-001",
                "work-001-test/task-002",
            ],
        )
        self.assertIn("work-001-test/task-001", details)
        self.assertIn("work-001-test/task-002", details)
        # task-001 has 2 findings; task-002 has 0
        self.assertEqual(len(details["work-001-test/task-001"].findings), 2)
        self.assertEqual(len(details["work-001-test/task-002"].findings), 0)


# ---------------------------------------------------------------------------
# Torn-read tolerance tests
# ---------------------------------------------------------------------------

class TestTornReadTolerance(unittest.TestCase):
    """Torn/missing blocks -> parse_warnings + best-effort; never throws (NFR7)."""

    def test_torn_findings_block_no_exception(self):
        """Partial/incomplete findings block -> never throws."""
        text = """\
## Quick Check Findings

### task-001

- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] Truncated entry --
"""
        warnings = []
        # Should not raise
        findings = parse_quick_check_findings(text, "task-001", warnings)
        self.assertIsNotNone(findings)

    def test_torn_delivery_gate_no_exception(self):
        """Partial delivery gate block -> best-effort, no exception."""
        text = """\
## Delivery Gates

### delivery-001

- **Grade:** A+
"""
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
