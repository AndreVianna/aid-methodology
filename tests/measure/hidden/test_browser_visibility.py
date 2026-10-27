"""Run: python tests/measure/hidden/test_browser_visibility.py.

Set PLAYWRIGHT_NODE_MODULES and PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH to real local tools.
"""
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('site_grader', Path(__file__).with_name('check_site.py'))
grader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(grader)
REAL_RUN = subprocess.run


class RenderedVisibility(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('PLAYWRIGHT_NODE_MODULES') and os.environ.get('PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH'),
                         'real browser paths were not provided')
    def test_external_css_controls_reported_table_visibility_without_axe(self):
        scratch = Path(__file__).resolve().parents[3] / '.aid' / '.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='site-visibility-', dir=scratch) as tmp:
            root = Path(tmp)
            (root / 'canonical/skills').mkdir(parents=True)
            (root / 'canonical/aid/templates').mkdir(parents=True)
            (root / 'canonical/aid/templates/shortcut-catalog.yml').write_text('', encoding='utf-8')
            dist = root / 'site/dist'
            dist.mkdir(parents=True)
            (root / 'site/package.json').write_text('{}', encoding='utf-8')
            (dist / 'style.css').write_text('.external{display:none}', encoding='utf-8')
            (dist / 'index.html').write_text(
                '<link rel="stylesheet" href="/style.css"><style>.hidden{display:none}</style>'
                '<p>東京 — “visible” | --- | --- |</p><p class="hidden">| --- | --- |</p>'
                '<p class="external">| --- | --- |</p><div style="visibility:hidden">'
                '<p style="visibility:visible">| --- | --- |</p></div><pre>| --- | --- |</pre>', encoding='utf-8')
            for name in ('one', 'two', 'three'):
                directory = dist / name
                directory.mkdir()
                (directory / 'index.html').write_text('<p>clean</p>', encoding='utf-8')
            unicode_page = dist / 'café test'
            unicode_page.mkdir()
            (unicode_page / 'index.html').write_text('<p>| --- | --- |</p>', encoding='utf-8')
            def run(command, *args, **kwargs):
                if list(command)[1:3] == ['run', 'build']:
                    return subprocess.CompletedProcess(command, 0, '', '')
                return REAL_RUN(command, *args, **kwargs)
            output = io.StringIO()
            with patch.object(grader.sys, 'argv', ['check_site.py', str(root), str(root / 'out')]), \
                    patch.object(grader.subprocess, 'run', side_effect=run), \
                    patch.dict(os.environ, {'AXE_JS': ''}), redirect_stdout(output):
                self.assertEqual(grader.main(), 0)
            report = json.loads(output.getvalue())
            self.assertEqual(report['raw_table_status'], 'complete', report)
            self.assertEqual(report['raw_table_pages'], {'index.html': 2, 'café test/index.html': 1}, report)
            self.assertEqual(report['a11y_status'], 'not_run')
            (dist / 'style.css').unlink()
            missing_output = io.StringIO()
            with patch.object(grader.sys, 'argv', ['check_site.py', str(root), str(root / 'out')]), \
                    patch.object(grader.subprocess, 'run', side_effect=run), \
                    patch.dict(os.environ, {'AXE_JS': ''}), redirect_stdout(missing_output):
                self.assertEqual(grader.main(), 0)
            missing = json.loads(missing_output.getvalue())
            self.assertEqual(missing['raw_table_status'], 'error', missing)
            self.assertIsNone(missing['raw_table_pages'])
            (dist / 'style.css').write_text('@import url(/missing.css); .external{display:none}', encoding='utf-8')
            import_output = io.StringIO()
            with patch.object(grader.sys, 'argv', ['check_site.py', str(root), str(root / 'out')]), \
                    patch.object(grader.subprocess, 'run', side_effect=run), \
                    patch.dict(os.environ, {'AXE_JS': ''}), redirect_stdout(import_output):
                self.assertEqual(grader.main(), 0)
            failed_import = json.loads(import_output.getvalue())
            self.assertEqual(failed_import['raw_table_status'], 'error', failed_import)
            self.assertIsNone(failed_import['raw_table_pages'])


if __name__ == '__main__':
    unittest.main()
