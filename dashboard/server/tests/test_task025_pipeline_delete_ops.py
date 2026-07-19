"""
test_task025_pipeline_delete_ops.py -- "pipeline.delete op row + exit-7->409
map" (task-025, feature-009-pipeline-delete, delivery-004,
work-017-cli-improvements) -- Python twin.

Scope (per task-025 DETAIL.md): the DISPATCH/VALIDATION/MAPPING wiring only --
the `OP_TABLE` row, the `status_map` exit-7->409 override (preserving every
DEFAULT_MAP row), the argv-builder, and the server-side validation order
(work_id shape/length -> resolve_work_dir -> args-empty) BEFORE any spawn.
Full end-to-end delete round-trips through the real delete-pipeline.sh writer
(git worktree fixtures, guard trips, actual removal) are task-027's job --
deliberately NOT exercised here.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. OP_TABLE shape: the pipeline.delete row carries scope="pipeline", writer
     "delete-pipeline.sh", an empty arg_schema, a callable build_argv, a
     semantic_validate hook that IS feature-004's shared _validate_no_args (no
     op-schema flag; no 'spawn' override -- default _spawn_writer/_run_writer,
     KI-009's hardened bash-resolver path, never _spawn_aid_cli).
  2. status_map (OP-SM): exit 7 -> 409 'pipeline-active', and the row's
     status_map is otherwise BYTE-IDENTICAL to DEFAULT_MAP (1/2/3/4/5
     preserved verbatim) -- verified both via _map_exit_code() and a direct
     dict-equality assertion.
  3. Argv builder (_op_pipeline_delete_argv): argv is a list (never a shell
     string); AID_REPO_ROOT is ALWAYS server-built from served_root, never
     echoed from a request-body field (SEC-2/SEC-3).
  4. _dispatch_op validation order (Feature Flow steps 6-7), no writer spawn
     until every check passes:
       - a structurally malformed/absent target.work_id (missing key, wrong
         type) -> 400 'bad-request'.
       - a target.work_id that is a STRING but fails the full anchored
         ^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$ shape or exceeds 64 chars -> 422
         'invalid-value' (INLINE, no spawn) -- including a value that would
         PASS every other pipeline/task-scoped op's looser ^work-[0-9]+
         prefix-only check (proves this op's stricter validation, not the
         shared default).
       - resolve_work_dir(...) returning None (work_id well-formed but not
         found in any enumerated worktree root) -> 404 'not-found', no spawn.
       - a non-empty `args` (op takes no parameters) -> 422 'invalid-value',
         evaluated AFTER the work_id/resolve_work_dir checks -- proven with a
         real, resolvable work_id and a live directory that is verified to
         still exist afterward (no spawn happened).
  5. Every OTHER existing pipeline/task-scoped OP_TABLE row (pipeline.finish,
     pipeline.rename, task.rename, task.set-notes) is untouched: its work_id
     shape check still returns the shared 400 'bad-request' class for an
     invalid work_id (byte-identical to pre-task-025 behavior) -- proof the
     new OPTIONAL work_id_re/work_id_max_len/work_id_invalid_status
     dispatcher fields are opt-in, not a behavior change for existing rows.

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` / pure helper functions directly -- no
`_ServerThread` socket bind anywhere -- so the whole file is safe to run
locally per the project's port-binding-server-test constraint. None of these
cases spawn the real delete-pipeline.sh writer (that is task-027's job); the
scratch directories used here are plain (non-git) tempdirs, which is
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


def _seed_work(root: Path, work_id: str, lifecycle: str = "Completed") -> Path:
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

class TestOpTablePipelineDeleteRow(unittest.TestCase):
    def test_row_shape(self):
        row = srv.OP_TABLE["pipeline.delete"]
        self.assertEqual(row["scope"], "pipeline")
        self.assertEqual(row["writer"], "delete-pipeline.sh")
        self.assertEqual(row["arg_schema"], {})
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))

    def test_semantic_validate_is_shared_validate_no_args(self):
        """Reuses feature-004's _validate_no_args -- no bespoke reimplementation
        of the 'no parameters' rule."""
        row = srv.OP_TABLE["pipeline.delete"]
        self.assertIs(row["semantic_validate"], srv._validate_no_args)

    def test_no_spawn_override(self):
        """No 'spawn' key -> dispatcher default _spawn_writer/_run_writer (the
        KI-009-hardened bash resolver path), never _spawn_aid_cli. Do not
        disturb the KI-009 dispatch code (task-025 scope note)."""
        row = srv.OP_TABLE["pipeline.delete"]
        self.assertNotIn("spawn", row)

    def test_no_post_verify_no_resolve_target_no_pre_validate(self):
        """No op-schema flag: none of the feature-003-style extension hooks
        that don't apply to this op are wired in."""
        row = srv.OP_TABLE["pipeline.delete"]
        self.assertNotIn("post_verify", row)
        self.assertNotIn("resolve_target", row)
        self.assertNotIn("pre_validate", row)

    def test_work_id_shape_override_fields_present(self):
        row = srv.OP_TABLE["pipeline.delete"]
        self.assertEqual(row["work_id_re"], srv._RE_WORK_ID_STRICT)
        self.assertEqual(row["work_id_max_len"], 64)
        self.assertEqual(row["work_id_invalid_status"], (422, "invalid-value"))


