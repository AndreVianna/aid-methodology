"""
test_security_hardening.py -- v2.1.0 security hardening regression tests.

Covers the reader-hardening fix set (Python <-> Node twins, lockstep):

  1. HIGH  git option injection via kb_baseline.branch: neutralized by
           --end-of-options in the git-log call underlying git_freshness_check
           (derivation.py _run_git_log / reader.mjs runGitLog).
  2. LOW   git option injection via a frontmatter approved_at_commit: value
           reaching merge-base --is-ancestor: neutralized by --end-of-options
           (derivation.py _run_merge_base_is_ancestor / reader.mjs
           _runMergeBaseIsAncestor).
  3. MEDIUM unbounded file read -> DoS: a >5 MB STATE.md is bounded-read (no
           OOM) and read_repo() still yields a well-formed model.
  4. Python<->Node parity: the bounded-read fix produces the identical
           bytes_read for the same oversized file in both twins.

Git-dependent tests are skipped when git is unavailable on PATH.
Node-parity tests are skipped when node is unavailable on PATH.

Node invocation note: this suite spawns Node via `pathToFileURL(...).href` +
dynamic `await import(...)` (NOT a raw absolute-path import specifier) --
on some Windows/Node combinations a bare absolute path ("C:/...") fed to
`node --input-type=module` as a static `import` specifier raises
ERR_UNSUPPORTED_ESM_URL_SCHEME; pathToFileURL sidesteps that entirely.

Python 3.11+ stdlib only. No third-party deps. No write / no LLM.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.derivation import (
    _run_merge_base_is_ancestor,
    derive_doc_freshness,
    git_freshness_check,
)
from dashboard.reader.io_bounds import MAX_READ_BYTES, read_bytes_bounded
from dashboard.reader.models import KbBaseline

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# Availability guards
# ---------------------------------------------------------------------------

def _is_git_available() -> bool:
    try:
        subprocess.run(["git", "--version"], capture_output=True, timeout=5)
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _is_node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


_GIT_AVAILABLE = _is_git_available()
_NODE_AVAILABLE = _is_node_available()

_GIT_ENV = {
    **os.environ,
    "GIT_AUTHOR_NAME": "test",
    "GIT_AUTHOR_EMAIL": "test@test.com",
    "GIT_COMMITTER_NAME": "test",
    "GIT_COMMITTER_EMAIL": "test@test.com",
}


def _git(repo: Path, args: list[str]) -> subprocess.CompletedProcess:
    result = subprocess.run(
        ["git", "-C", str(repo)] + args,
        capture_output=True, text=True, timeout=15, env=_GIT_ENV,
    )
    if result.returncode != 0:
        raise RuntimeError(f"git {args!r} failed: {result.stderr[:400]}")
    return result


# ---------------------------------------------------------------------------
# Node invocation helper (pathToFileURL workaround -- see module docstring)
# ---------------------------------------------------------------------------

_NODE_MODEL_SCRIPT = r"""
import {{ pathToFileURL }} from "url";
const readerUrl = pathToFileURL({reader_mjs!r}).href;
const {{ readRepo }} = await import(readerUrl);

