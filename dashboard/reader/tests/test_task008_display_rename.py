"""
test_task008_display_rename.py -- work-017-cli-improvements,
feature-005-display-rename, delivery-001 task-008.

Covers the reader-twin half of task-008 (TaskModel.display_name):
  - ParsedTaskState.display_name defaults to None; parse_task_state_md reads it
    ONLY from frontmatter (no legacy prose bullet form exists for this NEW
    field -- unlike state/review/elapsed/notes, which also have a body-scan
    fallback).
  - parse_tasks_lifecycle_md reads the trailing Name column (col 5); a legacy
    5-column row (no Name column authored yet) yields display_name None.
  - read_repo() end-to-end for BOTH the flat (### Tasks lifecycle Name column)
    and hierarchical (per-task STATE.md frontmatter display_name key) layouts,
    including the serialized DM shape (_ser_task/_ser_work) carrying the field.
  - Cross-twin parity (Python read_repo() vs Node readRepo(), computed
    in-process via a bounded subprocess -- no server, no port, no *parity*.sh
    script) for both layouts, including the legacy-5-column fallback shape.

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
from dashboard.reader.parsers import (
    ParsedTaskState,
    parse_task_state_md,
    parse_tasks_lifecycle_md,
)

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# Unit tests: ParsedTaskState.display_name default
# ---------------------------------------------------------------------------

class TestParsedTaskStateDisplayName(unittest.TestCase):
    def test_default_is_none(self):
        pts = ParsedTaskState()
        self.assertIsNone(pts.display_name)


# ---------------------------------------------------------------------------
# Unit tests: parse_task_state_md (nested/full layout frontmatter)
# ---------------------------------------------------------------------------

class TestParseTaskStateMdDisplayName(unittest.TestCase):
    def test_frontmatter_display_name_read(self):
        text = (
            "---\nstate: Done\ndisplay_name: Wire up the rename dispatch\n---\n\n"
            "## Task State\n"
        )
        pts = parse_task_state_md(text, task_id="task-001")
        self.assertEqual(pts.display_name, "Wire up the rename dispatch")

    def test_no_frontmatter_key_is_none(self):
        text = "---\nstate: Done\n---\n\n## Task State\n"
        pts = parse_task_state_md(text, task_id="task-002")
        self.assertIsNone(pts.display_name)

    def test_null_sentinel_values_are_none(self):
        for sentinel in ("--", "-"):
            with self.subTest(sentinel=sentinel):
                text = (
                    f"---\nstate: Done\ndisplay_name: '{sentinel}'\n---\n\n"
                    "## Task State\n"
                )
                pts = parse_task_state_md(text, task_id="task-003")
                self.assertIsNone(pts.display_name)

    def test_legacy_prose_only_file_has_no_display_name(self):
        """display_name has NO legacy prose bullet form -- a pre-migration file
        (no frontmatter at all) always yields None, never an AttributeError."""
        text = "## Task State\n\n- **State:** In Progress\n"
        pts = parse_task_state_md(text, task_id="task-004")
        self.assertIsNone(pts.display_name)

    def test_other_fields_unaffected(self):
        """Adding display_name must not disturb the existing state/review/
        elapsed/notes frontmatter reads (regression guard)."""
        text = (
            "---\nstate: Done\nreview: A+ (Large)\nelapsed: '02:30'\nnotes: shipped\n"
            "display_name: Renamed task\n---\n\n## Task State\n"
        )
        pts = parse_task_state_md(text, task_id="task-005")
        self.assertEqual(pts.state.value, "Done")
        self.assertEqual(pts.review, "A+ (Large)")
        self.assertEqual(pts.elapsed, "02:30")
        self.assertEqual(pts.notes, "shipped")
        self.assertEqual(pts.display_name, "Renamed task")


# ---------------------------------------------------------------------------
# Unit tests: parse_tasks_lifecycle_md (flat/Lite layout Name column)
# ---------------------------------------------------------------------------

class TestParseTasksLifecycleMdName(unittest.TestCase):
    def test_six_column_row_reads_name(self):
        text = (
            "### Tasks lifecycle\n\n"
            "| Task | State | Review | Elapsed | Notes | Name |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| task-001 | Done | -- | -- | -- | Wire up the rename dispatch |\n"
        )
        result, warnings = parse_tasks_lifecycle_md(text)
        self.assertEqual(warnings, [])
        self.assertEqual(result["task-001"].display_name, "Wire up the rename dispatch")

    def test_legacy_five_column_row_yields_none(self):
        """A pre-feature-005 table (no Name column at all) must not warn or
        throw -- _col(5) is simply out of range -> None (AC backward-compat)."""
        text = (
            "### Tasks lifecycle\n\n"
            "| Task | State | Review | Elapsed | Notes |\n"
            "| --- | --- | --- | --- | --- |\n"
            "| task-001 | Done | -- | -- | -- |\n"
        )
        result, warnings = parse_tasks_lifecycle_md(text)
        self.assertEqual(warnings, [])
        self.assertIsNone(result["task-001"].display_name)

    def test_null_sentinel_cell_yields_none(self):
        text = (
            "### Tasks lifecycle\n\n"
            "| Task | State | Review | Elapsed | Notes | Name |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| task-001 | Done | -- | -- | -- | -- |\n"
        )
        result, _ = parse_tasks_lifecycle_md(text)
        self.assertIsNone(result["task-001"].display_name)

    def test_other_columns_unaffected(self):
        text = (
            "### Tasks lifecycle\n\n"
            "| Task | State | Review | Elapsed | Notes | Name |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| task-001 | In Progress | A+ | 01:15 | partial | Custom label |\n"
        )
        result, _ = parse_tasks_lifecycle_md(text)
        pts = result["task-001"]
        self.assertEqual(pts.state.value, "In Progress")
        self.assertEqual(pts.review, "A+")
        self.assertEqual(pts.elapsed, "01:15")
        self.assertEqual(pts.notes, "partial")
        self.assertEqual(pts.display_name, "Custom label")


# ---------------------------------------------------------------------------
# Integration: read_repo() end-to-end, both layouts
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


def _build_flat_work(aid: Path, work_id: str, name_column: bool, name_value: str = "--") -> Path:
    """Lite-flat layout (BLUEPRINT.md + tasks/task-NNN/DETAIL.md, no deliveries/).
    name_column=False writes the LEGACY 5-column table (no Name column at all);
    name_column=True writes the 6-column table with name_value in the Name cell.
    """
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Flat delivery\n\n"
        "## Objective\n\nDeliver.\n\n## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    if name_column:
        table = (
            "| Task | State | Review | Elapsed | Notes | Name |\n"
            "|------|-------|--------|---------|-------|------|\n"
            f"| task-001 | Done | -- | -- | -- | {name_value} |\n"
        )
    else:
        table = (
            "| Task | State | Review | Elapsed | Notes |\n"
            "|------|-------|--------|---------|-------|\n"
            "| task-001 | Done | -- | -- | -- |\n"
        )
    (work_dir / "STATE.md").write_text(
        "## Pipeline State\n\n- **Lifecycle:** Running\n\n"
        "## Delivery Lifecycle\n\n- **State:** Executing\n\n"
        "### Tasks lifecycle\n\n" + table,
        encoding="utf-8",
    )
    task_dir = work_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Flat task short name\n\n**Type:** IMPLEMENT\n\nBody.\n",
        encoding="utf-8",
    )
    return work_dir


def _build_hierarchical_work(aid: Path, work_id: str, display_name: "str | None") -> Path:
    """Full-nested layout (deliveries/delivery-NNN/tasks/task-NNN/{DETAIL,STATE}.md).
    display_name=None omits the frontmatter key entirely (pre-feature-005 file);
    otherwise writes it as a flat frontmatter scalar in the per-task STATE.md.
    """
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
    fm = "---\nstate: Done\n"
    if display_name is not None:
        fm += f"display_name: {display_name}\n"
    fm += "---\n\n## Task State\n"
    (task_dir / "STATE.md").write_text(fm, encoding="utf-8")
    return work_dir


def _read_repo_single_work(root: Path, aid: Path):
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        return read_repo(root)


class TestReadRepoFlatLayoutDisplayName(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_name_column_value_flows_to_task_model(self):
        _build_flat_work(self.aid, "work-980-flat", name_column=True, name_value="Renamed flat task")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertEqual(task.display_name, "Renamed flat task")
        self.assertEqual(task.short_name, "Flat task short name", "short_name still read independently")

    def test_legacy_five_column_table_yields_none(self):
        _build_flat_work(self.aid, "work-981-flat-legacy", name_column=False)
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertIsNone(task.display_name)

    def test_null_sentinel_cell_yields_none(self):
        _build_flat_work(self.aid, "work-982-flat-null", name_column=True, name_value="--")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertIsNone(task.display_name)


class TestReadRepoHierarchicalLayoutDisplayName(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_frontmatter_display_name_flows_to_task_model(self):
        _build_hierarchical_work(self.aid, "work-983-nested", display_name="Renamed nested task")
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertEqual(task.display_name, "Renamed nested task")
        self.assertEqual(task.short_name, "Nested task short name")

    def test_absent_frontmatter_key_yields_none(self):
        _build_hierarchical_work(self.aid, "work-984-nested-legacy", display_name=None)
        model = _read_repo_single_work(self.root, self.aid)
        task = model.works[0].tasks[0]
        self.assertIsNone(task.display_name)


class TestSerializedTaskCarriesDisplayName(unittest.TestCase):
    """The DM serializer (server.py _ser_task) must emit display_name beside
    notes/short_name (AC: reader change is applied identically to the
    parser/model AND its serializer)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_ser_task_includes_display_name(self):
        _build_flat_work(self.aid, "work-985-flat-ser", name_column=True, name_value="Serialized name")
        model = _read_repo_single_work(self.root, self.aid)
        from dashboard.server.server import _ser_task
        serialized = _ser_task(model.works[0].tasks[0])
        self.assertIn("display_name", serialized)
        self.assertEqual(serialized["display_name"], "Serialized name")


# ---------------------------------------------------------------------------
# Cross-twin parity: Python read_repo() vs Node readRepo() (in-process, bounded)
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
class TestCrossTwinParityDisplayName(unittest.TestCase):
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

    def test_flat_name_column_parity(self):
        _build_flat_work(self.aid, "work-990-flat-parity", name_column=True, name_value="Parity flat name")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertEqual(py_t["display_name"], "Parity flat name")

    def test_flat_legacy_five_column_parity(self):
        _build_flat_work(self.aid, "work-991-flat-legacy-parity", name_column=False)
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertIsNone(py_t["display_name"])

    def test_hierarchical_frontmatter_parity(self):
        _build_hierarchical_work(self.aid, "work-992-nested-parity", display_name="Parity nested name")
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertEqual(py_t["display_name"], "Parity nested name")

    def test_hierarchical_absent_key_parity(self):
        _build_hierarchical_work(self.aid, "work-993-nested-legacy-parity", display_name=None)
        py_t = self._py_task0()
        node_t = _run_node_task0(self.root, self.pinned_home)
        self.assertEqual(py_t, node_t)
        self.assertIsNone(py_t["display_name"])


if __name__ == "__main__":
    unittest.main()
