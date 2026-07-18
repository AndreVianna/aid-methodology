"""
test_task013_project_registry_ops.py -- "project.add / project.remove handlers +
shared aid-CLI resolver" (task-013, feature-003-project-registry, delivery-002,
work-017-cli-improvements) -- Python twin.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. Pure validation: _validate_project_add_args (empty / control-char / overlong
     / relative / valid absolute).
  2. Pure target resolution: _resolve_project_remove_target against a real
     registry.yml fixture (known id, unknown id, missing/non-string id).
  3. The shared aid-CLI resolver's own contract (KI-004): _run_aid_cli spawns an
     argv ARRAY (never shell=True), threads AID_HOME, and never adds
     AID_CODE_HOME -- proven via a throwaway dump-env probe script (never the
     real bin/aid), mirroring test_task011_dispatch_round_trip.py's own
     probe-writer convention.
  4. The fail-open post-dispatch guard, unit-level: _post_verify_project_add /
     _post_verify_project_remove against synthetic exit/stderr combinations
     (WARN present, clean, still-in-union "phantom success").
  5. Full HOME_OP_TABLE dispatch (_dispatch_op) against a controllable FAKE aid
     CLI (never bin/aid) -- proves the row wiring (build_argv -> pre_validate/
     resolve_target -> spawn -> post_verify -> status_map) end to end: 200
     happy path, 500 write-unverified (fail-open WARN and phantom-success), 422
     (CLI exit 2), 404 (unknown target.id), 400 (bad path, never reaching the
     fake CLI at all).
  6. A genuine END-TO-END round trip through the REAL bin/aid CLI (no fake, no
     monkeypatch) -- register/unregister a real temp AID project and read the
     registry back via _load_union_repos, proving AC1 (persists to disk) for
     real, plus the CLI's own 422 'not an AID project' path. Bounded: a single
     `bash bin/aid projects ...` subprocess call per assertion (fast, no
     socket bind), same class of check test_task012's own "REAL co-vendored
     writer" round trips already run locally.

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` / `srv._run_aid_cli(...)` directly -- no
`_ServerThread` socket bind anywhere -- so the whole file is safe to run
locally per the project's port-binding-server-test constraint. All classes
were exercised directly as part of this task's own verification pass.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
import unittest.mock as mock
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
from dashboard.server.tests.test_server_py import _make_aid_home, _write_registry, _repo_id8


# ===========================================================================
# (1) Pure validation: _validate_project_add_args
# ===========================================================================

class TestValidateProjectAddArgs(unittest.TestCase):
    def test_empty_path_is_rejected(self):
        err = srv._validate_project_add_args({"path": ""})
        self.assertIsNotNone(err)
        self.assertIn("required", err)

    def test_relative_path_is_rejected(self):
        err = srv._validate_project_add_args({"path": "relative/path/to/proj"})
        self.assertIsNotNone(err)
        self.assertIn("absolute", err)

    def test_control_char_newline_is_rejected(self):
        err = srv._validate_project_add_args({"path": "/abs/path\nwith/newline"})
        self.assertIsNotNone(err)
        self.assertIn("control character", err)

    def test_control_char_nul_is_rejected(self):
        err = srv._validate_project_add_args({"path": "/abs/path\x00evil"})
        self.assertIsNotNone(err)
        self.assertIn("control character", err)

    def test_overlong_path_is_rejected(self):
        overlong = "/" + ("a" * 4096)
        err = srv._validate_project_add_args({"path": overlong})
        self.assertIsNotNone(err)
        self.assertIn("exceeds max length", err)

    def test_valid_absolute_path_passes(self):
        err = srv._validate_project_add_args({"path": "/abs/path/to/aid/project"})
        self.assertIsNone(err)


# ===========================================================================
# (2) Pure target resolution: _resolve_project_remove_target
# ===========================================================================

class TestResolveProjectRemoveTarget(unittest.TestCase):
    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._known_path = "/tmp/fake/known-project"
        _write_registry(self._aid_home, [self._known_path])
        self._known_id = _repo_id8(self._known_path)

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_known_id_resolves_to_verbatim_path(self):
        resolved = srv._resolve_project_remove_target(str(self._aid_home), {"id": self._known_id})
        self.assertEqual(resolved, self._known_path)

    def test_unknown_id_resolves_to_none(self):
        resolved = srv._resolve_project_remove_target(str(self._aid_home), {"id": "deadbeef"})
        self.assertIsNone(resolved)

    def test_missing_id_resolves_to_none(self):
        resolved = srv._resolve_project_remove_target(str(self._aid_home), {})
        self.assertIsNone(resolved)

    def test_non_string_id_resolves_to_none(self):
        resolved = srv._resolve_project_remove_target(str(self._aid_home), {"id": 12345})
        self.assertIsNone(resolved)

    def test_empty_id_resolves_to_none(self):
        resolved = srv._resolve_project_remove_target(str(self._aid_home), {"id": ""})
        self.assertIsNone(resolved)


# ===========================================================================
# (3) The shared aid-CLI resolver's own contract (KI-004): argv array, env
# threading, AID_CODE_HOME never added -- via a throwaway dump-env probe.
# ===========================================================================

class TestRunAidCliContract(unittest.TestCase):
    """Never touches the real bin/aid -- a throwaway probe script stands in
    (mirrors TestOpStatusMapOverrideHook's own probe-writer convention in
    test_task011_dispatch_round_trip.py). Only srv._AID_CLI_PATH is redirected
    for the duration of this test class, restored in tearDown."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())
        self._probe = self._tmp / "probe-aid.sh"
        self._probe.write_text(
            "#!/usr/bin/env bash\n"
            'printf "ARGV:%s\\n" "$*" >&2\n'
            'printf "AID_HOME:%s\\n" "${AID_HOME:-<unset>}" >&2\n'
            'printf "AID_CODE_HOME:%s\\n" "${AID_CODE_HOME:-<unset>}" >&2\n'
            "exit 0\n",
            encoding="utf-8",
        )
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._probe

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def test_argv_array_env_threading_and_no_code_home_leak(self):
        exit_code, stderr_text = srv._run_aid_cli(
            ["projects", "add", "/abs/path"], {"AID_HOME": "/pinned/aid_home"}
        )
        self.assertEqual(exit_code, 0)
        self.assertIn("ARGV:projects add /abs/path", stderr_text)
        self.assertIn("AID_HOME:/pinned/aid_home", stderr_text)
        self.assertIn("AID_CODE_HOME:<unset>", stderr_text)

    def test_no_local_shared_verbose_flags_in_argv(self):
        """Sanity check on the OWN argv this test constructs (not a hook into
        the argv-builders -- those are exercised in group (5) below): the
        shared resolver forwards whatever argv it is given verbatim, so an
        argv-builder that emits exactly 3 elements never grows a --local/
        --shared/--verbose flag by passing through _run_aid_cli."""
        exit_code, stderr_text = srv._run_aid_cli(["projects", "remove", "/abs/path"], {"AID_HOME": "/x"})
        self.assertEqual(exit_code, 0)
        self.assertIn("ARGV:projects remove /abs/path", stderr_text)
        for flag in ("--local", "--shared", "--verbose"):
            self.assertNotIn(flag, stderr_text)


