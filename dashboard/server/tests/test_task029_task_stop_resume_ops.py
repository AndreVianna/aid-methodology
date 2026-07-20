"""
test_task029_task_stop_resume_ops.py -- "Derived stop_requested reader twin +
task.stop/task.resume ops" (task-029, feature-008-execution-control,
delivery-005, work-017-cli-improvements) -- Python twin.

Scope (per task-029 DETAIL.md): the DISPATCH/VALIDATION/MAPPING wiring for the
two new OP_TABLE rows only -- the row shape, the (shared, unoverridden)
DEFAULT_MAP exit-code mapping, the argv-builder, and the server-side
validation order (work_id/task_id shape -> resolve_work_dir -> args-empty)
BEFORE any spawn. The `stop_requested` reader-twin derivation itself is
covered by dashboard/reader/tests/test_task029_stop_requested.py (this file
covers ONLY the OP_TABLE half). A real write-control-signal.sh round trip
(actual file creation/removal, `stop_requested` re-derivation on the next
model read) is task-033's job -- deliberately NOT exercised here.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. OP_TABLE shape: both rows carry scope="task", writer
     "write-control-signal.sh", an empty arg_schema, a callable build_argv, a
     semantic_validate hook that IS feature-004's shared _validate_no_args, no
     status_map override (None -- write-control-signal.sh reuses the
     writeback exit alphabet verbatim, so DEFAULT_MAP already maps it
     correctly), no 'spawn' override (default _spawn_writer/_run_writer,
     KI-009's hardened bash-resolver path, never _spawn_aid_cli), and no
     work_id_re/work_id_max_len/work_id_invalid_status override (the SAME
     loose ^work-[0-9]+ prefix check + shared 400 'bad-request' class every
     pre-task-025 pipeline/task-scoped row uses -- NOT pipeline.delete's own
     stricter override).
  2. Argv builders (_op_task_stop_argv / _op_task_resume_argv): argv is a
     list (never a shell string) ending in the fixed --action stop|resume
     flag; AID_WORK_DIR is ALWAYS the work_dir the dispatcher resolved, never
     echoed from a request-body field (SEC-2/SEC-3); no AID_STATE_FILE is set
     (unlike task.rename/task.set-notes -- write-control-signal.sh never
     touches STATE.md).
  3. _dispatch_op validation order (scope="task": work_id AND task_id both
     required), no writer spawn until every check passes:
       - a structurally malformed/absent target.work_id -> 400 'bad-request'.
       - target.work_id present but target.task_id absent -> 400
         'bad-request' ("this op requires target.task_id").
       - target.task_id present but malformed (fails the superset regex)
         -> 400 'bad-request'.
       - a target.work_id that fails the generic loose ^work-[0-9]+ prefix
         check -> 400 'bad-request' (the SAME shared class every other
         pipeline/task-scoped row gets -- proves this op did NOT opt into
         pipeline.delete's stricter override).
       - resolve_work_dir(...) returning None (work_id well-formed but not
         found in any enumerated worktree root) -> 404 'not-found', no spawn.
       - a non-empty `args` (op takes no parameters) -> 422 'invalid-value',
         evaluated AFTER the work_id/task_id/resolve_work_dir checks -- proven
         with a real, resolvable work_id/task_id and a stubbed spawn that is
         never invoked.
  4. DEFAULT_MAP exit-code mapping (via _map_exit_code, no per-op override):
     4/5 -> 422 'invalid-value', 2 -> 409 'busy', other/unknown -> 500
     'write-failed' -- exactly the writeback alphabet write-control-signal.sh
     documents.
  5. Every OTHER existing task-scoped OP_TABLE row (task.rename,
     task.set-notes) is untouched.

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` / pure helper functions directly -- no
`_ServerThread` socket bind anywhere -- so the whole file is safe to run
locally per the project's port-binding-server-test constraint. None of these
cases spawn the real write-control-signal.sh writer (that is task-033's job);
the scratch directories used here are plain (non-git) tempdirs, which is
sufficient for resolve_work_dir's own SD-3 main-root-only degradation to
exercise every case above without ever reaching a child spawn.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
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


class _TmpRepo:
    """Context manager: a scratch (non-git) repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(str(self.path), ignore_errors=True)


def _seed_work(root: Path, work_id: str, lifecycle: str = "Running") -> Path:
    """Seed a minimal .aid/works/<work_id>/STATE.md so resolve_work_dir finds
    it via the main-root-only fallback (no .git needed -- see locator.py's
    SD-3 degradation)."""
    work_dir = root / ".aid" / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(f"---\nlifecycle: {lifecycle}\n---\n", encoding="utf-8")
    return work_dir


