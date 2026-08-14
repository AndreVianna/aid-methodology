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
  - DM-1 tools_catalog (additive, work-017 post-dogfood Tools section):
    present at the envelope top level (AFTER write_enabled, BEFORE model),
    an array, byte-identical across runtimes -- exercised as a byproduct of
    the SAME fixture this file already drives for write_enabled, since both
    keys are serialized by the identical serialize_model/serializeModel call.
  - SP-19b (work-009-refactor task-016): against a converted (STATE.yml)
    work, each of the three write-enabled edit surfaces -- task.set-notes,
    pipeline.finish (Lifecycle=Completed), task.rename -- writes
    successfully to STATE.yml in BOTH runtimes (a REAL writeback-state.sh
    spawn each side, never stubbed) with identical dispatch results, and
    the raw-state viewer (read_repo_detail / readRepoDetail's
    TaskDetail.raw_state.path) resolves the SAME source path in both --
    the oracle that would catch a half-retargeted AID_STATE_FILE (see
    TestSp19bWriteEnabledEditSurfacesBothRuntimes below).

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


_NODE_DISPATCH_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , slicePath, readerPath, servedRoot, opJson, workId, taskId] = process.argv;
const sliceMod = await import(pathToFileURL(slicePath).href);
const readerMod = await import(pathToFileURL(readerPath).href);

const parsed = JSON.parse(opJson);
const [status, bodyBuf] = sliceMod.dispatchOp(sliceMod.OP_TABLE, parsed, servedRoot, servedRoot);
const body = Buffer.from(bodyBuf).toString("utf-8");

const { details } = readerMod.readRepoDetail(servedRoot, [workId + "/" + taskId]);
const detail = details[workId + "/" + taskId];
const rawStatePath = detail ? detail.raw_state.path : null;

process.stdout.write(JSON.stringify({ status, body, raw_state_path: rawStatePath }));
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
        + "\nexport { serializeModel, serializeModelWithDetails, buildHomeModel, serializeHome, "
          "dispatchOp, OP_TABLE };\n"
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

        # -- DM-1 tools_catalog (additive, work-017 post-dogfood Tools section):
        # present at the envelope top level, an array, positioned AFTER
        # write_enabled and BEFORE model in BOTH runtimes (schema_version
        # stays 3 -- RC-2 no-bump precedent, same as write_enabled itself).
        self.assertIn("tools_catalog", py_dm1, "Python DM-1 envelope must carry tools_catalog")
        self.assertIn("tools_catalog", node_dm1, "Node DM-1 envelope must carry tools_catalog")
        self.assertIsInstance(py_dm1["tools_catalog"], list)
        self.assertIsInstance(node_dm1["tools_catalog"], list)
        self.assertEqual(
            list(py_dm1.keys()), ["schema_version", "generated_by", "write_enabled", "tools_catalog", "model"],
            "Python DM-1 envelope key order",
        )
        self.assertEqual(
            list(node_dm1.keys()), ["schema_version", "generated_by", "write_enabled", "tools_catalog", "model"],
            "Node DM-1 envelope key order",
        )
        self.assertEqual(
            py_dm1["tools_catalog"], node_dm1["tools_catalog"],
            "DM-1 tools_catalog must be byte-identical across runtimes (both read the same "
            "install-tree lib/tools-catalog.txt / static fallback list)",
        )

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


