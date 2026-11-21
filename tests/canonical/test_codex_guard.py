#!/usr/bin/env python3
"""Exercise the proposed Codex hook handler without starting Codex or running Git.

Usage: python tests/canonical/test_codex_guard.py
Exit codes: 0 all tests pass; nonzero on a failure.
The tests check handler output, not hook registration, user trust or host enforcement.
"""
import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HANDLER = ROOT / 'canonical/aid/scripts/change/codex_safeguard.py'


class CodexGuard(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not HANDLER.is_file():
            raise AssertionError(f'handler is missing: {HANDLER}')

    def call(self, value):
        return subprocess.run([sys.executable, str(HANDLER)], input=value, text=True, capture_output=True)

    def event(self, command):
        return json.dumps({'hook_event_name': 'PreToolUse', 'tool_name': 'Bash',
                           'tool_input': {'command': command}})

    def test_recognized_push_and_merge_are_denied_without_ask(self):
        # Only direct supported shell forms: aliases, indirection, other tools and
        # host fail-open behavior require separate native-host tests.
        for command in ('git push origin work', 'git.exe push origin work',
                        'git -C /tmp/project push origin work',
                        'git -C "C:/project with spaces" push origin work',
                        'git -c user.name=test push origin work',
                        'git --git-dir=.git push origin work', 'git merge feature',
                        'gh pr merge 42', 'git status && git push origin work',
                        'git status | git push origin work'):
            with self.subTest(command=command):
                result = self.call(self.event(command))
                self.assertEqual(result.returncode, 0, result.stderr)
                output = json.loads(result.stdout)
                hook = output['hookSpecificOutput']
                self.assertEqual(hook['hookEventName'], 'PreToolUse')
                self.assertEqual(hook['permissionDecision'], 'deny')
                self.assertTrue(hook['permissionDecisionReason'])

    def test_non_mutating_git_commands_are_not_blocked(self):
        for command in ('git status --short', 'git log --grep=merge',
                        'git config --get push.default', 'echo hello'):
            with self.subTest(command=command):
                result = self.call(self.event(command))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(result.stdout.strip(), result.stdout)

    def test_environment_assignment_does_not_hide_direct_git(self):
        # Environment prefixes are direct invocations, not shell aliases or wrappers.
        for command in ('LANG=C git push origin work', 'GIT_TERMINAL_PROMPT=0 git merge feature',
                        'LANG=C LC_ALL=C git -C /tmp/repo push origin work'):
            with self.subTest(command=command):
                result = self.call(self.event(command))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)['hookSpecificOutput']['permissionDecision'], 'deny')

    def test_invalid_hook_input_fails_closed(self):
        for raw in ('{', '{}', json.dumps({'tool_input': {'command': 17}})):
            with self.subTest(raw=raw):
                result = self.call(raw)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertTrue(result.stderr.strip())


if __name__ == '__main__':
    unittest.main()
