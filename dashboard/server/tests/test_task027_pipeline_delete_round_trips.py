"""
test_task027_pipeline_delete_round_trips.py -- "Delete round-trips + guard
coverage" (task-027, feature-009-pipeline-delete, delivery-004,
work-017-cli-improvements).

This is a TEST-type task: NO production code is written here (that is tasks
024-026 -- the `delete-pipeline.sh` writer, the `pipeline.delete` OP_TABLE row
+ exit-7->409 map, and the Danger-zone UI). This file closes the gap those
tasks' own suites deliberately left open: tests/canonical/test-delete-pipeline.sh
proves the writer CLI directly (throwaway git fixtures, no dispatcher in the
loop); test_task025_pipeline_delete_ops.py/.mjs proves the OP_TABLE
row/status-map/argv-builder/dispatch-VALIDATION-ORDER wiring with every
`_dispatch_op` case EITHER hitting a plain (non-git) tempdir 404 path OR
stubbing the row's 'spawn' hook so the real writer is never actually invoked.
NEITHER proves the full OP -> _dispatch_op -> real delete-pipeline.sh spawn ->
real disk mutation -> re-read layer with a REAL git repo + REAL `git worktree
add` fixtures, and neither proves Node/Python twin byte-parity for this op's
dispatch responses. This file closes both gaps (feature-009 SPEC.md
Sec API Contracts / Sec Migration: "the twin byte-parity suites ... gain
op-dispatch cases (403-gated, 404, 409-guard, 200-happy) applied identically
to both twins").

Covers (all against THROWAWAY git repos under a fresh mktemp scratch directory
-- NEVER this repo's own pipelines/branches/worktrees):
  (A) 404 -- work_id resolves to no enumerated worktree root, no spawn.
  (B) 409 guards -- (a) STATE.md lifecycle=Running; (b) the dispatch process's
      OWN cwd is the non-main worktree being targeted (delete-pipeline.sh's
      "$PWD" current-worktree guard -- exercised via a real `os.chdir()` into
      the throwaway worktree before dispatching, mirroring
      tests/canonical/test-delete-pipeline.sh's own Unit 10 technique).
      NEITHER guard removes anything.
  (C) 200 happy across all three removal topologies (classified by CONTENT,
      per task-024): main-folder (rm -rf the folder only, main worktree
      survives), dedicated-worktree (git worktree remove --force -- folder +
      worktree gone, branch RETAINED), shared-worktree (rm -rf the folder
      only, sibling work + the worktree checkout itself retained).
  (D) Containment rejection -- a symlinked work_id folder whose realpath
      escapes .aid/works/ -> 500 'write-failed', no removal. Uses the SAME
      MSYS=winsymlinks:nativestrict real-symlink technique
      tests/canonical/test-delete-pipeline.sh's own Unit 11 uses (via the
      server's own resolved bash.exe), self-skipping cleanly when the host
      cannot produce a resolvable symlink.
  (E) Post-delete truthfulness -- after a 200: the pipeline is ABSENT from a
      fresh read_repo() (AC2, the same function GET /r/<id>/api/model calls);
      the git BRANCH still exists (OQ-PL3, `git branch --list`); and for a
      work_id shadowed in two worktrees, ONLY the reconciled winner (newest
      `updated`) is removed -- the shadow copy re-surfaces as the sole
      remaining copy on the next read_repo() (WT-1 symmetry, the SPEC's own
      documented AC2 edge case).
  (F) Twin dispatch byte-parity -- every case above (plus the args-non-empty
      422 and the invalid-work_id-shape 422 rows) re-driven through BOTH
      Python's real `_dispatch_op` and Node's real `dispatchOp` (sliced import
      of the ACTUAL server.mjs, no fake writer -- mirrors
      test_task023_list_management_round_trips.py's
      TestConnectorSetRealWriterCrossRuntimeParity technique, applied here
      with no WRITER_DIR override since the REAL delete-pipeline.sh writer is
      exactly what must be proven byte-identical), asserting (status, body)
      byte-identical between runtimes. No existing golden-fixture bytes
      change; no schema_version bump (neither twin's OP_TABLE/DEFAULT_MAP
      shape is touched by this file).

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` directly (Python) or drives Node's `dispatchOp`
via a sliced-import `node --input-type=module` subprocess (bounded, no port
bind) -- no `_ServerThread` socket bind anywhere in this file -- safe to run
locally per the project's port-binding-server-test constraint, and every case
was exercised directly as part of this task's own verification pass (skipped,
not failed, when `git`/`bash`/`node` is absent, or when the host cannot
produce a resolvable symlink). The 403 write-gate case (which fires in
`_serve_op` BEFORE `_dispatch_op` is ever reached, per test_server_py.py's own
`TestOpDispatchLive` convention) is added directly to `test_server_py.py`
(`TestOpDispatchLive`, live-socket) and `test_server_node.mjs` (its existing
[2c] write-gate + [5c-op] OP_TABLE dispatch-smoke groups) instead of here.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import os
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD (mirrors the other
# task-0NN suites' own sys.path setup).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv
from dashboard.reader.reader import read_repo

_SERVER_MJS = _DASHBOARD_DIR / "server" / "server.mjs"
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"


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


def _bash_available() -> "str | None":
    """Resolve an ABSOLUTE bash.exe path via server.py's own _BASH_EXE resolver
    (never a bare "bash" argv[0] -- see server.py's _resolve_bash_exe
    docstring: on Windows CreateProcess would otherwise silently resolve to
    the unusable WSL-launcher stub in System32)."""
    try:
        subprocess.run([srv._BASH_EXE, "--version"], capture_output=True, check=True, timeout=10)
        return srv._BASH_EXE
    except Exception:
        return None


_NODE_AVAILABLE = _node_available()
_GIT_AVAILABLE = _git_available()
_BASH_EXE_RESOLVED = _bash_available()
_PREREQS_OK = _GIT_AVAILABLE and _BASH_EXE_RESOLVED


# ---------------------------------------------------------------------------
# Real throwaway git-repo fixture helpers (mirrors tests/canonical/
# test-delete-pipeline.sh's own _mk_repo/_mk_work/_mk_worktree conventions, so
# a fixture built here reads identically to what the writer's OWN test suite
# already proved -- this file's job is the DISPATCH layer on top, not a
# reimplementation of the writer's own fixture vocabulary).
# ---------------------------------------------------------------------------

def _git(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True, timeout=15)


def _rmtree_onerror(func, path, _exc_info) -> None:
    """shutil.rmtree onerror handler: git marks packed objects/refs read-only
    on Windows, which a plain shutil.rmtree(..., ignore_errors=True) silently
    fails to delete (leaving an orphaned .git/ directory behind under the OS
    temp dir on every run -- a real test-hygiene gap, not merely cosmetic).
    Clears the read-only bit and retries once; still swallows any residual
    failure (best-effort cleanup, never fails a test)."""
    try:
        os.chmod(path, stat.S_IWRITE)
        func(path)
    except Exception:
        pass


def _rmtree(path: "Path | str") -> None:
    """Robust throwaway-fixture removal used EVERYWHERE in this file instead
    of a bare shutil.rmtree(..., ignore_errors=True) -- see _rmtree_onerror."""
    shutil.rmtree(str(path), onerror=_rmtree_onerror)


def _rmtree_if_exists(path: "Path | str") -> None:
    """Belt-and-suspenders cleanup for a worktree directory a SUCCESSFUL
    delete-pipeline.sh dispatch is EXPECTED to have already removed (dedicated-
    worktree topology): a no-op when the dispatch behaved as expected, but
    still cleans up the throwaway fixture (rather than leaking it under the OS
    temp dir) if an assertion fires before that point or the dispatch
    unexpectedly failed to remove it."""
    p = Path(path)
    if p.exists():
        _rmtree(p)


class _GitRepo:
    """A throwaway git repo (main worktree) with an empty .aid/works/
    container and one commit, cleaned up on exit. NEVER this repo's own
    working tree -- always a fresh mktemp scratch directory.

    .resolve() immediately on creation: on this Windows host,
    tempfile.mkdtemp() can return a path with an 8.3 SHORT username segment
    (e.g. 'ANDRE~1.VIA') while git itself always reports the LONG canonical
    form via `rev-parse --show-toplevel` -- Python's Path.resolve() expands
    the short form to match git's report, but Node's path.resolve() is purely
    LEXICAL (no filesystem query) and does NOT, so a raw (unresolved) mktemp
    path handed to Node's dispatchOp makes its `_isGitToplevel` check fail
    (long != short) and silently degrade to a main-root-only worktree
    enumeration -- a documented pre-existing Windows-host test-fixture
    artifact (same root cause as the long-vs-8.3-short `aid_dir` normalization
    test_task023_list_management_round_trips.py's own TestDm1Serializer
    ConnectorsExternalSourcesParity already documents), not a delete-pipeline
    dispatch defect. Resolving here once, before any worktree is added off
    this path, keeps every fixture built by this file long-form-consistent
    for BOTH runtimes."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp(prefix="aid-t027-")).resolve()
        (self.path / ".aid" / "works").mkdir(parents=True, exist_ok=True)
        _git(["init", "-q", "-b", "main"], self.path)
        _git(["config", "user.email", "test@example.invalid"], self.path)
        _git(["config", "user.name", "Test"], self.path)
        (self.path / ".aid" / "works" / ".gitkeep").write_text("", encoding="utf-8")
        _git(["add", "-A"], self.path)
        _git(["commit", "-q", "-m", "init"], self.path)
        return self.path

    def __exit__(self, *_exc) -> None:
        _rmtree(self.path)


