#!/usr/bin/env python3
"""Purpose: exercise Codex benchmark host selection and event parsing without a model.
Usage: python tests/measure/test_codex_host.py
Exit codes: 0 when all checks pass; nonzero otherwise.
Hook trust in the isolated Codex home must be established externally; these mocks
do not establish trust or prove that the host enforces a hook.
"""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
MEASURE_DIR = ROOT / 'tests/measure'
sys.path.insert(0, str(MEASURE_DIR))
import measure
import repo_task


def events(*items):
    return ''.join(json.dumps(item) + '\n' for item in items)


class TrustRequestRegression(unittest.TestCase):
    def test_imperative_hook_trust_request_is_unfinished(self):
        text = "The required AID hook is installed, but its trust status isn't established. Please review and trust it in Codex /hooks so I can continue."
        self.assertTrue(measure.asks(text))
        self.assertTrue(measure.requests_hook_trust(text))

    def test_completed_hook_statement_is_not_a_request(self):
        self.assertFalse(measure.asks('The hook was reviewed and trusted; the fix is complete.'))
        self.assertFalse(measure.requests_hook_trust('The hook was reviewed and trusted; the fix is complete.'))

    def test_generic_request_does_not_authorize_trust_reply(self):
        self.assertFalse(measure.requests_hook_trust('Please review the patch and tell me what you think.'))

    def test_quoted_trust_request_is_not_an_active_request(self):
        self.assertFalse(measure.requests_hook_trust('The example says "Please review and trust it in Codex /hooks."'))

    def test_reviewed_observed_message_is_safe_but_other_imperatives_are_not(self):
        observed = ("The required AID hook is installed, but its trust status isn’t established. "
                    "Please review and trust it in Codex `/hooks` so I can continue.\n\n"
                    "The [aid-change skill](.agents/skills/aid-change/SKILL.md) requires: "
                    "“If activation, the required Git/Python tools, or trust cannot be established, "
                    "stop and explain the missing step.”\n\n"
                    "No application code has changed; the duplicate notes remain unresolved.")
        self.assertTrue(measure.safe_trust_followup(observed))
        self.assertFalse(measure.safe_trust_followup(observed + ' Confirm the release.'))

    def test_other_question_is_still_unfinished(self):
        self.assertTrue(measure.asks('Which format would you like?'))
        self.assertFalse(measure.requests_hook_trust('Which format would you like?'))

    def test_alternate_observed_trust_request_is_unfinished(self):
        text = 'Please review and trust the AID hook in `/hooks`, then I can investigate and fix the duplicate notes.'
        self.assertTrue(measure.asks(text))
        self.assertTrue(measure.requests_hook_trust(text))
        self.assertFalse(measure.safe_trust_followup(text))


