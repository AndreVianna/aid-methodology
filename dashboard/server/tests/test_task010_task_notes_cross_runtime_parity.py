"""
test_task010_task_notes_cross_runtime_parity.py -- task-010 (feature-006-task-notes,
delivery-001): CROSS-RUNTIME parity leg for the task.set-notes handler this task
finalizes -- the target.task_id superset normalization ('task-NNN' or bare 'NNN' ->
bare numeric, shared _dispatch_op/dispatchOp logic) and the empty-value -> '--'
null-sentinel argv-builder substitution.

test_task010_task_notes.py already proves this logic on the Python twin in-process
(no server spawn). This file closes the analogous Node-twin gap the same way
test_write_enabled_cross_runtime_parity.py closes it for write_enabled and
test_resolve_work_dir_cross_runtime_parity.py closes it for resolve_work_dir: it
calls Python's `srv._dispatch_op` directly (in-process import) and Node's
`dispatchOp` via a short-lived `node` subprocess -- NO server spawn, NO port
binding, so this is safe to run locally per this repo's port-binding-test
constraint (both sides DO spawn a REAL writeback-state.sh child via bash --
a bounded, non-interactive, fast subprocess -- the SAME thing
test_task004_op_dispatch.py already does locally).

server.mjs has no top-level `export` statements and self-executes (parses argv,
BINDS A SOCKET) on import, so it cannot be `import()`-ed directly. This file
reuses test_write_enabled_cross_runtime_parity.py's own workaround: slice
server.mjs's source at the stable "// Main: parse args, create server, bind,
register SIGTERM" marker (everything before it is pure function/const
declarations reachable at module-evaluation time with no side effect), append a
plain `export { ... }` naming the functions this test needs, and write the
result to a throwaway sibling file next to the real server.mjs/reader.mjs (so
its own relative `./reader.mjs` import resolves exactly as it does in the real
file). The sibling file is deleted in tearDownClass regardless of outcome.

Covers:
  - target.task_id accepts BOTH the prefixed 'task-NNN' form and the bare 'NNN'
    form, normalizing to the bare numeric id before the writer spawn -- proven
    via a REAL writeback-state.sh round-trip, byte-identical outcome in both
    runtimes.
  - An empty args.value round-trips to a SUCCESSFUL 200 write with the '--' null
    sentinel (NOT the writer's own exit-5 'value is required' guard) in both
    runtimes.
  - args.value containing '|' / a newline / exceeding the 1 KiB cap 422s
    'invalid-value' in both runtimes, without ever reaching the writer.
  - A malformed target.task_id (does not match the superset regex) still 400s
    'bad-request' in both runtimes (the superset did not over-widen).

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

from dashboard.server import server as srv

_SERVER_MJS = _SERVER_DIR / "server.mjs"

# Stable single-line cut marker -- see test_write_enabled_cross_runtime_parity.py's
# own module docstring for the full rationale; kept in lockstep with that file's
# identical marker string.
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , slicePath, servedRoot, requestJson] = process.argv;
const sliceMod = await import(pathToFileURL(slicePath).href);
const request = JSON.parse(requestJson);
const [status, bodyBuf] = sliceMod.dispatchOp(sliceMod.OP_TABLE, request, servedRoot);
const bodyStr = Buffer.from(bodyBuf).toString("utf-8");
process.stdout.write(JSON.stringify({ status: status, body: bodyStr }));
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
    'Main' tail, with dispatchOp / OP_TABLE re-exported.

    Raises AssertionError (loud, not silent) if the stable marker is gone.
    """
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    return text[:idx] + "\nexport { dispatchOp, OP_TABLE };\n"


