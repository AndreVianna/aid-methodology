"""task-079 (work-003 delivery-003, Feature 002 section 8 Testing, AC-41): work
fixtures at each phase, during a call, with the record warnings, read by both
dashboard readers.

The fixtures live in `fixtures/task079/works.txt` (one STATE.yml per work,
each introduced by an `@@ <work-id>` line) and their expected values in
`fixtures/task079/expected.json`. The Node suite
(`dashboard/server/tests/test_task079_phase_fixtures.mjs`) and the card-line
test in `dashboard/server/tests/test_index_html.py` read the same two files.

Each test writes its own temporary repository from those files; no work
folder of this project is read.

Checks:
  - each fixture serializes identically through the Python reader
    (dashboard/reader/) and the Node reader (dashboard/server/reader.mjs);
  - each fixture carries the expected phase, lifecycle, step, step_detail,
    open call, open question count and record_status;
  - the fixtures cover every phase, a call in progress, and both record
    warnings (missing and inconsistent).
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
_FIXTURE_DIR = Path(__file__).resolve().parent / "fixtures" / "task079"


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def load_works(path: Path = _FIXTURE_DIR / "works.txt") -> dict[str, str]:
    """Return {work_id: STATE.yml text} from the `@@ <work-id>` sections, in file order."""
    works: dict[str, list[str]] = {}
    current: list[str] | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("@@ "):
            current = works.setdefault(line[3:].strip(), [])
        elif current is not None:
            current.append(line)
    return {wid: "\n".join(lines) + "\n" for wid, lines in works.items()}


def load_expected(path: Path = _FIXTURE_DIR / "expected.json") -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_repo(root: Path, works: dict[str, str]) -> None:
    """Write a repo at `root` holding one `.aid/works/<id>/STATE.yml` per entry."""
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
    for work_id, text in works.items():
        work_dir = aid / "works" / work_id
        work_dir.mkdir(parents=True, exist_ok=True)
        (work_dir / "STATE.yml").write_text(text, encoding="utf-8")


def read_python_works(root: Path) -> dict[str, dict]:
    aid = root / ".aid"
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        model = read_repo(root)
    return {w.work_id: _ser_work(w) for w in model.works}


def read_node_works(root: Path, home: Path) -> dict[str, dict]:
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "process.stdout.write(JSON.stringify(m.works || []) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=30,
        env={**os.environ, "HOME": str(home)},
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return {w["work_id"]: w for w in json.loads(result.stdout.strip())}


class TestTask079PhaseFixtures(unittest.TestCase):
    """The fixture set, read by both readers."""

    @classmethod
    def setUpClass(cls):
        cls.works = load_works()
        cls.expected = load_expected()["works"]

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.home = self.tmp / "pinned-home"
        self.home.mkdir()
        self.root = self.tmp / "repo"
        self.root.mkdir()
        write_repo(self.root, self.works)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_fixture_set_matches_expected(self):
        self.assertEqual(sorted(self.works), sorted(self.expected))

    def test_fixtures_cover_every_phase_and_lifecycle_case(self):
        phases = {e["phase"] for e in self.expected.values()}
        for phase in ("Definition", "Specification", "Planning", "Building", "CI"):
            self.assertIn(phase, phases, f"no fixture at phase {phase}")
        self.assertIn("Completed", {e["lifecycle"] for e in self.expected.values()})
        self.assertTrue(any(e["open_call"] for e in self.expected.values()),
                        "no fixture with a call in progress")
        statuses = {e["record_status"] for e in self.expected.values()}
        self.assertTrue({"missing", "inconsistent"} <= statuses,
                        "fixtures must hold a missing and an inconsistent record")

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_both_readers_serialize_each_fixture_identically(self):
        py = read_python_works(self.root)
        node = read_node_works(self.root, self.home)
        self.assertEqual(sorted(py), sorted(self.works))
        for work_id in self.works:
            with self.subTest(work=work_id):
                self.assertEqual(py[work_id], node[work_id],
                                 "Python and Node must agree on the serialized work")

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_each_fixture_carries_its_expected_values_in_both_readers(self):
        py = read_python_works(self.root)
        node = read_node_works(self.root, self.home)
        for work_id, exp in self.expected.items():
            for label, w in (("python", py[work_id]), ("node", node[work_id])):
                with self.subTest(work=work_id, reader=label):
                    self.assertEqual(w["phase"], exp["phase"])
                    self.assertEqual(w["lifecycle"], exp["lifecycle"])
                    self.assertEqual(w["step"], exp["step"])
                    self.assertEqual(w["step_detail"], exp["step_detail"])
                    self.assertEqual(w["open_call"], exp["open_call"])
                    self.assertEqual(len(w["pending_inputs"]), exp["pending"])
                    self.assertEqual(w["record_status"], exp["record_status"])

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_open_call_names_the_phase_the_work_returns_to(self):
        py = read_python_works(self.root)
        node = read_node_works(self.root, self.home)
        for label, w in (("python", py["work-105-building-during-call"]),
                         ("node", node["work-105-building-during-call"])):
            with self.subTest(reader=label):
                self.assertEqual(w["open_call"]["returns_to"], "Building")
                self.assertEqual(w["open_call"]["to"], "aid-kb-update")

    @unittest.skipUnless(_node_available(), "node not available on PATH")
    def test_old_phase_name_reads_as_its_new_name_in_both_readers(self):
        py = read_python_works(self.root)
        node = read_node_works(self.root, self.home)
        self.assertEqual(py["work-108-old-phase-names"]["phase"], "Building")
        self.assertEqual(node["work-108-old-phase-names"]["phase"], "Building")


if __name__ == "__main__":
    unittest.main()