# ===========================================================================
# (1) OP_TABLE shape
# ===========================================================================

class TestOpTableTaskStopResumeRows(unittest.TestCase):
    def test_task_stop_row_shape(self):
        row = srv.OP_TABLE["task.stop"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "write-control-signal.sh")
        self.assertEqual(row["arg_schema"], {})
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row["status_map"])

    def test_task_resume_row_shape(self):
        row = srv.OP_TABLE["task.resume"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "write-control-signal.sh")
        self.assertEqual(row["arg_schema"], {})
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row["status_map"])

    def test_semantic_validate_is_shared_validate_no_args(self):
        """Reuses feature-004's _validate_no_args -- no bespoke
        reimplementation of the 'no parameters' rule."""
        self.assertIs(srv.OP_TABLE["task.stop"]["semantic_validate"], srv._validate_no_args)
        self.assertIs(srv.OP_TABLE["task.resume"]["semantic_validate"], srv._validate_no_args)

    def test_no_spawn_override(self):
        """No 'spawn' key -> dispatcher default _spawn_writer/_run_writer (the
        KI-009-hardened bash resolver path), never _spawn_aid_cli."""
        self.assertNotIn("spawn", srv.OP_TABLE["task.stop"])
        self.assertNotIn("spawn", srv.OP_TABLE["task.resume"])

    def test_no_post_verify_no_resolve_target_no_pre_validate(self):
        for op in ("task.stop", "task.resume"):
            with self.subTest(op=op):
                row = srv.OP_TABLE[op]
                self.assertNotIn("post_verify", row)
                self.assertNotIn("resolve_target", row)
                self.assertNotIn("pre_validate", row)

    def test_no_work_id_shape_override_fields(self):
        """Neither row opts into pipeline.delete's stricter work_id override
        -- both fall back to the generic loose ^work-[0-9]+ prefix check +
        the shared 400 'bad-request' class (SPEC.md API Contracts: 'validated
        ^work-[0-9]+ + dir-exists per feature-001')."""
        for op in ("task.stop", "task.resume"):
            with self.subTest(op=op):
                row = srv.OP_TABLE[op]
                self.assertNotIn("work_id_re", row)
                self.assertNotIn("work_id_max_len", row)
                self.assertNotIn("work_id_invalid_status", row)


# ===========================================================================
# (2) DEFAULT_MAP exit-code mapping (no per-op override)
# ===========================================================================

class TestTaskStopResumeStatusMap(unittest.TestCase):
    def test_exit_4_and_5_map_to_422_invalid_value(self):
        for op in ("task.stop", "task.resume"):
            row = srv.OP_TABLE[op]
            for exit_code in (4, 5):
                with self.subTest(op=op, exit_code=exit_code):
                    status, error_class = srv._map_exit_code(
                        exit_code, row.get("status_map"), row.get("status_map_default"),
                    )
                    self.assertEqual((status, error_class), (422, "invalid-value"))

    def test_exit_2_maps_to_409_busy(self):
        for op in ("task.stop", "task.resume"):
            row = srv.OP_TABLE[op]
            status, error_class = srv._map_exit_code(2, row.get("status_map"), row.get("status_map_default"))
            self.assertEqual((status, error_class), (409, "busy"))

    def test_unmapped_exit_code_falls_back_to_500_write_failed(self):
        for op in ("task.stop", "task.resume"):
            row = srv.OP_TABLE[op]
            got = srv._map_exit_code(42, row.get("status_map"), row.get("status_map_default"))
            self.assertEqual(got, srv._DEFAULT_FALLBACK)
            self.assertEqual(got, (500, "write-failed"))

    def test_status_map_is_none_uses_default_map_directly(self):
        for op in ("task.stop", "task.resume"):
            self.assertIsNone(srv.OP_TABLE[op]["status_map"])


# ===========================================================================
# (3) Argv builders
# ===========================================================================

