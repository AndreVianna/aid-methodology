"""
test_resolve_work_dir_cross_runtime_parity.py -- task-011
(feature-001-write-infrastructure, delivery-001): "Foundation parity + dispatch
round-trip suite" -- resolve_work_dir CROSS-RUNTIME parity leg.

test_task002_resolve_work_dir.py (this directory) and
dashboard/server/tests/test_task002_resolve_work_dir.mjs each already prove
their OWN twin's resolve_work_dir/resolveWorkDir behavior in isolation (WT-1
worktree resolution, the newest-`updated` winner rule, the `main`-first
tie-break, SD-3 git-absent degradation, None/null-on-miss). Neither compares
the two runtimes against the SAME on-disk fixture. This file closes that gap:
it builds one fixture, calls the Python resolver directly (in-process import)
and the Node resolver via a short-lived `node` subprocess (no server spawn, no
port binding -- a bounded, synchronous compute call, same class as the
existing `git` subprocess calls both task-002 twin-test files already make),
and asserts the two return the SAME directory.

Deliberately NOT named test_task011_*.py: dashboard/reader/tests/ already has
an UNRELATED test_task011_reconcile.py from an earlier work's own task-011
(same-work reconcile) -- this name avoids any ambiguity with that file.

Covers (per task-011 DETAIL):
  - Python and reader.mjs pick the SAME directory for a work held in a git
    worktree (WT-1) -- skipped gracefully if `git` or `node` is unavailable.
  - Both return None/null for an absent work_id.
  - The git-absent (SD-3) path: both resolve via the same main-root-only
    fallback for a plain (non-git) served root -- no `git`/`node` availability
    gate needed for degradation logic itself, but the Node half of the
    comparison still needs `node`.

Windows 8.3-short-name note (mirrors test_task002_resolve_work_dir.mjs's own
`freshTmp()` comment): the fixture root is normalized to its canonical
long-form path via `Path(...).resolve()` BEFORE being handed to either
resolver, because Node's `path.resolve()` (used inside resolveWorkDir) is
PURELY LEXICAL -- unlike Python's `Path.resolve()`, it does not dereference an
8.3 short form a raw `tempfile.mkdtemp()` path might come back as on Windows.
Normalizing once, up front, keeps the byte-for-byte path comparison exact
without touching either resolver's production code.

Python 3.11+ stdlib only. No third-party deps. Requires `node` on PATH for the
Node-side comparison (module SKIPS, not fails, if absent); the WT-1 worktree
group additionally requires `git` (skips its own group if absent).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # dashboard/reader/tests/ -> AID/
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.reader import resolve_work_dir

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , readerPath, servedRoot, workId] = process.argv;
const mod = await import(pathToFileURL(readerPath).href);
const result = mod.resolveWorkDir(servedRoot, workId);
process.stdout.write(JSON.stringify(result));
"""


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


