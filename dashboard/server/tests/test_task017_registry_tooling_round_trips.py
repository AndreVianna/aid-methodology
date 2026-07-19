"""
test_task017_registry_tooling_round_trips.py -- "Registry + tooling op
round-trips" (task-017, feature-003-project-registry / feature-004-update-tools,
delivery-002, work-017-cli-improvements).

This is a TEST-type task: no production code (that is tasks 013-016). It closes
the ONE gap the individual op-implementation tasks' own suites deliberately left
open -- a genuine cross-runtime BYTE-parity assertion (server.py vs server.mjs
returning IDENTICAL HTTP status + response bytes for the SAME scenario) -- plus
two smaller gaps neither task-013's nor task-015's own suite covers:

  1. TWIN OP-HANDLER PARITY (the new thing this task adds; BLUEPRINT AC4 /
     feature-003 SPEC AC4 / feature-004 SPEC AC4, "Twin op-handler parity is
     asserted"). test_task013_project_registry_ops.py/.mjs and
     test_task015_tools_update_ops.py/.mjs each prove their OWN runtime's
     dispatch logic thoroughly (fake-CLI-driven `_dispatch_op`/`dispatchOp`
     unit coverage, argv-builders, status-map hooks, row-shape checks) -- but
     NEITHER file ever puts the two runtimes' ACTUAL outputs side by side for
     an identical input. TestProjectAddParity / TestProjectRemoveParity /
     TestToolsUpdateParity / TestToolsUpdateSelfParity / TestToolsUpdateTimeoutParity
     below do exactly that: the SAME fake `aid` CLI script (bash, byte-identical
     text) is dispatched through Python's `srv._dispatch_op` AND a live Node
     subprocess importing a sliced copy of server.mjs's `dispatchOp` (the same
     slice-and-export technique test_task012_consuming_round_trips.py's
     `_NodeSlicedServerFixture` established for `readSettings`, extended here
     to ALSO redirect the `AID_CLI_PATH` const so Node spawns the identical fake
     script Python does) -- and the two (status, response-body-bytes) pairs are
     asserted EQUAL, not just each independently "looks right".

  2. tools.update's unknown-`<id>` 404 (task-017 Scope: "unknown repo `<id>` ...
     via POST /r/<id>/api/op"). This id-resolution 404 fires in `_serve_op`/
     `serveOp` BEFORE any OP_TABLE dispatch -- neither test_task013's nor
     test_task015's own suite adds HTTP-layer (socket-bound) coverage for
     their rows (both docstrings say so explicitly, and precedent is
     test_task011_dispatch_round_trip.py's own boundary: `_dispatch_op` is
     the correct in-process boundary for those tasks). TestToolsUpdateUnknownRepoIdLive
     below closes it -- deferred-live per this host's port-binding constraint
     (see LOCAL TEST NOTE), its Node twin lives in the companion
     test_task017_registry_tooling_round_trips.mjs file.

  3. Exit-alphabet DISTINCTNESS, explicitly asserted (task-017 Scope:
     "Exit-alphabet coverage... Assert both distinct per-op alphabets"):
     TestExitAlphabetDistinctness proves the `aid projects` alphabet (exit 2 ->
     422) and the `aid update` alphabet (any other non-zero -> 500
     'update-failed'; timeout sentinel -> 504 'timed-out') are genuinely
     DIFFERENT maps -- not that one accidentally aliases the other for exit 2.

Deliberately NOT re-covered here (thin pointers only, see
TestProjectAddRealPersistenceAlreadyCovered /
TestProjectRemoveIdMapNotBodyAlreadyCovered below) -- already exhaustively
covered by test_task013_project_registry_ops.py/.mjs:
  - "200 + persistence" for project.add/remove through the REAL bin/aid CLI
    (TestProjectRegistryRealCliRoundTrip / Node group [C]) -- unlike this
    file's fake-CLI parity cases (which prove STATUS/BODY parity, not real
    disk persistence), that suite proves the real CLI actually mutates
    registry.yml. Not duplicated here.
  - "confirm the path is resolved from id_map, never the body"
    (TestProjectRemoveDispatchFakeCli.test_body_supplied_path_is_ignored...).

Automated/manual coverage boundary (task-017 Scope, mirrors the
delivery-001/task-012 convention): this file (and its .mjs companion) covers
server op-handler round-trips + twin byte-parity ONLY. The client-side
index.html JS added by tasks 014/016 (write_enabled gating, the Remove
confirm button-flip, the Update busy-state + restart advisory) is NOT placed
under automated test here -- it is manual-acceptance-only against those
tasks' own ACs, exactly as delivery-001/task-012 scoped settings.set/
task.rename's client-rendering half out of its own suite.

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every parity class below
calls `srv._dispatch_op(...)` directly (no `_ServerThread`) and shells out to
`node --input-type=module` as a bounded subprocess (no port bind) -- safe to
run locally per the project's port-binding-server-test constraint, and all
were exercised directly as part of this task's own verification pass (skipped,
not failed, when `node` is absent from PATH). TestToolsUpdateUnknownRepoIdLive
is the ONE class in this file that binds a loopback socket (`_ServerThread`) --
per that same constraint it is NOT executed locally; deferred to CI.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
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
from dashboard.server.tests.test_server_py import (
    _ServerThread, _make_aid_home, _write_registry, _repo_id8, _patch_run_aid_cli_force_unix,
)

_SERVER_MJS = _DASHBOARD_DIR / "server" / "server.mjs"

# Stable single-line cut marker -- kept in lockstep with
# test_task012_consuming_round_trips.py's identical marker string.
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()


# ---------------------------------------------------------------------------
# Shared FAKE aid CLI -- ONE bash script, byte-identical text, spawned by BOTH
# runtimes via `bash <script> <argv...>` (mirrors test_task013's/test_task015's
# own fake-CLI convention, generalized across all four ops since none of the
# scenarios below depend on op-specific argv content -- only on FAKE_MODE).
# ---------------------------------------------------------------------------

_FAKE_AID_SCRIPT = (
    "#!/usr/bin/env bash\n"
    'mode="${FAKE_MODE:-ok}"\n'
    "case \"$mode\" in\n"
    "  ok) exit 0 ;;\n"
    '  warn) echo "WARN: aid: shared registry write declined or unavailable" >&2; exit 0 ;;\n'
    '  err2) echo "ERROR: aid: bad request" >&2; exit 2 ;;\n'
    '  err9) echo "unexpected failure" >&2; exit 9 ;;\n'
    "  remove_ok)\n"
    '    path="$3"\n'
    '    if [[ -n "${FAKE_REG_FILE:-}" && -f "${FAKE_REG_FILE}" ]]; then\n'
    '      grep -vxF "  - ${path}" "${FAKE_REG_FILE}" > "${FAKE_REG_FILE}.tmp" '
    '&& mv "${FAKE_REG_FILE}.tmp" "${FAKE_REG_FILE}"\n'
    "    fi\n"
    "    exit 0 ;;\n"
    "  noop_clean) exit 0 ;;\n"
    "  slow) sleep 3 ;;\n"
    # >1 MiB of stdout then a clean exit 0: exercises the maxBuffer twin-parity
    # path (Node's default 1 MiB cap must be disabled so a verbose child is not
    # SIGTERM-killed, matching Python's unbounded capture_output). ~2 MB.
    "  bigout) yes X | head -c 2000000 ; exit 0 ;;\n"
    "esac\n"
)


def _write_fake_aid(base: Path) -> Path:
    base.mkdir(parents=True, exist_ok=True)
    script = base / "fake-aid.sh"
    script.write_text(_FAKE_AID_SCRIPT, encoding="utf-8")
    return script


# ---------------------------------------------------------------------------
# Node sliced-module dispatch fixture: mirrors test_task012_consuming_round_
# trips.py's `_NodeSlicedServerFixture` technique (server.mjs self-executes on
# import -- parses argv, binds a socket -- so it cannot be imported as-is;
# slice the source right before the side-effecting 'Main' tail and re-export
# what's needed), EXTENDED to also redirect the `AID_CLI_PATH` const (so the
# Node side spawns the SAME fake CLI script the Python side uses -- otherwise
# there would be nothing to compare) and, optionally, `TOOLS_UPDATE_TIMEOUT`
# (for the 504 parity case, so the test stays bounded rather than waiting the
# real 600s production ceiling).
# ---------------------------------------------------------------------------

def _sliced_server_mjs_source(aid_cli_path: Path, tools_timeout_ms: "int | None" = None) -> str:
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    sliced = text[:idx]

    old_cli_line = 'const AID_CLI_PATH = join(_CODE_HOME, "bin", "aid");'
    assert old_cli_line in sliced, (
        "server.mjs's AID_CLI_PATH const declaration line has changed shape -- "
        "this test's slice-and-redirect cut point needs updating"
    )
    new_cli_line = f"const AID_CLI_PATH = {json.dumps(str(aid_cli_path))};"
    sliced = sliced.replace(old_cli_line, new_cli_line, 1)

    if tools_timeout_ms is not None:
        old_timeout_line = "const TOOLS_UPDATE_TIMEOUT = 600000;"
        assert old_timeout_line in sliced, (
            "server.mjs's TOOLS_UPDATE_TIMEOUT const declaration line has changed shape -- "
            "this test's timeout-override cut point needs updating"
        )
        sliced = sliced.replace(
            old_timeout_line, f"const TOOLS_UPDATE_TIMEOUT = {tools_timeout_ms};", 1,
        )

    # KI-009: force runAidCli's default isWin resolution to the Unix/bash
    # branch, regardless of the ACTUAL host OS this Node driver runs on --
    # every fake CLI this fixture spawns is a bash-shebang script (never a
    # .ps1 twin), so a Windows-host test run must not silently take the
    # Windows/PowerShell dispatch branch. Scoped to JUST runAidCli's own
    # isWin-default line via its enclosing function body (the IDENTICAL text
    # also appears in resolveBashExe/nativeFsPath, which must NOT be touched --
    # those seams are exercised with an EXPLICIT isWin argument by their own
    # tests, never relying on this default).
    func_marker = "function runAidCli("
    func_idx = sliced.find(func_marker)
    assert func_idx != -1, "server.mjs's runAidCli(...) function is gone -- this slice needs updating"
    old_default_line = 'const win = isWin === undefined ? process.platform === "win32" : isWin;'
    default_idx = sliced.find(old_default_line, func_idx)
    assert default_idx != -1, (
        "runAidCli's isWin-default line has changed shape -- this slice's KI-009 "
        "force-Unix-dispatch cut point needs updating"
    )
    new_default_line = "const win = isWin === undefined ? false : isWin;"
    sliced = sliced[:default_idx] + new_default_line + sliced[default_idx + len(old_default_line):]

    return sliced + "\nexport { dispatchOp, OP_TABLE, HOME_OP_TABLE, nativeFsPath };\n"


class _NodeSlicedDispatchFixture:
    """setUpClass/tearDownClass helper: writes a per-class sliced server.mjs
    copy once, deletes it afterward regardless of outcome. `_node_dispatch_many`
    runs ALL cases handed to it in ONE Node subprocess invocation (minimizes
    per-call fork overhead -- this repo's own perf note: forking is
    ~1s/spawn on this host's Git-Bash/MSYS class of environment) and returns a
    list of (status, body_text) tuples in the same order, resetting
    FAKE_MODE/FAKE_REG_FILE between cases so no state leaks across them.

    KI-009: every fake CLI this fixture spawns is a bash-shebang script (never
    a .ps1 twin), so BOTH runtimes' default `is_windows`/`isWin` dispatch
    resolution must be forced to the Unix/bash branch regardless of the
    ACTUAL host OS the suite runs on -- otherwise a Windows-host run (this
    repo's own local dev sandbox) would spawn PowerShell/pwsh against a bash
    script on either side. `_sliced_server_mjs_source` forces the Node side
    (a source-text substitution scoped to JUST runAidCli's own isWin-default
    line -- resolveBashExe/nativeFsPath's identical lines are left untouched,
    since those seams are exercised with an EXPLICIT isWin argument by their
    own tests elsewhere); each subclass below forces the Python side via
    `_patch_run_aid_cli_force_unix` in its own setUpClass/tearDownClass."""

    _slice_path: Path
    _fake_cli_path: Path
    _fake_dir: Path

    @classmethod
    def _tools_timeout_ms(cls) -> "int | None":
        """Overridden by TestToolsUpdateTimeoutParity to shrink the production
        600s ceiling to a bounded test value; every other class leaves the
        real 600000 constant untouched (its fake-CLI modes all return
        instantly, so the real ceiling is never exercised)."""
        return None

    @classmethod
    def setUpClass(cls) -> None:
        cls._fake_dir = Path(tempfile.mkdtemp())
        cls._fake_cli_path = _write_fake_aid(cls._fake_dir)
        cls._slice_path = _SERVER_DIR / f"_test_task017_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(
            _sliced_server_mjs_source(cls._fake_cli_path, tools_timeout_ms=cls._tools_timeout_ms()),
            encoding="utf-8",
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)
        shutil.rmtree(str(cls._fake_dir), ignore_errors=True)

    def _node_dispatch_many(self, cases: list[dict]) -> list[tuple[int, str]]:
        """cases: [{table: 'OP_TABLE'|'HOME_OP_TABLE', parsed: {...},
        servedRoot: str, aidHome: str, env: {...}}, ...]. Runs them
        SEQUENTIALLY in one Node process."""
        driver = (
            "import { dispatchOp, OP_TABLE, HOME_OP_TABLE } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const cases = {json.dumps(cases)};\n"
            "const results = [];\n"
            "for (const c of cases) {\n"
            "  delete process.env.FAKE_MODE;\n"
            "  delete process.env.FAKE_REG_FILE;\n"
            "  Object.assign(process.env, c.env || {});\n"
            "  const table = c.table === 'OP_TABLE' ? OP_TABLE : HOME_OP_TABLE;\n"
            "  const [status, body] = dispatchOp(table, c.parsed, c.servedRoot, c.aidHome);\n"
            "  results.push([status, Buffer.from(body).toString('utf-8')]);\n"
            "}\n"
            "process.stdout.write(JSON.stringify(results));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node dispatch driver failed: {result.stderr[:1000]}")
        return [tuple(x) for x in json.loads(result.stdout.strip())]


def _assert_parity(
    test: unittest.TestCase,
    py_result: "tuple[int, bytes]",
    node_result: "tuple[int, str]",
    expected_status: int,
    expected_error: "str | None" = None,
) -> None:
    """The core twin-parity assertion this task adds: BOTH runtimes must
    independently produce the EXPECTED status, AND the two runtimes' actual
    (status, body-bytes) pairs must be IDENTICAL to each other -- not merely
    "both look plausible"."""
    py_status, py_body = py_result
    node_status, node_body = node_result
    py_text = py_body.decode("utf-8") if isinstance(py_body, (bytes, bytearray)) else py_body
    test.assertEqual(py_status, expected_status, f"python status mismatch; body={py_text!r}")
    test.assertEqual(node_status, expected_status, f"node status mismatch; body={node_body!r}")
    test.assertEqual(py_status, node_status, "python/node HTTP status DIVERGE (twin parity broken)")
    test.assertEqual(py_text, node_body, "python/node response BODY bytes DIVERGE (twin parity broken)")
    if expected_error is not None:
        test.assertEqual(json.loads(py_text)["error"], expected_error)


# ===========================================================================
# (A) project.add: twin parity across the full status_map + fail-open-guard
# + pre-validate alphabet (feature-003 SPEC API Contracts; task-017 Scope
# bullet 1).
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestProjectAddParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        super().tearDownClass()

    def test_all_cases_parity(self) -> None:
        # (name, path_value, env, expected_status, expected_error)
        cases = [
            ("happy",          "/abs/project/path",        {"FAKE_MODE": "ok"},   200, None),
            ("fail_open_warn", "/abs/project/path",        {"FAKE_MODE": "warn"}, 500, "write-unverified"),
            ("relative_path",  "relative/path/to/proj",    {},                    400, "bad-request"),
            ("nul_byte",       "/abs/path\x00evil",         {},                    400, "bad-request"),
            ("newline",        "/abs/path\nwith/newline",   {},                    400, "bad-request"),
            ("control_char",   "/abs/path\x1bevil",         {},                    400, "bad-request"),
            ("overlong",       "/" + ("a" * 4096),          {},                    400, "bad-request"),
            ("cli_exit2",      "/abs/project/path",        {"FAKE_MODE": "err2"}, 422, "invalid-value"),
            ("cli_exit9",      "/abs/project/path",        {"FAKE_MODE": "err9"}, 500, "write-failed"),
        ]

        node_cases = [
            {
                "table": "HOME_OP_TABLE",
                "parsed": {"op": "project.add", "args": {"path": path_value}},
                "servedRoot": "/state/home",
                "aidHome": "/state/home",
                "env": env,
            }
            for (_name, path_value, env, _status, _err) in cases
        ]
        node_results = self._node_dispatch_many(node_cases)

        for (name, path_value, env, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                with mock.patch.dict("os.environ", env, clear=False):
                    py_result = srv._dispatch_op(
                        srv.HOME_OP_TABLE,
                        {"op": "project.add", "args": {"path": path_value}},
                        "/state/home",
                    )
                _assert_parity(self, py_result, node_result, expected_status, expected_error)


class TestProjectAddRealPersistenceAlreadyCovered(unittest.TestCase):
    """AC-traceability pointer only (task-017 Scope: "200 + persistence") --
    ALREADY exhaustively covered through the REAL bin/aid CLI (not a fake) by
    test_task013_project_registry_ops.py's
    TestProjectRegistryRealCliRoundTrip.test_add_then_remove_round_trip_persists_to_disk
    and its Node twin (test_task013_project_registry_ops.mjs group [C],
    cases C.4/C.6). This file's TestProjectAddParity above proves STATUS/BODY
    twin parity for a 200 exit (via a fake CLI, which cannot prove real disk
    persistence); this pointer is a thin, self-contained re-assertion for
    direct traceability from THIS task's own suite, without duplicating that
    fixture (same convention test_task012_consuming_round_trips.py's
    TestTaskRenameRoundTripAlreadyCovered established)."""

    def test_pointer_to_real_cli_persistence_round_trip(self) -> None:
        from dashboard.server.tests import test_task013_project_registry_ops as t013
        self.assertTrue(
            hasattr(t013, "TestProjectRegistryRealCliRoundTrip"),
            "test_task013_project_registry_ops.py's real-CLI persistence round trip is gone",
        )


# ===========================================================================
# (B) project.remove: twin parity across the full status_map + fail-open
# guard (both the explicit-WARN and the phantom-success/still-in-union
# triggers) + 404 target resolution (task-017 Scope bullet 2).
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestProjectRemoveParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        super().tearDownClass()

    def setUp(self) -> None:
        self._py_base = Path(tempfile.mkdtemp())
        self._node_base = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._py_base), ignore_errors=True)
        shutil.rmtree(str(self._node_base), ignore_errors=True)

    def _seed(self, base: Path, case_name: str, registered: bool) -> "tuple[Path, str, str]":
        """A fresh aid_home per case, seeded with a path whose LENGTH varies by
        case_name -- guarantees a distinct registry.yml byte size per case, so
        _get_id_map's/getIdMap's mtime+size-keyed cache (module-global, keyed
        on stat tuples alone -- see server.py's _cache_key) can never collide
        between two different cases' directories created in quick succession."""
        aid_home = base / f"aid_home_{case_name}"
        _make_aid_home(aid_home)
        path = f"/tmp/fake/remove-me-{case_name}"
        _write_registry(aid_home, [path] if registered else [])
        return aid_home, path, _repo_id8(path)

    def test_all_cases_parity(self) -> None:
        cases = [
            # (name, fake_mode, expected_status, expected_error)
            ("happy",   "remove_ok",  200, None),
            ("unknown", None,         404, "not-found"),
            ("phantom", "noop_clean", 500, "write-unverified"),
            ("warn",    "warn",       500, "write-unverified"),
            ("exit2",   "err2",       422, "invalid-value"),
        ]

        node_cases = []
        node_fixtures = []
        for name, fake_mode, _status, _err in cases:
            node_home, node_path, node_id = self._seed(self._node_base, name, registered=(name != "unknown"))
            node_fixtures.append((node_home, node_path, node_id))
            target_id = "deadbeefcafe" if name == "unknown" else node_id
            env = {"FAKE_MODE": fake_mode} if fake_mode else {}
            if fake_mode:
                env["FAKE_REG_FILE"] = str(node_home / "registry.yml")
            node_cases.append({
                "table": "HOME_OP_TABLE",
                "parsed": {"op": "project.remove", "target": {"id": target_id}},
                "servedRoot": str(node_home),
                "aidHome": str(node_home),
                "env": env,
            })
        node_results = self._node_dispatch_many(node_cases)

        for (name, fake_mode, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                py_home, py_path, py_id = self._seed(self._py_base, name, registered=(name != "unknown"))
                target_id = "deadbeefcafe" if name == "unknown" else py_id
                env = {"FAKE_MODE": fake_mode} if fake_mode else {}
                if fake_mode:
                    env["FAKE_REG_FILE"] = str(py_home / "registry.yml")
                with mock.patch.dict("os.environ", env, clear=False):
                    py_result = srv._dispatch_op(
                        srv.HOME_OP_TABLE,
                        {"op": "project.remove", "target": {"id": target_id}},
                        str(py_home),
                    )
                _assert_parity(self, py_result, node_result, expected_status, expected_error)


class TestProjectRemoveIdMapNotBodyAlreadyCovered(unittest.TestCase):
    """AC-traceability pointer only (task-017 Scope: "confirm the path is
    resolved from id_map, never the body") -- ALREADY covered by
    test_task013_project_registry_ops.py's TestProjectRemoveDispatchFakeCli.
    test_body_supplied_path_is_ignored_id_map_path_used_verbatim. Not
    duplicated here."""

    def test_pointer_to_id_map_not_body_coverage(self) -> None:
        from dashboard.server.tests import test_task013_project_registry_ops as t013
        self.assertTrue(
            hasattr(t013.TestProjectRemoveDispatchFakeCli, "test_body_supplied_path_is_ignored_id_map_path_used_verbatim"),
            "test_task013's id_map-not-body proof is gone",
        )


# ===========================================================================
# (C) tools.update: twin parity (dispatch-level cases only -- the unknown-<id>
# 404 is an HTTP-layer case, covered by TestToolsUpdateUnknownRepoIdLive /
# the .mjs companion below, per task-017 Scope bullet 3).
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestToolsUpdateParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        super().tearDownClass()

    def test_all_cases_parity(self) -> None:
        cases = [
            # (name, args, env, expected_status, expected_error)
            ("happy",          {},               {"FAKE_MODE": "ok"},   200, None),
            ("non_empty_args", {"force": "true"}, {},                   422, "invalid-value"),
            ("nonzero_exit",   {},               {"FAKE_MODE": "err9"}, 500, "update-failed"),
        ]
        node_cases = [
            {
                "table": "OP_TABLE",
                "parsed": {"op": "tools.update", "args": args} if args else {"op": "tools.update"},
                "servedRoot": "/repo/path",
                "aidHome": "/state/home",
                "env": env,
            }
            for (_name, args, env, _status, _err) in cases
        ]
        node_results = self._node_dispatch_many(node_cases)

        for (name, args, env, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                parsed = {"op": "tools.update", "args": args} if args else {"op": "tools.update"}
                with mock.patch.dict("os.environ", env, clear=False):
                    py_result = srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path", aid_home="/state/home")
                _assert_parity(self, py_result, node_result, expected_status, expected_error)


# ===========================================================================
# (D) tools.update-self: twin parity (task-017 Scope bullet 4).
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestToolsUpdateSelfParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        super().tearDownClass()

    def test_all_cases_parity(self) -> None:
        cases = [
            ("happy",          {},                {"FAKE_MODE": "ok"},   200, None),
            ("non_empty_args", {"x": "y"},         {},                    422, "invalid-value"),
            ("nonzero_exit",   {},                {"FAKE_MODE": "err9"}, 500, "update-failed"),
        ]
        node_cases = [
            {
                "table": "HOME_OP_TABLE",
                "parsed": {"op": "tools.update-self", "args": args} if args else {"op": "tools.update-self"},
                "servedRoot": "/state/home",
                "aidHome": "/state/home",
                "env": env,
            }
            for (_name, args, env, _status, _err) in cases
        ]
        node_results = self._node_dispatch_many(node_cases)

        for (name, args, env, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                parsed = {"op": "tools.update-self", "args": args} if args else {"op": "tools.update-self"}
                with mock.patch.dict("os.environ", env, clear=False):
                    py_result = srv._dispatch_op(srv.HOME_OP_TABLE, parsed, "/state/home")
                _assert_parity(self, py_result, node_result, expected_status, expected_error)


# ===========================================================================
# (E) tools.update / tools.update-self timeout (504 'timed-out') twin parity --
# a SEPARATE sliced module (short TOOLS_UPDATE_TIMEOUT) so the test stays
# bounded (a few seconds), never the real 600s production ceiling.
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestToolsUpdateTimeoutParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def _tools_timeout_ms(cls) -> int:
        return 1000   # 1s (vs. the fake's `sleep 3` -- reliably times out)

    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)
        # Deep-copy the two rows so the 1s test-local timeout override never
        # leaks into the module-level OP_TABLE/HOME_OP_TABLE for other tests
        # (mirrors test_task015_tools_update_ops.py's TestToolsUpdateTimeout).
        cls._orig_op_row = dict(srv.OP_TABLE["tools.update"])
        cls._orig_home_row = dict(srv.HOME_OP_TABLE["tools.update-self"])
        srv.OP_TABLE["tools.update"] = dict(cls._orig_op_row, aid_cli_timeout=1)
        srv.HOME_OP_TABLE["tools.update-self"] = dict(cls._orig_home_row, aid_cli_timeout=1)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        srv.OP_TABLE["tools.update"] = cls._orig_op_row
        srv.HOME_OP_TABLE["tools.update-self"] = cls._orig_home_row
        super().tearDownClass()

    def test_tools_update_python_side_timeout_is_504(self) -> None:
        """Python-side half of the timeout case (was always unaffected by the
        Node-only timeout-ordering bug fixed in runAidCli -- see the parity
        methods below) -- proves srv._dispatch_op maps the AID_CLI_TIMEOUT_EXIT
        sentinel to 504 'timed-out' for tools.update. Mirrors (thin, not
        duplicating) test_task015_tools_update_ops.py's own TestToolsUpdateTimeout."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "slow"}, clear=False):
            status, body = srv._dispatch_op(srv.OP_TABLE, {"op": "tools.update"}, "/repo/path", aid_home="/state/home")
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")

    def test_tools_update_self_python_side_timeout_is_504(self) -> None:
        """Python-side half of the timeout case (was always unaffected by the
        Node-only timeout-ordering bug fixed in runAidCli -- see the parity
        methods below)."""
        with mock.patch.dict("os.environ", {"FAKE_MODE": "slow"}, clear=False):
            status, body = srv._dispatch_op(srv.HOME_OP_TABLE, {"op": "tools.update-self"}, "/state/home")
        self.assertEqual(status, 504)
        self.assertEqual(json.loads(body)["error"], "timed-out")

    # -- Node/Python timeout parity (regression guard) -- these two methods
    # guard a bug discovered while authoring task-017: on Windows, Node's
    # spawnSync(...) populates BOTH result.error (an Error with code
    # 'ETIMEDOUT') AND result.signal ('SIGTERM') when its `timeout` option
    # kills the child, so server.mjs's runAidCli(...) -- which originally
    # checked `if (result.error)` BEFORE `if (result.signal)` -- misreported a
    # genuine 600s-ceiling kill as a generic exec failure (exit 3 -> 500
    # 'update-failed') instead of the spec'd 504 'timed-out' (feature-004
    # SPEC.md API Contracts: 'Child exceeds the 600s ceiling (killed) -> 504
    # timed-out'). Fixed in runAidCli by checking `result.signal ||
    # (result.error && result.error.code === 'ETIMEDOUT')` BEFORE the generic
    # result.error branch, mirroring Python's `except subprocess.TimeoutExpired`
    # being caught before the generic `except Exception`. These parity tests
    # (previously @unittest.skip'd against the target behavior) are now enabled
    # so the twins can never drift back apart.

    def test_tools_update_timeout_parity(self) -> None:
        node_result = self._node_dispatch_many([{
            "table": "OP_TABLE", "parsed": {"op": "tools.update"},
            "servedRoot": "/repo/path", "aidHome": "/state/home",
            "env": {"FAKE_MODE": "slow"},
        }])[0]
        with mock.patch.dict("os.environ", {"FAKE_MODE": "slow"}, clear=False):
            py_result = srv._dispatch_op(srv.OP_TABLE, {"op": "tools.update"}, "/repo/path", aid_home="/state/home")
        _assert_parity(self, py_result, node_result, 504, "timed-out")

    def test_tools_update_self_timeout_parity(self) -> None:
        node_result = self._node_dispatch_many([{
            "table": "HOME_OP_TABLE", "parsed": {"op": "tools.update-self"},
            "servedRoot": "/state/home", "aidHome": "/state/home",
            "env": {"FAKE_MODE": "slow"},
        }])[0]
        with mock.patch.dict("os.environ", {"FAKE_MODE": "slow"}, clear=False):
            py_result = srv._dispatch_op(srv.HOME_OP_TABLE, {"op": "tools.update-self"}, "/state/home")
        _assert_parity(self, py_result, node_result, 504, "timed-out")


# ===========================================================================
# (E2) tools.update / tools.update-self LARGE-OUTPUT (>1 MiB stdout) twin
# parity -- regression guard for the maxBuffer fix. A verbose-but-valid child
# must NOT be killed on either runtime: Python's subprocess.run(capture_output=
# True) has no output cap, so server.mjs's spawnSync must disable Node's default
# 1 MiB maxBuffer to match. Before the fix, Node SIGTERM-killed the child
# (result.error 'ENOBUFS', signal 'SIGTERM') and -- because the timeout branch
# then keyed off a bare result.signal -- misreported it as 504 'timed-out',
# diverging from Python's exit-0 -> 200. Both twins now return 200 in lockstep.
# ===========================================================================

@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestToolsUpdateLargeOutputParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_aid_cli_path = srv._AID_CLI_PATH
        srv._AID_CLI_PATH = cls._fake_cli_path
        cls._orig_run_aid_cli = _patch_run_aid_cli_force_unix(srv)

    @classmethod
    def tearDownClass(cls) -> None:
        srv._AID_CLI_PATH = cls._orig_aid_cli_path
        srv._run_aid_cli = cls._orig_run_aid_cli
        super().tearDownClass()

    def test_tools_update_large_output_parity(self) -> None:
        node_result = self._node_dispatch_many([{
            "table": "OP_TABLE", "parsed": {"op": "tools.update"},
            "servedRoot": "/repo/path", "aidHome": "/state/home",
            "env": {"FAKE_MODE": "bigout"},
        }])[0]
        with mock.patch.dict("os.environ", {"FAKE_MODE": "bigout"}, clear=False):
            py_result = srv._dispatch_op(srv.OP_TABLE, {"op": "tools.update"}, "/repo/path", aid_home="/state/home")
        _assert_parity(self, py_result, node_result, 200, None)

    def test_tools_update_self_large_output_parity(self) -> None:
        node_result = self._node_dispatch_many([{
            "table": "HOME_OP_TABLE", "parsed": {"op": "tools.update-self"},
            "servedRoot": "/state/home", "aidHome": "/state/home",
            "env": {"FAKE_MODE": "bigout"},
        }])[0]
        with mock.patch.dict("os.environ", {"FAKE_MODE": "bigout"}, clear=False):
            py_result = srv._dispatch_op(srv.HOME_OP_TABLE, {"op": "tools.update-self"}, "/state/home")
        _assert_parity(self, py_result, node_result, 200, None)


# ===========================================================================
# (F) Exit-alphabet DISTINCTNESS, explicitly asserted (task-017 Scope:
# "Exit-alphabet coverage").
# ===========================================================================

class TestExitAlphabetDistinctness(unittest.TestCase):
    """Proves the `aid projects` alphabet (exit 2 -> 422 'invalid-value') and
    the `aid update` alphabet (any other non-zero -> 500 'update-failed';
    the out-of-band timeout sentinel -> 504 'timed-out') are genuinely
    DIFFERENT status_map dicts, each independently correct for its own op
    family -- not a shared/aliased map that happens to look right for only
    one of the two (feature-003 SPEC API Contracts vs feature-004 SPEC API
    Contracts, explicitly contrasted)."""

    def test_project_ops_exit2_is_422(self) -> None:
        self.assertEqual(
            srv._map_exit_code(2, srv._PROJECT_OP_STATUS_MAP, None),
            (422, "invalid-value"),
        )

    def test_tools_update_exit2_is_not_422_collapses_to_500(self) -> None:
        """The SAME raw exit code (2) means something entirely different in
        the aid-update alphabet: 'aid update' has no defined semantic for
        exit 2 on this closed argv surface (API Contracts -- aid's own
        usage-error exits are not reachable through it), so it must NOT
        borrow project.add/remove's 422 mapping."""
        result = srv._map_exit_code(2, srv._TOOLS_UPDATE_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_DEFAULT)
        self.assertEqual(result, (500, "update-failed"))
        self.assertNotEqual(result, srv._map_exit_code(2, srv._PROJECT_OP_STATUS_MAP, None))

    def test_tools_update_timeout_sentinel_is_504(self) -> None:
        self.assertEqual(
            srv._map_exit_code(srv._AID_CLI_TIMEOUT_EXIT, srv._TOOLS_UPDATE_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_DEFAULT),
            (504, "timed-out"),
        )

    def test_project_ops_status_map_has_no_dedicated_timeout_row(self) -> None:
        """project.add/remove's own status_map has NO dedicated timeout row --
        an out-of-band timeout there falls through to the shared (500,
        'write-failed') fallback, distinct from tools.update's dedicated 504
        -- proving the two alphabets are not merely "different dicts" but
        differ in exactly the documented way."""
        self.assertNotIn(srv._AID_CLI_TIMEOUT_EXIT, srv._PROJECT_OP_STATUS_MAP)
        result = srv._map_exit_code(srv._AID_CLI_TIMEOUT_EXIT, srv._PROJECT_OP_STATUS_MAP, None)
        self.assertEqual(result, (500, "write-failed"))

    def test_the_two_maps_are_distinct_objects_not_aliased(self) -> None:
        self.assertIsNot(srv._PROJECT_OP_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_MAP)
        self.assertNotEqual(srv._PROJECT_OP_STATUS_MAP, srv._TOOLS_UPDATE_STATUS_MAP)


class TestSharedAidCliResolverAlreadyCovered(unittest.TestCase):
    """AC-traceability pointer only (task-017 Scope: "Shared-mechanism
    assertions (KI-004)... assert that all four ops dispatch through the
    single self-located $AID_CODE_HOME/bin/aid resolver with an argv array").
    ALREADY covered:
      - the resolver's OWN contract (argv array, AID_HOME threading, no
        AID_CODE_HOME leak) -- test_task013_project_registry_ops.py's
        TestRunAidCliContract (Python) / test_task013_project_registry_ops.mjs
        group [A] (Node, scoped to runAidCli's function body).
      - all FOUR rows (project.add, project.remove, tools.update,
        tools.update-self) reusing the SAME spawn function, not a re-invented
        one per op -- test_task015_tools_update_ops.py's TestOpTableRegistration.
        test_both_ops_reuse_the_same_shared_aid_cli_spawn_as_project_ops.
    Not duplicated here; this file's TestProjectAddParity/TestProjectRemoveParity/
    TestToolsUpdateParity/TestToolsUpdateSelfParity above additionally prove
    (as a byproduct of driving all four ops through ONE shared fake-CLI script
    on both runtimes) that a mis-wired resolver would be caught: every case's
    expected status/body depends on the fake script's argv-position-sensitive
    behavior (e.g. project.remove's `path="$3"`) actually being reached."""

    def test_pointer_to_resolver_contract_coverage(self) -> None:
        from dashboard.server.tests import test_task013_project_registry_ops as t013
        from dashboard.server.tests import test_task015_tools_update_ops as t015
        self.assertTrue(hasattr(t013, "TestRunAidCliContract"))
        self.assertTrue(hasattr(t015.TestOpTableRegistration, "test_both_ops_reuse_the_same_shared_aid_cli_spawn_as_project_ops"))
        # Direct structural re-assertion (cheap, in-process): all FOUR rows
        # this task-017 file exercises share the identical spawn function.
        self.assertIs(srv.HOME_OP_TABLE["project.add"]["spawn"], srv._spawn_aid_cli)
        self.assertIs(srv.HOME_OP_TABLE["project.remove"]["spawn"], srv._spawn_aid_cli)
        self.assertIs(srv.OP_TABLE["tools.update"]["spawn"], srv._spawn_aid_cli)
        self.assertIs(srv.HOME_OP_TABLE["tools.update-self"]["spawn"], srv._spawn_aid_cli)


# ===========================================================================
# (G) tools.update unknown-<id> 404 -- HTTP-layer (_serve_op), live socket.
# ===========================================================================

class TestToolsUpdateUnknownRepoIdLive(unittest.TestCase):
    """HTTP-layer coverage (task-017 Scope: "unknown repo <id> ... via POST
    /r/<id>/api/op"). The id-resolution 404 fires in _serve_op BEFORE any
    OP_TABLE dispatch -- untested by both test_task013's and test_task015's
    own suites (neither adds socket-bound coverage; see their own
    docstrings -- `_dispatch_op` is their established boundary). Never
    reaches the fake/real aid CLI at all (the 404 short-circuits before any
    spawn), so no FAKE_MODE plumbing is needed here.

    Expected body is asserted against the EXACT literal envelope
    (`_op_fail_body(None, "not-found", "unknown project id")`) -- the same
    literal this class's Node twin (test_task017_registry_tooling_round_
    trips.mjs) asserts against, which is how twin parity is proven for this
    HTTP-layer case without a live cross-process comparison at runtime.

    LOCAL TEST NOTE: this class binds a loopback socket (_ServerThread) --
    per the project's port-binding-server-test constraint it is NOT executed
    locally as part of this task's own verification pass; deferred to CI.
    """

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        _write_registry(self._aid_home, [])   # no repos registered at all

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_unknown_repo_id_is_404_not_found_before_any_dispatch(self) -> None:
        with _ServerThread(str(self._aid_home), write_enabled=True) as server:
            status, body = server.post_json("/r/deadbeefcafe/api/op", {"op": "tools.update"})
        self.assertEqual(status, 404)
        self.assertEqual(
            json.loads(body),
            {"ok": False, "op": None, "error": "not-found", "detail": "unknown project id"},
        )


# ===========================================================================
# (H) KI-008: MSYS '/c/x' -> native 'C:/x' filesystem-path normalizer.
# `aid projects add`/`remove` run under bash and store the MSYS '/<drive>/rest'
# form; native-Windows Python/Node cannot resolve it, so a dashboard-added
# project rendered with no metadata. Both reader twins normalize ONLY at the
# filesystem boundary (id + displayed path stay verbatim). These tests use the
# injectable is_windows/isWin seam so the Linux CI runner exercises the Windows
# branch. Pure Python-side unit checks (no Node) + a cross-twin parity check.
# ===========================================================================

class TestNativeFsPathUnit(unittest.TestCase):
    def test_windows_msys_drive_paths_map_to_native(self) -> None:
        self.assertEqual(srv._native_fs_path("/c/Projects/x", is_windows=True), "C:/Projects/x")
        self.assertEqual(srv._native_fs_path("/d/data/y", is_windows=True), "D:/data/y")
        self.assertEqual(srv._native_fs_path("/c", is_windows=True), "C:/")
        self.assertEqual(srv._native_fs_path("/c/", is_windows=True), "C:/")
        # already-native and non-drive absolute paths are untouched even on Windows
        self.assertEqual(srv._native_fs_path("C:/already/native", is_windows=True), "C:/already/native")
        self.assertEqual(srv._native_fs_path("/home/user/aid", is_windows=True), "/home/user/aid")
        self.assertEqual(srv._native_fs_path("/usr/local", is_windows=True), "/usr/local")
        self.assertEqual(srv._native_fs_path("relative/path", is_windows=True), "relative/path")

    def test_posix_branch_is_a_pure_noop(self) -> None:
        # On POSIX '/c/foo' is a legitimate absolute path -- MUST NOT be rewritten.
        for p in ("/c/Projects/x", "/c", "/home/user", "C:/x", "relative", ""):
            self.assertEqual(srv._native_fs_path(p, is_windows=False), p)


_NATIVE_FS_PATH_CASES = [
    "/c/Projects/Personal/AID", "/c/Users/andre/x", "/d/data", "/c", "/c/",
    "C:/already/native", "/home/user/aid", "/usr/local", "relative/path", "",
]


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestNativeFsPathParity(_NodeSlicedDispatchFixture, unittest.TestCase):
    """The KI-008 normalizer must be byte-identical across the Python and Node
    reader twins for BOTH the Windows branch and the POSIX no-op branch."""

    def _node_native_fs_path(self, is_win: bool) -> list[str]:
        driver = (
            "import { nativeFsPath } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const cases = {json.dumps(_NATIVE_FS_PATH_CASES)};\n"
            f"const isWin = {json.dumps(is_win)};\n"
            "process.stdout.write(JSON.stringify(cases.map((c) => nativeFsPath(c, isWin))));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"node nativeFsPath driver failed: {result.stderr[:1000]}")
        return list(json.loads(result.stdout.strip()))

    def test_windows_branch_twin_parity(self) -> None:
        node_out = self._node_native_fs_path(True)
        py_out = [srv._native_fs_path(c, is_windows=True) for c in _NATIVE_FS_PATH_CASES]
        self.assertEqual(py_out, node_out, "python/node nativeFsPath DIVERGE (Windows branch)")
        # anchor the intended transform so a regression can't pass by both twins agreeing on wrong
        self.assertEqual(py_out[0], "C:/Projects/Personal/AID")

    def test_posix_branch_twin_parity_is_noop(self) -> None:
        node_out = self._node_native_fs_path(False)
        py_out = [srv._native_fs_path(c, is_windows=False) for c in _NATIVE_FS_PATH_CASES]
        self.assertEqual(py_out, node_out, "python/node nativeFsPath DIVERGE (POSIX branch)")
        self.assertEqual(py_out, _NATIVE_FS_PATH_CASES, "POSIX branch must be a pure no-op")


if __name__ == "__main__":
    unittest.main(verbosity=2)
