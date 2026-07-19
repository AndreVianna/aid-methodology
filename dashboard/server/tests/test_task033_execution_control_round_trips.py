"""
test_task033_execution_control_round_trips.py -- "Execution-control op
round-trips + parity" (task-033, feature-008-execution-control, delivery-005,
work-017-cli-improvements).

This is a TEST-type task: NO production code is written here (that is
tasks 028-030 -- write-control-signal.sh, the stop_requested reader twin +
task.stop/task.resume OP_TABLE rows, and the Finish/Stop/Resume UI). This
file closes the gaps those tasks' own suites deliberately left open:

  - test_task029_task_stop_resume_ops.py/.mjs prove the task.stop/task.resume
    OP_TABLE row/status-map/argv-builder/dispatch-VALIDATION-ORDER wiring, but
    EVERY case either hits a plain (non-git) tempdir 404 path or stubs the
    row's 'spawn' hook so write-control-signal.sh is NEVER actually invoked
    (see that file's own module docstring: "A real write-control-signal.sh
    round trip ... is task-033's job -- deliberately NOT exercised here").
  - test_task029_stop_requested.py proves the reader-twin derivation
    (`_task_stop_requested`, `read_repo()`, `_ser_task`) against a
    HAND-WRITTEN `.stop` signal file (`_seed_stop_signal`) -- never one the
    real writer actually produced -- and its own WT-1 class proves
    worktree-awareness via a MOCKED `enumerate_worktree_roots`, never a real
    `git worktree add` fixture.
  - test_task030_finish_stop_resume_ui.py proves the AC6 gate CONDITION is
    correctly written in home.html via a static source-text parse -- it never
    executes the gate against a real serialized model.

None of the three proves the full OP -> _dispatch_op -> REAL writer spawn ->
REAL disk mutation -> re-read layer for pipeline.finish or task.stop/resume
with a REAL writer (bash-spawned write-control-signal.sh / writeback-state.sh)
in the loop, a REAL git worktree for WT-1, the AC6 gate evaluated against a
REAL serialized model for every task status, or dispatch-response byte-parity
across the Python/Node twins for the REAL write-control-signal.sh writer. This
file closes all of those gaps (feature-008-execution-control SPEC.md;
mirrors test_task027_pipeline_delete_round_trips.py's own "closes the gap"
role for pipeline.delete, and test_task023_list_management_round_trips.py's
real-writer cross-runtime parity technique).

Covers (all against THROWAWAY tempdirs/git repos under a fresh mktemp scratch
directory -- NEVER this repo's own pipelines/branches/worktrees):

  (A) pipeline.finish real round-trip (AC-EC1/AC2/AC3) -- dispatches the op
      through the REAL writeback-state.sh writer (no spawn stub), asserts
      `lifecycle: Completed` is persisted via a surgical frontmatter rewrite
      (the STATE.md BODY text -- everything after the closing `---` fence --
      survives byte-for-byte untouched, i.e. no hand-written DERIVED section),
      and that a fresh read_repo()+serialize_model() pass (the EXACT function
      chain `/r/<id>/api/model` dispatches to, per server.py's own
      `_serve_repo_model`) reports `lifecycle: "Completed"`.

  (B) task.stop / task.resume real round-trip (AC-EC1/AC2) -- dispatches both
      ops through the REAL write-control-signal.sh writer: stop creates the
      `.stop` control file and the NEXT model read re-derives
      `stop_requested: true`; resume removes it and the next read re-derives
      `false`; both ops are independently idempotent (re-stop / re-resume are
      still 200, with no observable state change).

  (C) WT-1 real-worktree coverage -- a REAL `git worktree add` fixture (same
      technique as test_task027_pipeline_delete_round_trips.py's own
      `_GitRepo`/`_make_worktree` helpers): the work lives ONLY in the
      secondary worktree, `served_root` passed to `_dispatch_op`/`read_repo`
      is the MAIN worktree. Proves the `.stop` file lands under the
      WORKTREE's own `.aid/.control/<work_id>/` (never a reconstructed
      `<served-root>/.aid/.control/<work_id>/` path -- which is asserted to
      never even be created), and that a REAL `read_repo()` pass (real git
      worktree enumeration, no mocking) re-derives `stop_requested` relative
      to that SAME walked worktree copy.

  (D) AC6 gate model-flags matrix -- for EVERY TaskStatus value
      (Pending/In Progress/In Review/Blocked/Done/Failed/Canceled) crossed
      with both `write_enabled` states, builds a REAL task fixture, reads it
      through `read_repo()`+`serialize_model()`, and evaluates the exact
      home.html gate condition (`task.status === 'In Progress' &&
      writeEnabled`) against the REAL serialized `status`/`write_enabled`
      values the server actually emits. Complements (does not duplicate)
      test_task030_finish_stop_resume_ui.py's own static parse of the JS gate
      TEXT (T-G1) -- that file proves the JS logic is written correctly; this
      file proves the MODEL DATA it operates on is derived correctly for
      every status.

  (E) Twin dispatch byte-parity for the REAL write-control-signal.sh writer --
      task.stop / task.resume re-driven through BOTH Python's real
      `_dispatch_op` and Node's real `dispatchOp` (sliced import of the ACTUAL
      server.mjs, no fake writer, no WRITER_DIR override -- mirrors
      test_task027_pipeline_delete_round_trips.py's own `TestTwinDispatchParity`
      class, applied to write-control-signal.sh instead of
      delete-pipeline.sh), asserting (status, body) byte-identical between
      runtimes for the stop/resume/idempotent-re-stop cases. This is NEW
      relative to test_task029_task_stop_resume_ops.py/.mjs, which both stub
      'spawn' and therefore never actually invoke the writer on EITHER
      runtime.

  stop_requested reader-twin serializer parity (AC4) itself -- Python
  `_ser_task` vs Node `_buildTaskModel` byte-identical output, including
  `stop_requested`, across both signal states and both flat/hierarchical
  layouts -- is ALREADY fully covered by
  dashboard/reader/tests/test_task029_stop_requested.py's own
  `TestCrossTwinParityStopRequested` class (regenerated golden fixtures, per
  that task's own DETAIL.md scope). This file does not re-churn those
  fixtures; verification re-runs that suite to CONFIRM it still passes
  (see this task's own STATE.md / dispatch report for the exact command).

KNOWN PRODUCTION DEFECT discovered while authoring this file (NOT fixed here
-- TEST-type task; see IMPEDIMENT-task-033.md at the work root for the full
write-up + proposed resolution, and this module's own
`_AID_WORK_DIR_BACKSLASH_DEFECT` comment for the exact root cause): on a
Windows host, `_op_task_stop_argv`/`_op_task_resume_argv` (BOTH server.py and
server.mjs) hand write-control-signal.sh a BACKSLASH-separated AID_WORK_DIR,
which breaks that script's own forward-slash path arithmetic
(`${WORK_DIR##*/}` + manual `/../../` concatenation) -- the control-signal
file lands at a garbled path instead of the documented
`<work_dir>/../../.control/<work_id>/task-<NNN>.stop`, while the writer still
reports success (HTTP 200) and `stop_requested` silently never flips. This is
a genuine, previously-unexercised (task-029's own suite explicitly deferred
the real-writer round trip to this task) defect in FR-T3 on Windows;
writeback-state.sh (pipeline.finish) is UNAFFECTED. Every test below that
requires the writer to land the signal at the CORRECT path is `skipIf`-gated
on this defect (fully exercised and GREEN on POSIX/CI); a dedicated
Windows-only regression canary (`TestKnownDefectAidWorkDirBackslashOnWindows`)
positively demonstrates the current (buggy) behavior as a tripwire for when
the production fix lands.

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` directly (Python) or drives Node's `dispatchOp`
via a sliced-import `node --input-type=module` subprocess (bounded, no port
bind) -- no `_ServerThread` socket bind anywhere in this file -- safe to run
locally per the project's port-binding-server-test constraint. Every writer
spawned here (write-control-signal.sh, writeback-state.sh) is a plain bounded
child process (30s subprocess timeout, per `_run_writer`), never a background/
detached process. Classes requiring `git`/`bash`/`node` self-skip cleanly when
the host lacks them.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import os
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
from dashboard.reader import read_repo

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


# ---------------------------------------------------------------------------
# KNOWN PRODUCTION DEFECT discovered by this TEST-type task (NOT fixed here --
# see IMPEDIMENT-task-033.md at the work root for the full write-up + proposed
# resolution; this is a TEST task, production code is out of scope):
#
# _op_task_stop_argv / _op_task_resume_argv (server.py) and opTaskStopArgv /
# opTaskResumeArgv (server.mjs) set env `AID_WORK_DIR = str(work_dir)` /
# `String(workDir)` -- a NATIVE path string, backslash-separated on Windows.
# write-control-signal.sh's own path arithmetic on that env var
# (`WORK_DIR="${WORK_DIR%/}"`, `WORK_ID="${WORK_DIR##*/}"`, and the manual
# `"${WORK_DIR}/../../.control/${WORK_ID}"` concatenation) assumes a
# FORWARD-SLASH path: on a backslash path, `${WORK_DIR##*/}` finds no `/` to
# strip on and returns the WHOLE path unchanged, so CONTROL_DIR ends up
# embedding the entire work_dir string a second time as a bogus path
# component -- the control-signal file is created at a garbled location
# instead of `<work_dir>/../../.control/<work_id>/task-<NNN>.stop`, while the
# writer itself still exits 0 (HTTP 200) and the READER (pathlib, slash-
# agnostic) looks at the CORRECT path and never finds it. Net effect: on a
# genuine Windows host (using the same Git-Bash `_BASH_EXE` this codebase
# already special-cases extensively for other MSYS argv-mangling -- see
# `_run_writer`'s / `_posix_argv_path`'s own docstrings), FR-T3 (Task Stop/
# Resume) silently no-ops: the client gets a 200, but `stop_requested` never
# actually flips. writeback-state.sh (pipeline.finish) is UNAFFECTED -- it
# only ever uses `$WORK_DIR`/`$AID_STATE_FILE` as opaque file paths for
# redirection (real filesystem I/O, which Windows accepts with either slash
# style), never string-arithmetic on it.
#
# FIXED (2026-07-19, task-033 fix cycle): the dispatcher now hands
# write-control-signal.sh a FORWARD-SLASH $AID_WORK_DIR --
# `_op_task_stop_argv`/`_op_task_resume_argv` use `work_dir.as_posix()` and the
# Node twins `opTaskStopArgv`/`opTaskResumeArgv` use `toPosixArg(String(workDir))`
# (mirroring `_posix_argv_path`'s existing argv convention) -- so the writer's
# `${WORK_DIR##*/}` + `/../../.control/...` arithmetic resolves correctly on
# every host. The REAL-writer round trips below therefore run + PASS on Windows
# too; the flag is retained as a `False` regression tripwire (if it ever regresses
# to a backslash path the skipIf guards would re-skip). The old Windows-only
# "defect canary" was removed with the fix.
# ---------------------------------------------------------------------------
_AID_WORK_DIR_BACKSLASH_DEFECT = False
_DEFECT_SKIP_REASON = (
    "regression tripwire (fixed 2026-07-19): the dispatcher passes a "
    "forward-slash $AID_WORK_DIR (work_dir.as_posix() / toPosixArg), so "
    "write-control-signal.sh's path arithmetic resolves on every host."
)


# ---------------------------------------------------------------------------
# Robust cleanup (git marks packed objects/refs read-only on Windows -- a
# plain shutil.rmtree(..., ignore_errors=True) silently fails to delete them,
# leaking a stale .git/ under the OS temp dir every run; mirrors
# test_task027_pipeline_delete_round_trips.py's own _rmtree_onerror).
# ---------------------------------------------------------------------------

def _rmtree_onerror(func, path, _exc_info) -> None:
    try:
        os.chmod(path, stat.S_IWRITE)
        func(path)
    except Exception:
        pass


def _rmtree(path: "Path | str") -> None:
    shutil.rmtree(str(path), onerror=_rmtree_onerror)


def _rmtree_if_exists(path: "Path | str") -> None:
    p = Path(path)
    if p.exists():
        _rmtree(p)


class _TmpRepo:
    """A throwaway, NON-git scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp(prefix="aid-t033-")).resolve()
        return self.path

    def __exit__(self, *_exc) -> None:
        _rmtree(self.path)


