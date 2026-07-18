"""
test_write_enabled_cross_runtime_parity.py -- task-011 (feature-001-write-infrastructure,
delivery-001): "Foundation parity + dispatch round-trip suite" -- write_enabled
CROSS-RUNTIME byte-parity leg (closes AC1's write_enabled gap).

test_server_py.py and test_server_node.mjs each already prove their OWN twin's
write_enabled behavior in isolation (default False on a bare spawn, True with
--allow-writes, in both the DM-1 /r/<id>/api/model envelope and the DM-2
/api/home machine block) -- but always via a REAL server spawn on THEIR OWN
runtime. Neither compares the two runtimes against the SAME fixture in a
single test. This file closes that gap the same way
dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py closes
the analogous gap for resolve_work_dir: it calls the Python serializer
functions directly (in-process import) and the Node serializer functions via
a short-lived `node` subprocess -- NO server spawn, NO port binding.

server.mjs has no top-level `export` statements, and its own module-scope
tail unconditionally parses argv and BINDS A SOCKET (`server.listen(...)`),
so it cannot be `import()`-ed directly without triggering either side effect.
This file works around that WITHOUT touching server.mjs: it slices
server.mjs's own source text at the stable "// Main: parse args, create
server, bind, register SIGTERM" marker comment (everything before that
marker is pure function/const declarations -- no argv parsing, no socket
bind reachable at module-evaluation time), appends a plain `export { ... }`
statement naming the functions this test needs, and writes the result to a
throwaway sibling file placed NEXT TO the real server.mjs/reader.mjs (same
directory) so its own `import.meta.url`-derived `__dirname_srv` and its
relative `import ... from "./reader.mjs"` resolve exactly as they do in the
real file. The sibling file is deleted in `finally`/tearDownClass regardless
of outcome. This exercises the ACTUAL current server.mjs bytes for
serializeModel / serializeModelWithDetails / buildHomeModel / serializeHome
-- not a hand copy -- so an edit to any of those functions is exactly what
this test proves (or disproves) parity against, the same guarantee the
existing resolve_work_dir suite gives for resolveWorkDir.

Covers (per task-011 DETAIL, AC1):
  - DM-1 envelope (serialize_model / serializeModel): write_enabled is
    present at the TOP LEVEL, beside generated_by (never nested inside
    `model`), with the identical boolean value in both runtimes' RAW
    compact-JSON bytes, for both write_enabled=True and write_enabled=False.
  - DM-2 model (build_home_model / buildHomeModel + serialize_home /
    serializeHome): write_enabled is present inside the `machine` block
    (never at the DM-2 envelope top level), identical boolean value, both
    runtimes, both flag states.

Deliberately NOT named test_task011_*.py: dashboard/server/tests/ already has
test_task011_dispatch_round_trip.py (an UNRELATED task-011 leg -- OP dispatch,
not serialization parity); this name instead mirrors
test_resolve_work_dir_cross_runtime_parity.py's own convention one-for-one
(test_<subject>_cross_runtime_parity.py).

Python 3.11+ stdlib only. No third-party deps. Requires `node` on PATH for the
Node-side comparison (module SKIPS, not fails, if absent).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as _server_module
from dashboard.reader.reader import read_repo

_SERVER_MJS = _SERVER_DIR / "server.mjs"
_READER_MJS = _SERVER_DIR / "reader.mjs"

# Stable single-line cut marker: everything BEFORE this comment in server.mjs
# is pure function/const declarations (no argv parsing, no socket bind at
# module-evaluation time); everything from this comment onward is the
# side-effecting "Main" tail. See module docstring.
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , slicePath, readerPath, servedRoot, writeEnabledStr] = process.argv;
const writeEnabled = writeEnabledStr === "true";
const sliceMod = await import(pathToFileURL(slicePath).href);
const readerMod = await import(pathToFileURL(readerPath).href);

const model = readerMod.readRepo(servedRoot);
const dm1Buf = sliceMod.serializeModel(model, writeEnabled);
const dm1Raw = Buffer.from(dm1Buf).toString("utf-8");

const dm2Model = sliceMod.buildHomeModel(
  servedRoot, servedRoot + "/registry.yml", [], [], "node", writeEnabled
);
const dm2Buf = sliceMod.serializeHome(dm2Model);
const dm2Raw = Buffer.from(dm2Buf).toString("utf-8");

process.stdout.write(JSON.stringify({ dm1_raw: dm1Raw, dm2_raw: dm2Raw }));
"""


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()


