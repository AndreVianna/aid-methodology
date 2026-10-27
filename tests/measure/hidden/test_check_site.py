"""Run with: python -m unittest discover -s tests/measure/hidden -p test_check_site.py"""

import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("check_site", Path(__file__).with_name("check_site.py"))
check_site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check_site)


class RawTableTests(unittest.TestCase):
    def test_detects_literal_table_delimiters_in_page_text(self):
        html = "<p>Name | Value<br>| :--- | ---: |<br>one | two</p><p>| --- |</p>"
        self.assertEqual(check_site.count_raw_tables(html), 2)

    def test_ignores_delimiter_examples_in_code_and_scripts(self):
        html = "<pre><code>| --- | --- |</code></pre><script>const x = '| --- | --- |';</script>"
        self.assertEqual(check_site.count_raw_tables(html), 0)

    def test_ignores_real_tables_and_ordinary_prose(self):
        html = "<table><tr><td>---</td><td>---</td></tr></table><p>--- is a separator.</p>"
        self.assertEqual(check_site.count_raw_tables(html), 0)

    def test_detects_collapsed_table_text(self):
        self.assertEqual(check_site.count_raw_tables("<p>Name | Value | --- | --- | one | two</p>"), 1)

    def test_excludes_explicitly_hidden_content(self):
        html = '<div style="display:none">| --- | --- |</div><div hidden>| --- | --- |</div>'
        self.assertEqual(check_site.count_raw_tables(html), 0)

    def test_reports_each_affected_page_and_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            dist = Path(tmp)
            (dist / "index.html").write_text("<p>| --- | --- |</p>", encoding="utf-8")
            (dist / "clean.html").write_text("<p>fine</p>", encoding="utf-8")
            self.assertEqual(check_site.raw_table_pages(dist, sorted(dist.glob("*.html"))), {"index.html": 1})

    def test_browser_page_urls_are_portable_and_include_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            dist = Path(tmp)
            nested = dist / "guide" / "install"
            nested.mkdir(parents=True)
            pages = [dist / "index.html", nested / "index.html"]
            self.assertEqual(check_site.page_urls(dist, pages), ["/", "/guide/install/"])

    def test_grade_reports_raw_table_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "canonical/skills").mkdir(parents=True)
            (root / "canonical/aid/templates").mkdir(parents=True)
            (root / "canonical/aid/templates/shortcut-catalog.yml").write_text("", encoding="utf-8")
            (root / "site/dist").mkdir(parents=True)
            (root / "site/dist/index.html").write_text("<p>| --- | --- |</p>", encoding="utf-8")
            (root / "site/package.json").write_text("{}", encoding="utf-8")
            output = io.StringIO()
            build = SimpleNamespace(returncode=0, stdout="", stderr="")
            with patch.object(check_site.sys, "argv", ["check_site.py", str(root), str(root / "out")]), \
                    patch.object(check_site.subprocess, "run", return_value=build), \
                    patch.dict(check_site.os.environ, {"AXE_JS": ""}), redirect_stdout(output):
                self.assertEqual(check_site.main(), 0)
            report = json.loads(output.getvalue())
            self.assertEqual(report["raw_table_static_estimate"], {"index.html": 1})
            self.assertIsNone(report["raw_table_pages"])
            self.assertEqual(report["raw_table_status"], "error")
            self.assertEqual(report["a11y_status"], "not_run")
            self.assertIn("AXE_JS", report["a11y_reason"])

    def test_npm_resolves_windows_command_wrapper(self):
        with patch.object(check_site.os, "name", "nt"), \
                patch.object(check_site.shutil, "which", side_effect=lambda name: "C:/tools/npm.cmd" if name == "npm.cmd" else None):
            self.assertEqual(check_site.npm_command(), "C:/tools/npm.cmd")

    def test_explicit_playwright_module_directory_avoids_global_lookup(self):
        with patch.dict(check_site.os.environ, {"PLAYWRIGHT_NODE_MODULES": "C:/custom/node_modules"}), \
                patch.object(check_site.subprocess, "run") as run:
            self.assertEqual(check_site.playwright_node_modules("npm"), "C:/custom/node_modules")
            run.assert_not_called()

    def test_default_playwright_module_directory_uses_npm_global_root(self):
        result = SimpleNamespace(stdout="/global/node_modules\n")
        with patch.dict(check_site.os.environ, {}, clear=True), \
                patch.object(check_site.subprocess, "run", return_value=result) as run:
            self.assertEqual(check_site.playwright_node_modules("npm"), "/global/node_modules")
            run.assert_called_once_with(["npm", "root", "-g"], capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