class TestTaskStopArgvBuilder(unittest.TestCase):
    def test_argv_and_env(self):
        argv, env = srv._op_task_stop_argv(Path("/some/resolved/workdir"), "/repo/root", {"task_id": "008"}, {})
        self.assertIsInstance(argv, list)
        self.assertEqual(argv, ["--task-id", "008", "--action", "stop"])
        # .as_posix(): the builder forward-slashes AID_WORK_DIR for the bash writer's
        # path arithmetic (the KI/AID_WORK_DIR fix); backslash str() would break on Windows.
        self.assertEqual(env, {"AID_WORK_DIR": Path("/some/resolved/workdir").as_posix()})

    def test_no_aid_state_file_env(self):
        """Unlike task.rename/task.set-notes, write-control-signal.sh never
        touches STATE.md -- AID_STATE_FILE must NOT be set."""
        _argv, env = srv._op_task_stop_argv(Path("/some/resolved/workdir"), "/repo/root", {"task_id": "008"}, {})
        self.assertNotIn("AID_STATE_FILE", env)

    def test_work_dir_never_taken_from_body(self):
        """AID_WORK_DIR is ALWAYS the dispatcher-resolved work_dir, never a
        client-supplied field, even if target/args try to smuggle one in
        (SEC-2/SEC-3)."""
        argv, env = srv._op_task_stop_argv(
            Path("/real/resolved/dir"), "/repo/root",
            {"task_id": "008", "AID_WORK_DIR": "/evil/path", "work_dir": "/evil/path"},
            {"AID_WORK_DIR": "/evil/path"},
        )
        self.assertEqual(env["AID_WORK_DIR"], Path("/real/resolved/dir").as_posix())
        self.assertNotIn("/evil/path", argv)
        self.assertNotIn("/evil/path", env.values())


class TestTaskResumeArgvBuilder(unittest.TestCase):
    def test_argv_and_env(self):
        argv, env = srv._op_task_resume_argv(Path("/some/resolved/workdir"), "/repo/root", {"task_id": "008"}, {})
        self.assertIsInstance(argv, list)
        self.assertEqual(argv, ["--task-id", "008", "--action", "resume"])
        # .as_posix(): the builder forward-slashes AID_WORK_DIR for the bash writer's
        # path arithmetic (the KI/AID_WORK_DIR fix); backslash str() would break on Windows.
        self.assertEqual(env, {"AID_WORK_DIR": Path("/some/resolved/workdir").as_posix()})

    def test_no_aid_state_file_env(self):
        _argv, env = srv._op_task_resume_argv(Path("/some/resolved/workdir"), "/repo/root", {"task_id": "008"}, {})
        self.assertNotIn("AID_STATE_FILE", env)

    def test_args_is_accepted_but_unused(self):
        """args is always {} by the time build_argv runs (arg_schema is empty
        and semantic_validate already 422'd a non-empty args) -- the builder
        signature still accepts it (frozen call shape) but never reads it."""
        argv, _env = srv._op_task_resume_argv(Path("/wd"), "/repo/root", {"task_id": "008"}, {"foo": "bar"})
        self.assertNotIn("foo", argv)
        self.assertNotIn("bar", argv)


# ===========================================================================
# (4) _dispatch_op validation order -- no spawn until every check passes
# ===========================================================================

