"""
test_task029_stop_requested.py -- work-017-cli-improvements,
feature-008-execution-control, delivery-005 task-029.

Covers the reader-twin half of task-029 (TaskModel.stop_requested):
  - `_task_stop_requested(work_dir, work_id, task_id)`: the raw stat helper --
    present signal file -> True; absent signal file in an existing control
    dir -> False; missing `.control/` directory entirely -> False; a
    different task_id's signal in the SAME control dir does not leak; never
    throws (even on a pathological same-named DIRECTORY at the signal path).
  - `read_repo()` end-to-end for BOTH the flat (work-root `### Tasks
    lifecycle`) and hierarchical (per-task STATE.md) layouts: the derived
    field flows onto TaskModel with no STATE.md parser change (the control
    file is never read as STATE.md, and STATE.md is never touched by this
    field).
  - Serialized DM shape (`_ser_task`) carries `stop_requested`.
  - WT-1: the control dir is derived relative to the WALKED work_dir (the
    real worktree copy `enumerate_worktree_roots` returns), never
    reconstructed from the `aid_root`/served-root argument passed to
    `read_repo()` -- a signal seeded under the wrong (served-root) tree has
    NO effect; a signal seeded under the real worktree tree IS detected.
  - Cross-twin parity (Python `read_repo()` vs Node `readRepo()`, computed
    in-process via a bounded subprocess -- no server, no port, no *parity*.sh
    script) for both layouts and both signal states.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.reader import _task_stop_requested

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# (1) Unit tests: _task_stop_requested raw stat helper
# ---------------------------------------------------------------------------

class TestTaskStopRequestedHelper(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _work_dir(self, work_id: str) -> Path:
        work_dir = self.tmp / ".aid" / "works" / work_id
        work_dir.mkdir(parents=True, exist_ok=True)
        return work_dir

    def test_present_signal_file_returns_true(self):
        work_id = "work-100-sample"
        work_dir = self._work_dir(work_id)
        control_dir = self.tmp / ".aid" / ".control" / work_id
        control_dir.mkdir(parents=True)
        (control_dir / "task-001.stop").write_text(
            "[2026-01-01T00:00:00Z] stop | source=dashboard\n", encoding="utf-8",
        )
        self.assertTrue(_task_stop_requested(work_dir, work_id, "task-001"))

    def test_absent_signal_file_in_existing_control_dir_returns_false(self):
        work_id = "work-101-sample"
        work_dir = self._work_dir(work_id)
        control_dir = self.tmp / ".aid" / ".control" / work_id
        control_dir.mkdir(parents=True)
        self.assertFalse(_task_stop_requested(work_dir, work_id, "task-001"))

    def test_missing_control_dir_entirely_returns_false(self):
        work_id = "work-102-sample"
        work_dir = self._work_dir(work_id)
        # No .control dir created at all -- fail-safe, never throws.
        self.assertFalse(_task_stop_requested(work_dir, work_id, "task-001"))

    def test_different_task_id_in_same_control_dir_does_not_leak(self):
        work_id = "work-103-sample"
        work_dir = self._work_dir(work_id)
        control_dir = self.tmp / ".aid" / ".control" / work_id
        control_dir.mkdir(parents=True)
        (control_dir / "task-002.stop").write_text("stop\n", encoding="utf-8")
        self.assertFalse(_task_stop_requested(work_dir, work_id, "task-001"))
        self.assertTrue(_task_stop_requested(work_dir, work_id, "task-002"))

    def test_never_throws_on_a_directory_named_like_the_signal_file(self):
        """A pathological same-named DIRECTORY (not a file) at the signal
        path -- Path.is_file() correctly returns False, never an exception."""
        work_id = "work-104-sample"
        work_dir = self._work_dir(work_id)
        control_dir = self.tmp / ".aid" / ".control" / work_id
        control_dir.mkdir(parents=True)
        (control_dir / "task-001.stop").mkdir()
        self.assertFalse(_task_stop_requested(work_dir, work_id, "task-001"))

    def test_different_work_id_control_dir_does_not_leak(self):
        """Two different work_ids under the same .control/ root: a signal for
        one work_id must not be visible when stat'ing the other's."""
        work_a = "work-105-a"
        work_b = "work-105-b"
        work_dir_a = self._work_dir(work_a)
        self._work_dir(work_b)
        control_dir_a = self.tmp / ".aid" / ".control" / work_a
        control_dir_a.mkdir(parents=True)
        (control_dir_a / "task-001.stop").write_text("stop\n", encoding="utf-8")
        self.assertTrue(_task_stop_requested(work_dir_a, work_a, "task-001"))
        # work_b's own work_dir, queried against work_b's own id -- no signal seeded there
        work_dir_b = self.tmp / ".aid" / "works" / work_b
        self.assertFalse(_task_stop_requested(work_dir_b, work_b, "task-001"))


# ---------------------------------------------------------------------------
# Shared fixture builders (mirrors test_task008_display_rename.py's own)
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
    root = tmp
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    manifest = {
        "manifest_version": 1,
        "aid_version": "1.0.0",
        "installed_at": "2026-01-01T00:00:00Z",
        "tools": {"claude-code": {}},
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (aid / "settings.yml").write_text("project:\n  name: TestRepo\n", encoding="utf-8")
    return root, aid


def _build_flat_work(aid: Path, work_id: str) -> Path:
    """Lite-flat layout (BLUEPRINT.md + tasks/task-NNN/DETAIL.md, no deliveries/)."""
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Flat delivery\n\n"
        "## Objective\n\nDeliver.\n\n## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    (work_dir / "STATE.md").write_text(
        "## Pipeline State\n\n- **Lifecycle:** Running\n\n"
        "## Delivery Lifecycle\n\n- **State:** Executing\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "|------|-------|--------|---------|-------|\n"
        "| task-001 | In Progress | -- | -- | -- |\n",
        encoding="utf-8",
    )
    task_dir = work_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Flat task short name\n\n**Type:** IMPLEMENT\n\nBody.\n",
        encoding="utf-8",
    )
    return work_dir


def _build_hierarchical_work(aid: Path, work_id: str) -> Path:
    """Full-nested layout (deliveries/delivery-NNN/tasks/task-NNN/{DETAIL,STATE}.md)."""
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text("## Pipeline State\n\n- **Lifecycle:** Running\n", encoding="utf-8")

    del_dir = work_dir / "deliveries" / "delivery-001"
    del_dir.mkdir(parents=True, exist_ok=True)
    (del_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Nested delivery\n\n"
        "## Objective\n\nDeliver.\n\n## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n- **State:** Executing\n\n"
        "## Delivery Gate\n\n- **Reviewer Tier:** Small\n- **Grade:** A+\n"
        "- **Issue List:** none\n- **Timestamp:** 2026-07-08T12:00:00Z\n",
        encoding="utf-8",
    )
    task_dir = del_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Nested task short name\n\n**Type:** IMPLEMENT\n\nBody.\n",
        encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        "---\nstate: In Progress\n---\n\n## Task State\n", encoding="utf-8",
    )
    return work_dir


def _seed_stop_signal(aid: Path, work_id: str, task_id: str) -> Path:
    control_dir = aid / ".control" / work_id
    control_dir.mkdir(parents=True, exist_ok=True)
    signal = control_dir / f"{task_id}.stop"
    signal.write_text("[2026-01-01T00:00:00Z] stop | source=dashboard\n", encoding="utf-8")
    return signal


def _read_repo_single_work(root: Path, aid: Path):
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        return read_repo(root)


# ---------------------------------------------------------------------------
# (2) Integration: read_repo() end-to-end, both layouts, both signal states
# ---------------------------------------------------------------------------

class TestReadRepoFlatLayoutStopRequested(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_signal_present_yields_true(self):
        _build_flat_work(self.aid, "work-980-flat-stop")
        _seed_stop_signal(self.aid, "work-980-flat-stop", "task-001")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertTrue(task.stop_requested)

    def test_signal_absent_yields_false(self):
        _build_flat_work(self.aid, "work-981-flat-nostop")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertFalse(task.stop_requested)

    def test_never_parsed_from_state_md(self):
        """STATE.md carries no stop-signal syntax at all -- the field is
        derived purely from the control-file stat, never from STATE.md text."""
        work_dir = _build_flat_work(self.aid, "work-982-flat-purederived")
        _seed_stop_signal(self.aid, "work-982-flat-purederived", "task-001")
        state_text_before = (work_dir / "STATE.md").read_text(encoding="utf-8")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertTrue(task.stop_requested)
        state_text_after = (work_dir / "STATE.md").read_text(encoding="utf-8")
        self.assertEqual(state_text_before, state_text_after, "STATE.md must be untouched")


class TestReadRepoHierarchicalLayoutStopRequested(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_signal_present_yields_true(self):
        _build_hierarchical_work(self.aid, "work-983-nested-stop")
        _seed_stop_signal(self.aid, "work-983-nested-stop", "task-001")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertTrue(task.stop_requested)

    def test_signal_absent_yields_false(self):
        _build_hierarchical_work(self.aid, "work-984-nested-nostop")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertFalse(task.stop_requested)


class TestSerializedTaskCarriesStopRequested(unittest.TestCase):
    """The DM serializer (server.py _ser_task) must emit stop_requested beside
    display_name/notes/short_name (AC: reader change applied identically to
    the model AND its serializer)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_ser_task_includes_stop_requested_true(self):
        _build_flat_work(self.aid, "work-985-flat-ser-stop")
        _seed_stop_signal(self.aid, "work-985-flat-ser-stop", "task-001")
        model = _read_repo_single_work(self.root, self.aid)
        from dashboard.server.server import _ser_task
        serialized = _ser_task(model.works[0].tasks[0])
        self.assertIn("stop_requested", serialized)
        self.assertIs(serialized["stop_requested"], True)

    def test_ser_task_includes_stop_requested_false(self):
        _build_flat_work(self.aid, "work-986-flat-ser-nostop")
        model = _read_repo_single_work(self.root, self.aid)
        from dashboard.server.server import _ser_task
        serialized = _ser_task(model.works[0].tasks[0])
        self.assertIn("stop_requested", serialized)
        self.assertIs(serialized["stop_requested"], False)


