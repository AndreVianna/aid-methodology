#!/usr/bin/env python3
"""Purpose: test dogfood resync shell selection, paths and failure handling.
Usage: python tests/canonical/test_sync_dogfood.py
Exit codes: 0 all tests pass, nonzero otherwise.
"""
import importlib.util
import io
import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / '.claude/skills/generate-profile/scripts/sync_dogfood.py'
spec = importlib.util.spec_from_file_location('sync_dogfood_test', SOURCE)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class ResyncTests(unittest.TestCase):
    def test_git_bash_path_conversion_is_explicit_and_keeps_spaces(self):
        self.assertEqual(sync._bash_path(r'C:\Users\A B\repo'), '/c/Users/A B/repo')
        self.assertEqual(sync._bash_path('D:/temp/stage'), '/d/temp/stage')
        self.assertEqual(sync._bash_path('/tmp/repo'), '/tmp/repo')
        with self.assertRaises(ValueError):
            sync._bash_path(r'\\server\share\repo')

    def test_unix_shell_remains_standard_bash(self):
        with mock.patch.object(sync.sys, 'platform', 'linux'):
            self.assertEqual(sync._bash_prefix(), ['bash'])

    def test_windows_uses_git_bash_and_crlf_option(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            git = root / 'cmd/git.exe'
            bash = root / 'bin/bash.exe'
            git.parent.mkdir()
            bash.parent.mkdir()
            git.touch()
            bash.touch()
            with mock.patch.object(sync.sys, 'platform', 'win32'), mock.patch.object(sync.shutil, 'which', return_value=str(git)):
                self.assertEqual(sync._bash_prefix(), [str(bash), '-o', 'igncr'])

    def test_resync_passes_stage_target_and_private_home_as_shell_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            target, scratch = root / 'target', root / 'scratch'
            target.mkdir()
            scratch.mkdir()
            calls = []
            def run(cmd, **kwargs):
                calls.append((cmd, kwargs))
                return subprocess.CompletedProcess(cmd, 0, '', '')
            with mock.patch.object(sync.subprocess, 'run', side_effect=run), mock.patch.object(sync, '_bash_prefix', return_value=['fake-bash']):
                with redirect_stdout(io.StringIO()):
                    self.assertEqual(sync.resync(target, scratch), 0)
            self.assertEqual(calls[0][0][-1], sync._bash_path(scratch / 'stage'))
            self.assertEqual(calls[1][0][1], sync._bash_path(sync.REPO_ROOT / 'bin/aid'))
            self.assertEqual(calls[1][0][-1], sync._bash_path(target))
            self.assertEqual(calls[1][1]['env']['AID_HOME'], sync._bash_path(scratch / 'home'))

    def test_stage_failure_stops_before_install(self):
        with tempfile.TemporaryDirectory() as temp:
            scratch = Path(temp)
            with mock.patch.object(sync, '_run', return_value=subprocess.CompletedProcess([], 1, '', 'failed')) as run:
                with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                    self.assertEqual(sync.resync(scratch, scratch), 1)
            self.assertEqual(run.call_count, 1)


if __name__ == '__main__':
    unittest.main()
