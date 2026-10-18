"""task-048 (work-003 delivery-002, AC-41): phase mapping and cross-runtime parity.

For each fixture work -- one at every FR-1 phase, one completed work, one
work holding every old phase name, and one unknown name -- the Python reader
(dashboard/reader/) and the Node reader (dashboard/server/reader.mjs) must
return the same serialized work, and the phase must be the member the spec's
phase table gives (Describe -> Definition, Define and Specify -> Specification,
Plan and Detail -> Planning, Execute -> Building).

Each fixture builds its own temporary repository; no work folder is shared.
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

from dashboard.reader import read_repo  # noqa: E402
from dashboard.server.server import _ser_work  # noqa: E402

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

# The new FR-1 names: each maps to itself.
_NEW_PHASES = ("Definition", "Specification", "Planning", "Building", "CI")

# The spec's phase table (REQUIREMENTS.md Feature 002, Work state layout).
_OLD_TO_NEW = {
    "Describe": "Definition",
    "Define": "Specification",
    "Specify": "Specification",
    "Plan": "Planning",
    "Detail": "Planning",
    "Execute": "Building",
}


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _write_work(root: Path, phase_value: str, lifecycle: str = "Running") -> str:
    """Write a repo at `root` holding one frontmatter STATE.yml work whose
    `phase:` is `phase_value`. Returns the work id."""
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

    work_id = "work-980-phase-fixture"
    work_dir = aid / "works" / work_id
    work_dir.mkdir(parents=True)
    (work_dir / "STATE.yml").write_text(
        "pipeline:\n"
        "  path: full\n"
        "  initiator: aid-describe\n"
        'started: "2026-10-01"\n'
        "minimum_grade: A\n"
        "user_approved: no\n"
        f"lifecycle: {lifecycle}\n"
        f"phase: {phase_value}\n"
        "active_skill: aid-execute\n"
        'updated: "2026-10-01T12:00:00Z"\n',
        encoding="utf-8",
    )
    tasks_dir = work_dir / "tasks" / "task-001"
    tasks_dir.mkdir(parents=True)
    (tasks_dir / "DETAIL.md").write_text(
        "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
    )
    return work_id


class TestPhaseMappingParity(unittest.TestCase):
    """Both readers agree on every phase fixture and map old names by the table."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.pinned_home = self.tmp / "pinned-home"
        self.pinned_home.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _fresh_root(self, name: str) -> Path:
        root = self.tmp / name
        root.mkdir(parents=True, exist_ok=True)
        return root

    def _read_python_work(self, root: Path) -> dict:
        aid = root / ".aid"
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", aid)],
        ):
            model = read_repo(root)
        return _ser_work(model.works[0])

    def _read_node_work(self, root: Path) -> dict:
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
            env={**os.environ, "HOME": str(self.pinned_home)},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
        return json.loads(result.stdout.strip())

    def _assert_parity_and_phase(self, phase_value: str, expected: str, lifecycle: str = "Running"):
        root = self._fresh_root(f"case-{phase_value.lower()}-{lifecycle.lower()}")
        _write_work(root, phase_value, lifecycle)
        py_w = self._read_python_work(root)
        node_w = self._read_node_work(root)
        self.assertEqual(
            py_w, node_w,
            f"Python and Node must agree on the serialized work for phase={phase_value!r}",
        )
        self.assertEqual(py_w["phase"], expected,
                         f"phase={phase_value!r} must read as {expected!r}")
        self.assertEqual(py_w["lifecycle"], lifecycle)

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_each_new_phase_reads_as_itself_in_both_readers(self):
        for phase in _NEW_PHASES:
            with self.subTest(phase=phase):
                self._assert_parity_and_phase(phase, phase)

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_completed_work_keeps_its_phase_in_both_readers(self):
        self._assert_parity_and_phase("Building", "Building", lifecycle="Completed")

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_old_phase_names_map_by_the_spec_table_in_both_readers(self):
        for old, new in _OLD_TO_NEW.items():
            with self.subTest(old=old):
                self._assert_parity_and_phase(old, new)

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_unknown_phase_name_reads_as_unknown_in_both_readers(self):
        self._assert_parity_and_phase("Ship", "Unknown")


if __name__ == "__main__":
    unittest.main()