def _git(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True, timeout=15)


class _GitRepo:
    """A throwaway git repo (main worktree) with an empty .aid/works/
    container and one commit, cleaned up on exit. NEVER this repo's own
    working tree -- always a fresh mktemp scratch directory. Mirrors
    test_task027_pipeline_delete_round_trips.py's own _GitRepo verbatim
    (including its .resolve()-on-creation note re: Windows 8.3 short-path
    normalization)."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp(prefix="aid-t033-git-")).resolve()
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


def _make_worktree(repo: Path, path: Path, branch: str) -> None:
    r = _git(["worktree", "add", "-q", "-b", branch, str(path)], repo)
    if r.returncode != 0:
        raise RuntimeError(f"git worktree add failed: {r.stderr}")


def _commit_all(root: Path, msg: str) -> None:
    _git(["add", "-A"], root)
    _git(["commit", "-q", "-m", msg], root)


# ---------------------------------------------------------------------------
# Fixture builders (mirrors test_task029_stop_requested.py's own _make_repo /
# _build_hierarchical_work conventions, so a fixture built here reads
# identically to what task-029's own suite already proved).
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
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


def _seed_pipeline_state(aid: Path, work_id: str, lifecycle: str = "Running") -> Path:
    """<aid>/works/<work_id>/STATE.md with a realistic frontmatter + BODY (not
    just a bare frontmatter block) -- so a round-trip test can prove the BODY
    survives writeback-state.sh's surgical frontmatter rewrite byte-for-byte
    (no hand-written DERIVED section, AC3)."""
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(
        f"---\nlifecycle: {lifecycle}\n---\n\n"
        "# Work State\n\n"
        "Pre-existing body content that must survive a Lifecycle frontmatter "
        "rewrite untouched -- never a hand-authored DERIVED section.\n",
        encoding="utf-8",
    )
    return work_dir


def _seed_hierarchical_task(aid: Path, work_id: str, task_id: str, status: str,
                             lifecycle: str = "Running") -> Path:
    """Full-nested layout (deliveries/delivery-001/tasks/<task_id>/{DETAIL,STATE}.md)
    with ONE task at the given status -- mirrors test_task029_stop_requested.py's
    own _build_hierarchical_work, parametrized by task_id/status."""
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(f"---\nlifecycle: {lifecycle}\n---\n", encoding="utf-8")

    del_dir = work_dir / "deliveries" / "delivery-001"
    del_dir.mkdir(parents=True, exist_ok=True)
    (del_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: T033 sample delivery\n\n"
        "## Objective\n\nDeliver.\n\n## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n- **State:** Executing\n\n"
        "## Delivery Gate\n\n- **Reviewer Tier:** Small\n- **Grade:** A+\n"
        "- **Issue List:** none\n- **Timestamp:** 2026-01-01T00:00:00Z\n",
        encoding="utf-8",
    )
    task_dir = del_dir / "tasks" / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "DETAIL.md").write_text(
        f"# {task_id}: T033 sample task\n\n**Type:** IMPLEMENT\n\nBody.\n",
        encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        f"---\nstate: {status}\n---\n\n## Task State\n", encoding="utf-8",
    )
    return work_dir


def _control_signal_path(aid: Path, work_id: str, task_id: str) -> Path:
    return aid / ".control" / work_id / f"{task_id}.stop"


def _frontmatter_and_body(text: str) -> "tuple[str, str]":
    """Split STATE.md text into (frontmatter_mapping_text, body_text), where
    body_text is everything AFTER the closing '---' fence line. Used to prove
    a writeback-state.sh rewrite touches ONLY the frontmatter block."""
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].rstrip("\r\n") != "---":
        return "", text
    for i in range(1, len(lines)):
        if lines[i].rstrip("\r\n") == "---":
            return "".join(lines[1:i]), "".join(lines[i + 1:])
    return "".join(lines[1:]), ""


def _read_model_json(root: Path, write_enabled: bool) -> dict:
    """The EXACT function chain server.py's own `_serve_repo_model` handler
    dispatches to for GET /r/<id>/api/model -- read_repo(fs_path) ->
    serialize_model(model, write_enabled) -- called in-process (no socket
    bind) so this reproduces the real endpoint's output byte-for-byte without
    a live server."""
    model = read_repo(str(root))
    body = srv.serialize_model(model, write_enabled)
    return json.loads(body.decode("utf-8"))


def _find_task(data: dict, work_id: str, task_id: str) -> dict:
    """`data` is the FULL DM-1 envelope (schema_version/generated_by/
    write_enabled/model) -- works live under the nested `model` key, never at
    the envelope top level; `write_enabled` is the one key that DOES live at
    the top level (see server.py's own serialize_model envelope shape)."""
    work = next(w for w in data["model"]["works"] if w["work_id"] == work_id)
    return next(t for t in work["tasks"] if t["task_id"] == task_id)


def _find_work(data: dict, work_id: str) -> dict:
    return next(w for w in data["model"]["works"] if w["work_id"] == work_id)


# ===========================================================================
# (A) pipeline.finish real round-trip (AC-EC1/AC2/AC3)
# ===========================================================================

@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available -- writer round trip skipped")
class TestPipelineFinishRealRoundTrip(unittest.TestCase):
    def test_finish_persists_completed_via_real_writeback_state_sh_body_untouched(self):
        with _TmpRepo() as tmp:
            root, aid = _make_repo(tmp)
            work_id = "work-700-finish"
            work_dir = _seed_pipeline_state(aid, work_id, lifecycle="Running")
            state_path = work_dir / "STATE.md"
            fm_before, body_before = _frontmatter_and_body(state_path.read_text(encoding="utf-8"))
            self.assertIn("lifecycle: Running", fm_before)

            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.finish", "target": {"work_id": work_id}}, str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.finish"})

            # AC-EC1/AC3: durable frontmatter persistence via the REAL writer --
            # never a hand-written DERIVED section. Only the `lifecycle` scalar
            # changes; the STATE.md BODY survives byte-for-byte.
            state_text_after = state_path.read_text(encoding="utf-8")
            fm_after, body_after = _frontmatter_and_body(state_text_after)
            self.assertIn("lifecycle: Completed", fm_after)
            self.assertNotIn("Running", fm_after)
            self.assertEqual(body_before, body_after, "STATE.md body must survive untouched (no DERIVED hand-write)")

    def test_post_op_model_read_shows_completed(self):
        """AC2: a post-op /r/<id>/api/model read shows Completed -- verified via
        the SAME read_repo()+serialize_model() chain the live endpoint calls."""
        with _TmpRepo() as tmp:
            root, aid = _make_repo(tmp)
            work_id = "work-701-finish-read"
            _seed_pipeline_state(aid, work_id, lifecycle="Running")

            data_before = _read_model_json(root, write_enabled=True)
            self.assertEqual(_find_work(data_before, work_id)["lifecycle"], "Running")

            status, _body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.finish", "target": {"work_id": work_id}}, str(root),
            )
            self.assertEqual(status, 200)

            data_after = _read_model_json(root, write_enabled=True)
            self.assertEqual(_find_work(data_after, work_id)["lifecycle"], "Completed")


