#!/usr/bin/env python3
"""Offline trial installation and direct-state compatibility checks."""
import importlib.util
import dataclasses
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / '.aid/.temp'
INSTALLER = ROOT / 'experiments/aid-plain-first/trial_install.py'
REQUIREMENTS = ROOT / 'experiments/aid-plain-first/work_requirements.py'
direct_spec = importlib.util.spec_from_file_location('direct_tests', ROOT / 'tests/canonical/test_direct_state.py')
direct_tests = importlib.util.module_from_spec(direct_spec)
direct_spec.loader.exec_module(direct_tests)


class TrialInstallation(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.tmp = tempfile.TemporaryDirectory(prefix='outcome-trial-', dir=SCRATCH)
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'project'
        (self.root / '.agents/skills').mkdir(parents=True)
        (self.root / '.aid/runtime/templates').mkdir(parents=True)
        (self.root / '.aid/runtime/scripts/change').mkdir(parents=True)
        shutil.copyfile(ROOT / 'canonical/aid/templates/work-initiation-gate.md',
                        self.root / '.aid/runtime/templates/work-initiation-gate.md')
        shutil.copyfile(ROOT / 'canonical/aid/scripts/change/state.py',
                        self.root / '.aid/runtime/scripts/change/state.py')
        shutil.copyfile(ROOT / 'canonical/aid/templates/direct-state-template.yml',
                        self.root / '.aid/runtime/templates/direct-state-template.yml')
        for name in ('config/read-setting.sh', 'execute/writeback-state.sh', 'grade.sh',
                     'change/safeguard.py', 'change/codex_safeguard.py', 'change/codex_hook_config.py'):
            target = self.root / '.aid/runtime/scripts' / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / 'canonical/aid/scripts' / name, target)
        hooks = self.root / '.codex/hooks.json'
        hooks.parent.mkdir()
        hooks.write_text('{"user": "unchanged"}', encoding='utf-8')
        self.hooks = hooks
        self.skill = self.root / '.agents/skills/aid-outcome'

    def command(self, action):
        return subprocess.run([sys.executable, str(INSTALLER), action, '--project', str(self.root)],
                              capture_output=True, text=True)

    def test_install_and_remove_leave_user_hooks_unchanged(self):
        before = self.hooks.read_bytes()
        result = self.command('install')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.skill / 'SKILL.md').is_file())
        self.assertTrue((self.skill / 'scripts/outcome_coverage.py').is_file())
        self.assertTrue((self.skill / 'references/review.md').is_file())
        self.assertEqual((self.skill / 'references/review.md').read_bytes(),
                         (ROOT / 'experiments/aid-plain-first/aid-outcome/references/review.md').read_bytes())
        self.assertEqual(self.hooks.read_bytes(), before)
        coverage = self.root / 'coverage.json'
        coverage.write_text(json.dumps({'outcomes': [{'id': 'O1', 'description': 'a result'}],
                                        'results': []}), encoding='utf-8')
        check = subprocess.run([sys.executable, str(self.skill / 'scripts/outcome_coverage.py'), str(coverage)],
                               cwd=self.root, capture_output=True, text=True)
        self.assertEqual(check.returncode, 1, check.stdout + check.stderr)
        self.assertIn('unverified', check.stdout)
        self.assertNotEqual(self.command('install').returncode, 0)
        removed = self.command('remove')
        self.assertEqual(removed.returncode, 0, removed.stderr)
        self.assertFalse(self.skill.exists())
        quarantines = list((self.root / '.aid/.temp').glob('aid-outcome-quarantine-*/aid-outcome/SKILL.md'))
        self.assertEqual(len(quarantines), 1)
        self.assertTrue(quarantines[0].is_file())
        self.assertEqual(self.hooks.read_bytes(), before)

    def test_remove_refuses_changed_or_added_files(self):
        self.assertEqual(self.command('install').returncode, 0)
        skill = self.skill / 'SKILL.md'
        before = skill.read_bytes()
        skill.write_bytes(before + b'\nuser edit\n')
        self.assertNotEqual(self.command('remove').returncode, 0)
        self.assertTrue(skill.read_bytes().endswith(b'user edit\n'))
        skill.write_bytes(before)
        extra = self.skill / 'user.txt'
        extra.write_text('preserve', encoding='utf-8')
        self.assertNotEqual(self.command('remove').returncode, 0)
        self.assertEqual(extra.read_text(), 'preserve')
        self.assertTrue(skill.exists())

    def test_late_edit_is_preserved_in_quarantine(self):
        self.assertEqual(self.command('install').returncode, 0)
        spec = importlib.util.spec_from_file_location('trial_installer', INSTALLER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        real_digest = module.digest
        skill = self.skill / 'SKILL.md'

        def interleaved(path):
            value = real_digest(path)
            if path.name == 'outcome_coverage.py':
                skill.write_bytes(skill.read_bytes() + b'\nlate user edit\n')
            return value

        with mock.patch.object(module, 'digest', side_effect=interleaved):
            module.remove(str(self.root))
        preserved = list((self.root / '.aid/.temp').glob('aid-outcome-quarantine-*/aid-outcome/SKILL.md'))
        self.assertEqual(len(preserved), 1)
        self.assertTrue(preserved[0].read_bytes().endswith(b'late user edit\n'))
        self.assertFalse(self.skill.exists())

    def test_source_drift_prevents_automatic_removal(self):
        self.assertEqual(self.command('install').returncode, 0)
        spec = importlib.util.spec_from_file_location('trial_installer', INSTALLER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        changed = Path(self.tmp.name) / 'changed-source.md'
        changed.write_text('a newer source version', encoding='utf-8')
        sources = dict(module.FILES, **{'SKILL.md': changed})
        with mock.patch.object(module, 'FILES', sources):
            with self.assertRaisesRegex(ValueError, 'changed'):
                module.remove(str(self.root))
        self.assertTrue((self.skill / 'SKILL.md').exists())

    def test_existing_skill_or_old_gate_is_not_overwritten(self):
        self.skill.mkdir()
        owned = self.skill / 'SKILL.md'
        owned.write_text('user skill', encoding='utf-8')
        self.assertNotEqual(self.command('install').returncode, 0)
        self.assertEqual(owned.read_text(), 'user skill')
        owned.unlink()
        self.skill.rmdir()
        (self.root / '.aid/runtime/templates/work-initiation-gate.md').write_text('old gate', encoding='utf-8')
        self.assertNotEqual(self.command('install').returncode, 0)
        self.assertFalse(self.skill.exists())

    def test_gate_preserves_lifecycle_and_default_routes(self):
        gate = (self.root / '.aid/runtime/templates/work-initiation-gate.md').read_text(encoding='utf-8')
        self.assertIn('`pipeline.path`, `pipeline.initiator`, `phase`, `lifecycle`', gate)
        paused = gate.index('Direct work `Paused-Awaiting-Input`')
        outcome = gate.index('Direct work `Running` with `pipeline.initiator: aid-outcome`')
        other = gate.index('Other direct work `Running`')
        self.assertLess(paused, outcome)
        self.assertLess(outcome, other)
        self.assertIn('otherwise stop', gate[outcome:other])
        self.assertIn('/aid-change <work>', gate[other:])

    def test_start_guidance_does_not_claim_gate_allocates_the_directory(self):
        guidance = (ROOT / 'experiments/aid-plain-first/aid-outcome/references/start-and-resume.md').read_text(encoding='utf-8')
        self.assertIn('gate itself allocates nothing', guidance)
        self.assertIn('create and enter', guidance)
        self.assertIn('exclusively create the empty work directory', guidance)

    def test_symlinked_skills_directory_is_rejected(self):
        skills = self.root / '.agents/skills'
        skills.rmdir()
        target = self.root / 'elsewhere'
        target.mkdir()
        try:
            skills.symlink_to(target, target_is_directory=True)
        except OSError:
            self.skipTest('directory symlinks unavailable')
        self.assertNotEqual(self.command('install').returncode, 0)
        self.assertEqual(list(target.iterdir()), [])

    def test_linked_state_initializer_is_never_executed(self):
        state = self.root / '.aid/runtime/scripts/change/state.py'
        state.unlink()
        outside = Path(self.tmp.name) / 'untrusted.py'
        marker = Path(self.tmp.name) / 'executed'
        outside.write_text('from pathlib import Path\nPath(%r).write_text("bad")\nprint("--initiator")\n'
                           % str(marker), encoding='utf-8')
        try:
            state.symlink_to(outside)
        except OSError:
            self.skipTest('file symlinks unavailable')
        self.assertNotEqual(self.command('install').returncode, 0)
        self.assertFalse(marker.exists())
        self.assertFalse(self.skill.exists())

    def test_missing_initializer_prerequisite_prevents_installation(self):
        (self.root / '.aid/runtime/templates/direct-state-template.yml').unlink()
        self.assertNotEqual(self.command('install').returncode, 0)
        self.assertFalse(self.skill.exists())

    def test_crlf_shell_prerequisite_is_not_treated_as_compatible(self):
        writer = self.root / '.aid/runtime/scripts/execute/writeback-state.sh'
        data = writer.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
        writer.write_bytes(data)
        result = self.command('install')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(writer.read_bytes(), data)
        self.assertFalse(self.skill.exists())


class OutcomeState(unittest.TestCase):
    def setUp(self):
        self.fixture = direct_tests.DirectState('test_goal_is_required_before_writes')
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def initialize(self, *extra):
        f = self.fixture
        return subprocess.run([sys.executable, str(f.script), '--init-work-dir', str(f.work),
                               '--goal', f.goal, *extra], cwd=f.project, env=f.env,
                              capture_output=True, text=True)

    def test_outcome_state_is_published_with_correct_initiator(self):
        f = self.fixture
        result = self.initialize('--initiator', 'aid-outcome')
        self.assertEqual(result.returncode, 0, result.stderr)
        state = f.state.read_text(encoding='utf-8')
        self.assertIn('initiator: aid-outcome', state)
        self.assertIn('active_skill: aid-outcome', state)
        self.assertIn('REQUIREMENTS.md', state)
        self.assertIn('lifecycle: Running', state)
        self.assertNotIn('lifecycle: Completed', state)

    def test_default_and_existing_state_are_preserved(self):
        f = self.fixture
        self.assertEqual(self.initialize().returncode, 0)
        original = f.state.read_bytes()
        self.assertIn(b'initiator: aid-change', original)
        self.assertNotEqual(self.initialize('--initiator', 'aid-outcome').returncode, 0)
        self.assertEqual(f.state.read_bytes(), original)

    def test_existing_dashboard_readers_see_outcome_work(self):
        f = self.fixture
        self.assertEqual(self.initialize('--initiator', 'aid-outcome').returncode, 0)
        sys.path.insert(0, str(ROOT))
        from dashboard.reader import read_repo
        model = dataclasses.asdict(read_repo(f.project))
        self.assertEqual(model['works'][0]['work_path'], 'direct')
        self.assertEqual(model['works'][0]['active_skill'], 'aid-outcome')
        node = shutil.which('node')
        if not node:
            self.skipTest('Node unavailable; Python reader passed')
        command = ("import {readRepo} from './dashboard/server/reader.mjs'; "
                   "console.log(JSON.stringify(readRepo(process.argv[1]).works))")
        result = subprocess.run([node, '--input-type=module', '-e', command, str(f.project)],
                                cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        works = json.loads(result.stdout)
        self.assertEqual(works[0]['work_path'], 'direct')
        self.assertEqual(works[0]['active_skill'], 'aid-outcome')

    def test_failed_staged_writer_does_not_publish_state(self):
        f = self.fixture
        real = f.writer.with_name('real-writer.sh')
        f.writer.replace(real)
        f.writer.write_text('#!/usr/bin/env bash\n'
                            'if [[ "$*" == *"Pipeline Initiator"* ]]; then exit 7; fi\n'
                            'exec bash "$(dirname "$0")/real-writer.sh" "$@"\n', encoding='utf-8')
        result = self.initialize('--initiator', 'aid-outcome')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(f.state.exists())

    def test_requirements_creation_resume_and_changed_file_detection(self):
        f = self.fixture
        self.assertEqual(self.initialize('--initiator', 'aid-outcome').returncode, 0)
        work = f.work.relative_to(f.project).as_posix()
        base = [sys.executable, str(REQUIREMENTS)]
        missing = subprocess.run([*base, 'inspect', '--work', work], cwd=f.project,
                                 env=f.env, capture_output=True, text=True)
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn('REQUIREMENTS.md', f.state.read_text(encoding='utf-8'))
        content = '# Requirements\nUser decision: retain existing data.\n'
        created = subprocess.run([*base, 'create', '--work', work], cwd=f.project, env=f.env,
                                 input=content, capture_output=True, text=True)
        self.assertEqual(created.returncode, 0, created.stderr)
        requirements = f.work / 'REQUIREMENTS.md'
        duplicate = subprocess.run([*base, 'create', '--work', work], cwd=f.project, env=f.env,
                                   input='different intent', capture_output=True, text=True)
        self.assertNotEqual(duplicate.returncode, 0)
        self.assertEqual(requirements.read_text(encoding='utf-8'), content)
        inspected = subprocess.run([*base, 'inspect', '--work', work], cwd=f.project,
                                   env=f.env, capture_output=True, text=True, check=True)
        before_hash = inspected.stdout.strip()
        requirements.write_text(content + 'User adds a constraint.\n', encoding='utf-8')
        changed = subprocess.run([*base, 'check', '--work', work, '--expected-sha256', before_hash],
                                 cwd=f.project, env=f.env, capture_output=True, text=True)
        self.assertEqual(changed.returncode, 1)
        self.assertIn('User adds a constraint.', requirements.read_text(encoding='utf-8'))
        self.assertIn('initiator: aid-outcome', f.state.read_text(encoding='utf-8'))

    def test_documented_writer_invocation_records_the_next_action(self):
        f = self.fixture
        self.assertEqual(self.initialize('--initiator', 'aid-outcome').returncode, 0)
        guide = (ROOT / 'experiments/aid-plain-first/aid-outcome/references/start-and-resume.md').read_text(encoding='utf-8')
        blocks = re.findall(r'```bash\n(.*?)\n```', guide, re.DOTALL)
        command = next(block for block in blocks if "Direct Next Step" in block)
        action = 'Check café "notes" and literal $(touch OUTCOME_INJECTION_MARKER); preserve evidence.'
        env = dict(f.env, work=f.work.relative_to(f.project).as_posix(), next_action=action)
        result = subprocess.run([f.bash, '-c', command], cwd=f.project, env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(action, f.state.read_text(encoding='utf-8'))
        self.assertFalse((f.project / 'OUTCOME_INJECTION_MARKER').exists())

    @unittest.skipUnless(os.name == 'nt', 'Windows junction test')
    def test_junction_to_another_work_is_not_initialized(self):
        f = self.fixture
        f.work.rmdir()
        target = f.work.parent / 'work-002-existing'
        target.mkdir()
        made = subprocess.run(['cmd', '/c', 'mklink', '/J', str(f.work), str(target)],
                              capture_output=True, text=True)
        if made.returncode:
            self.skipTest('junction creation unavailable: ' + made.stderr.strip())
        try:
            result = self.initialize('--initiator', 'aid-outcome')
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((target / 'STATE.yml').exists())
        finally:
            os.rmdir(f.work)


if __name__ == '__main__':
    unittest.main()
