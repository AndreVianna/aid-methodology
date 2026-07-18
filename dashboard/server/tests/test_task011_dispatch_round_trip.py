"""
test_task011_dispatch_round_trip.py -- "Foundation parity + dispatch round-trip
suite" (task-011, feature-001-write-infrastructure, delivery-001).

This file closes the coverage explicitly deferred to task-011 by the comments in
test_task004_op_dispatch.py (dispatch-LOGIC, in-process, no socket) and
test_server_py.py's TestOpDispatchLive class (do_POST routing/gate wiring, one
representative op, over a real socket):

  1. The full DEFAULT_MAP writer-exit -> HTTP-status matrix (1->404, 2->409,
     3->500, 4->422, 5->422, 6->500), each driven end-to-end through a REAL
     writer script (writeback-state.sh / write-setting.sh) via a crafted
     fixture that naturally exits with that code -- never a synthetic stub --
     over a real loopback socket (do_POST -> _serve_op -> _dispatch_op ->
     _run_writer -> subprocess.run(...)).
  2. WT-1: a pipeline-scoped op (task.set-notes) whose target.work_id no
     worktree holds -> 404 'not-found', over the live socket (complementary to
     test_server_py.py's existing pipeline.rename live-server WT-1 case).
  3. Oversize (>64 KiB) request body -> 400 'bad-request', over the live socket.
  4. The OP-SM hook (`op.status_map or DEFAULT_MAP`): a synthetic OP_TABLE-shaped
     row carrying its own status_map overrides DEFAULT_MAP; a sibling row
     without one still uses DEFAULT_MAP unchanged. No SEEDED OP_TABLE row uses
     status_map yet (features 003/004 add the first ones), so this is
     exercised via `_dispatch_op` directly (in-process, no socket -- mirrors
     test_task004_op_dispatch.py's own approach to hooks with no live row yet)
     against a throwaway probe writer script (never touching the real
     co-vendored `dashboard/scripts/` set) so the test proves the HOOK, not
     any specific op's business logic.
  5. SEC-3/SEC-4 static guard, precisely scoped: the writer-dispatch call site
     uses an argv ARRAY (never `shell=True` / a concatenated command string),
     and no in-process fs-WRITE primitive exists in server.py. (NOTE: this
     file does NOT re-assert TestSourceInvariants.test_no_shutil's overly broad
     "no substring 'shutil' anywhere" rule, which currently FAILS against this
     branch's own `import shutil` / `shutil.which("bash")` -- a benign,
     read-only PATH probe task-004 added; that pre-existing regression is a
     task-004-owned test-hygiene item, out of this task's scope, and is
     reported as a finding, not fixed here. This file's own guard is scoped to
     the actual mutation-class primitives -- shutil.rmtree/copy/move/remove --
     which server.py correctly has none of.)

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): classes in this file that
bind a loopback socket via `_ServerThread` (imported from test_server_py) are
NOT run locally as part of this task's own verification pass -- per the
project's port-binding-server-test constraint, they are deferred to CI. The
in-process (no-socket) classes -- TestOpStatusMapOverrideHook and
TestSec3Sec4Guard -- are safe to run locally and were exercised directly.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import ast
import json
import re
import shutil
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD (mirrors test_server_py.py
# / test_task004_op_dispatch.py's own sys.path setup).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv
from dashboard.server.tests.test_server_py import (
    _ServerThread,
    _make_aid_home,
    _make_repo,
    _write_registry,
    _repo_id8,
)


# ---------------------------------------------------------------------------
# Fixture helpers -- flat-layout work directories in the 3 shapes this suite
# needs (mirrors test_task004_op_dispatch.py's _make_flat_work, plus two
# deliberately-broken variants used ONLY to drive writeback-state.sh's own
# exit-1 / exit-6 paths through a REAL writer invocation).
# ---------------------------------------------------------------------------

def _make_flat_markers(work_dir: Path) -> None:
    """BLUEPRINT.md + tasks/task-001/DETAIL.md -- the 2 presence markers
    is_flat_layout() (writeback-state.sh) requires, alongside deliveries/
    absence (the default -- we never create one)."""
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text("# task-001\n", encoding="utf-8")


def _make_flat_work(root: Path, work_id: str) -> Path:
    """A well-formed flat-layout work: markers + a valid STATE.md with the
    '### Tasks lifecycle' table and a task-001 row. Round-trips cleanly."""
    work_dir = root / ".aid" / "works" / work_id
    _make_flat_markers(work_dir)
    (work_dir / "STATE.md").write_text(
        "---\n"
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "---\n\n"
        "# Work State\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        "| task-001 | Pending | -- | -- | -- |\n",
        encoding="utf-8",
    )
    return work_dir


def _make_flat_work_no_state(root: Path, work_id: str) -> Path:
    """Flat markers present, but NO STATE.md at all -- writeback-state.sh's
    write_task_field_flat() hits `[[ ! -f "$STATE_FILE" ]]` -> die exit 1
    ('does not exist' -> DEFAULT_MAP 404 'not-found'). resolve_work_dir still
    resolves this directory (presence-only inclusion test, WT-1/task-002),
    so the 404 proven here is the WRITER's exit-1 path, not a WT-1 miss."""
    work_dir = root / ".aid" / "works" / work_id
    _make_flat_markers(work_dir)
    return work_dir