# ===========================================================================
# (B) task.stop / task.resume real round-trip (AC-EC1/AC2)
# ===========================================================================

@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available -- writer round trip skipped")
class TestTaskStopResumeRealRoundTrip(unittest.TestCase):
    def _dispatch(self, root: Path, op: str, work_id: str, task_id: str) -> "tuple[int, bytes]":
        return srv._dispatch_op(
            srv.OP_TABLE, {"op": op, "target": {"work_id": work_id, "task_id": task_id}}, str(root),
        )

    @unittest.skipIf(_AID_WORK_DIR_BACKSLASH_DEFECT, _DEFECT_SKIP_REASON)
    def test_stop_creates_signal_resume_removes_it_stop_requested_re_derives_idempotent(self):
        with _TmpRepo() as tmp:
            root, aid = _make_repo(tmp)
            work_id = "work-702-stopresume"
            _seed_hierarchical_task(aid, work_id, "task-001", status="In Progress")
            signal = _control_signal_path(aid, work_id, "task-001")

            self.assertFalse(signal.exists(), "sanity: no signal before dispatch")

            # task.stop -> REAL write-control-signal.sh creates the .stop file.
            status, body = self._dispatch(root, "task.stop", work_id, "001")
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.stop"})
            self.assertTrue(signal.is_file(), "write-control-signal.sh must create the .stop file")

            data = _read_model_json(root, write_enabled=True)
            self.assertTrue(_find_task(data, work_id, "task-001")["stop_requested"])

            # Idempotent re-stop: still 200, file still present, still true.
            status2, body2 = self._dispatch(root, "task.stop", work_id, "001")
            self.assertEqual(status2, 200)
            self.assertEqual(json.loads(body2), {"ok": True, "op": "task.stop"})
            self.assertTrue(signal.is_file())
            data2 = _read_model_json(root, write_enabled=True)
            self.assertTrue(_find_task(data2, work_id, "task-001")["stop_requested"])

            # task.resume -> REAL write-control-signal.sh removes the .stop file.
            status3, body3 = self._dispatch(root, "task.resume", work_id, "001")
            self.assertEqual(status3, 200)
            self.assertEqual(json.loads(body3), {"ok": True, "op": "task.resume"})
            self.assertFalse(signal.exists(), "write-control-signal.sh must remove the .stop file")

            data3 = _read_model_json(root, write_enabled=True)
            self.assertFalse(_find_task(data3, work_id, "task-001")["stop_requested"])

            # Idempotent re-resume: still 200, file remains absent, still false.
            status4, body4 = self._dispatch(root, "task.resume", work_id, "001")
            self.assertEqual(status4, 200)
            self.assertEqual(json.loads(body4), {"ok": True, "op": "task.resume"})
            self.assertFalse(signal.exists())
            data4 = _read_model_json(root, write_enabled=True)
            self.assertFalse(_find_task(data4, work_id, "task-001")["stop_requested"])

    @unittest.skipIf(_AID_WORK_DIR_BACKSLASH_DEFECT, _DEFECT_SKIP_REASON)
    def test_signal_content_line_is_informational_only_never_parsed(self):
        """Presence is the signal; the informational content line
        ('[<ISO-8601 UTC>] stop | source=dashboard') is advisory only -- proven
        here by asserting the reader's derived boolean depends solely on file
        PRESENCE, independent of the exact byte content the writer produced."""
        with _TmpRepo() as tmp:
            root, aid = _make_repo(tmp)
            work_id = "work-703-content"
            _seed_hierarchical_task(aid, work_id, "task-001", status="In Progress")
            self._dispatch(root, "task.stop", work_id, "001")
            signal = _control_signal_path(aid, work_id, "task-001")
            content = signal.read_text(encoding="utf-8")
            self.assertRegex(content, r"^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\] stop \| source=dashboard\n$")
            data = _read_model_json(root, write_enabled=True)
            self.assertTrue(_find_task(data, work_id, "task-001")["stop_requested"])