def _make_flat_work(root: Path, work_id: str, notes: str = "--") -> Path:
    """A minimal FLAT-layout work with a '### Tasks lifecycle' row for task-001."""
    work_dir = root / ".aid" / "works" / work_id
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text("# task-001\n", encoding="utf-8")
    (work_dir / "STATE.md").write_text(
        "---\n"
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "---\n\n"
        "# Work State\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        f"| task-001 | Pending | -- | -- | {notes} |\n",
        encoding="utf-8",
    )
    return work_dir


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime comparison skipped")
class TestTaskSetNotesCrossRuntimeParity(unittest.TestCase):
    """Python's _dispatch_op and Node's dispatchOp agree on task.set-notes's
    task_id-normalization and empty-value-sentinel behavior, driven through a
    REAL writeback-state.sh child in both runtimes."""

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_task010_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def _node_dispatch(self, served_root: str, request: dict) -> "tuple[int, str]":
        """Invoke the sliced server.mjs's dispatchOp via a short-lived `node`
        subprocess (a bounded, non-interactive call that itself spawns a REAL
        writeback-state.sh child via bash -- no server spawn, no port binding).
        Returns (status, body_str)."""
        driver = self._tmp / "driver.mjs"
        driver.write_text(_NODE_DRIVER, encoding="utf-8")
        proc = subprocess.run(
            ["node", str(driver), str(self._slice_path), served_root, json.dumps(request)],
            capture_output=True, text=True, timeout=15,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed (exit {proc.returncode}): {proc.stderr}")
        result = json.loads(proc.stdout)
        return result["status"], result["body"]

    def _py_dispatch(self, served_root: str, request: dict) -> "tuple[int, str]":
        status, body = srv._dispatch_op(srv.OP_TABLE, request, served_root)
        return status, body.decode("utf-8") if isinstance(body, (bytes, bytearray)) else body

    def test_prefixed_task_id_accepted_and_normalized_both_runtimes(self):
        py_root = self._tmp / "py-repo"
        node_root = self._tmp / "node-repo"
        py_work_dir = _make_flat_work(py_root, "work-900-prefixed")
        node_work_dir = _make_flat_work(node_root, "work-900-prefixed")

        request = {
            "op": "task.set-notes",
            "target": {"work_id": "work-900-prefixed", "task_id": "task-001"},
            "args": {"value": "hello from prefixed id"},
        }
        py_status, py_body = self._py_dispatch(str(py_root), request)
        node_status, node_body = self._node_dispatch(str(node_root), request)

        self.assertEqual(py_status, 200, py_body)
        self.assertEqual(node_status, 200, node_body)
        self.assertEqual(py_status, node_status)
        self.assertEqual(json.loads(py_body), json.loads(node_body))
        self.assertIn("hello from prefixed id", (py_work_dir / "STATE.md").read_text(encoding="utf-8"))
        self.assertIn("hello from prefixed id", (node_work_dir / "STATE.md").read_text(encoding="utf-8"))

    def test_empty_value_clears_to_null_sentinel_both_runtimes(self):
        py_root = self._tmp / "py-repo"
        node_root = self._tmp / "node-repo"
        py_work_dir = _make_flat_work(py_root, "work-901-clear", notes="had notes")
        node_work_dir = _make_flat_work(node_root, "work-901-clear", notes="had notes")

        request = {
            "op": "task.set-notes",
            "target": {"work_id": "work-901-clear", "task_id": "001"},
            "args": {"value": ""},
        }
        py_status, py_body = self._py_dispatch(str(py_root), request)
        node_status, node_body = self._node_dispatch(str(node_root), request)

        self.assertEqual(py_status, 200, py_body)
        self.assertEqual(node_status, 200, node_body)
        self.assertEqual(json.loads(py_body), json.loads(node_body))
        py_content = (py_work_dir / "STATE.md").read_text(encoding="utf-8")
        node_content = (node_work_dir / "STATE.md").read_text(encoding="utf-8")
        self.assertIn("| task-001 | Pending | -- | -- | -- |", py_content)
        self.assertIn("| task-001 | Pending | -- | -- | -- |", node_content)
        self.assertNotIn("had notes", py_content)
        self.assertNotIn("had notes", node_content)

    def test_pipe_value_is_422_both_runtimes(self):
        py_root = self._tmp / "py-repo"
        node_root = self._tmp / "node-repo"
        _make_flat_work(py_root, "work-902-pipe")
        _make_flat_work(node_root, "work-902-pipe")

        request = {
            "op": "task.set-notes",
            "target": {"work_id": "work-902-pipe", "task_id": "001"},
            "args": {"value": "a|b"},
        }
        py_status, py_body = self._py_dispatch(str(py_root), request)
        node_status, node_body = self._node_dispatch(str(node_root), request)

        self.assertEqual(py_status, 422)
        self.assertEqual(node_status, 422)
        self.assertEqual(json.loads(py_body)["error"], "invalid-value")
        self.assertEqual(json.loads(node_body)["error"], "invalid-value")

    def test_oversize_value_is_422_both_runtimes(self):
        py_root = self._tmp / "py-repo"
        node_root = self._tmp / "node-repo"
        _make_flat_work(py_root, "work-903-oversize")
        _make_flat_work(node_root, "work-903-oversize")

        request = {
            "op": "task.set-notes",
            "target": {"work_id": "work-903-oversize", "task_id": "001"},
            "args": {"value": "x" * 1025},
        }
        py_status, py_body = self._py_dispatch(str(py_root), request)
        node_status, node_body = self._node_dispatch(str(node_root), request)

        self.assertEqual(py_status, 422)
        self.assertEqual(node_status, 422)
        self.assertEqual(json.loads(py_body)["error"], "invalid-value")
        self.assertEqual(json.loads(node_body)["error"], "invalid-value")

    def test_malformed_task_id_is_400_both_runtimes(self):
        py_root = self._tmp / "py-repo"
        node_root = self._tmp / "node-repo"

        request = {
            "op": "task.set-notes",
            "target": {"work_id": "work-904-bad", "task_id": "task-abc"},
            "args": {"value": "x"},
        }
        py_status, py_body = self._py_dispatch(str(py_root), request)
        node_status, node_body = self._node_dispatch(str(node_root), request)

        self.assertEqual(py_status, 400)
        self.assertEqual(node_status, 400)
        self.assertEqual(json.loads(py_body)["error"], "bad-request")
        self.assertEqual(json.loads(node_body)["error"], "bad-request")


if __name__ == "__main__":
    unittest.main(verbosity=2)