def _make_work(root: Path, work_id: str, lifecycle: str = "Pending",
                updated: str = "2026-01-01T00:00:00Z") -> Path:
    """<root>/.aid/works/<work_id>/STATE.md -- the SAME minimal
    frontmatter-only shape tests/canonical/test-delete-pipeline.sh's own
    _mk_work uses (read identically by delete-pipeline.sh's bash
    _frontmatter_value AND dashboard/reader/parsers.py's
    _apply_pipeline_frontmatter -- WT-1 consistency by construction)."""
    work_dir = root / ".aid" / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(
        f"---\nlifecycle: {lifecycle}\nupdated: '{updated}'\n---\n# Work State\n",
        encoding="utf-8",
    )
    return work_dir


def _commit_all(root: Path, msg: str) -> None:
    _git(["add", "-A"], root)
    _git(["commit", "-q", "-m", msg], root)


def _make_worktree(repo: Path, path: Path, branch: str) -> None:
    r = _git(["worktree", "add", "-q", "-b", branch, str(path)], repo)
    if r.returncode != 0:
        raise RuntimeError(f"git worktree add failed: {r.stderr}")


def _branch_exists(repo: Path, branch: str) -> bool:
    r = _git(["branch", "--list", branch], repo)
    return branch in r.stdout


def _try_make_symlink(bash_exe: str, link_path: Path, target_path: Path) -> bool:
    """Mirrors tests/canonical/test-delete-pipeline.sh's own Unit 11 technique:
    MSYS=winsymlinks:nativestrict forces a GENUINE (non-junction) symlink on
    Windows Git-Bash. Returns False (never raises) on any failure -- the
    caller self-skips rather than asserting a host limitation."""
    env = dict(os.environ)
    env["MSYS"] = "winsymlinks:nativestrict"
    try:
        r = subprocess.run(
            [bash_exe, "-c", f"ln -s {shlex.quote(str(target_path))} {shlex.quote(str(link_path))}"],
            env=env, capture_output=True, text=True, timeout=10,
        )
        return r.returncode == 0 and link_path.exists()
    except Exception:
        return False