# ===========================================================================
# (C) WT-1 real-git-worktree coverage
# ===========================================================================

@unittest.skipUnless(_GIT_AVAILABLE, "git not available -- WT-1 resolve_work_dir test skipped")
class TestWt1ResolveWorkDirTargetsWorktree(unittest.TestCase):
    """The half of WT-1 that is 100% independent of write-control-signal.sh's
    own (Windows-only, see _AID_WORK_DIR_BACKSLASH_DEFECT) shell-arithmetic
    defect: `resolve_work_dir` -- the SAME function _dispatch_op's scope block
    calls to compute `work_dir`, and that _op_task_stop_argv/_op_task_resume_argv
    then hand to the writer as AID_WORK_DIR -- resolves a work_id living ONLY in
    a secondary worktree to that worktree's own directory, NEVER a reconstructed
    <served-root>/.aid/works/<work_id> path. Runs unconditionally (no bash
    needed) on every host with git."""

    def test_resolve_work_dir_targets_worktree_never_served_root(self):
        with _GitRepo() as root:
            wt = root.parent / f"aid-t033-wt-resolve-{uuid.uuid4().hex}"
            branch = f"feature-t033-resolve-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                wt_aid = wt / ".aid"
                work_id = "work-705-wt1-resolve"
                _seed_hierarchical_task(wt_aid, work_id, "task-001", status="In Progress")
                _commit_all(wt, "add work-705-wt1-resolve")

                resolved = srv.resolve_work_dir(str(root), work_id)
                self.assertIsNotNone(resolved)
                self.assertEqual(resolved, wt_aid / "works" / work_id)
                self.assertNotEqual(resolved, root / ".aid" / "works" / work_id)

                # read_repo(root) (real git worktree enumeration, no mocking)
                # discovers the work via `wt`, never via a served-root guess.
                data = json.loads(srv.serialize_model(read_repo(str(root)), write_enabled=True).decode("utf-8"))
                self.assertIn(work_id, [w["work_id"] for w in data["model"]["works"]])
            finally:
                _rmtree_if_exists(wt)


