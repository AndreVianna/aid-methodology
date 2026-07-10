"""
test_flattened_layout_parity.py -- feature-001 flattened single-delivery layout.

Covers task-005 (work-001-lite-aid-skills, delivery-001): a shortcut-generated
Lite work with NO `features/` folder and NO `deliveries/`/`delivery-NNN/`
wrapper -- REQUIREMENTS.md + SPEC.md + PLAN.md + work-root BLUEPRINT.md +
`tasks/task-NNN/DETAIL.md` (no per-task STATE.md) + a work-root STATE.md
carrying the three feature-001-promoted AUTHORED blocks:
  - `## Delivery Lifecycle` (+ nested `### Tasks lifecycle` table)
  - `## Delivery Gate`

Asserts:
  1. `_detect_flat` (reader.py) returns True for this layout.
  2. `read_repo` (Python) resolves tasks from DETAIL.md + the `### Tasks
     lifecycle` cells, synthesizes ONE `delivery-001` DeliverableRef
     (wave="delivery-001", delivery=1), and parses `## Delivery Lifecycle` /
     `## Delivery Gate` from the work-root STATE.md.
  3. `reader.py` and `reader.mjs` (Node twin) read the SAME fixture
     identically (AC-8 parity).

Per A-10 (clean switch): only the two amended layouts are exercised anywhere
in this repo's fixtures -- flat (here) and full `deliveries/...` (feature-015,
covered by test_task014_fixtures.py's TestHierarchicalWork). No old-nested
(`delivery-NNN/SPEC.md`) or mixed-vintage fixture is added here.

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

# Ensure the repo root is on sys.path so we can import dashboard.*
_REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.models import SourceMode, TaskStatus


# ---------------------------------------------------------------------------
# Fixture helpers (self-contained -- mirrors test_task014_fixtures.py's style)
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> tuple[Path, Path]:
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


def _build_flat_work(
    aid: Path,
    work_id: str,
    tasks: list[dict],  # [{id, type, title, state, review, elapsed, notes}, ...]
    delivery_state: str = "Executing",
    gate_grade: str = "A",
    work_lifecycle: str = "Running",
    work_updated: str = "2026-07-08T12:00:00Z",
) -> Path:
    """Build a complete FLATTENED (feature-001) work fixture under aid/.

    Layout produced:
      work_dir/REQUIREMENTS.md
      work_dir/SPEC.md
      work_dir/PLAN.md
      work_dir/BLUEPRINT.md
      work_dir/STATE.md            (Pipeline State + Delivery Lifecycle/Gate + Tasks lifecycle)
      work_dir/tasks/task-NNN/DETAIL.md   (NO per-task STATE.md)

    No features/ folder, no deliveries/ wrapper -- A-10 clean switch.
    Returns the work_dir path.
    """
    work_dir = aid / work_id
    work_dir.mkdir(parents=True, exist_ok=True)

    (work_dir / "REQUIREMENTS.md").write_text(
        "# Requirements -- Flattened Test Work\n\n"
        "- **Name:** Flattened Test Work\n"
        "- **Description:** A shortcut-generated Lite work exercising the flat layout.\n\n"
        "## 1. Objective\n\n"
        "Prove the flattened single-delivery layout renders end to end.\n\n"
        "## 2. Problem Statement\n\n"
        "N/A (fixture).\n",
        encoding="utf-8",
    )

    (work_dir / "SPEC.md").write_text(
        "# Flattened Test Feature\n\n"
        "## Description\n\n"
        "The single feature spec for this flattened work (no features/ folder).\n",
        encoding="utf-8",
    )

    (work_dir / "PLAN.md").write_text(
        "# Plan -- Flattened Test Work\n\n"
        "## Deliverables\n\n"
        "- **Delivery:** delivery-001 -- Flat delivery\n"
        "- **What it delivers:** the flattened layout\n"
        "- **Features:** feature-001-flattened-test\n"
        "- **Depends on:** -- (none -- single delivery)\n"
        "- **Priority:** Must\n\n"
        "## Execution Graph\n\n"
        "### Task Dependencies\n\n"
        "| Task | Depends On |\n"
        "|------|------------|\n"
        "| task-001 | -- (none) |\n\n"
        "### Can Be Done In Parallel\n\n"
        "| Wave | Tasks |\n"
        "|------|-------|\n"
        "| 1 | task-001 |\n",
        encoding="utf-8",
    )

    (work_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Flat Delivery Title\n\n"
        "## Objective\n\nDeliver the flat layout.\n\n"
        "## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )

    # tasks/task-NNN/DETAIL.md -- NO per-task STATE.md in this layout
    tasks_dir = work_dir / "tasks"
    for task in tasks:
        tid = task["id"]
        task_dir = tasks_dir / tid
        task_dir.mkdir(parents=True, exist_ok=True)
        (task_dir / "DETAIL.md").write_text(
            f"# {tid}: {task.get('title', f'{tid} title')}\n\n"
            f"**Type:** {task.get('type', 'IMPLEMENT')}\n\n"
            f"**Source:** {work_id} -> delivery-001\n\n"
            "**Depends on:** --\n\n"
            "**Scope:**\n- fixture scope\n\n"
            "**Acceptance Criteria:**\n- [ ] x\n",
            encoding="utf-8",
        )

    # work-root STATE.md: Pipeline State + the 3 promoted feature-001 blocks
    lifecycle_rows = "\n".join(
        f"| {t['id']} | {t.get('state', 'Pending')} | {t.get('review', '--')} | "
        f"{t.get('elapsed', '--')} | {t.get('notes', '--')} |"
        for t in tasks
    )
    if not lifecycle_rows:
        lifecycle_rows = "| _none yet_ | | | | |"

    state_text = f"""# Work State -- {work_id}