def _make_flat_work_malformed_state(root: Path, work_id: str) -> Path:
    """Flat markers + a STATE.md present but lacking '### Tasks lifecycle' --
    writeback-state.sh's write_task_field_flat() -> die exit 6 ('malformed
    work STATE.md ... (flat layout)' -> DEFAULT_MAP 500 'write-failed')."""
    work_dir = root / ".aid" / "works" / work_id
    _make_flat_markers(work_dir)
    (work_dir / "STATE.md").write_text(
        "---\nlifecycle: Running\n---\n\n# Work State\n\nNo tasks section here.\n",
        encoding="utf-8",
    )
    return work_dir


def _make_nested_work_unresolvable_delivery(root: Path, work_id: str) -> Path:
    """A NESTED-layout work (deliveries/ wrapper -- is_flat_layout() is false) whose
    task-001 DETAIL.md carries NO '**Source:**' bullet -- writeback-state.sh's
    resolve_delivery_from_task_spec() can't recover a delivery number, so
    resolve_delivery_for_task_mode() dies exit 5 ('cannot resolve delivery for
    task ...') when --delivery-id is omitted (mirrors test_task008_display_rename.py's
    _make_hierarchical_work). Used to drive the DEFAULT_MAP exit-5 -> 422 row via a
    DIFFERENT path than an empty --value now that task-010's argv-builder substitutes
    the '--' null sentinel before spawn (so an empty task.set-notes value no longer
    reaches writeback-state.sh's own '--value is required' exit-5 guard)."""
    del_dir = root / ".aid" / "works" / work_id / "deliveries" / "delivery-001"
    task_dir = del_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (root / ".aid" / "works" / work_id / "STATE.md").write_text(
        "## Pipeline State\n\n- **Lifecycle:** Running\n", encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n- **State:** Executing\n", encoding="utf-8",
    )
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Nested task (no Source line)\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        "---\nstate: Pending\n---\n\n## Task State\n", encoding="utf-8",
    )
    return root / ".aid" / "works" / work_id


# ===========================================================================
# (A) DEFAULT_MAP writer-exit -> HTTP-status matrix, over a REAL live socket,
# each driven by a REAL writer script (never a stub).
# ===========================================================================