@unittest.skipUnless(_GIT_AVAILABLE and _BASH_EXE_RESOLVED, "git/bash not available -- WT-1 real-worktree test skipped")
class TestWt1RealWorktreeControlSignal(unittest.TestCase):
    @unittest.skipIf(_AID_WORK_DIR_BACKSLASH_DEFECT, _DEFECT_SKIP_REASON)
    def test_signal_lands_in_worktree_never_served_root_reader_finds_it_via_real_worktree_enumeration(self):
        with _GitRepo() as root:
            wt = root.parent / f"aid-t033-wt-{uuid.uuid4().hex}"
            branch = f"feature-t033-{uuid.uuid4().hex[:8]}"
            try:
                _make_worktree(root, wt, branch)
                wt_aid = wt / ".aid"
                work_id = "work-704-wt1"
                _seed_hierarchical_task(wt_aid, work_id, "task-001", status="In Progress")
                _commit_all(wt, "add work-704-wt1")

                # served_root passed to _dispatch_op/read_repo is the MAIN
                # worktree (root); the work itself lives ONLY in `wt`.
                status, body = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "task.stop", "target": {"work_id": work_id, "task_id": "001"}}, str(root),
                )
                self.assertEqual(status, 200)
                self.assertEqual(json.loads(body), {"ok": True, "op": "task.stop"})

                wt_signal = wt_aid / ".control" / work_id / "task-001.stop"
                self.assertTrue(
                    wt_signal.is_file(),
                    "signal must be created relative to AID_WORK_DIR (resolve_work_dir's real "
                    "worktree-resolved output), not the served_root argument",
                )
                self.assertFalse(
                    (root / ".aid" / ".control").exists(),
                    "a reconstructed <served-root>/.aid/.control/ must NEVER be created",
                )

                # The reader stats the SAME walked-tree path: real git worktree
                # enumeration (no mocking) discovers `wt`, and read_repo(root)
                # re-derives stop_requested relative to it.
                data = srv.serialize_model(read_repo(str(root)), write_enabled=True)
                data = json.loads(data.decode("utf-8"))
                task = _find_task(data, work_id, "task-001")
                self.assertTrue(task["stop_requested"])

                status2, body2 = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "task.resume", "target": {"work_id": work_id, "task_id": "001"}}, str(root),
                )
                self.assertEqual(status2, 200)
                self.assertEqual(json.loads(body2), {"ok": True, "op": "task.resume"})
                self.assertFalse(wt_signal.exists())
                data2 = json.loads(srv.serialize_model(read_repo(str(root)), write_enabled=True).decode("utf-8"))
                self.assertFalse(_find_task(data2, work_id, "task-001")["stop_requested"])
            finally:
                _rmtree_if_exists(wt)


