"""task-031 (work-003 delivery-002, AC-41): intent.phases through both readers.

A STATE.yml whose `intent:` block carries a `phases:` block list must reach
the serialized work as that same list, in order, from the Python reader
(dashboard/reader/) and from the Node reader (dashboard/server/reader.mjs).
A work whose file has no intent block must serialize `phases` as null.

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

_PHASES = ["Definition", "Specification", "Building", "CI"]


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _write_work(root: Path, intent_block: str) -> None:
    """Write a repo at `root` holding one work whose STATE.yml carries
    `intent_block` (may be empty) after the identity keys."""
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

    work_dir = aid / "works" / "work-981-intent-fixture"
    (work_dir / "tasks" / "task-001").mkdir(parents=True)
    (work_dir / "STATE.yml").write_text(
        "pipeline:\n"
        "  path: full\n"
        "  initiator: aid-describe\n"
        'started: "2026-10-01"\n'
        "minimum_grade: A\n"
        "user_approved: no\n"
        "lifecycle: Running\n"
        "phase: Building\n"
        "active_skill: aid-execute\n"
        'updated: "2026-10-01T12:00:00Z"\n'
        + intent_block,
        encoding="utf-8",
    )
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text(
        "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
    )


_WITH_PHASES = (
    "intent:\n"
    "  phases:\n"
    + "".join(f"    - {p}\n" for p in _PHASES)
)


class TestIntentPhasesThroughBothReaders(unittest.TestCase):
    """The serialized work carries intent.phases, in order, from both readers."""

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

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_intent_phases_list_reaches_both_serialized_works(self):
        root = self._fresh_root("with-phases")
        _write_work(root, _WITH_PHASES)
        py_w = self._read_python_work(root)
        node_w = self._read_node_work(root)
        self.assertEqual(py_w["phases"], _PHASES)
        self.assertEqual(node_w["phases"], _PHASES)
        self.assertEqual(py_w, node_w, "Python and Node must agree on the serialized work")

    def test_work_without_intent_serializes_phases_as_null(self):
        root = self._fresh_root("no-intent")
        _write_work(root, "")
        py_w = self._read_python_work(root)
        self.assertIsNone(py_w["phases"])

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_work_without_intent_serializes_phases_as_null_in_both_readers(self):
        root = self._fresh_root("no-intent-parity")
        _write_work(root, "")
        self.assertIsNone(self._read_python_work(root)["phases"])
        self.assertIsNone(self._read_node_work(root)["phases"])


if __name__ == "__main__":
    unittest.main()
