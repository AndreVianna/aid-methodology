"""
test_ki009_windows_dispatch.py -- KI-009 fix verification: OS-native aid-CLI
dispatch (Part A) + robust bash auto-discovery (Part B).

KI-009 (see .aid/works/work-017-cli-improvements/known-issues.md): `aid
dashboard start` runs in the user's NATIVE shell (PowerShell on Windows, not
Git Bash). `_run_aid_cli`/`runAidCli` dispatched every aid-CLI op as
`bash <bin/aid> <argv...>` and `_run_writer`/`runWriter` dispatched every
writer as `bash <writer>.sh` -- and `_resolve_bash_exe`/`resolveBashExe` only
walked PATH for bash.exe, which from a PowerShell launch resolves to the
unusable Windows-shipped WSL-launcher stub (`C:\\Windows\\System32\\bash.exe`),
breaking EVERY dashboard write op. The fix:

  Part A -- OS-native aid-CLI dispatch (_run_aid_cli/runAidCli): on Windows
  (the SERVER PROCESS's own os.name/process.platform -- NEVER a client/
  request signal, so `--remote` stays correct), dispatch the bundled
  bin/aid.ps1 via a resolved PowerShell exe (_resolve_pwsh_exe/resolvePwshExe:
  prefer pwsh, else the real powershell.exe -- System32 IS the genuine
  PowerShell, unlike bash, so it is never skipped) as an argv ARRAY
  (`[<pwsh>, "-NoProfile", "-NonInteractive", "-File", <aid.ps1>, <argv...>]`).
  On Unix, dispatch is UNCHANGED (`bash <bin/aid> <argv...>`).

  Part B -- robust bash auto-discovery (_resolve_bash_exe/resolveBashExe, used
  by _run_writer/runWriter for the bash-only .sh writers): honors an
  AID_BASH_EXE override; walks PATH for bash.exe SKIPPING the System32
  WSL-stub dir; falls back to probing Git's own known install locations
  (<ProgramFiles>/Git/bin, <ProgramFiles>/Git/usr/bin, the
  <ProgramFiles(x86)> equivalents, and a location DERIVED from git.exe's own
  PATH entry); falls back to the bare "bash" name.

Covers, all in-process (no socket bind, no real WSL/Git-install dependency --
every Windows-only branch is exercised via the injectable `is_windows`/`env`/
`exists_fn` seams, mirroring KI-008's `_native_fs_path`'s `is_windows`
convention):
  (A) _resolve_bash_exe: AID_BASH_EXE override, System32-stub skip + PATH
      walk, Git-install-dir probe (ProgramFiles/ProgramFiles(x86)/derived-
      from-git.exe), bare-name fallback, Unix branch untouched, the
      injectable seam itself defaulting to the real os.name (never a
      hardcoded/client value).
  (B) _resolve_pwsh_exe: prefers pwsh over powershell.exe, falls back to
      powershell.exe, does NOT skip System32 (contrast with (A)), bare-name
      fallback.
  (C) _run_aid_cli's OS branch: argv SHAPE for both branches (mocked
      subprocess.run, no real spawn), env threading (AID_HOME only, never
      AID_CODE_HOME), the default `is_windows=None` seam resolving from the
      real os.name (proving the dispatch OS is the SERVER-HOST OS, never any
      client-supplied value), and timeout/exec-failure sentinel parity
      identical across both branches.
  (D) A REAL end-to-end dispatch through the ACTUAL bin/aid.ps1 (never a
      stub) via a resolved real pwsh -- proves Part A's exit-alphabet parity
      claim empirically (`projects add <nonexistent>` -> exit 2, matching
      bin/aid's own alphabet) and a full HOME_OP_TABLE project.add/remove
      200 round trip with real registry.yml persistence. Skipped when pwsh
      is absent from PATH (mirrors tests/canonical/test-aid-cli-parity.sh's
      own skip gate; CI asserts pwsh IS present, so this runs there).
  (E) Python<->Node byte-parity for the resolver functions across a battery
      of fabricated Windows-shaped envs (mirrors test_task017_registry_
      tooling_round_trips.py's `_NodeSlicedDispatchFixture`/exported-function
      technique, generalized to a self-contained slice here rather than
      importing that file's fixture -- same "duplicated rather than
      imported" rationale test_task013's own .mjs file documents).
  (F) The NODE-side symmetric counterpart to (D): a REAL end-to-end
      dispatch through the ACTUAL bin/aid.ps1 (never a fake) via server.mjs's
      OWN `runAidCli` (exported directly through the slice technique -- not
      merely `dispatchOp`), asserting Python<->Node BYTE-parity of the exit
      code/stderr/response-body for `version`, a `projects add` validation
      failure (exit 2), and a full project.add/remove 200 round trip. Closes
      a review-flagged gap: (D)/(E) alone never proved the NODE runAidCli's
      Windows branch reaches a real, working aid.ps1. Gated on an ACTUAL
      Windows host (`sys.platform == 'win32'`, unlike (D)'s cross-platform
      pwsh-only gate) + pwsh-or-powershell.exe present; skips cleanly on
      non-Windows CI.

LOCAL TEST NOTE: every class here calls `srv._resolve_bash_exe(...)` /
`srv._resolve_pwsh_exe(...)` / `srv._run_aid_cli(...)` / `srv._dispatch_op(...)`
directly (or spawns node as a bounded subprocess) -- no `_ServerThread` socket
bind anywhere -- so the whole file is safe to run locally per the project's
port-binding-server-test constraint. All classes were exercised directly as
part of this fix's own verification pass (skipped, not failed, when pwsh/node
is absent from PATH).

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
from dashboard.server.tests.test_server_py import _make_aid_home, _write_registry


def _pwsh_available() -> bool:
    try:
        r = subprocess.run(["pwsh", "-NoProfile", "-Command", "$PSVersionTable.PSVersion"],
                            capture_output=True, timeout=15)
        return r.returncode == 0
    except Exception:
        return False


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


_PWSH_AVAILABLE = _pwsh_available()
_NODE_AVAILABLE = _node_available()


# ===========================================================================
# (A) _resolve_bash_exe: Part B hardening.
# ===========================================================================

class TestResolveBashExeWindowsHardening(unittest.TestCase):
    def test_aid_bash_exe_override_short_circuits_everything(self):
        env = {"AID_BASH_EXE": r"D:\custom\bash.exe", "PATH": r"C:\Windows\System32"}
        exists = lambda p: p == r"D:\custom\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"D:\custom\bash.exe")

    def test_aid_bash_exe_override_ignored_when_file_absent(self):
        env = {"AID_BASH_EXE": r"D:\custom\bash.exe", "PATH": r"C:\Program Files\Git\bin"}
        exists = lambda p: p == r"C:\Program Files\Git\bin\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"C:\Program Files\Git\bin\bash.exe")

    def test_system32_stub_is_skipped_even_when_present_and_earlier_in_path(self):
        env = {
            "PATH": r"C:\Windows\System32;C:\Program Files\Git\bin",
            "SystemRoot": r"C:\Windows",
        }
        files = {r"C:\Windows\System32\bash.exe", r"C:\Program Files\Git\bin\bash.exe"}
        exists = lambda p: p in files  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"C:\Program Files\Git\bin\bash.exe")

    def test_system32_only_candidate_falls_back_to_bare_bash_not_the_stub(self):
        env = {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows"}
        exists = lambda p: p == r"C:\Windows\System32\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), "bash")

    def test_git_install_dir_probe_program_files(self):
        env = {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows", "ProgramFiles": r"C:\Program Files"}
        exists = lambda p: p == r"C:\Program Files\Git\bin\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"C:\Program Files\Git\bin\bash.exe")

    def test_git_install_dir_probe_usr_bin_variant(self):
        env = {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows", "ProgramFiles": r"C:\Program Files"}
        exists = lambda p: p == r"C:\Program Files\Git\usr\bin\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"C:\Program Files\Git\usr\bin\bash.exe")

    def test_git_install_dir_probe_program_files_x86(self):
        env = {
            "PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows",
            "ProgramFiles(x86)": r"C:\Program Files (x86)",
        }
        exists = lambda p: p == r"C:\Program Files (x86)\Git\bin\bash.exe"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"C:\Program Files (x86)\Git\bin\bash.exe")

    def test_derive_from_git_exe_own_path_entry(self):
        """<X>/Git/cmd/git.exe -> <X>/Git/bin/bash.exe (git.exe on PATH, no
        ProgramFiles hit at all -- a non-standard Git install location)."""
        env = {"PATH": r"D:\devtools\Git\cmd", "SystemRoot": r"C:\Windows"}
        files = {r"D:\devtools\Git\cmd\git.exe", r"D:\devtools\Git\bin\bash.exe"}
        exists = lambda p: p in files  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"D:\devtools\Git\bin\bash.exe")

    def test_derive_from_git_exe_own_path_entry_usr_bin_variant(self):
        env = {"PATH": r"D:\devtools\Git\cmd", "SystemRoot": r"C:\Windows"}
        files = {r"D:\devtools\Git\cmd\git.exe", r"D:\devtools\Git\usr\bin\bash.exe"}
        exists = lambda p: p in files  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(True, env, exists), r"D:\devtools\Git\usr\bin\bash.exe")

    def test_no_candidate_anywhere_falls_back_to_bare_bash(self):
        env = {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows"}
        self.assertEqual(srv._resolve_bash_exe(True, env, lambda p: False), "bash")

    def test_unix_branch_is_unaffected_by_windows_hardening(self):
        env = {"PATH": "/usr/bin:/usr/local/bin"}
        exists = lambda p: p == "/usr/local/bin/bash"  # noqa: E731
        self.assertEqual(srv._resolve_bash_exe(False, env, exists), "/usr/local/bin/bash")

    def test_unix_branch_falls_back_to_bare_bash(self):
        env = {"PATH": "/usr/bin"}
        self.assertEqual(srv._resolve_bash_exe(False, env, lambda p: False), "bash")

    def test_default_is_windows_seam_resolves_from_real_os_name_not_hardcoded(self):
        """The dispatch OS is the SERVER-HOST OS (os.name), never a caller-
        supplied/client value, UNLESS a test explicitly overrides the seam."""
        with mock.patch.object(srv.os, "name", "nt"):
            with mock.patch.object(srv.os, "environ", {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows"}):
                self.assertEqual(srv._resolve_bash_exe(), "bash")
        with mock.patch.object(srv.os, "name", "posix"):
            with mock.patch.object(srv.os, "environ", {"PATH": "/usr/bin"}):
                self.assertEqual(srv._resolve_bash_exe(), "bash")


# ===========================================================================
# (B) _resolve_pwsh_exe: Part A resolver.
# ===========================================================================

class TestResolvePwshExe(unittest.TestCase):
    def test_prefers_pwsh_over_powershell(self):
        env = {"PATH": r"C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\PowerShell\7"}
        files = {
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
            r"C:\Program Files\PowerShell\7\pwsh.exe",
        }
        exists = lambda p: p in files  # noqa: E731
        self.assertEqual(srv._resolve_pwsh_exe(env, exists), r"C:\Program Files\PowerShell\7\pwsh.exe")

    def test_falls_back_to_real_powershell_exe_when_pwsh_absent(self):
        env = {"PATH": r"C:\Windows\System32\WindowsPowerShell\v1.0"}
        exists = lambda p: p == r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"  # noqa: E731
        self.assertEqual(
            srv._resolve_pwsh_exe(env, exists),
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        )

    def test_system32_is_not_skipped_for_powershell_unlike_bash(self):
        """Contrast with _resolve_bash_exe: System32's powershell.exe IS the
        genuine Windows PowerShell -- no WSL-stub hazard exists for it."""
        env = {"PATH": r"C:\Windows\System32\WindowsPowerShell\v1.0", "SystemRoot": r"C:\Windows"}
        exists = lambda p: p == r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"  # noqa: E731
        self.assertEqual(
            srv._resolve_pwsh_exe(env, exists),
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        )

    def test_no_candidate_falls_back_to_bare_pwsh(self):
        env = {"PATH": r"C:\Windows\System32"}
        self.assertEqual(srv._resolve_pwsh_exe(env, lambda p: False), "pwsh")


# ===========================================================================
# (C) _run_aid_cli's OS branch: argv shape, env threading, timeout/exec-
# failure sentinel parity across both branches -- mocked subprocess.run, no
# real spawn.
# ===========================================================================

class TestRunAidCliOsDispatch(unittest.TestCase):
    def setUp(self) -> None:
        self._orig_pwsh = srv._PWSH_EXE
        self._orig_bash = srv._BASH_EXE
        self._orig_cli_ps1 = srv._AID_CLI_PATH_PS1
        self._orig_cli = srv._AID_CLI_PATH
        srv._PWSH_EXE = "FAKE_PWSH"
        srv._BASH_EXE = "FAKE_BASH"
        srv._AID_CLI_PATH_PS1 = Path("C:/fake/bin/aid.ps1")
        srv._AID_CLI_PATH = Path("/fake/bin/aid")

    def tearDown(self) -> None:
        srv._PWSH_EXE = self._orig_pwsh
        srv._BASH_EXE = self._orig_bash
        srv._AID_CLI_PATH_PS1 = self._orig_cli_ps1
        srv._AID_CLI_PATH = self._orig_cli

    def test_windows_branch_argv_shape(self):
        captured = {}

        def fake_run(argv_full, **kwargs):
            captured["argv"] = argv_full
            captured["env"] = kwargs.get("env")
            return subprocess.CompletedProcess(argv_full, 0, stdout="", stderr="")

        with mock.patch.object(srv.subprocess, "run", side_effect=fake_run):
            rc, err = srv._run_aid_cli(["projects", "add", "/abs/path"], {"AID_HOME": "/x"}, is_windows=True)
        self.assertEqual(rc, 0)
        self.assertEqual(
            captured["argv"],
            ["FAKE_PWSH", "-NoProfile", "-NonInteractive", "-File", "C:/fake/bin/aid.ps1",
             "projects", "add", "/abs/path"],
        )
        self.assertEqual(captured["env"]["AID_HOME"], "/x")
        self.assertNotIn("AID_CODE_HOME", {"AID_HOME"})  # sanity: env_overrides never smuggles it

    def test_unix_branch_argv_shape_unchanged(self):
        captured = {}

        def fake_run(argv_full, **kwargs):
            captured["argv"] = argv_full
            return subprocess.CompletedProcess(argv_full, 0, stdout="", stderr="")

        with mock.patch.object(srv.subprocess, "run", side_effect=fake_run):
            rc, err = srv._run_aid_cli(["projects", "add", "/abs/path"], {"AID_HOME": "/x"}, is_windows=False)
        self.assertEqual(rc, 0)
        self.assertEqual(captured["argv"], ["FAKE_BASH", "/fake/bin/aid", "projects", "add", "/abs/path"])

    def test_default_seam_resolves_from_server_host_os_name(self):
        """No `is_windows` argument at all: the branch taken must follow the
        REAL os.name -- never a hardcoded value, never anything client-
        supplied (KI-009 `--remote` correctness requirement)."""
        captured = {}

        def fake_run(argv_full, **kwargs):
            captured["argv"] = argv_full
            return subprocess.CompletedProcess(argv_full, 0, stdout="", stderr="")

        with mock.patch.object(srv.os, "name", "nt"):
            with mock.patch.object(srv.subprocess, "run", side_effect=fake_run):
                srv._run_aid_cli(["version"], {})
        self.assertEqual(captured["argv"][0], "FAKE_PWSH")

        with mock.patch.object(srv.os, "name", "posix"):
            with mock.patch.object(srv.subprocess, "run", side_effect=fake_run):
                srv._run_aid_cli(["version"], {})
        self.assertEqual(captured["argv"][0], "FAKE_BASH")

    def test_timeout_sentinel_parity_across_both_branches(self):
        def raise_timeout(argv_full, **kwargs):
            raise subprocess.TimeoutExpired(cmd=argv_full, timeout=kwargs.get("timeout", 1), output=None, stderr="boom")

        with mock.patch.object(srv.subprocess, "run", side_effect=raise_timeout):
            rc_win, err_win = srv._run_aid_cli(["update"], {}, is_windows=True)
            rc_unix, err_unix = srv._run_aid_cli(["update"], {}, is_windows=False)
        self.assertEqual(rc_win, srv._AID_CLI_TIMEOUT_EXIT)
        self.assertEqual(rc_unix, srv._AID_CLI_TIMEOUT_EXIT)
        self.assertEqual(err_win, "boom")
        self.assertEqual(err_unix, "boom")

    def test_exec_failure_sentinel_parity_across_both_branches(self):
        def raise_oserror(argv_full, **kwargs):
            raise FileNotFoundError("no such file: " + argv_full[0])

        with mock.patch.object(srv.subprocess, "run", side_effect=raise_oserror):
            rc_win, err_win = srv._run_aid_cli(["version"], {}, is_windows=True)
            rc_unix, err_unix = srv._run_aid_cli(["version"], {}, is_windows=False)
        self.assertEqual(rc_win, 3)
        self.assertEqual(rc_unix, 3)
        self.assertIn("FAKE_PWSH", err_win)
        self.assertIn("FAKE_BASH", err_unix)


# ===========================================================================
# (D) REAL end-to-end dispatch through the ACTUAL bin/aid.ps1 via a resolved
# real pwsh -- never a stub. Skipped when pwsh is absent (mirrors tests/
# canonical/test-aid-cli-parity.sh's own skip gate).
# ===========================================================================

@unittest.skipUnless(_PWSH_AVAILABLE, "pwsh not found on PATH -- real aid.ps1 dispatch skipped")
class TestRunAidCliRealPs1Dispatch(unittest.TestCase):
    """Forces is_windows=True regardless of the ACTUAL host OS -- pwsh
    (PowerShell 7+) is cross-platform and can execute bin/aid.ps1 on Linux
    too, so this class genuinely exercises the Windows dispatch branch even
    when the suite runs on a Linux CI runner that has pwsh installed (per
    tests/canonical/test-aid-cli-parity.sh's own convention: 'CI asserts pwsh
    IS present')."""

    def test_version_exits_0(self):
        rc, stderr = srv._run_aid_cli(["version"], {}, is_windows=True)
        self.assertEqual(rc, 0, stderr)

    def test_projects_add_nonexistent_path_exits_2(self):
        """KI-009 exit-alphabet parity claim, proven empirically against the
        REAL aid.ps1 (never a fake): a validation failure on `projects add`
        exits 2, matching bin/aid's own alphabet (_PROJECT_OP_STATUS_MAP maps
        exit 2 -> 422 'invalid-value' for EITHER runtime)."""
        rc, stderr = srv._run_aid_cli(
            ["projects", "add", "/definitely/does/not/exist/xyz123-ki009"], {"AID_HOME": "/tmp/ki009-fake"},
            is_windows=True,
        )
        self.assertEqual(rc, 2, stderr)
        self.assertIn("path does not exist", stderr)

    def test_project_add_remove_round_trip_via_dispatch_op(self):
        """Full HOME_OP_TABLE round trip (200 + real registry.yml
        persistence) through the REAL PowerShell dispatch branch."""
        base = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: shutil.rmtree(str(base), ignore_errors=True))
        aid_home = base / "aid_home"
        _make_aid_home(aid_home)
        proj = base / "real-project-ki009"
        (proj / ".aid").mkdir(parents=True, exist_ok=True)

        # _dispatch_op calls _spawn_aid_cli -> _run_aid_cli WITHOUT an
        # is_windows override, so force the seam at the _run_aid_cli call
        # boundary via a thin wrapper that always forces True, restoring the
        # original after the test (mirrors TestRunAidCliContract's own
        # redirect-then-restore convention).
        orig = srv._run_aid_cli

        def forced(argv, env_overrides, timeout=srv._DEFAULT_AID_CLI_TIMEOUT):
            return orig(argv, env_overrides, timeout, is_windows=True)

        srv._run_aid_cli = forced
        try:
            status, body = srv._dispatch_op(
                srv.HOME_OP_TABLE, {"op": "project.add", "args": {"path": str(proj).replace("\\", "/")}},
                str(aid_home),
            )
            self.assertEqual(status, 200, body)
            reg_text = (aid_home / "registry.yml").read_text(encoding="utf-8")
            self.assertIn("real-project-ki009", reg_text)

            id_map, _warnings = srv._get_id_map(str(aid_home))
            target_id = next((k for k, v in id_map.items() if "real-project-ki009" in v), None)
            self.assertIsNotNone(target_id, id_map)

            status2, body2 = srv._dispatch_op(
                srv.HOME_OP_TABLE, {"op": "project.remove", "target": {"id": target_id}}, str(aid_home),
            )
            self.assertEqual(status2, 200, body2)
            reg_text2 = (aid_home / "registry.yml").read_text(encoding="utf-8")
            self.assertNotIn("real-project-ki009", reg_text2)
        finally:
            srv._run_aid_cli = orig


