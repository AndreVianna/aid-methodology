#!/usr/bin/env python3
"""Exercise benchmark token accounting with mocked host turns, never a model.

Usage: python tests/measure/test_usage_accounting.py
"""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/measure'))
import measure
import repo_task


class UsageAccounting(unittest.TestCase):
    def setUp(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='usage-accounting-', dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'codex-home'
        self.home.mkdir()
        (self.home / 'config.toml').write_text('[tui]\nscreen_reader_detection_done = true\n', encoding='utf-8')
        self.revision = 'a' * 40

    def turns(self, host, *, decreasing=False, missing_final=False):
        if host == 'codex':
            usages = [dict(input_tokens=459840, output_tokens=1927, cache_read_input_tokens=427648,
                           cache_creation_input_tokens=None),
                      dict(input_tokens=1469646, output_tokens=7725, cache_read_input_tokens=1376384,
                           cache_creation_input_tokens=None)]
            if decreasing:
                usages[1]['input_tokens'] = 1
            if missing_final:
                usages[1]['input_tokens'] = None
        else:
            usages = [dict(input_tokens=100, output_tokens=5, cache_read_input_tokens=20,
                           cache_creation_input_tokens=7),
                      dict(input_tokens=200, output_tokens=10, cache_read_input_tokens=40,
                           cache_creation_input_tokens=11)]
        records = []
        for i, usage in enumerate(usages):
            records.append({'session': 'fixture-thread', 'tools': {'command_execution': 1},
                            'dispatches': None if host == 'codex' else 0,
                            'writer_calls': None if host == 'codex' else 0, 'start_context': None,
                            'result': {'result': 'Continue?' if i == 0 else 'Done.', 'usage': usage,
                                       'total_cost_usd': None if host == 'codex' else 0.1,
                                       'is_error': False, 'num_turns': 1}})
        return records

    def run_small(self, host, records):
        work = Path(tempfile.mkdtemp(prefix='small-' + host + '-', dir=self.root))
        project = work / 'project'
        project.mkdir()
        grade = {'hidden_pass': True, 'tests_pass': True, 'code_files_changed': 1}
        fn = 'turn_codex' if host == 'codex' else 'turn'
        commands = []
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            output = 'codex-cli 0.164.0\n' if '--version' in cmd else self.revision + '\n'
            return subprocess.CompletedProcess(cmd, 0, output, '')
        with mock.patch.object(measure.tempfile, 'mkdtemp', return_value=str(work)), \
             mock.patch.object(measure, 'setup', return_value=(project, {'CODEX_HOME': str(self.home)})), \
             mock.patch.object(measure, fn, side_effect=records), \
             mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure, 'locations', return_value=[project]), \
             mock.patch.object(measure, 'grade', return_value=grade), \
             contextlib.redirect_stderr(io.StringIO()):
            result = measure.measure('fix', False, len(records), 'test-model', self.root / 'bundle',
                                     host=host, codex_home=self.home if host == 'codex' else None)
        if host == 'codex':
            self.assertTrue(any('--version' in cmd for cmd in commands), 'must observe actual CLI version')
        return result

    def run_brownfield(self, host, records, resumed=False):
        out = Path(tempfile.mkdtemp(prefix='repo-' + host + '-', dir=self.root))
        project = out / 'project'
        project.mkdir()
        if resumed:
            metadata = {'commit': self.revision, 'prepared_head': self.revision, 'project': str(project.resolve()),
                        'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'plain'}
            (out / 'benchmark-metadata.json').write_text(json.dumps(metadata), encoding='utf-8')
        argv = ['repo_task.py', '--host', host, '--no-aid', '--out', str(out), '--turns', str(len(records)), '--model', 'test-model']
        if host == 'codex':
            argv += ['--codex-home', str(self.home)]
        if resumed:
            argv += ['--resume', 'fixture-thread', '--cwd', str(project)]
        fn = 'turn_codex' if host == 'codex' else 'turn'
        output = io.StringIO()
        commands = []
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            output = 'codex-cli 0.164.0\n' if '--version' in cmd else self.revision + '\n'
            return subprocess.CompletedProcess(cmd, 0, output, '')
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(repo_task, 'setup', return_value=(project, {'CODEX_HOME': str(self.home)})), \
             mock.patch.object(repo_task, fn, side_effect=records), \
             mock.patch.object(repo_task, 'run', side_effect=fake_run), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(repo_task.main(), 0)
        if host == 'codex':
            self.assertTrue(any('--version' in cmd for cmd in commands), 'must observe actual CLI version')
        return json.loads(output.getvalue())

    def test_both_drivers_use_last_cumulative_codex_usage(self):
        for name, run in (('small', self.run_small), ('brownfield', self.run_brownfield)):
            with self.subTest(driver=name):
                record = run('codex', self.turns('codex'))
                self.assertEqual(record['user_turns'], 2)
                self.assertEqual(record['input_tokens'], 1469646)
                self.assertEqual(record['cache_read_tokens'], 1376384)
                self.assertEqual(record['output_tokens'], 7725)
                self.assertIsNone(record['cache_write_tokens'])
                self.assertEqual(record['usage_scope'], 'session_cumulative')

    def test_both_drivers_preserve_claude_per_turn_addition(self):
        for name, run in (('small', self.run_small), ('brownfield', self.run_brownfield)):
            with self.subTest(driver=name):
                record = run('claude', self.turns('claude'))
                self.assertEqual(record['user_turns'], 2)
                self.assertEqual(record['input_tokens'], 300)
                self.assertEqual(record['cache_read_tokens'], 60)
                self.assertEqual(record['cache_write_tokens'], 18)
                self.assertEqual(record['output_tokens'], 15)

    def test_externally_resumed_codex_labels_usage_as_including_prior_turns(self):
        record = self.run_brownfield('codex', self.turns('codex'), resumed=True)
        self.assertEqual(record['input_tokens'], 1469646)
        self.assertEqual(record['usage_scope'], 'session_cumulative_including_previous_turns')

    def test_missing_latest_codex_usage_stays_unknown(self):
        for name, run in (('small', self.run_small), ('brownfield', self.run_brownfield)):
            with self.subTest(driver=name):
                record = run('codex', self.turns('codex', missing_final=True))
                self.assertIsNone(record['input_tokens'])

    def test_decreasing_cumulative_codex_totals_fail_closed(self):
        for name, run in (('small', self.run_small), ('brownfield', self.run_brownfield)):
            for key in ('input_tokens', 'output_tokens', 'cache_read_input_tokens'):
                with self.subTest(driver=name, field=key):
                    records = self.turns('codex')
                    records[1]['result']['usage'][key] = 1
                    with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                        run('codex', records)

    def test_usage_version_helper_accepts_only_observed_exact_supported_cli(self):
        project = self.root / 'version-project'
        project.mkdir()
        env = {'CODEX_HOME': str(self.home), 'PATH': 'private-test-path'}
        for output, status, accepted in (('codex-cli 0.164.0\n', 0, True),
                                         ('codex-cli 0.165.0\n', 0, False),
                                         ('codex-cli 0.164.0-alpha.1\n', 0, False),
                                         ('unknown\n', 0, False), ('', 1, False)):
            with self.subTest(output=output, status=status), \
                 mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], status, output, '')) as run:
                if accepted:
                    self.assertEqual(measure.require_supported_codex_version(project, env), '0.164.0')
                else:
                    with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                        measure.require_supported_codex_version(project, env)
                self.assertEqual(run.call_args.args[0][:2], ['codex', '--version'])
                self.assertEqual(run.call_args.args[2], env)

    def test_unknown_cli_version_stops_both_drivers_before_model(self):
        for module, prefix in ((measure, 'small'), (repo_task, 'repo')):
            for output, status in (('codex-cli 0.165.0\n', 0), ('codex-cli 0.164.0-alpha.1\n', 0),
                                   ('unrecognized\n', 0), ('', 1)):
                out = Path(tempfile.mkdtemp(prefix='unsupported-' + prefix + '-', dir=self.root))
                project = out / 'project'
                project.mkdir()
                argv = ([f'{prefix}.py', '--host', 'codex', '--no-aid', '--model', 'test-model',
                         '--codex-home', str(self.home), '--turns', '1'] +
                        (['--runs', '1'] if module is measure else ['--out', str(out)]))
                calls = []
                def fake_run(cmd, cwd, env, stdin=None):
                    calls.append(cmd)
                    if Path(cmd[0]).name in ('codex', 'codex.exe') and '--version' in cmd:
                        return subprocess.CompletedProcess(cmd, status, output, '')
                    return subprocess.CompletedProcess(cmd, 0, self.revision + '\n', '')
                with self.subTest(driver=prefix, output=output, status=status), \
                     mock.patch.object(sys, 'argv', argv), \
                     mock.patch.object(module, 'setup', return_value=(project, {'CODEX_HOME': str(self.home)})), \
                     mock.patch.object(module, 'turn_codex', side_effect=AssertionError('model must not run')), \
                     mock.patch.object(module, 'run', side_effect=fake_run), \
                     contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                        module.main()
                    self.assertTrue(any(Path(cmd[0]).name in ('codex', 'codex.exe') and '--version' in cmd for cmd in calls))

    def test_decrease_cannot_be_hidden_by_an_unreported_intermediate_value(self):
        for name, run in (('small', self.run_small), ('brownfield', self.run_brownfield)):
            for key in ('input_tokens', 'output_tokens', 'cache_read_input_tokens'):
                with self.subTest(driver=name, field=key):
                    records = self.turns('codex')
                    final = json.loads(json.dumps(records[1]))
                    records[1]['result']['result'] = 'Continue?'
                    records[1]['result']['usage'][key] = None
                    final['result']['usage'][key] = 1
                    records.append(final)
                    with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                        run('codex', records)


if __name__ == '__main__':
    unittest.main()