# ===========================================================================
# (4) Fail-open post-dispatch guard, unit-level (synthetic exit/stderr).
# ===========================================================================

class TestPostVerifyProjectAdd(unittest.TestCase):
    def test_clean_exit0_no_override(self):
        self.assertIsNone(srv._post_verify_project_add(0, "", {}, {}, "/aid_home"))

    def test_exit0_with_warn_line_overrides_to_500(self):
        stderr = "WARN: aid: shared registry write declined or unavailable; project not registered in shared tier\n"
        override = srv._post_verify_project_add(0, stderr, {}, {}, "/aid_home")
        self.assertIsNotNone(override)
        status, error_class, detail = override
        self.assertEqual(status, 500)
        self.assertEqual(error_class, "write-unverified")
        self.assertIn("WARN: aid:", detail)

    def test_exit0_with_priv_run_error_line_overrides_to_500(self):
        stderr = "ERROR: aid: /var/lib/aid is not writable and sudo is unavailable. Run manually:\n  mv ...\n"
        override = srv._post_verify_project_add(0, stderr, {}, {}, "/aid_home")
        self.assertIsNotNone(override)
        self.assertEqual(override[0], 500)
        self.assertEqual(override[1], "write-unverified")

    def test_nonzero_exit_never_overridden_here(self):
        """The guard only applies to an apparently-clean (exit 0) result --
        a non-zero exit is left to the normal status_map mapping."""
        self.assertIsNone(srv._post_verify_project_add(2, "ERROR: aid projects: bad path\n", {}, {}, "/aid_home"))


