#!/usr/bin/env python3
"""Check notes benchmark context and arm parity without invoking a model.

Usage: python tests/measure/test_notes_fixture.py
Exit codes: 0 when checks pass; nonzero otherwise.
"""
import os
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/measure'))
import measure


def tree_bytes(root):
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in root.rglob('*') if p.is_file()}


class NotesFixture(unittest.TestCase):
    def setUp(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='notes-fixture-', dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'codex-home'
        self.home.mkdir()
        (self.home / 'config.toml').write_text('[tui]\nscreen_reader_detection_done = true\n', encoding='utf-8')
        self.bundle = self.root / 'bundle'
        self.bundle.mkdir()

    def test_fixture_has_usable_notes_project_card(self):
        card = measure.FIXTURE / '.aid/knowledge/PROJECT.md'
        self.assertTrue(card.is_file(), 'lean benchmark fixture must include a real notes project card')
        text = card.read_text(encoding='utf-8')
        for required in ('objective:', 'summary:', 'sources:', '## What it is', '## Stack',
                         '## Commands', '## Where things live', '## Detail',
                         'src/notes/store.py', 'tests/test_store.py', 'PYTHONPATH=src'):
            with self.subTest(required=required):
                self.assertIn(required, text)
        self.assertIn('unittest', text)
        self.assertIn('notes.json', text)
        self.assertIn('INDEX.md', text)

    def test_plain_and_lean_start_with_identical_notes_code_and_use_same_hidden_grader(self):
        snapshot = {part: tree_bytes(measure.FIXTURE / part) for part in ('src', 'tests')}
        readme = (measure.FIXTURE / 'README.md').read_bytes()
        grader = measure.HIDDEN / 'check_fix.py'
        grader_before = grader.read_bytes()
        commands = []
        def fake_run(cmd, cwd, env, stdin=None):
            commands.append(cmd)
            output = 'fixture-baseline\n' if cmd[:2] == ['git', 'rev-list'] else ''
            return subprocess.CompletedProcess(cmd, 0, output, '')
        projects = []
        with mock.patch.object(measure, 'run', side_effect=fake_run), \
             mock.patch.object(measure, 'bash_executable', return_value='bash'), \
             mock.patch.object(measure, 'bash_path', side_effect=str):
            for mode in ('plain', 'lean'):
                work = self.root / mode
                work.mkdir()
                project, env = measure.setup(work, mode == 'lean', self.bundle, host='codex',
                                             codex_home=self.home, lean=mode == 'lean')
                projects.append(project)
                for part in snapshot:
                    self.assertEqual(tree_bytes(project / part), snapshot[part], f'{mode}: {part}')
                self.assertEqual((project / 'README.md').read_bytes(), readme)
                # This mocked call verifies driver selection, not grader behavior.
                measure.grade(project, 'fix', work, env)
        self.assertFalse((projects[0] / '.aid').exists())
        card = measure.FIXTURE / '.aid/knowledge/PROJECT.md'
        self.assertTrue(card.is_file(), 'the real fixture card is missing')
        self.assertEqual((projects[1] / '.aid/knowledge/PROJECT.md').read_bytes(), card.read_bytes())
        checks = [cmd for cmd in commands if len(cmd) >= 2 and cmd[1] == str(grader)]
        self.assertEqual(len(checks), 2)
        self.assertEqual({Path(cmd[2]) for cmd in checks}, set(projects))
        self.assertEqual(grader.read_bytes(), grader_before)
        # The real hidden check must reject the same planted bug in both arms.
        env = dict(os.environ, TMP=str(self.root), TEMP=str(self.root), TMPDIR=str(self.root),
                   PYTHONDONTWRITEBYTECODE='1')
        for project in projects:
            result = subprocess.run([sys.executable, str(grader), str(project)], env=env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("['2', '1', '2', '3']", result.stdout)


class LeanDiscoveryInstructions(unittest.TestCase):
    def test_discovery_is_targeted_and_excludes_irrelevant_trees_by_default(self):
        text = (ROOT / 'canonical/skills/aid-change/SKILL.md').read_text(encoding='utf-8')
        self.assertRegex(text, r'(?is)(?:(?:targeted|focused|bounded).{0,180}(?:search|discovery|read|inspect)|(?:search|discovery|read|inspect).{0,180}(?:targeted|focused|bounded))')
        self.assertRegex(text, r'(?is)(?:(?:exclude|avoid|skip).{0,180}(?:\.git|git internals)|(?:\.git|git internals).{0,180}(?:exclude|avoid|skip))')
        self.assertRegex(text, r'(?is)(?:(?:exclude|avoid|skip).{0,180}(?:generated|node_modules|build output)|(?:generated|node_modules|build output).{0,180}(?:exclude|avoid|skip))')
        self.assertRegex(text, r'(?is)(?:unless|when|if).{0,100}(?:needed|necessary|relevant|requires)')
        self.assertRegex(text, r'(?is)(?:sections?|help|targeted|bounded).{0,160}(?:templates?|scripts?|output)')

    def test_existing_verification_and_safeguard_requirements_remain(self):
        text = (ROOT / 'canonical/skills/aid-change/SKILL.md').read_text(encoding='utf-8')
        for required in ('Tests first', 'baseline', 'checks.py', 'independent', 'whole-result',
                         'PreToolUse', 'safeguard.py', 'codex_hook_config.py', '/hooks'):
            with self.subTest(required=required):
                self.assertIn(required, text)


class LeanReviewAvailabilityInstructions(unittest.TestCase):
    def test_unavailable_named_reviewer_falls_back_without_weakening_review(self):
        skill = (ROOT / 'canonical/skills/aid-change/SKILL.md').read_text(encoding='utf-8')
        review = (ROOT / 'canonical/skills/aid-change/references/review.md').read_text(encoding='utf-8')
        text = skill + '\n' + review
        self.assertRegex(text, r'(?is)(?:model.{0,120}(?:unsupported|not supported|unrecognized|model_not_found)|(?:unsupported|not supported|unrecognized|model_not_found).{0,120}model)')
        self.assertRegex(text, r'(?is)(?:host|session).{0,60}default')
        self.assertRegex(text, r'(?is)(?:user|human).{0,80}(?:require|specif).{0,50}model')
        self.assertRegex(text, r'(?is)(?:report|disclose|tell|inform).{0,120}(?:fallback|retry|default)')
        self.assertRegex(text, r'(?is)(?:independent.{0,120}(?:review|reviewer)|(?:review|reviewer).{0,120}independent)')
        self.assertRegex(text, r'(?is)(?:same|unchanged).{0,120}(?:criteria|review|task)')
        self.assertRegex(text, r'(?is)(?:other|unrelated).{0,120}(?:failures|errors).{0,120}(?:stop|report|surface)')
        paragraphs = re.split(r'\n\s*\n', text)
        errors_paragraph = next((p for p in paragraphs if all(re.search(term, p, re.I)
                                for term in (r'quota|rate.limit', r'auth', r'service'))), '')
        self.assertTrue(errors_paragraph, 'quota, authentication and service errors must be addressed together')
        self.assertRegex(errors_paragraph, r'(?is)\b(?:do not|never|must not)\s+(?:retry|fall back|fallback|switch|substitut)')
        self.assertIn('whole result', review.lower())


class LeanExistingWorkInstructions(unittest.TestCase):
    def test_direct_continuation_records_only_in_related_active_work(self):
        text = (ROOT / 'canonical/skills/aid-change/SKILL.md').read_text(encoding='utf-8')
        candidates = [p for p in re.split(r'\n\s*\n', text)
                      if re.search(r'\b(?:related|continuation|same work)\b', p, re.I)
                      and re.search(r'\b(?:active|running)\b', p, re.I)
                      and re.search(r'STATE\.yml', p, re.I)]
        self.assertTrue(candidates, 'direct continuation must record in its related active work STATE.yml')
        paragraph = '\n'.join(candidates)
        self.assertRegex(paragraph, r'(?is)\b(?:existing|reuse|continue|record)\b')
        self.assertRegex(paragraph, r'(?is)\b(?:unrelated|different)\b')
        self.assertRegex(paragraph, r'(?is)\b(?:completed|done)\b')
        self.assertRegex(paragraph, r'(?is)\b(?:canceled|cancelled)\b')
        self.assertRegex(paragraph, r'(?is)\b(?:never|do not|must not|not)\b.{0,100}\b(?:reuse|reopen|continue|use)\b')
        for required in ('Tests first', 'independent', 'whole-result', 'safeguard.py', 'codex_hook_config.py'):
            with self.subTest(required=required):
                self.assertIn(required, text)


if __name__ == '__main__':
    unittest.main()