def _git_available() -> bool:
    try:
        r = subprocess.run(["git", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()
_GIT_AVAILABLE = _git_available()


def _node_resolve_work_dir(served_root: str, work_id: str) -> "str | None":
    """Invoke reader.mjs's resolveWorkDir via a short-lived `node` subprocess
    (a bounded compute call -- no server spawn, no port binding). Returns the
    resolved path as a string, or None (Node's `null`)."""
    driver = Path(tempfile.mkdtemp()) / "driver.mjs"
    driver.write_text(_NODE_DRIVER, encoding="utf-8")
    try:
        proc = subprocess.run(
            ["node", str(driver), str(_READER_MJS), served_root, work_id],
            capture_output=True, text=True, timeout=15,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed (exit {proc.returncode}): {proc.stderr}")
        return json.loads(proc.stdout)
    finally:
        shutil.rmtree(str(driver.parent), ignore_errors=True)


def _canonical_root(raw: Path) -> Path:
    """Resolve to the canonical long-form path ONCE, up front (see module
    docstring's Windows 8.3 note)."""
    return raw.resolve()


def _write_state(work_dir: Path, updated: str = "2026-07-17T00:00:00Z") -> None:
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(
        "## Pipeline State\n\n"
        "- **Lifecycle:** Running\n"
        "- **Phase:** Execute\n"
        "- **Active Skill:** aid-execute\n"
        f"- **Updated:** {updated}\n"
        "- **Pause Reason:** --\n"
        "- **Block Reason:** --\n"
        "- **Block Artifact:** --\n\n"
        "## Tasks State\n\n"
        "| # | Task | Type | Wave | State | Review | Elapsed | Notes |\n"
        "|---|------|------|------|-------|--------|---------|-------|\n",
        encoding="utf-8",
    )


def _git_env() -> dict:
    import os
    env = dict(os.environ)
    env.update({
        "GIT_AUTHOR_NAME": "test", "GIT_AUTHOR_EMAIL": "test@test.com",
        "GIT_COMMITTER_NAME": "test", "GIT_COMMITTER_EMAIL": "test@test.com",
    })
    return env


def _init_repo_with_commit(root: Path) -> None:
    env = _git_env()
    subprocess.run(["git", "init", "-b", "main", str(root)], env=env, capture_output=True, timeout=10)
    (root / "seed.txt").write_text("seed\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "seed.txt"], env=env, capture_output=True, timeout=10)
    subprocess.run(["git", "-C", str(root), "commit", "-m", "seed"], env=env, capture_output=True, timeout=10)


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime comparison skipped")
class TestResolveWorkDirCrossRuntimeParity(unittest.TestCase):
    """Python resolve_work_dir() and Node resolveWorkDir() agree, byte-for-byte,
    on the SAME on-disk fixture."""

    def setUp(self) -> None:
        self._tmp = _canonical_root(Path(tempfile.mkdtemp()))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    # -- SD-3: git-absent served root, single copy under <root>/.aid/works/ --

    def test_git_absent_both_runtimes_resolve_the_same_directory(self):
        aid = self._tmp / ".aid"
        work_dir = aid / "works" / "work-800-nongit"
        _write_state(work_dir)
        self.assertFalse((self._tmp / ".git").exists(), "fixture sanity: root must not be a git repo")

        py_result = resolve_work_dir(self._tmp, "work-800-nongit")
        node_result = _node_resolve_work_dir(str(self._tmp), "work-800-nongit")

        self.assertIsNotNone(py_result)
        self.assertIsNotNone(node_result)
        self.assertEqual(str(py_result), node_result,
                          "Python and Node must resolve to the identical directory (SD-3, git-absent)")
        self.assertEqual(Path(node_result), work_dir.resolve())

    def test_absent_work_id_both_runtimes_return_none(self):
        aid = self._tmp / ".aid"
        _write_state(aid / "works" / "work-801-exists")

        py_result = resolve_work_dir(self._tmp, "work-999-does-not-exist")
        node_result = _node_resolve_work_dir(str(self._tmp), "work-999-does-not-exist")

        self.assertIsNone(py_result)
        self.assertIsNone(node_result)

    # -- WT-1: worktree-isolated pipeline, real git worktree --

    @unittest.skipUnless(_GIT_AVAILABLE, "git not available on PATH -- WT-1 worktree group skipped")
    def test_worktree_isolated_pipeline_both_runtimes_resolve_to_the_worktree_copy(self):
        """A pipeline that lives ONLY under a git worktree (never under the
        main root's own .aid/works/) -- work-017's own topology -- must
        resolve to the SAME worktree directory in both runtimes, never a
        reconstructed <main-root>/.aid/works/<work_id> path (WT-1)."""
        _init_repo_with_commit(self._tmp)
        main_aid = self._tmp / ".aid"
        main_aid.mkdir(parents=True, exist_ok=True)   # main root HAS .aid/, but not this work

        wt_path = self._tmp / "wt-feat"
        env = _git_env()
        result = subprocess.run(
            ["git", "-C", str(self._tmp), "worktree", "add", str(wt_path), "-b", "feat-branch"],
            env=env, capture_output=True, timeout=15,
        )
        if result.returncode != 0:
            self.skipTest(f"git worktree add failed: {result.stderr}")

        try:
            wt_aid = wt_path / ".aid"
            work_dir = wt_aid / "works" / "work-017-cli-improvements"
            _write_state(work_dir)

            reconstructed_main_path = main_aid / "works" / "work-017-cli-improvements"
            self.assertFalse(
                reconstructed_main_path.exists(),
                "fixture sanity: the main-root reconstruction must NOT exist on disk",
            )

            py_result = resolve_work_dir(self._tmp, "work-017-cli-improvements")
            node_result = _node_resolve_work_dir(str(self._tmp), "work-017-cli-improvements")

            self.assertIsNotNone(py_result)
            self.assertIsNotNone(node_result)
            self.assertEqual(
                str(py_result), node_result,
                "Python and Node must resolve to the identical worktree directory (WT-1)",
            )
            expected = work_dir.resolve()
            self.assertEqual(py_result, expected)
            self.assertEqual(Path(node_result), expected)
            self.assertNotEqual(py_result, reconstructed_main_path)
        finally:
            subprocess.run(
                ["git", "-C", str(self._tmp), "worktree", "remove", "--force", str(wt_path)],
                capture_output=True, timeout=10,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