# ===========================================================================
# (A) 404 -- work_id resolves to no enumerated worktree root, no spawn.
# ===========================================================================

@unittest.skipUnless(_PREREQS_OK, "git/bash not available")
class TestNotFoundRealGitFixture(unittest.TestCase):
    def test_work_id_in_no_worktree_404_no_spawn(self):
        with _GitRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-999-nonexistent"}}, str(root),
            )
            self.assertEqual(status, 404)
            self.assertEqual(json.loads(body)["error"], "not-found")
            # Nothing was touched: the repo itself is still a valid git checkout.
            self.assertTrue((root / ".git").is_dir())


# ===========================================================================
# (B) 409 guards -- Running lifecycle; current-worktree. Neither removes
# anything.
# ===========================================================================

@unittest.skipUnless(_PREREQS_OK, "git/bash not available")
class TestGuardsRealGitFixture(unittest.TestCase):
    def test_lifecycle_running_409_no_removal(self):
        with _GitRepo() as root:
            work_dir = _make_work(root, "work-100-run", lifecycle="Running")
            _commit_all(root, "add work-100-run")
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-100-run"}}, str(root),
            )
            self.assertEqual(status, 409)
            self.assertEqual(json.loads(body)["error"], "pipeline-active")
            self.assertTrue(work_dir.is_dir(), "folder must NOT be removed under the Running guard")

    def test_current_worktree_409_no_removal(self):
        """delete-pipeline.sh's current-worktree guard reads `$PWD` -- the
        dispatched child's own cwd, inherited from the Python process's cwd at
        subprocess.run() time (server.py's _run_writer sets no explicit cwd=).
        Mirrors tests/canonical/test-delete-pipeline.sh's own Unit 10
        (`cd "$WT10" && ... bash "$SUT" ...`)."""
        old_cwd = os.getcwd()
        with _GitRepo() as root:
            wt = root.parent / f"aid-t027-wt-cur-{uuid.uuid4().hex}"
            try:
                _make_worktree(root, wt, f"feature-cur-{uuid.uuid4().hex[:8]}")
                work_dir = _make_work(wt, "work-200-cur")
                _commit_all(wt, "add work-200-cur")
                try:
                    os.chdir(str(wt))
                    status, body = srv._dispatch_op(
                        srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-200-cur"}}, str(root),
                    )
                finally:
                    os.chdir(old_cwd)
                self.assertEqual(status, 409)
                self.assertEqual(json.loads(body)["error"], "pipeline-active")
                self.assertTrue(work_dir.is_dir())
                self.assertTrue(wt.is_dir(), "the current worktree itself must not be removed")
            finally:
                _rmtree_if_exists(wt)


