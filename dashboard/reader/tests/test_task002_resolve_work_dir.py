"""
test_task002_resolve_work_dir.py -- Verification fixture for task-002
(feature-001-write-infrastructure, delivery-001): worktree-aware
resolve_work_dir(served_root, work_id) -> Path | None resolver (WT-1).

Validates:
  1. Resolves to the on-disk work directory when exactly one worktree holds work_id.
  2. Returns None when no worktree of the served repo holds work_id (-> caller 404s).
  3. A worktree-isolated pipeline resolves to ITS worktree copy -- never a
     reconstructed <served-root>/.aid/works/<work_id> path (WT-1 core invariant).
  4. Same winner rule as _reconcile_same_work step 2: newest `updated` wins.
  5. Tie-break: branch_label lexical sort, "main" sorting first.
  6. SD-3 degradation: git-absent / non-git served root -> main-root-only,
     matching the reader (uses the REAL enumerate_worktree_roots, not mocked).
  7. A work directory with no STATE.md still counts as a candidate (presence of
     the directory is the sole inclusion test -- not STATE.md presence/parseability).
  8. Never throws on malformed STATE.md.
  9. Accepts either the repo root or a path ending in ".aid" (read_repo convention).
  10. Returns a pathlib.Path (or None), never a string / other type.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

# Ensure the repo root is on sys.path so we can import dashboard.*
_REPO_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.reader import resolve_work_dir


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
"""


def _state_text(lifecycle: str = "Running", updated: str = "2026-06-10T12:00:00Z") -> str:
    return _STATE_TEMPLATE.format(lifecycle=lifecycle, updated=updated)


def _write_work(aid_dir: Path, work_id: str, updated: str = "2026-06-10T12:00:00Z",
                 with_state: bool = True) -> Path:
    work_dir = aid_dir / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    if with_state:
        (work_dir / "STATE.md").write_text(_state_text(updated=updated), encoding="utf-8")
    return work_dir


