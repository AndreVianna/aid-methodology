"""
test_task015_tools_update_ops.py -- "tools.update / tools.update-self handlers"
(task-015, feature-004-update-tools, delivery-002, work-017-cli-improvements) --
Python twin.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. Pure validation: _validate_no_args (absent/empty/non-empty args).
  2. Pure argv-builders: _op_tools_update_argv / _op_tools_update_self_argv --
     argv shape, and the AID_HOME env threading (KI-004-adjacent extension):
     tools.update's servedRoot is the REPO path (not aid_home), so its env
     AID_HOME must come from target['_aid_home'] (the value _dispatch_op
     stashes there); tools.update-self's servedRoot already IS aid_home
     (home scope, mirrors project.add/remove exactly).
  3. Full OP_TABLE / HOME_OP_TABLE dispatch (_dispatch_op) against a
     controllable FAKE aid CLI (never the real bin/aid) -- proves the row
     wiring (semantic_validate -> build_argv -> spawn -> status_map) end to
     end: 200 happy path, 422 on non-empty args (never reaching the fake CLI
     at all), 500 'update-failed' on ANY non-zero exit (not just an
     enumerated one -- the per-op 'status_map_default' extension), 504
     'timed-out' on the out-of-band timeout sentinel.
  4. _map_exit_code's new 'default_status' parameter, unit-level: an
     unenumerated exit code falls back to the row's own default when one is
     given, else the shared (500, 'write-failed') _DEFAULT_FALLBACK.
  5. OP_TABLE / HOME_OP_TABLE structural registration sanity checks (cheap,
     in-process) -- both rows reuse _spawn_aid_cli (KI-004: the SAME shared
     resolver task-013 introduced, not re-invented) and carry a 600s
     aid_cli_timeout (vs. the 30s default sized for the fast registry ops).
  6. tools.add / tools.remove (work-017 post-dogfood -- per-project host-tool
     management, moved off the home card onto the project page's Tools
     section): _validate_tool_arg (pre-dispatch charset/shape validation,
     NOT existence -- the CLI stays authority); _op_tools_add_argv /
     _op_tools_remove_argv (argv shape + the SAME target['_aid_home']
     smuggling convention tools.update established); full OP_TABLE dispatch
     via a fake CLI (200 happy path, 400 'bad-request' on an invalid tool id
     BEFORE any spawn, 422 'invalid-value' on the CLI's own exit 2 -- UNLIKE
     tools.update's exit 2, which collapses to 500 'update-failed' -- 500
     'tools-op-failed' default, 504 'timed-out'); OP_TABLE row-shape checks.

Deliberately NOT covered here (out of this task's scope / a task-017 target):
  - A genuine end-to-end round trip through the REAL bin/aid CLI: unlike
    project.add/remove (fast local filesystem ops), `aid update`/`aid update
    self` perform real network fetches (GitHub/npm/PyPI) and can take
    seconds-to-minutes -- unsuitable for a bounded local unit test. The
    dispatch-level fake-CLI tests below fully exercise this task's own new
    logic (row wiring, env threading, status-map extension) without touching
    the network; task-017 (Registry + tooling op round-trips) is the
    integration-level TEST task for the full round trip.
  - HTTP-layer (_serve_op / _serve_home_op) coverage: task-013's own test
    suite (test_task013_project_registry_ops.py) does not add socket-bound
    coverage for its rows either -- _dispatch_op is the correct boundary
    (mirrors that precedent exactly).

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` / `srv._map_exit_code(...)` directly -- no
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
from dashboard.server.tests.test_server_py import _patch_run_aid_cli_force_unix


# ===========================================================================
# (1) Pure validation: _validate_no_args
# ===========================================================================

class TestValidateNoArgs(unittest.TestCase):
    def test_absent_args_is_none(self):
        self.assertIsNone(srv._validate_no_args({}))

    def test_non_empty_args_is_rejected(self):
        err = srv._validate_no_args({"foo": "bar"})
        self.assertIsNotNone(err)
        self.assertIn("no arguments", err)


# ===========================================================================
# (2) Pure argv-builders: _op_tools_update_argv / _op_tools_update_self_argv
# ===========================================================================

class TestOpToolsUpdateArgv(unittest.TestCase):
    def test_argv_and_env_from_stashed_aid_home(self):
        """servedRoot is the REPO path (project scope); AID_HOME must come
        from target['_aid_home'] -- the value _dispatch_op stashes there,
        NEVER from served_root itself (that would leak the repo path into
        AID_HOME)."""
        target = {"_aid_home": "/state/home"}
        argv, env = srv._op_tools_update_argv(None, "/repo/path", target, {})
        self.assertEqual(argv, ["update", "--target", "/repo/path"])
        self.assertEqual(env, {"AID_HOME": "/state/home"})

    def test_windows_path_posix_ified_in_argv_not_env(self):
        target = {"_aid_home": "C:\\state\\home"}
        argv, env = srv._op_tools_update_argv(None, "C:\\repo\\path", target, {})
        self.assertEqual(argv, ["update", "--target", "C:/repo/path"])
        # env is NOT posix-ified (matches _op_project_add_argv's own convention --
        # only ARGV elements are, never an env-var value).
        self.assertEqual(env, {"AID_HOME": "C:\\state\\home"})


class TestOpToolsUpdateSelfArgv(unittest.TestCase):
    def test_argv_and_env_from_served_root(self):
        """servedRoot here IS aid_home (home scope) -- mirrors
        _op_project_add_argv/_op_project_remove_argv exactly, no
        target['_aid_home'] indirection needed."""
        argv, env = srv._op_tools_update_self_argv(None, "/state/home", {}, {})
        self.assertEqual(argv, ["update", "self"])
        self.assertEqual(env, {"AID_HOME": "/state/home"})


# ===========================================================================
# (3) Full dispatch via a controllable FAKE aid CLI (never the real bin/aid).
# ===========================================================================

class TestToolsUpdateDispatchFakeCli(unittest.TestCase):
    """Fake aid: reads FAKE_MODE from the environment to control its exit
    code / stderr, and echoes back the argv + env it received (proving the
    env/argv wiring), mirroring test_task013's own probe-writer convention.
    srv._AID_CLI_PATH is redirected for the duration of this test class,
    restored in tearDown.

    KI-009: this fake has a bash shebang, so _run_aid_cli's default dispatch
    is forced to the Unix/bash branch (_patch_run_aid_cli_force_unix) for the
    duration of each test -- otherwise, on an ACTUAL Windows host (the
    default `is_windows` seam resolves from the real os.name), the dispatch
    would spawn PowerShell against this bash script instead."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())
        self._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)
        self._fake = self._tmp / "fake-aid.sh"
        self._fake.write_text(
            "#!/usr/bin/env bash\n"
            'mode="${FAKE_MODE:-ok}"\n'
            'printf "ARGV:%s\\n" "$*" >&2\n'
            'printf "AID_HOME:%s\\n" "${AID_HOME:-<unset>}" >&2\n'
            'printf "AID_CODE_HOME:%s\\n" "${AID_CODE_HOME:-<unset>}" >&2\n'
            "case \"$mode\" in\n"
            "  ok) exit 0 ;;\n"
            '  fail) echo "some transient failure" >&2; exit 7 ;;\n'
            '  usage2) echo "unreachable usage-error class" >&2; exit 2 ;;\n'
            "esac\n",
            encoding="utf-8",
        )
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._fake

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        srv._run_aid_cli = self._orig_run_aid_cli
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    # -- tools.update (per-repo, OP_TABLE) -----------------------------------

    def _dispatch_update(self, parsed: dict):
        return srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path", aid_home="/state/home")

    def test_happy_path_is_200(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "ok"}):
            status, body = self._dispatch_update({"op": "tools.update"})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"ok": True, "op": "tools.update"})

    def test_non_empty_args_is_422_before_any_spawn(self):
        """The fake CLI would exit 0 for ANY mode by default (env unset ->
        'ok') -- a 422 here proves semantic_validate short-circuited BEFORE
        spawn, not that the fake happened to fail."""
        status, body = self._dispatch_update({"op": "tools.update", "args": {"force": "true"}})
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_any_nonzero_exit_collapses_to_500_update_failed(self):
        """A non-2 exit (7) maps through status_map_default -- NOT the shared
        _DEFAULT_FALLBACK's 'write-failed' class."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch_update({"op": "tools.update"})
        self.assertEqual(status, 500)
        data = json.loads(body)
        self.assertEqual(data["error"], "update-failed")
        self.assertIn("some transient failure", data["detail"])

    def test_exit_2_also_collapses_to_500_update_failed_not_422(self):
        """Unlike project.add/remove's status_map (where exit 2 -> 422), an
        'aid update' exit 2 is NOT reachable through this closed-argv surface
        per the API Contracts note -- but if the shared helper were ever
        mis-wired to produce one, it must still collapse to 'update-failed'
        (status_map_default), never silently borrow project.add/remove's
        422 semantics."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "usage2"}):
            status, body = self._dispatch_update({"op": "tools.update"})
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "update-failed")

    def test_env_threading_argv_and_aid_home_from_target(self):
        """Proves the full round trip: _dispatch_op stashes aid_home into
        target['_aid_home'], _op_tools_update_argv reads it, and the child
        actually receives it (never AID_CODE_HOME)."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch_update({"op": "tools.update"})
        detail = json.loads(body)["detail"]
        self.assertIn("ARGV:update --target /repo/path", detail)
        self.assertIn("AID_HOME:/state/home", detail)
        self.assertIn("AID_CODE_HOME:<unset>", detail)

    # -- tools.update-self (home, HOME_OP_TABLE) -----------------------------

    def _dispatch_update_self(self, parsed: dict):
        return srv._dispatch_op(srv.HOME_OP_TABLE, parsed, "/state/home")

    def test_update_self_happy_path_is_200(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "ok"}):
            status, body = self._dispatch_update_self({"op": "tools.update-self"})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"ok": True, "op": "tools.update-self"})

    def test_update_self_non_empty_args_is_422_before_any_spawn(self):
        status, body = self._dispatch_update_self({"op": "tools.update-self", "args": {"x": "y"}})
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_update_self_any_nonzero_exit_collapses_to_500_update_failed(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch_update_self({"op": "tools.update-self"})
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "update-failed")

    def test_update_self_env_threading_argv_and_aid_home(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch_update_self({"op": "tools.update-self"})
        detail = json.loads(body)["detail"]
        self.assertIn("ARGV:update self", detail)
        self.assertIn("AID_HOME:/state/home", detail)
        self.assertIn("AID_CODE_HOME:<unset>", detail)


# ===========================================================================
# (3b) Timeout sentinel -> 504 'timed-out' (the out-of-band exit -1, never a
# real 0..255 exit code) -- exercised via a real (but fast) sub-second sleep
# against a per-test overridden 'aid_cli_timeout', so the test itself stays
# bounded (<2s), never the real 600s production ceiling.
# ===========================================================================

class TestToolsUpdateTimeout(unittest.TestCase):
    """KI-009: the slow probe below has a bash shebang, so _run_aid_cli's
    default dispatch is forced to the Unix/bash branch
    (_patch_run_aid_cli_force_unix) for the duration of each test -- see
    TestToolsUpdateDispatchFakeCli's own note."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())
        self._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)
        self._slow = self._tmp / "slow-aid.sh"
        self._slow.write_text("#!/usr/bin/env bash\nsleep 3\n", encoding="utf-8")
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._slow
        # Deep-copy the two rows so the 1s test-local timeout override never
        # leaks into the module-level OP_TABLE/HOME_OP_TABLE for other tests.
        self._orig_op_row = dict(srv.OP_TABLE["tools.update"])
        self._orig_home_row = dict(srv.HOME_OP_TABLE["tools.update-self"])
        srv.OP_TABLE["tools.update"] = dict(self._orig_op_row, aid_cli_timeout=1)
        srv.HOME_OP_TABLE["tools.update-self"] = dict(self._orig_home_row, aid_cli_timeout=1)

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        srv._run_aid_cli = self._orig_run_aid_cli
        srv.OP_TABLE["tools.update"] = self._orig_op_row
        srv.HOME_OP_TABLE["tools.update-self"] = self._orig_home_row
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def test_tools_update_timeout_is_504(self):
        status, body = srv._dispatch_op(srv.OP_TABLE, {"op": "tools.update"}, "/repo/path", aid_home="/state/home")
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")

    def test_tools_update_self_timeout_is_504(self):
        status, body = srv._dispatch_op(srv.HOME_OP_TABLE, {"op": "tools.update-self"}, "/state/home")
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")


