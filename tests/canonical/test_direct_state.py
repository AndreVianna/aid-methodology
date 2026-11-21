#!/usr/bin/env python3
"""Direct state contract in a disposable installed-style project; no model calls."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

try:
    import yaml
except ImportError:
    yaml = None

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / '.aid/.temp'


class DirectState(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='direct-state-', dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'project'
        runtime = self.project / '.aid/runtime'
        sources = {
            'scripts/change/state.py': ROOT / 'canonical/aid/scripts/change/state.py',
            'scripts/execute/writeback-state.sh': ROOT / 'canonical/aid/scripts/execute/writeback-state.sh',
            'scripts/config/read-setting.sh': ROOT / 'canonical/aid/scripts/config/read-setting.sh',
        }
        for relative, source in sources.items():
            target = runtime / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes().replace(b'\r\n', b'\n'))
        template_source = ROOT / 'canonical/aid/templates/direct-state-template.yml'
        self.template = runtime / 'templates/direct-state-template.yml'
        if template_source.is_file():
            self.template.parent.mkdir(parents=True, exist_ok=True)
            self.template.write_bytes(template_source.read_bytes().replace(b'\r\n', b'\n'))
        self.script = runtime / 'scripts/change/state.py'
        self.writer = runtime / 'scripts/execute/writeback-state.sh'
        self.dashboard_writer = self.project / 'dashboard/scripts/writeback-state.sh'
        self.dashboard_writer.parent.mkdir(parents=True)
        self.dashboard_writer.write_bytes((ROOT / 'dashboard/scripts/writeback-state.sh').read_bytes().replace(b'\r\n', b'\n'))
        self.settings = self.project / '.aid/settings.yml'
        self.settings.write_text('review:\n  minimum_grade: B+\n', encoding='utf-8')
        self.work = self.project / '.aid/works/work-001-direct'
        self.work.mkdir(parents=True)
        self.state = self.work / 'STATE.yml'
        self.goal = 'Fix café notes: preserve "pinned" order'
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', HOME=str(self.root / 'private-home'),
                        TMP=str(self.root), TEMP=str(self.root), TMPDIR=str(self.root))
        self.bash = 'bash'
        if os.name == 'nt':
            git_bash = Path('C:/Program Files/Git/bin/bash.exe')
            if git_bash.is_file():
                self.bash = str(git_bash)
                git_root = git_bash.parent.parent
                self.env['PATH'] = os.pathsep.join((str(git_root / 'bin'), str(git_root / 'usr/bin'), self.env.get('PATH', '')))

    def init(self, work=None, goal=None):
        return subprocess.run([sys.executable, str(self.script), '--init-work-dir', str(work or self.work),
                               '--goal', self.goal if goal is None else goal], cwd=self.project,
                              env=self.env, capture_output=True, text=True)

    def write(self, *args, dashboard=False):
        env = dict(self.env, AID_STATE_FILE='.aid/works/work-001-direct/STATE.yml',
                   AID_WORK_DIR='.aid/works/work-001-direct')
        script = 'dashboard/scripts/writeback-state.sh' if dashboard else '.aid/runtime/scripts/execute/writeback-state.sh'
        return subprocess.run([self.bash, script, *args],
                              cwd=self.project, env=env, capture_output=True, text=True)

    def test_initializer_seeds_truthful_compact_state_using_real_writer_and_settings(self):
        if yaml is None:
            self.skipTest('PyYAML required to validate YAML values and types')
        real_writer = self.writer.with_name('writeback-state-real.sh')
        self.writer.replace(real_writer)
        self.writer.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$PWD/.aid/writer-calls.log"\n'
                               'exec bash "$(dirname "$0")/writeback-state-real.sh" "$@"\n', encoding='utf-8')
        result = self.init()
        self.assertEqual(result.returncode, 0, result.stderr)
        data = yaml.safe_load(self.state.read_text(encoding='utf-8'))
        self.assertEqual(data['pipeline'], {'path': 'direct', 'initiator': 'aid-change'})
        self.assertEqual(data['goal'], self.goal)
        self.assertEqual(data['minimum_grade'], 'B+')
        self.assertEqual(data['user_approved'], 'no')
        self.assertEqual((data['lifecycle'], data['phase'], data['active_skill']), ('Running', 'Execute', 'aid-change'))
        for key in ('interview', 'features', 'delivery_state', 'gate_grade', 'delivery_gate',
                    'delivery_lifecycle', 'tasks_lifecycle', 'review_history'):
            self.assertNotIn(key, data, f'{key} does not apply at direct-work initialization')
        calls = (self.project / '.aid/writer-calls.log').read_text(encoding='utf-8')
        self.assertIn('--pipeline', calls)
        self.assertIn('--field', calls)
        self.assertNotIn('Completed', calls)
        self.assertFalse(any(self.work.glob('delivery-*')))

    def test_missing_settings_use_reader_default_without_mutating_settings(self):
        self.settings.unlink()
        result = self.init()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.settings.exists())
        self.assertRegex(self.state.read_text(encoding='utf-8'), r'(?m)^minimum_grade:\s*A\s*$')

    @unittest.skipUnless(os.name == 'nt', 'realistic competing WSL bash PATH requires native Windows')
    def test_windows_git_cmd_path_initializes_with_competing_wsl_bash(self):
        git_cmd = Path('C:/Program Files/Git/cmd')
        wsl_bash = Path(os.environ.get('SystemRoot', 'C:/Windows')) / 'System32/bash.exe'
        if not (git_cmd / 'git.exe').is_file() or not wsl_bash.is_file():
            self.skipTest('Git for Windows and the competing WSL bash launcher are required')
        self.env['PATH'] = os.pathsep.join((str(git_cmd), str(wsl_bash.parent)))
        self.assertEqual(Path(shutil.which('git', path=self.env['PATH'])).resolve(), (git_cmd / 'git.exe').resolve())
        self.assertEqual(Path(shutil.which('bash', path=self.env['PATH'])).resolve(), wsl_bash.resolve())
        self.assertNotIn(str(git_cmd.parent / 'usr/bin').lower(), self.env['PATH'].lower())
        result = self.init()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.state.is_file())
        self.assertIn('path: direct', self.state.read_text(encoding='utf-8'))

    def test_goal_is_required_before_writes(self):
        for goal in ('', '   '):
            with self.subTest(goal=goal):
                self.assertNotEqual(self.init(goal=goal).returncode, 0)
                self.assertFalse(self.state.exists())
        result = subprocess.run([sys.executable, str(self.script), '--init-work-dir', str(self.work)],
                                cwd=self.project, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.state.exists())

    def test_goal_cannot_inject_approval_or_completion_fields(self):
        goal = "Fix notes\nuser_approved: 'yes'\nlifecycle: Completed"
        result = self.init(goal=goal)
        if result.returncode:
            self.assertFalse(self.state.exists())
            return
        if yaml is None:
            self.skipTest('PyYAML required to verify safe multiline goal encoding')
        data = yaml.safe_load(self.state.read_text(encoding='utf-8'))
        self.assertEqual(data['goal'], goal)
        self.assertEqual(data['user_approved'], 'no')
        self.assertEqual(data['lifecycle'], 'Running')

    def test_existing_or_linked_state_is_never_clobbered(self):
        marker = b'preserve existing state\n'
        self.state.write_bytes(marker)
        self.assertNotEqual(self.init().returncode, 0)
        self.assertEqual(self.state.read_bytes(), marker)
        self.state.unlink()
        outside = self.root / 'outside-state.yml'
        outside.write_bytes(marker)
        try:
            self.state.symlink_to(outside)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        self.assertNotEqual(self.init().returncode, 0)
        self.assertTrue(self.state.is_symlink())
        self.assertEqual(outside.read_bytes(), marker)

    def test_unallocated_outside_and_symlinked_work_paths_are_rejected(self):
        missing = self.project / '.aid/works/work-999-unallocated'
        self.assertNotEqual(self.init(missing).returncode, 0)
        self.assertFalse(missing.exists())
        outside = self.root / 'outside'
        outside.mkdir()
        (outside / 'keep').write_bytes(b'keep')
        self.assertNotEqual(self.init(outside).returncode, 0)
        self.assertFalse((outside / 'STATE.yml').exists())
        self.assertEqual((outside / 'keep').read_bytes(), b'keep')
        link = self.project / '.aid/works/work-002-link'
        try:
            link.symlink_to(outside, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f'symlink creation unavailable: {exc}')
        self.assertNotEqual(self.init(link).returncode, 0)
        self.assertFalse((outside / 'STATE.yml').exists())

    def test_nonempty_allocated_work_is_rejected_without_modifying_any_files(self):
        cases = (('PLAN.md', False), ('tasks/task-001/DETAIL.md', False),
                 ('deliveries/delivery-001/STATE.yml', False), ('.hidden', False), ('empty-directory', True))
        for index, (relative, is_directory) in enumerate(cases, start=10):
            with self.subTest(existing=relative):
                work = self.project / '.aid/works' / f'work-{index:03d}-existing'
                work.mkdir()
                existing = work / relative
                if is_directory:
                    existing.mkdir(parents=True)
                else:
                    existing.parent.mkdir(parents=True, exist_ok=True)
                    existing.write_bytes(b'existing user work\n\x00preserve\n')
                before = {p.relative_to(work): p.read_bytes() for p in work.rglob('*') if p.is_file()}
                dirs_before = {p.relative_to(work) for p in work.rglob('*') if p.is_dir()}
                self.assertNotEqual(self.init(work).returncode, 0)
                self.assertFalse((work / 'STATE.yml').exists())
                self.assertEqual({p.relative_to(work): p.read_bytes() for p in work.rglob('*') if p.is_file()}, before)
                self.assertEqual({p.relative_to(work) for p in work.rglob('*') if p.is_dir()}, dirs_before)
    def test_invalid_grade_missing_reader_or_writer_failure_do_not_publish_state(self):
        self.settings.write_text('review:\n  minimum_grade: invalid\n', encoding='utf-8')
        before = self.settings.read_bytes()
        self.assertNotEqual(self.init().returncode, 0)
        self.assertFalse(self.state.exists())
        self.assertEqual(self.settings.read_bytes(), before)
        self.settings.write_text('review:\n  minimum_grade: B+\n', encoding='utf-8')
        template = self.template.read_bytes() if self.template.exists() else None
        self.template.unlink(missing_ok=True)
        self.assertNotEqual(self.init().returncode, 0)
        self.assertFalse(self.state.exists())
        if template is not None:
            self.template.write_bytes(template)
        reader = self.project / '.aid/runtime/scripts/config/read-setting.sh'
        reader.unlink()
        self.assertNotEqual(self.init().returncode, 0)
        self.assertFalse(self.state.exists())
        reader.write_bytes((ROOT / 'canonical/aid/scripts/config/read-setting.sh').read_bytes().replace(b'\r\n', b'\n'))
        self.writer.write_text('#!/usr/bin/env bash\nexit 7\n', encoding='utf-8')
        self.assertNotEqual(self.init().returncode, 0)
        self.assertFalse(self.state.exists())

    def test_concurrent_initializers_publish_at_most_one_state(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: self.init(), range(2)))
        self.assertEqual(sum(r.returncode == 0 for r in results), 1,
                         [(r.returncode, r.stderr) for r in results])
        self.assertTrue(self.state.is_file())
        self.assertIn('direct', self.state.read_text(encoding='utf-8'))

    def test_both_writers_preserve_legacy_assignment_and_refuse_direct_layout_switches(self):
        # Legacy changes remain supported; direct can only be reassigned to itself.
        for dashboard in (False, True):
            for old, new in (('lite', 'lite'), ('full', 'full'), ('lite', 'full'), ('full', 'lite'),
                             ('direct', 'direct'), ('lite', 'direct'), ('full', 'direct'),
                             ('direct', 'lite'), ('direct', 'full')):
                with self.subTest(dashboard=dashboard, old=old, new=new):
                    self.state.write_text(f'pipeline:\n  path: {old}\nlifecycle: Running\n', encoding='utf-8')
                    before = self.state.read_bytes()
                    result = self.write('--pipeline', '--field', 'Pipeline Path', '--value', new, dashboard=dashboard)
                    refused = (old == 'direct') != (new == 'direct')
                    if refused:
                        self.assertNotEqual(result.returncode, 0)
                        self.assertEqual(self.state.read_bytes(), before)
                    else:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertIn('path: ' + new, self.state.read_text(encoding='utf-8'))

    def test_both_writers_reject_direct_for_undeclared_legacy_work_with_real_artifacts(self):
        for dashboard in (False, True):
            for layout in ('lite', 'full'):
                with self.subTest(dashboard=dashboard, layout=layout):
                    # Use a separate work directory per case so each legacy layout is real.
                    case = self.project / '.aid/works' / f'work-{int(dashboard) + 2:03d}-{layout}'
                    case.mkdir()
                    state = case / 'STATE.yml'
                    state.write_text('lifecycle: Running\nphase: Execute\n', encoding='utf-8')
                    if layout == 'lite':
                        (case / 'BLUEPRINT.md').write_text('# Legacy blueprint\n', encoding='utf-8')
                        detail = case / 'tasks/task-001/DETAIL.md'
                        detail.parent.mkdir(parents=True)
                        detail.write_text('# Legacy task\n', encoding='utf-8')
                    else:
                        nested = case / 'deliveries/delivery-001/tasks/task-001/STATE.yml'
                        nested.parent.mkdir(parents=True)
                        nested.write_text('state: Pending\n', encoding='utf-8')
                    before = {p.relative_to(case): p.read_bytes() for p in case.rglob('*') if p.is_file()}
                    env = dict(self.env, AID_STATE_FILE=state.relative_to(self.project).as_posix(),
                               AID_WORK_DIR=case.relative_to(self.project).as_posix())
                    script = 'dashboard/scripts/writeback-state.sh' if dashboard else '.aid/runtime/scripts/execute/writeback-state.sh'
                    result = subprocess.run([self.bash, script, '--pipeline', '--field', 'Pipeline Path', '--value', 'direct'],
                                            cwd=self.project, env=env, capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual({p.relative_to(case): p.read_bytes() for p in case.rglob('*') if p.is_file()}, before)

    def test_direct_writer_transitions_and_task_delivery_requests_do_not_invent_artifacts(self):
        self.state.write_text("pipeline:\n  path: direct\n  initiator: aid-change\n"
                              "goal: fix notes\nuser_approved: 'no'\nlifecycle: Running\n"
                              "phase: Execute\nactive_skill: aid-change\n", encoding='utf-8')
        before = self.state.read_text(encoding='utf-8').splitlines(keepends=True)
        result = self.write('--pipeline', '--field', 'Updated', '--value', '2031-02-03T04:05:06Z')
        self.assertEqual(result.returncode, 0, result.stderr)
        after = self.state.read_text(encoding='utf-8').splitlines(keepends=True)
        self.assertEqual([line for line in before if not line.startswith('updated:')],
                         [line for line in after if not line.startswith('updated:')])
        stable = self.state.read_bytes()
        for dashboard in (False, True):
            with self.subTest(dashboard=dashboard):
                self.assertNotEqual(self.write('--task-id', '001', '--field', 'State', '--value', 'In Progress',
                                               dashboard=dashboard).returncode, 0)
                self.assertNotEqual(self.write('--delivery-id', '001', '--lifecycle', 'Executing',
                                               dashboard=dashboard).returncode, 0)
        self.assertEqual(self.state.read_bytes(), stable)
        self.assertFalse((self.work / 'deliveries').exists())
        self.assertFalse((self.work / 'tasks').exists())

    def test_actual_direct_lifecycle_reason_and_evidence_round_trip(self):
        if yaml is None:
            self.skipTest('PyYAML required to verify direct state values')
        for lifecycle, reason_field, reason_key, reason in (
            ('Completed', None, None, None),
            ('Blocked', 'Block Reason', 'block_reason', 'The required check could not run'),
            ('Paused-Awaiting-Input', 'Pause Reason', 'pause_reason', 'Awaiting the user decision'),
        ):
            for dashboard in (False, True):
                with self.subTest(lifecycle=lifecycle, dashboard=dashboard):
                    self.state.write_text("pipeline:\n  path: direct\n  initiator: aid-change\n"
                                          "goal: fix notes\nuser_approved: 'no'\nlifecycle: Running\n"
                                          "phase: Execute\nactive_skill: aid-change\n", encoding='utf-8')
                    evidence = 'Actual result: focused check passed' if lifecycle == 'Completed' else 'Actual result: no verified completion'
                    result = self.write('--pipeline', '--field', 'Direct Evidence', '--value', evidence, dashboard=dashboard)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    if reason_field:
                        result = self.write('--pipeline', '--field', reason_field, '--value', reason, dashboard=dashboard)
                        self.assertEqual(result.returncode, 0, result.stderr)
                    result = self.write('--pipeline', '--field', 'Lifecycle', '--value', lifecycle, dashboard=dashboard)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    data = yaml.safe_load(self.state.read_text(encoding='utf-8'))
                    self.assertEqual(data['lifecycle'], lifecycle)
                    self.assertEqual(data['evidence'], evidence)
                    self.assertEqual(data['user_approved'], 'no')
                    if reason_key:
                        self.assertEqual(data[reason_key], reason)
                    for forbidden in ('interview', 'delivery_state', 'delivery_gate', 'tasks_lifecycle'):
                        self.assertNotIn(forbidden, data)
                    self.assertFalse((self.work / 'deliveries').exists())
                    self.assertFalse((self.work / 'tasks').exists())

    def test_direct_skill_lifecycle_instructions_require_actual_writeback(self):
        """Prose-only contract: this does not establish an agent's behavior."""
        text = (ROOT / 'canonical/skills/aid-change/SKILL.md').read_text(encoding='utf-8')
        flat = re.sub(r'\s+', ' ', text)
        self.assertIn('writeback-state.sh', flat, 'the skill must identify the actual state writer')
        self.assertRegex(flat, r'(?i)only after.{0,180}checks?.{0,100}(?:succeeded|passed).{0,150}lifecycle.{0,60}completed')
        for term in ('Lifecycle', 'Blocked', 'Block Reason', 'Paused-Awaiting-Input', 'Pause Reason', 'Direct Evidence'):
            self.assertIn(term.casefold(), flat.casefold(), f'missing direct lifecycle instruction: {term}')
        self.assertRegex(flat, r'(?i)(?:actual|real).{0,60}evidence|evidence.{0,60}(?:actual|real)')
        self.assertRegex(flat, r'(?i)(?:do not|never).{0,100}(?:invent|assume|fabricate).{0,100}(?:evidence|approval|checks?)')

    def test_direct_writer_refuses_existing_unrelated_delivery_and_task_files(self):
        self.state.write_text("pipeline:\n  path: direct\n  initiator: aid-change\n"
                              "goal: fix notes\nuser_approved: 'no'\nlifecycle: Running\n"
                              "phase: Execute\nactive_skill: aid-change\n", encoding='utf-8')
        delivery = self.work / 'deliveries/delivery-001/STATE.yml'
        task = delivery.parent / 'tasks/task-001/STATE.yml'
        task.parent.mkdir(parents=True)
        delivery.write_bytes(b'delivery_state: Pending-Spec\n')
        task.write_bytes(b'state: Pending\n')
        before = (self.state.read_bytes(), delivery.read_bytes(), task.read_bytes())
        for dashboard in (False, True):
            with self.subTest(dashboard=dashboard):
                self.assertNotEqual(self.write('--task-id', '001', '--field', 'State', '--value', 'In Progress',
                                               dashboard=dashboard).returncode, 0)
                self.assertNotEqual(self.write('--delivery-id', '001', '--lifecycle', 'Executing',
                                               dashboard=dashboard).returncode, 0)
                self.assertEqual((self.state.read_bytes(), delivery.read_bytes(), task.read_bytes()), before)

    def test_legacy_json_mode_remains_available(self):
        path = self.root / 'legacy.json'
        data = {'goal': 'preserve café', 'count': 2}
        result = subprocess.run([sys.executable, str(self.script), '--file', str(path), '--data', json.dumps(data)],
                                cwd=self.project, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(path.read_text(encoding='utf-8')), data)


if __name__ == '__main__':
    unittest.main()