class TestTaskStopResumeDispatchValidation(unittest.TestCase):
    def test_missing_target_key_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(srv.OP_TABLE, {"op": "task.stop"}, str(root))
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_target_present_but_no_work_id_key_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.stop", "target": {"task_id": "001"}}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_malformed_target_shape_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.stop", "target": "not-an-object"}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_work_id_present_task_id_absent_returns_400(self):
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "task.stop", "target": {"work_id": "work-042-sample"}}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_malformed_task_id_returns_400(self):
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.stop", "target": {"work_id": "work-042-sample", "task_id": "not-numeric"}},
                str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_invalid_work_id_shape_returns_400_not_422(self):
        """Proves task.stop/task.resume do NOT opt into pipeline.delete's
        stricter override -- an invalid work_id gets the SAME shared 400
        'bad-request' class every pre-task-025 pipeline/task-scoped row got."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.stop", "target": {"work_id": "not-a-work-id", "task_id": "001"}},
                str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_valid_shape_not_found_returns_404_no_spawn(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.stop", "target": {"work_id": "work-999-nonexistent", "task_id": "001"}},
                str(root),
            )
            self.assertEqual(status, 404)
            self.assertEqual(json.loads(body)["error"], "not-found")

    def test_prefixed_task_id_form_is_accepted_and_normalized(self):
        """target.task_id accepts BOTH 'task-NNN' and bare 'NNN' (feature-006's
        superset regex) -- normalized to the bare (still zero-padded, digits
        verbatim) numeric string BEFORE build_argv runs, exactly as
        task.rename/task.set-notes already normalize it."""
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            row = srv.OP_TABLE["task.stop"]
            calls = []

            def _stub_spawn(row_arg, argv, env_overrides):
                calls.append((argv, env_overrides))
                return 0, ""

            row["spawn"] = _stub_spawn
            try:
                status, _body = srv._dispatch_op(
                    srv.OP_TABLE,
                    {"op": "task.stop", "target": {"work_id": "work-042-sample", "task_id": "task-001"}},
                    str(root),
                )
            finally:
                del row["spawn"]
            self.assertEqual(status, 200)
            self.assertEqual(calls[0][0], ["--task-id", "001", "--action", "stop"])

    def test_non_empty_args_returns_422_after_resolve_no_spawn(self):
        """A resolvable work_id/task_id with a non-empty args object -> 422,
        evaluated AFTER the step-6 checks -- and never reaches a child spawn."""
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            row = srv.OP_TABLE["task.stop"]
            calls = []

            def _stub_spawn(row_arg, argv, env_overrides):
                calls.append((argv, env_overrides))
                return 0, ""

            row["spawn"] = _stub_spawn
            try:
                status, body = srv._dispatch_op(
                    srv.OP_TABLE,
                    {
                        "op": "task.stop",
                        "target": {"work_id": "work-042-sample", "task_id": "001"},
                        "args": {"lifecycle": "Completed"},
                    },
                    str(root),
                )
            finally:
                del row["spawn"]
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")
            self.assertEqual(len(calls), 0, "no spawn happened -- semantic_validate rejected before dispatch")

    def test_empty_args_object_reaches_spawn_stage_with_correct_argv(self):
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            row = srv.OP_TABLE["task.stop"]
            calls = []

            def _stub_spawn(row_arg, argv, env_overrides):
                calls.append((argv, env_overrides))
                return 0, ""

            had_spawn = "spawn" in row
            original_spawn = row.get("spawn")
            row["spawn"] = _stub_spawn
            try:
                status, body = srv._dispatch_op(
                    srv.OP_TABLE,
                    {"op": "task.stop", "target": {"work_id": "work-042-sample", "task_id": "001"}, "args": {}},
                    str(root),
                )
            finally:
                if had_spawn:
                    row["spawn"] = original_spawn
                else:
                    del row["spawn"]

            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.stop"})
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0][0], ["--task-id", "001", "--action", "stop"])
            # Computed via the SAME resolve_work_dir() the dispatcher itself calls
            # (never a hand-built str(root/...) path) -- .resolve() may normalize
            # to an 8.3 short-path alias on some Windows hosts, which a
            # hand-built path string would not reproduce.
            # .as_posix(): the builder forward-slashes AID_WORK_DIR for the bash writer.
            expected_work_dir = srv.resolve_work_dir(str(root), "work-042-sample").as_posix()
            self.assertEqual(calls[0][1], {"AID_WORK_DIR": expected_work_dir})

    def test_task_resume_reaches_spawn_stage_with_correct_argv(self):
        with _TmpRepo() as root:
            _seed_work(root, "work-043-sample")
            row = srv.OP_TABLE["task.resume"]
            calls = []

            def _stub_spawn(row_arg, argv, env_overrides):
                calls.append((argv, env_overrides))
                return 0, ""

            had_spawn = "spawn" in row
            original_spawn = row.get("spawn")
            row["spawn"] = _stub_spawn
            try:
                status, body = srv._dispatch_op(
                    srv.OP_TABLE,
                    {"op": "task.resume", "target": {"work_id": "work-043-sample", "task_id": "001"}, "args": {}},
                    str(root),
                )
            finally:
                if had_spawn:
                    row["spawn"] = original_spawn
                else:
                    del row["spawn"]

            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "task.resume"})
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0][0], ["--task-id", "001", "--action", "resume"])
            # .as_posix(): the builder forward-slashes AID_WORK_DIR for the bash writer.
            expected_work_dir = srv.resolve_work_dir(str(root), "work-043-sample").as_posix()
            self.assertEqual(calls[0][1], {"AID_WORK_DIR": expected_work_dir})


# ===========================================================================
# (5) Existing task-scoped rows are UNCHANGED
# ===========================================================================

class TestExistingTaskScopedRowsUnchanged(unittest.TestCase):
    def test_task_rename_row_untouched(self):
        row = srv.OP_TABLE["task.rename"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "writeback-state.sh")
        self.assertIsNone(row["status_map"])

    def test_task_set_notes_row_untouched(self):
        row = srv.OP_TABLE["task.set-notes"]
        self.assertEqual(row["scope"], "task")
        self.assertEqual(row["writer"], "writeback-state.sh")
        self.assertIsNone(row["status_map"])


if __name__ == "__main__":
    unittest.main()
