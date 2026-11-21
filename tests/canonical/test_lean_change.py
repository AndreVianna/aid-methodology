#!/usr/bin/env python3
"""Purpose: exercise the lean change scripts against small, disposable projects.
Usage: python tests/canonical/test_lean_change.py
Exit codes: 0 when all tests pass; nonzero on a failure.
"""
import json
import contextlib
import hashlib
import importlib.util
import io
import os
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "canonical" / "aid" / "scripts" / "change"


class LeanScripts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="aid-lean-test-")
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)
        def git(*args):
            return subprocess.run(["git", "-C", str(self.dir), *args], check=True,
                                  text=True, capture_output=True).stdout.strip()
        git("init", "-q")
        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        (self.dir / "tracked.txt").write_text("starting content", encoding="utf-8")
        git("add", "tracked.txt")
        git("commit", "-qm", "starting revision")
        self.start_commit = git("rev-parse", "HEAD")

    def run_script(self, name, *args, cwd=None):
        return subprocess.run(
            [sys.executable, str(SCRIPTS / (name + ".py")), *map(str, args)],
            cwd=str(cwd or self.dir), text=True, capture_output=True,
            env=getattr(self, "script_env", None),
        )

    def write_json(self, name, data):
        path = self.dir / name
        path.write_text(json.dumps(data), encoding="utf-8")
        return path

    def track(self, *paths):
        subprocess.run(["git", "-C", str(self.dir), "add", "--", *map(str, paths)],
                       check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.dir), "commit", "-qm", "fixture inputs"],
                       check=True, capture_output=True)
        self.start_commit = subprocess.run(["git", "-C", str(self.dir), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True).stdout.strip()

    def check_spec(self, cases):
        # Each command executes independently and writes real JUnit XML.
        driver = self.dir / "produce.py"
        driver.write_text(
            "import json, sys, xml.etree.ElementTree as E\n"
            "d=json.load(open(sys.argv[1])); s=E.Element('testsuite', tests=str(len(d)))\n"
            "for case in d:\n"
            " c=E.SubElement(s,'testcase',classname='suite',name=case['name'])\n"
            " if case.get('failure') is not None:\n"
            "  e=E.SubElement(c,'failure',message=case['failure']); e.text=case['failure']\n"
            "E.ElementTree(s).write(sys.argv[2],encoding='unicode')\n"
            "sys.exit(1 if any('failure' in c for c in d) else 0)\n",
            encoding="utf-8",
        )
        self.write_json("cases.json", cases)
        self.track(driver, self.dir / "cases.json")
        return self.write_json("spec.json", {"commands": [{
            "name": "unit", "argv": [sys.executable, str(driver), "cases.json", "result.xml"],
            "junit": "result.xml",
        }]})

    def test_checks_remembers_existing_failure_but_blocks_new_or_changed(self):
        spec = self.check_spec([{"name": "old", "failure": "original"}, {"name": "ok"}])
        baseline = self.dir / "baseline.json"
        first = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
        same = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertEqual(same.returncode, 0, same.stderr + same.stdout)
        self.assertIn("old", same.stdout + same.stderr)
        self.assertIn("original", same.stdout + same.stderr)
        self.write_json("cases.json", [{"name": "old", "failure": "changed"}, {"name": "ok"}])
        changed = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(changed.returncode, 0, changed.stdout)
        self.write_json("cases.json", [{"name": "old", "failure": "original"}, {"name": "ok", "failure": "new"}])
        new = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(new.returncode, 0, new.stdout)

    def test_checks_blocks_fewer_tests_and_stale_or_invalid_reports(self):
        spec = self.check_spec([{"name": "one"}, {"name": "two"}])
        baseline = self.dir / "baseline.json"
        self.assertEqual(self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline).returncode, 0)
        self.write_json("cases.json", [{"name": "one"}])
        self.assertNotEqual(self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline).returncode, 0)
        # An old report must not disguise a command that failed before running tests.
        spec = self.write_json("spec.json", {"commands": [{"name": "unit", "argv": [sys.executable, "-c", "raise SystemExit(3)"], "junit": "result.xml"}]})
        self.assertNotEqual(self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline).returncode, 0)

    def test_checks_counts_executed_tests_not_skipped_cases(self):
        driver = self.dir / "skip-producer.py"
        driver.write_text(
            "from pathlib import Path\n"
            "skip=Path('skip-mode').read_text() == 'skip'\n"
            "xml='<testsuite tests=\"2\"><testcase name=\"one\"/><testcase name=\"two\">' + ('<skipped/>' if skip else '') + '</testcase></testsuite>'\n"
            "Path('report.xml').write_text(xml)\n", encoding="utf-8")
        flag = self.dir / "skip-mode"
        flag.write_text("run", encoding="utf-8")
        self.track(driver, flag)
        spec = self.write_json("skip-spec.json", {"commands": [{"name": "unit", "argv": [sys.executable, str(driver)], "junit": "report.xml"}]})
        baseline = self.dir / "skip-baseline.json"
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        flag.write_text("skip", encoding="utf-8")
        result = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_checks_runs_all_commands_even_if_one_fails_without_report(self):
        marker = self.dir / "second-ran"
        spec = self.write_json("spec.json", {"commands": [
            {"name": "broken", "argv": [sys.executable, "-c", "raise SystemExit(3)"], "junit": "absent.xml"},
            {"name": "second", "argv": [sys.executable, "-c", "from pathlib import Path; Path('second-ran').write_text('yes')"], "junit": "also-absent.xml"},
        ]})
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(marker.exists(), result.stdout + result.stderr)

    def test_checks_tracks_non_junit_failures_and_preserves_the_baseline(self):
        driver = self.dir / "lint.py"
        driver.write_text(
            "from pathlib import Path\nimport sys\n"
            "value=Path('lint-state').read_text()\n"
            "print(value)\n"
            "sys.exit(0 if value == 'ok' else 1)\n", encoding="utf-8")
        state = self.dir / "lint-state"
        state.write_text("old failure", encoding="utf-8")
        self.track(driver, state)
        spec = self.write_json("lint-spec.json", {"commands": [{
            "name": "lint", "argv": [sys.executable, str(driver)]}]})
        baseline = self.dir / "lint-baseline.json"
        def invoke(mode):
            return self.run_script("checks", mode, "--spec", spec, "--baseline", baseline)
        first = invoke("baseline")
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
        original = baseline.read_bytes()
        same = invoke("compare")
        self.assertEqual(same.returncode, 0, same.stderr + same.stdout)
        self.assertIn("old failure", same.stderr + same.stdout)
        state.write_text("changed failure", encoding="utf-8")
        self.assertNotEqual(invoke("compare").returncode, 0)
        self.assertNotEqual(invoke("baseline").returncode, 0)
        self.assertEqual(baseline.read_bytes(), original)
        state.write_text("ok", encoding="utf-8")
        self.assertEqual(invoke("compare").returncode, 0)
        baseline.unlink()
        fresh = self.dir / "passing-baseline.json"
        self.track(state)
        self.assertEqual(self.run_script("checks", "baseline", "--spec", spec, "--baseline", fresh).returncode, 0)
        state.write_text("new failure", encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", "--spec", spec, "--baseline", fresh).returncode, 0)

    def test_checks_baseline_records_clean_start_commit_and_retains_it_during_edits(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        tracked = self.dir / "tracked.txt"
        tracked.write_text("dirty before baseline", encoding="utf-8")
        dirty = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(dirty.returncode, 0, dirty.stdout + dirty.stderr)
        self.assertFalse(baseline.exists())
        subprocess.run(["git", "-C", str(self.dir), "add", "tracked.txt"], check=True, capture_output=True)
        staged = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(staged.returncode, 0, staged.stdout + staged.stderr)
        self.assertFalse(baseline.exists())
        subprocess.run(["git", "-C", str(self.dir), "reset", "-q", "HEAD", "--", "tracked.txt"], check=True, capture_output=True)
        tracked.write_text("starting content", encoding="utf-8")
        first = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        self.assertEqual(json.loads(baseline.read_text(encoding="utf-8"))["commit"], self.start_commit)
        tracked.write_text("legitimate implementation edit", encoding="utf-8")
        after = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertEqual(after.returncode, 0, after.stdout + after.stderr)
        self.assertEqual(json.loads(baseline.read_text(encoding="utf-8"))["commit"], self.start_commit)

    def test_checks_requires_explicit_untracked_inputs_and_records_their_hashes(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        untracked = self.dir / "context.txt"
        untracked.write_text("starting context", encoding="utf-8")
        args = ("--spec", spec, "--baseline", baseline)
        rejected = self.run_script("checks", "baseline", *args)
        self.assertNotEqual(rejected.returncode, 0, rejected.stdout + rejected.stderr)
        self.assertFalse(baseline.exists())
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["allowed_untracked"] = ["context.txt"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        accepted = self.run_script("checks", "baseline", *args)
        self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)
        raw = baseline.read_text(encoding="utf-8")
        self.assertIn("context.txt", raw)
        self.assertIn(hashlib.sha256(untracked.read_bytes()).hexdigest(), raw)
        (self.dir / "new-implementation.py").write_text("new work", encoding="utf-8")
        unchanged = self.run_script("checks", "compare", *args)
        self.assertEqual(unchanged.returncode, 0, unchanged.stdout + unchanged.stderr)
        untracked.write_text("changed context", encoding="utf-8")
        changed = self.run_script("checks", "compare", *args)
        self.assertNotEqual(changed.returncode, 0, changed.stdout + changed.stderr)

    def test_checks_rejects_escaping_and_symlink_allowed_inputs(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["allowed_untracked"] = ["../outside.txt"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline).returncode, 0)
        outside = self.dir.parent / (self.dir.name + "-outside.txt")
        outside.write_text("outside", encoding="utf-8")
        self.addCleanup(outside.unlink)
        link = self.dir / "link.txt"
        try:
            link.symlink_to(outside)
        except OSError:
            self.skipTest("creating symlinks is unavailable")
        data["allowed_untracked"] = ["link.txt"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline).returncode, 0)

    def test_checks_rejects_ignored_input_unless_explicitly_hashed(self):
        ignore = self.dir / ".gitignore"
        ignore.write_text("local-config.json\n", encoding="utf-8")
        self.track(ignore)
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        hidden = self.dir / "local-config.json"
        hidden.write_text('{"rule":"original"}', encoding="utf-8")
        args = ("--spec", spec, "--baseline", baseline)
        rejected = self.run_script("checks", "baseline", *args)
        self.assertNotEqual(rejected.returncode, 0, rejected.stdout + rejected.stderr)
        self.assertFalse(baseline.exists())
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["allowed_untracked"] = ["local-config.json"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        accepted = self.run_script("checks", "baseline", *args)
        self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)
        raw = baseline.read_text(encoding="utf-8")
        self.assertIn("local-config.json", raw)
        self.assertIn(hashlib.sha256(hidden.read_bytes()).hexdigest(), raw)
        same = self.run_script("checks", "compare", *args)
        self.assertEqual(same.returncode, 0, same.stdout + same.stderr)
        hidden.write_text('{"rule":"changed"}', encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def compatibility_fixture(self):
        spec = self.check_spec([{"name": "one"}])
        site = self.dir / "site"
        site.mkdir()
        lock = site / "package-lock.json"
        lock.write_text('{"lockfileVersion":3}', encoding="utf-8")
        self.track(lock)
        work = self.dir / ".aid/works/work-001-example"
        work.mkdir(parents=True)
        state = work / "STATE.yml"
        state.write_text("lifecycle: Running\n", encoding="utf-8")
        tmp = tempfile.TemporaryDirectory(prefix="aid-lean-dependencies-")
        self.addCleanup(tmp.cleanup)
        dependency = Path(tmp.name)
        (dependency / "package.js").write_text("module.exports = 1;\n", encoding="utf-8")
        link = site / "node_modules"
        try:
            link.symlink_to(dependency, target_is_directory=True)
        except OSError:
            self.skipTest("creating directory symlinks is unavailable")
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["work_states"] = [".aid/works/work-001-example/STATE.yml"]
        data["dependency_links"] = [{"path": "site/node_modules", "target": str(dependency.resolve()),
                                     "lockfile": "site/package-lock.json"}]
        spec.write_text(json.dumps(data), encoding="utf-8")
        self.script_env = dict(os.environ, AID_STATE_FILE=str(state), AID_WORK_DIR=str(work))
        return spec, state, link, dependency, lock

    def test_checks_accepts_declared_mutable_state_and_pinned_dependency(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        evidence = json.loads(baseline.read_text(encoding="utf-8"))
        self.assertEqual(evidence["work_states"][".aid/works/work-001-example/STATE.yml"],
                         hashlib.sha256(state.read_bytes()).hexdigest())
        self.assertIn("site/node_modules", evidence["dependency_links"])
        state.write_text("lifecycle: Running\nupdated: later\n", encoding="utf-8")
        same = self.run_script("checks", "compare", *args)
        self.assertEqual(same.returncode, 0, same.stdout + same.stderr)
        self.assertIn(hashlib.sha256(state.read_bytes()).hexdigest(), same.stdout)
        self.write_json("cases.json", [{"name": "one", "failure": "new"}])
        changed = self.run_script("checks", "compare", *args)
        self.assertNotEqual(changed.returncode, 0, changed.stdout + changed.stderr)
        self.assertIn("new or changed failure", changed.stderr)

    def test_checks_rejects_changed_or_missing_declared_state_and_policy(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        contents = state.read_text(encoding="utf-8")
        state.unlink()
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)
        state.write_text(contents, encoding="utf-8")
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["work_states"] = []
        spec.write_text(json.dumps(data), encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)
        data["work_states"] = ["tracked.txt"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_rejects_mutated_dependencies_and_lockfile(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        package = dependency / "package.js"
        original = package.read_bytes()
        package.write_text("module.exports = 2;\n", encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)
        package.write_bytes(original)
        (dependency / "unexpected.js").write_text("new", encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)
        (dependency / "unexpected.js").unlink()
        lock.write_text('{"lockfileVersion":4}', encoding="utf-8")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_rejects_retargeted_and_escaping_dependency_links(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        link.unlink()
        link.symlink_to(self.dir, target_is_directory=True)
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)
        link.unlink()
        link.symlink_to(dependency, target_is_directory=True)
        nested = dependency / "escape"
        nested.symlink_to(self.dir / "tracked.txt")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_cannot_unlink_declared_work_state_as_a_report(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["commands"][0]["junit"] = ".aid/works/work-001-example/STATE.yml"
        spec.write_text(json.dumps(data), encoding="utf-8")
        before = state.read_bytes()
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(state.read_bytes(), before)

    def test_checks_rejects_unrelated_inputs_and_untracked_lockfile(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        extra = self.dir / "unrelated.txt"
        extra.write_text("do not hide me", encoding="utf-8")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unrelated.txt", result.stderr)
        extra.unlink()
        subprocess.run(["git", "-C", str(self.dir), "rm", "--cached", "--", "site/package-lock.json"],
                       check=True, capture_output=True)
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("lockfile must be tracked", result.stderr)

    def test_checks_rejects_a_dependency_changed_during_baseline(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["commands"][0]["argv"] = [sys.executable, "-c",
            "from pathlib import Path; Path('site/node_modules/package.js').write_text('changed'); "
            "Path('result.xml').write_text('<testsuite><testcase name=\"one\"/></testsuite>')"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        baseline = self.dir / "baseline.json"
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(baseline.exists())
        self.assertIn("stable inputs changed", result.stderr)

    def test_checks_rejects_tracked_changes_during_baseline(self):
        spec = self.check_spec([{"name": "one"}])
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["commands"][0]["argv"] = [sys.executable, "-c",
            "from pathlib import Path; Path('tracked.txt').write_text('changed'); "
            "Path('result.xml').write_text('<testsuite><testcase name=\"one\"/></testsuite>')"]
        spec.write_text(json.dumps(data), encoding="utf-8")
        baseline = self.dir / "baseline.json"
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(baseline.exists())
        self.assertIn("tracked changes", result.stderr)

    def test_checks_accepts_safe_internal_dependency_symlinks(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        (dependency / ".bin").mkdir()
        internal = dependency / ".bin/tool"
        try:
            internal.symlink_to("../package.js")
        except OSError:
            self.skipTest("creating file symlinks is unavailable")
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        self.assertEqual(self.run_script("checks", "compare", *args).returncode, 0)
        internal.unlink()
        internal.symlink_to("../missing.js")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_rejects_indirect_directory_symlink_cycles(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        left, right = dependency / "left", dependency / "right"
        left.mkdir()
        right.mkdir()
        try:
            (left / "to-right").symlink_to("../right", target_is_directory=True)
            (right / "to-left").symlink_to("../left", target_is_directory=True)
        except OSError:
            self.skipTest("creating directory symlinks is unavailable")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cycle", result.stderr)

    @unittest.skipUnless(os.name == "nt", "Windows junction test")
    def test_checks_rejects_windows_junction_without_is_junction(self):
        spec = importlib.util.spec_from_file_location("baseline_checks", SCRIPTS / "checks.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        target, junction = self.dir / "junction-target", self.dir / "junction"
        target.mkdir()
        made = subprocess.run(["cmd", "/c", "mklink", "/J", str(junction), str(target)],
                              capture_output=True, text=True)
        if made.returncode:
            self.skipTest("junction creation unavailable: " + made.stderr.strip())
        try:
            with mock.patch.object(Path, "is_junction", return_value=False, create=True):
                with self.assertRaisesRegex(ValueError, "may not contain links"):
                    module.unlinked_path(self.dir, "junction/file")
        finally:
            os.rmdir(junction)

    def test_checks_accepts_dirty_tracked_active_state_only(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        subprocess.run(["git", "add", "-f", str(state.relative_to(self.dir))], cwd=self.dir, check=True)
        subprocess.run(["git", "commit", "-qm", "track state"], cwd=self.dir, check=True)
        state.write_text("status: Running\n", encoding="utf-8")
        baseline = self.dir / "baseline.json"
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(baseline.read_text())["work_states"][state.relative_to(self.dir).as_posix()],
                         hashlib.sha256(state.read_bytes()).hexdigest())

    def test_checks_accepts_multiple_links_sharing_a_lockfile(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        second = self.dir / "second/node_modules"
        second.parent.mkdir()
        try:
            second.symlink_to(dependency, target_is_directory=True)
        except OSError:
            self.skipTest("creating directory symlinks is unavailable")
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["dependency_links"].append({"path": "second/node_modules", "target": str(dependency),
                                         "lockfile": "site/package-lock.json"})
        spec.write_text(json.dumps(data), encoding="utf-8")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_checks_requires_the_literal_declared_lockfile_to_be_tracked(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        tracked = self.dir / "site/a.lock"
        tracked.write_text("tracked", encoding="utf-8")
        subprocess.run(["git", "add", "site/a.lock"], cwd=self.dir, check=True)
        subprocess.run(["git", "commit", "-qm", "add lock"], cwd=self.dir, check=True)
        literal = self.dir / "site/[abc].lock"
        literal.write_text("untracked", encoding="utf-8")
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["dependency_links"][0]["lockfile"] = "site/[abc].lock"
        spec.write_text(json.dumps(data), encoding="utf-8")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("lockfile must be tracked", result.stderr)

    def test_checks_rejects_dependency_pointing_into_worktree_git_metadata(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        worktree = self.dir.parent / (self.dir.name + "-linked-worktree")
        subprocess.run(["git", "worktree", "add", "--detach", str(worktree)], cwd=self.dir,
                       check=True, capture_output=True)
        try:
            git_dir = Path(subprocess.run(["git", "rev-parse", "--absolute-git-dir"], cwd=worktree,
                                          check=True, capture_output=True, text=True).stdout.strip())
            data = json.loads(spec.read_text(encoding="utf-8"))
            worktree_spec = worktree / "spec.json"
            link_path = worktree / "site/node_modules"
            link_path.symlink_to(git_dir, target_is_directory=True)
            data["work_states"] = []
            data["dependency_links"][0]["target"] = str(git_dir)
            worktree_spec.write_text(json.dumps(data), encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPTS / "checks.py"), "baseline", "--spec",
                                     str(worktree_spec), "--baseline", str(worktree / "baseline.json")],
                                    cwd=worktree, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Git metadata", result.stderr)
        finally:
            subprocess.run(["git", "worktree", "remove", "--force", str(worktree)], cwd=self.dir,
                           check=True, capture_output=True)

    def test_checks_preserves_unknown_or_tampered_report_receipts(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        receipt = Path(str(baseline) + ".reports.json")
        receipt.write_text("user data", encoding="utf-8")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(receipt.read_text(encoding="utf-8"), "user data")
        receipt.unlink()
        first = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        report = self.dir / "result.xml"
        before = report.read_bytes()
        receipt.write_text("tampered", encoding="utf-8")
        result = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(receipt.read_text(encoding="utf-8"), "tampered")
        self.assertEqual(report.read_bytes(), before)

    def test_checks_rejects_report_alias_to_declared_state_before_unlink(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        alias = self.dir / "alias.xml"
        try:
            alias.symlink_to(state)
        except OSError:
            self.skipTest("creating file symlinks is unavailable")
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["commands"][0]["junit"] = "alias.xml"
        spec.write_text(json.dumps(data), encoding="utf-8")
        before = state.read_bytes()
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(state.read_bytes(), before)
        self.assertTrue(alias.is_symlink())

    def test_checks_compares_legacy_baselines_without_new_declarations(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        old = json.loads(baseline.read_text(encoding="utf-8"))
        old.pop("work_states")
        old.pop("dependency_links")
        baseline.write_text(json.dumps(old), encoding="utf-8")
        Path(str(baseline) + ".reports.json").unlink()
        report = self.dir / "result.xml"
        before = report.read_bytes()
        refused = self.run_script("checks", "compare", *args)
        self.assertNotEqual(refused.returncode, 0)
        self.assertEqual(report.read_bytes(), before)
        report.rename(self.dir / "preserved-old-result.xml")
        result = self.run_script("checks", "compare", *args)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_checks_binds_declared_state_to_the_active_work_environment(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        self.script_env.pop("AID_STATE_FILE")
        self.assertNotEqual(self.run_script("checks", "baseline", *args).returncode, 0)
        self.script_env["AID_STATE_FILE"] = str(state)
        self.script_env["AID_WORK_DIR"] = str(state.parent.parent)
        self.assertNotEqual(self.run_script("checks", "baseline", *args).returncode, 0)
        self.script_env["AID_WORK_DIR"] = str(state.parent)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        self.script_env["AID_STATE_FILE"] = str(self.dir / "tracked.txt")
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_records_dependency_root_mode(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        if os.name == "nt":
            self.skipTest("POSIX dependency mode semantics unavailable")
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        original = dependency.stat().st_mode
        dependency.chmod(original ^ 0o100)
        self.addCleanup(dependency.chmod, original)
        self.assertNotEqual(self.run_script("checks", "compare", *args).returncode, 0)

    def test_checks_rejects_a_different_checkout_revision(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        args = ("--spec", spec, "--baseline", baseline)
        first = self.run_script("checks", "baseline", *args)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        (self.dir / "tracked.txt").write_text("new commit", encoding="utf-8")
        self.track("tracked.txt")
        result = self.run_script("checks", "compare", *args)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("checkout revision", result.stderr)

    def test_checks_preserves_existing_untracked_or_git_report_paths(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        report = self.dir / "result.xml"
        report.write_text("user data", encoding="utf-8")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report.read_text(encoding="utf-8"), "user data")
        report.unlink()
        data = json.loads(spec.read_text(encoding="utf-8"))
        data["commands"][0]["junit"] = ".git/config"
        spec.write_text(json.dumps(data), encoding="utf-8")
        config = self.dir / ".git/config"
        before = config.read_bytes()
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(config.read_bytes(), before)

    def test_checks_preserves_tracked_or_replaced_junit_reports(self):
        spec = self.check_spec([{"name": "one"}])
        baseline = self.dir / "baseline.json"
        report = self.dir / "result.xml"
        report.write_text("tracked user data", encoding="utf-8")
        self.track(report)
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report.read_text(encoding="utf-8"), "tracked user data")
        subprocess.run(["git", "-C", str(self.dir), "rm", "-q", "--", "result.xml"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.dir), "commit", "-qm", "remove report"], check=True, capture_output=True)
        first = self.run_script("checks", "baseline", "--spec", spec, "--baseline", baseline)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        report.write_text("user changed report", encoding="utf-8")
        result = self.run_script("checks", "compare", "--spec", spec, "--baseline", baseline)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report.read_text(encoding="utf-8"), "user changed report")

    def test_checks_rejects_hardlinked_work_state(self):
        spec, state, link, dependency, lock = self.compatibility_fixture()
        state.unlink()
        try:
            os.link(self.dir / "tracked.txt", state)
        except OSError:
            self.skipTest("creating hard links is unavailable")
        result = self.run_script("checks", "baseline", "--spec", spec, "--baseline", self.dir / "baseline.json")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.dir / "tracked.txt").read_text(encoding="utf-8"), "starting content")

    def test_instruction_line_budgets(self):
        skill = ROOT / "canonical" / "skills" / "aid-change"
        for path, limit in ((skill / "SKILL.md", 100), (skill / "references" / "review.md", 60)):
            with self.subTest(path=path):
                lines = len(path.read_text(encoding="utf-8").splitlines())
                self.assertLessEqual(lines, limit, f"{path} has {lines} lines; budget is {limit}")

    def test_site_review_requires_rendered_and_content_evidence(self):
        review = (ROOT / "canonical/skills/aid-change/references/review.md").read_text(encoding="utf-8")
        for required in ("visible raw Markdown table separators", "code examples",
                         "changed documentation pages", "before and after",
                         "explain how to", "unverified"):
            with self.subTest(required=required):
                self.assertIn(required, review)

    def test_change_requires_relevant_facts_to_become_outcome_checks(self):
        skill = (ROOT / "canonical/skills/aid-change/SKILL.md").read_text(encoding="utf-8")
        planned = (ROOT / "canonical/skills/aid-change/references/planned.md").read_text(encoding="utf-8")
        review = (ROOT / "canonical/skills/aid-change/references/review.md").read_text(encoding="utf-8")
        for text, required in (
            (skill, "relevant KB facts and project rules"),
            (skill, "verify them against current source"),
            (skill, "required outcome without evidence as unverified"),
            (skill, "do not report the task complete"),
            (planned, "user-visible outcomes"),
            (planned, "plausible incomplete result"),
            (planned, "removed or replaced behavior"),
            (review, "relevant KB facts and project rules"),
            (review, "positive outcome evidence"),
        ):
            with self.subTest(required=required):
                self.assertIn(required, text)

    def test_claude_shell_safeguard_decisions_and_invalid_input(self):
        # Direct invocations only: shell aliases, indirection, bypasses, other
        # tools and other hosts are intentionally outside this test's proof.
        handler = SCRIPTS / "safeguard.py"
        cases = [
            ("Bash", "git merge feature", "deny"),
            ("Bash", "gh pr merge 12", "deny"),
            ("Bash", "git push origin work-004", "ask"),
            ("Bash", "git -C /tmp/project push origin branch", "ask"),
            ("Bash", "git status && git push origin branch", "ask"),
            ("Bash", "git status | git push origin branch", "ask"),
            ("PowerShell", "git push origin branch", "ask"),
            ("Bash", "git status --short", None),
        ]
        for tool, command, expected in cases:
            with self.subTest(tool=tool, command=command):
                result = subprocess.run([sys.executable, str(handler)], cwd=str(self.dir),
                    input=json.dumps({"tool_name": tool, "tool_input": {"command": command}}),
                    capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                output = json.loads(result.stdout) if result.stdout.strip() else {}
                decision = output.get("hookSpecificOutput", {}).get("permissionDecision")
                self.assertEqual(decision, expected, output)
                if decision:
                    self.assertEqual(output["hookSpecificOutput"].get("hookEventName"), "PreToolUse")
        invalid = subprocess.run([sys.executable, str(handler)], cwd=str(self.dir),
                                 input="{", capture_output=True, text=True)
        self.assertNotEqual(invalid.returncode, 0)

    def test_claude_skill_registers_safeguard_for_both_shell_tools(self):
        # This validates the skill declaration, not host approval or enforcement.
        path = ROOT / "canonical/skills/aid-change/SKILL.md"
        parts = path.read_text(encoding="utf-8").split("---", 2)
        self.assertEqual(parts[0].strip(), "")
        frontmatter = parts[1]
        command = 'python3 "$CLAUDE_PROJECT_DIR/.aid/runtime/scripts/change/safeguard.py"'
        try:
            import yaml
        except ImportError:
            match = re.search(r"(?ms)^hooks:\s*\n(.*?)(?=^[a-z][\w-]*:|\Z)", frontmatter)
            self.assertIsNotNone(match, "hooks frontmatter missing")
            self.assertRegex(match.group(1), r"(?m)^\s+PreToolUse:\s*$")
            self.assertRegex(match.group(1), r"(?m)^\s+-\s+matcher:\s*['\"]?Bash\|PowerShell['\"]?\s*$")
            self.assertRegex(match.group(1), r"(?m)^\s+-\s+type:\s*command\s*$")
            self.assertIn(command, match.group(1))
        else:
            entries = yaml.safe_load(frontmatter)["hooks"]["PreToolUse"]
            self.assertTrue(any(entry.get("matcher") == "Bash|PowerShell" and
                any(hook.get("type") == "command" and hook.get("command") == command
                    for hook in entry.get("hooks", [])) for entry in entries))

    def test_trace_requires_both_directions_and_nonempty_task_links(self):
        data = {"criteria": ["C1", "C2"], "tasks": [{"id": "T1", "criteria": ["C1"]}, {"id": "T2", "criteria": ["C2"]}]}
        path = self.write_json("trace.json", data)
        self.assertEqual(self.run_script("trace", "--file", path).returncode, 0)
        for tasks in ([{"id": "T1", "criteria": ["C1"]}],
                      [{"id": "T1", "criteria": ["C1", "C2", "C3"]}],
                      [{"id": "T1", "criteria": ["C1", "C2"]}, {"id": "T2", "criteria": []}]):
            data["tasks"] = tasks
            self.write_json("trace.json", data)
            with self.subTest(tasks=tasks):
                self.assertNotEqual(self.run_script("trace", "--file", path).returncode, 0)

    def test_state_writes_complete_json_and_bad_input_preserves_old_state(self):
        state = self.dir / "state.json"
        data = {"goal": "Ship a fix", "plan": [{"task": "check", "done": False}], "milestones": [], "decisions": ["review"], "budget_used": 1.5}
        result = self.run_script("state", "--file", state, "--data", json.dumps(data))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(state.read_text(encoding="utf-8")), data)
        before = state.read_bytes()
        result = self.run_script("state", "--file", state, "--data", "not JSON")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(state.read_bytes(), before)

    def test_red_first_runs_tests_on_old_revision_without_mutating_repo(self):
        repo = self.dir / "repo"
        repo.mkdir()
        def git(*args):
            return subprocess.run(["git", "-C", str(repo), *args], check=True, text=True, capture_output=True).stdout.strip()
        git("init", "-q")
        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        (repo / "value.txt").write_text("old", encoding="utf-8")
        git("add", "value.txt")
        git("commit", "-qm", "old")
        rev = git("rev-parse", "HEAD")
        (repo / "value.txt").write_text("new", encoding="utf-8")
        tests = self.dir / "new-tests"
        tests.mkdir()
        (tests / "probe.py").write_text(
            "from pathlib import Path\nimport sys\n"
            "bad=Path('value.txt').read_text() == 'old'\n"
            "Path('report.xml').write_text('<testsuite tests=\"1\"><testcase name=\"probe\">' + ('<failure message=\"old\"/>' if bad else '') + '</testcase></testsuite>')\n"
            "sys.exit(1 if bad else 0)\n", encoding="utf-8")
        args = ("--repo", repo, "--revision", rev, "--tests", tests, "--junit", "report.xml", "--", sys.executable, "new-tests/probe.py")
        result = self.run_script("red-first", *args)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertEqual((repo / "value.txt").read_text(), "new")
        self.assertFalse((repo / "new-tests").exists())
        # An infrastructure failure or a passing test is not a verified red test.
        broken = self.run_script("red-first", "--repo", repo, "--revision", rev, "--tests", tests, "--junit", "report.xml", "--", "missing-command-aid")
        self.assertNotEqual(broken.returncode, 0)
        (tests / "probe.py").write_text("from pathlib import Path\nPath('report.xml').write_text('<testsuite tests=\"1\"><testcase name=\"probe\"/></testsuite>')\n", encoding="utf-8")
        self.assertNotEqual(self.run_script("red-first", *args).returncode, 0)

    def test_red_first_overlays_changed_tests_in_copy_and_rejects_incomplete_red(self):
        repo = self.dir / "old-repo"
        repo.mkdir()
        def git(*args):
            return subprocess.run(["git", "-C", str(repo), *args], check=True, text=True, capture_output=True).stdout.strip()
        git("init", "-q")
        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        (repo / "tests").mkdir()
        (repo / "tests" / "existing.txt").write_text("old", encoding="utf-8")
        git("add", "tests")
        git("commit", "-qm", "old")
        rev = git("rev-parse", "HEAD")
        incoming = self.dir / "tests"
        incoming.mkdir()
        probe = incoming / "probe.py"
        def write_probe(cases):
            probe.write_text(
                "from pathlib import Path\nimport sys\n"
                "assert Path('tests/existing.txt').read_text() == 'old'\n"
                "Path('report.xml').write_text(" + repr('<testsuite>' + cases + '</testsuite>') + ")\n"
                "sys.exit(1)\n", encoding="utf-8")
        args = ("--repo", repo, "--revision", rev, "--tests", incoming,
                "--junit", "report.xml", "--", sys.executable, "tests/probe.py")
        write_probe('<testcase name="new"><failure message="expected"/></testcase>')
        result = self.run_script("red-first", *args)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((repo / "tests" / "existing.txt").read_text(), "old")
        external = self.dir / "outside.txt"
        external.write_text("private", encoding="utf-8")
        try:
            (incoming / "escape.txt").symlink_to(external)
        except OSError:
            pass  # Some Windows accounts cannot create symlinks.
        else:
            self.assertNotEqual(self.run_script("red-first", *args).returncode, 0)
            self.assertEqual(external.read_text(), "private")
            (incoming / "escape.txt").unlink()
        self.assertFalse((repo / "tests" / "probe.py").exists())
        write_probe('<testcase name="red"><failure message="expected"/></testcase><testcase name="already-green"/>')
        self.assertNotEqual(self.run_script("red-first", *args).returncode, 0)
        write_probe('<testcase name="skipped"><skipped/></testcase>')
        self.assertNotEqual(self.run_script("red-first", *args).returncode, 0)
        (incoming / "existing.txt").write_text("replace", encoding="utf-8")
        probe.write_text(
            "from pathlib import Path\nimport sys\n"
            "assert Path('tests/existing.txt').read_text() == 'replace'\n"
            "Path('report.xml').write_text('<testsuite><testcase name=\"new\"><failure message=\"expected\"/></testcase></testsuite>')\n"
            "sys.exit(1)\n", encoding="utf-8")
        result = self.run_script("red-first", *args)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((repo / "tests" / "existing.txt").read_text(), "old")


class MeasurementModes(unittest.TestCase):
    """Run the real argument handling with mocked turns; never launch a model."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="aid-mode-test-")
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)
        path = ROOT / "tests" / "measure"
        sys.path.insert(0, str(path))
        self.addCleanup(sys.path.remove, str(path))
        old = sys.dont_write_bytecode
        sys.dont_write_bytecode = True
        self.addCleanup(setattr, sys, "dont_write_bytecode", old)
        spec = importlib.util.spec_from_file_location("aid_measure_test", path / "measure.py")
        self.measure = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.measure)
        spec = importlib.util.spec_from_file_location("aid_repo_task_test", path / "repo_task.py")
        self.repo = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.repo)

    def result(self, message, *args):
        message.append(args[3])
        return {"session": "test", "result": {"result": "done", "usage": {}},
                "tools": {}, "dispatches": 0, "writer_calls": 0, "start_context": 0}

    def test_bash_path_converts_windows_drives_and_preserves_posix(self):
        self.assertEqual(self.measure.bash_path("C:/Users/andre/AID bundle"), "/c/Users/andre/AID bundle")
        self.assertEqual(self.measure.bash_path(r"D:\projects\AID\nested"), "/d/projects/AID/nested")
        self.assertEqual(self.measure.bash_path("C:/"), "/c/")
        self.assertEqual(self.measure.bash_path("/tmp/aid bundle/sub"), "/tmp/aid bundle/sub")
        self.assertEqual(self.measure.bash_path(Path("/tmp/aid bundle")), "/tmp/aid bundle")

    def measure_prompt(self, flags):
        messages = []
        project = self.dir / "fixture"
        project.mkdir(exist_ok=True)
        grade = {"hidden_pass": True, "tests_pass": True, "code_files_changed": 1}
        with mock.patch.object(sys, "argv", ["measure.py", "--scenario", "fix", "--runs", "1", "--turns", "1", *flags]), \
             mock.patch.object(self.measure, "setup", return_value=(project, {})), \
             mock.patch.object(self.measure, "turn", side_effect=lambda *a: self.result(messages, *a)), \
             mock.patch.object(self.measure, "locations", return_value=[project]), \
             mock.patch.object(self.measure, "grade", return_value=grade), \
             mock.patch.object(self.measure.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "", "")), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(self.measure.main(), 0)
        return messages[0]

    def repo_prompt(self, flags):
        messages = []
        project = self.dir / "repo"
        project.mkdir(exist_ok=True)
        if "--lean" in flags:
            bundle = self.dir / "lean-bundle"
            bundle.mkdir(exist_ok=True)
            flags = [*flags, "--lean-bundle", str(bundle)]
        with mock.patch.object(sys, "argv", ["repo_task.py", "--out", str(self.dir / "run"), "--turns", "1", *flags]), \
             mock.patch.object(self.repo, "setup", return_value=(project, {})), \
             mock.patch.object(self.repo, "turn", side_effect=lambda *a: self.result(messages, *a)), \
             mock.patch.object(self.repo, "run", return_value=subprocess.CompletedProcess([], 0, "test-revision\n", "")), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(self.repo.main(), 0)
        return messages[0]

    def test_lean_and_existing_modes_choose_expected_initial_request(self):
        for driver in (self.measure_prompt, self.repo_prompt):
            with self.subTest(driver=driver.__name__):
                self.assertTrue(driver(["--lean"]).startswith("/aid-change "))
                plain = driver(["--no-aid"])
                self.assertFalse(plain.startswith("/aid-"))
                default = driver([])
                if driver == self.repo_prompt:
                    self.assertTrue(default.startswith("/aid-describe "))
                else:
                    self.assertFalse(default.startswith("/aid-"))

    def test_lean_and_no_aid_are_rejected_before_any_run(self):
        for module, argv in ((self.measure, ["measure.py", "--lean", "--no-aid"]),
                             (self.repo, ["repo_task.py", "--out", str(self.dir / "conflict"), "--lean", "--no-aid"])):
            with self.subTest(module=module.__name__), mock.patch.object(sys, "argv", argv), \
                 mock.patch.object(module, "setup", side_effect=AssertionError("setup must not run")), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as err:
                    module.main()
                self.assertNotEqual(err.exception.code, 0)

    def test_report_separates_lean_full_and_legacy_plain_runs(self):
        records = []
        for aid, mode, cost in ((True, "lean", 0.20), (True, "aid", 4.00),
                                (True, None, 6.00), (False, "plain", 0.10),
                                (False, None, 0.30)):
            row = {"scenario": "fix", "aid": aid, "model": "known-model", "start_context_tokens": 100,
                   "cache_write_tokens": 100, "cost_usd": cost, "seconds": 1,
                   "hidden_pass": True}
            if mode is not None:
                row["mode"] = mode
            records.append(row)
        path = self.dir / "runs.jsonl"
        path.write_text("".join(json.dumps(row) + "\n" for row in records), encoding="utf-8")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(self.measure.report([str(path)]), 0)
        rows = [line.split() for line in output.getvalue().splitlines()
                if line.split() and line.split()[0] == "fix"]
        by_mode = {row[1]: row for row in rows}
        self.assertEqual(set(by_mode), {"lean", "aid", "plain"})
        for mode, count, median_cost in (("lean", "1", "$0.20"),
                                         ("aid", "2", "$5.00"),
                                         ("plain", "2", "$0.20")):
            with self.subTest(mode=mode):
                self.assertEqual(by_mode[mode][2], count)
                self.assertIn(median_cost, by_mode[mode])

    def test_lean_brownfield_setup_installs_requested_bundle_and_fails_closed(self):
        bundle = self.dir / "bundle"
        bundle.mkdir()
        calls = []
        def native_target(value):
            # The real installer receives Git Bash paths; map them back only for
            # this fake's marker writes on Windows, without touching the host root.
            match = re.match(r"^/([a-zA-Z])/(.*)$", str(value)) if os.name == "nt" else None
            return Path(match.group(1).upper() + ":/" + match.group(2)) if match else Path(value)
        def fake_run(command, cwd, env, *args):
            calls.append(command)
            if command[:2] == ["git", "clone"]:
                project = Path(command[-1])
                (project / ".aid").mkdir(parents=True)
            if "--from-bundle" in command:
                project = native_target(command[command.index("--target") + 1])
                for marker in (".claude/skills/aid-change/SKILL.md", ".aid/runtime/scripts/change/checks.py"):
                    target = project / marker
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("installed", encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "", "")
        out = self.dir / "historical"
        out.mkdir()
        with mock.patch.object(self.repo, "run", side_effect=fake_run), \
             mock.patch.object(self.repo.shutil, "copytree"), \
             mock.patch.dict(os.environ, {"CLAUDE_CODE_OAUTH_TOKEN": "test-placeholder"}):
            project, _ = self.repo.setup(out, "site", True, "old-revision", lean_bundle=bundle)
        install = [cmd for cmd in calls if "--from-bundle" in cmd]
        self.assertEqual(len(install), 1)
        self.assertIn("update", install[0])
        self.assertEqual(native_target(install[0][install[0].index("--from-bundle") + 1]), bundle)
        self.assertEqual(native_target(install[0][install[0].index("--target") + 1]), project)
        self.assertTrue((project / ".claude/skills/aid-change/SKILL.md").is_file())
        self.assertTrue((project / ".aid/runtime/scripts/change/checks.py").is_file())

        def fail_install(command, cwd, env, *args):
            if command[:2] == ["git", "clone"]:
                (Path(command[-1]) / ".aid").mkdir(parents=True)
            return subprocess.CompletedProcess(command, 1 if "--from-bundle" in command else 0, "", "install failed")
        failed = self.dir / "failed"
        failed.mkdir()
        with mock.patch.object(self.repo, "run", side_effect=fail_install), \
             mock.patch.object(self.repo.shutil, "copytree"), \
             mock.patch.dict(os.environ, {"CLAUDE_CODE_OAUTH_TOKEN": "test-placeholder"}):
            with self.assertRaises(SystemExit):
                self.repo.setup(failed, "site", True, "old-revision", lean_bundle=bundle)

        no_aid_calls = []
        def fake_add(command, cwd, env, *args):
            no_aid_calls.append(command)
            if command[:2] == ["git", "clone"]:
                Path(command[-1]).mkdir(parents=True)
            if "--from-bundle" in command:
                project = native_target(command[command.index("--target") + 1])
                for marker in (".claude/skills/aid-change/SKILL.md", ".aid/runtime/scripts/change/checks.py"):
                    target = project / marker
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("installed", encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "", "")
        fresh = self.dir / "without-aid"
        fresh.mkdir()
        with mock.patch.object(self.repo, "run", side_effect=fake_add), \
             mock.patch.object(self.repo.shutil, "copytree"), \
             mock.patch.dict(os.environ, {"CLAUDE_CODE_OAUTH_TOKEN": "test-placeholder"}):
            self.repo.setup(fresh, "site", True, "old-revision", lean_bundle=bundle)
        fresh_install = [cmd for cmd in no_aid_calls if "--from-bundle" in cmd]
        self.assertEqual(len(fresh_install), 1)
        self.assertIn("add", fresh_install[0])
        self.assertIn("claude-code", fresh_install[0])

        def no_markers(command, cwd, env, *args):
            if command[:2] == ["git", "clone"]:
                (Path(command[-1]) / ".aid").mkdir(parents=True)
            return subprocess.CompletedProcess(command, 0, "", "")
        invalid = self.dir / "no-markers"
        invalid.mkdir()
        with mock.patch.object(self.repo, "run", side_effect=no_markers), \
             mock.patch.object(self.repo.shutil, "copytree"), \
             mock.patch.dict(os.environ, {"CLAUDE_CODE_OAUTH_TOKEN": "test-placeholder"}):
            with self.assertRaises(SystemExit):
                self.repo.setup(invalid, "site", True, "old-revision", lean_bundle=bundle)

    def test_lean_brownfield_requires_bundle_before_setup(self):
        with mock.patch.object(sys, "argv", ["repo_task.py", "--out", str(self.dir / "missing"), "--lean"]), \
             mock.patch.object(self.repo, "setup", side_effect=AssertionError("setup must not run")), \
             contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as err:
                self.repo.main()
            self.assertNotEqual(err.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