const model = readRepo({repo_root!r});
process.stdout.write(JSON.stringify({{
  bytes_read: model.read.bytes_read,
  work_count: model.works.length,
}}) + "\n");
"""


def _run_node_model(repo_root: Path) -> dict:
    """Run Node readRepo(repo_root) via the pathToFileURL-safe invocation.

    Returns {bytes_read, work_count}. Raises RuntimeError on Node failure.
    """
    script = _NODE_MODEL_SCRIPT.format(
        reader_mjs=str(_READER_MJS), repo_root=str(repo_root),
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script, capture_output=True, text=True, timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node script failed (rc={result.returncode}): {result.stderr[:600]}")
    raw = result.stdout.strip()
    if not raw:
        raise RuntimeError(f"Node script produced empty stdout. stderr: {result.stderr[:400]}")
    return json.loads(raw)


# ---------------------------------------------------------------------------
# FIX-1 (HIGH): git option injection via kb_baseline.branch
# ---------------------------------------------------------------------------

@unittest.skipUnless(_GIT_AVAILABLE, "git not available on PATH")
class TestGitBranchInjectionNeutralized(unittest.TestCase):
    """kb_baseline.branch is read verbatim from an untrusted repo's settings.yml.

    A value shaped like a git OPTION (e.g. "--output=<path>") must never be
    able to create/truncate an arbitrary file via the underlying `git log`
    subprocess (derivation.py _run_git_log / reader.mjs runGitLog).
    """

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.repo = Path(self._tmp)
        subprocess.run(
            ["git", "init", "-q", "-b", "main", str(self.repo)],
            capture_output=True, env=_GIT_ENV, timeout=10,
        )
        _git(self.repo, ["commit", "-q", "--allow-empty", "-m", "init"])

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_malicious_branch_does_not_create_file_via_git_freshness_check(self):
        """Direct unit: git_freshness_check() with an option-shaped branch."""
        pwned = self.repo / "PWNED"
        baseline = KbBaseline(branch="--output=" + str(pwned), tip_date="2000-01-01T00:00:00Z")

        result = git_freshness_check(self.repo, baseline)

        self.assertFalse(
            pwned.exists(),
            "git option injection via kb_baseline.branch must NOT create a file",
        )
        # Neutralized: git treats the value as a (nonexistent) revision -> log
        # fails -> degrades to skip (never crashes, never a false "approved").
        self.assertEqual(result, "skip")

    def test_read_repo_end_to_end_does_not_create_file(self):
        """Full read_repo() path: settings.yml carries the malicious branch and
        the KB-approved gate is present so the git_freshness path actually fires
        (derive_kb_status step 4)."""
        pwned = self.repo / "PWNED_END_TO_END"
        aid = self.repo / ".aid"
        kb = aid / "knowledge"
        kb.mkdir(parents=True)
        (kb / "STATE.md").write_text(
            "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
            encoding="utf-8",
        )
        (kb / "kb.html").write_text("<html></html>", encoding="utf-8")
        (aid / "settings.yml").write_text(
            "project:\n  name: Test\n"
            "kb_baseline:\n"
            f"  branch: --output={pwned}\n"
            "  tip_date: 2000-01-01T00:00:00Z\n",
            encoding="utf-8",
        )

        model = read_repo(self.repo)

        self.assertFalse(
            pwned.exists(),
            "read_repo() must not create a file via an injected kb_baseline.branch",
        )
        self.assertIsNotNone(model.repo.kb_state)
        # Degrades to skip -> stays approved (never a crash, never a false outdated)
        self.assertEqual(model.repo.kb_state.status.value, "approved")

    @unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH")
    def test_node_read_repo_end_to_end_does_not_create_file(self):
        """Node twin of test_read_repo_end_to_end_does_not_create_file."""
        pwned = self.repo / "PWNED_NODE"
        aid = self.repo / ".aid"
        kb = aid / "knowledge"
        kb.mkdir(parents=True)
        (kb / "STATE.md").write_text(
            "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
            encoding="utf-8",
        )
        (kb / "kb.html").write_text("<html></html>", encoding="utf-8")
        (aid / "settings.yml").write_text(
            "project:\n  name: Test\n"
            "kb_baseline:\n"
            f"  branch: --output={pwned}\n"
            "  tip_date: 2000-01-01T00:00:00Z\n",
            encoding="utf-8",
        )

        _run_node_model(self.repo)

        self.assertFalse(
            pwned.exists(),
            "Node readRepo() must not create a file via an injected kb_baseline.branch",
        )


# ---------------------------------------------------------------------------
# FIX-2 (LOW): git option injection via approved_at_commit reaching merge-base
# ---------------------------------------------------------------------------

@unittest.skipUnless(_GIT_AVAILABLE, "git not available on PATH")
class TestMergeBaseInjectionNeutralized(unittest.TestCase):
    """approved_at_commit: (frontmatter) reaches merge-base --is-ancestor as the
    trailing 'baseline' commit-ish. An option-shaped value must not be parsed
    as a git option (derivation.py _run_merge_base_is_ancestor)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.repo = Path(self._tmp)
        subprocess.run(
            ["git", "init", "-q", "-b", "main", str(self.repo)],
            capture_output=True, env=_GIT_ENV, timeout=10,
        )
        (self.repo / "tracked.txt").write_text("hello\n", encoding="utf-8")
        _git(self.repo, ["add", "tracked.txt"])
        _git(self.repo, ["commit", "-q", "-m", "add tracked.txt"])
        self.c_src = _git(self.repo, ["rev-parse", "HEAD"]).stdout.strip()

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_malicious_baseline_does_not_create_file(self):
        """Direct unit: _run_merge_base_is_ancestor() with an option-shaped baseline."""
        pwned = self.repo / "PWNED_MB"
        baseline = "--output=" + str(pwned)

        result = _run_merge_base_is_ancestor(self.repo, self.c_src, baseline)

        self.assertFalse(
            pwned.exists(),
            "git option injection via approved_at_commit must NOT create a file",
        )
        # Neutralized: baseline is treated as a (bad) object name -> merge-base
        # exits non-zero/non-one -> degrades to unknown (never a false suspect).
        self.assertEqual(result, "unknown")

    def test_derive_doc_freshness_end_to_end_does_not_create_file(self):
        """Full derive_doc_freshness() path: a KB doc's approved_at_commit: is
        the malicious value; sources: points at the real tracked file so the
        per-source git-log lookup succeeds and merge-base is actually invoked."""
        pwned = self.repo / "PWNED_MB_END_TO_END"
        kb_dir = self.repo / ".aid" / "knowledge"
        kb_dir.mkdir(parents=True)
        (kb_dir / "doc.md").write_text(
            "---\n"
            f"approved_at_commit: --output={pwned}\n"
            "sources:\n"
            "  - tracked.txt\n"
            "---\n"
            "# Doc\n",
            encoding="utf-8",
        )

        results = derive_doc_freshness(kb_dir, self.repo)

        self.assertFalse(
            pwned.exists(),
            "derive_doc_freshness() must not create a file via a malicious "
            "approved_at_commit value",
        )
        self.assertEqual(len(results), 1)
        # Neutralized -> merge-base fails -> unknown (never a false suspect/current)
        self.assertEqual(results[0].verdict, "unknown")


