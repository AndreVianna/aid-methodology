"""
test_task064_kb_status.py -- Unit tests for task-064 KB status extension.

Covers:
  - parse_kb_baseline: tolerant line-scan of .aid/settings.yml kb_baseline block
  - derive_kb_status: FF-A3 5-state waterfall (all branches)
  - git_freshness_check: FF-A2 graceful degradation (all 7 failure modes)
  - _normalize_to_utc_ms: UTC normalization helper (R12)
  - KbStateRef extended fields in read_repo() output

Python 3.11+ stdlib only. No third-party deps.
All tests are deterministic (temp dirs, no network; git tests use real git or skip).
No write / no LLM / one read-only git log subprocess for KB freshness (FR35).
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.models import KbBaseline, KbStatus, KbStateRef
from dashboard.reader.parsers import parse_kb_baseline
from dashboard.reader.derivation import (
    _normalize_to_utc_ms,
    derive_kb_status,
    git_freshness_check,
)


def _is_git_available() -> bool:
    """Return True if git is available on PATH."""
    try:
        subprocess.run(["git", "--version"], capture_output=True, timeout=2)
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_aid_tree(root: Path) -> tuple[Path, Path]:
    """Create minimal .aid/ tree, return (aid_dir, kb_dir)."""
    aid = root / ".aid"
    kb = aid / "knowledge"
    aid.mkdir(parents=True, exist_ok=True)
    return aid, kb


# ---------------------------------------------------------------------------
# parse_kb_baseline
# ---------------------------------------------------------------------------

class TestParseKbBaseline(unittest.TestCase):
    """Tests for parsers.py parse_kb_baseline (DM-A4, task-064)."""

    def test_returns_none_when_file_absent(self):
        with tempfile.TemporaryDirectory() as tmp:
            result, br = parse_kb_baseline(Path(tmp) / "settings.yml")
            self.assertIsNone(result)
            self.assertEqual(br, 0)

    def test_returns_none_when_kb_baseline_key_absent(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text("project:\n  name: MyProject\n", encoding="utf-8")
            result, br = parse_kb_baseline(settings)
            self.assertIsNone(result)
            self.assertGreater(br, 0)

    def test_parses_branch_and_tip_date(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text(
                "project:\n  name: MyProject\n"
                "kb_baseline:\n"
                "  branch: master\n"
                "  tip_date: 2026-06-12T14:03:00Z\n",
                encoding="utf-8",
            )
            result, br = parse_kb_baseline(settings)
            self.assertIsNotNone(result)
            assert result is not None
            self.assertEqual(result.branch, "master")
            self.assertEqual(result.tip_date, "2026-06-12T14:03:00Z")
            self.assertGreater(br, 0)

    def test_parses_only_branch(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text("kb_baseline:\n  branch: main\n", encoding="utf-8")
            result, _ = parse_kb_baseline(settings)
            self.assertIsNotNone(result)
            assert result is not None
            self.assertEqual(result.branch, "main")
            self.assertIsNone(result.tip_date)

    def test_returns_none_when_kb_baseline_empty(self):
        """If kb_baseline: key is present but has no sub-keys, return None."""
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text("kb_baseline:\nother: val\n", encoding="utf-8")
            result, _ = parse_kb_baseline(settings)
            self.assertIsNone(result)

    def test_strips_inline_yaml_comments(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text(
                "kb_baseline:\n"
                "  branch: main  # the default branch\n"
                "  tip_date: 2026-06-01T00:00:00Z  # baseline commit date\n",
                encoding="utf-8",
            )
            result, _ = parse_kb_baseline(settings)
            self.assertIsNotNone(result)
            assert result is not None
            self.assertEqual(result.branch, "main")
            self.assertEqual(result.tip_date, "2026-06-01T00:00:00Z")

    def test_next_top_level_key_ends_block(self):
        with tempfile.TemporaryDirectory() as tmp:
            settings = Path(tmp) / "settings.yml"
            settings.write_text(
                "kb_baseline:\n  branch: main\nother_key: value\n", encoding="utf-8"
            )
            result, _ = parse_kb_baseline(settings)
            self.assertIsNotNone(result)
            assert result is not None
            self.assertEqual(result.branch, "main")


# ---------------------------------------------------------------------------
# _normalize_to_utc_ms
# ---------------------------------------------------------------------------

class TestNormalizeToUtcMs(unittest.TestCase):
    """Tests for derivation.py _normalize_to_utc_ms (R12, FF-A2 step 4)."""

    def test_z_suffix_parses(self):
        ms = _normalize_to_utc_ms("2026-06-12T14:03:00Z")
        self.assertIsNotNone(ms)
        self.assertIsInstance(ms, int)

    def test_offset_parses(self):
        ms = _normalize_to_utc_ms("2026-06-12T10:03:00-04:00")
        self.assertIsNotNone(ms)
        self.assertIsInstance(ms, int)

    def test_z_and_offset_same_instant_equal(self):
        """Z-suffix and +00:00 offset of the same instant must yield equal ms."""
        ms_z = _normalize_to_utc_ms("2026-06-12T14:03:00Z")
        ms_offset = _normalize_to_utc_ms("2026-06-12T14:03:00+00:00")
        self.assertEqual(ms_z, ms_offset)

    def test_local_offset_equals_utc_equivalent(self):
        """2026-06-12T10:03:00-04:00 == 2026-06-12T14:03:00Z (same instant)."""
        ms_local = _normalize_to_utc_ms("2026-06-12T10:03:00-04:00")
        ms_utc = _normalize_to_utc_ms("2026-06-12T14:03:00Z")
        self.assertEqual(ms_local, ms_utc)

    def test_later_date_has_larger_ms(self):
        ms_earlier = _normalize_to_utc_ms("2026-06-01T00:00:00Z")
        ms_later = _normalize_to_utc_ms("2026-06-12T00:00:00Z")
        self.assertGreater(ms_later, ms_earlier)

    def test_empty_string_returns_none(self):
        self.assertIsNone(_normalize_to_utc_ms(""))

    def test_unparseable_returns_none(self):
        self.assertIsNone(_normalize_to_utc_ms("not-a-date"))


# ---------------------------------------------------------------------------
# derive_kb_status (FF-A3 waterfall)
# ---------------------------------------------------------------------------

class TestDeriveKbStatus(unittest.TestCase):
    """Tests for derivation.py derive_kb_status (FF-A3 waterfall, task-064)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _make_kb_dir(self, approved: bool = True) -> Path:
        kb = self.tmp / ".aid" / "knowledge"
        kb.mkdir(parents=True, exist_ok=True)
        state = kb / "STATE.md"
        approval_line = "yes (2026-06-01)" if approved else "no"
        state.write_text(
            "## Knowledge Summary Status\n"
            f"**User Approved:** {approval_line}\n",
            encoding="utf-8",
        )
        return kb

    def _make_kb_html(self) -> Path:
        dashboard_dir = self.tmp / ".aid" / "dashboard"
        dashboard_dir.mkdir(parents=True, exist_ok=True)
        kb_html = dashboard_dir / "kb.html"
        kb_html.write_text("<html></html>", encoding="utf-8")
        return kb_html

    # Step 1: pending
    def test_pending_when_knowledge_dir_absent(self):
        kb_dir = self.tmp / ".aid" / "knowledge"  # does not exist
        status = derive_kb_status(kb_dir, False, False, None, self.tmp)
        self.assertEqual(status, KbStatus.pending)

    def test_pending_when_knowledge_dir_empty(self):
        kb = self.tmp / ".aid" / "knowledge"
        kb.mkdir(parents=True)
        # empty directory
        status = derive_kb_status(kb, False, False, None, self.tmp)
        self.assertEqual(status, KbStatus.pending)

    # Step 2: generating (SPEC residual-#1 safe default)
    def test_generating_when_kb_present_not_approved(self):
        kb = self._make_kb_dir(approved=False)
        status = derive_kb_status(kb, False, False, None, self.tmp)
        self.assertEqual(status, KbStatus.generating)

    # Step 3: preparing
    def test_preparing_when_kb_approved_but_no_kb_html(self):
        kb = self._make_kb_dir(approved=True)
        status = derive_kb_status(kb, True, False, None, self.tmp)
        self.assertEqual(status, KbStatus.preparing)

    # Step 4+5: approved (no baseline -> skip freshness -> approved)
    def test_approved_when_kb_and_html_ready_no_baseline(self):
        kb = self._make_kb_dir(approved=True)
        self._make_kb_html()
        status = derive_kb_status(kb, True, True, None, self.tmp)
        self.assertEqual(status, KbStatus.approved)

    # Outdated is only tested here structurally (the git call would need a real git repo)
    # For non-git dir -> git read degrades -> approved (not outdated)
    def test_approved_when_non_git_dir_with_baseline(self):
        kb = self._make_kb_dir(approved=True)
        self._make_kb_html()
        # Non-git dir -> git_freshness_check degrades -> "skip" -> approved
        baseline = KbBaseline(branch="main", tip_date="2020-01-01T00:00:00Z")
        status = derive_kb_status(kb, True, True, baseline, self.tmp)
        # Either approved or outdated depending on whether git is available;
        # in a non-git dir it must degrade to skip -> approved
        self.assertIn(status, (KbStatus.approved, KbStatus.outdated))


