"""
test_task044_freshness_parity.py -- task-044: reader-parity suite for per-doc freshness.

FR-6 parity gate: Python derive_doc_freshness() and Node deriveDocFreshness() MUST produce
byte-identical doc_freshness arrays (and suspect_count) for the same repo state.

Test matrix (one doc per verdict class, as required by task-044 AC):
  - current:  sources: [some/path] that was last-changed at-or-before approved_at_commit
  - suspect:  sources: [some/path] that was last-changed AFTER approved_at_commit
              (and therefore appears in suspect_sources)
  - url-unknown: sources: [https://example.com/ref] -- URL source -> unknown
  - pre-migration-unknown: no approved_at_commit field -> unknown (pre-migration doc)

Isolation discipline (AC load-bearing):
  - HOME pinned to a throwaway dir before any reader run
  - Real-HOME .aid canary snapshot before/after: assert no .aid appeared
  - Parity fixture git repo lives in mktemp -d scratch (via tempfile.mkdtemp)
  - trap-equivalent: setUp/tearDown ensure cleanup even on assertion failure
  - Never mutates the AID repo's own git history or committed fixtures
  - Explicit fixture paths passed to both readers

Python 3.11+ stdlib only. No third-party deps. No write / no LLM. ASCII-only source.
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

# Repo root: this file is at dashboard/reader/tests/test_task044_freshness_parity.py
_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.derivation import derive_doc_freshness


# ---------------------------------------------------------------------------
# Availability guards
# ---------------------------------------------------------------------------

def _is_git_available() -> bool:
    """Return True if git is available on PATH."""
    try:
        subprocess.run(
            ["git", "--version"],
            capture_output=True,
            timeout=5,
        )
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _is_node_available() -> bool:
    """Return True if node is available on PATH."""
    try:
        r = subprocess.run(
            ["node", "--version"],
            capture_output=True,
            timeout=5,
        )
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


_GIT_AVAILABLE = _is_git_available()
_NODE_AVAILABLE = _is_node_available()


# ---------------------------------------------------------------------------
# Git fixture builder
# ---------------------------------------------------------------------------

_GIT_ENV_BASE = {
    "GIT_AUTHOR_NAME": "test",
    "GIT_AUTHOR_EMAIL": "test@test.com",
    "GIT_COMMITTER_NAME": "test",
    "GIT_COMMITTER_EMAIL": "test@test.com",
}

# Frozen commit dates (deterministic across runs).
# BASELINE_DATE is used as approved_at_commit for "current" and "suspect" docs.
# SOURCE_BEFORE is the date for the "current" source commit (before baseline).
# SOURCE_AFTER is the date for the "suspect" source commit (after baseline).
_DATE_BASELINE = "2026-01-10T12:00:00+00:00"
_DATE_SOURCE_BEFORE = "2026-01-01T00:00:00+00:00"  # before baseline -> current
_DATE_SOURCE_AFTER = "2026-01-20T00:00:00+00:00"   # after baseline -> suspect


def _git(repo: Path, args: list[str], env_extra: dict | None = None) -> subprocess.CompletedProcess:
    """Run a git command in repo, raising on nonzero exit."""
    env = {**os.environ, **_GIT_ENV_BASE}
    if env_extra:
        env.update(env_extra)
    result = subprocess.run(
        ["git", "-C", str(repo)] + args,
        capture_output=True,
        text=True,
        timeout=15,
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"git {args!r} failed (rc={result.returncode}): {result.stderr[:400]}"
        )
    return result


def _commit(repo: Path, message: str, frozen_date: str) -> str:
    """Make a commit with a frozen date. Returns the commit SHA."""
    env_extra = {
        "GIT_AUTHOR_DATE": frozen_date,
        "GIT_COMMITTER_DATE": frozen_date,
    }
    _git(repo, ["commit", "-m", message, "--allow-empty"], env_extra=env_extra)
    sha = _git(repo, ["rev-parse", "HEAD"]).stdout.strip()
    return sha


def _write_and_stage(repo: Path, rel_path: str, content: str, frozen_date: str) -> str:
    """Write a file, stage it, commit, return commit SHA."""
    target = repo / rel_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    _git(repo, ["add", rel_path])
    return _commit(repo, f"add {rel_path}", frozen_date)


def _write_and_stage_only(repo: Path, rel_path: str, content: str) -> None:
    """Write a file and stage it (do not commit yet)."""
    target = repo / rel_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    _git(repo, ["add", rel_path])


def build_parity_fixture(repo: Path) -> dict:
    """Build the parity fixture git repo and KB docs.

    Returns a dict with commit SHAs for verification:
      baseline_sha: commit SHA used as approved_at_commit for current/suspect docs
      source_before_sha: SHA of the "current" source's last-changed commit
      source_after_sha: SHA of the "suspect" source's last-changed commit

    Repo layout (relative to repo/):
      .aid/knowledge/           -- KB docs (the kb_dir)
        current-doc.md          -- verdict: current (source changed before baseline)
        suspect-doc.md          -- verdict: suspect (source changed after baseline)
        url-unknown-doc.md      -- verdict: unknown (URL source only)
        premigration-doc.md     -- verdict: unknown (no approved_at_commit)
      sources/
        stable-source.txt       -- the "current" source file
        drifted-source.txt      -- the "suspect" source file
    """
    env = {**os.environ, **_GIT_ENV_BASE}

    # Init
    subprocess.run(
        ["git", "init", "-b", "master", str(repo)],
        capture_output=True,
        env=env,
        timeout=10,
        check=True,
    )

    kb_dir = repo / ".aid" / "knowledge"
    kb_dir.mkdir(parents=True)
    sources_dir = repo / "sources"
    sources_dir.mkdir(parents=True)

    # Commit 1 (DATE_SOURCE_BEFORE): add the "stable" source file that will stay current.
    # This commit is BEFORE the baseline -- so it will be an ancestor of approved_at_commit.
    _write_and_stage_only(repo, "sources/stable-source.txt", "stable content v1\n")
    # Also add a placeholder KB dir entry to init
    _write_and_stage_only(repo, ".aid/knowledge/.gitkeep", "")
    env_c1 = {**_GIT_ENV_BASE,
               "GIT_AUTHOR_DATE": _DATE_SOURCE_BEFORE,
               "GIT_COMMITTER_DATE": _DATE_SOURCE_BEFORE}
    subprocess.run(
        ["git", "-C", str(repo), "commit", "-m", "initial: stable source"],
        capture_output=True, text=True, timeout=10,
        env={**os.environ, **env_c1}, check=True,
    )
    source_before_sha = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        capture_output=True, text=True, timeout=5, env={**os.environ, **_GIT_ENV_BASE},
    ).stdout.strip()

    # Commit 2 (DATE_BASELINE): the KB docs + drifted source NOT yet added.
    # We use this SHA as the approved_at_commit for current and suspect docs.
    _write_and_stage_only(
        repo, ".aid/knowledge/current-doc.md",
        "---\n"
        "kb-category: primary\n"
        "approved_at_commit: PLACEHOLDER_BASELINE\n"
        "sources:\n"
        "  - sources/stable-source.txt\n"
        "---\n"
        "# Current Doc\n\nThis doc should be current.\n",
    )
    _write_and_stage_only(
        repo, ".aid/knowledge/suspect-doc.md",
        "---\n"
        "kb-category: primary\n"
        "approved_at_commit: PLACEHOLDER_BASELINE\n"
        "sources:\n"
        "  - sources/drifted-source.txt\n"
        "---\n"
        "# Suspect Doc\n\nThis doc should be suspect.\n",
    )
    _write_and_stage_only(
        repo, ".aid/knowledge/url-unknown-doc.md",
        "---\n"
        "kb-category: primary\n"
        "approved_at_commit: PLACEHOLDER_BASELINE\n"
        "sources:\n"
        "  - https://example.com/reference\n"
        "---\n"
        "# URL Unknown Doc\n\nURL source only -- unknown.\n",
    )
    _write_and_stage_only(
        repo, ".aid/knowledge/premigration-doc.md",
        "---\n"
        "kb-category: primary\n"
        "sources:\n"
        "  - sources/stable-source.txt\n"
        "---\n"
        "# Pre-migration Doc\n\nNo approved_at_commit -- unknown.\n",
    )
    env_c2 = {**_GIT_ENV_BASE,
               "GIT_AUTHOR_DATE": _DATE_BASELINE,
               "GIT_COMMITTER_DATE": _DATE_BASELINE}
    subprocess.run(
        ["git", "-C", str(repo), "commit", "-m", "baseline: KB docs"],
        capture_output=True, text=True, timeout=10,
        env={**os.environ, **env_c2}, check=True,
    )
    baseline_sha = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        capture_output=True, text=True, timeout=5, env={**os.environ, **_GIT_ENV_BASE},
    ).stdout.strip()

    # Commit 3 (DATE_SOURCE_AFTER): add the "drifted" source file that was NOT there
    # at the baseline. This commit is AFTER the baseline -- so it is NOT an ancestor
    # of baseline_sha, meaning the suspect-doc's source is "suspect".
    _write_and_stage_only(repo, "sources/drifted-source.txt", "drifted content v1\n")
    env_c3 = {**_GIT_ENV_BASE,
               "GIT_AUTHOR_DATE": _DATE_SOURCE_AFTER,
               "GIT_COMMITTER_DATE": _DATE_SOURCE_AFTER}
    subprocess.run(
        ["git", "-C", str(repo), "commit", "-m", "post-baseline: drifted source"],
        capture_output=True, text=True, timeout=10,
        env={**os.environ, **env_c3}, check=True,
    )
    source_after_sha = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        capture_output=True, text=True, timeout=5, env={**os.environ, **_GIT_ENV_BASE},
    ).stdout.strip()

    # Now rewrite the KB docs with the real baseline_sha (not PLACEHOLDER_BASELINE).
    # We do this in-place (not committed to git) because the readers read from the
    # working tree. The frontmatter is in the working tree; git history is for
    # the sources -- not the docs themselves. The docs are NOT staged/committed again
    # so git log for the kb-doc paths still points to commit 2 (the baseline commit).
    for doc_name in ("current-doc.md", "suspect-doc.md", "url-unknown-doc.md"):
        doc_path = kb_dir / doc_name
        doc_content = doc_path.read_text(encoding="utf-8")
        doc_content = doc_content.replace("PLACEHOLDER_BASELINE", baseline_sha)
        doc_path.write_text(doc_content, encoding="utf-8")

    return {
        "baseline_sha": baseline_sha,
        "source_before_sha": source_before_sha,
        "source_after_sha": source_after_sha,
        "kb_dir": kb_dir,
        "repo_root": repo,
    }


# ---------------------------------------------------------------------------
# Node invocation helper
# ---------------------------------------------------------------------------

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

# Node script template: calls readRepo(repoRoot) and extracts doc_freshness from kb_state.
# deriveDocFreshness is an internal function in reader.mjs (not exported directly).
# readRepo() is exported and returns model.repo.kb_state which contains doc_freshness
# and suspect_count (added by task-042, wired in _buildKbStateRef).
_NODE_SCRIPT_TEMPLATE = r"""
import {{ readRepo }} from {reader_mjs!r};