# ===========================================================================
# (4) _map_exit_code's 'default_status' parameter, unit-level.
# ===========================================================================

class TestMapExitCodeDefaultStatus(unittest.TestCase):
    def test_unenumerated_code_falls_back_to_given_default(self):
        status_map = {srv._AID_CLI_TIMEOUT_EXIT: (504, "timed-out")}
        result = srv._map_exit_code(9, status_map, (500, "update-failed"))
        self.assertEqual(result, (500, "update-failed"))

    def test_enumerated_code_wins_over_default(self):
        status_map = {srv._AID_CLI_TIMEOUT_EXIT: (504, "timed-out")}
        result = srv._map_exit_code(srv._AID_CLI_TIMEOUT_EXIT, status_map, (500, "update-failed"))
        self.assertEqual(result, (504, "timed-out"))

    def test_no_default_falls_back_to_shared_default_fallback(self):
        """Existing rows (e.g. project.add/remove's _PROJECT_OP_STATUS_MAP) pass
        no status_map_default -- must be UNCHANGED behavior (500, 'write-failed')."""
        result = srv._map_exit_code(9, srv._PROJECT_OP_STATUS_MAP, None)
        self.assertEqual(result, (500, "write-failed"))


# ===========================================================================
# (5) OP_TABLE / HOME_OP_TABLE structural registration sanity checks.
# ===========================================================================