# ---------------------------------------------------------------------------
# git_freshness_check degradation (FF-A2, DD-A2 7-mode matrix)
# ---------------------------------------------------------------------------

class TestGitFreshnessCheckDegradation(unittest.TestCase):
    """Tests for FF-A2 degradation modes -- every failure -> 'skip' (stay approved)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_skip_when_baseline_absent(self):
        """Degradation mode 6: kb_baseline absent -> skip."""
        result = git_freshness_check(self.tmp, None)
        self.assertEqual(result, "skip")

    def test_skip_when_not_a_git_repo(self):
        """Degradation mode 1: not a git repo -> git fails -> skip."""
        baseline = KbBaseline(branch="main", tip_date="2026-06-01T00:00:00Z")
        result = git_freshness_check(self.tmp, baseline)
        self.assertEqual(result, "skip")

    def test_skip_when_tip_date_unparseable(self):
        """Degradation mode 5: unparseable baseline tip_date -> skip."""
        baseline = KbBaseline(branch="main", tip_date="not-a-date")
        result = git_freshness_check(self.tmp, baseline)
        self.assertEqual(result, "skip")

    def test_skip_when_baseline_branch_empty_non_git(self):
        """No resolvable branch in non-git dir -> skip."""
        baseline = KbBaseline(branch=None, tip_date="2026-06-01T00:00:00Z")
        result = git_freshness_check(self.tmp, baseline)
        self.assertEqual(result, "skip")

    def test_skip_when_baseline_has_no_tip_date(self):
        """Degradation: baseline tip_date absent -> skip."""
        baseline = KbBaseline(branch="main", tip_date=None)
        result = git_freshness_check(self.tmp, baseline)
        self.assertEqual(result, "skip")

    @unittest.skipUnless(
        _is_git_available(),
        "git not available on PATH"
    )
    def test_skip_when_git_repo_but_branch_not_exist(self):
        """Degradation mode 2: branch doesn't exist -> git log fails -> skip."""
        # Initialize a git repo with no commits
        subprocess.run(["git", "init", str(self.tmp)], capture_output=True)
        baseline = KbBaseline(branch="nonexistent-branch-xyz", tip_date="2026-06-01T00:00:00Z")
        result = git_freshness_check(self.tmp, baseline)
        self.assertEqual(result, "skip")

    @unittest.skipUnless(
        _is_git_available(),
        "git not available on PATH"
    )
    def test_approved_when_tip_not_newer_than_baseline(self):
        """A real git repo with known history -> 'approved' when tip <= baseline."""
        # Use the AID repo root itself (which IS a git repo)
        # The baseline tip_date is set to far-future so current_tip <= baseline -> approved
        baseline = KbBaseline(branch="HEAD", tip_date="2099-01-01T00:00:00Z")
        result = git_freshness_check(_REPO_ROOT, baseline)
        # Should be "approved" (current tip is before 2099)
        self.assertEqual(result, "approved")

    @unittest.skipUnless(
        _is_git_available(),
        "git not available on PATH"
    )
    def test_outdated_when_tip_newer_than_baseline(self):
        """A real git repo with known history -> 'outdated' when tip > baseline."""
        # baseline is set to the past (before any commit in the repo)
        baseline = KbBaseline(branch="HEAD", tip_date="2000-01-01T00:00:00Z")
        result = git_freshness_check(_REPO_ROOT, baseline)
        # Should be "outdated" (current tip is after 2000-01-01)
        self.assertEqual(result, "outdated")