# ---------------------------------------------------------------------------
# FIX-3 (MEDIUM): bounded read (5 MB cap)
# ---------------------------------------------------------------------------

class TestBoundedRead(unittest.TestCase):
    """read_bytes_bounded(): stat-then-bounded-read helper (io_bounds.py)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_small_file_reads_byte_identical_to_read_bytes(self):
        """Under-cap file: read_bytes_bounded() == path.read_bytes() (no drift)."""
        p = self.tmp / "small.md"
        content = b"# Small\n\nSome content.\n" * 100
        p.write_bytes(content)

        bounded = read_bytes_bounded(p)

        self.assertEqual(bounded, p.read_bytes())
        self.assertEqual(len(bounded), len(content))

    def test_oversized_file_is_capped_at_max_read_bytes(self):
        """Over-cap file: read_bytes_bounded() returns exactly MAX_READ_BYTES,
        never the full file (no OOM on a huge/malicious file)."""
        p = self.tmp / "huge.md"
        real_size = MAX_READ_BYTES + (2 * 1024 * 1024)  # 2 MB over the cap
        with p.open("wb") as f:
            f.write(b"#" * real_size)

        bounded = read_bytes_bounded(p)

        self.assertEqual(len(bounded), MAX_READ_BYTES)
        self.assertLess(len(bounded), real_size)

    def test_file_at_exact_cap_boundary_reads_whole_file(self):
        """A file exactly MAX_READ_BYTES in size is read whole (boundary case)."""
        p = self.tmp / "exact.md"
        with p.open("wb") as f:
            f.write(b"x" * MAX_READ_BYTES)

        bounded = read_bytes_bounded(p)

        self.assertEqual(len(bounded), MAX_READ_BYTES)


class TestReadRepoSurvivesOversizedStateMd(unittest.TestCase):
    """read_repo() end-to-end: a >5 MB STATE.md is bounded-read, never OOMs,
    and still yields a well-formed model (the parseable header sits inside the
    first 5 MB; only the padding tail is truncated)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.root = Path(self._tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _make_oversized_work(self) -> tuple[Path, int]:
        aid = self.root / ".aid"
        work_dir = aid / "works" / "work-001-huge"
        work_dir.mkdir(parents=True)
        header = (
            "# Work State -- work-001-huge\n\n"
            "## Pipeline Status\n\n"
            "- **Lifecycle:** Running\n"
            "- **Phase:** Execute\n"
            "- **Active Skill:** aid-execute\n"
            "- **Updated:** 2026-06-10T12:00:00Z\n"
            "- **Pause Reason:** --\n"
            "- **Block Reason:** --\n"
            "- **Block Artifact:** --\n\n"
            "## Tasks Status\n\n"
            "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |\n"
            "|---|------|------|------|--------|--------|---------|-------|\n"
            "| 001 | task-001 | IMPLEMENT | delivery-001 | In Progress | -- | -- | first |\n\n"
        )
        # Pad well past the 5 MB cap; the padding is inert prose (no ## headers),
        # so truncating it never disturbs the meaningful header parsed above.
        padding = "x" * (MAX_READ_BYTES + (2 * 1024 * 1024))
        content = header + padding
        state_path = work_dir / "STATE.md"
        state_path.write_text(content, encoding="utf-8")
        return state_path, len(content.encode("utf-8"))

    def test_model_produced_without_oom_and_bytes_read_is_capped(self):
        state_path, real_size = self._make_oversized_work()
        self.assertGreater(real_size, MAX_READ_BYTES, "fixture must exceed the cap")

        model = read_repo(self.root)

        self.assertEqual(len(model.works), 1)
        work = model.works[0]
        # The header (within the first 5 MB) still parses correctly.
        self.assertEqual(work.lifecycle.value, "Running")
        self.assertEqual(len(work.tasks), 1)
        self.assertEqual(work.tasks[0].task_id, "task-001")
        # bytes_read reflects the BOUNDED read, not the true on-disk size.
        self.assertLess(model.read.bytes_read, real_size)
        self.assertGreaterEqual(model.read.bytes_read, MAX_READ_BYTES)

    @unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH")
    def test_node_parity_bytes_read_identical(self):
        """Python<->Node parity: the SAME oversized STATE.md yields the SAME
        bytes_read in both twins (bounded-read behavior is symmetric)."""
        self._make_oversized_work()

        py_model = read_repo(self.root)
        node_model = _run_node_model(self.root)

        self.assertEqual(node_model["work_count"], 1)
        self.assertEqual(
            py_model.read.bytes_read, node_model["bytes_read"],
            "Python and Node must cap the oversized STATE.md read identically",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