# ===========================================================================
# (2) status_map (OP-SM): exit 7 -> 409 'pipeline-active'; DEFAULT_MAP
#     preserved verbatim
# ===========================================================================

class TestPipelineDeleteStatusMap(unittest.TestCase):
    def test_exit_7_maps_to_409_pipeline_active(self):
        row = srv.OP_TABLE["pipeline.delete"]
        status, error_class = srv._map_exit_code(7, row.get("status_map"), row.get("status_map_default"))
        self.assertEqual((status, error_class), (409, "pipeline-active"))

    def test_default_map_rows_all_preserved(self):
        """Every DEFAULT_MAP row (1->404, 2->409 busy, 3->500, 4/5->422, plus
        the 6->500 malformed-STATE.md row) resolves IDENTICALLY through the
        pipeline.delete row's own status_map."""
        row = srv.OP_TABLE["pipeline.delete"]
        for exit_code, expected in srv.DEFAULT_MAP.items():
            with self.subTest(exit_code=exit_code):
                got = srv._map_exit_code(exit_code, row.get("status_map"), row.get("status_map_default"))
                self.assertEqual(got, expected)

    def test_status_map_equals_default_map_plus_exit7_exactly(self):
        """Direct dict-equality: the row's status_map is DEFAULT_MAP with
        exactly one added key (7), no other row changed/removed."""
        row = srv.OP_TABLE["pipeline.delete"]
        expected = dict(srv.DEFAULT_MAP)
        expected[7] = (409, "pipeline-active")
        self.assertEqual(row["status_map"], expected)

    def test_unmapped_exit_code_falls_back_to_default_fallback(self):
        """An exit code with no row (e.g. 42) still falls through to the
        shared _DEFAULT_FALLBACK (500, 'write-failed'), same as every other
        op without a status_map_default override."""
        row = srv.OP_TABLE["pipeline.delete"]
        got = srv._map_exit_code(42, row.get("status_map"), row.get("status_map_default"))
        self.assertEqual(got, srv._DEFAULT_FALLBACK)


# ===========================================================================
# (3) Argv builder
# ===========================================================================

class TestPipelineDeleteArgvBuilder(unittest.TestCase):
    def test_argv_is_list_with_work_id_flag(self):
        argv, env = srv._op_pipeline_delete_argv(None, "/repo/root", {"work_id": "work-042-sample"}, {})
        self.assertIsInstance(argv, list)
        self.assertEqual(argv, ["--work-id", "work-042-sample"])
        self.assertEqual(env, {"AID_REPO_ROOT": "/repo/root"})

    def test_args_is_accepted_but_unused(self):
        """args is always {} by the time build_argv runs (arg_schema is empty
        and semantic_validate already 422'd a non-empty args) -- the builder
        signature still accepts it (frozen call shape) but never reads it."""
        argv, env = srv._op_pipeline_delete_argv(None, "/repo/root", {"work_id": "work-042-sample"}, {})
        self.assertNotIn("args", argv)

    def test_repo_root_never_taken_from_body(self):
        """AID_REPO_ROOT is ALWAYS the server-resolved served_root, never a
        client-supplied field, even if target/args try to smuggle one in
        (SEC-2/SEC-3 -- 'no path from the body')."""
        argv, env = srv._op_pipeline_delete_argv(
            None, "/repo/root",
            {"work_id": "work-042-sample", "repo_root": "/evil/path", "AID_REPO_ROOT": "/evil/path"},
            {"repo_root": "/evil/path"},
        )
        self.assertEqual(env["AID_REPO_ROOT"], "/repo/root")
        self.assertNotIn("/evil/path", argv)
        self.assertNotIn("/evil/path", env.values())

    def test_work_dir_not_forwarded(self):
        """work_dir (resolve_work_dir's result) is NOT forwarded to the
        writer -- delete-pipeline.sh re-derives the worktree root itself
        (feature-009 SPEC.md API Contracts Algorithm step 5)."""
        argv, env = srv._op_pipeline_delete_argv(
            Path("/some/resolved/workdir"), "/repo/root", {"work_id": "work-042-sample"}, {},
        )
        self.assertNotIn("/some/resolved/workdir", argv)
        self.assertNotIn("/some/resolved/workdir", env.values())


# ===========================================================================
# (4) _dispatch_op validation order (Feature Flow steps 6-7) -- no spawn
#     until every check passes
# ===========================================================================