class TestOpTableRegistration(unittest.TestCase):
    def test_tools_update_row_shape(self):
        row = srv.OP_TABLE["tools.update"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["arg_schema"], {})
        self.assertIs(row["build_argv"], srv._op_tools_update_argv)
        self.assertIs(row["semantic_validate"], srv._validate_no_args)
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertEqual(row["aid_cli_timeout"], 600)
        self.assertIs(row["status_map"], srv._TOOLS_UPDATE_STATUS_MAP)
        self.assertEqual(row["status_map_default"], (500, "update-failed"))
        self.assertNotIn("resolve_target", row)
        self.assertNotIn("post_verify", row)

    def test_tools_update_self_row_shape(self):
        row = srv.HOME_OP_TABLE["tools.update-self"]
        self.assertEqual(row["scope"], "home")
        self.assertEqual(row["arg_schema"], {})
        self.assertIs(row["build_argv"], srv._op_tools_update_self_argv)
        self.assertIs(row["semantic_validate"], srv._validate_no_args)
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertEqual(row["aid_cli_timeout"], 600)
        self.assertIs(row["status_map"], srv._TOOLS_UPDATE_STATUS_MAP)
        self.assertEqual(row["status_map_default"], (500, "update-failed"))
        self.assertNotIn("resolve_target", row)
        self.assertNotIn("post_verify", row)

    def test_both_ops_reuse_the_same_shared_aid_cli_spawn_as_project_ops(self):
        """KI-004: the SAME shared resolver task-013 introduced (_spawn_aid_cli /
        _run_aid_cli) is reused, never re-invented, by feature-004's rows."""
        self.assertIs(srv.OP_TABLE["tools.update"]["spawn"], srv.HOME_OP_TABLE["project.add"]["spawn"])
        self.assertIs(srv.HOME_OP_TABLE["tools.update-self"]["spawn"], srv.HOME_OP_TABLE["project.remove"]["spawn"])

    def test_timeout_longer_than_registry_ops_default(self):
        self.assertGreater(srv.OP_TABLE["tools.update"]["aid_cli_timeout"], srv._DEFAULT_AID_CLI_TIMEOUT)
        self.assertGreater(srv.HOME_OP_TABLE["tools.update-self"]["aid_cli_timeout"], srv._DEFAULT_AID_CLI_TIMEOUT)