class TestPostVerifyProjectRemove(unittest.TestCase):
    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._path = "/tmp/fake/still-there"

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_clean_exit_and_path_gone_no_override(self):
        _write_registry(self._aid_home, [])   # path already absent (removed for real)
        override = srv._post_verify_project_remove(
            0, "", {"_resolved_path": self._path}, {}, str(self._aid_home)
        )
        self.assertIsNone(override)

    def test_warn_line_overrides_to_500_regardless_of_union_state(self):
        _write_registry(self._aid_home, [])   # even with the path gone, a WARN still fails-open
        override = srv._post_verify_project_remove(
            0, "WARN: aid: could not update the machine project registry: mv failed\n",
            {"_resolved_path": self._path}, {}, str(self._aid_home),
        )
        self.assertIsNotNone(override)
        self.assertEqual(override[0], 500)
        self.assertEqual(override[1], "write-unverified")

    def test_phantom_success_clean_exit_but_path_still_in_union(self):
        """Core guard proof (feature-003 AC1): exit 0, NO WARN, but the
        resolved path is still present in the re-loaded union (e.g. a
        mis-wired/no-op CLI) -- must NOT be reported as a phantom 200."""
        _write_registry(self._aid_home, [self._path])   # still present -- the CLI didn't really remove it
        override = srv._post_verify_project_remove(
            0, "", {"_resolved_path": self._path}, {}, str(self._aid_home)
        )
        self.assertIsNotNone(override)
        self.assertEqual(override[0], 500)
        self.assertEqual(override[1], "write-unverified")

    def test_nonzero_exit_never_overridden_here(self):
        _write_registry(self._aid_home, [self._path])
        override = srv._post_verify_project_remove(
            2, "ERROR: aid projects: not registered\n", {"_resolved_path": self._path}, {}, str(self._aid_home)
        )
        self.assertIsNone(override)


# ===========================================================================
# (5) Full HOME_OP_TABLE dispatch via a controllable FAKE aid CLI (never the
# real bin/aid) -- proves the row wiring end to end, in-process, no socket.
# ===========================================================================