# ===========================================================================
# (C) 200 happy across all three removal topologies (classified by CONTENT).
# ===========================================================================

@unittest.skipUnless(_PREREQS_OK, "git/bash not available")
class TestHappyPathTopologiesRealGitFixture(unittest.TestCase):
    def test_main_folder_rm_rf_folder_only(self):
        with _GitRepo() as root:
            work_dir = _make_work(root, "work-300-main")
            _commit_all(root, "add work-300-main")
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-300-main"}}, str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.delete"})
            self.assertFalse(work_dir.exists())
            self.assertTrue(root.is_dir(), "the main worktree itself must survive")
            self.assertTrue((root / ".aid" / "works").is_dir())

    def test_dedicated_worktree_removes_folder_and_worktree_branch_retained(self):
        with _GitRepo() as root:
            wt = root.parent / f"aid-t027-wt-ded-{uuid.uuid4().hex}"
            branch = f"feature-ded-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                _make_work(wt, "work-301-ded")
                _commit_all(wt, "add work-301-ded")
                status, body = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-301-ded"}}, str(root),
                )
                self.assertEqual(status, 200)
                self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.delete"})
                self.assertFalse(wt.exists(), "dedicated worktree directory must be gone")
                self.assertTrue(_branch_exists(root, branch), "branch RETAINED (OQ-PL3)")
            finally:
                _rmtree_if_exists(wt)

    def test_shared_worktree_removes_folder_only_sibling_and_worktree_survive(self):
        with _GitRepo() as root:
            wt = root.parent / f"aid-t027-wt-shared-{uuid.uuid4().hex}"
            branch = f"feature-shared-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                work_a = _make_work(wt, "work-302-a")
                work_b = _make_work(wt, "work-302-b")
                _commit_all(wt, "add work-302-a and work-302-b")
                status, body = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-302-a"}}, str(root),
                )
                self.assertEqual(status, 200)
                self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.delete"})
                self.assertFalse(work_a.exists())
                self.assertTrue(work_b.is_dir(), "sibling work retained")
                self.assertTrue(wt.is_dir(), "shared worktree checkout itself survives")
                self.assertTrue(_branch_exists(root, branch))
            finally:
                _rmtree_if_exists(wt)