def _sliced_server_mjs_source() -> str:
    """Return server.mjs's own source, truncated right before its side-effecting
    'Main' tail (argv parsing + socket bind), with serializeModel /
    serializeModelWithDetails / buildHomeModel / serializeHome re-exported.

    Raises AssertionError (loud, not silent) if the stable marker is gone --
    signals server.mjs was restructured and this slice's cut point needs
    updating, rather than silently comparing against stale/wrong code.
    """
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    return (
        text[:idx]
        + "\nexport { serializeModel, serializeModelWithDetails, buildHomeModel, serializeHome };\n"
    )


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime comparison skipped")
class TestWriteEnabledCrossRuntimeParity(unittest.TestCase):
    """Python serialize_model()/build_home_model() and Node's twin functions
    agree, byte-for-byte, on write_enabled -- for both flag states, in both
    the DM-1 envelope and the DM-2 machine block."""

    @classmethod
    def setUpClass(cls) -> None:
        # Written NEXT TO the real server.mjs/reader.mjs (not a tmp dir) so its
        # own import.meta.url-derived __dirname_srv and its relative
        # `./reader.mjs` import resolve exactly as they do in the real file.
        cls._slice_path = _SERVER_DIR / f"_test_write_enabled_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def _node_serialize(self, write_enabled: bool) -> dict:
        """Invoke the sliced server.mjs's serializeModel/buildHomeModel/serializeHome
        via a short-lived `node` subprocess (a bounded compute call -- no server
        spawn, no port binding). Returns {"dm1_raw": <str>, "dm2_raw": <str>}."""
        driver = self._tmp / "driver.mjs"
        driver.write_text(_NODE_DRIVER, encoding="utf-8")
        proc = subprocess.run(
            [
                "node", str(driver),
                str(self._slice_path), str(_READER_MJS),
                str(self._tmp), "true" if write_enabled else "false",
            ],
            capture_output=True, text=True, timeout=15,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed (exit {proc.returncode}): {proc.stderr}")
        return json.loads(proc.stdout)

    def _assert_write_enabled_parity(self, write_enabled: bool) -> None:
        # ---- Python side (in-process, the REAL production functions) ----
        py_model = read_repo(self._tmp)
        py_dm1_raw = _server_module.serialize_model(py_model, write_enabled=write_enabled).decode("utf-8")
        py_dm2_model = _server_module.build_home_model(
            aid_home=str(self._tmp), reg_path=self._tmp / "registry.yml",
            id_map={}, warnings=[], runtime="python", write_enabled=write_enabled,
        )
        py_dm2_raw = _server_module.serialize_home(py_dm2_model).decode("utf-8")

        # ---- Node side (subprocess, the sliced-but-real current server.mjs bytes) ----
        node_result = self._node_serialize(write_enabled)
        node_dm1_raw = node_result["dm1_raw"]
        node_dm2_raw = node_result["dm2_raw"]

        expected_fragment = f'"write_enabled":{"true" if write_enabled else "false"}'

        # -- DM-1: top-level, beside generated_by -- byte-identical compact rendering.
        self.assertIn(expected_fragment, py_dm1_raw, "Python DM-1 raw bytes must carry write_enabled")
        self.assertIn(expected_fragment, node_dm1_raw, "Node DM-1 raw bytes must carry write_enabled")
        py_dm1 = json.loads(py_dm1_raw)
        node_dm1 = json.loads(node_dm1_raw)
        self.assertIn("generated_by", py_dm1)
        self.assertIn("generated_by", node_dm1)
        self.assertEqual(py_dm1["write_enabled"], write_enabled)
        self.assertEqual(node_dm1["write_enabled"], write_enabled)
        self.assertEqual(
            py_dm1["write_enabled"], node_dm1["write_enabled"],
            "DM-1 write_enabled must be byte-identical across runtimes",
        )
        self.assertNotIn("write_enabled", py_dm1.get("model") or {})
        self.assertNotIn("write_enabled", node_dm1.get("model") or {})

        # -- DM-2: inside `machine`, never at the envelope top level -- byte-identical.
        self.assertIn(expected_fragment, py_dm2_raw, "Python DM-2 raw bytes must carry write_enabled")
        self.assertIn(expected_fragment, node_dm2_raw, "Node DM-2 raw bytes must carry write_enabled")
        py_dm2 = json.loads(py_dm2_raw)
        node_dm2 = json.loads(node_dm2_raw)
        self.assertNotIn("write_enabled", py_dm2)
        self.assertNotIn("write_enabled", node_dm2)
        self.assertEqual(py_dm2["machine"]["write_enabled"], write_enabled)
        self.assertEqual(node_dm2["machine"]["write_enabled"], write_enabled)
        self.assertEqual(
            py_dm2["machine"]["write_enabled"], node_dm2["machine"]["write_enabled"],
            "DM-2 machine.write_enabled must be byte-identical across runtimes",
        )

    def test_write_enabled_true_parity(self):
        self._assert_write_enabled_parity(True)

    def test_write_enabled_false_parity(self):
        self._assert_write_enabled_parity(False)


if __name__ == "__main__":
    unittest.main(verbosity=2)