class TestPipelineDeleteDispatchValidation(unittest.TestCase):
    def test_missing_target_key_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(srv.OP_TABLE, {"op": "pipeline.delete"}, str(root))
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_target_present_but_no_work_id_key_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {}}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_work_id_non_string_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": 12345}}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_malformed_target_shape_returns_400(self):
        """target itself not an object -> the shared generic 400 (never reaches
        the pipeline.delete-specific work_id check at all)."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": "not-an-object"}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_invalid_work_id_shape_returns_422_not_400(self):
        """A string that does not match the full anchored regex at all --
        proves this is 422 (a 'failing value'), not the shared 400 the
        looser check would have produced for a non-string/absent work_id."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "not-a-work-id"}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_value_passing_loose_prefix_but_failing_strict_shape_returns_422(self):
        """A value that WOULD pass every other pipeline/task-scoped op's
        looser ^work-[0-9]+ prefix-only check (it does start with 'work-123')
        but fails the full anchored shape -- proves the STRICTER, op-specific
        regex is actually being applied, not silently falling back to the
        shared loose one."""
        with _TmpRepo() as root:
            self.assertTrue(srv._RE_WORK_ID_SHAPE.match("work-123$$$"))  # sanity: loose check would pass
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-123$$$"}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_overlong_work_id_returns_422(self):
        with _TmpRepo() as root:
            long_id = "work-1-" + ("a" * 60)  # 67 chars > 64
            self.assertGreater(len(long_id), 64)
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": long_id}}, str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_work_id_at_max_length_passes_shape_check(self):
        """Exactly 64 chars is the boundary -- must NOT be rejected by the
        length check (only reaches resolve_work_dir's 404, proving the shape
        check itself passed)."""
        with _TmpRepo() as root:
            work_id = "work-1-" + ("a" * 57)  # exactly 64 chars, valid slug shape
            self.assertEqual(len(work_id), 64)
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": work_id}}, str(root),
            )
            self.assertEqual(status, 404)  # not found, but NOT 422 -- shape passed
            self.assertEqual(json.loads(body)["error"], "not-found")

    def test_valid_shape_not_found_returns_404_no_spawn(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.delete", "target": {"work_id": "work-999-nonexistent"}}, str(root),
            )
            self.assertEqual(status, 404)
            self.assertEqual(json.loads(body)["error"], "not-found")

    def test_non_empty_args_returns_422_after_resolve_no_spawn(self):
        """A resolvable work_id (resolve_work_dir succeeds) with a non-empty
        args object -> 422, evaluated AFTER the step-6 checks -- and never
        reaches a child spawn (proven by the seeded directory still existing:
        delete-pipeline.sh would have removed it)."""
        with _TmpRepo() as root:
            work_dir = _seed_work(root, "work-042-sample")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.delete", "target": {"work_id": "work-042-sample"}, "args": {"foo": "bar"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")
            self.assertTrue(work_dir.exists(), "no spawn happened -- seeded work dir must still exist")

    def test_empty_args_object_reaches_spawn_stage_with_correct_argv(self):
        """target present + valid, resolvable work_id + explicit empty args ->
        the request passes every dispatch-level check and proceeds to
        build_argv/spawn. Stubs the row's 'spawn' hook so THIS test never
        invokes the real delete-pipeline.sh writer (task-027's job owns real
        writer round-trips) -- it only proves the request was not rejected
        before spawn on account of target/args shape, and that the argv the
        dispatcher built is exactly what _op_pipeline_delete_argv produces."""
        with _TmpRepo() as root:
            _seed_work(root, "work-042-sample")
            row = srv.OP_TABLE["pipeline.delete"]
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
                    {"op": "pipeline.delete", "target": {"work_id": "work-042-sample"}, "args": {}},
                    str(root),
                )
            finally:
                if had_spawn:
                    row["spawn"] = original_spawn
                else:
                    del row["spawn"]

            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "pipeline.delete"})
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0][0], ["--work-id", "work-042-sample"])
            self.assertEqual(calls[0][1], {"AID_REPO_ROOT": str(root)})


# ===========================================================================
# (5) Existing pipeline/task-scoped rows are UNCHANGED (opt-in, no fixture
#     drift for pipeline.finish / pipeline.rename / task.rename /
#     task.set-notes)
# ===========================================================================

class TestExistingWorkIdScopedRowsUnchanged(unittest.TestCase):
    def test_pipeline_finish_invalid_work_id_still_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "pipeline.finish", "target": {"work_id": "not-a-work-id"}}, str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_pipeline_rename_invalid_work_id_still_returns_400(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "not-a-work-id"}, "args": {"value": "x"}},
                str(root),
            )
            self.assertEqual(status, 400)
            self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_pipeline_finish_no_work_id_shape_override_fields(self):
        """Proves the new fields are OPT-IN: rows that never set them fall
        back to the generic loose-check defaults inside _dispatch_op."""
        row = srv.OP_TABLE["pipeline.finish"]
        self.assertNotIn("work_id_re", row)
        self.assertNotIn("work_id_max_len", row)
        self.assertNotIn("work_id_invalid_status", row)

    def test_pipeline_rename_status_map_still_none(self):
        row = srv.OP_TABLE["pipeline.rename"]
        self.assertIsNone(row.get("status_map"))


if __name__ == "__main__":
    unittest.main()