# ===========================================================================
# (D) Containment rejection -- symlink escape.
# ===========================================================================

@unittest.skipUnless(_PREREQS_OK, "git/bash not available")
class TestContainmentRejectionRealGitFixture(unittest.TestCase):
    def test_symlink_escape_500_no_removal(self):
        with _GitRepo() as root:
            outside = root.parent / f"aid-t027-outside-{uuid.uuid4().hex}"
            outside.mkdir(parents=True, exist_ok=True)
            marker = outside / "marker"
            marker.write_text("x", encoding="utf-8")
            link_path = root / ".aid" / "works" / "work-600-sym"
            try:
                ok = _try_make_symlink(_BASH_EXE_RESOLVED, link_path, outside)
                if not ok:
                    self.skipTest(
                        "host cannot create a resolvable symlink (no privilege / "
                        "Windows Developer Mode off) -- deferred to a host where "
                        "symlink creation is unrestricted (e.g. CI/Linux)"
                    )
                try:
                    link_real = link_path.resolve()
                    works_real = (root / ".aid" / "works").resolve()
                except OSError:
                    self.skipTest("cannot resolve realpath of the created symlink")
                self.assertNotEqual(link_real, works_real)
                self.assertFalse(
                    works_real in link_real.parents,
                    "fixture sanity: the symlink must resolve OUTSIDE .aid/works/",
                )

                status, body = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-600-sym"}}, str(root),
                )
                self.assertEqual(status, 500)
                self.assertEqual(json.loads(body)["error"], "write-failed")
                self.assertTrue(marker.exists(), "outside target must be untouched -- no traversal")
            finally:
                _rmtree(outside)


# ===========================================================================
# (E) Post-delete truthfulness -- read_repo() absence (AC2); branch retained
# (OQ-PL3); WT-1 shadow symmetry.
# ===========================================================================