const repoRoot = {repo_root!r};

const model = readRepo(repoRoot);
const kbState = model && model.repo && model.repo.kb_state ? model.repo.kb_state : null;
const docFreshness = kbState && Array.isArray(kbState.doc_freshness) ? kbState.doc_freshness : [];
const suspectCount = typeof (kbState && kbState.suspect_count) === 'number' ? kbState.suspect_count : 0;

process.stdout.write(JSON.stringify({{
  doc_freshness: docFreshness,
  suspect_count: suspectCount
}}) + '\n');
"""


def _run_node_freshness(kb_dir: Path, repo_root: Path, pinned_home: Path) -> dict:
    """Run Node deriveDocFreshness via readRepo() and node --input-type=module.

    Calls readRepo(repo_root) which internally calls deriveDocFreshness and
    attaches the result to model.repo.kb_state.doc_freshness / suspect_count.

    Returns {doc_freshness: [...], suspect_count: int}.
    Raises RuntimeError on Node failure.
    """
    # kb_dir is not passed to the Node script directly (readRepo derives it from repoRoot)
    # but we keep it in the signature for symmetry with the Python interface.
    _ = kb_dir  # unused; Node uses repo_root through readRepo
    script = _NODE_SCRIPT_TEMPLATE.format(
        reader_mjs=str(_READER_MJS),
        repo_root=str(repo_root),
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=30,
        env={**os.environ, "HOME": str(pinned_home)},
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Node script failed (rc={result.returncode}): {result.stderr[:600]}"
        )
    raw = result.stdout.strip()
    if not raw:
        raise RuntimeError(f"Node script produced empty stdout. stderr: {result.stderr[:400]}")
    return json.loads(raw)


# ---------------------------------------------------------------------------
# Parity test
# ---------------------------------------------------------------------------

@unittest.skipUnless(_GIT_AVAILABLE, "git not available on PATH")
@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH")
class TestDocFreshnessParity(unittest.TestCase):
    """FR-6 byte-parity gate: Python derive_doc_freshness === Node deriveDocFreshness.

    Builds a scripted git fixture KB with one doc of each verdict class, runs
    both readers over it, and asserts byte-identical doc_freshness + suspect_count.

    Covers task-044 AC:
      AC-1: doc_freshness + suspect_count are part of the Python-vs-Node diff
      AC-2: fixture has current, suspect (with suspect_sources), URL-unknown, pre-migration-unknown
      AC-3: byte-identical arrays + suspect_count; path-sorted entry ordering
      AC-4: HOME-pinned; real-HOME .aid canary; fixture in mktemp scratch; AID git never mutated
      AC-5: deterministic clean setup/teardown; FR-6 parity gate exercised
    """

    def setUp(self):
        """Set up isolated temp dirs and snapshot real-HOME .aid canary."""
        self._scratch = tempfile.mkdtemp(prefix="aid-parity-t044-")
        self._scratch_path = Path(self._scratch)

        # HOME pinning: use a throwaway dir so reader git calls cannot bleed into
        # the developer's real home.
        self._pinned_home = self._scratch_path / "pinned-home"
        self._pinned_home.mkdir()

        # Real-HOME .aid canary: snapshot whether .aid exists BEFORE the test.
        real_home = Path.home()
        self._real_home_aid = real_home / ".aid"
        self._canary_aid_existed_before = self._real_home_aid.exists()

        # Parity fixture git repo lives entirely inside _scratch.
        self._repo = self._scratch_path / "parity-fixture-repo"
        self._repo.mkdir()

        # Build the fixture
        self._fixture = build_parity_fixture(self._repo)

    def tearDown(self):
        """Verify real-HOME .aid canary and clean up scratch."""
        # Canary: .aid must not have appeared in real HOME during the test.
        # If it did not exist before, it must not exist after.
        if not self._canary_aid_existed_before:
            self.assertFalse(
                self._real_home_aid.exists(),
                f"Isolation violation: .aid appeared in real HOME={Path.home()} "
                "during the test. HOME pinning may have failed.",
            )

        shutil.rmtree(self._scratch, ignore_errors=True)

    # ------------------------------------------------------------------
    # Core parity assertion
    # ------------------------------------------------------------------

    def test_parity_byte_identical_doc_freshness(self):
        """Python and Node produce byte-identical doc_freshness for the fixture KB.

        This is the FR-6 parity gate (task-044 AC-1 + AC-3).
        """
        kb_dir = self._fixture["kb_dir"]
        repo_root = self._fixture["repo_root"]

        # Run Python
        py_freshness = derive_doc_freshness(kb_dir, repo_root)

        # Serialize Python result as JSON (the canonical comparison form)
        py_list = [
            {
                "doc": d.doc,
                "verdict": d.verdict,
                "suspect_sources": d.suspect_sources,
            }
            for d in py_freshness
        ]
        py_suspect_count = sum(1 for d in py_freshness if d.verdict == "suspect")

        # Run Node
        node_data = _run_node_freshness(kb_dir, repo_root, self._pinned_home)
        node_list = node_data["doc_freshness"]
        node_suspect_count = node_data["suspect_count"]

        # Serialize both to canonical JSON for byte-identical comparison
        py_json = json.dumps(py_list, separators=(",", ":"), ensure_ascii=True, sort_keys=False)
        node_json = json.dumps(node_list, separators=(",", ":"), ensure_ascii=True, sort_keys=False)

        self.assertEqual(
            py_json,
            node_json,
            f"doc_freshness NOT byte-identical:\n  Python: {py_json}\n  Node:   {node_json}",
        )
        self.assertEqual(
            py_suspect_count,
            node_suspect_count,
            f"suspect_count differs: Python={py_suspect_count} Node={node_suspect_count}",
        )

    # ------------------------------------------------------------------
    # Per-verdict assertions (Python and Node independently)
    # ------------------------------------------------------------------

    def _py_freshness_map(self) -> dict:
        """Run Python derive_doc_freshness and return {doc_name: {verdict, suspect_sources}}."""
        kb_dir = self._fixture["kb_dir"]
        repo_root = self._fixture["repo_root"]
        results = derive_doc_freshness(kb_dir, repo_root)
        return {d.doc: {"verdict": d.verdict, "suspect_sources": d.suspect_sources}
                for d in results}

    def _node_freshness_map(self) -> dict:
        """Run Node deriveDocFreshness and return {doc_name: {verdict, suspect_sources}}."""
        kb_dir = self._fixture["kb_dir"]
        repo_root = self._fixture["repo_root"]
        data = _run_node_freshness(kb_dir, repo_root, self._pinned_home)
        return {d["doc"]: {"verdict": d["verdict"], "suspect_sources": d["suspect_sources"]}
                for d in data["doc_freshness"]}

    def _check_all_verdicts(self, fm: dict, runtime: str):
        """Assert all four verdicts are correct for one runtime's result."""
        # current-doc: source stable-source.txt was last-changed BEFORE baseline
        self.assertIn("current-doc.md", fm, f"{runtime}: current-doc.md not in doc_freshness")
        self.assertEqual(
            fm["current-doc.md"]["verdict"], "current",
            f"{runtime}: current-doc.md verdict must be 'current'; got {fm['current-doc.md']['verdict']}",
        )
        self.assertEqual(
            fm["current-doc.md"]["suspect_sources"], [],
            f"{runtime}: current-doc.md must have empty suspect_sources",
        )

        # suspect-doc: source drifted-source.txt was last-changed AFTER baseline
        self.assertIn("suspect-doc.md", fm, f"{runtime}: suspect-doc.md not in doc_freshness")
        self.assertEqual(
            fm["suspect-doc.md"]["verdict"], "suspect",
            f"{runtime}: suspect-doc.md verdict must be 'suspect'; got {fm['suspect-doc.md']['verdict']}",
        )
        self.assertIn(
            "sources/drifted-source.txt",
            fm["suspect-doc.md"]["suspect_sources"],
            f"{runtime}: drifted-source.txt must appear in suspect_sources for suspect-doc.md; "
            f"got {fm['suspect-doc.md']['suspect_sources']}",
        )

        # url-unknown-doc: only URL source -> unknown
        self.assertIn("url-unknown-doc.md", fm, f"{runtime}: url-unknown-doc.md not in doc_freshness")
        self.assertEqual(
            fm["url-unknown-doc.md"]["verdict"], "unknown",
            f"{runtime}: url-unknown-doc.md verdict must be 'unknown'; "
            f"got {fm['url-unknown-doc.md']['verdict']}",
        )
        self.assertEqual(
            fm["url-unknown-doc.md"]["suspect_sources"], [],
            f"{runtime}: url-unknown-doc.md must have empty suspect_sources (URL sources excluded)",
        )

        # premigration-doc: no approved_at_commit -> unknown (never suspect)
        self.assertIn("premigration-doc.md", fm, f"{runtime}: premigration-doc.md not in doc_freshness")
        self.assertEqual(
            fm["premigration-doc.md"]["verdict"], "unknown",
            f"{runtime}: premigration-doc.md verdict must be 'unknown'; "
            f"got {fm['premigration-doc.md']['verdict']}",
        )

    def test_python_current_verdict(self):
        """Python: current-doc.md -> verdict=current, suspect_sources=[]."""
        fm = self._py_freshness_map()
        self.assertEqual(fm.get("current-doc.md", {}).get("verdict"), "current",
                         f"Python current-doc.md must be 'current'; got {fm.get('current-doc.md')}")

    def test_python_suspect_verdict_with_named_source(self):
        """Python: suspect-doc.md -> verdict=suspect, drifted-source.txt in suspect_sources."""
        fm = self._py_freshness_map()
        entry = fm.get("suspect-doc.md", {})
        self.assertEqual(entry.get("verdict"), "suspect",
                         f"Python suspect-doc.md must be 'suspect'; got {entry}")
        self.assertIn("sources/drifted-source.txt", entry.get("suspect_sources", []),
                      f"Python: drifted-source.txt must be in suspect_sources; got {entry}")

    def test_python_url_source_unknown(self):
        """Python: url-unknown-doc.md -> verdict=unknown (URL source cannot be git-logged)."""
        fm = self._py_freshness_map()
        entry = fm.get("url-unknown-doc.md", {})
        self.assertEqual(entry.get("verdict"), "unknown",
                         f"Python url-unknown-doc.md must be 'unknown'; got {entry}")
        self.assertEqual(entry.get("suspect_sources", []), [],
                         "Python: URL source must not appear in suspect_sources")

    def test_python_premigration_unknown(self):
        """Python: premigration-doc.md (no approved_at_commit) -> verdict=unknown."""
        fm = self._py_freshness_map()
        entry = fm.get("premigration-doc.md", {})
        self.assertEqual(entry.get("verdict"), "unknown",
                         f"Python premigration-doc.md must be 'unknown'; got {entry}")

    def test_node_current_verdict(self):
        """Node: current-doc.md -> verdict=current, suspect_sources=[]."""
        fm = self._node_freshness_map()
        self.assertEqual(fm.get("current-doc.md", {}).get("verdict"), "current",
                         f"Node current-doc.md must be 'current'; got {fm.get('current-doc.md')}")

    def test_node_suspect_verdict_with_named_source(self):
        """Node: suspect-doc.md -> verdict=suspect, drifted-source.txt in suspect_sources."""
        fm = self._node_freshness_map()
        entry = fm.get("suspect-doc.md", {})
        self.assertEqual(entry.get("verdict"), "suspect",
                         f"Node suspect-doc.md must be 'suspect'; got {entry}")
        self.assertIn("sources/drifted-source.txt", entry.get("suspect_sources", []),
                      f"Node: drifted-source.txt must be in suspect_sources; got {entry}")

    def test_node_url_source_unknown(self):
        """Node: url-unknown-doc.md -> verdict=unknown (URL source cannot be git-logged)."""
        fm = self._node_freshness_map()
        entry = fm.get("url-unknown-doc.md", {})
        self.assertEqual(entry.get("verdict"), "unknown",
                         f"Node url-unknown-doc.md must be 'unknown'; got {entry}")
        self.assertEqual(entry.get("suspect_sources", []), [],
                         "Node: URL source must not appear in suspect_sources")

    def test_node_premigration_unknown(self):
        """Node: premigration-doc.md (no approved_at_commit) -> verdict=unknown."""
        fm = self._node_freshness_map()
        entry = fm.get("premigration-doc.md", {})
        self.assertEqual(entry.get("verdict"), "unknown",
                         f"Node premigration-doc.md must be 'unknown'; got {entry}")

    # ------------------------------------------------------------------
    # Ordering assertion: path-sorted, identical between twins
    # ------------------------------------------------------------------

    def test_doc_freshness_entry_order_identical(self):
        """Both readers emit doc_freshness entries in identical path-sorted order (AC-3)."""
        kb_dir = self._fixture["kb_dir"]
        repo_root = self._fixture["repo_root"]

        py_results = derive_doc_freshness(kb_dir, repo_root)
        py_order = [d.doc for d in py_results]

        node_data = _run_node_freshness(kb_dir, repo_root, self._pinned_home)
        node_order = [d["doc"] for d in node_data["doc_freshness"]]

        self.assertEqual(
            py_order, node_order,
            f"doc_freshness entry order differs:\n  Python: {py_order}\n  Node:   {node_order}",
        )
        # Verify both are actually sorted (deterministic path-sort)
        self.assertEqual(
            py_order, sorted(py_order),
            f"Python doc_freshness entries are not path-sorted: {py_order}",
        )

    # ------------------------------------------------------------------
    # suspect_count rollup
    # ------------------------------------------------------------------

    def test_suspect_count_equals_one(self):
        """Exactly one doc is suspect (suspect-doc.md); suspect_count==1 for both twins."""
        kb_dir = self._fixture["kb_dir"]
        repo_root = self._fixture["repo_root"]

        py_results = derive_doc_freshness(kb_dir, repo_root)
        py_suspect = sum(1 for d in py_results if d.verdict == "suspect")

        node_data = _run_node_freshness(kb_dir, repo_root, self._pinned_home)
        node_suspect = node_data["suspect_count"]

        self.assertEqual(py_suspect, 1,
                         f"Python: expected exactly 1 suspect doc; got {py_suspect}")
        self.assertEqual(node_suspect, 1,
                         f"Node: expected exactly 1 suspect doc; got {node_suspect}")
        self.assertEqual(py_suspect, node_suspect,
                         f"suspect_count differs: Python={py_suspect} Node={node_suspect}")

    # ------------------------------------------------------------------
    # All-verdicts sweep (convenience: checks all 4 docs for each runtime)
    # ------------------------------------------------------------------

    def test_all_verdicts_python(self):
        """Python produces correct verdicts for all 4 fixture docs."""
        fm = self._py_freshness_map()
        self._check_all_verdicts(fm, "Python")

    def test_all_verdicts_node(self):
        """Node produces correct verdicts for all 4 fixture docs."""
        fm = self._node_freshness_map()
        self._check_all_verdicts(fm, "Node")

    # ------------------------------------------------------------------
    # Isolation self-check: fixture is NOT inside the AID repo tree
    # ------------------------------------------------------------------

    def test_fixture_repo_not_inside_aid_repo(self):
        """The fixture git repo lives in a temp dir, not inside the AID repo (AC-4)."""
        import os as _os
        real_aid = _REPO_ROOT.resolve()
        fixture_root = self._fixture["repo_root"].resolve()
        # fixture_root must NOT be under real_aid
        try:
            fixture_root.relative_to(real_aid)
            inside = True
        except ValueError:
            inside = False
        self.assertFalse(
            inside,
            f"Isolation violation: fixture repo is inside AID repo tree.\n"
            f"  AID root:    {real_aid}\n"
            f"  Fixture root: {fixture_root}",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