## Pipeline State

- **Lifecycle:** {work_lifecycle}
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** {work_updated}
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Lifecycle

- **State:** {delivery_state}
- **Updated:** {work_updated}
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
{lifecycle_rows}

## Delivery Gate

- **Reviewer Tier:** Small
- **Grade:** {gate_grade}
- **Issue List:** none
- **Timestamp:** {work_updated}

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
"""
    (work_dir / "STATE.md").write_text(state_text, encoding="utf-8")

    return work_dir


# ---------------------------------------------------------------------------
# Scenario: Flattened single-delivery work (feature-001)
# ---------------------------------------------------------------------------

class TestFlattenedLayout(unittest.TestCase):
    """Flattened single-delivery work (no features/, no deliveries/ wrapper).

    Asserts:
    - `_detect_flat` returns True; `_detect_hierarchy` returns False
    - Tasks resolved from DETAIL.md (type/short_name) + ### Tasks lifecycle
      cells (state/review/elapsed/notes)
    - ONE synthesized DeliverableRef for delivery-001 (wave/delivery=1)
    - ## Delivery Lifecycle / ## Delivery Gate parsed from work-root STATE.md
    - Identity fields (title/description) resolved from REQUIREMENTS.md
    - source_mode normalized; read_repo never throws
    """

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _build_fixture(self):
        return _build_flat_work(
            self.aid,
            work_id="work-001-flat-test",
            tasks=[
                {"id": "task-001", "type": "IMPLEMENT", "title": "First flat task",
                 "state": "Done", "review": "A", "elapsed": "1h", "notes": "--"},
                {"id": "task-002", "type": "TEST", "title": "Second flat task",
                 "state": "In Progress", "review": "--", "elapsed": "--", "notes": "--"},
            ],
            delivery_state="Executing",
            gate_grade="Pending",
        )

    def test_detect_flat_true(self):
        """_detect_flat returns True for the flattened layout."""
        from dashboard.reader.reader import _detect_flat, _detect_hierarchy
        work_dir = self._build_fixture()
        self.assertTrue(_detect_flat(work_dir))
        self.assertFalse(_detect_hierarchy(work_dir),
                          "flat and hierarchical detection must be mutually exclusive")

    def test_no_deliveries_or_features_folder(self):
        """A-10 / AC-2: no deliveries/ wrapper, no features/ folder on disk."""
        work_dir = self._build_fixture()
        self.assertFalse((work_dir / "deliveries").exists())
        self.assertFalse((work_dir / "features").exists())
        self.assertTrue((work_dir / "BLUEPRINT.md").is_file())
        self.assertTrue((work_dir / "tasks" / "task-001" / "DETAIL.md").is_file())
        self.assertFalse((work_dir / "tasks" / "task-001" / "STATE.md").exists(),
                          "flat layout has NO per-task STATE.md")

    def test_tasks_resolved_from_detail_and_tasks_lifecycle(self):
        """Tasks resolved from DETAIL.md (type/short_name) + ### Tasks lifecycle cells."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        self.assertEqual(len(model.works), 1)
        w = model.works[0]
        task_map = {t.task_id: t for t in w.tasks}

        self.assertIn("task-001", task_map)
        self.assertIn("task-002", task_map)

        self.assertEqual(task_map["task-001"].type, "IMPLEMENT")
        self.assertEqual(task_map["task-001"].short_name, "First flat task")
        self.assertEqual(task_map["task-001"].status, TaskStatus.Done)
        self.assertEqual(task_map["task-001"].review_grade, "A")
        self.assertEqual(task_map["task-001"].elapsed, "1h")

        self.assertEqual(task_map["task-002"].type, "TEST")
        self.assertEqual(task_map["task-002"].short_name, "Second flat task")
        self.assertEqual(task_map["task-002"].status, TaskStatus.InProgress)

    def test_delivery_001_synthesized(self):
        """Every task gets wave='delivery-001' and delivery=1 (synthesized)."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        for t in w.tasks:
            self.assertEqual(t.wave, "delivery-001")
            self.assertEqual(t.delivery, 1)

    def test_one_deliverable_ref_synthesized(self):
        """Exactly ONE DeliverableRef (number=1) is synthesized -- no deliveries/ to enumerate."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        self.assertEqual(len(w.deliverables), 1)
        d = w.deliverables[0]
        self.assertEqual(d.number, 1)
        self.assertEqual(d.task_count, 2)
        self.assertEqual(d.delivery_state, "Executing")
        self.assertEqual(d.name, "Flat Delivery Title")

    def test_work_path_defaults_to_lite(self):
        """FIX 1: a shortcut-produced flat work never authors a `## Triage ->
        **Path:**` field (there is no Triage section in this fixture at all),
        so `_read_work_flat` defaults `work_path` to 'lite' -- a flat work IS
        a Lite work by construction. Without the default, home.html mislabels
        the work "[Identifying path]", wraps its tasks in a redundant
        "Delivery #1" panel, and omits the Lite badge."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        self.assertEqual(w.work_path, "lite")

    def test_delivery_lifecycle_and_gate_from_work_root_state(self):
        """## Delivery Lifecycle / ## Delivery Gate are parsed from the work-root STATE.md."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        # delivery_state on the synthesized DeliverableRef comes from
        # ## Delivery Lifecycle (parse_delivery_state_md), not a per-delivery file.
        self.assertEqual(w.deliverables[0].delivery_state, "Executing")

    def test_identity_fields_from_requirements_md(self):
        """title/description resolved from REQUIREMENTS.md (unchanged fallback chain)."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        self.assertEqual(w.title, "Flattened Test Work")
        self.assertEqual(
            w.description,
            "A shortcut-generated Lite work exercising the flat layout.",
        )

    def test_source_mode_normalized(self):
        """Flat work with a typed ## Pipeline State block -> source_mode=normalized."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)

        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_never_throws(self):
        """read_repo on a flat fixture never throws."""
        self._build_fixture()
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            try:
                model = read_repo(self.root)
            except Exception as exc:  # noqa: BLE001
                self.fail(f"read_repo raised on flat fixture: {exc}")
        self.assertIsNotNone(model)

    # NOTE: a zero-task flat delivery (BLUEPRINT.md present, no tasks/task-NNN/
    # DETAIL.md yet) is intentionally NOT exercised here. Per the feature-001
    # detection rule (no `deliveries/` wrapper AND `tasks/task-NNN/DETAIL.md`
    # present), the flat layout is shortcut-generated in one shot (REQUIREMENTS
    # + SPEC + PLAN + BLUEPRINT + tasks together), unlike the full path's staged
    # aid-plan -> aid-specify -> aid-detail flow where an SD-9-style zero-task
    # intermediate state is a defined scenario (see test_task014_fixtures.py
    # TestSD9SpikeScenario). A zero-task flat work is out of this task's scope.

    # -----------------------------------------------------------------------
    # AC-8 / task-005: reader.py and reader.mjs read the fixture identically
    # -----------------------------------------------------------------------

    def test_node_mirrors_python(self):
        """reader.mjs reads the flat fixture identically to reader.py (parity)."""
        try:
            subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            self.skipTest("node not available")

        self._build_fixture()
        reader_mjs = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
        # Use a file:// URI (not a raw path string) -- on Windows a raw
        # "C:\..." string is mis-parsed by Node's ESM loader as a URL with
        # scheme "c:", raising ERR_UNSUPPORTED_ESM_URL_SCHEME.
        script = (
            f"import {{ readRepo }} from {repr(reader_mjs.as_uri())};\n"
            f"const m = readRepo({repr(str(self.root))});\n"
            "const w = m.works && m.works[0];\n"
            "const tasks = w ? w.tasks : [];\n"
            "const deliverables = w ? w.deliverables : [];\n"
            "const result = {\n"
            "  work_count: m.works ? m.works.length : 0,\n"
            "  task_count: tasks.length,\n"
            "  task_states: Object.fromEntries(tasks.map(t => [t.taskId || t.task_id, t.status])),\n"
            "  task_types: Object.fromEntries(tasks.map(t => [t.taskId || t.task_id, t.type])),\n"
            "  task_waves: Object.fromEntries(tasks.map(t => [t.taskId || t.task_id, t.wave])),\n"
            "  task_deliveries: Object.fromEntries(tasks.map(t => [t.taskId || t.task_id, t.delivery])),\n"
            "  deliverable_count: deliverables.length,\n"
            "  deliverable_numbers: deliverables.map(d => d.number),\n"
            "  deliverable_task_counts: deliverables.map(d => d.taskCount || d.task_count),\n"
            "  lifecycle: w ? w.lifecycle : null,\n"
            "  title: w ? w.title : null,\n"
            "  description: w ? w.description : null,\n"
            "  source_mode: w ? (w.sourceMode || w.source_mode) : null,\n"
            "  work_path: w ? w.work_path : null,\n"
            "};\n"
            "process.stdout.write(JSON.stringify(result) + '\\n');\n"
        )
        pinned_home = self.tmp / "pinned-home"
        pinned_home.mkdir(exist_ok=True)
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=script,
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "HOME": str(pinned_home)},
        )
        if result.returncode != 0:
            self.fail(f"Node script error: {result.stderr[:2000]}")
        node_data = json.loads(result.stdout.strip())

        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            py_model = read_repo(self.root)
        py_w = py_model.works[0]

        self.assertEqual(node_data["work_count"], 1, "Node: exactly 1 work")
        self.assertEqual(node_data["task_count"], len(py_w.tasks),
                          "Node/Python task_count parity")
        self.assertEqual(node_data["deliverable_count"], 1, "Node: exactly 1 deliverable")
        self.assertEqual(node_data["deliverable_numbers"], [1], "Node: delivery-001 synthesized")
        self.assertEqual(node_data["deliverable_task_counts"], [len(py_w.tasks)],
                          "Node/Python deliverable task_count parity")

        py_task_states = {t.task_id: t.status.value for t in py_w.tasks}
        self.assertEqual(node_data["task_states"], py_task_states,
                          "Node/Python per-task State parity")

        py_task_types = {t.task_id: t.type for t in py_w.tasks}
        self.assertEqual(node_data["task_types"], py_task_types,
                          "Node/Python per-task Type parity")

        py_task_waves = {t.task_id: t.wave for t in py_w.tasks}
        self.assertEqual(node_data["task_waves"], py_task_waves,
                          "Node/Python per-task wave parity (both 'delivery-001')")

        py_task_deliveries = {t.task_id: t.delivery for t in py_w.tasks}
        self.assertEqual(node_data["task_deliveries"], py_task_deliveries,
                          "Node/Python per-task delivery parity (both 1)")

        self.assertEqual(node_data["lifecycle"], py_w.lifecycle.value,
                          "Node/Python work lifecycle parity")
        self.assertEqual(node_data["title"], py_w.title, "Node/Python title parity")
        self.assertEqual(node_data["description"], py_w.description,
                          "Node/Python description parity")
        self.assertEqual(node_data["source_mode"], py_w.source_mode.value,
                          "Node/Python source_mode parity")

        # FIX 1: both twins default a flat work's work_path to 'lite' when no
        # `## Triage -> **Path:**` field was authored (shortcut-produced works
        # never author one -- a flat work IS a Lite work by construction).
        self.assertEqual(node_data["work_path"], py_w.work_path,
                          "Node/Python work_path parity")
        self.assertEqual(py_w.work_path, "lite", "flat work defaults work_path to 'lite'")


if __name__ == "__main__":
    unittest.main()
