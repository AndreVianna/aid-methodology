"""Offline tests for the documentation-quality benchmark preparation and grader."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("quality_probe.py")


class QualityProbeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location("quality_probe", MODULE)
        cls.probe = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.probe)

    def test_stub_fails_and_prepare_never_overwrites(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "trial"
            project = self.probe.prepare(out)
            result = self.probe.grade(project)
            self.assertFalse(result["automated_pass"])
            self.assertFalse(result["outcome_checks"]["ordered_workflow"])
            self.assertEqual(result["browser_visual"], "not_run")
            with self.assertRaises(FileExistsError):
                self.probe.prepare(out)

    def test_complete_example_and_raw_table_are_distinguished(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = self.probe.prepare(Path(tmp) / "trial")
            page = project / "site" / "release.html"
            good = self.probe.EXAMPLE_COMPLETE
            page.write_text(good, encoding="utf-8")
            result = self.probe.grade(project)
            self.assertTrue(result["automated_pass"], result)
            self.assertEqual(result["browser_visual"], "not_run")
            # A table separator in an intentional code example is not a visible defect.
            page.write_text(good + "<pre><code>| --- | --- |</code></pre>", encoding="utf-8")
            self.assertTrue(self.probe.grade(project)["automated_pass"])
            page.write_text(good + "<p>| --- | --- |</p>", encoding="utf-8")
            result = self.probe.grade(project)
            self.assertFalse(result["automated_pass"])
            self.assertFalse(result["outcome_checks"]["no_raw_table_separator"])

    def test_correct_commands_hidden_or_misordered_do_not_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = self.probe.prepare(Path(tmp) / "trial")
            page = project / "site" / "release.html"
            page.write_text(
                '<main><h1>Release</h1><p hidden>preview approve publish</p>'
                '<p>publish, then approve, then preview</p></main>', encoding="utf-8")
            result = self.probe.grade(project)
            self.assertFalse(result["automated_pass"])
            self.assertFalse(result["outcome_checks"]["ordered_workflow"])

    def test_valid_python3_commands_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = self.probe.prepare(Path(tmp) / "trial")
            (project / "site/release.html").write_text(
                self.probe.EXAMPLE_COMPLETE.replace("python release.py", "python3 release.py"),
                encoding="utf-8")
            self.assertTrue(self.probe.grade(project)["automated_pass"])

    def test_changed_release_tool_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = self.probe.prepare(Path(tmp) / "trial")
            (project / "site/release.html").write_text(self.probe.EXAMPLE_COMPLETE, encoding="utf-8")
            (project / "release.py").write_text('print("published")\n', encoding="utf-8")
            result = self.probe.grade(project)
            self.assertFalse(result["automated_pass"])
            self.assertFalse(result["outcome_checks"]["release_tool_unchanged"])

    def test_header_only_table_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = self.probe.prepare(Path(tmp) / "trial")
            page = self.probe.EXAMPLE_COMPLETE
            page = page.replace('<tbody><tr><td>Preview</td><td>Review</td></tr></tbody>', '')
            (project / "site/release.html").write_text(page, encoding="utf-8")
            result = self.probe.grade(project)
            self.assertFalse(result["automated_pass"])
            self.assertFalse(result["outcome_checks"]["semantic_table"])


if __name__ == "__main__":
    unittest.main()