@unittest.skipUnless(_PREREQS_OK, "git/bash not available")
class TestPostDeleteTruthfulnessRealGitFixture(unittest.TestCase):
    def test_absent_from_fresh_read_repo_after_delete(self):
        """AC2: 'the pipeline no longer appears' -- proven against the SAME
        read_repo() function GET /r/<id>/api/model dispatches to, not a
        reimplementation."""
        with _GitRepo() as root:
            _make_work(root, "work-400-gone")
            _commit_all(root, "add work-400-gone")
            status, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-400-gone"}}, str(root),
            )
            self.assertEqual(status, 200)
            model = read_repo(str(root))
            self.assertNotIn("work-400-gone", [w.work_id for w in model.works])

    def test_branch_retained_after_dedicated_worktree_delete(self):
        with _GitRepo() as root:
            wt = root.parent / f"aid-t027-wt-branch-{uuid.uuid4().hex}"
            branch = f"feature-branch-check-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                _make_work(wt, "work-401-branch")
                _commit_all(wt, "add work-401-branch")
                status, _ = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-401-branch"}}, str(root),
                )
                self.assertEqual(status, 200)
                self.assertTrue(_branch_exists(root, branch), "OQ-PL3: branch never deleted")
            finally:
                _rmtree_if_exists(wt)

    def test_shadowed_work_id_wt1_symmetry_only_winner_removed_shadow_resurfaces(self):
        """A work_id present in BOTH the main root (OLDER `updated`) and a
        worktree (NEWER `updated`) -- resolve_work_dir/delete-pipeline.sh both
        select the WORKTREE copy as the reconciled winner (newest wins); ONLY
        it is removed. The shadow (main) copy re-surfaces on the next
        read_repo() as the new sole/reconciled copy -- truthful to disk, per
        feature-009 SPEC.md's own documented AC2 edge case (WT-1 symmetry, no
        bulk delete)."""
        with _GitRepo() as root:
            shadow_dir = _make_work(root, "work-402-shadow", updated="2020-01-01T00:00:00Z")
            _commit_all(root, "add older main copy")
            wt = root.parent / f"aid-t027-wt-shadow-{uuid.uuid4().hex}"
            branch = f"feature-shadow-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                winner_dir = _make_work(wt, "work-402-shadow", updated="2026-06-01T00:00:00Z")
                _commit_all(wt, "add newer worktree copy")

                before = read_repo(str(root))
                self.assertIn("work-402-shadow", [w.work_id for w in before.works])

                status, _ = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-402-shadow"}}, str(root),
                )
                self.assertEqual(status, 200)
                self.assertFalse(winner_dir.exists(), "the newer (winner) worktree copy must be removed")
                self.assertTrue(
                    shadow_dir.is_dir(),
                    "the older (shadow) main copy must be left untouched -- WT-1 symmetry, no bulk delete",
                )
                # This worktree hosted ONLY work-402-shadow -- 'dedicated' classification,
                # so the whole worktree is removed together with the folder.
                self.assertFalse(wt.exists())
                self.assertTrue(_branch_exists(root, branch), "OQ-PL3: branch retained even for the winner's worktree")

                after = read_repo(str(root))
                after_ids = [w.work_id for w in after.works]
                self.assertIn(
                    "work-402-shadow", after_ids,
                    "the shadow copy re-surfaces as the sole remaining copy on the next read (truthful to disk)",
                )
            finally:
                _rmtree_if_exists(wt)


# ===========================================================================
# (F) Twin dispatch byte-parity -- every case re-driven through Python's real
# _dispatch_op AND Node's real dispatchOp (sliced import, REAL writer, no
# WRITER_DIR override), asserting (status, body) byte-identical.
# ===========================================================================

def _sliced_server_mjs_source() -> str:
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    if idx == -1:
        raise AssertionError(
            "server.mjs 'Main: parse args, create server, bind, register SIGTERM' "
            "marker comment is gone -- this test's slice cut point needs updating"
        )
    return text[:idx] + "\nexport { dispatchOp, OP_TABLE };\n"


class _NodeSlicedDispatchFixture:
    """setUpClass/tearDownClass helper mirroring test_task023_list_management_
    round_trips.py's own _NodeSlicedFakeWriterFixture, but with NO WRITER_DIR
    redirect -- this file drives the REAL delete-pipeline.sh writer on both
    runtimes (the whole point is proving the ACTUAL writer's output is
    byte-identical across twins, not a synthetic exit-code matrix)."""

    _slice_path: Path

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_task027_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def _node_dispatch(self, parsed: dict, served_root: str) -> "tuple[int, str]":
        driver = (
            "import { dispatchOp, OP_TABLE } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const parsed = {json.dumps(parsed)};\n"
            f"const [status, body] = dispatchOp(OP_TABLE, parsed, {json.dumps(served_root)});\n"
            "process.stdout.write(JSON.stringify([status, Buffer.from(body).toString('utf-8')]));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node dispatch driver failed: {result.stderr[:2000]}")
        status, body = json.loads(result.stdout.strip())
        return status, body


def _assert_parity(test: unittest.TestCase, py_result, node_result, expected_status: int,
                    expected_error: "str | None" = None) -> None:
    """Mirrors test_task023_list_management_round_trips.py's own _assert_parity
    helper verbatim: BOTH runtimes must independently produce the EXPECTED
    status, AND the two runtimes' actual (status, body-bytes) pairs must be
    IDENTICAL to each other."""
    py_status, py_body = py_result
    node_status, node_body = node_result
    py_text = py_body.decode("utf-8") if isinstance(py_body, (bytes, bytearray)) else py_body
    test.assertEqual(py_status, expected_status, f"python status mismatch; body={py_text!r}")
    test.assertEqual(node_status, expected_status, f"node status mismatch; body={node_body!r}")
    test.assertEqual(py_status, node_status, "python/node HTTP status DIVERGE (twin parity broken)")
    test.assertEqual(py_text, node_body, "python/node response BODY bytes DIVERGE (twin parity broken)")
    if expected_error is not None:
        test.assertEqual(json.loads(py_text)["error"], expected_error)