class TestProjectAddDispatchFakeCli(unittest.TestCase):
    """Fake aid: reads FAKE_AID_MODE from the environment to control its exit
    code / stderr. Never touches the real bin/aid -- srv._AID_CLI_PATH is
    redirected for the duration of this test class, restored in tearDown."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._fake = self._base / "fake-aid.sh"
        self._fake.write_text(
            "#!/usr/bin/env bash\n"
            'mode="${FAKE_AID_MODE:-ok}"\n'
            "case \"$mode\" in\n"
            "  ok) exit 0 ;;\n"
            '  warn) echo "WARN: aid: shared registry write declined or unavailable" >&2; exit 0 ;;\n'
            '  err2) echo "ERROR: aid projects add: bad path" >&2; exit 2 ;;\n'
            '  err9) echo "unexpected failure" >&2; exit 9 ;;\n'
            "esac\n",
            encoding="utf-8",
        )
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._fake

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        shutil.rmtree(str(self._base), ignore_errors=True)

    def _dispatch(self, path_value: str):
        return srv._dispatch_op(
            srv.HOME_OP_TABLE,
            {"op": "project.add", "args": {"path": path_value}},
            str(self._aid_home),
        )

    def test_happy_path_is_200(self):
        with mock.patch.dict("os.environ", {"FAKE_AID_MODE": "ok"}):
            status, body = self._dispatch("/abs/project/path")
        self.assertEqual(status, 200)
        data = json.loads(body)
        self.assertEqual(data, {"ok": True, "op": "project.add"})

    def test_fail_open_warn_is_500_write_unverified(self):
        with mock.patch.dict("os.environ", {"FAKE_AID_MODE": "warn"}):
            status, body = self._dispatch("/abs/project/path")
        self.assertEqual(status, 500)
        data = json.loads(body)
        self.assertEqual(data["error"], "write-unverified")
        self.assertIn("WARN: aid:", data["detail"])

    def test_cli_exit2_is_422_invalid_value(self):
        with mock.patch.dict("os.environ", {"FAKE_AID_MODE": "err2"}):
            status, body = self._dispatch("/abs/project/path")
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_cli_other_nonzero_is_500_write_failed(self):
        with mock.patch.dict("os.environ", {"FAKE_AID_MODE": "err9"}):
            status, body = self._dispatch("/abs/project/path")
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-failed")

    def test_relative_path_is_400_before_any_spawn(self):
        """The fake CLI would exit 0 for ANY mode by default (env unset ->
        'ok') -- a 400 here proves pre_validate short-circuited BEFORE spawn,
        not that the fake happened to fail."""
        status, body = self._dispatch("relative/path")
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_empty_path_is_400_bad_request(self):
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE, {"op": "project.add", "args": {"path": ""}}, str(self._aid_home)
        )
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_missing_path_arg_is_400_bad_request(self):
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE, {"op": "project.add", "args": {}}, str(self._aid_home)
        )
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")


class TestProjectRemoveDispatchFakeCli(unittest.TestCase):
    """Fake aid for project.remove: on FAKE_AID_MODE=ok, actually deletes the
    matching '  - <path>' line from FAKE_REG_FILE (simulating a real CLI
    removal) so the post-dispatch union re-check can observe persistence.
    On FAKE_AID_MODE=noop_clean, exits 0 WITHOUT touching the file -- the
    "phantom success" scenario the fail-open guard must catch."""

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._path = "/tmp/fake/remove-me"
        _write_registry(self._aid_home, [self._path])
        self._id = _repo_id8(self._path)

        self._fake = self._base / "fake-aid.sh"
        self._fake.write_text(
            "#!/usr/bin/env bash\n"
            'mode="${FAKE_AID_MODE:-ok}"\n'
            'path="$3"\n'
            "case \"$mode\" in\n"
            "  ok)\n"
            '    if [[ -n "${FAKE_REG_FILE:-}" && -f "${FAKE_REG_FILE}" ]]; then\n'
            '      grep -vxF "  - ${path}" "${FAKE_REG_FILE}" > "${FAKE_REG_FILE}.tmp" '
            '&& mv "${FAKE_REG_FILE}.tmp" "${FAKE_REG_FILE}"\n'
            "    fi\n"
            "    exit 0 ;;\n"
            "  noop_clean) exit 0 ;;\n"
            '  warn) echo "WARN: aid: shared registry write declined or unavailable" >&2; exit 0 ;;\n'
            '  err2) echo "ERROR: aid projects: not registered" >&2; exit 2 ;;\n'
            "esac\n",
            encoding="utf-8",
        )
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._fake

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        shutil.rmtree(str(self._base), ignore_errors=True)

    def _dispatch(self, target_id: str, env: dict):
        with mock.patch.dict("os.environ", {**env, "FAKE_REG_FILE": str(self._aid_home / "registry.yml")}):
            return srv._dispatch_op(
                srv.HOME_OP_TABLE, {"op": "project.remove", "target": {"id": target_id}}, str(self._aid_home)
            )

    def test_unknown_id_is_404_before_any_spawn(self):
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE, {"op": "project.remove", "target": {"id": "deadbeef"}}, str(self._aid_home)
        )
        self.assertEqual(status, 404)
        self.assertEqual(json.loads(body)["error"], "not-found")

    def test_happy_path_removes_line_and_returns_200(self):
        status, body = self._dispatch(self._id, {"FAKE_AID_MODE": "ok"})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"ok": True, "op": "project.remove"})
        repos, _warnings, _primary, _fallback = srv._load_union_repos(str(self._aid_home))
        self.assertNotIn(self._path, repos)

    def test_phantom_success_is_500_write_unverified_and_line_stays(self):
        """exit 0, clean stderr, but the fake CLI did NOT touch the registry
        file -- the guard must convert this into 500, never a phantom 200."""
        status, body = self._dispatch(self._id, {"FAKE_AID_MODE": "noop_clean"})
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-unverified")
        repos, _warnings, _primary, _fallback = srv._load_union_repos(str(self._aid_home))
        self.assertIn(self._path, repos)   # never silently dropped from the registry

    def test_fail_open_warn_is_500_write_unverified(self):
        status, body = self._dispatch(self._id, {"FAKE_AID_MODE": "warn"})
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "write-unverified")

    def test_cli_exit2_is_422_invalid_value(self):
        status, body = self._dispatch(self._id, {"FAKE_AID_MODE": "err2"})
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_body_supplied_path_is_ignored_id_map_path_used_verbatim(self):
        """A body carrying a bogus args.path must NOT leak into the argv --
        project.remove only ever uses the id_map-resolved path (SEC-2). Proven
        by dispatching with an extraneous 'args.path' and confirming the
        REGISTRY entry removed is still the id_map one (self._path), i.e. the
        op still succeeds against the real registered path regardless of the
        (ignored) body path."""
        with mock.patch.dict(
            "os.environ",
            {"FAKE_AID_MODE": "ok", "FAKE_REG_FILE": str(self._aid_home / "registry.yml")},
        ):
            status, body = srv._dispatch_op(
                srv.HOME_OP_TABLE,
                {
                    "op": "project.remove",
                    "target": {"id": self._id},
                    "args": {"path": "/attacker/supplied/path"},
                },
                str(self._aid_home),
            )
        self.assertEqual(status, 200)
        repos, _warnings, _primary, _fallback = srv._load_union_repos(str(self._aid_home))
        self.assertNotIn(self._path, repos)


# ===========================================================================
# (6) Genuine end-to-end round trip through the REAL bin/aid CLI (no fake, no
# monkeypatch) -- proves AC1 for real. Bounded: one bash subprocess per check.
# ===========================================================================

class TestProjectRegistryRealCliRoundTrip(unittest.TestCase):
    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._project = self._base / "real-project"
        (self._project / ".aid").mkdir(parents=True, exist_ok=True)
        # Isolate from the REAL developer $HOME/.aid/registry.yml fallback tier:
        # _load_union_repos unions aid_home with $HOME/.aid unless the two
        # paths coincide, so without this override this test's assertions
        # would be polluted by whatever projects are ACTUALLY registered on
        # the machine running the suite. Pointing HOME at a fresh,
        # registry-free directory isolates both this test's own
        # _load_union_repos reads AND the real bin/aid child spawn (env
        # overrides layer onto a copy of the CURRENT os.environ, so the CLI's
        # own $HOME-relative fallback logic is isolated too).
        self._fake_home = self._base / "fake_home"
        self._fake_home.mkdir(parents=True, exist_ok=True)
        self._home_patch = mock.patch.dict("os.environ", {"HOME": str(self._fake_home)})
        self._home_patch.start()

    def tearDown(self) -> None:
        self._home_patch.stop()
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_add_then_remove_round_trip_persists_to_disk(self):
        # Add: dispatch through the REAL bin/aid (srv._AID_CLI_PATH untouched).
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE,
            {"op": "project.add", "args": {"path": str(self._project)}},
            str(self._aid_home),
        )
        self.assertEqual(status, 200, f"add failed: {body!r}")
        self.assertEqual(json.loads(body), {"ok": True, "op": "project.add"})

        # Re-read the registry FRESH (uncached) -- exactly one entry now,
        # whatever canonical form the real CLI's `cd && pwd` produced.
        repos, _warnings, _primary, _fallback = srv._load_union_repos(str(self._aid_home))
        self.assertEqual(len(repos), 1, f"expected exactly one registered repo, got {repos!r}")
        stored_path = repos[0]

        # Remove: resolve the id from the ACTUAL stored (possibly
        # MSYS-canonicalized) path -- never assume it byte-matches the
        # original str(self._project) input (platform-dependent canonicalization).
        stored_id = _repo_id8(stored_path)
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE,
            {"op": "project.remove", "target": {"id": stored_id}},
            str(self._aid_home),
        )
        self.assertEqual(status, 200, f"remove failed: {body!r}")
        self.assertEqual(json.loads(body), {"ok": True, "op": "project.remove"})

        repos_after, _warnings, _primary, _fallback = srv._load_union_repos(str(self._aid_home))
        self.assertEqual(repos_after, [])

    def test_add_non_aid_project_is_422_invalid_value(self):
        not_a_project = self._base / "not-an-aid-project"
        not_a_project.mkdir(parents=True, exist_ok=True)   # no .aid/ subfolder
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE,
            {"op": "project.add", "args": {"path": str(not_a_project)}},
            str(self._aid_home),
        )
        self.assertEqual(status, 422)
        data = json.loads(body)
        self.assertEqual(data["error"], "invalid-value")
        self.assertIn("not an AID project", data["detail"])

    def test_add_nonexistent_path_is_422_invalid_value(self):
        nonexistent = str(self._base / "does-not-exist-at-all")
        status, body = srv._dispatch_op(
            srv.HOME_OP_TABLE,
            {"op": "project.add", "args": {"path": nonexistent}},
            str(self._aid_home),
        )
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")


# ===========================================================================
# (7) HOME_OP_TABLE structural registration sanity check (cheap, in-process).
# ===========================================================================

class TestHomeOpTableRegistration(unittest.TestCase):
    def test_project_add_row_shape(self):
        row = srv.HOME_OP_TABLE["project.add"]
        self.assertEqual(row["scope"], "home")
        self.assertIn("path", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["path"]["required"])
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertIs(row["pre_validate"], srv._validate_project_add_args)
        self.assertIs(row["post_verify"], srv._post_verify_project_add)
        self.assertIs(row["status_map"], srv._PROJECT_OP_STATUS_MAP)
        self.assertNotIn("resolve_target", row)

    def test_project_remove_row_shape(self):
        row = srv.HOME_OP_TABLE["project.remove"]
        self.assertEqual(row["scope"], "home")
        self.assertEqual(row["arg_schema"], {})
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertIs(row["resolve_target"], srv._resolve_project_remove_target)
        self.assertIs(row["post_verify"], srv._post_verify_project_remove)
        self.assertIs(row["status_map"], srv._PROJECT_OP_STATUS_MAP)
        self.assertNotIn("pre_validate", row)


if __name__ == "__main__":
    unittest.main(verbosity=2)