class _TempCase(unittest.TestCase):
    """Base class: provides a fresh temp dir per test."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Test 1: single worktree holds work_id
# ---------------------------------------------------------------------------

class TestResolveSingleCopy(_TempCase):
    def test_resolves_single_worktree_copy(self):
        root, aid = _make_repo(self.tmp)
        work_dir = _write_work(aid, "work-001-solo")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(root, "work-001-solo")

        self.assertEqual(result, work_dir)

    def test_returns_path_instance(self):
        root, aid = _make_repo(self.tmp)
        _write_work(aid, "work-001-typed")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(root, "work-001-typed")

        self.assertIsInstance(result, Path)

    def test_accepts_dot_aid_suffix_root(self):
        """Passing <root>/.aid behaves the same as passing <root> (read_repo convention)."""
        root, aid = _make_repo(self.tmp)
        work_dir = _write_work(aid, "work-001-dotaid")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(aid, "work-001-dotaid")

        self.assertEqual(result, work_dir)


# ---------------------------------------------------------------------------
# Test 2: no worktree holds work_id -> None (caller 404s)
# ---------------------------------------------------------------------------

class TestResolveNotFound(_TempCase):
    def test_returns_none_when_no_worktree_holds_work_id(self):
        root, aid = _make_repo(self.tmp)
        _write_work(aid, "work-001-exists")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(root, "work-999-does-not-exist")

        self.assertIsNone(result)

    def test_returns_none_when_no_aid_dir_at_all(self):
        root = self.tmp  # no .aid/ created at all
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", root / ".aid")],
        ):
            result = resolve_work_dir(root, "work-001-anything")

        self.assertIsNone(result)


# ---------------------------------------------------------------------------
# Test 3: WT-1 -- worktree-isolated pipeline resolves to ITS copy, never a
# reconstructed <served-root>/.aid/works/<work_id> path.
# ---------------------------------------------------------------------------

class TestWorktreeIsolatedResolution(_TempCase):
    def test_worktree_only_copy_resolves_to_worktree_path_not_served_root(self):
        """A pipeline that lives ONLY under a worktree (never under the served
        root's own .aid/works/) resolves to the worktree copy -- the served-root
        reconstruction '<served-root>/.aid/works/<work_id>' does not even exist
        on disk, proving the resolver did not fabricate it."""
        root, aid = _make_repo(self.tmp)
        work_id = "work-017-cli-improvements"

        # Simulate .claude/worktrees/<wt>/.aid/works/<work_id> -- work-017's own topology.
        wt_root = self.tmp / ".claude" / "worktrees" / "work-017-cli-improvements"
        wt_aid = wt_root / ".aid"
        wt_work_dir = _write_work(wt_aid, work_id, updated="2026-07-17T00:00:00Z")

        reconstructed_served_path = aid / "works" / work_id
        self.assertFalse(
            reconstructed_served_path.exists(),
            "fixture sanity: the served-root reconstruction must NOT exist on disk",
        )

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid), ("work-017-cli-improvements", wt_aid)],
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, wt_work_dir)
        self.assertNotEqual(result, reconstructed_served_path)


# ---------------------------------------------------------------------------
# Test 4: same winner rule as _reconcile_same_work step 2 -- newest updated wins
# ---------------------------------------------------------------------------

class TestWinnerRuleNewestUpdated(_TempCase):
    def test_newest_updated_wins_across_worktrees(self):
        root, aid = _make_repo(self.tmp)
        work_id = "work-002-multi"
        main_dir = _write_work(aid, work_id, updated="2026-06-10T09:00:00Z")

        wt_aid = self.tmp / "wt" / ".aid"
        wt_dir = _write_work(wt_aid, work_id, updated="2026-06-10T12:00:00Z")  # NEWER

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid), ("feat", wt_aid)],
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, wt_dir)
        self.assertNotEqual(result, main_dir)

    def test_older_timestamp_does_not_win(self):
        root, aid = _make_repo(self.tmp)
        work_id = "work-002-older"
        main_dir = _write_work(aid, work_id, updated="2026-06-10T00:00:00Z")  # NEWER

        wt_aid = self.tmp / "wt" / ".aid"
        _write_work(wt_aid, work_id, updated="2026-06-09T00:00:00Z")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid), ("feat", wt_aid)],
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, main_dir)


# ---------------------------------------------------------------------------
# Test 5: tie-break -- branch_label lexical sort, "main" first
# ---------------------------------------------------------------------------

class TestWinnerRuleTieBreak(_TempCase):
    def test_main_wins_on_tie(self):
        root, aid = _make_repo(self.tmp)
        work_id = "work-003-tie"
        main_dir = _write_work(aid, work_id, updated="2026-06-10T12:00:00Z")

        wt_aid = self.tmp / "wt-feat" / ".aid"
        _write_work(wt_aid, work_id, updated="2026-06-10T12:00:00Z")  # SAME timestamp

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("feat", wt_aid), ("main", aid)],  # main NOT first in input
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, main_dir)

    def test_lexical_tie_break_when_no_main(self):
        root, aid = _make_repo(self.tmp)
        work_id = "work-003-lex"

        wt_a_aid = self.tmp / "wt-zzz" / ".aid"
        zzz_dir = _write_work(wt_a_aid, work_id, updated="2026-06-10T12:00:00Z")
        wt_b_aid = self.tmp / "wt-aaa" / ".aid"
        aaa_dir = _write_work(wt_b_aid, work_id, updated="2026-06-10T12:00:00Z")

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("zzz-branch", wt_a_aid), ("aaa-branch", wt_b_aid)],
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, aaa_dir)
        self.assertNotEqual(result, zzz_dir)

    def test_both_none_updated_main_wins(self):
        root, aid = _make_repo(self.tmp)
        work_id = "work-003-nots"
        main_dir = _write_work(aid, work_id, with_state=False)  # no STATE.md -> updated=None

        wt_aid = self.tmp / "wt" / ".aid"
        _write_work(wt_aid, work_id, with_state=False)

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("feat", wt_aid), ("main", aid)],
        ):
            result = resolve_work_dir(root, work_id)

        self.assertEqual(result, main_dir)


# ---------------------------------------------------------------------------
# Test 6: SD-3 degradation -- git-absent / non-git served root -> main-root-only
# (uses the REAL enumerate_worktree_roots, not mocked, on a genuinely non-git dir)
# ---------------------------------------------------------------------------

class TestSD3Degradation(_TempCase):
    def test_non_git_root_still_resolves_via_main_root_only_fallback(self):
        """A served root with no .git at all must still resolve a work_id present
        under <root>/.aid/works/<id> -- enumerate_worktree_roots degrades to
        main-root-only (SD-3), and resolve_work_dir must use that fallback list,
        matching the reader's own degradation posture."""
        root, aid = _make_repo(self.tmp)
        work_dir = _write_work(aid, "work-004-nongit")

        self.assertFalse((root / ".git").exists(), "fixture sanity: root must not be a git repo")

        # No mocking here: exercises the REAL locator.enumerate_worktree_roots.
        result = resolve_work_dir(root, "work-004-nongit")

        # resolve_work_dir resolves served_root internally (Path.resolve()); compare
        # against the same normalization (Windows may 8.3-shorten a temp-dir segment).
        self.assertEqual(result, work_dir.resolve())


# ---------------------------------------------------------------------------
# Test 7: presence-only inclusion -- missing/malformed STATE.md never excludes
# a candidate and never throws.
# ---------------------------------------------------------------------------

class TestNeverThrows(_TempCase):
    def test_missing_state_md_still_resolves(self):
        root, aid = _make_repo(self.tmp)
        work_dir = _write_work(aid, "work-005-nostate", with_state=False)

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(root, "work-005-nostate")

        self.assertEqual(result, work_dir)

    def test_malformed_state_md_does_not_throw(self):
        root, aid = _make_repo(self.tmp)
        work_dir = aid / "works" / "work-005-malformed"
        work_dir.mkdir(parents=True, exist_ok=True)
        (work_dir / "STATE.md").write_text("## Pipeline Sta", encoding="utf-8")  # truncated

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            result = resolve_work_dir(root, "work-005-malformed")

        # Never throws; still resolves via presence (updated may be None/derived).
        self.assertEqual(result, work_dir)

    def test_empty_worktree_list_returns_none(self):
        root, _aid = _make_repo(self.tmp)
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[],
        ):
            result = resolve_work_dir(root, "work-006-anything")

        self.assertIsNone(result)


if __name__ == "__main__":
    unittest.main(verbosity=2)
