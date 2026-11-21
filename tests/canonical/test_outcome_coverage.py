#!/usr/bin/env python3
"""Exercise the opt-in outcome coverage check using disposable evidence records."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "experiments/aid-plain-first/outcome_coverage.py"
SCRATCH = ROOT / ".aid/.temp"


class OutcomeCoverage(unittest.TestCase):
    def run_check(self, data):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            file = Path(directory) / "coverage.json"
            file.write_text(json.dumps(data), encoding="utf-8")
            return subprocess.run([sys.executable, str(SCRIPT), str(file)], capture_output=True, text=True)

    def record(self):
        return {"outcomes": [{"id": "O1", "description": "The user can export data"},
                             {"id": "O2", "description": "Existing data remains intact"}],
                "results": [{"id": "O1", "status": "verified", "evidence": ["tests/export.py"]},
                            {"id": "O2", "status": "verified", "evidence": ["review of saved data"]}]}

    def test_complete_records_are_only_structural_evidence(self):
        result = self.run_check(self.record())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("structural", result.stdout.lower())
        self.assertIn("does not prove", result.stdout.lower())

    def test_omitted_or_unverified_outcome_is_not_a_pass(self):
        data = self.record()
        data["results"].pop()
        result = self.run_check(data)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("O2", result.stdout)
        self.assertIn("unverified", result.stdout.lower())
        self.assertIn("no result supplied", result.stdout.lower())

    @unittest.skipIf(sys.platform == "win32", "grade.sh runs in the project's Bash lane")
    def test_empty_ledger_grade_does_not_hide_missing_outcome(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            ledger = Path(directory) / "ledger.md"
            ledger.write_text("| # | Severity | Status | Doc | Line | Description | Evidence |\n"
                              "|---|---|---|---|---|---|---|\n", encoding="utf-8")
            grade = subprocess.run(["bash", str(ROOT / "canonical/aid/scripts/grade.sh"), str(ledger)],
                                   capture_output=True, text=True)
        self.assertEqual(grade.returncode, 0, grade.stderr)
        self.assertEqual(grade.stdout.strip(), "A+")
        data = self.record()
        data["results"].pop()
        self.assertEqual(self.run_check(data).returncode, 1)

    def test_failed_outcome_is_not_a_pass(self):
        data = self.record()
        data["results"][0] = {"id": "O1", "status": "failed", "evidence": ["export failed"]}
        result = self.run_check(data)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("failed", result.stdout.lower())

    def test_empty_evidence_cannot_verify_an_outcome(self):
        data = self.record()
        data["results"][0]["evidence"] = []
        result = self.run_check(data)
        self.assertNotEqual(result.returncode, 0)

    def test_unverified_outcome_discloses_why(self):
        data = self.record()
        data["results"][0] = {"id": "O1", "status": "unverified", "evidence": ["Browser unavailable"]}
        result = self.run_check(data)
        self.assertEqual(result.returncode, 1)
        data["results"][0]["evidence"] = []
        self.assertEqual(self.run_check(data).returncode, 2)

    def test_duplicate_unknown_or_empty_outcome_sets_are_invalid(self):
        for mutate in (lambda d: d["results"].append(d["results"][0]),
                       lambda d: d["results"].append({"id": "O3", "status": "verified", "evidence": ["x"]}),
                       lambda d: d.update(outcomes=[], results=[])):
            with self.subTest(mutate=mutate):
                data = self.record()
                mutate(data)
                self.assertEqual(self.run_check(data).returncode, 2)

    def test_duplicate_json_keys_are_rejected(self):
        raw = ('{"outcomes":[{"id":"O1","description":"first"}],'
               '"outcomes":[{"id":"O2","description":"second"}],'
               '"results":[{"id":"O2","status":"verified","evidence":["x"]}]}')
        SCRATCH.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            file = Path(directory) / "coverage.json"
            file.write_text(raw, encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), str(file)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("duplicate JSON key", result.stderr)


if __name__ == "__main__":
    unittest.main()