@unittest.skipUnless(_NODE_AVAILABLE and _PREREQS_OK, "node/git/bash not available -- twin parity skipped")
class TestTwinDispatchParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    """Drives the SAME fixture SHAPE through Python's _dispatch_op and Node's
    sliced dispatchOp independently (each against its OWN throwaway git repo --
    dispatch is destructive, so the fixture is built twice, once per
    runtime), asserting the (status, body) pair is byte-identical across
    runtimes for every case in the guard/topology/validation matrix (AC4)."""

    def _assert_case_parity(self, build_fixture, parsed_fn, expected_status: int,
                             expected_error: "str | None" = None) -> None:
        """build_fixture(root) seeds the fixture under a fresh _GitRepo root;
        it may return a Path that MIGHT need manual cleanup (a worktree a
        successful dispatch is expected to remove, or a shared worktree left
        behind after a folder-only removal) or None. Cleanup is always a
        no-op (_rmtree_if_exists) when the dispatch already removed it --
        belt-and-suspenders so a failed assertion (or an unexpectedly-failed
        dispatch) never leaks the fixture under the OS temp dir. parsed_fn()
        returns the op-request dict (called fresh for each runtime -- no
        shared mutable state)."""
        extra_dirs: list[Path] = []
        with _GitRepo() as py_root:
            extra = build_fixture(py_root)
            if extra is not None:
                extra_dirs.append(extra)
            py_result = srv._dispatch_op(srv.OP_TABLE, parsed_fn(), str(py_root))

        with _GitRepo() as node_root:
            extra = build_fixture(node_root)
            if extra is not None:
                extra_dirs.append(extra)
            node_result = self._node_dispatch(parsed_fn(), str(node_root))

        try:
            _assert_parity(self, py_result, node_result, expected_status, expected_error)
        finally:
            for d in extra_dirs:
                _rmtree_if_exists(d)

    def test_404_not_found_parity(self) -> None:
        self._assert_case_parity(
            lambda root: None,
            lambda: {"op": "pipeline.delete", "target": {"work_id": "work-999-nonexistent"}},
            404, "not-found",
        )

    def test_422_invalid_work_id_shape_parity(self) -> None:
        self._assert_case_parity(
            lambda root: None,
            lambda: {"op": "pipeline.delete", "target": {"work_id": "not-a-work-id"}},
            422, "invalid-value",
        )

    def test_422_non_empty_args_parity(self) -> None:
        def build(root: Path) -> None:
            _make_work(root, "work-500-args")
            _commit_all(root, "add work-500-args")

        self._assert_case_parity(
            build,
            lambda: {"op": "pipeline.delete", "target": {"work_id": "work-500-args"}, "args": {"x": "y"}},
            422, "invalid-value",
        )

    def test_409_running_guard_parity(self) -> None:
        def build(root: Path) -> None:
            _make_work(root, "work-100-run", lifecycle="Running")
            _commit_all(root, "add work-100-run")

        self._assert_case_parity(
            build, lambda: {"op": "pipeline.delete", "target": {"work_id": "work-100-run"}}, 409, "pipeline-active",
        )

    def test_200_main_folder_parity(self) -> None:
        def build(root: Path) -> None:
            _make_work(root, "work-300-main")
            _commit_all(root, "add work-300-main")

        self._assert_case_parity(
            build, lambda: {"op": "pipeline.delete", "target": {"work_id": "work-300-main"}}, 200,
        )

    def test_200_dedicated_worktree_parity(self) -> None:
        def build(root: Path) -> Path:
            wt = root.parent / f"aid-t027-parity-ded-{uuid.uuid4().hex}"
            _make_worktree(root, wt, f"feature-parity-ded-{uuid.uuid4().hex[:8]}")
            _make_work(wt, "work-301-ded")
            _commit_all(wt, "add work-301-ded")
            # Expected to be removed by the dispatch itself on BOTH runtimes'
            # success path -- returned anyway so _assert_case_parity's
            # belt-and-suspenders _rmtree_if_exists cleans it up if an
            # assertion fires first or the dispatch unexpectedly fails to.
            return wt

        self._assert_case_parity(
            build, lambda: {"op": "pipeline.delete", "target": {"work_id": "work-301-ded"}}, 200,
        )

    def test_200_shared_worktree_parity(self) -> None:
        def build(root: Path) -> Path:
            wt = root.parent / f"aid-t027-parity-shared-{uuid.uuid4().hex}"
            _make_worktree(root, wt, f"feature-parity-shared-{uuid.uuid4().hex[:8]}")
            _make_work(wt, "work-302-a")
            _make_work(wt, "work-302-b")
            _commit_all(wt, "add work-302-a and work-302-b")
            return wt  # folder-only removal -- the worktree itself survives, needs cleanup

        self._assert_case_parity(
            build, lambda: {"op": "pipeline.delete", "target": {"work_id": "work-302-a"}}, 200,
        )

    def test_409_current_worktree_guard_parity(self) -> None:
        """Same technique as TestGuardsRealGitFixture.test_current_worktree_
        409_no_removal, applied to BOTH runtimes: os.chdir() into the
        throwaway worktree before dispatching (Python) / before spawning the
        Node driver subprocess (which itself spawns bash with no cwd=
        override, inheriting the Python parent's cwd at subprocess.run()
        time -- server.mjs's own runWriter sets no explicit cwd either)."""
        old_cwd = os.getcwd()
        extra_dirs: list[Path] = []
        try:
            with _GitRepo() as py_root:
                wt = py_root.parent / f"aid-t027-parity-cur-{uuid.uuid4().hex}"
                extra_dirs.append(wt)
                _make_worktree(py_root, wt, f"feature-parity-cur-{uuid.uuid4().hex[:8]}")
                _make_work(wt, "work-200-cur")
                _commit_all(wt, "add work-200-cur")
                try:
                    os.chdir(str(wt))
                    py_result = srv._dispatch_op(
                        srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-200-cur"}}, str(py_root),
                    )
                finally:
                    os.chdir(old_cwd)

            with _GitRepo() as node_root:
                wt2 = node_root.parent / f"aid-t027-parity-cur-{uuid.uuid4().hex}"
                extra_dirs.append(wt2)
                _make_worktree(node_root, wt2, f"feature-parity-cur-{uuid.uuid4().hex[:8]}")
                _make_work(wt2, "work-200-cur")
                _commit_all(wt2, "add work-200-cur")
                try:
                    os.chdir(str(wt2))
                    node_result = self._node_dispatch(
                        {"op": "pipeline.delete", "target": {"work_id": "work-200-cur"}}, str(node_root),
                    )
                finally:
                    os.chdir(old_cwd)

            _assert_parity(self, py_result, node_result, 409, "pipeline-active")
        finally:
            os.chdir(old_cwd)
            for d in extra_dirs:
                _rmtree_if_exists(d)


class TestNoScopeCreepPointer(unittest.TestCase):
    """AC-traceability pointer only (task-027 DETAIL: 'no existing golden-
    fixture bytes change; no schema_version bump'). This file never writes
    under dashboard/server/tests/fixtures/ and never touches server.py/
    server.mjs/OP_TABLE/DEFAULT_MAP (verified by inspection during authoring,
    not re-asserted at runtime here -- this class exists purely to make the
    constraint discoverable to a future reader of this file's test list, the
    same convention test_task023_list_management_round_trips.py's own
    TestSemanticValidate422BeforeSpawnAlreadyCovered / TestDm1AlreadyCovered
    KeyOrderSchemaVersion pointer classes establish)."""

    def test_pointer_no_production_code_touched_by_this_task(self) -> None:
        self.assertTrue(True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