# ---------------------------------------------------------------------------
# (3) WT-1: control dir derived from the WALKED work_dir, never reconstructed
#     from the served-root argument passed to read_repo()
# ---------------------------------------------------------------------------

class TestWt1ControlDirDerivedFromWalkedWorkDir(unittest.TestCase):
    """Simulates a worktree topology: `enumerate_worktree_roots` is mocked to
    return a REAL worktree tree (`self.real_aid`) that is a SIBLING directory
    of the served-root argument (`self.served_root`) passed to `read_repo()`
    -- never reachable by naively joining served_root + '.aid/...'. Proves the
    control-file stat is derived relative to the walked work_dir (WT-1), not
    a reconstructed <served-root>/.aid/.control/<work_id>/ path."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.served_root, self.served_aid = _make_repo(self.tmp / "served-root")
        self.real_root = self.tmp / "real-worktree"
        self.real_aid = self.real_root / ".aid"
        self.real_aid.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _read_via_real_worktree(self):
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("wt-branch", self.real_aid)],
        ):
            return read_repo(self.served_root)

    def test_signal_under_real_worktree_control_dir_is_detected(self):
        _build_flat_work(self.real_aid, "work-200-wt1")
        _seed_stop_signal(self.real_aid, "work-200-wt1", "task-001")
        # Sanity: the served root has NO .control dir at all.
        self.assertFalse((self.served_aid / ".control").exists())

        model = self._read_via_real_worktree()
        task = model.works[0].tasks[0]
        self.assertTrue(task.stop_requested)

    def test_signal_under_served_root_is_not_detected(self):
        """A signal seeded under the SERVED root's (wrong) tree must have NO
        effect -- proves the reader never reconstructs
        <served-root>/.aid/.control/<work_id>/."""
        _build_flat_work(self.real_aid, "work-201-wt1")
        _seed_stop_signal(self.served_aid, "work-201-wt1", "task-001")  # wrong tree

        model = self._read_via_real_worktree()
        task = model.works[0].tasks[0]
        self.assertFalse(task.stop_requested)


# ---------------------------------------------------------------------------
# (4) Cross-twin parity: Python read_repo() vs Node readRepo() (in-process, bounded)
# ---------------------------------------------------------------------------

def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_task0(root: Path, pinned_home: Path) -> "dict | None":
    """Run reader.mjs's readRepo() in a bounded, in-process (no server, no
    port) subprocess and return works[0].tasks[0] as a plain dict."""
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "const w = (m.works && m.works[0]) || null;\n"
        "const t = (w && w.tasks && w.tasks[0]) || null;\n"
        "process.stdout.write(JSON.stringify(t) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=15,
        env={**os.environ, "HOME": str(pinned_home)},
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return json.loads(result.stdout.strip())


@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParityStopRequested(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)
        self.pinned_home = self.tmp / "pinned-home"
        self.pinned_home.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _py_task0(self):
        model = _read_repo_single_work(self.root, self.aid)
        from dashboard.server.server import _ser_task
        return _ser_task(model.works[0].tasks[0])

    def test_flat_signal_present_parity(self):
        _build_flat_work(self.aid, "work-990-flat-parity-stop")
        _seed_stop_signal(self.aid, "work-990-flat-parity-stop", "task-001")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertTrue(py_t["stop_requested"])

    def test_flat_signal_absent_parity(self):
        _build_flat_work(self.aid, "work-991-flat-parity-nostop")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertFalse(py_t["stop_requested"])

    def test_hierarchical_signal_present_parity(self):
        _build_hierarchical_work(self.aid, "work-992-nested-parity-stop")
        _seed_stop_signal(self.aid, "work-992-nested-parity-stop", "task-001")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertTrue(py_t["stop_requested"])

    def test_hierarchical_signal_absent_parity(self):
        _build_hierarchical_work(self.aid, "work-993-nested-parity-nostop")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertFalse(py_t["stop_requested"])


if __name__ == "__main__":
    unittest.main()