# ===========================================================================
# (6) tools.add / tools.remove (work-017 post-dogfood): per-project host-tool
# management, moved off the home card onto the project page's Tools section.
# Mirrors tools.update's shared-aid-CLI shape (KI-004 resolver, _spawn_aid_cli,
# target['_aid_home'] smuggling) but take a single validated `tool` id.
# ===========================================================================

class TestValidateToolArg(unittest.TestCase):
    """_validate_tool_arg: pre-dispatch shape/charset validation ONLY -- NOT a
    claim the tool exists (the CLI stays sole authority; an unknown but
    well-formed id reaches the fake/real CLI and gets its own exit 2 -> 422)."""

    def test_valid_lowercase_kebab_id_is_none(self):
        self.assertIsNone(srv._validate_tool_arg({"tool": "claude-code"}))
        self.assertIsNone(srv._validate_tool_arg({"tool": "cursor"}))
        self.assertIsNone(srv._validate_tool_arg({"tool": "a"}))
        self.assertIsNone(srv._validate_tool_arg({"tool": "a" * 64}))

    def test_missing_tool_key_is_rejected(self):
        err = srv._validate_tool_arg({})
        self.assertIsNotNone(err)
        self.assertIn("required", err)

    def test_empty_string_is_rejected(self):
        err = srv._validate_tool_arg({"tool": ""})
        self.assertIsNotNone(err)
        self.assertIn("required", err)

    def test_non_string_is_rejected(self):
        for bad in (None, 123, ["claude-code"], {"x": 1}, True):
            with self.subTest(value=bad):
                err = srv._validate_tool_arg({"tool": bad})
                self.assertIsNotNone(err)

    def test_uppercase_is_rejected(self):
        err = srv._validate_tool_arg({"tool": "Claude-Code"})
        self.assertIsNotNone(err)
        self.assertIn("lowercase", err)

    def test_leading_hyphen_is_rejected(self):
        # _RE_TOOL_ID requires the FIRST char to be [a-z0-9] -- a leading
        # hyphen (or any non-alnum first char) is rejected.
        err = srv._validate_tool_arg({"tool": "-claude-code"})
        self.assertIsNotNone(err)

    def test_space_is_rejected(self):
        err = srv._validate_tool_arg({"tool": "claude code"})
        self.assertIsNotNone(err)

    def test_control_char_is_rejected(self):
        err = srv._validate_tool_arg({"tool": "claude\x1bcode"})
        self.assertIsNotNone(err)

    def test_over_length_is_rejected(self):
        # _RE_TOOL_ID caps at 64 chars total.
        err = srv._validate_tool_arg({"tool": "a" * 65})
        self.assertIsNotNone(err)

    def test_reserved_self_keyword_is_rejected(self):
        # 'self' matches the lowercase-kebab charset but is the CLI's RESERVED
        # keyword (`aid remove self` = full CLI self-uninstall). Must be rejected
        # explicitly, not left to the CLI's --target flag-parser coincidence.
        err = srv._validate_tool_arg({"tool": "self"})
        self.assertIsNotNone(err)
        self.assertIn("reserved", err.lower())