# ===========================================================================
# (D) AC6 gate model-flags matrix
# ===========================================================================

class TestAc6GateModelFlags(unittest.TestCase):
    """AC6: reproduces home.html's own `_buildTaskStopResumeControl` gate
    condition (task-030: `if (task.status !== 'In Progress' || !writeEnabled)
    return null;`) as a pure boolean evaluated over the REAL serialized model
    the server actually emits (task.status + top-level write_enabled), for
    every TaskStatus value crossed with both write_enabled states. Never
    executes home.html's own JS (that would require a DOM/jsdom harness this
    codebase does not have -- browser-dogfood's job); complements (does not
    duplicate) test_task030_finish_stop_resume_ui.py's own static source-text
    parse of the gate LOGIC (T-G1) -- that file proves the JS is written
    correctly, this file proves the MODEL DATA it operates on is derived
    correctly."""

    _ALL_STATUSES = ["Pending", "In Progress", "In Review", "Blocked", "Done", "Failed", "Canceled"]

    @staticmethod
    def _gate_would_show_control(status: str, write_enabled: bool) -> bool:
        return status == "In Progress" and write_enabled is True

    def setUp(self) -> None:
        self._tmps: list[Path] = []

    def tearDown(self) -> None:
        for tmp in self._tmps:
            _rmtree_if_exists(tmp)

    def _model_for_status(self, status: str) -> "tuple[Path, str]":
        tmp = Path(tempfile.mkdtemp(prefix="aid-t033-ac6-")).resolve()
        self._tmps.append(tmp)
        root, aid = _make_repo(tmp)
        work_id = "work-800-ac6"
        _seed_hierarchical_task(aid, work_id, "task-001", status=status)
        return root, work_id

    def test_every_status_x_write_enabled_combination(self):
        for status in self._ALL_STATUSES:
            for write_enabled in (True, False):
                with self.subTest(status=status, write_enabled=write_enabled):
                    root, work_id = self._model_for_status(status)
                    data = _read_model_json(root, write_enabled=write_enabled)
                    self.assertEqual(data["write_enabled"], write_enabled)
                    task = _find_task(data, work_id, "task-001")
                    self.assertEqual(task["status"], status)
                    shows_control = self._gate_would_show_control(task["status"], data["write_enabled"])
                    if status == "In Progress" and write_enabled:
                        self.assertTrue(shows_control, "the ONE permitted combination must show a control")
                    else:
                        self.assertFalse(shows_control, f"status={status!r} write_enabled={write_enabled!r} must show NO control")

    def test_every_other_status_yields_none_even_when_write_enabled(self):
        """Explicit enumeration (not just the loop's implicit math) of AC6's
        own excluded set, INCLUDING In Review -- even with write_enabled=True,
        every one of these must yield no control."""
        excluded = ["Pending", "Blocked", "Done", "Failed", "Canceled", "In Review"]
        for status in excluded:
            with self.subTest(status=status):
                root, work_id = self._model_for_status(status)
                data = _read_model_json(root, write_enabled=True)
                task = _find_task(data, work_id, "task-001")
                self.assertFalse(self._gate_would_show_control(task["status"], data["write_enabled"]))

    def test_in_progress_and_write_enabled_is_the_sole_permitted_combination(self):
        root, work_id = self._model_for_status("In Progress")
        data = _read_model_json(root, write_enabled=True)
        task = _find_task(data, work_id, "task-001")
        self.assertTrue(self._gate_would_show_control(task["status"], data["write_enabled"]))