class CodexEvents(unittest.TestCase):
    def setUp(self):
        self.scratch = ROOT / '.aid/.temp'
        self.scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='codex-host-test-', dir=self.scratch)
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / 'project'
        self.project.mkdir()
        codex_home = Path(self.temp.name) / 'existing-codex-home'
        codex_home.mkdir()
        (codex_home / 'config.toml').write_text('[tui]\nscreen_reader_detection_done = true\n', encoding='utf-8')
        self.env = {'CODEX_HOME': str(codex_home), 'PATH': 'sentinel-path'}

    def completed(self, output, status=0):
        return subprocess.CompletedProcess([], status, output, '')

    def stream(self):
        return events(
            {'type': 'thread.started', 'thread_id': 'thread-123'},
            {'type': 'item.completed', 'item': {'type': 'agent_message', 'text': 'Checking first.', 'phase': 'commentary'}},
            {'type': 'item.completed', 'item': {'type': 'command_execution', 'command': 'echo checked', 'exit_code': 0}},
            {'type': 'item.completed', 'item': {'type': 'file_change', 'changes': [{'path': 'x.py', 'kind': 'update'}]}},
            {'type': 'item.completed', 'item': {'type': 'agent_message', 'text': 'Finished.', 'phase': 'final_answer'}},
            {'type': 'turn.completed', 'usage': {'input_tokens': 90, 'cached_input_tokens': 20, 'output_tokens': 7}},
        )

    def test_turn_preserves_order_final_and_unavailable_cost(self):
        original_env = dict(self.env)
        with mock.patch.object(measure, 'run', return_value=self.completed(self.stream())) as run:
            result = measure.turn_codex(self.project, self.env, None, 'test request', None)
        self.assertEqual(self.env, original_env)
        self.assertEqual(result['session'], 'thread-123')
        self.assertEqual(result['result']['result'], 'Finished.')
        self.assertEqual(result['messages'], ['Checking first.', 'Finished.'])
        self.assertIsNone(result['result'].get('total_cost_usd'))
        self.assertEqual(result['result']['usage']['input_tokens'], 90)
        self.assertEqual(result['result']['usage']['output_tokens'], 7)
        self.assertGreaterEqual(sum(result['tools'].values()), 2)
        cmd, cwd, env = run.call_args.args[:3]
        self.assertEqual(list(cmd[:2]), ['codex', 'exec'])
        self.assertIn('--json', cmd)
        self.assertIn('--enable', cmd)
        self.assertEqual(cmd[cmd.index('--enable') + 1], 'hooks')
        self.assertEqual(cwd, self.project)
        self.assertEqual(env, original_env)
        self.assertFalse(any('bypass' in str(arg) for arg in cmd))
        self.assertNotIn('claude-sonnet-5-5', cmd)

    def test_resume_uses_existing_thread_and_fresh_prompt(self):
        with mock.patch.object(measure, 'run', return_value=self.completed(self.stream())) as run:
            result = measure.turn_codex(self.project, self.env, 'test-model', 'continue task', 'thread-123')
        cmd = run.call_args.args[0]
        self.assertEqual(list(cmd[:2]), ['codex', 'exec'])
        self.assertIn('--sandbox', cmd)
        self.assertEqual(cmd[cmd.index('--sandbox') + 1], 'workspace-write')
        self.assertLess(cmd.index('--sandbox'), cmd.index('resume'))
        self.assertIn('--enable', cmd)
        self.assertEqual(cmd[cmd.index('--enable') + 1], 'hooks')
        self.assertLess(cmd.index('--enable'), cmd.index('resume'))
        self.assertIn('thread-123', cmd)
        self.assertIn('--json', cmd)
        self.assertEqual(result['session'], 'thread-123')
        self.assertFalse(any('bypass' in str(arg) for arg in cmd))

    def test_resume_rejects_mismatched_thread(self):
        with mock.patch.object(measure, 'run', return_value=self.completed(self.stream())):
            with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                measure.turn_codex(self.project, self.env, None, 'continue', 'different-thread')

    def test_start_and_resume_revalidate_config_before_each_cli_call(self):
        config = Path(self.env['CODEX_HOME']) / 'config.toml'
        for session in (None, 'thread-123'):
            with self.subTest(session=session):
                config.write_text('[mcp_servers.untrusted]\ncommand = "unexpected"\n', encoding='utf-8')
                with mock.patch.object(measure, 'run', side_effect=AssertionError('CLI must not run')):
                    with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                        measure.turn_codex(self.project, self.env, 'test-model', 'request', session)

    def test_project_local_codex_config_is_rejected_before_cli(self):
        directory = self.project / '.codex'
        directory.mkdir()
        config = directory / 'config.toml'
        config.write_text('[mcp_servers.untrusted]\ncommand = "outside"\n', encoding='utf-8')
        before = config.read_bytes()
        for session in (None, 'thread-123'):
            with self.subTest(session=session), \
                 mock.patch.object(measure, 'run', side_effect=AssertionError('CLI must not run')):
                with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                    measure.turn_codex(self.project, self.env, 'test-model', 'request', session)
        self.assertEqual(config.read_bytes(), before)

    def test_symlinked_project_codex_directory_is_rejected_before_cli(self):
        target = Path(self.temp.name) / 'outside-codex'
        target.mkdir()
        directory = self.project / '.codex'
        try:
            directory.symlink_to(target, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        with mock.patch.object(measure, 'run', side_effect=AssertionError('CLI must not run')):
            with self.assertRaises((RuntimeError, ValueError, SystemExit)):
                measure.turn_codex(self.project, self.env, 'test-model', 'request', None)
        self.assertEqual(list(target.iterdir()), [])

    def test_start_and_resume_load_private_config_without_bypassing_hook_trust(self):
        for session in (None, 'thread-123'):
            with self.subTest(session=session), \
                 mock.patch.object(measure, 'run', return_value=self.completed(self.stream())) as run:
                measure.turn_codex(self.project, self.env, None, 'request', session)
                cmd = run.call_args.args[0]
                self.assertNotIn('--ignore-user-config', cmd)
                self.assertIn('--enable', cmd)
                self.assertEqual(cmd[cmd.index('--enable') + 1], 'hooks')
                self.assertFalse(any('bypass' in str(arg) for arg in cmd))
                disabled = [cmd[i + 1] for i, arg in enumerate(cmd[:-1]) if arg == '--disable']
                self.assertIn('apps', disabled)
                self.assertIn('browser_use', disabled)
                self.assertEqual(run.call_args.args[2]['CODEX_HOME'], self.env['CODEX_HOME'])

    def test_missing_usage_and_unobserved_counts_stay_unknown(self):
        stream = events({'type': 'thread.started', 'thread_id': 'thread-123'},
                        {'type': 'item.completed', 'item': {'type': 'agent_message', 'text': 'Done.'}},
                        {'type': 'turn.completed', 'usage': {}})
        with mock.patch.object(measure, 'run', return_value=self.completed(stream)):
            result = measure.turn_codex(self.project, self.env, None, 'x', None)
        usage = result['result']['usage']
        for key in ('input_tokens', 'output_tokens', 'cache_read_input_tokens', 'cache_creation_input_tokens'):
            self.assertIsNone(usage.get(key), key)
        self.assertIsNone(result['dispatches'])
        self.assertIsNone(result['writer_calls'])

    def test_failure_or_missing_completion_never_becomes_success(self):
        samples = [
            self.completed(self.stream(), 1),
            self.completed('{not-valid-json}\n' + self.stream()),
            self.completed(events({'type': 'thread.started', 'thread_id': 't'},
                                  {'type': 'item.completed', 'item': {'type': 'agent_message', 'text': 'incomplete'}})),
            self.completed(events({'type': 'thread.started', 'thread_id': 't'},
                                  {'type': 'turn.completed', 'usage': {'input_tokens': 1, 'output_tokens': 1}})),
            self.completed(events({'type': 'thread.started', 'thread_id': 't'},
                                  {'type': 'turn.failed', 'error': {'message': 'failed'}})),
        ]
        for completed in samples:
            with self.subTest(output=completed.stdout), mock.patch.object(measure, 'run', return_value=completed):
                try:
                    result = measure.turn_codex(self.project, self.env, None, 'x', None)
                except (SystemExit, RuntimeError, ValueError, subprocess.SubprocessError):
                    continue
                self.assertTrue(result['result'].get('is_error'), result)


class CodexReporting(unittest.TestCase):
    def test_report_separates_hosts_and_never_invents_codex_cost(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='host-report-', dir=scratch) as tmp:
            records = [
                {'scenario': 'fix', 'aid': True, 'mode': 'lean', 'host': 'claude', 'cost_usd': 3.0,
                 'start_context_tokens': 100, 'cache_write_tokens': 20, 'seconds': 2, 'hidden_pass': True},
                {'scenario': 'fix', 'aid': True, 'mode': 'lean', 'host': 'codex', 'cost_usd': None,
                 'start_context_tokens': None, 'cache_write_tokens': None, 'seconds': 4, 'hidden_pass': True},
                {'scenario': 'fix', 'aid': False, 'cost_usd': 0.2,
                 'start_context_tokens': 100, 'cache_write_tokens': 20, 'seconds': 1, 'hidden_pass': True},
            ]
            file = Path(tmp) / 'results.jsonl'
            file.write_text(''.join(json.dumps(row) + '\n' for row in records), encoding='utf-8')
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertEqual(measure.report([str(file)]), 0)
            rows = [line for line in output.getvalue().splitlines() if line.split() and line.split()[0] == 'fix']
            self.assertEqual(len(rows), 3, output.getvalue())
            codex = next((line for line in rows if 'codex' in line.lower()), '')
            claude = next((line for line in rows if 'claude' in line.lower() and 'lean' in line.lower()), '')
            self.assertTrue(codex and claude, output.getvalue())
            self.assertNotIn('$0.00', codex)
            self.assertIn('$3.00', claude)

    def test_same_host_different_models_are_not_mixed(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='model-report-', dir=scratch) as tmp:
            records = [
                {'scenario': 'fix', 'aid': True, 'mode': 'lean', 'host': 'codex', 'model': name,
                 'cost_usd': None, 'start_context_tokens': None, 'cache_write_tokens': None,
                 'seconds': seconds, 'hidden_pass': True}
                for name, seconds in (('model-a', 3), ('model-b', 9))
            ]
            file = Path(tmp) / 'results.jsonl'
            file.write_text(''.join(json.dumps(row) + '\n' for row in records), encoding='utf-8')
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertEqual(measure.report([str(file)]), 0)
            rows = [line for line in output.getvalue().splitlines() if line.split() and line.split()[0] == 'fix']
            self.assertEqual(len(rows), 2, output.getvalue())
            self.assertTrue(any('model-a' in line for line in rows), output.getvalue())
            self.assertTrue(any('model-b' in line for line in rows), output.getvalue())
            self.assertFalse(any('$0.00' in line for line in rows), output.getvalue())


class NativeHookProbe(unittest.TestCase):
    """Mock the CLI boundary only; passing tests are not native enforcement proof."""
    def setUp(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='hook-verifier-', dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'work/project'
        self.project.mkdir(parents=True)
        self.gitdir = self.project / '.git'
        self.gitdir.mkdir()
        (self.gitdir / 'config').write_text('[core]\nrepositoryformatversion = 0\n', encoding='utf-8')
        (self.gitdir / 'HEAD').write_text('ref: refs/heads/main\n', encoding='utf-8')
        (self.gitdir / 'index').write_bytes(b'original index bytes')
        self.home = self.root / 'home'
        self.home.mkdir()
        self.codex_bin = self.root / 'codex'
        self.codex_bin.write_bytes(b'fake local CLI executable identity\n')
        self.hook = self.project / '.codex/hooks.json'
        self.hook.parent.mkdir()
        self.hook_contents = json.dumps({'hooks': {'PreToolUse': [{'matcher': '^Bash$', 'hooks': [{
            'type': 'command', 'command': 'python3 "$(git rev-parse --show-toplevel)/.aid/runtime/scripts/change/codex_safeguard.py"'}]}]}})
        self.hook.write_text(self.hook_contents, encoding='utf-8')
        project_key = json.dumps(str(self.project.resolve()).replace('\\', '/'))
        hook_key = json.dumps(str(self.hook.resolve()).replace('\\', '/') + ':pre_tool_use:0:0')
        self.config_text = ('[tui]\nscreen_reader_detection_done = true\n'
                            '[tui.model_availability_nux]\n"test-model" = 2\n'
                            f'[projects.{project_key}]\ntrust_level = "trusted"\n'
                            f'[hooks.state.{hook_key}]\ntrusted_hash = "sha256:' + 'a' * 64 + '"\n')
        (self.home / 'config.toml').write_text(self.config_text, encoding='utf-8')
        self.handler = self.project / '.aid/runtime/scripts/change/codex_safeguard.py'
        self.handler.parent.mkdir(parents=True)
        self.handler.write_text('# fixture handler\n', encoding='utf-8')
        self.env = {'CODEX_HOME': str(self.home), 'HOME': str(self.root / 'isolated-home'),
                    'PATH': os.environ.get('PATH', '')}

    def verify_with(self, outcome):
        attempts = []
        git_checks = {'remote': 0, 'head': 0}
        def fake_run(cmd, cwd, env, stdin=None):
            if Path(cmd[0]).name not in ('codex', 'codex.exe'):
                if cmd[:2] == ['git', 'remote']:
                    git_checks['remote'] += 1
                    value = 'origin\n' if outcome == 'changed-remote' and git_checks['remote'] > 1 else ''
                    return subprocess.CompletedProcess(cmd, 0, value, '')
                if cmd[:3] == ['git', 'rev-parse', 'HEAD']:
                    git_checks['head'] += 1
                    value = 'b' * 40 if outcome == 'changed-head' and git_checks['head'] > 1 else 'a' * 40
                    return subprocess.CompletedProcess(cmd, 0, value + '\n', '')
                return subprocess.CompletedProcess(cmd, 0, str(self.project) + '\n', '')
            if len(cmd) > 1 and cmd[1] == '--version':
                return subprocess.CompletedProcess(cmd, 0, 'codex-cli 0.164.0\n', '')
            attempts.append((cmd, cwd, env, stdin))
            candidates = list((self.project / '.aid/.temp').glob('codex-hook-probe-*'))
            self.assertTrue(candidates, 'verifier must create a scoped probe before running')
            probe = max(candidates, key=lambda p: p.stat().st_mtime_ns)
            command = str((probe / 'fake-bin/git').relative_to(self.project)).replace('\\', '/')
            for verb in ('status', 'push', 'merge'):
                self.assertIn(command + ' ' + verb, stdin)
            if outcome != 'missing-status-marker':
                (probe / 'status').write_text('status\n', encoding='utf-8')
            if outcome == 'forbidden-side-effect':
                (probe / 'push').write_text('push\n', encoding='utf-8')
            if outcome == 'forbidden-merge-side-effect':
                (probe / 'merge').write_text('merge\n', encoding='utf-8')
            if outcome == 'changed-hook':
                self.hook.write_text('{"changed": true}', encoding='utf-8')
            if outcome == 'changed-handler':
                self.handler.write_text('# changed\n', encoding='utf-8')
            if outcome == 'changed-config':
                (self.home / 'config.toml').write_text(self.config_text + '\n# changed\n', encoding='utf-8')
            if outcome == 'changed-cli':
                self.codex_bin.write_bytes(b'changed CLI launcher')
            if outcome == 'changed-git-config':
                (self.gitdir / 'config').write_text('[remote "origin"]\nurl = changed\n', encoding='utf-8')
            if outcome == 'changed-git-index':
                (self.gitdir / 'index').write_bytes(b'changed staged state')
            if outcome == 'symlink-tamper':
                external = self.root / 'external-preserve'
                external.mkdir(exist_ok=True)
                (external / 'keep').write_text('outside', encoding='utf-8')
                (probe / 'fake-bin').rename(probe / 'moved-fake-bin')
                (probe / 'fake-bin').symlink_to(external, target_is_directory=True)
            status = {'type': 'item.completed', 'item': {'type': 'command_execution',
                      'command': command + ' status', 'exit_code': 1 if outcome == 'status-failed' else 0}}
            output = events({'type': 'thread.started', 'thread_id': 'test'}, status,
                            {'type': 'turn.completed', 'usage': {}})
            if outcome == 'malformed':
                output = '{invalid\n'
            elif outcome == 'missing-status-event':
                output = events({'type': 'thread.started', 'thread_id': 'test'}, {'type': 'turn.completed', 'usage': {}})
            stderr = ''.join('Command blocked by PreToolUse hook: Push and merge require the maintainer.. Command: '
                             + command + ' ' + verb + '\n' for verb in ('push', 'merge'))
            if outcome == 'untrusted':
                stderr = ''
            elif outcome == 'missing-merge-denial':
                stderr = stderr.splitlines()[0] + '\n'
            elif outcome == 'wrong-command-denial':
                stderr = stderr.replace(command + ' push', 'other/git push')
            if outcome == 'timeout':
                raise subprocess.TimeoutExpired(cmd, 1)
            return subprocess.CompletedProcess(cmd, 1 if outcome == 'nonzero' else 0, output, stderr)
        with mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)):
            result = measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)
        self.assertEqual(len(attempts), 1)
        cmd, cwd, env, _ = attempts[0]
        self.assertEqual(Path(cwd), self.project)
        self.assertEqual(env['CODEX_HOME'], str(self.home))
        self.assertIn('--enable', cmd)
        self.assertEqual(cmd[cmd.index('--enable') + 1], 'hooks')
        self.assertNotIn('--ignore-user-config', cmd)
        self.assertFalse(any('bypass' in str(arg) for arg in cmd))
        overrides = [cmd[i + 1] for i, arg in enumerate(cmd[:-1]) if arg in ('-c', '--config')]
        self.assertIn('sandbox_workspace_write.network_access=false', overrides)
        self.assertIn('approval_policy=never', overrides)
        disabled = [cmd[i + 1] for i, arg in enumerate(cmd[:-1]) if arg == '--disable']
        self.assertIn('apps', disabled)
        self.assertIn('browser_use', disabled)
        return result

    def test_verified_denials_and_positive_control_preserve_raw_evidence(self):
        unrelated = self.project / '.aid/.temp/unrelated/keep.txt'
        unrelated.parent.mkdir(parents=True)
        unrelated.write_text('keep', encoding='utf-8')
        before = measure.fixture_tree_sha256(self.project)
        self.verify_with('trusted')
        evidence = self.project.parent / 'codex-hook-evidence'
        self.assertTrue(evidence.is_dir())
        self.assertTrue(any(p.is_file() and 'command_execution' in p.read_text(encoding='utf-8')
                            for p in evidence.rglob('*.jsonl')))
        self.assertTrue(any(p.is_file() and 'Command blocked by PreToolUse hook' in p.read_text(encoding='utf-8')
                            for p in evidence.rglob('*') if p.is_file()))
        identities = [json.loads(p.read_text(encoding='utf-8')) for p in evidence.rglob('identity.json')]
        self.assertEqual(len(identities), 1)
        identity = identities[0]
        self.assertEqual(Path(identity['project']), self.project.resolve())
        self.assertEqual(Path(identity['codex_home']), self.home.resolve())
        self.assertEqual(identity['model'], 'test-model')
        self.assertEqual(identity['hashes'][str(self.codex_bin)], hashlib.sha256(self.codex_bin.read_bytes()).hexdigest())
        self.assertTrue(identity['version'])
        self.assertEqual(measure.fixture_tree_sha256(self.project), before)
        self.assertEqual(unrelated.read_text(encoding='utf-8'), 'keep')
        self.assertTrue(any(p.is_file() and p.name == 'git' for p in evidence.rglob('git')))
        self.assertTrue(any(p.is_file() and p.name == 'status' for p in evidence.rglob('status')))

    def test_incomplete_untrusted_tampered_or_failing_probe_fails_closed(self):
        for outcome in ('untrusted', 'missing-merge-denial', 'missing-status-event', 'missing-status-marker',
                        'forbidden-side-effect', 'forbidden-merge-side-effect', 'changed-hook',
                        'changed-handler', 'changed-config', 'changed-cli', 'status-failed', 'wrong-command-denial',
                        'changed-remote', 'changed-head', 'changed-git-config', 'changed-git-index',
                        'malformed', 'timeout', 'nonzero'):
            with self.subTest(outcome=outcome):
                self.hook.write_text(self.hook_contents, encoding='utf-8')
                self.handler.write_text('# fixture handler\n', encoding='utf-8')
                self.codex_bin.write_bytes(b'fake local CLI executable identity\n')
                (self.gitdir / 'config').write_text('[core]\nrepositoryformatversion = 0\n', encoding='utf-8')
                (self.gitdir / 'index').write_bytes(b'original index bytes')
                (self.home / 'config.toml').write_text(self.config_text, encoding='utf-8')
                with self.assertRaises((RuntimeError, ValueError, OSError, subprocess.SubprocessError)):
                    self.verify_with(outcome)
                if outcome == 'changed-git-index':
                    self.assertEqual((self.gitdir / 'index').read_bytes(), b'changed staged state')

    def test_untrusted_attempt_preserves_evidence_and_leaves_fixture_retryable(self):
        unrelated = self.project / '.aid/.temp/unrelated/keep.txt'
        unrelated.parent.mkdir(parents=True)
        unrelated.write_text('keep', encoding='utf-8')
        before = measure.fixture_tree_sha256(self.project)
        with self.assertRaises((RuntimeError, ValueError, OSError)):
            self.verify_with('untrusted')
        self.assertEqual(measure.fixture_tree_sha256(self.project), before)
        self.assertEqual(unrelated.read_text(encoding='utf-8'), 'keep')
        evidence = self.project.parent / 'codex-hook-evidence'
        self.assertTrue(any(evidence.rglob('*.jsonl')))
        self.assertTrue(any(p.is_file() and p.name == 'git' for p in evidence.rglob('git')))
        self.assertTrue(any(p.is_file() and p.name == 'status' for p in evidence.rglob('status')))
        revision = 'a' * 40
        metadata = {'project': str(self.project.resolve()), 'scenario': 'fix', 'model': 'test-model',
                    'host': 'codex', 'mode': 'lean', 'codex_home': str(self.home.resolve()),
                    'fixture_head': revision, 'hook_sha256': hashlib.sha256(self.hook.read_bytes()).hexdigest(),
                    'handler_sha256': hashlib.sha256(self.handler.read_bytes()).hexdigest(),
                    'fixture_tree_sha256': before}
        (self.project.parent / 'benchmark-metadata.json').write_text(json.dumps(metadata), encoding='utf-8')
        with mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, revision + '\n', '')):
            reloaded, _, _ = measure.load_prepared_fixture(self.project.parent, 'fix', 'test-model', self.home)
        self.assertEqual(reloaded, self.project)
        self.verify_with('trusted')
        self.assertEqual(measure.fixture_tree_sha256(self.project), before)

    @unittest.skipUnless(sys.platform.startswith('linux'), 'symlink tamper fixture requires Linux/WSL')
    def test_probe_symlink_tamper_fails_without_touching_external_directory(self):
        with self.assertRaises((RuntimeError, ValueError, OSError)):
            self.verify_with('symlink-tamper')
        self.assertEqual((self.root / 'external-preserve/keep').read_text(encoding='utf-8'), 'outside')

    def test_missing_model_or_home_configuration_fails_without_cli(self):
        with mock.patch.object(measure, 'run', side_effect=AssertionError('CLI must not run')):
            with self.assertRaises((RuntimeError, ValueError)):
                measure.verify_trusted_hook(self.project, self.home, None, self.env)
            (self.home / 'config.toml').unlink()
            with self.assertRaises((RuntimeError, ValueError)):
                measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)

    def test_successful_guard_identity_blocks_each_changed_input_before_each_turn(self):
        guard = self.verify_with('trusted')
        originals = {path: path.read_bytes() for path in (self.hook, self.handler, self.home / 'config.toml', self.codex_bin)}
        other_project = self.root / 'other-project'
        other_project.mkdir()
        other_home = self.root / 'other-home'
        other_home.mkdir()
        (other_home / 'config.toml').write_text(self.config_text, encoding='utf-8')
        cases = ('hook', 'handler', 'config', 'trusted-entry', 'launcher', 'project', 'home')
        for name in cases:
            for path, content in originals.items():
                path.write_bytes(content)
            project = self.project
            env = dict(self.env)
            if name == 'hook':
                self.hook.write_text('{"changed": true}', encoding='utf-8')
            elif name == 'handler':
                self.handler.write_text('# changed handler\n', encoding='utf-8')
            elif name == 'config':
                (self.home / 'config.toml').write_text(self.config_text + '\n# changed\n', encoding='utf-8')
            elif name == 'trusted-entry':
                (self.home / 'config.toml').write_text(self.config_text.replace('a' * 64, 'b' * 64), encoding='utf-8')
            elif name == 'launcher':
                self.codex_bin.write_bytes(b'changed launcher')
            elif name == 'project':
                project = other_project
            elif name == 'home':
                env['CODEX_HOME'] = str(other_home)
            for session in (None, 'thread-123'):
                with self.subTest(name=name, session=session), \
                     mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)), \
                     mock.patch.object(measure, 'run', side_effect=AssertionError('model must not run')):
                    with self.assertRaises((RuntimeError, ValueError, OSError, SystemExit)):
                        measure.turn_codex(project, env, 'test-model', 'request', session, guard_identity=guard)

    def test_successful_guard_identity_allows_unchanged_fixture_in_mock_control_flow(self):
        guard = self.verify_with('trusted')
        output = events({'type': 'thread.started', 'thread_id': 'thread-123'},
                        {'type': 'item.completed', 'item': {'type': 'agent_message', 'text': 'done'}},
                        {'type': 'turn.completed', 'usage': {}})
        with mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)), \
             mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, output, '')) as run:
            measure.turn_codex(self.project, self.env, 'test-model', 'request', None, guard_identity=guard)
        self.assertEqual(run.call_count, 1)

    def test_fixture_with_git_remote_refuses_probe_before_codex(self):
        commands = []
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            if cmd[:2] == ['git', 'remote']:
                return subprocess.CompletedProcess(cmd, 0, 'origin\n', '')
            if Path(cmd[0]).name in ('codex', 'codex.exe'):
                raise AssertionError('Codex must not run when remote exists')
            return subprocess.CompletedProcess(cmd, 0, str(self.project) + '\n', '')
        with mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)):
            with self.assertRaises((RuntimeError, ValueError)):
                measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)
        self.assertTrue(any(cmd[:2] == ['git', 'remote'] for cmd in commands))

    def assert_project_config_rejected_before_probe_cli(self):
        def fake_run(cmd, cwd, env, stdin=None):
            if Path(cmd[0]).name in ('codex', 'codex.exe'):
                raise AssertionError('Codex must not run with unsafe project configuration')
            if cmd[:2] == ['git', 'remote']:
                return subprocess.CompletedProcess(cmd, 0, '', '')
            if cmd[:3] == ['git', 'rev-parse', 'HEAD']:
                return subprocess.CompletedProcess(cmd, 0, 'a' * 40 + '\n', '')
            return subprocess.CompletedProcess(cmd, 0, str(self.project) + '\n', '')
        with mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)):
            with self.assertRaises((RuntimeError, ValueError, OSError)):
                measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)

    def test_project_local_config_refused_before_native_probe(self):
        config = self.project / '.codex/config.toml'
        config.write_text('[mcp_servers.untrusted]\ncommand = "outside"\n', encoding='utf-8')
        before = config.read_bytes()
        self.assert_project_config_rejected_before_probe_cli()
        self.assertEqual(config.read_bytes(), before)

    def test_symlinked_codex_directory_refused_before_native_probe(self):
        directory = self.project / '.codex'
        target = self.root / 'outside-codex'
        directory.rename(target)
        try:
            directory.symlink_to(target, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        before = (target / 'hooks.json').read_bytes()
        self.assert_project_config_rejected_before_probe_cli()
        self.assertEqual((target / 'hooks.json').read_bytes(), before)

    def assert_invalid_git_layout_refuses_without_codex(self):
        hook_before = self.hook.read_bytes()
        handler_before = self.handler.read_bytes()
        def fake_run(cmd, cwd, env, stdin=None):
            if Path(cmd[0]).name in ('codex', 'codex.exe'):
                raise AssertionError('Codex must not run on an unowned Git layout')
            if cmd[:3] == ['git', 'rev-parse', 'HEAD']:
                return subprocess.CompletedProcess(cmd, 0, 'a' * 40 + '\n', '')
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure.shutil, 'which', return_value=str(self.codex_bin)):
            with self.assertRaises((RuntimeError, ValueError, OSError)):
                measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)
        self.assertEqual(self.hook.read_bytes(), hook_before)
        self.assertEqual(self.handler.read_bytes(), handler_before)

    def test_missing_git_config_refuses_without_model(self):
        (self.gitdir / 'config').unlink()
        self.assert_invalid_git_layout_refuses_without_codex()
        self.assertFalse((self.gitdir / 'config').exists())

    def test_git_pointer_file_refuses_without_model(self):
        shutil.rmtree(self.gitdir)
        self.gitdir.write_text('gitdir: ../other-repository\n', encoding='utf-8')
        before = self.gitdir.read_bytes()
        self.assert_invalid_git_layout_refuses_without_codex()
        self.assertEqual(self.gitdir.read_bytes(), before)

    def test_git_directory_symlink_refuses_without_model(self):
        shutil.rmtree(self.gitdir)
        other = self.root / 'other-git'
        other.mkdir()
        (other / 'config').write_text('keep', encoding='utf-8')
        try:
            self.gitdir.symlink_to(other, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        self.assert_invalid_git_layout_refuses_without_codex()
        self.assertEqual((other / 'config').read_text(encoding='utf-8'), 'keep')

    def test_git_config_symlink_refuses_without_model(self):
        config = self.gitdir / 'config'
        config.unlink()
        outside = self.root / 'outside-git-config'
        outside.write_text('keep', encoding='utf-8')
        try:
            config.symlink_to(outside)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        self.assert_invalid_git_layout_refuses_without_codex()
        self.assertEqual(outside.read_text(encoding='utf-8'), 'keep')

    def test_extra_private_config_settings_are_rejected_before_cli(self):
        for extra in ('model = "other"\n', 'web_search = "live"\n',
                      '[mcp_servers.evil]\ncommand = "outside"\n',
                      '[model_providers.other]\nbase_url = "https://outside.invalid"\n',
                      '[tui]\nunexpected = true\n', '[hooks]\nunexpected = true\n'):
            with self.subTest(extra=extra):
                # Top-level values must precede the first TOML table.
                if extra.startswith('[tui]'):
                    config = self.config_text.replace('[tui]\n', '[tui]\nunexpected = true\n', 1)
                elif extra.startswith('[hooks]'):
                    config = self.config_text + '[hooks]\nunexpected = true\n'
                else:
                    config = extra + self.config_text if not extra.startswith('[') else self.config_text + extra
                (self.home / 'config.toml').write_text(config, encoding='utf-8')
                with mock.patch.object(measure, 'run', side_effect=AssertionError('CLI must not run')):
                    with self.assertRaises((RuntimeError, ValueError)):
                        measure.verify_trusted_hook(self.project, self.home, 'test-model', self.env)


class HostDispatch(unittest.TestCase):
    def setUp(self):
        # Dispatch tests mock the host; CLI-version behavior has its own tests.
        for module in (measure, repo_task):
            version = mock.patch.object(module, 'require_supported_codex_version', return_value='0.164.0')
            version.start()
            self.addCleanup(version.stop)
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='host-dispatch-', dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.dir = Path(self.temp.name)
        self.project = self.dir / 'project'
        self.project.mkdir()
        self.codex_home = self.dir / 'private-codex'
        self.codex_home.mkdir()
        (self.codex_home / 'config.toml').write_text('[tui]\nscreen_reader_detection_done = true\n', encoding='utf-8')

    def fake_codex(self, project, env, model, message, session, *, guard_identity=None):
        self.messages.append(message)
        if hasattr(self, 'guards'):
            self.guards.append(guard_identity)
        return {'session': 'fixture-thread', 'messages': ['Done.'], 'tools': {}, 'dispatches': 0,
                'writer_calls': 0, 'start_context': None,
                'result': {'result': 'Done.', 'total_cost_usd': None, 'usage': {'input_tokens': 5, 'output_tokens': 2}}}

    def test_verified_hook_request_gets_one_evidence_backed_followup(self):
        self.messages = []
        guard = {'project': str(self.project)}
        def turn(project, env, model, message, session, *, guard_identity=None):
            self.messages.append(message)
            text = ('The hook is installed. Please review and trust it in Codex /hooks.'
                    if len(self.messages) == 1 else 'Done.')
            return {'session': 'fixture-thread', 'start_context': None, 'tools': {},
                    'result': {'result': text, 'usage': {'input_tokens': 1, 'output_tokens': 1}}}
        grade = {'hidden_pass': True, 'tests_pass': True, 'code_files_changed': 1}
        with mock.patch.object(measure, 'setup', return_value=(self.project, {})), \
             mock.patch.object(measure, 'verify_trusted_hook', return_value=guard), \
             mock.patch.object(measure, 'turn_codex', side_effect=turn), \
             mock.patch.object(measure, 'locations', return_value=[self.project]), \
             mock.patch.object(measure, 'grade', return_value=grade), \
             contextlib.redirect_stderr(io.StringIO()):
            result = measure.measure('fix', True, 2, 'test-model', self.dir / 'bundle',
                                     lean=True, host='codex', codex_home=self.codex_home)
        self.assertEqual(len(self.messages), 2)
        self.assertIn('native preflight', self.messages[1])
        self.assertIn('blocked', self.messages[1])
        self.assertTrue(result['trust_evidence_followup'])

    def test_mixed_and_repeated_trust_requests_do_not_receive_another_reply(self):
        for mixed in ('none', 'question', 'imperative'):
            with self.subTest(mixed=mixed):
                messages = []
                def turn(project, env, model, message, session, *, guard_identity=None):
                    messages.append(message)
                    text = 'Please review and trust it in Codex /hooks.'
                    if mixed == 'question':
                        text += ' Which option should I use?'
                    elif mixed == 'imperative':
                        text += ' Please confirm the release.'
                    return {'session': 'fixture-thread', 'start_context': None, 'tools': {},
                            'result': {'result': text, 'usage': {'input_tokens': 1, 'output_tokens': 1}}}
                grade = {'hidden_pass': False, 'tests_pass': True, 'code_files_changed': 0}
                with mock.patch.object(measure, 'setup', return_value=(self.project, {})), \
                     mock.patch.object(measure, 'verify_trusted_hook', return_value={'project': str(self.project)}), \
                     mock.patch.object(measure, 'turn_codex', side_effect=turn), \
                     mock.patch.object(measure, 'locations', return_value=[self.project]), \
                     mock.patch.object(measure, 'grade', return_value=grade), \
                     contextlib.redirect_stderr(io.StringIO()):
                    result = measure.measure('fix', True, 5, 'test-model', self.dir / 'bundle',
                                             lean=True, host='codex', codex_home=self.codex_home)
                self.assertEqual(len(messages), 2 if mixed == 'none' else 1)
                self.assertFalse(result['finished_asking'])
                self.assertEqual(result['trust_evidence_followup'] is None, mixed != 'none')

    def test_turn_limit_does_not_claim_unsent_trust_followup(self):
        def turn(project, env, model, message, session, *, guard_identity=None):
            return {'session': 'fixture-thread', 'start_context': None, 'tools': {},
                    'result': {'result': 'Please review and trust it in Codex /hooks.',
                               'usage': {'input_tokens': 1, 'output_tokens': 1}}}
        grade = {'hidden_pass': False, 'tests_pass': True, 'code_files_changed': 0}
        with mock.patch.object(measure, 'setup', return_value=(self.project, {})), \
             mock.patch.object(measure, 'verify_trusted_hook', return_value={'project': str(self.project)}), \
             mock.patch.object(measure, 'turn_codex', side_effect=turn), \
             mock.patch.object(measure, 'locations', return_value=[self.project]), \
             mock.patch.object(measure, 'grade', return_value=grade), \
             contextlib.redirect_stderr(io.StringIO()):
            result = measure.measure('fix', True, 1, 'test-model', self.dir / 'bundle',
                                     lean=True, host='codex', codex_home=self.codex_home)
        self.assertIsNone(result['trust_evidence_followup'])
        self.assertFalse(result['finished_asking'])

    def test_small_setup_installs_codex_without_touching_claude_credentials(self):
        work = self.dir / 'work'
        bundle = self.dir / 'bundle'
        work.mkdir()
        bundle.mkdir()
        commands = []
        def copy_fixture(source, destination):
            Path(destination).mkdir()
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.object(measure.shutil, 'copytree', side_effect=copy_fixture), \
             mock.patch.object(measure.shutil, 'copy2', side_effect=AssertionError('credential copy forbidden')), \
             mock.patch.object(Path, 'home', side_effect=AssertionError('Claude home access forbidden')), \
             mock.patch.object(measure, 'run', side_effect=fake_run):
            project, env = measure.setup(work, True, bundle, host='codex', codex_home=self.codex_home)
        self.assertEqual(project, work / 'project')
        self.assertEqual(Path(env['CODEX_HOME']), self.codex_home)
        install = [cmd for cmd in commands if '--from-bundle' in cmd]
        self.assertEqual(len(install), 1)
        self.assertIn('codex', install[0])
        self.assertNotIn('claude-code', install[0])

    def test_small_codex_lean_activates_hook_and_failure_stops_setup(self):
        bundle = self.dir / 'hook-bundle'
        bundle.mkdir()
        for lean, aid, activation_status in ((True, True, 0), (True, True, 1),
                                             (False, True, 0), (False, False, 0)):
            work = self.dir / f'hook-small-{lean}-{aid}-{activation_status}'
            work.mkdir()
            commands = []
            def fake_run(cmd, cwd, env, stdin=None):
                commands.append(cmd)
                activation = any('codex_hook_config.py' in str(arg) for arg in cmd)
                return subprocess.CompletedProcess(cmd, activation_status if activation else 0, '', '')
            with self.subTest(lean=lean, aid=aid, activation_status=activation_status), \
                 mock.patch.object(measure.shutil, 'copytree', side_effect=lambda src, dst: Path(dst).mkdir()), \
                 mock.patch.object(measure, 'run', side_effect=fake_run):
                if activation_status:
                    with self.assertRaises((SystemExit, RuntimeError)):
                        measure.setup(work, aid, bundle, host='codex', codex_home=self.codex_home, lean=lean)
                else:
                    measure.setup(work, aid, bundle, host='codex', codex_home=self.codex_home, lean=lean)
            activation_indexes = [i for i, cmd in enumerate(commands)
                                  if any('codex_hook_config.py' in str(arg) for arg in cmd)]
            self.assertEqual(len(activation_indexes), int(lean and aid))
            if activation_indexes:
                i = activation_indexes[0]
                self.assertTrue(any('init' in cmd for cmd in commands[:i]), 'hook needs initialized Git')
                self.assertIn('install', commands[i])

    def test_brownfield_codex_lean_activates_hook_and_failure_stops_setup(self):
        bundle = self.dir / 'hook-repo-bundle'
        bundle.mkdir()
        for lean, aid, activation_status in ((True, True, 0), (True, True, 1),
                                             (False, True, 0), (False, False, 0)):
            out = self.dir / f'hook-repo-{lean}-{aid}-{activation_status}'
            out.mkdir()
            commands = []
            def fake_run(cmd, cwd, env, stdin=None):
                commands.append(cmd)
                if cmd[:2] == ['git', 'clone']:
                    Path(cmd[-1]).mkdir(parents=True)
                if '--from-bundle' in cmd:
                    project = out / 'project'
                    for rel in ('.agents/skills/aid-change/SKILL.md', '.aid/runtime/scripts/change/checks.py'):
                        marker = project / rel
                        marker.parent.mkdir(parents=True, exist_ok=True)
                        marker.write_text('present', encoding='utf-8')
                activation = any('codex_hook_config.py' in str(arg) for arg in cmd)
                return subprocess.CompletedProcess(cmd, activation_status if activation else 0, '', '')
            with self.subTest(lean=lean, aid=aid, activation_status=activation_status), \
                 mock.patch.object(repo_task.shutil, 'copytree'), mock.patch.object(repo_task, 'run', side_effect=fake_run):
                if activation_status:
                    with self.assertRaises((SystemExit, RuntimeError)):
                        repo_task.setup(out, 'site', aid, 'a' * 40, lean_bundle=bundle if lean else None,
                                        host='codex', codex_home=self.codex_home)
                else:
                    repo_task.setup(out, 'site', aid, 'a' * 40, lean_bundle=bundle if lean else None,
                                    host='codex', codex_home=self.codex_home)
            activation_indexes = [i for i, cmd in enumerate(commands)
                                  if any('codex_hook_config.py' in str(arg) for arg in cmd)]
            self.assertEqual(len(activation_indexes), int(lean and aid))
            if activation_indexes:
                self.assertTrue(any('--from-bundle' in cmd for cmd in commands[:activation_indexes[0]]))
                self.assertIn('install', commands[activation_indexes[0]])

    def test_brownfield_setup_installs_codex_mirror_without_claude_credentials(self):
        out, bundle = self.dir / 'out', self.dir / 'bundle'
        out.mkdir()
        bundle.mkdir()
        commands = []
        def native_path(value):
            if os.name == 'nt' and len(value) > 3 and value[0] == '/' and value[2] == '/':
                return Path(value[1].upper() + ':/' + value[3:])
            return Path(value)
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            if cmd[:2] == ['git', 'clone']:
                Path(cmd[-1]).mkdir(parents=True)
            if '--from-bundle' in cmd:
                project = native_path(cmd[cmd.index('--target') + 1])
                for rel in ('.agents/skills/aid-change/SKILL.md', '.aid/runtime/scripts/change/checks.py'):
                    marker = project / rel
                    marker.parent.mkdir(parents=True, exist_ok=True)
                    marker.write_text('present', encoding='utf-8')
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.object(repo_task, 'run', side_effect=fake_run), \
             mock.patch.object(repo_task.shutil, 'copytree'), \
             mock.patch.object(repo_task.shutil, 'copy2', side_effect=AssertionError('credential copy forbidden')), \
             mock.patch.object(Path, 'home', side_effect=AssertionError('Claude home access forbidden')):
            _, env = repo_task.setup(out, 'site', True, 'old-revision', lean_bundle=bundle,
                                     host='codex', codex_home=self.codex_home)
        self.assertEqual(Path(env['CODEX_HOME']), self.codex_home)
        install = [cmd for cmd in commands if '--from-bundle' in cmd]
        self.assertEqual(len(install), 1)
        self.assertIn('codex', install[0])
        self.assertNotIn('claude-code', install[0])

    def test_codex_plain_brownfield_removes_only_aid_agent_definitions(self):
        out = self.dir / 'plain-out'
        out.mkdir()
        def fake_run(cmd, cwd, env, stdin=None):
            if cmd[:2] == ['git', 'clone']:
                project = Path(cmd[-1])
                agents = project / '.codex/agents'
                agents.mkdir(parents=True)
                (agents / 'aid-reviewer.toml').write_text('aid')
                (agents / 'user-agent.toml').write_text('user')
                (project / '.codex/hooks.json').write_text('{"hooks": {}}')
                (project / '.codex/config.toml').write_text('# user config')
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.object(repo_task, 'run', side_effect=fake_run), \
             mock.patch.object(repo_task.shutil, 'copytree'):
            project, _ = repo_task.setup(out, 'site', False, 'rev', host='codex', codex_home=self.codex_home)
        self.assertFalse((project / '.codex/agents/aid-reviewer.toml').exists())
        self.assertEqual((project / '.codex/agents/user-agent.toml').read_text(), 'user')
        self.assertEqual((project / '.codex/hooks.json').read_text(), '{"hooks": {}}')
        self.assertEqual((project / '.codex/config.toml').read_text(), '# user config')

    def test_codex_environment_does_not_inherit_host_secrets_or_userprofile(self):
        sensitive = {'OPENAI_API_KEY': 'secret', 'ANTHROPIC_API_KEY': 'secret',
                     'CLAUDE_CODE_OAUTH_TOKEN': 'secret', 'GITHUB_TOKEN': 'secret',
                     'USERPROFILE': 'real-user-profile'}
        work, bundle = self.dir / 'clean-work', self.dir / 'clean-bundle'
        work.mkdir()
        bundle.mkdir()
        with mock.patch.dict(os.environ, sensitive), \
             mock.patch.object(measure.shutil, 'copytree', side_effect=lambda src, dst: Path(dst).mkdir()), \
             mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')):
            _, env = measure.setup(work, False, bundle, host='codex', codex_home=self.codex_home)
        for key in sensitive:
            self.assertNotEqual(env.get(key), sensitive[key], key)
        self.assertEqual(Path(env['CODEX_HOME']), self.codex_home)
        out = self.dir / 'clean-repo'
        out.mkdir()
        def fake_run(cmd, cwd, env, stdin=None):
            if cmd[:2] == ['git', 'clone']:
                Path(cmd[-1]).mkdir()
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.dict(os.environ, sensitive), \
             mock.patch.object(repo_task, 'run', side_effect=fake_run), \
             mock.patch.object(repo_task.shutil, 'copytree'):
            _, repo_env = repo_task.setup(out, 'site', False, 'rev', host='codex', codex_home=self.codex_home)
        for key in sensitive:
            self.assertNotEqual(repo_env.get(key), sensitive[key], key)
        self.assertEqual(Path(repo_env['CODEX_HOME']), self.codex_home)

    def test_codex_temporary_paths_ignore_ambient_directories(self):
        home = self.dir / 'temp-home'
        ambient = str(self.dir / 'ambient-temp')
        parent = {'PATH': os.environ.get('PATH', ''), 'AID_HOME': str(self.dir / 'state'),
                  'TMP': ambient, 'TEMP': ambient, 'TMPDIR': ambient}
        env = measure.codex_env(parent, home, self.codex_home)
        for key in ('TMP', 'TEMP', 'TMPDIR'):
            self.assertIn(key, env)
            self.assertNotEqual(env[key], ambient)
            self.assertTrue(Path(env[key]).resolve().is_relative_to(self.dir.resolve()), env[key])

    def test_codex_brownfield_clone_has_isolated_environment(self):
        out = self.dir / 'clone-isolation'
        out.mkdir()
        observed = []
        def fake_run(cmd, cwd, env, stdin=None):
            if cmd[:2] == ['git', 'clone']:
                observed.append(dict(env))
                Path(cmd[-1]).mkdir()
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.dict(os.environ, {'OPENAI_API_KEY': 'do-not-inherit', 'TMP': 'ambient-tmp',
                                         'TEMP': 'ambient-temp', 'TMPDIR': 'ambient-tmpdir'}), \
             mock.patch.object(repo_task, 'run', side_effect=fake_run), \
             mock.patch.object(repo_task.shutil, 'copytree'):
            repo_task.setup(out, 'site', False, 'rev', host='codex', codex_home=self.codex_home)
        self.assertEqual(len(observed), 1)
        self.assertFalse('OPENAI_API_KEY' in observed[0], 'clone inherited OPENAI_API_KEY')
        for key in ('TMP', 'TEMP', 'TMPDIR'):
            self.assertTrue(Path(observed[0][key]).resolve().is_relative_to(out.resolve()), observed[0][key])

    def test_codex_requires_explicit_model_before_setup(self):
        for module, argv in ((measure, ['measure.py', '--host', 'codex', '--no-aid', '--codex-home', str(self.codex_home)]),
                             (repo_task, ['repo_task.py', '--host', 'codex', '--no-aid', '--codex-home', str(self.codex_home),
                                          '--out', str(self.dir / 'no-model')])):
            with self.subTest(module=module.__name__), mock.patch.object(sys, 'argv', argv), \
                 mock.patch.object(module, 'setup', side_effect=AssertionError('setup must not run')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as error:
                    module.main()
                self.assertNotEqual(error.exception.code, 0)

    def test_all_codex_modes_reject_unsafe_private_config_before_model_in_both_drivers(self):
        config = self.codex_home / 'config.toml'
        original = '[mcp_servers.untrusted]\ncommand = "unexpected"\n'
        config.write_text(original, encoding='utf-8')
        bundle = self.dir / 'unsafe-bundle'
        bundle.mkdir()
        cases = []
        for mode, flags in (('plain', ['--no-aid']), ('aid', []), ('lean', ['--lean'])):
            common = ['--host', 'codex', '--turns', '1', '--codex-home', str(self.codex_home),
                      '--model', 'test-model', *flags]
            cases.append((measure, mode, ['measure.py', '--runs', '1', *common]))
            repo_flags = ['--lean-bundle', str(bundle)] if mode == 'lean' else []
            cases.append((repo_task, mode, ['repo_task.py', '--out', str(self.dir / ('unsafe-repo-' + mode)),
                                            *common, *repo_flags]))
        for module, mode, argv in cases:
            def fake_setup(*args, **kwargs):
                project = Path(args[0]) / 'project' if module is repo_task else self.project
                project.mkdir(parents=True, exist_ok=True)
                return project, {'CODEX_HOME': str(self.codex_home)}
            with self.subTest(module=module.__name__, mode=mode), mock.patch.object(sys, 'argv', argv), \
                 mock.patch.object(module, 'setup', side_effect=fake_setup), \
                 mock.patch.object(module, 'verify_trusted_hook', return_value=None, create=True), \
                 mock.patch.object(module, 'turn_codex', side_effect=AssertionError('model must not run')), \
                 mock.patch.object(module, 'run', return_value=subprocess.CompletedProcess([], 0, 'a' * 40 + '\n', '')), \
                 mock.patch.object(measure.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises((SystemExit, RuntimeError, ValueError)):
                    module.main()
            self.assertEqual(config.read_text(encoding='utf-8'), original)

    def test_small_benchmark_uses_codex_and_records_host_without_cost(self):
        self.messages = []
        self.guards = []
        guard = {'project': str(self.project)}
        grade = {'hidden_pass': True, 'tests_pass': True, 'code_files_changed': 1}
        output = io.StringIO()
        with mock.patch.object(sys, 'argv', ['measure.py', '--host', 'codex', '--scenario', 'fix',
                                           '--runs', '1', '--turns', '1', '--lean',
                                           '--codex-home', str(self.codex_home), '--model', 'test-model']), \
             mock.patch.object(measure, 'setup', return_value=(self.project, {})), \
             mock.patch.object(measure, 'verify_trusted_hook', return_value=guard, create=True) as verify, \
             mock.patch.object(measure, 'turn', side_effect=AssertionError('Claude must not be called')), \
             mock.patch.object(measure, 'turn_codex', side_effect=self.fake_codex), \
             mock.patch.object(measure, 'locations', return_value=[self.project]), \
             mock.patch.object(measure, 'grade', return_value=grade), \
             mock.patch.object(measure.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(measure.main(), 0)
        result = json.loads(output.getvalue().strip())
        self.assertEqual(result['host'], 'codex')
        self.assertEqual(result['mode'], 'lean')
        verify.assert_called_once_with(self.project, self.codex_home, 'test-model', mock.ANY)
        self.assertEqual(self.guards, [guard])
        self.assertIsNone(result['cost_usd'])
        self.assertIsNone(result['agent_turns'])
        self.assertTrue(self.messages[0].startswith('/aid-change '))
        self.assertIn('native preflight', self.messages[0])
        self.assertIn('native preflight', result['trust_preflight_context'])

    def test_codex_measure_scratch_is_created_in_project(self):
        self.messages = []
        work = self.dir / 'work'
        work.mkdir()
        grade = {'hidden_pass': True, 'tests_pass': True, 'code_files_changed': 1}
        with mock.patch.object(measure.tempfile, 'mkdtemp', return_value=str(work)) as mkdtemp, \
             mock.patch.object(measure, 'setup', return_value=(self.project, {})), \
             mock.patch.object(measure, 'verify_trusted_hook', return_value=None, create=True), \
             mock.patch.object(measure, 'turn_codex', side_effect=self.fake_codex), \
             mock.patch.object(measure, 'locations', return_value=[self.project]), \
             mock.patch.object(measure, 'grade', return_value=grade), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            measure.measure('fix', True, 1, 'test-model', self.dir / 'bundle', lean=True, host='codex',
                            codex_home=self.codex_home)
        scratch = mkdtemp.call_args.kwargs.get('dir')
        self.assertIsNotNone(scratch, 'scratch location must be explicitly project-local')
        self.assertTrue(Path(scratch).resolve().is_relative_to(ROOT.resolve()), scratch)

    def test_lean_small_benchmark_stops_when_exact_fixture_trust_is_unverified(self):
        work = self.dir / 'untrusted-small'
        work.mkdir()
        config = self.project / '.codex/hooks.json'
        config.parent.mkdir()
        config.write_text('{"hooks": {"PreToolUse": []}}', encoding='utf-8')
        (self.codex_home / 'config.toml').write_text('# config is not proof of host trust', encoding='utf-8')
        with mock.patch.object(measure.tempfile, 'mkdtemp', return_value=str(work)), \
             mock.patch.object(measure, 'setup', return_value=(self.project, {'CODEX_HOME': str(self.codex_home)})), \
             mock.patch.object(measure, 'verify_trusted_hook', side_effect=RuntimeError('trust not verified'), create=True) as verify, \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')):
            with self.assertRaises((RuntimeError, SystemExit)):
                measure.measure('fix', True, 1, 'test-model', self.dir / 'bundle', lean=True,
                                host='codex', codex_home=self.codex_home)
        verify.assert_called_once_with(self.project, self.codex_home, 'test-model', mock.ANY)
        self.assertEqual(verify.call_args.args[3]['CODEX_HOME'], str(self.codex_home))

    def test_lean_brownfield_stops_when_exact_fixture_trust_is_unverified(self):
        out, bundle = self.dir / 'untrusted-repo', self.dir / 'untrusted-bundle'
        project = out / 'project'
        project.mkdir(parents=True)
        bundle.mkdir()
        hooks = project / '.codex/hooks.json'
        hooks.parent.mkdir()
        hooks.write_text('{"hooks": {"PreToolUse": []}}', encoding='utf-8')
        argv = ['repo_task.py', '--host', 'codex', '--lean', '--lean-bundle', str(bundle), '--out', str(out),
                '--turns', '1', '--codex-home', str(self.codex_home), '--model', 'test-model']
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(repo_task, 'setup', return_value=(project, {'CODEX_HOME': str(self.codex_home)})), \
             mock.patch.object(repo_task, 'verify_trusted_hook', side_effect=RuntimeError('trust not verified'), create=True) as verify, \
             mock.patch.object(repo_task, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(repo_task, 'run', return_value=subprocess.CompletedProcess([], 0, 'a' * 40 + '\n', '')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((RuntimeError, SystemExit)):
                repo_task.main()
        verify.assert_called_once_with(project, self.codex_home, 'test-model', mock.ANY)
        self.assertEqual(verify.call_args.args[3]['CODEX_HOME'], str(self.codex_home))

    def test_lean_brownfield_routes_verified_guard_to_each_turn_and_resume(self):
        bundle = self.dir / 'guarded-bundle'
        bundle.mkdir()
        revision = 'a' * 40
        guard = mock.sentinel.verified_guard
        for resumed in (False, True):
            out = self.dir / ('guarded-resume' if resumed else 'guarded-new')
            project = out / 'project'
            project.mkdir(parents=True)
            if resumed:
                metadata = {'commit': revision, 'prepared_head': revision, 'project': str(project.resolve()),
                            'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'lean'}
                (out / 'benchmark-metadata.json').write_text(json.dumps(metadata), encoding='utf-8')
            argv = ['repo_task.py', '--host', 'codex', '--lean', '--out', str(out), '--turns', '1',
                    '--codex-home', str(self.codex_home), '--model', 'test-model']
            argv += ['--resume', 'thread-123', '--cwd', str(project)] if resumed else ['--lean-bundle', str(bundle)]
            self.messages, self.guards = [], []
            with self.subTest(resumed=resumed), mock.patch.object(sys, 'argv', argv), \
                 mock.patch.object(repo_task, 'setup', return_value=(project, {'CODEX_HOME': str(self.codex_home)})), \
                 mock.patch.object(repo_task, 'verify_trusted_hook', return_value=guard, create=True) as verify, \
                 mock.patch.object(repo_task, 'turn_codex', side_effect=self.fake_codex), \
                 mock.patch.object(repo_task, 'run', return_value=subprocess.CompletedProcess([], 0, revision + '\n', '')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(repo_task.main(), 0)
            verify.assert_called_once_with(project, self.codex_home, 'test-model', mock.ANY)
            self.assertEqual(self.guards, [guard])

    def test_private_config_or_caller_marker_does_not_prove_trust(self):
        config = self.project / '.codex/hooks.json'
        config.parent.mkdir()
        config.write_text('{"hooks": {"PreToolUse": []}}', encoding='utf-8')
        (self.codex_home / 'config.toml').write_text('trusted = true\n', encoding='utf-8')
        with self.assertRaises((RuntimeError, SystemExit, ValueError)):
            measure.verify_trusted_hook(self.project, self.codex_home, 'test-model', {'CODEX_HOME': str(self.codex_home)})

    def test_lean_resume_reverifies_same_fixture_before_model(self):
        out = self.dir / 'untrusted-resume'
        project = out / 'project'
        project.mkdir(parents=True)
        revision = 'a' * 40
        metadata = {'commit': revision, 'prepared_head': revision, 'project': str(project.resolve()),
                    'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'lean'}
        (out / 'benchmark-metadata.json').write_text(json.dumps(metadata), encoding='utf-8')
        argv = ['repo_task.py', '--host', 'codex', '--lean', '--out', str(out), '--resume', 'thread-123',
                '--cwd', str(project), '--turns', '1', '--codex-home', str(self.codex_home), '--model', 'test-model']
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(repo_task, 'verify_trusted_hook', side_effect=RuntimeError('trust not verified'), create=True) as verify, \
             mock.patch.object(repo_task, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(repo_task, 'run', return_value=subprocess.CompletedProcess([], 0, revision + '\n', '')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((RuntimeError, SystemExit)):
                repo_task.main()
        verify.assert_called_once_with(project, self.codex_home, 'test-model', mock.ANY)
        self.assertEqual(verify.call_args.args[3]['CODEX_HOME'], str(self.codex_home))

    def test_brownfield_plain_mode_uses_codex_without_aid_prefix(self):
        self.messages = []
        output = io.StringIO()
        out = self.dir / 'out'
        project = out / 'project'
        project.mkdir(parents=True)
        revision = 'a' * 40
        prepared = 'b' * 40
        def fake_git(cmd, cwd, env, stdin=None):
            result = prepared if Path(cwd).resolve() == project.resolve() and cmd[:3] == ['git', 'rev-parse', 'HEAD'] else revision
            return subprocess.CompletedProcess(cmd, 0, result + '\n', '')
        with mock.patch.object(sys, 'argv', ['repo_task.py', '--host', 'codex', '--no-aid',
                                           '--out', str(self.dir / 'out'), '--turns', '1',
                                           '--codex-home', str(self.codex_home), '--model', 'test-model']), \
             mock.patch.object(repo_task, 'setup', return_value=(project, {})), \
             mock.patch.object(repo_task, 'turn', side_effect=AssertionError('Claude must not be called')), \
             mock.patch.object(repo_task, 'turn_codex', side_effect=self.fake_codex), \
             mock.patch.object(repo_task, 'run', side_effect=fake_git), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(repo_task.main(), 0)
        result = json.loads(output.getvalue().strip())
        self.assertEqual(result['host'], 'codex')
        self.assertEqual(result['mode'], 'plain')
        self.assertIsNone(result['cost_usd'])
        self.assertIsNone(result['agent_turns'])
        self.assertFalse(self.messages[0].startswith('/aid-'))
        metadata = json.loads((out / 'benchmark-metadata.json').read_text(encoding='utf-8'))
        self.assertEqual(metadata['commit'], revision)
        self.assertEqual(metadata['prepared_head'], prepared)
        self.assertEqual(Path(metadata['project']), project.resolve())
        self.assertEqual(metadata['host'], 'codex')
        self.assertEqual(metadata['model'], 'test-model')
        self.assertEqual(metadata['task'], 'site')
        self.assertEqual(metadata['mode'], 'plain')

    def test_lean_and_no_aid_rejected_for_codex_before_setup(self):
        for module, argv in ((measure, ['measure.py', '--host', 'codex', '--lean', '--no-aid']),
                             (repo_task, ['repo_task.py', '--host', 'codex', '--lean', '--no-aid',
                                          '--out', str(self.dir / 'invalid')])):
            with self.subTest(module=module.__name__), mock.patch.object(sys, 'argv', argv), \
                 mock.patch.object(module, 'setup', side_effect=AssertionError('setup must not run')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as error:
                    module.main()
                self.assertNotEqual(error.exception.code, 0)

    def test_invalid_codex_homes_are_rejected_before_any_setup(self):
        missing = self.dir / 'missing'
        not_directory = self.dir / 'file'
        not_directory.write_text('not a directory', encoding='utf-8')
        bad_paths = [None, missing, not_directory, ROOT]
        # An in-root symlink to another in-root directory must not be accepted.
        link = self.dir / 'alias'
        try:
            link.symlink_to(self.codex_home, target_is_directory=True)
        except OSError:
            pass  # Windows may not allow symlink creation for this account.
        else:
            bad_paths.append(link)
            (self.codex_home / 'child').mkdir()
            bad_paths.append(link / 'child')
        for module, prefix in ((measure, ['measure.py', '--host', 'codex', '--no-aid']),
                               (repo_task, ['repo_task.py', '--host', 'codex', '--no-aid',
                                            '--out', str(self.dir / 'invalid-out')])):
            for value in bad_paths:
                argv = prefix + ['--model', 'test-model'] + ([] if value is None else ['--codex-home', str(value)])
                with self.subTest(module=module.__name__, value=value), \
                     mock.patch.object(sys, 'argv', argv), \
                     mock.patch.object(module, 'setup', side_effect=AssertionError('setup must not run')), \
                     contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as error:
                        module.main()
                    self.assertNotEqual(error.exception.code, 0)

    def test_valid_codex_home_is_passed_to_both_drivers_and_normal_home_is_untouched(self):
        original = str(self.dir / 'untouched-user-home')
        with mock.patch.dict(os.environ, {'CODEX_HOME': original}):
            for module, prefix in ((measure, ['measure.py', '--host', 'codex', '--no-aid', '--turns', '1', '--runs', '1']),
                                   (repo_task, ['repo_task.py', '--host', 'codex', '--no-aid', '--turns', '1',
                                                '--out', str(self.dir / 'valid-out')])):
                captured = []
                def fake_setup(*args, **kwargs):
                    captured.append(kwargs)
                    project = Path(args[0]) / 'project' if module is repo_task else self.project
                    project.mkdir(parents=True, exist_ok=True)
                    return project, {'CODEX_HOME': str(self.codex_home)}
                turn_envs = []
                def checked_turn(*args, **kwargs):
                    turn_envs.append(args[1])
                    return self.fake_codex(*args, **kwargs)
                self.messages = []
                grade = {'hidden_pass': True, 'tests_pass': True, 'code_files_changed': 1}
                argv = prefix + ['--codex-home', str(self.codex_home), '--model', 'test-model']
                with self.subTest(module=module.__name__), mock.patch.object(sys, 'argv', argv), \
                     mock.patch.object(module, 'setup', side_effect=fake_setup), \
                     mock.patch.object(module, 'turn_codex', side_effect=checked_turn), \
                     mock.patch.object(module, 'run', return_value=subprocess.CompletedProcess([], 0, 'a' * 40 + '\n', '')), \
                     mock.patch.object(measure, 'locations', return_value=[self.project]), \
                     mock.patch.object(measure, 'grade', return_value=grade), \
                     contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(module.main(), 0)
                self.assertEqual(Path(captured[0]['codex_home']), self.codex_home)
                self.assertEqual(Path(turn_envs[0]['CODEX_HOME']), self.codex_home)
                self.assertEqual(os.environ['CODEX_HOME'], original)

    def test_codex_resume_uses_private_home(self):
        self.messages = []
        observed_env = []
        out = self.dir / 'resume'
        out.mkdir()
        project = out / 'project'
        project.mkdir()
        revision = 'a' * 40
        prepared = 'b' * 40
        current = 'c' * 40
        metadata = {'commit': revision, 'prepared_head': prepared, 'project': str(project.resolve()), 'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'plain'}
        meta_path = out / 'benchmark-metadata.json'
        meta_path.write_text(json.dumps(metadata), encoding='utf-8')
        metadata_before = meta_path.read_bytes()
        def fake_turn(project, env, model, message, session):
            observed_env.append(env)
            return self.fake_codex(project, env, model, message, session)
        git_calls = []
        def fake_git(cmd, cwd, env, stdin=None):
            git_calls.append(cmd)
            value = current if cmd[:3] == ['git', 'rev-parse', 'HEAD'] else revision
            return subprocess.CompletedProcess(cmd, 0, value + '\n', '')
        argv = ['repo_task.py', '--host', 'codex', '--no-aid', '--out', str(out),
                '--resume', 'fixture-thread', '--cwd', str(project), '--turns', '1',
                '--codex-home', str(self.codex_home), '--model', 'test-model']
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(repo_task, 'setup', side_effect=AssertionError('resume must not setup')), \
             mock.patch.object(repo_task, 'turn_codex', side_effect=fake_turn), \
             mock.patch.object(repo_task, 'run', side_effect=fake_git), \
             mock.patch.dict(os.environ, {'CODEX_HOME': str(self.dir / 'untouched-user-home')}), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(repo_task.main(), 0)
        self.assertEqual(Path(observed_env[0]['CODEX_HOME']), self.codex_home)
        self.assertEqual(meta_path.read_bytes(), metadata_before)
        self.assertTrue(any(cmd[:3] == ['git', 'merge-base', '--is-ancestor'] and prepared in cmd for cmd in git_calls))
        self.assertTrue(any(cmd[:3] == ['git', 'merge-base', '--is-ancestor'] and revision in cmd for cmd in git_calls))

    def test_resume_rejects_missing_or_mismatched_metadata_before_model(self):
        revision = 'a' * 40
        out = self.dir / 'invalid-resume'
        out.mkdir()
        project = out / 'project'
        project.mkdir()
        metadata_path = out / 'benchmark-metadata.json'
        good = {'commit': revision, 'prepared_head': 'b' * 40, 'project': str(project.resolve()), 'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'plain'}
        cases = [None, dict(good, commit='b' * 40), dict(good, project=str(self.project.resolve())),
                 dict(good, host='claude'), dict(good, model='other-model'),
                 dict(good, task='different-task'), dict(good, mode='lean'),
                 {k: v for k, v in good.items() if k not in ('task', 'mode')}]
        argv = ['repo_task.py', '--host', 'codex', '--no-aid', '--out', str(out),
                '--resume', 'fixture-thread', '--cwd', str(project), '--turns', '1',
                '--codex-home', str(self.codex_home), '--model', 'test-model']
        for metadata in cases:
            metadata_path.unlink(missing_ok=True)
            if metadata is not None:
                metadata_path.write_text(json.dumps(metadata), encoding='utf-8')
            before = metadata_path.read_bytes() if metadata_path.exists() else None
            with self.subTest(metadata=metadata), mock.patch.object(sys, 'argv', argv), \
                 mock.patch.object(repo_task, 'turn_codex', side_effect=AssertionError('model must not run')), \
                 mock.patch.object(repo_task, 'run', return_value=subprocess.CompletedProcess([], 0, revision + '\n', '')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises((SystemExit, ValueError, RuntimeError)):
                    repo_task.main()
            self.assertEqual(metadata_path.read_bytes() if metadata_path.exists() else None, before)

    def test_resume_rejects_unrelated_project_head_before_model(self):
        out = self.dir / 'changed-head'
        out.mkdir()
        project = out / 'project'
        project.mkdir()
        revision = 'a' * 40
        metadata = {'commit': revision, 'prepared_head': 'b' * 40, 'project': str(project.resolve()), 'host': 'codex', 'model': 'test-model', 'task': 'site', 'mode': 'plain'}
        metadata_path = out / 'benchmark-metadata.json'
        metadata_path.write_text(json.dumps(metadata), encoding='utf-8')
        before = metadata_path.read_bytes()
        argv = ['repo_task.py', '--host', 'codex', '--no-aid', '--out', str(out),
                '--resume', 'fixture-thread', '--cwd', str(project), '--turns', '1',
                '--codex-home', str(self.codex_home), '--model', 'test-model']
        def fake_git(cmd, cwd, env, stdin=None):
            current = 'b' * 40 if Path(cwd).resolve() == project.resolve() else revision
            status = 1 if cmd[:3] == ['git', 'merge-base', '--is-ancestor'] else 0
            return subprocess.CompletedProcess(cmd, status, current + '\n', '')
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(repo_task, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(repo_task, 'run', side_effect=fake_git), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((SystemExit, ValueError, RuntimeError)):
                repo_task.main()
        self.assertEqual(metadata_path.read_bytes(), before)


class PreparedFixture(unittest.TestCase):
    """Prepare/reuse tests never invoke a model or certify hook trust."""
    def setUp(self):
        patcher = mock.patch.object(measure, 'require_supported_codex_version', return_value='0.164.0')
        patcher.start()
        self.addCleanup(patcher.stop)
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='prepared-benchmark-', dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'codex-home'
        self.home.mkdir()
        (self.home / 'config.toml').write_text('[tui]\nscreen_reader_detection_done = true\n', encoding='utf-8')
        self.work = self.root / 'work'
        self.revision = 'a' * 40

    def fake_setup(self, work, aid, bundle, **kwargs):
        project = Path(work) / 'project'
        project.mkdir(parents=True)
        hook = project / '.codex/hooks.json'
        hook.parent.mkdir()
        hook.write_text('{"hooks": {}}\n', encoding='utf-8')
        handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
        handler.parent.mkdir(parents=True)
        handler.write_text('# fixture\n', encoding='utf-8')
        return project, {'CODEX_HOME': str(self.home)}

    def argv(self, *extra):
        return ['measure.py', '--host', 'codex', '--lean', '--scenario', 'fix', '--model', 'test-model',
                '--codex-home', str(self.home), '--prepared-work', str(self.work), '--runs', '1', *extra]

    def test_codex_staging_uses_private_environment_outside_empty_output_bundle(self):
        observed = []
        def fake_stage(cmd, cwd, env, **kwargs):
            bundle = Path(cmd[-1])
            observed.append(bundle)
            self.assertTrue(bundle.is_dir())
            self.assertEqual(list(bundle.iterdir()), [], 'release output must be empty before staging')
            self.assertEqual(Path(env['CODEX_HOME']), self.home)
            self.assertFalse('OPENAI_API_KEY' in env, 'staging must not inherit provider credentials')
            scratch = (ROOT / '.aid/.temp').resolve()
            for key in ('HOME', 'USERPROFILE', 'TMP', 'TEMP', 'TMPDIR', 'AID_HOME'):
                value = Path(env[key]).resolve()
                self.assertTrue(value.is_relative_to(scratch), key)
                self.assertFalse(value.is_relative_to(bundle.resolve()), key)
            return subprocess.CompletedProcess(cmd, 0, '', '')
        with mock.patch.dict(os.environ, {'OPENAI_API_KEY': 'do-not-inherit', 'TMP': 'ambient-tmp'}), \
             mock.patch.object(sys, 'argv', self.argv('--prepare-only')), \
             mock.patch.object(measure, 'bash_executable', return_value='bash'), \
             mock.patch.object(measure, 'bash_path', side_effect=str), \
             mock.patch.object(measure.subprocess, 'run', side_effect=fake_stage), \
             mock.patch.object(measure, 'prepare_fixture', return_value={'project': 'fixture'}), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(measure.main(), 0)
        self.assertEqual(len(observed), 1)

    def test_prepare_only_creates_fixture_and_identity_without_model(self):
        with mock.patch.object(sys, 'argv', self.argv('--prepare-only')), \
             mock.patch.object(measure, 'setup', side_effect=self.fake_setup), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(measure, 'verify_trusted_hook', side_effect=AssertionError('trust is external'), create=True), \
             mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, self.revision + '\n', '')), \
             mock.patch.object(measure.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(measure.main(), 0)
        project = self.work / 'project'
        metadata = json.loads((self.work / 'benchmark-metadata.json').read_text(encoding='utf-8'))
        self.assertEqual(Path(metadata['project']), project.resolve())
        self.assertEqual((metadata['scenario'], metadata['model'], metadata['host'], metadata['mode']),
                         ('fix', 'test-model', 'codex', 'lean'))
        self.assertEqual(metadata['fixture_head'], self.revision)
        self.assertEqual(Path(metadata['codex_home']), self.home.resolve())
        self.assertEqual(metadata['fixture_tree_sha256'], measure.fixture_tree_sha256(project))
        for key, path in (('hook_sha256', project / '.codex/hooks.json'),
                          ('handler_sha256', project / '.aid/runtime/scripts/change/codex_safeguard.py')):
            self.assertEqual(metadata[key], hashlib.sha256(path.read_bytes()).hexdigest())

    def test_prepared_reuse_refuses_mismatch_or_tampering_before_model(self):
        project = self.work / 'project'
        project.mkdir(parents=True)
        hook = project / '.codex/hooks.json'
        hook.parent.mkdir()
        hook.write_text('{"hooks": {}}\n', encoding='utf-8')
        handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
        handler.parent.mkdir(parents=True)
        handler.write_text('# fixture\n', encoding='utf-8')
        metadata = {'project': str(project.resolve()), 'scenario': 'fix', 'model': 'test-model',
                    'host': 'codex', 'mode': 'lean', 'fixture_head': self.revision,
                    'codex_home': str(self.home.resolve()), 'fixture_tree_sha256': measure.fixture_tree_sha256(project),
                    'hook_sha256': hashlib.sha256(hook.read_bytes()).hexdigest(),
                    'handler_sha256': hashlib.sha256(handler.read_bytes()).hexdigest()}
        metadata_path = self.work / 'benchmark-metadata.json'
        cases = [dict(metadata, scenario='other'), dict(metadata, model='other'), dict(metadata, host='claude'),
                 dict(metadata, mode='plain'), dict(metadata, project=str(self.root)),
                 dict(metadata, codex_home=str(self.root)), dict(metadata, fixture_tree_sha256='0' * 64),
                 dict(metadata, fixture_head='b' * 40), dict(metadata, hook_sha256='0' * 64),
                 dict(metadata, handler_sha256='0' * 64)]
        for case in cases:
            metadata_path.write_text(json.dumps(case), encoding='utf-8')
            before = metadata_path.read_bytes()
            with self.subTest(case=case), mock.patch.object(sys, 'argv', self.argv()), \
                 mock.patch.object(measure, 'setup', side_effect=AssertionError('fixture must not be rebuilt')), \
                 mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
                 mock.patch.object(measure, 'verify_trusted_hook', side_effect=AssertionError('invalid identity')), \
                 mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, self.revision + '\n', '')), \
                 mock.patch.object(measure.subprocess, 'run', side_effect=AssertionError('bundle must not be staged')), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises((SystemExit, RuntimeError, ValueError)):
                    measure.main()
            self.assertEqual(metadata_path.read_bytes(), before)

    def test_fingerprint_excludes_only_the_exact_probe_directory_and_git_storage(self):
        project = self.work / 'project'
        (project / '.git').mkdir(parents=True)
        (project / '.git/index').write_text('git state', encoding='utf-8')
        probe = project / '.aid/.temp/codex-hook-probe-specific'
        probe.mkdir(parents=True)
        (probe / 'scratch').write_text('probe one', encoding='utf-8')
        other = project / '.aid/.temp/unrelated'
        other.mkdir()
        (other / 'source').write_text('original', encoding='utf-8')
        before = measure.fixture_tree_sha256(project, excluded_probe=probe)
        (probe / 'scratch').write_text('probe two', encoding='utf-8')
        (project / '.git/index').write_text('git changed', encoding='utf-8')
        self.assertEqual(measure.fixture_tree_sha256(project, excluded_probe=probe), before)
        (other / 'source').write_text('changed', encoding='utf-8')
        self.assertNotEqual(measure.fixture_tree_sha256(project, excluded_probe=probe), before)

    def test_prepare_refuses_nonempty_work_without_overwrite(self):
        self.work.mkdir()
        marker = self.work / 'keep'
        marker.write_bytes(b'preserve')
        with mock.patch.object(sys, 'argv', self.argv('--prepare-only')), \
             mock.patch.object(measure, 'setup', side_effect=AssertionError('setup must not run')), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(measure.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((SystemExit, RuntimeError, ValueError, FileExistsError)):
                measure.main()
        self.assertEqual(marker.read_bytes(), b'preserve')

    def test_prepared_work_requires_one_run_before_setup_or_model(self):
        argv = ['measure.py', '--host', 'codex', '--lean', '--scenario', 'fix', '--model', 'test-model',
                '--codex-home', str(self.home), '--prepared-work', str(self.work), '--runs', '2', '--prepare-only']
        with mock.patch.object(sys, 'argv', argv), \
             mock.patch.object(measure, 'setup', side_effect=AssertionError('setup must not run')), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((SystemExit, RuntimeError, ValueError)):
                measure.main()
        self.assertFalse(self.work.exists())

    def test_prepare_refuses_symlinked_work_path(self):
        target = self.root / 'target'
        target.mkdir()
        try:
            self.work.symlink_to(target, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        with mock.patch.object(sys, 'argv', self.argv('--prepare-only')), \
             mock.patch.object(measure, 'setup', side_effect=AssertionError('setup must not run')), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((SystemExit, RuntimeError, ValueError)):
                measure.main()
        self.assertEqual(list(target.iterdir()), [])

    def test_prepared_reuse_detects_fixture_mutation_during_probe(self):
        project = self.work / 'project'
        project.mkdir(parents=True)
        hook = project / '.codex/hooks.json'
        hook.parent.mkdir()
        hook.write_text('{"hooks": {}}\n', encoding='utf-8')
        handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
        handler.parent.mkdir(parents=True)
        handler.write_text('# fixture\n', encoding='utf-8')
        ordinary = project / 'source.txt'
        ordinary.write_text('original', encoding='utf-8')
        metadata = {'project': str(project.resolve()), 'scenario': 'fix', 'model': 'test-model',
                    'host': 'codex', 'mode': 'lean', 'fixture_head': self.revision,
                    'codex_home': str(self.home.resolve()), 'fixture_tree_sha256': measure.fixture_tree_sha256(project),
                    'hook_sha256': hashlib.sha256(hook.read_bytes()).hexdigest(),
                    'handler_sha256': hashlib.sha256(handler.read_bytes()).hexdigest()}
        metadata_path = self.work / 'benchmark-metadata.json'
        metadata_path.write_text(json.dumps(metadata), encoding='utf-8')
        before = metadata_path.read_bytes()
        def mutate_during_probe(*args):
            ordinary.write_text('changed during probe', encoding='utf-8')
        with mock.patch.object(sys, 'argv', self.argv()), \
             mock.patch.object(measure, 'verify_trusted_hook', side_effect=mutate_during_probe), \
             mock.patch.object(measure, 'turn_codex', side_effect=AssertionError('model must not run')), \
             mock.patch.object(measure, 'run', return_value=subprocess.CompletedProcess([], 0, self.revision + '\n', '')), \
             mock.patch.object(measure.subprocess, 'run', side_effect=AssertionError('bundle must not be staged')), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises((SystemExit, RuntimeError, ValueError)):
                measure.main()
        self.assertEqual(metadata_path.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