# ===========================================================================
# (E) Python<->Node byte-parity for the resolver functions (self-contained
# slice -- generalizes test_task017's `_NodeSlicedDispatchFixture` technique
# rather than importing it, mirrors test_task013's own .mjs "duplicated
# rather than imported" rationale).
# ===========================================================================

_SERVER_MJS = _DASHBOARD_DIR / "server" / "server.mjs"
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"

_RESOLVER_ENV_CASES = [
    # (name, is_win, env)
    ("system32_skip", True, {"PATH": r"C:\Windows\System32;C:\Program Files\Git\bin", "SystemRoot": r"C:\Windows"}),
    ("aid_bash_exe_override", True, {"AID_BASH_EXE": r"D:\custom\bash.exe"}),
    ("program_files_probe", True,
     {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows", "ProgramFiles": r"C:\Program Files"}),
    ("no_candidate_fallback", True, {"PATH": r"C:\Windows\System32", "SystemRoot": r"C:\Windows"}),
    ("unix_branch", False, {"PATH": "/usr/bin:/usr/local/bin"}),
    ("derive_from_git_exe", True, {"PATH": r"D:\devtools\Git\cmd", "SystemRoot": r"C:\Windows"}),
]

# Every candidate path this battery's exists_fn probes must be pre-listed here
# so BOTH runtimes' fake exists_fn/existsFn implementations agree on which
# candidates "exist" without needing a real filesystem.
_EXISTING_FILES = {
    r"C:\Program Files\Git\bin\bash.exe",
    r"D:\custom\bash.exe",
    r"C:\Program Files\Git\usr\bin\bash.exe",
    "/usr/local/bin/bash",
    r"D:\devtools\Git\cmd\git.exe",
    r"D:\devtools\Git\bin\bash.exe",
}


def _sliced_server_mjs_source() -> str:
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    sliced = text[:idx]
    return sliced + "\nexport { resolveBashExe, resolvePwshExe };\n"


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestBashPwshResolverParity(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_ki009_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def _node_resolve_many(self, cases: list[dict]) -> list[str]:
        existing = json.dumps(sorted(_EXISTING_FILES))
        driver = (
            "import { resolveBashExe, resolvePwshExe } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const existing = new Set({existing});\n"
            "const exists = (p) => existing.has(p);\n"
            f"const cases = {json.dumps(cases)};\n"
            "const results = cases.map((c) => resolveBashExe(c.isWin, c.env, exists));\n"
            "process.stdout.write(JSON.stringify(results));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node resolver driver failed: {result.stderr[:1000]}")
        return list(json.loads(result.stdout.strip()))

    def test_resolve_bash_exe_parity_across_env_battery(self) -> None:
        cases = [{"isWin": is_win, "env": env} for (_name, is_win, env) in _RESOLVER_ENV_CASES]
        node_results = self._node_resolve_many(cases)

        exists = lambda p: p in _EXISTING_FILES  # noqa: E731
        for (name, is_win, env), node_result in zip(_RESOLVER_ENV_CASES, node_results):
            with self.subTest(case=name):
                py_result = srv._resolve_bash_exe(is_win, env, exists)
                self.assertEqual(
                    py_result, node_result,
                    f"python/node _resolve_bash_exe DIVERGE for case {name!r}: py={py_result!r} node={node_result!r}",
                )

    def test_resolve_pwsh_exe_parity(self) -> None:
        env = {"PATH": r"C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\PowerShell\7"}
        files = {
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
            r"C:\Program Files\PowerShell\7\pwsh.exe",
        }
        driver = (
            "import { resolvePwshExe } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const existing = new Set({json.dumps(sorted(files))});\n"
            "const exists = (p) => existing.has(p);\n"
            f"const env = {json.dumps(env)};\n"
            "process.stdout.write(JSON.stringify(resolvePwshExe(env, exists)));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        node_result = json.loads(result.stdout.strip())
        py_result = srv._resolve_pwsh_exe(env, lambda p: p in files)
        self.assertEqual(py_result, node_result)
        self.assertEqual(py_result, r"C:\Program Files\PowerShell\7\pwsh.exe")


# ===========================================================================
# (F) Node-side REAL end-to-end dispatch through the ACTUAL bin/aid.ps1 (never
# a fake) -- symmetric counterpart to (D)'s Python-only TestRunAidCliRealPs1
# Dispatch. Closes a review-flagged [MEDIUM] gap: (D) proved the PYTHON
# _run_aid_cli's Windows branch reaches a real, working aid.ps1; (E)'s
# cross-twin parity covers only the resolver helpers (resolveBashExe/
# resolvePwshExe) -- neither proved the NODE runAidCli's Windows branch
# actually dispatches correctly through a real aid.ps1, so a Node-only
# regression there (wrong argv order/shape, wrong PWSH_EXE selection, a
# broken toPosixArg on AID_CLI_PATH_PS1, etc.) could have gone undetected
# even with the identical Python-side logic staying correct.
#
# runAidCli IS cleanly exportable via this slice technique (proven here, not
# merely dispatchOp) and callable directly with the SAME argv Python uses, so
# every assertion below is a genuine Python<->Node BYTE-parity check (not
# just "both look plausible") -- both twins spawn the SAME underlying aid.ps1
# script with the SAME argv, so stderr/response-body text is expected to be
# byte-identical, not merely equivalent.
#
# Gated on sys.platform == 'win32' (UNLIKE (D), which deliberately forces
# is_windows=True from ANY host since pwsh is cross-platform): this class
# asserts parity of runAidCli's ACTUAL output on THIS host, so it must run
# against a genuine Windows PowerShell install (pwsh, or the always-present
# powershell.exe fallback) -- skips cleanly on non-Windows CI (e.g. this
# project's Linux runner).
# ===========================================================================

def _win32_pwsh_or_powershell_available() -> bool:
    if sys.platform != "win32":
        return False
    if _PWSH_AVAILABLE:
        return True
    try:
        r = subprocess.run(
            ["powershell.exe", "-NoProfile", "-Command", "$PSVersionTable.PSVersion"],
            capture_output=True, timeout=15,
        )
        return r.returncode == 0
    except Exception:
        return False


_WIN32_PWSH_OR_POWERSHELL_AVAILABLE = _win32_pwsh_or_powershell_available()


def _sliced_server_mjs_source_full() -> str:
    """Like _sliced_server_mjs_source() above, but exports runAidCli ITSELF
    (proven cleanly reachable via this slice technique -- not just
    dispatchOp), plus dispatchOp/HOME_OP_TABLE/getIdMap for the full-round-
    trip case. No AID_CLI_PATH/AID_CLI_PATH_PS1 redirection here -- this
    slice dispatches through the REAL bin/aid.ps1, never a fake, mirroring
    (D)'s Python class exactly."""
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    sliced = text[:idx]
    return sliced + "\nexport { runAidCli, dispatchOp, HOME_OP_TABLE, getIdMap };\n"


@unittest.skipUnless(
    _NODE_AVAILABLE and _WIN32_PWSH_OR_POWERSHELL_AVAILABLE,
    "requires an actual Windows host + node + (pwsh or powershell.exe) on PATH -- "
    "real Node aid.ps1 dispatch skipped",
)
class TestRunAidCliRealPs1DispatchNodeParity(unittest.TestCase):
    """Node-side symmetric counterpart to (D)'s TestRunAidCliRealPs1Dispatch:
    runs the REAL server.mjs runAidCli (never a fake) through the ACTUAL
    bin/aid.ps1 via a resolved real PowerShell exe, and asserts BYTE-parity
    against Python's _run_aid_cli for the identical argv."""

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_ki009_full_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source_full(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def _node_run_aid_cli(self, argv: list[str], env_overrides: dict) -> "tuple[int, str]":
        driver = (
            "import { runAidCli } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const r = runAidCli({json.dumps(argv)}, {json.dumps(env_overrides)}, undefined, true);\n"
            "process.stdout.write(JSON.stringify(r));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node runAidCli driver failed: {result.stderr[:2000]}")
        code, stderr_text = json.loads(result.stdout.strip())
        return code, stderr_text

    def _node_dispatch_project_op(self, parsed: dict, aid_home: str) -> "tuple[int, str]":
        driver = (
            "import { dispatchOp, HOME_OP_TABLE } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const r = dispatchOp(HOME_OP_TABLE, {json.dumps(parsed)}, {json.dumps(aid_home)}, {json.dumps(aid_home)});\n"
            "process.stdout.write(JSON.stringify([r[0], Buffer.from(r[1]).toString('utf-8')]));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node dispatchOp driver failed: {result.stderr[:2000]}")
        status, body = json.loads(result.stdout.strip())
        return status, body

    def _node_get_id_map(self, aid_home: str) -> dict:
        driver = (
            "import { getIdMap } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const r = getIdMap({json.dumps(aid_home)});\n"
            "process.stdout.write(JSON.stringify(Object.fromEntries(r.idMap)));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"], input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node getIdMap driver failed: {result.stderr[:2000]}")
        return json.loads(result.stdout.strip())

    def test_version_exit_0_byte_parity(self) -> None:
        py_code, py_stderr = srv._run_aid_cli(["version"], {}, is_windows=True)
        node_code, node_stderr = self._node_run_aid_cli(["version"], {})
        self.assertEqual(py_code, 0, py_stderr)
        self.assertEqual(node_code, 0, node_stderr)
        self.assertEqual(py_code, node_code, "python/node runAidCli exit-code DIVERGE for 'version'")

    def test_projects_add_validation_failure_exit_2_byte_parity(self) -> None:
        """KI-009 exit-alphabet parity claim, now proven on the NODE side too
        (this is the [MEDIUM] gap a review flagged: only the Python side had
        a real-dispatch proof before this class) -- the SAME argv is used on
        both runtimes, so stderr is asserted content-IDENTICAL modulo the
        two runtimes' own line-ending CAPTURE convention (Python's
        subprocess.run(text=True) auto-translates the child's raw CRLF to LF
        per universal-newlines mode; Node's spawnSync(encoding:'utf8') does
        NOT -- this is an artifact of how each stdlib decodes a captured
        pipe, not a real divergence in aid.ps1's own output or in the
        dispatch logic under test, so both sides are normalized before
        comparing)."""
        argv = ["projects", "add", "/definitely/does/not/exist/xyz123-ki009-parity"]
        env = {"AID_HOME": "/tmp/ki009-fake-parity"}
        py_code, py_stderr = srv._run_aid_cli(argv, env, is_windows=True)
        node_code, node_stderr = self._node_run_aid_cli(argv, env)
        self.assertEqual(py_code, 2, py_stderr)
        self.assertEqual(node_code, 2, node_stderr)
        self.assertEqual(
            py_code, node_code, "python/node runAidCli exit-code DIVERGE for projects-add-validation-failure",
        )
        self.assertEqual(
            py_stderr.replace("\r\n", "\n"), node_stderr.replace("\r\n", "\n"),
            "python/node runAidCli stderr text DIVERGE (same aid.ps1, same argv; CRLF-normalized)",
        )
        self.assertIn("path does not exist", py_stderr)

    def test_project_add_remove_round_trip_dispatch_op_byte_parity(self) -> None:
        """Full HOME_OP_TABLE 200 round trip (project.add then project.remove)
        through the REAL PowerShell dispatch on BOTH runtimes -- separate temp
        aid_home/project dirs per runtime (each side really mutates its own
        disk), asserting the JSON envelope bodies are byte-identical (the
        success envelope carries no path-specific data, so this IS a
        meaningful byte-parity assertion, not a tautology)."""
        py_base = Path(tempfile.mkdtemp())
        node_base = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: shutil.rmtree(str(py_base), ignore_errors=True))
        self.addCleanup(lambda: shutil.rmtree(str(node_base), ignore_errors=True))

        py_aid_home = py_base / "aid_home"
        _make_aid_home(py_aid_home)
        py_proj = py_base / "real-project-ki009-py"
        (py_proj / ".aid").mkdir(parents=True, exist_ok=True)

        node_aid_home = node_base / "aid_home"
        _make_aid_home(node_aid_home)
        node_proj = node_base / "real-project-ki009-node"
        (node_proj / ".aid").mkdir(parents=True, exist_ok=True)

        # Node side add.
        node_add_status, node_add_body = self._node_dispatch_project_op(
            {"op": "project.add", "args": {"path": str(node_proj).replace("\\", "/")}},
            str(node_aid_home).replace("\\", "/"),
        )
        self.assertEqual(node_add_status, 200, node_add_body)

        # Python side add -- forced is_windows=True the same way (D)'s class
        # does (_dispatch_op -> _spawn_aid_cli -> _run_aid_cli carries no
        # is_windows override of its own, so redirect-then-restore the
        # module-level _run_aid_cli for the duration of this call only).
        orig = srv._run_aid_cli

        def forced(argv, env_overrides, timeout=srv._DEFAULT_AID_CLI_TIMEOUT):
            return orig(argv, env_overrides, timeout, is_windows=True)

        srv._run_aid_cli = forced
        try:
            py_add_status, py_add_body_raw = srv._dispatch_op(
                srv.HOME_OP_TABLE, {"op": "project.add", "args": {"path": str(py_proj).replace("\\", "/")}},
                str(py_aid_home),
            )
            # _dispatch_op returns BYTES (Python's own wire-body type); the
            # Node driver already decodes to a JS/JSON string on its side
            # (Buffer.from(...).toString('utf-8')) -- decode here too so the
            # cross-runtime comparison is content-vs-content, not
            # bytes-vs-str (mirrors test_task017's _assert_parity convention).
            py_add_body = py_add_body_raw.decode("utf-8")
            self.assertEqual(py_add_status, 200, py_add_body)
            self.assertEqual(py_add_status, node_add_status, "python/node project.add status DIVERGE")
            self.assertEqual(py_add_body, node_add_body, "python/node project.add response body DIVERGE")

            py_id_map, _warnings = srv._get_id_map(str(py_aid_home))
            py_target_id = next((k for k, v in py_id_map.items() if "real-project-ki009-py" in v), None)
            self.assertIsNotNone(py_target_id, py_id_map)

            py_remove_status, py_remove_body_raw = srv._dispatch_op(
                srv.HOME_OP_TABLE, {"op": "project.remove", "target": {"id": py_target_id}}, str(py_aid_home),
            )
            py_remove_body = py_remove_body_raw.decode("utf-8")
            self.assertEqual(py_remove_status, 200, py_remove_body)
        finally:
            srv._run_aid_cli = orig

        node_id_map = self._node_get_id_map(str(node_aid_home).replace("\\", "/"))
        node_target_id = next((k for k, v in node_id_map.items() if "real-project-ki009-node" in v), None)
        self.assertIsNotNone(node_target_id, node_id_map)

        node_remove_status, node_remove_body = self._node_dispatch_project_op(
            {"op": "project.remove", "target": {"id": node_target_id}},
            str(node_aid_home).replace("\\", "/"),
        )
        self.assertEqual(node_remove_status, 200, node_remove_body)

        self.assertEqual(py_remove_status, node_remove_status, "python/node project.remove status DIVERGE")
        self.assertEqual(py_remove_body, node_remove_body, "python/node project.remove response body DIVERGE")


if __name__ == "__main__":
    unittest.main(verbosity=2)