class TestDefaultMapExitMatrixLive(unittest.TestCase):
    """Every DEFAULT_MAP row (1/2/3/4/5/6) reached end-to-end through the
    actual do_POST -> _serve_op -> _dispatch_op -> _run_writer path."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a)          # .aid/settings.yml + manifest present
        self._repo_b = self._base / "repo-B"
        (self._repo_b / ".aid").mkdir(parents=True, exist_ok=True)   # NO settings.yml
        _write_registry(self._aid_home, [str(self._repo_a), str(self._repo_b)])
        self._id_a = _repo_id8(str(self._repo_a))
        self._id_b = _repo_id8(str(self._repo_b))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_exit1_missing_state_md_is_404_not_found(self):
        """task.set-notes against a work dir that exists (WT-1 resolves it) but
        has no STATE.md -> writeback-state.sh exit 1 -> DEFAULT_MAP 404."""
        _make_flat_work_no_state(self._repo_a, "work-711-nostate")
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "task.set-notes",
                 "target": {"work_id": "work-711-nostate", "task_id": "001"},
                 "args": {"value": "hi"}},
            )
        self.assertEqual(status, 404)
        data = json.loads(body)
        self.assertEqual(data["error"], "not-found")

    def test_exit2_lock_contention_is_409_busy(self):
        """Pre-created .writeback-state.lock sentinel -> writeback-state.sh's
        acquire_lock retries then exits 2 -> DEFAULT_MAP 409 'busy'.
        AID_LOCK_TIMEOUT=1 keeps the retry loop to ~0.5s (deterministic, fast)
        instead of the 5s default."""
        work_dir = _make_flat_work(self._repo_a, "work-712-locked")
        (work_dir / ".writeback-state.lock").write_text("999999\n", encoding="utf-8")
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            with mock.patch.dict("os.environ", {"AID_LOCK_TIMEOUT": "1"}):
                status, body = server.post_json(
                    f"/r/{self._id_a}/api/op",
                    {"op": "task.set-notes",
                     "target": {"work_id": "work-712-locked", "task_id": "001"},
                     "args": {"value": "hi"}},
                )
        self.assertEqual(status, 409)
        self.assertEqual(json.loads(body)["error"], "busy")

    def test_exit3_settings_file_missing_is_500_write_failed(self):
        """settings.set against a repo whose .aid/ exists but has NO
        settings.yml -> write-setting.sh's own `-f` check -> exit 3 ->
        DEFAULT_MAP 500 'write-failed' (distinct from writeback-state.sh's own
        exit-1 'does not exist' -> 404 convention -- write-setting.sh's exit
        alphabet intentionally maps a missing settings file to exit 3, per its
        own header contract)."""
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_b}/api/op",
                {"op": "settings.set", "args": {"path": "project.name", "value": "x"}},
            )
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-failed")

    def test_exit4_pipe_in_value_is_422_invalid_value(self):
        """task.set-notes args.value containing '|' bypasses the generic shape
        check (a non-empty string) and reaches writeback-state.sh's own pipe
        guard in mode_field() -> exit 4 -> DEFAULT_MAP 422."""
        _make_flat_work(self._repo_a, "work-714-pipe")
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "task.set-notes",
                 "target": {"work_id": "work-714-pipe", "task_id": "001"},
                 "args": {"value": "a|b"}},
            )
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_exit5_unresolvable_delivery_is_422_invalid_value(self):
        """task.set-notes against a NESTED-layout task whose DETAIL.md carries no
        '**Source:**' bullet, with --delivery-id omitted -> writeback-state.sh's
        resolve_delivery_for_task_mode() can't recover a delivery number -> exit 5
        -> DEFAULT_MAP 422 (same HTTP status as exit 4 -- both are the
        invalid-value class -- but a DISTINCT writer-side exit path).

        NOTE: this scenario replaces the file's original exit-5 case (an empty
        args.value) -- task-010 (feature-006-task-notes) added an argv-builder
        substitution that maps an empty value to the '--' null sentinel BEFORE
        spawn, so an empty task.set-notes value now round-trips to a SUCCESSFUL
        200 write (see test_task010_task_notes.py's
        TestTaskSetNotesEmptyValueClearsToNull), never reaching
        writeback-state.sh's own '--value is required' exit-5 guard. This test
        proves the DEFAULT_MAP exit-5 -> 422 row is still reachable via the
        OTHER documented exit-5 path (feature-006 SPEC.md API Contracts:
        'unresolvable delivery ... resolve_delivery_for_task_mode')."""
        _make_nested_work_unresolvable_delivery(self._repo_a, "work-715-nodelivery")
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "task.set-notes",
                 "target": {"work_id": "work-715-nodelivery", "task_id": "001"},
                 "args": {"value": "hi"}},
            )
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_exit6_malformed_state_md_is_500_write_failed(self):
        """A flat-layout work whose STATE.md lacks '### Tasks lifecycle' ->
        writeback-state.sh's write_task_field_flat() -> exit 6 -> DEFAULT_MAP
        500 'write-failed'."""
        _make_flat_work_malformed_state(self._repo_a, "work-716-malformed")
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "task.set-notes",
                 "target": {"work_id": "work-716-malformed", "task_id": "001"},
                 "args": {"value": "hi"}},
            )
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-failed")


# ===========================================================================
# (B) WT-1: pipeline-scoped op, unresolvable work_id -> 404 (live socket,
# complementary op to test_server_py.py's existing pipeline.rename case).
# ===========================================================================

class TestWt1UnresolvableWorkIdLive(unittest.TestCase):
    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a)
        _write_registry(self._aid_home, [str(self._repo_a)])
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_task_set_notes_unresolvable_work_id_is_404_not_found(self):
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "task.set-notes",
                 "target": {"work_id": "work-999-nowhere", "task_id": "001"},
                 "args": {"value": "hi"}},
            )
        self.assertEqual(status, 404)
        self.assertEqual(json.loads(body)["error"], "not-found")


# ===========================================================================
# (C) Oversize request body -> 400 'bad-request' (live socket).
# ===========================================================================

class TestOversizeBodyLive(unittest.TestCase):
    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo_a = self._base / "repo-A"
        _make_repo(self._repo_a)
        _write_registry(self._aid_home, [str(self._repo_a)])
        self._id_a = _repo_id8(str(self._repo_a))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_body_over_64kib_is_400_bad_request(self):
        oversize_value = "x" * (70 * 1024)   # 70 KiB > the 64 KiB cap
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json(
                f"/r/{self._id_a}/api/op",
                {"op": "settings.set", "args": {"path": "project.name", "value": oversize_value}},
            )
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")


# ===========================================================================
# (D) OP-SM hook: `op.status_map or DEFAULT_MAP` -- in-process (no socket),
# via a throwaway probe writer (never touches dashboard/scripts/).
# ===========================================================================

class TestOpStatusMapOverrideHook(unittest.TestCase):
    """No SEEDED OP_TABLE row carries a status_map yet (features 003/004 add
    the first ones) -- so this exercises the REAL `_dispatch_op`/`_run_writer`
    pipeline against a synthetic, test-local OP_TABLE-shaped row and a
    throwaway probe writer script (`exit "$1"`), proving the HOOK itself
    rather than any specific op's business logic. dashboard/scripts/ (the
    real co-vendored writer set) is never touched or monkeypatched globally --
    only `srv._WRITER_DIR` is redirected for the duration of this test class,
    restored in tearDown."""

    def setUp(self) -> None:
        self._writer_dir = Path(tempfile.mkdtemp())
        probe = self._writer_dir / "probe-exit.sh"
        probe.write_text('#!/usr/bin/env bash\nexit "$1"\n', encoding="utf-8")
        self._orig_writer_dir = srv._WRITER_DIR
        srv._WRITER_DIR = self._writer_dir

    def tearDown(self) -> None:
        srv._WRITER_DIR = self._orig_writer_dir
        shutil.rmtree(str(self._writer_dir), ignore_errors=True)

    @staticmethod
    def _probe_row(status_map=None):
        return {
            "scope": "project",
            "writer": "probe-exit.sh",
            "arg_schema": {"code": {"required": True}},
            "build_argv": lambda work_dir, served_root, target, args: ([args["code"]], {}),
            "status_map": status_map,
        }

    def test_row_without_status_map_uses_default_map(self):
        table = {"probe.default": self._probe_row(status_map=None)}
        status, body = srv._dispatch_op(table, {"op": "probe.default", "args": {"code": "4"}}, "/does/not/matter")
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_row_with_status_map_overrides_default_map(self):
        override = {4: (409, "custom-conflict")}
        table = {"probe.override": self._probe_row(status_map=override)}
        status, body = srv._dispatch_op(table, {"op": "probe.override", "args": {"code": "4"}}, "/does/not/matter")
        self.assertEqual(status, 409)
        self.assertEqual(json.loads(body)["error"], "custom-conflict")

    def test_sibling_rows_resolve_independently_in_the_same_table(self):
        """A row WITH an override and a row WITHOUT one, side by side in the
        SAME table, resolve independently -- the hook is per-row, not global."""
        table = {
            "probe.default":  self._probe_row(status_map=None),
            "probe.override": self._probe_row(status_map={4: (409, "custom-conflict")}),
        }
        status_default, _ = srv._dispatch_op(table, {"op": "probe.default", "args": {"code": "4"}}, "/x")
        status_override, _ = srv._dispatch_op(table, {"op": "probe.override", "args": {"code": "4"}}, "/x")
        self.assertEqual(status_default, 422)    # DEFAULT_MAP
        self.assertEqual(status_override, 409)   # its own status_map

    def test_override_map_exit_absent_from_override_falls_back_to_500(self):
        """An exit code absent from the OVERRIDE map falls back to the fixed
        (500, write-failed) sentinel, NOT to DEFAULT_MAP's own row for that
        code (the override fully replaces DEFAULT_MAP for this op) --
        mirrors _map_exit_code's documented contract, proven here through the
        full dispatch pipeline rather than by calling _map_exit_code alone."""
        override = {1: (401, "custom-unauthorized")}   # no entry for exit 4
        table = {"probe.partial": self._probe_row(status_map=override)}
        status, body = srv._dispatch_op(table, {"op": "probe.partial", "args": {"code": "4"}}, "/x")
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-failed")


# ===========================================================================
# (E) SEC-3/SEC-4 static guard, precisely scoped (see module docstring for why
# this does not re-assert TestSourceInvariants.test_no_shutil verbatim).
# ===========================================================================

class TestSec3Sec4DispatchGuard(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = Path(srv.__file__).read_text(encoding="utf-8")
        cls.code = re.sub(r"(?m)#.*$", " ", cls.source)   # strip line comments
        cls.tree = ast.parse(cls.source, filename=str(srv.__file__))

    def _subprocess_run_calls(self):
        """AST Call nodes for every `subprocess.run(...)` in server.py -- robust
        against the source's own doc comments/docstrings legitimately containing
        the prose "never shell=True" (a plain string/comment scan would
        false-positive on that explanatory text; walking the actual parsed
        keyword arguments cannot)."""
        calls = []
        for node in ast.walk(self.tree):
            if (
                isinstance(node, ast.Call)
                and isinstance(node.func, ast.Attribute)
                and node.func.attr == "run"
                and isinstance(node.func.value, ast.Name)
                and node.func.value.id == "subprocess"
            ):
                calls.append(node)
        return calls

    def test_writer_dispatch_uses_an_argv_list_not_a_shell_string(self):
        """Every subprocess.run(...) call site's first positional arg is a
        Python LIST literal (an argv array), and no call passes shell=True --
        SEC-3's injection defense. Checked via the parsed AST (not string
        scanning), so the source's own doc comments/docstrings that mention
        "shell=True" while explaining it is NEVER used cannot false-positive
        this assertion (see server.py lines ~25/979)."""
        calls = self._subprocess_run_calls()
        self.assertTrue(calls, "no subprocess.run(...) call site found in server.py")
        for call in calls:
            self.assertTrue(
                call.args and isinstance(call.args[0], ast.List),
                "subprocess.run(...) first positional arg must be a list literal (argv array)",
            )
            for kw in call.keywords:
                if kw.arg == "shell":
                    self.assertFalse(
                        isinstance(kw.value, ast.Constant) and kw.value.value is True,
                        "subprocess.run(..., shell=True) is forbidden (SEC-3)",
                    )

    def test_no_destructive_shutil_primitive(self):
        """Precisely-scoped SEC-3 guard: server.py may use shutil.which()
        (read-only PATH probe, task-004) but must never call a MUTATING
        shutil primitive (rmtree/copy/copy2/copyfile/move/copytree)."""
        for destructive in ("shutil.rmtree", "shutil.copy", "shutil.copy2",
                             "shutil.copyfile", "shutil.move", "shutil.copytree"):
            self.assertNotIn(destructive, self.code, f"server.py must not call {destructive}(...)")

    def test_no_in_process_fs_write_primitive(self):
        """Re-asserts the write-primitive-free invariant (SEC-3) scoped to the
        actual mutation-class calls, independent of the unrelated (and
        currently broken -- see module docstring) test_no_shutil rule."""
        self.assertNotIn("os.remove", self.code)
        self.assertNotIn("os.unlink", self.code)
        self.assertNotIn(".write_text(", self.code)
        self.assertNotIn(".write_bytes(", self.code)
        matches = re.findall(r'''open\s*\(.*?['"][wWaA][bB+]?['"]''', self.code)
        self.assertEqual(matches, [], f"server.py must not open files for writing; found: {matches}")

    def test_no_agent_llm_import(self):
        """SEC-4: dispatched children are shell scripts, never an agent/LLM import."""
        for lib in ("anthropic", "openai", "langchain"):
            self.assertNotIn(lib, self.source)


if __name__ == "__main__":
    unittest.main(verbosity=2)