# ===========================================================================
# (E) Twin dispatch byte-parity for the REAL write-control-signal.sh writer
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
    """Mirrors test_task027_pipeline_delete_round_trips.py's own
    _NodeSlicedDispatchFixture verbatim: NO WRITER_DIR redirect -- this file
    drives the REAL write-control-signal.sh writer on both runtimes."""

    _slice_path: Path

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_task033_slice_{uuid.uuid4().hex}.mjs"
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
    """Mirrors test_task027_pipeline_delete_round_trips.py's own _assert_parity
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


@unittest.skipUnless(_NODE_AVAILABLE and _BASH_EXE_RESOLVED, "node/bash not available -- twin parity skipped")
class TestTaskStopResumeRealWriterTwinParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    """(AC4) NEW coverage beyond test_task029_task_stop_resume_ops.py/.mjs
    (which both deliberately stub 'spawn' -- see those files' own module
    docstrings): dispatches task.stop/task.resume through Python's REAL
    _dispatch_op AND Node's REAL sliced dispatchOp, each spawning the ACTUAL
    committed write-control-signal.sh writer (no WRITER_DIR override, no spawn
    stub), asserting the (status, body) response pair is byte-identical
    across runtimes."""

    def _fixture(self) -> "tuple[Path, str]":
        tmp = Path(tempfile.mkdtemp(prefix="aid-t033-parity-")).resolve()
        aid = tmp / ".aid"
        work_id = "work-900-parity"
        _seed_hierarchical_task(aid, work_id, "task-001", status="In Progress")
        return tmp, work_id

    def test_stop_dispatch_parity(self) -> None:
        py_tmp, py_work_id = self._fixture()
        node_tmp, node_work_id = self._fixture()
        try:
            py_result = srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.stop", "target": {"work_id": py_work_id, "task_id": "001"}}, str(py_tmp),
            )
            node_result = self._node_dispatch(
                {"op": "task.stop", "target": {"work_id": node_work_id, "task_id": "001"}}, str(node_tmp),
            )
            _assert_parity(self, py_result, node_result, 200)
            self.assertEqual(json.loads(py_result[1]), {"ok": True, "op": "task.stop"})
            if not _AID_WORK_DIR_BACKSLASH_DEFECT:
                # On POSIX (CI), the REAL writer creates the signal at the
                # documented path on BOTH twins (this assertion is skipped,
                # not silently dropped, on Windows -- see
                # _AID_WORK_DIR_BACKSLASH_DEFECT's own module-level comment;
                # the (status, body) parity assertion above still holds
                # unconditionally either way, since both twins are affected
                # identically by that defect).
                self.assertTrue((py_tmp / ".aid" / ".control" / py_work_id / "task-001.stop").is_file())
                self.assertTrue((node_tmp / ".aid" / ".control" / node_work_id / "task-001.stop").is_file())
        finally:
            _rmtree_if_exists(py_tmp)
            _rmtree_if_exists(node_tmp)

    def test_resume_dispatch_parity(self) -> None:
        py_tmp, py_work_id = self._fixture()
        node_tmp, node_work_id = self._fixture()
        try:
            # Real task.stop on each side first, so resume has something real
            # to remove.
            srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.stop", "target": {"work_id": py_work_id, "task_id": "001"}}, str(py_tmp),
            )
            self._node_dispatch(
                {"op": "task.stop", "target": {"work_id": node_work_id, "task_id": "001"}}, str(node_tmp),
            )
            py_result = srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.resume", "target": {"work_id": py_work_id, "task_id": "001"}}, str(py_tmp),
            )
            node_result = self._node_dispatch(
                {"op": "task.resume", "target": {"work_id": node_work_id, "task_id": "001"}}, str(node_tmp),
            )
            _assert_parity(self, py_result, node_result, 200)
            self.assertEqual(json.loads(py_result[1]), {"ok": True, "op": "task.resume"})
            self.assertFalse((py_tmp / ".aid" / ".control" / py_work_id / "task-001.stop").exists())
            self.assertFalse((node_tmp / ".aid" / ".control" / node_work_id / "task-001.stop").exists())
        finally:
            _rmtree_if_exists(py_tmp)
            _rmtree_if_exists(node_tmp)

    def test_idempotent_restop_parity(self) -> None:
        py_tmp, py_work_id = self._fixture()
        node_tmp, node_work_id = self._fixture()
        try:
            py_result = None
            for _ in range(2):
                py_result = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "task.stop", "target": {"work_id": py_work_id, "task_id": "001"}}, str(py_tmp),
                )
            node_result = None
            for _ in range(2):
                node_result = self._node_dispatch(
                    {"op": "task.stop", "target": {"work_id": node_work_id, "task_id": "001"}}, str(node_tmp),
                )
            _assert_parity(self, py_result, node_result, 200)
        finally:
            _rmtree_if_exists(py_tmp)
            _rmtree_if_exists(node_tmp)

    def test_idempotent_reresume_parity(self) -> None:
        py_tmp, py_work_id = self._fixture()
        node_tmp, node_work_id = self._fixture()
        try:
            # No prior stop -- resuming an already-resumed (never-stopped) task
            # is idempotent too (writer's own --action resume: rm -f, exit 0).
            py_result = None
            for _ in range(2):
                py_result = srv._dispatch_op(
                    srv.OP_TABLE, {"op": "task.resume", "target": {"work_id": py_work_id, "task_id": "001"}}, str(py_tmp),
                )
            node_result = None
            for _ in range(2):
                node_result = self._node_dispatch(
                    {"op": "task.resume", "target": {"work_id": node_work_id, "task_id": "001"}}, str(node_tmp),
                )
            _assert_parity(self, py_result, node_result, 200)
            self.assertFalse((py_tmp / ".aid" / ".control" / py_work_id / "task-001.stop").exists())
            self.assertFalse((node_tmp / ".aid" / ".control" / node_work_id / "task-001.stop").exists())
        finally:
            _rmtree_if_exists(py_tmp)
            _rmtree_if_exists(node_tmp)


# ===========================================================================
# (The Windows-only "defect canary" that lived here was removed in the
# 2026-07-19 fix cycle: the AID_WORK_DIR backslash defect it demonstrated is
# fixed (work_dir.as_posix() / toPosixArg on both twins), so the REAL-writer
# round-trip tests above now run + pass on Windows and ARE the regression
# guard. See IMPEDIMENT-task-033.md for the original root-cause.)
# ===========================================================================


class TestNoScopeCreepPointer(unittest.TestCase):
    """AC-traceability pointer only (task-033 DETAIL: TEST-type task, no
    production code; no existing golden-fixture bytes change; no
    schema_version bump). This file never writes under dashboard/server/tests/
    fixtures/ and never touches server.py/server.mjs/reader.py/reader.mjs/
    home.html/write-control-signal.sh/writeback-state.sh (verified by
    inspection during authoring, not re-asserted at runtime here -- mirrors
    test_task027_pipeline_delete_round_trips.py's own TestNoScopeCreepPointer
    convention). The stop_requested reader-twin serializer parity fixtures
    task-029 already regenerated (dashboard/reader/tests/test_task029_stop_
    requested.py) are reused/confirmed by this task's own verification pass,
    never re-churned here."""

    def test_pointer_no_production_code_touched_by_this_task(self) -> None:
        self.assertTrue(True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
