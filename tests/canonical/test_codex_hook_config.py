#!/usr/bin/env python3
"""Test project-local Codex hook registration without starting Codex or Git.

These checks prove file management only, not host trust or hook enforcement.
"""
import json
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / 'canonical/aid/scripts/change/codex_hook_config.py'
SCRATCH = ROOT / '.aid/.temp'
SKILL = ROOT / 'canonical/skills/aid-change/SKILL.md'


@unittest.skipUnless(sys.platform.startswith('linux'), 'registration fixture requires Linux/WSL')
class HookRegistration(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='codex-hook-test-', dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / 'project'
        self.project.mkdir()
        git = subprocess.run(['git', 'init', '-q', str(self.project)], capture_output=True, text=True,
                             env=dict(os.environ, GIT_CONFIG_NOSYSTEM='1', HOME=self.temp.name))
        if git.returncode:
            self.fail('disposable Git fixture initialization failed: ' + git.stderr)
        self.handler = self.project / '.aid/runtime/scripts/change/codex_safeguard.py'
        self.handler.parent.mkdir(parents=True)
        self.handler.write_text('# fixture handler\n', encoding='utf-8')
        self.codex = self.project / '.codex'
        self.codex.mkdir()
        self.hooks = self.codex / 'hooks.json'
        self.config = self.codex / 'config.toml'
        self.config.write_bytes(b'# user settings\nmodel = "keep-me"\n')
        self.home = Path(self.temp.name) / 'codex-home'
        self.home.mkdir()
        (self.home / 'config.toml').write_bytes(b'# private config must remain unchanged\n')

    def call(self, operation):
        env = dict(os.environ, CODEX_HOME=str(self.home), PYTHONDONTWRITEBYTECODE='1')
        return subprocess.run([sys.executable, str(HELPER), operation, '--project',
                               str(self.project)], text=True, capture_output=True, env=env)

    def test_install_refuses_existing_user_hooks_and_preserves_configs(self):
        existing = {'description': 'user-owned', 'hooks': {
            'PreToolUse': [{'matcher': 'Bash', 'hooks': [{'type': 'command', 'command': 'user-pre'}]}],
            'Stop': [{'hooks': [{'type': 'command', 'command': 'user-stop'}]}]}}
        self.hooks.write_text(json.dumps(existing), encoding='utf-8')
        config_before = self.config.read_bytes()
        home_before = (self.home / 'config.toml').read_bytes()
        before = self.hooks.read_bytes()
        result = self.call('install')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.hooks.read_bytes(), before)
        self.assertIn('manual', (result.stdout + result.stderr).lower())
        self.assertEqual(self.config.read_bytes(), config_before)
        self.assertEqual((self.home / 'config.toml').read_bytes(), home_before)
        self.assertEqual(sorted(p.name for p in self.home.iterdir()), ['config.toml'])

    def test_owned_install_is_idempotent_and_removal_is_manual(self):
        result = self.call('install')
        self.assertEqual(result.returncode, 0, result.stderr)
        before = self.hooks.read_bytes()
        self.assertIn('codex_safeguard.py', before.decode())
        self.assertEqual(self.call('install').returncode, 0)
        self.assertEqual(self.hooks.read_bytes(), before)
        result = self.call('remove')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('manual', (result.stdout + result.stderr).lower())
        self.assertEqual(self.hooks.read_bytes(), before)

    def test_new_registration_never_uses_replace_for_shared_path(self):
        spec = importlib.util.spec_from_file_location('hook_registration_under_test', HELPER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with mock.patch.object(module.os, 'replace', side_effect=AssertionError('unsafe replacement')):
            module.update(self.project, 'install')
        self.assertIn('codex_safeguard.py', self.hooks.read_text(encoding='utf-8'))

    def test_concurrent_creation_is_not_overwritten(self):
        spec = importlib.util.spec_from_file_location('hook_race_under_test', HELPER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        real_link = os.link
        sentinel = b'{"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "concurrent"}]}]}}'
        invoked = []
        def competing_link(source, target, *args, **kwargs):
            if Path(target) == self.hooks and not invoked:
                invoked.append(True)
                self.hooks.write_bytes(sentinel)
            return real_link(source, target, *args, **kwargs)
        with mock.patch.object(module.os, 'link', side_effect=competing_link):
            with self.assertRaises((FileExistsError, ValueError)):
                module.update(self.project, 'install')
        self.assertTrue(invoked, 'registration must exclusively create hooks.json')
        self.assertEqual(self.hooks.read_bytes(), sentinel)

    def test_invalid_existing_file_is_never_overwritten(self):
        for invalid in (b'{', b'[]', b'{"hooks": []}', b'{"hooks": {"PreToolUse": {}}}'):
            with self.subTest(invalid=invalid):
                self.hooks.write_bytes(invalid)
                self.assertNotEqual(self.call('install').returncode, 0)
                self.assertEqual(self.hooks.read_bytes(), invalid)

    def test_missing_installed_handler_refuses_install_without_writing(self):
        self.handler.unlink()
        self.hooks.write_bytes(b'{"hooks": {}}\n')
        before = self.hooks.read_bytes()
        self.assertNotEqual(self.call('install').returncode, 0)
        self.assertEqual(self.hooks.read_bytes(), before)

    def test_symlinked_hook_file_is_never_followed(self):
        target = Path(self.temp.name) / 'outside-hooks.json'
        target.write_bytes(b'{"hooks": {}}\n')
        try:
            self.hooks.symlink_to(target)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        before = target.read_bytes()
        self.assertNotEqual(self.call('install').returncode, 0)
        self.assertTrue(self.hooks.is_symlink())
        self.assertEqual(target.read_bytes(), before)

    def test_symlinked_handler_is_not_registered(self):
        external = Path(self.temp.name) / 'external-handler.py'
        external.write_text('# unrelated handler\n', encoding='utf-8')
        self.handler.unlink()
        try:
            self.handler.symlink_to(external)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        self.hooks.write_bytes(b'{"hooks": {}}\n')
        before = self.hooks.read_bytes()
        self.assertNotEqual(self.call('install').returncode, 0)
        self.assertEqual(self.hooks.read_bytes(), before)

    def test_modified_owned_entry_is_not_removed_or_replaced(self):
        self.assertEqual(self.call('install').returncode, 0)
        value = json.loads(self.hooks.read_text(encoding='utf-8'))
        owned = next(item for item in value['hooks']['PreToolUse']
                     if 'codex_safeguard.py' in json.dumps(item))
        owned['hooks'][0]['command'] += ' --user-modified'
        self.hooks.write_text(json.dumps(value), encoding='utf-8')
        before = self.hooks.read_bytes()
        for operation in ('install', 'remove'):
            with self.subTest(operation=operation):
                self.assertNotEqual(self.call(operation).returncode, 0)
                self.assertEqual(self.hooks.read_bytes(), before)

class InstalledWorkflowInstructions(unittest.TestCase):
    def test_codex_activation_is_a_precondition_with_scope_and_trust_disclosed(self):
        text = SKILL.read_text(encoding='utf-8')
        lower = text.lower()
        self.assertIn('codex_hook_config.py', text)
        self.assertIn('python3', text)
        self.assertIn('install --project', text)
        self.assertIn('/hooks', text)
        self.assertIn('trust', lower)
        self.assertIn('project-wide', lower)
        self.assertIn('wsl', lower)
        self.assertIn('git', lower)
        self.assertLess(text.index('codex_hook_config.py'), text.index('**Size:**'))


@unittest.skipUnless(sys.platform == 'win32', 'native Windows rejection requires Windows')
class NativeWindowsRejection(unittest.TestCase):
    def test_install_refuses_native_windows_without_writing_config(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='codex-hook-native-windows-', dir=SCRATCH) as tmp:
            project = Path(tmp) / 'project'
            handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
            handler.parent.mkdir(parents=True)
            handler.write_text('# fixture\n', encoding='utf-8')
            result = subprocess.run([sys.executable, str(HELPER), 'install', '--project', str(project)],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((project / '.codex/hooks.json').exists())


class Preflight(unittest.TestCase):
    """Mocked preflight control flow, not proof the host actually loads a hook."""
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='codex-hook-preflight-', dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / 'project'
        self.project.mkdir()
        self.config = self.project / '.codex/hooks.json'
        self.config.parent.mkdir()
        self.config.write_bytes(b'{"existing": "preserve"}\n')
        spec = importlib.util.spec_from_file_location('codex_hook_preflight', HELPER)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def run_preflight(self, platform='linux', missing=None, git_root=None, git_status=0):
        def lookup(name):
            return None if name == missing else '/usr/bin/' + name
        completed = subprocess.CompletedProcess([], git_status, str(git_root or self.project.resolve()) + '\n', '')
        with mock.patch.object(self.module.sys, 'platform', platform), \
             mock.patch.object(self.module.shutil, 'which', side_effect=lookup), \
             mock.patch.object(self.module.subprocess, 'run', return_value=completed):
            return self.module.preflight(self.project)

    def test_valid_linux_git_root_is_accepted_without_changing_existing_config(self):
        before = self.config.read_bytes()
        self.run_preflight()
        self.assertEqual(self.config.read_bytes(), before)

    def test_unsupported_or_invalid_environment_is_rejected_without_changes(self):
        cases = [dict(platform='win32'), dict(missing='git'), dict(missing='python3'),
                 dict(git_root=self.project.parent), dict(git_status=128)]
        for case in cases:
            with self.subTest(case=case):
                before = self.config.read_bytes()
                with self.assertRaises((ValueError, RuntimeError, OSError)):
                    self.run_preflight(**case)
                self.assertEqual(self.config.read_bytes(), before)

    def test_install_calls_preflight_before_touching_existing_config(self):
        before = self.config.read_bytes()
        with mock.patch.object(self.module, 'preflight', side_effect=ValueError('unsupported host')) as check:
            with self.assertRaises(ValueError):
                self.module.update(self.project, 'install')
        check.assert_called_once()
        self.assertEqual(self.config.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