class TestOpToolsAddArgv(unittest.TestCase):
    def test_argv_and_env_from_stashed_aid_home(self):
        target = {"_aid_home": "/state/home"}
        argv, env = srv._op_tools_add_argv(None, "/repo/path", target, {"tool": "cursor"})
        self.assertEqual(argv, ["add", "cursor", "--target", "/repo/path"])
        self.assertEqual(env, {"AID_HOME": "/state/home"})

    def test_windows_path_posix_ified_in_argv_not_env(self):
        target = {"_aid_home": "C:\\state\\home"}
        argv, env = srv._op_tools_add_argv(None, "C:\\repo\\path", target, {"tool": "cursor"})
        self.assertEqual(argv, ["add", "cursor", "--target", "C:/repo/path"])
        self.assertEqual(env, {"AID_HOME": "C:\\state\\home"})


class TestOpToolsRemoveArgv(unittest.TestCase):
    def test_argv_and_env_from_stashed_aid_home(self):
        target = {"_aid_home": "/state/home"}
        argv, env = srv._op_tools_remove_argv(None, "/repo/path", target, {"tool": "cursor"})
        self.assertEqual(argv, ["remove", "cursor", "--target", "/repo/path"])
        self.assertEqual(env, {"AID_HOME": "/state/home"})

    def test_windows_path_posix_ified_in_argv_not_env(self):
        target = {"_aid_home": "C:\\state\\home"}
        argv, env = srv._op_tools_remove_argv(None, "C:\\repo\\path", target, {"tool": "cursor"})
        self.assertEqual(argv, ["remove", "cursor", "--target", "C:/repo/path"])
        self.assertEqual(env, {"AID_HOME": "C:\\state\\home"})


