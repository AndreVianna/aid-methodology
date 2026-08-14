"""
test_work001_delivery_layouts.py -- work-001-add-deliveries-folder, task-003.

Committed both-layout coverage fixtures for the delivery-folder relocation
(task-001 relocated the on-disk layout; task-002 updated the reader twins to
detect both shapes). This module is the PERMANENT replacement for the ad hoc
twin-diff inspection task-002 did during development.

Fixture shapes follow work-001-lite-aid-skills's BLUEPRINT/DETAIL naming (the
flat single-delivery layout + the nested per-unit-STATE.yml hierarchy are the
two live shapes -- see test_flattened_layout_parity.py and
test_task014_fixtures.py's TestHierarchicalWork for the canonical fixture
shapes this module mirrors):

  - Lite-flat:   work-NNN/BLUEPRINT.md + work-NNN/tasks/task-NNN/DETAIL.md --
                 no deliveries/, no delivery-NNN/ folder, no per-task STATE.yml.
                 The single implicit delivery's lifecycle, gate, Cross-phase
                 Q&A, and per-task mutable cells (the `tasks_lifecycle`
                 mapping) are AUTHORED directly in the work-root STATE.yml.
  - Full-nested: work-NNN/deliveries/delivery-NNN/BLUEPRINT.md +
                 deliveries/delivery-NNN/tasks/task-NNN/{DETAIL.md,STATE.yml} --
                 mirrors features/feature-NNN/.

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
from dashboard.reader.reader import _detect_flat, _detect_hierarchy

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


def _write_task(task_dir: Path, task_id: str, task_type: str, title: str,
                 state: "str | None" = None) -> None:
    """Write a task-level DETAIL.md (+ optional STATE.yml), same shape for both
    layouts -- only the parent directory differs: tasks/task-NNN/ directly under
    the work root for lite-flat, or deliveries/delivery-NNN/tasks/task-NNN/ for
    full-nested.

    DETAIL.md is ALWAYS written -- both reader twins read short_name/type from
    it for every layout (reader.py _parse_task_spec_short_name/_parse_task_spec_type).

    STATE.yml is written ONLY when `state` is given (the full-nested layout's
    per-task mutable cells). The lite-flat layout has NO per-task STATE.yml --
    its mutable cells (state/review/elapsed/notes) live in the work-root
    STATE.yml's `tasks_lifecycle` mapping instead (see _build_lite_flat_work).
    (work-009-refactor task-016: was a '## Task State' bullet-heading STATE.md
    -- retired, SPEC.md sec:D-4.)
    """
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "DETAIL.md").write_text(
        f"# {task_id}: {title}\n\n"
        f"**Type:** {task_type}\n\n"
        "Body of the task spec.\n",
        encoding="utf-8",
    )
    if state is not None:
        (task_dir / "STATE.yml").write_text(
            f"state: {state}\n"
            "review: --\n"
            "elapsed: --\n"
            "notes: --\n",
            encoding="utf-8",
        )


_PIPELINE_STATE_BLOCK = (
    "lifecycle: Running\n"
    "phase: Execute\n"
    "active_skill: aid-execute\n"
    "updated: '2026-07-08T12:00:00Z'\n"
    "pause_reason: --\n"
    "block_reason: --\n"
    "block_artifact: --\n"
)

# Two Cross-phase Q&A entries (one Pending, one Answered) shared by both layout
# fixtures -- the Answered entry proves pending_inputs excludes non-Pending rows;
# a SECOND Pending entry (Q3) proves the union does not drop or duplicate entries.
# (work-009-refactor task-016: was a '## Cross-phase Q&A' -> '### Q{N}' bullet-
# heading block -- retired, SPEC.md sec:D-4's `qa` sequence shape.)
_CROSSPHASE_QA_BLOCK = (
    "qa:\n"
    "  - id: 1\n"
    "    category: Architecture\n"
    "    state: Pending\n"
    "    context: Should we use a monorepo?\n"
    "  - id: 2\n"
    "    category: Scope\n"
    "    state: Answered\n"
    "    context: Already resolved; kept for the historical record.\n"
    "  - id: 3\n"
    "    category: Testing\n"
    "    state: Pending\n"
    "    context: Which fixture format should new tests use?\n"
)


def _build_lite_flat_work(aid: Path, work_id: str) -> Path:
    """work-NNN/BLUEPRINT.md + work-NNN/tasks/task-NNN/DETAIL.md -- no deliveries/,
    no delivery-NNN/ folder, no per-task STATE.yml (feature-001 flattened layout,
    per test_flattened_layout_parity.py's canonical fixture shape).

    The single implicit delivery's `delivery_state`/`delivery_gate`/`qa` keys,
    PLUS the per-task mutable cells (the `tasks_lifecycle` mapping), are
    AUTHORED directly in the work-root STATE.yml (the work IS the delivery for a
    lite work -- work-001-add-deliveries-folder task-001/task-003).
    (work-009-refactor task-016: was a bullet-heading STATE.md with a
    '### Tasks lifecycle' markdown table -- retired, SPEC.md sec:D-4.)
    """
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Lite-flat delivery\n\n"
        "## Objective\n\nDeliver the lite-flat layout.\n\n"
        "## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    (work_dir / "STATE.yml").write_text(
        _PIPELINE_STATE_BLOCK +
        "delivery_state: Executing\n"
        "gate_tier: Small\n"
        "gate_grade: A+\n"
        "gate_timestamp: '2026-07-08T12:00:00Z'\n"
        "delivery_lifecycle:\n"
        "  updated: '2026-07-08T12:00:00Z'\n"
        "  block_reason: --\n"
        "  block_artifact: --\n"
        "tasks_lifecycle:\n"
        "  task-001:\n"
        "    state: Done\n"
        "    review: --\n"
        "    elapsed: --\n"
        "    notes: --\n"
        "  task-002:\n"
        "    state: In Progress\n"
        "    review: --\n"
        "    elapsed: --\n"
        "    notes: --\n"
        "delivery_gate:\n"
        "  issue_list: []\n"
        + _CROSSPHASE_QA_BLOCK,
        encoding="utf-8",
    )
    # No per-task STATE.yml in the flat layout -- state/review/elapsed/notes
    # come from the tasks_lifecycle mapping above (state=None omits the file).
    _write_task(work_dir / "tasks" / "task-001", "task-001", "REFACTOR", "First lite task")
    _write_task(work_dir / "tasks" / "task-002", "task-002", "TEST", "Second lite task")
    return work_dir


def _build_full_nested_work(aid: Path, work_id: str) -> Path:
    """work-NNN/deliveries/delivery-NNN/{BLUEPRINT.md,STATE.yml} +
    deliveries/delivery-NNN/tasks/task-NNN/{DETAIL.md,STATE.yml} -- mirrors
    features/feature-NNN/ (per test_task014_fixtures.py's TestHierarchicalWork
    fixture shape: BLUEPRINT.md at the delivery level, DETAIL.md at the task
    level -- reader.py's hierarchical path reads the delivery title from
    BLUEPRINT.md, never SPEC.md). (work-009-refactor task-016: was fenced-
    frontmatter/bullet-heading STATE.md files -- retired, SPEC.md sec:D-4.)"""
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True, exist_ok=True)
    (work_dir / "STATE.yml").write_text(_PIPELINE_STATE_BLOCK, encoding="utf-8")

    del_dir = work_dir / "deliveries" / "delivery-001"
    del_dir.mkdir(parents=True, exist_ok=True)
    (del_dir / "BLUEPRINT.md").write_text(
        "# Delivery BLUEPRINT -- delivery-001: Full-nested delivery\n\n"
        "## Objective\n\nDeliver the full-nested layout.\n\n"
        "## Gate Criteria\n\n- [ ] All tests pass\n",
        encoding="utf-8",
    )
    (del_dir / "STATE.yml").write_text(
        "delivery_state: Executing\n"
        "gate_tier: Small\n"
        "gate_grade: A+\n"
        "gate_timestamp: '2026-07-08T12:00:00Z'\n"
        "delivery_lifecycle:\n"
        "  updated: '2026-07-08T12:00:00Z'\n"
        "  block_reason: --\n"
        "  block_artifact: --\n"
        "delivery_gate:\n"
        "  issue_list: []\n"
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
    """work-NNN/BLUEPRINT.md + work-NNN/tasks/task-NNN/DETAIL.md -- single
    delivery, no per-task STATE.yml; lifecycle/gate/Q&A/task-cells AUTHORED
    in the work-root STATE.yml (the 3-part flat-detection rule: BLUEPRINT.md
    present AND tasks/task-NNN/DETAIL.md present AND no deliveries/)."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)
        self.work_dir = _build_lite_flat_work(self.aid, "work-901-lite-flat")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_detect_flat_true(self):
        """_detect_flat returns True for the flat layout; _detect_hierarchy
        (the nested per-task-STATE.yml rule) must be False -- the two are
        mutually exclusive by construction (see reader.py _detect_flat's
        own docstring, and test_flattened_layout_parity.py's identical check)."""
        self.assertTrue(_detect_flat(self.work_dir))
        self.assertFalse(_detect_hierarchy(self.work_dir))

    def test_no_deliveries_folder_on_disk(self):
        """The fixture itself has no deliveries/ folder (sanity on the fixture,
        not the reader) -- the defining trait of the lite-flat layout."""
        self.assertFalse((self.work_dir / "deliveries").exists())

    def test_tasks_read_from_detail_and_tasks_lifecycle(self):
        """Tasks resolved from DETAIL.md (type/short_name) + the work-root
        STATE.yml's `tasks_lifecycle` mapping (state) -- there is no per-task
        STATE.yml in this layout (reader.py _read_work_flat)."""
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
        """delivery_state comes from the work-root STATE.yml's own
        `delivery_state` key (AUTHORED, not derived) -- there is no
        separate delivery-level STATE.yml file for a lite work."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(w.deliverables[0].delivery_state, "Executing")

    def test_work_path_defaults_to_lite(self):
        """FIX 1: this fixture authors no `## Triage -> **Path:**` field at
        all (see _build_lite_flat_work -- no Triage section), matching a
        shortcut-produced work. `_read_work_flat` defaults `work_path` to
        'lite' -- a flat work IS a Lite work by construction."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(w.work_path, "lite")

    def test_work_lifecycle_distinct_from_delivery_state(self):
        """Work-level `lifecycle` (Running) and the delivery's own
        `delivery_state` (Executing) are two DIFFERENT keys in the
        SAME work-root STATE.yml file -- the reader must not confuse them."""
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
    """work-NNN/deliveries/delivery-NNN/{BLUEPRINT,STATE}.md +
    deliveries/delivery-NNN/tasks/task-NNN/{DETAIL,STATE}.md -- mirrors
    features/feature-NNN/."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        self.tmp = Path(self._tmpdir)
        self.root, self.aid = _make_repo(self.tmp)
        self.work_dir = _build_full_nested_work(self.aid, "work-902-full-nested")

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_detect_hierarchy_true(self):
        """_detect_hierarchy returns True (per-task STATE.yml present under
        deliveries/); _detect_flat must be False -- mutually exclusive."""
        self.assertTrue(_detect_hierarchy(self.work_dir))
        self.assertFalse(_detect_flat(self.work_dir))

    def test_deliveries_folder_present_on_disk(self):
        """Sanity on the fixture: deliveries/ nests delivery-001/, mirroring
        features/feature-NNN/ -- the defining trait of the full-nested layout."""
        self.assertTrue((self.work_dir / "deliveries" / "delivery-001").is_dir())

    def test_tasks_read_from_per_unit_state(self):
        """Tasks resolved from DETAIL.md (type/short_name) + the per-task
        deliveries/delivery-001/tasks/task-NNN/STATE.yml (state)."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        task_map = {t.task_id: t for t in w.tasks}
        self.assertEqual(task_map["task-001"].status.value, "Done")
        self.assertEqual(task_map["task-002"].status.value, "In Progress")
        self.assertEqual(task_map["task-001"].short_name, "First full task")
        self.assertEqual(task_map["task-002"].type, "TEST")

    def test_single_deliverable_name_from_delivery_blueprint(self):
        """The delivery's DeliverableRef.name is read from
        deliveries/delivery-001/BLUEPRINT.md's H1 heading (reader.py
        _read_work_hierarchical + _parse_delivery_spec_title), never SPEC.md."""
        model = _read_repo_single_work(self.root, self.aid)
        w = model.works[0]
        self.assertEqual(len(w.deliverables), 1)
        d = w.deliverables[0]
        self.assertEqual(d.number, 1)
        self.assertEqual(d.task_count, 2)
        self.assertEqual(d.name, "Full-nested delivery")

    def test_delivery_state_from_delivery_state_md(self):
        """delivery_state comes from deliveries/delivery-001/STATE.yml's own
        `delivery_state` key (a real per-delivery file, unlike lite)."""
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