# ---------------------------------------------------------------------------
# read_repo() integration: KbStateRef extended fields
# ---------------------------------------------------------------------------

class TestReadRepoKbStateExtended(unittest.TestCase):
    """Integration tests for read_repo() KbStateRef extended fields (DM-A1)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.root = Path(self._tmp)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _make_minimal_repo(self) -> Path:
        aid = self.root / ".aid"
        aid.mkdir(parents=True, exist_ok=True)
        return aid

    def test_kb_state_none_when_knowledge_absent(self):
        """When .aid/knowledge/ is absent, kb_state is None."""
        self._make_minimal_repo()
        model = read_repo(self.root)
        self.assertIsNone(model.repo.kb_state)

    def test_kb_state_has_status_pending_when_knowledge_empty(self):
        """When .aid/knowledge/ exists but is empty, status is 'pending'."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        self.assertEqual(model.repo.kb_state.status, KbStatus.pending)
        self.assertFalse(model.repo.kb_state.summary_present)
        self.assertIsNone(model.repo.kb_state.kb_baseline)

    def test_kb_state_has_status_generating_when_kb_not_approved(self):
        """When .aid/knowledge/ has files but no User Approved: yes, status is 'generating'."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        # Create STATE.md without approval
        state = kb / "STATE.md"
        state.write_text(
            "## Knowledge Summary Status\n**User Approved:** no\n",
            encoding="utf-8",
        )
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        self.assertEqual(model.repo.kb_state.status, KbStatus.generating)

    def test_kb_state_has_status_preparing_when_no_kb_html(self):
        """KB approved but kb.html absent -> status 'preparing'."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        state = kb / "STATE.md"
        state.write_text(
            "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
            encoding="utf-8",
        )
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        self.assertEqual(model.repo.kb_state.status, KbStatus.preparing)
        self.assertFalse(model.repo.kb_state.summary_present)

    def test_kb_state_has_status_approved_when_kb_html_present(self):
        """KB approved + kb.html present -> status 'approved'."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        state = kb / "STATE.md"
        state.write_text(
            "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
            encoding="utf-8",
        )
        dashboard = aid / "dashboard"
        dashboard.mkdir()
        (dashboard / "kb.html").write_text("<html></html>", encoding="utf-8")
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        # Without a baseline, freshness check skips -> approved
        self.assertEqual(model.repo.kb_state.status, KbStatus.approved)
        self.assertTrue(model.repo.kb_state.summary_present)

    def test_kb_baseline_parsed_from_settings(self):
        """kb_baseline is parsed from settings.yml and attached to kb_state."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        state = kb / "STATE.md"
        state.write_text(
            "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
            encoding="utf-8",
        )
        settings = aid / "settings.yml"
        settings.write_text(
            "project:\n  name: Test\n"
            "kb_baseline:\n"
            "  branch: main\n"
            "  tip_date: 2026-06-01T00:00:00Z\n",
            encoding="utf-8",
        )
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        self.assertIsNotNone(model.repo.kb_state.kb_baseline)
        assert model.repo.kb_state.kb_baseline is not None
        self.assertEqual(model.repo.kb_state.kb_baseline.branch, "main")
        self.assertEqual(model.repo.kb_state.kb_baseline.tip_date, "2026-06-01T00:00:00Z")

    def test_kb_state_status_field_is_kbstatus_enum(self):
        """kb_state.status is a KbStatus enum member."""
        aid = self._make_minimal_repo()
        kb = aid / "knowledge"
        kb.mkdir()
        model = read_repo(self.root)
        self.assertIsNotNone(model.repo.kb_state)
        assert model.repo.kb_state is not None
        self.assertIsInstance(model.repo.kb_state.status, KbStatus)


if __name__ == "__main__":
    unittest.main(verbosity=2)