def _make_flat_work_sp19b(root: Path, work_id: str, notes: str = "--") -> Path:
    """A flat-layout work (BLUEPRINT.md + tasks/task-001/DETAIL.md) with a
    STATE.yml `tasks_lifecycle` entry -- the fixture the SP-19b write-path
    assertions below dispatch task.set-notes / pipeline.finish / task.rename
    against, in BOTH runtimes (work-009-refactor task-016). `AID_STATE_FILE`
    is an explicit override to `STATE.yml` for all three ops (task-020), so
    the fixture MUST use that filename or the writer dies "$STATE_FILE does
    not exist" (exit 1) -- exactly the half-retargeted-AID_STATE_FILE
    failure mode this suite exists to catch."""
    work_dir = root / ".aid" / "works" / work_id
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text(
        "# task-001\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
    )
    (work_dir / "REQUIREMENTS.md").write_text(
        "# Requirements\n\n- **Name:** Old Title\n", encoding="utf-8",
    )
    (work_dir / "STATE.yml").write_text(
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "pause_reason: --\n"
        "block_reason: --\n"
        "block_artifact: --\n"
        "tasks_lifecycle:\n"
        "  task-001:\n"
        "    state: Pending\n"
        "    review: --\n"
        "    elapsed: --\n"
        f"    notes: {notes}\n",
        encoding="utf-8",
    )
    return work_dir


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime comparison skipped")
class TestSp19bWriteEnabledEditSurfacesBothRuntimes(unittest.TestCase):
    """SP-19b: against a converted (STATE.yml) work, each of the three
    write-enabled edit surfaces -- task.set-notes, pipeline.finish
    (Lifecycle=Completed), task.rename -- writes successfully to STATE.yml
    in BOTH runtimes with identical dispatch results, and the raw-state
    viewer (read_repo_detail / readRepoDetail's TaskDetail.raw_state.path)
    resolves the SAME source path in both. This is the oracle that would
    catch a half-retargeted AID_STATE_FILE: if either runtime's op
    build_argv/buildArgv still pointed at the retired STATE.md filename, the
    writer would die "does not exist" (exit 1 -> 404), a real writer-spawn
    failure this test's real (non-stubbed) writeback-state.sh dispatch would
    surface immediately -- not a false green."""

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_sp19b_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def setUp(self) -> None:
        self._py_root = Path(tempfile.mkdtemp())
        self._node_root = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._py_root), ignore_errors=True)
        shutil.rmtree(str(self._node_root), ignore_errors=True)

    def _py_dispatch_and_detail(self, root: Path, request: dict, work_id: str, task_id: str) -> dict:
        import unittest.mock as mock
        from dashboard.reader import read_repo_detail as _read_repo_detail

        status, body = _server_module._dispatch_op(_server_module.OP_TABLE, request, str(root))
        aid = root / ".aid"
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            _model, details = _read_repo_detail(root, [f"{work_id}/{task_id}"])
        detail = details.get(f"{work_id}/{task_id}")
        raw_state_path = detail.raw_state.path if detail is not None else None
        return {"status": status, "body": body.decode("utf-8"), "raw_state_path": raw_state_path}

    def _node_dispatch_and_detail(self, root: Path, request: dict, work_id: str, task_id: str) -> dict:
        driver = root / "_sp19b_driver.mjs"
        driver.write_text(_NODE_DISPATCH_DRIVER, encoding="utf-8")
        proc = subprocess.run(
            [
                "node", str(driver),
                str(self._slice_path), str(_READER_MJS),
                str(root), json.dumps(request), work_id, task_id,
            ],
            capture_output=True, text=True, timeout=15,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node dispatch driver failed (exit {proc.returncode}): {proc.stderr}")
        return json.loads(proc.stdout)

    def test_task_set_notes_both_runtimes(self):
        work_id = "work-810-sp19b-notes"
        _make_flat_work_sp19b(self._py_root, work_id)
        _make_flat_work_sp19b(self._node_root, work_id)
        request = {
            "op": "task.set-notes",
            "target": {"work_id": work_id, "task_id": "001"},
            "args": {"value": "sp19b cross-runtime note"},
        }
        py_result = self._py_dispatch_and_detail(self._py_root, request, work_id, "task-001")
        node_result = self._node_dispatch_and_detail(self._node_root, request, work_id, "task-001")

        self.assertEqual(py_result["status"], 200, py_result["body"])
        self.assertEqual(node_result["status"], 200, node_result["body"])
        self.assertEqual(py_result["status"], node_result["status"])
        self.assertEqual(json.loads(py_result["body"]), json.loads(node_result["body"]))

        py_content = (self._py_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        node_content = (self._node_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        self.assertIn("sp19b cross-runtime note", py_content)
        self.assertIn("sp19b cross-runtime note", node_content)

        # The raw-state viewer resolves the SAME source path in both runtimes
        # (the oracle for a half-retargeted AID_STATE_FILE: a wrong path here
        # would mean one runtime's viewer silently shows stale/empty content).
        self.assertEqual(py_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(node_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(py_result["raw_state_path"], node_result["raw_state_path"])

    def test_pipeline_finish_lifecycle_completed_both_runtimes(self):
        work_id = "work-811-sp19b-finish"
        _make_flat_work_sp19b(self._py_root, work_id)
        _make_flat_work_sp19b(self._node_root, work_id)
        request = {"op": "pipeline.finish", "target": {"work_id": work_id}}
        py_result = self._py_dispatch_and_detail(self._py_root, request, work_id, "task-001")
        node_result = self._node_dispatch_and_detail(self._node_root, request, work_id, "task-001")

        self.assertEqual(py_result["status"], 200, py_result["body"])
        self.assertEqual(node_result["status"], 200, node_result["body"])
        self.assertEqual(json.loads(py_result["body"]), json.loads(node_result["body"]))

        py_content = (self._py_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        node_content = (self._node_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        self.assertIn("lifecycle: Completed", py_content)
        self.assertIn("lifecycle: Completed", node_content)

        self.assertEqual(py_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(node_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(py_result["raw_state_path"], node_result["raw_state_path"])

    def test_task_rename_both_runtimes(self):
        work_id = "work-812-sp19b-rename"
        _make_flat_work_sp19b(self._py_root, work_id)
        _make_flat_work_sp19b(self._node_root, work_id)
        request = {
            "op": "task.rename",
            "target": {"work_id": work_id, "task_id": "001"},
            "args": {"value": "SP-19b renamed task"},
        }
        py_result = self._py_dispatch_and_detail(self._py_root, request, work_id, "task-001")
        node_result = self._node_dispatch_and_detail(self._node_root, request, work_id, "task-001")

        self.assertEqual(py_result["status"], 200, py_result["body"])
        self.assertEqual(node_result["status"], 200, node_result["body"])
        self.assertEqual(json.loads(py_result["body"]), json.loads(node_result["body"]))

        py_content = (self._py_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        node_content = (self._node_root / ".aid" / "works" / work_id / "STATE.yml").read_text(encoding="utf-8")
        self.assertIn("SP-19b renamed task", py_content)
        self.assertIn("SP-19b renamed task", node_content)

        self.assertEqual(py_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(node_result["raw_state_path"], f".aid/works/{work_id}/STATE.yml")
        self.assertEqual(py_result["raw_state_path"], node_result["raw_state_path"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
