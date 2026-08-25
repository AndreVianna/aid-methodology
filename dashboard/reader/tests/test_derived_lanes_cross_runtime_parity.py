"""
test_derived_lanes_cross_runtime_parity.py -- CROSS-RUNTIME parity for lane derivation
from task DETAIL.md files.

The flattened/Lite layout has one delivery and therefore no sequencing decision to
record, so its execution graph is not authored: each task's `**Depends on:**` field IS
the graph. Both reader twins derive lanes from those fields, and both must agree on
every input: reader.py's `_derive_lanes_from_details` and reader.mjs's
`_deriveLanesFromDetails`.

`canonical/aid/scripts/execute/derive-waves.sh` is the REFERENCE implementation -- its
awk pass owns the algorithm, and these two are ports. That makes three implementations
of one topological sort, which is precisely the shape that produced three silent
divergences earlier in this work (a bash YAML reader disagreeing with these same
twins on CRLF, single quotes, and an inline comment). Hence this file.

The fixtures target the rules a port is most likely to drop:

  - A dependency on a task NOT in the set is treated as already SATISFIED, not as an
    error. Deliveries run in series, so a dependency on an earlier delivery's task is
    met before this one starts. A port that treats it as unsatisfiable deadlocks and
    reports a cycle that does not exist.
  - A self-dependency is discarded rather than deadlocking.
  - A CYCLE yields {} -- not a partial map, which would show some tasks laned and
    others not, reading as a problem with the tasks rather than with the graph.
  - Every "no dependencies" spelling (em dash, en dash, '--', '-', 'none', empty)
    means the same thing, because ids are EXTRACTED rather than the field cleaned.
  - Case-insensitivity on both the field name and the ids.
  - A diamond, where the join must land one wave after BOTH its parents rather than
    one after the first.

Bounded compute only: the Node side is a short-lived `node` subprocess, no server
spawn and no port binding.
"""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.reader import _derive_lanes_from_details

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , readerPath, fixturesPath] = process.argv;
const fs = await import("node:fs");
const mod = await import(pathToFileURL(readerPath).href);
const fixtures = JSON.parse(fs.readFileSync(fixturesPath, "utf8"));
const out = {};
for (const [name, details] of Object.entries(fixtures)) {
  out[name] = mod._deriveLanesFromDetails(details);
}
process.stdout.write(JSON.stringify(out));
"""


def _d(depends: str) -> str:
    """A minimal DETAIL.md body carrying one **Depends on:** field."""
    return f"# task\n\n**Type:** IMPLEMENT\n\n**Depends on:** {depends}\n"


FIXTURES = {
    "single_no_deps": {"task-001": _d("-- (none)")},
    "chain_of_three": {
        "task-001": _d("--"),
        "task-002": _d("task-001"),
        "task-003": _d("task-002"),
    },
    "fan_out": {
        "task-001": _d("--"),
        "task-002": _d("task-001"),
        "task-003": _d("task-001"),
    },
    # The join must be wave 3, one after BOTH parents -- not wave 2, one after the
    # first parent a naive implementation happens to visit.
    "diamond": {
        "task-001": _d("--"),
        "task-002": _d("task-001"),
        "task-003": _d("task-001"),
        "task-004": _d("task-002, task-003"),
    },
    # Foreign dependency: task-900 is not in this set, so it is already satisfied.
    "foreign_dep_is_satisfied": {
        "task-001": _d("task-900"),
        "task-002": _d("task-001"),
    },
    "self_dep_discarded": {"task-001": _d("task-001")},
    "cycle_two": {"task-001": _d("task-002"), "task-002": _d("task-001")},
    "cycle_three": {
        "task-001": _d("task-003"),
        "task-002": _d("task-001"),
        "task-003": _d("task-002"),
    },
    "em_dash": {"task-001": _d("\u2014")},
    "en_dash": {"task-001": _d("\u2013")},
    "word_none": {"task-001": _d("None")},
    "empty_value": {"task-001": _d("")},
    "no_depends_field": {"task-001": "# task\n\n**Type:** TEST\n"},
    "uppercase_ids": {"task-001": _d("--"), "task-002": _d("TASK-001")},
    "uppercase_field": {"task-001": "**DEPENDS ON:** --\n"},
    "empty_set": {},
    # Ordering must not depend on insertion order: the same graph declared
    # back-to-front must produce the same waves.
    "declared_backwards": {
        "task-003": _d("task-002"),
        "task-002": _d("task-001"),
        "task-001": _d("--"),
    },
}


def _node_available() -> bool:
    try:
        proc = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return proc.returncode == 0
    except Exception:  # noqa: BLE001
        return False


_NODE_AVAILABLE = _node_available()


def _node_lanes(fixtures: dict) -> dict:
    tmp = Path(tempfile.mkdtemp())
    try:
        driver = tmp / "driver.mjs"
        driver.write_text(_NODE_DRIVER, encoding="utf-8")
        payload = tmp / "fixtures.json"
        payload.write_text(json.dumps(fixtures), encoding="utf-8")
        proc = subprocess.run(
            ["node", str(driver), str(_READER_MJS), str(payload)],
            capture_output=True, text=True, timeout=30,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed (exit {proc.returncode}): {proc.stderr}")
        return json.loads(proc.stdout)
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


class TestDerivedLanesParity(unittest.TestCase):

    def test_python_side_expected_values(self):
        """Pin the Python twin's answers, so parity cannot be satisfied by BOTH
        runtimes being wrong in the same way."""
        self.assertEqual(_derive_lanes_from_details(FIXTURES["single_no_deps"]),
                         {"task-001": 1})
        self.assertEqual(_derive_lanes_from_details(FIXTURES["chain_of_three"]),
                         {"task-001": 1, "task-002": 2, "task-003": 3})
        self.assertEqual(_derive_lanes_from_details(FIXTURES["fan_out"]),
                         {"task-001": 1, "task-002": 2, "task-003": 2})
        # The join lands one wave after BOTH parents.
        self.assertEqual(_derive_lanes_from_details(FIXTURES["diamond"]),
                         {"task-001": 1, "task-002": 2, "task-003": 2, "task-004": 3})
        # A dependency outside the set is already satisfied, so task-001 is still wave 1.
        self.assertEqual(_derive_lanes_from_details(FIXTURES["foreign_dep_is_satisfied"]),
                         {"task-001": 1, "task-002": 2})
        self.assertEqual(_derive_lanes_from_details(FIXTURES["self_dep_discarded"]),
                         {"task-001": 1})
        # A cycle yields {} -- never a partial map.
        self.assertEqual(_derive_lanes_from_details(FIXTURES["cycle_two"]), {})
        self.assertEqual(_derive_lanes_from_details(FIXTURES["cycle_three"]), {})
        # Every "no dependencies" spelling means the same thing.
        for name in ("em_dash", "en_dash", "word_none", "empty_value", "no_depends_field"):
            self.assertEqual(_derive_lanes_from_details(FIXTURES[name]), {"task-001": 1},
                             f"{name} should place the only task in wave 1")
        self.assertEqual(_derive_lanes_from_details(FIXTURES["uppercase_ids"]),
                         {"task-001": 1, "task-002": 2})
        self.assertEqual(_derive_lanes_from_details(FIXTURES["empty_set"]), {})
        # Declaration order must not change the answer.
        self.assertEqual(_derive_lanes_from_details(FIXTURES["declared_backwards"]),
                         _derive_lanes_from_details(FIXTURES["chain_of_three"]))

    @unittest.skipUnless(_NODE_AVAILABLE, "node not available")
    def test_both_runtimes_agree_on_every_fixture(self):
        node_out = _node_lanes(FIXTURES)
        mismatches = []
        for name, details in FIXTURES.items():
            py = _derive_lanes_from_details(details)
            nd = node_out.get(name)
            if py != nd:
                mismatches.append(f"{name}: python={py!r} node={nd!r}")
        self.assertEqual(
            mismatches, [],
            "reader.py and reader.mjs disagree on derived lanes:\n  " + "\n  ".join(mismatches),
        )

    @unittest.skipUnless(_NODE_AVAILABLE, "node not available")
    def test_agrees_with_the_bash_reference_implementation(self):
        """derive-waves.sh owns the algorithm; these two are ports of it.

        Agreement between the ports proves they match each other, not that either
        matches the reference. This runs the real script over a work built from one
        fixture and compares the waves it prints against the Python twin's map.
        """
        script = _REPO_ROOT / "canonical" / "aid" / "scripts" / "execute" / "derive-waves.sh"
        if not script.is_file():
            self.skipTest("derive-waves.sh not present")

        work = Path(tempfile.mkdtemp()) / "work-950-parity"
        try:
            for task_id, body in FIXTURES["diamond"].items():
                task_dir = work / "tasks" / task_id
                task_dir.mkdir(parents=True)
                (task_dir / "DETAIL.md").write_text(
                    body.replace("**Type:** IMPLEMENT",
                                 "**Type:** IMPLEMENT\n\n**Source:** w -> delivery-001"),
                    encoding="utf-8",
                )
            proc = subprocess.run(
                ["bash", str(script), "--from-tasks", str(work)],
                capture_output=True, text=True, timeout=60,
            )
            self.assertEqual(proc.returncode, 0, f"derive-waves.sh failed: {proc.stderr}")

            # Parse `wave N: task-a, task-b` lines into the same {task: wave} shape.
            bash_lanes = {}
            for line in proc.stdout.splitlines():
                line = line.strip()
                if not line.lower().startswith("wave "):
                    continue
                head, _, rest = line.partition(":")
                wave = int(head.split()[1])
                for tid in (t.strip().lower() for t in rest.split(",")):
                    if tid:
                        bash_lanes[tid] = wave

            self.assertEqual(
                bash_lanes, _derive_lanes_from_details(FIXTURES["diamond"]),
                "the Python port disagrees with derive-waves.sh, the reference implementation",
            )
        finally:
            shutil.rmtree(str(work.parent), ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
