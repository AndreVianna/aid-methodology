"""task-031 (work-003 delivery-002, AC-41) and task-070 (feature-002 section 6):
work-level fixtures through both readers.

A STATE.yml whose `intent:` block carries a `phases:` block list must reach
the serialized work as that same list, in order, from the Python reader
(dashboard/reader/) and from the Node reader (dashboard/server/reader.mjs).
A work whose file has no intent block must serialize `phases` as null.

task-070 adds the section-6 record fields, read identically by both readers:
  - an open call (returns yes, returned unset) serializes open_call with
    to, why and returns_to (the phase the work is in);
  - a work with no intent.reading serializes record_status missing;
  - a Completed work that still names a saved skill serializes inconsistent;
  - step and step_detail come through;
  - a qa entry in state Skipped counts as open (pending_inputs).

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


def _state_text(
    intent_block: str = "",
    *,
    lifecycle: str = "Running",
    active_skill: str = "aid-execute",
    extra: str = "",
) -> str:
    """Build a work STATE.yml: the identity keys, `extra` top-level blocks
    (step, handoffs, qa), then `intent_block` last (may be empty)."""
    return (
        "pipeline:\n"
        "  path: full\n"
        "  initiator: aid-describe\n"
        'started: "2026-10-01"\n'
        "minimum_grade: A\n"
        "user_approved: no\n"
        f"lifecycle: {lifecycle}\n"
        "phase: Building\n"
        f"active_skill: {active_skill}\n"
        + extra
        + 'updated: "2026-10-01T12:00:00Z"\n'
        + intent_block
    )


def _write_repo(root: Path, state_text: str) -> None:
    """Write a repo at `root` holding one work whose STATE.yml is `state_text`."""
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
    (work_dir / "STATE.yml").write_text(state_text, encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text(
        "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
    )


def _write_work(root: Path, intent_block: str) -> None:
    """Write a repo at `root` holding one work whose STATE.yml carries
    `intent_block` (may be empty) after the identity keys."""
    _write_repo(root, _state_text(intent_block))


_WITH_PHASES = (
    "intent:\n"
    "  phases:\n"
    + "".join(f"    - {p}\n" for p in _PHASES)
)

_INTENT_READ = "intent:\n  reading: Build the thing\n"

_STEP = 'step: "3"\nstep_detail: review the diff\n'

# One closed call (returned set) then one open call: the newest open one wins.
_HANDOFFS = (
    "handoffs:\n"
    "  - from: aid-execute\n"
    '    from_step: "2"\n'
    "    from_detail: --\n"
    "    to: aid-plan\n"
    "    why: old question\n"
    "    returns: yes\n"
    '    returned: "2026-10-02T09:00:00Z"\n'
    "  - from: aid-execute\n"
    '    from_step: "3"\n'
    "    from_detail: --\n"
    "    to: aid-review\n"
    "    why: needs a second look\n"
    "    returns: yes\n"
    "    returned: --\n"
)

# Skipped and Pending are open; Answered is not.
_QA = (
    "qa:\n"
    "  - id: 1\n"
    "    category: Scope\n"
    "    impact: Low\n"
    "    state: Skipped\n"
    "    context: first question\n"
    "    suggested: Yes\n"
    "  - id: 2\n"
    "    category: Scope\n"
    "    impact: High\n"
    "    state: Pending\n"
    "    context: second question\n"
    "    suggested: No\n"
    "  - id: 3\n"
    "    category: Scope\n"
    "    impact: High\n"
    "    state: Answered\n"
    "    context: third question\n"
    "    suggested: No\n"
)


class _BothReadersCase(unittest.TestCase):
    """Shared fixture plumbing: write a repo, read it through both readers."""

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

    def _both(self, name: str, state_text: str) -> tuple[dict, dict]:
        """Write one work with `state_text`; return (python, node) serialized works
        after asserting they are identical."""
        if not _node_available():
            self.skipTest("node not available on PATH")
        root = self._fresh_root(name)
        _write_repo(root, state_text)
        py_w = self._read_python_work(root)
        node_w = self._read_node_work(root)
        self.assertEqual(py_w, node_w, "Python and Node must agree on the serialized work")
        return py_w, node_w


class TestIntentPhasesThroughBothReaders(_BothReadersCase):
    """The serialized work carries intent.phases, in order, from both readers."""

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


class TestWorkRecordThroughBothReaders(_BothReadersCase):
    """task-070: the section-6 record fields serialize identically from both readers."""

    def test_open_call_serializes_identically(self):
        py_w, node_w = self._both(
            "open-call", _state_text(_INTENT_READ, extra=_STEP + _HANDOFFS)
        )
        expected = {
            "to": "aid-review",
            "why": "needs a second look",
            "returns_to": py_w["phase"],
        }
        self.assertEqual(py_w["open_call"], expected)
        self.assertEqual(node_w["open_call"], expected)
        self.assertEqual(py_w["open_call"]["returns_to"], "Building")

    def test_no_open_call_when_every_call_is_returned(self):
        closed_only = _HANDOFFS.split("  - from: aid-execute\n    from_step: \"3\"")[0]
        py_w, node_w = self._both(
            "no-open-call", _state_text(_INTENT_READ, extra=_STEP + closed_only)
        )
        self.assertIsNone(py_w["open_call"])
        self.assertIsNone(node_w["open_call"])

    def test_work_without_intent_reading_is_missing(self):
        py_w, node_w = self._both("no-reading", _state_text("", extra=_STEP))
        self.assertEqual(py_w["record_status"], "missing")
        self.assertEqual(node_w["record_status"], "missing")

    def test_completed_work_with_saved_skill_is_inconsistent(self):
        py_w, node_w = self._both(
            "completed-skill",
            _state_text(_INTENT_READ, lifecycle="Completed", extra=_STEP),
        )
        self.assertEqual(py_w["record_status"], "inconsistent")
        self.assertEqual(node_w["record_status"], "inconsistent")

    def test_completed_work_without_saved_skill_is_ok(self):
        py_w, node_w = self._both(
            "completed-no-skill",
            _state_text(
                _INTENT_READ, lifecycle="Completed", active_skill="none", extra=_STEP
            ),
        )
        self.assertEqual(py_w["record_status"], "ok")
        self.assertEqual(node_w["record_status"], "ok")

    def test_step_and_step_detail_come_through(self):
        py_w, node_w = self._both("step", _state_text(_INTENT_READ, extra=_STEP))
        for w in (py_w, node_w):
            self.assertEqual(w["step"], "3")
            self.assertEqual(w["step_detail"], "review the diff")
            self.assertEqual(w["record_status"], "ok")
            self.assertIsNone(w["open_call"])

    def test_skipped_qa_entry_counts_as_open(self):
        py_w, node_w = self._both(
            "skipped-qa", _state_text(_INTENT_READ, extra=_STEP + _QA)
        )
        for w in (py_w, node_w):
            self.assertEqual(
                [p["question_id"] for p in w["pending_inputs"]], ["Q1", "Q2"]
            )


if __name__ == "__main__":
    unittest.main()
