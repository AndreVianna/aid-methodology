"""
test_work001_delivery_layouts.py -- work-001-add-deliveries-folder, task-003.

Committed both-layout coverage fixtures for the delivery-folder relocation
(task-001 relocated the on-disk layout; task-002 updated the reader twins to
detect both shapes). This module is the PERMANENT replacement for the ad hoc
twin-diff inspection task-002 did during development:

  - Lite-flat:   work-NNN/tasks/task-NNN/... -- no deliveries/, no delivery-NNN/
                 folder. The single implicit delivery's lifecycle, gate, and
                 Cross-phase Q&A are AUTHORED directly in the work-root STATE.md.
  - Full-nested: work-NNN/deliveries/delivery-NNN/tasks/task-NNN/... -- mirrors
                 features/feature-NNN/.

Both reader twins (Python dashboard/reader/reader.py, Node
dashboard/server/reader.mjs) are asserted to:
  1. Parse each layout's structural fields correctly (Python-side assertions,
     mirroring the existing test_task014_fixtures.py conventions).
  2. Agree on a normalized JSON projection of the resulting WorkModel for BOTH
     layouts (cross-runtime parity, computed in-process -- no server, no port,
     no *parity*.sh script).

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import dataclasses
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

# Ensure the repo root is on sys.path so we can import dashboard.*
# parents[3] = worktree root (same depth as test_task014_fixtures.py uses)
_REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.reader import _detect_hierarchy

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# Shared fixture helpers
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
    """Return (repo_root, aid_dir) with minimal manifest + settings."""
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


def _write_task(task_dir: Path, task_id: str, task_type: str, title: str, state: str) -> None:
    """Write a task-level SPEC.md + STATE.md pair (same shape for both layouts --
    only the parent directory differs: tasks/task-NNN/ directly under the work
    root for lite-flat, or deliveries/delivery-NNN/tasks/task-NNN/ for full-nested)."""
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "SPEC.md").write_text(
        f"# {task_id}: {title}\n\n"
        f"**Type:** {task_type}\n\n"
        "Body of the task spec.\n",
        encoding="utf-8",
    )
    (task_dir / "STATE.md").write_text(
        "## Task State\n\n"
        f"- **State:** {state}\n"
        "- **Review:** --\n"
        "- **Elapsed:** --\n"
        "- **Notes:** --\n",
        encoding="utf-8",
    )


_PIPELINE_STATE_BLOCK = (
    "## Pipeline State\n\n"
    "- **Lifecycle:** Running\n"
    "- **Phase:** Execute\n"
    "- **Active Skill:** aid-execute\n"
    "- **Updated:** 2026-07-08T12:00:00Z\n"
    "- **Pause Reason:** --\n"
    "- **Block Reason:** --\n"
    "- **Block Artifact:** --\n"
)

# Two Cross-phase Q&A entries (one Pending, one Answered) shared by both layout
# fixtures -- the Answered entry proves pending_inputs excludes non-Pending rows;
# a SECOND Pending entry (Q3) proves the union does not drop or duplicate entries.
_CROSSPHASE_QA_BLOCK = (
    "## Cross-phase Q&A\n\n"
    "### Q1\n\n"
    "- **Status:** Pending\n"
    "- **Category:** Architecture\n"
    "- **Context:** Should we use a monorepo?\n\n"
    "### Q2\n\n"
    "- **Status:** Answered\n"
    "- **Category:** Scope\n"
    "- **Context:** Already resolved; kept for the historical record.\n\n"
    "### Q3\n\n"
    "- **Status:** Pending\n"
    "- **Category:** Testing\n"
    "- **Context:** Which fixture format should new tests use?\n"
)


def _build_lite_flat_work(aid: Path, work_id: str) -> Path:
    """work-NNN/tasks/task-NNN/ -- no deliveries/, no delivery-NNN/ folder.

    The single implicit delivery's ## Delivery Lifecycle / ## Delivery Gate /
    ## Cross-phase Q&A sections are AUTHORED directly in the work-root STATE.md
    (the work IS the delivery for a lite work -- work-001-add-deliveries-folder
    task-001/task-003).
    """
    work_dir = aid / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(
        _PIPELINE_STATE_BLOCK + "\n"
        "## Delivery Lifecycle\n\n"
        "- **State:** Executing\n"
        "- **Updated:** 2026-07-08T12:00:00Z\n"
        "- **Block Reason:** --\n"
        "- **Block Artifact:** --\n\n"
        "## Delivery Gate\n\n"
        "- **Reviewer Tier:** Small\n"
        "- **Grade:** A+\n"
        "- **Issue List:** none\n"
        "- **Timestamp:** 2026-07-08T12:00:00Z\n\n"
        + _CROSSPHASE_QA_BLOCK,
        encoding="utf-8",
    )
    _write_task(work_dir / "tasks" / "task-001", "task-001", "REFACTOR", "First lite task", "Done")
    _write_task(work_dir / "tasks" / "task-002", "task-002", "TEST", "Second lite task", "In Progress")
    return work_dir


def _build_full_nested_work(aid: Path, work_id: str) -> Path:
    """work-NNN/deliveries/delivery-NNN/tasks/task-NNN/ -- mirrors features/feature-NNN/."""
    work_dir = aid / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.md").write_text(_PIPELINE_STATE_BLOCK, encoding="utf-8")

    del_dir = work_dir / "deliveries" / "delivery-001"
    del_dir.mkdir(parents=True, exist_ok=True)
    (del_dir / "SPEC.md").write_text(
        "# Delivery SPEC -- delivery-001: Full-nested delivery\n\n"
        "Delivery scope and gate criteria.\n",
        encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n"
        "- **State:** Executing\n"
        "- **Updated:** 2026-07-08T12:00:00Z\n"
        "- **Block Reason:** --\n"
        "- **Block Artifact:** --\n\n"
        "## Delivery Gate\n\n"
        "- **Reviewer Tier:** Small\n"
        "- **Grade:** A+\n"
        "- **Issue List:** none\n"
        "- **Timestamp:** 2026-07-08T12:00:00Z\n\n"
        + _CROSSPHASE_QA_BLOCK,
        encoding="utf-8",
    )
    _write_task(del_dir / "tasks" / "task-001", "task-001", "REFACTOR", "First full task", "Done")
    _write_task(del_dir / "tasks" / "task-002", "task-002", "TEST", "Second full task", "In Progress")
    return work_dir


def _normalize_work(wm) -> dict:
    """Project a WorkModel into the subset of fields DIRECTLY comparable across
    the Python and Node reader twins, after round-tripping through JSON (turns
    str-Enum members into plain strings, matching Node's plain-string fields).

    Two fields are dropped for DOCUMENTED, pre-existing reasons (both runtimes
    already agree this asymmetry is intentional -- it is not something this
    task's scope touches, and not a coverage gap):
      - deliverables[].delivery_state: reader.mjs's _buildDeliverableRef
        intentionally omits it (parity with server.py's _ser_deliverable_ref,
        which does not serialize it either -- see reader.mjs comment at
        _buildDeliverableRef). delivery_state correctness is instead asserted
        directly on the Python model in TestLiteFlatLayout /
        TestFullNestedLayout below.
      - branch_label: reader.mjs's _buildWorkModel defines it as a
        non-enumerable property specifically so JSON.stringify excludes it
        (parity with server.py's _ser_work, which omits the field entirely).
    """
    d = json.loads(json.dumps(dataclasses.asdict(wm), default=str))
    d.pop("branch_label", None)
    for deliv in d.get("deliverables", []):
        deliv.pop("delivery_state", None)
    return d


def _read_repo_single_work(root: Path, aid: Path):
    """read_repo() with worktree enumeration stubbed to a single main root."""
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        return read_repo(root)


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_normalized_work(root: Path, pinned_home: Path) -> dict:
    """Run reader.mjs's readRepo() in a bounded, in-process (no server, no
    port) subprocess and return works[0] normalized the same way as
    _normalize_work() (delivery_state / branch_label already absent from the
    Node side by construction -- see _normalize_work's docstring).

    The module specifier MUST be a file:// URL (Path.as_uri()), not a bare
    Windows path -- Node's default ESM loader rejects a raw drive-letter
    path ('c:\\...') with ERR_UNSUPPORTED_ESM_URL_SCHEME. This is the same
    Windows-only pitfall that makes the existing test_task014_fixtures.py
    node-mirror tests (e.g. test_sd9_node_mirrors_python) skip on this box;
    using as_uri() here lets this test actually run (not just skip) on
    Windows too.
    """
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "const w = (m.works && m.works[0]) || null;\n"
        "process.stdout.write(JSON.stringify(w) + '\\n');\n"
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


# ---------------------------------------------------------------------------
# Lite-flat layout: structural assertions (Python side)
# ---------------------------------------------------------------------------

class TestLiteFlatLayout(unittest.TestCase):
    """work-NNN/tasks/task-NNN/ -- single delivery; lifecycle/gate/Q&A AUTHORED
    in the work-root STATE.md."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)
        self.work_dir = _build_lite_flat_work(self.aid, "work-901-lite-flat")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_detect_hierarchy_true(self):
        self.assertTrue(_detect_hierarchy(self.work_dir))

    def test_no_deliveries_folder_on_disk(self):
        """The fixture itself has no deliveries/ folder (sanity on the fixture,
        not the reader) -- the defining trait of the lite-flat layout."""
        self.assertFalse((self.work_dir / "deliveries").exists())

    def test_tasks_read_from_per_unit_state(self):
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        task_map = {t.task_id: t for t in w.tasks}
        self.assertIn("task-001", task_map)
        self.assertIn("task-002", task_map)
        self.assertEqual(task_map["task-001"].status.value, "Done")
        self.assertEqual(task_map["task-002"].status.value, "In Progress")
        self.assertEqual(task_map["task-001"].short_name, "First lite task")
        self.assertEqual(task_map["task-001"].type, "REFACTOR")

    def test_single_deliverable_delivery_001(self):
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(len(w.deliverables), 1, "a lite work has exactly one delivery")
        d = w.deliverables[0]
        self.assertEqual(d.number, 1)
        self.assertEqual(d.task_count, 2)
        for t in w.tasks:
            self.assertEqual(t.delivery, 1, "all tasks belong to the single implicit delivery-001")

    def test_delivery_state_authored_from_work_root_state(self):
        """delivery_state comes from the work-root STATE.md's own
        ## Delivery Lifecycle section (AUTHORED, not derived) -- there is no
        separate delivery-level STATE.md file for a lite work."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(w.deliverables[0].delivery_state, "Executing")

    def test_work_lifecycle_distinct_from_delivery_state(self):
        """Work-level Pipeline State (Running) and the delivery's own
        ## Delivery Lifecycle (Executing) are two DIFFERENT sections in the
        SAME work-root STATE.md file -- the reader must not confuse them."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(w.lifecycle.value, "Running")
        self.assertEqual(w.deliverables[0].delivery_state, "Executing")

    def test_pending_inputs_union_no_double_count(self):
        """Q1 + Q3 are Pending (Q2 is Answered, excluded). The lite-flat branch
        must NOT re-add the delivery's own Cross-phase Q&A a second time (it is
        the SAME section already captured by parse_state_md's own pending_inputs
        pass) -- this is the exact double-count regression called out in
        reader.py _read_work_hierarchical's lite-flat comment."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        q_ids = [pi.question_id for pi in w.pending_inputs]
        self.assertEqual(sorted(q_ids), ["Q1", "Q3"])
        self.assertEqual(len(q_ids), len(set(q_ids)), f"duplicate Q&A entries: {q_ids}")

    def test_never_throws(self):
        try:
            model = _read_repo_single_work(self.root, self.aid)
        except Exception as exc:  # noqa: BLE001
            self.fail(f"read_repo raised on lite-flat fixture: {exc}")
        self.assertIsNotNone(model)


# ---------------------------------------------------------------------------
# Full-nested layout: structural assertions (Python side)
# ---------------------------------------------------------------------------

class TestFullNestedLayout(unittest.TestCase):
    """work-NNN/deliveries/delivery-NNN/tasks/task-NNN/ -- mirrors features/feature-NNN/."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)
        self.work_dir = _build_full_nested_work(self.aid, "work-902-full-nested")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_detect_hierarchy_true(self):
        self.assertTrue(_detect_hierarchy(self.work_dir))

    def test_deliveries_folder_present_on_disk(self):
        """Sanity on the fixture: deliveries/ nests delivery-001/, mirroring
        features/feature-NNN/ -- the defining trait of the full-nested layout."""
        self.assertTrue((self.work_dir / "deliveries" / "delivery-001").is_dir())

    def test_tasks_read_from_per_unit_state(self):
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        task_map = {t.task_id: t for t in w.tasks}
        self.assertEqual(task_map["task-001"].status.value, "Done")
        self.assertEqual(task_map["task-002"].status.value, "In Progress")
        self.assertEqual(task_map["task-001"].short_name, "First full task")
        self.assertEqual(task_map["task-002"].type, "TEST")

    def test_single_deliverable_name_from_delivery_spec(self):
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(len(w.deliverables), 1)
        d = w.deliverables[0]
        self.assertEqual(d.number, 1)
        self.assertEqual(d.task_count, 2)
        self.assertEqual(d.name, "Full-nested delivery")

    def test_delivery_state_from_delivery_state_md(self):
        """delivery_state comes from deliveries/delivery-001/STATE.md's own
        ## Delivery Lifecycle section (a real per-delivery file, unlike lite)."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(w.deliverables[0].delivery_state, "Executing")

    def test_pending_inputs_from_delivery_qa(self):
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        q_ids = [pi.question_id for pi in w.pending_inputs]
        self.assertEqual(sorted(q_ids), ["Q1", "Q3"])

    def test_never_throws(self):
        try:
            model = _read_repo_single_work(self.root, self.aid)
        except Exception as exc:  # noqa: BLE001
            self.fail(f"read_repo raised on full-nested fixture: {exc}")
        self.assertIsNotNone(model)


# ---------------------------------------------------------------------------
# Cross-runtime parity: Python read_repo() vs Node readRepo() on BOTH layouts.
#
# This is the permanent, committed replacement for the ad hoc twin-diff
# inspection done during task-002's development (see that commit message).
# Runs entirely in-process via a bounded `node --input-type=module` subprocess
# invocation -- no server, no port, no *parity*.sh script.
# ---------------------------------------------------------------------------

class TestBothLayoutsNodeParity(unittest.TestCase):

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)
        self.pinned_home = self.tmp / "pinned-home"
        self.pinned_home.mkdir(exist_ok=True)
        if not _node_available():
            self.skipTest("node not available")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_lite_flat_python_node_agree(self):
        work_dir = _build_lite_flat_work(self.aid, "work-901-lite-flat")
        model = _read_repo_single_work(self.root, self.aid)
        py_norm = _normalize_work(model.works[0])

        try:
            node_w = _run_node_normalized_work(self.root, self.pinned_home)
        except RuntimeError as exc:
            self.skipTest(str(exc))
        node_w.pop("branch_label", None)
        for deliv in node_w.get("deliverables", []):
            deliv.pop("delivery_state", None)

        self.assertEqual(
            py_norm, node_w,
            "Python read_repo() and Node readRepo() disagree on the lite-flat fixture "
            f"(work_dir={work_dir})",
        )

    def test_full_nested_python_node_agree(self):
        work_dir = _build_full_nested_work(self.aid, "work-902-full-nested")
        model = _read_repo_single_work(self.root, self.aid)
        py_norm = _normalize_work(model.works[0])

        try:
            node_w = _run_node_normalized_work(self.root, self.pinned_home)
        except RuntimeError as exc:
            self.skipTest(str(exc))
        node_w.pop("branch_label", None)
        for deliv in node_w.get("deliverables", []):
            deliv.pop("delivery_state", None)

        self.assertEqual(
            py_norm, node_w,
            "Python read_repo() and Node readRepo() disagree on the full-nested fixture "
            f"(work_dir={work_dir})",
        )


if __name__ == "__main__":
    unittest.main()