class TestToolsAddRemoveDispatchFakeCli(unittest.TestCase):
    """Fake aid CLI (same convention as TestToolsUpdateDispatchFakeCli above):
    reads FAKE_MODE to control its exit code, echoes argv/env it received.
    srv._AID_CLI_PATH is redirected for the duration of this test class."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())
        self._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)
        self._fake = self._tmp / "fake-aid.sh"
        self._fake.write_text(
            "#!/usr/bin/env bash\n"
            'mode="${FAKE_MODE:-ok}"\n'
            'printf "ARGV:%s\\n" "$*" >&2\n'
            'printf "AID_HOME:%s\\n" "${AID_HOME:-<unset>}" >&2\n'
            "case \"$mode\" in\n"
            "  ok) exit 0 ;;\n"
            '  fail) echo "some transient failure" >&2; exit 9 ;;\n'
            '  usage2) echo "unknown tool id" >&2; exit 2 ;;\n'
            "esac\n",
            encoding="utf-8",
        )
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._fake

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        srv._run_aid_cli = self._orig_run_aid_cli
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def _dispatch(self, op: str, parsed: dict):
        return srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path", aid_home="/state/home")

    # -- tools.add ------------------------------------------------------------

    def test_add_happy_path_is_200(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "ok"}):
            status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {"tool": "cursor"}})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"ok": True, "op": "tools.add"})

    def test_add_invalid_tool_is_400_before_any_spawn(self):
        """An uppercase/invalid tool id is rejected by _validate_tool_arg
        (pre_validate) BEFORE any spawn -- the fake CLI would exit 0 by
        default, so a 400 here proves the pre-dispatch hook fired first."""
        status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {"tool": "Claude-Code"}})
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_add_missing_tool_is_400(self):
        status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {}})
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_add_cli_exit_2_is_422_invalid_value(self):
        """Unlike tools.update (whose exit 2 collapses to 500 'update-failed'),
        tools.add/remove's own status_map maps the CLI's exit 2 (an unknown
        tool id that slipped past the charset pre-check) to 422 -- the SAME
        semantics project.add/remove use for their own exit 2."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "usage2"}):
            status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {"tool": "unknown-tool"}})
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_add_other_nonzero_exit_collapses_to_500_tools_op_failed(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {"tool": "cursor"}})
        self.assertEqual(status, 500)
        data = json.loads(body)
        self.assertEqual(data["error"], "tools-op-failed")
        self.assertIn("some transient failure", data["detail"])

    def test_add_env_threading_argv_and_aid_home_from_target(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch("tools.add", {"op": "tools.add", "args": {"tool": "cursor"}})
        detail = json.loads(body)["detail"]
        self.assertIn("ARGV:add cursor --target /repo/path", detail)
        self.assertIn("AID_HOME:/state/home", detail)

    # -- tools.remove -----------------------------------------------------

    def test_remove_happy_path_is_200(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "ok"}):
            status, body = self._dispatch("tools.remove", {"op": "tools.remove", "args": {"tool": "cursor"}})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"ok": True, "op": "tools.remove"})

    def test_remove_invalid_tool_is_400_before_any_spawn(self):
        status, body = self._dispatch("tools.remove", {"op": "tools.remove", "args": {"tool": "has space"}})
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "bad-request")

    def test_remove_cli_exit_2_is_422_invalid_value(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "usage2"}):
            status, body = self._dispatch("tools.remove", {"op": "tools.remove", "args": {"tool": "cursor"}})
        self.assertEqual(status, 422)
        self.assertEqual(json.loads(body)["error"], "invalid-value")

    def test_remove_other_nonzero_exit_collapses_to_500_tools_op_failed(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch("tools.remove", {"op": "tools.remove", "args": {"tool": "cursor"}})
        self.assertEqual(status, 500)
        self.assertEqual(json.loads(body)["error"], "tools-op-failed")

    def test_remove_env_threading_argv_and_aid_home_from_target(self):
        with mock.patch.dict("os.environ", {"FAKE_MODE": "fail"}):
            status, body = self._dispatch("tools.remove", {"op": "tools.remove", "args": {"tool": "cursor"}})
        detail = json.loads(body)["detail"]
        self.assertIn("ARGV:remove cursor --target /repo/path", detail)
        self.assertIn("AID_HOME:/state/home", detail)


class TestToolsAddRemoveTimeout(unittest.TestCase):
    """Timeout sentinel -> 504 'timed-out', mirroring TestToolsUpdateTimeout's
    own bounded-sleep convention (never the real 600s production ceiling)."""

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())
        self._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)
        self._slow = self._tmp / "slow-aid.sh"
        self._slow.write_text("#!/usr/bin/env bash\nsleep 3\n", encoding="utf-8")
        self._orig_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = self._slow
        self._orig_add_row = dict(srv.OP_TABLE["tools.add"])
        self._orig_remove_row = dict(srv.OP_TABLE["tools.remove"])
        srv.OP_TABLE["tools.add"] = dict(self._orig_add_row, aid_cli_timeout=1)
        srv.OP_TABLE["tools.remove"] = dict(self._orig_remove_row, aid_cli_timeout=1)

    def tearDown(self) -> None:
        srv._AID_CLI_PATH = self._orig_path
        srv._run_aid_cli = self._orig_run_aid_cli
        srv.OP_TABLE["tools.add"] = self._orig_add_row
        srv.OP_TABLE["tools.remove"] = self._orig_remove_row
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def test_tools_add_timeout_is_504(self):
        status, body = srv._dispatch_op(
            srv.OP_TABLE, {"op": "tools.add", "args": {"tool": "cursor"}}, "/repo/path", aid_home="/state/home"
        )
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")

    def test_tools_remove_timeout_is_504(self):
        status, body = srv._dispatch_op(
            srv.OP_TABLE, {"op": "tools.remove", "args": {"tool": "cursor"}}, "/repo/path", aid_home="/state/home"
        )
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")


class TestOpTableRegistrationToolsAddRemove(unittest.TestCase):
    def test_tools_add_row_shape(self):
        row = srv.OP_TABLE["tools.add"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["arg_schema"], {"tool": {"required": True}})
        self.assertIs(row["build_argv"], srv._op_tools_add_argv)
        self.assertIs(row["pre_validate"], srv._validate_tool_arg)
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertEqual(row["aid_cli_timeout"], srv._TOOLS_UPDATE_TIMEOUT)
        self.assertIs(row["status_map"], srv._TOOLS_OP_STATUS_MAP)
        self.assertEqual(row["status_map_default"], (500, "tools-op-failed"))
        self.assertNotIn("semantic_validate", row)
        self.assertNotIn("resolve_target", row)
        self.assertNotIn("post_verify", row)

    def test_tools_remove_row_shape(self):
        row = srv.OP_TABLE["tools.remove"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["arg_schema"], {"tool": {"required": True}})
        self.assertIs(row["build_argv"], srv._op_tools_remove_argv)
        self.assertIs(row["pre_validate"], srv._validate_tool_arg)
        self.assertIs(row["spawn"], srv._spawn_aid_cli)
        self.assertEqual(row["aid_cli_timeout"], srv._TOOLS_UPDATE_TIMEOUT)
        self.assertIs(row["status_map"], srv._TOOLS_OP_STATUS_MAP)
        self.assertEqual(row["status_map_default"], (500, "tools-op-failed"))
        self.assertNotIn("semantic_validate", row)
        self.assertNotIn("resolve_target", row)
        self.assertNotIn("post_verify", row)

    def test_add_and_remove_share_the_same_pre_validate_and_status_map(self):
        self.assertIs(srv.OP_TABLE["tools.add"]["pre_validate"], srv.OP_TABLE["tools.remove"]["pre_validate"])
        self.assertIs(srv.OP_TABLE["tools.add"]["status_map"], srv.OP_TABLE["tools.remove"]["status_map"])

    def test_reuses_the_same_shared_aid_cli_spawn_as_tools_update(self):
        """KI-004: the SAME shared resolver, never re-invented."""
        self.assertIs(srv.OP_TABLE["tools.add"]["spawn"], srv.OP_TABLE["tools.update"]["spawn"])
        self.assertIs(srv.OP_TABLE["tools.remove"]["spawn"], srv.OP_TABLE["tools.update"]["spawn"])

    def test_status_map_distinct_from_tools_update_own_map(self):
        """tools.add/remove's exit-2 -> 422 semantics are genuinely DIFFERENT
        from tools.update's exit-2 -> 500 'update-failed' collapse -- not a
        shared/aliased map that happens to look right for only one op."""
        self.assertIsNot(srv._TOOLS_OP_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_MAP)
        self.assertEqual(srv._map_exit_code(2, srv._TOOLS_OP_STATUS_MAP, srv._TOOLS_OP_STATUS_DEFAULT),
                         (422, "invalid-value"))
        self.assertEqual(srv._map_exit_code(2, srv._TOOLS_UPDATE_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_DEFAULT),
                         (500, "update-failed"))

    def test_tools_update_row_unchanged(self):
        """tools.update itself is UNCHANGED by this addition (still exists,
        still project scope, still argument-free)."""
        row = srv.OP_TABLE["tools.update"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["arg_schema"], {})
        self.assertIs(row["semantic_validate"], srv._validate_no_args)
        self.assertNotIn("pre_validate", row)


if __name__ == "__main__":
    unittest.main(verbosity=2)
