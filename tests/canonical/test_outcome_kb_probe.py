#!/usr/bin/env python3
"""Validate the small source-backed KB fixture without starting a model."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / '.aid/.temp'
spec = importlib.util.spec_from_file_location('outcome_kb_probe', ROOT / 'tests/measure/outcome_kb_probe.py')
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)
snapshot_spec = importlib.util.spec_from_file_location('outcome_snapshot', ROOT / 'tests/measure/outcome_snapshot.py')
snapshotter = importlib.util.module_from_spec(snapshot_spec)
snapshot_spec.loader.exec_module(snapshotter)


class KBProbe(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        SCRATCH.resolve().relative_to(ROOT.resolve())
        self.tmp = tempfile.TemporaryDirectory(prefix='outcome-kb-test-', dir=SCRATCH)
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.old_base = probe.BASE
        probe.BASE = self.base
        self.addCleanup(setattr, probe, 'BASE', self.old_base)
        self.out = self.base / 'fixture'

    def test_prepared_kb_matches_source_and_existing_fixture_is_preserved(self):
        project = probe.prepare(self.out)
        for name in probe.FILES:
            if name not in ('.aid/knowledge/architecture.md', '.aid/knowledge/capability-inventory.md',
                            '.aid/knowledge/PROJECT.md', '.aid/knowledge/INDEX.md'):
                self.assertEqual((project / name).read_bytes(), (probe.FIXTURE / name).read_bytes())
        architecture = (project / '.aid/knowledge/architecture.md').read_text(encoding='utf-8')
        self.assertIn('Listing only reads', architecture)
        self.assertIn('baseline exposes no export command', architecture)
        inventory = (project / '.aid/knowledge/capability-inventory.md').read_text(encoding='utf-8')
        self.assertIn('pinned notes are duplicated', inventory)
        self.assertIn('pinned + notes', (project / 'src/notes/commands.py').read_text(encoding='utf-8'))
        self.assertIn('Python 3.10+', (project / '.aid/knowledge/PROJECT.md').read_text(encoding='utf-8'))
        self.assertIn('G-01', (project / '.aid/knowledge/authoring-conventions.md').read_text(encoding='utf-8'))
        self.assertIn('no configured connectors', (project / '.aid/connectors/INDEX.md').read_text(encoding='utf-8'))
        saved = (project / '.aid/knowledge/capability-inventory.md').read_bytes()
        with self.assertRaises(FileExistsError):
            probe.prepare(self.out)
        self.assertEqual((project / '.aid/knowledge/capability-inventory.md').read_bytes(), saved)

    def test_fixture_base_rejects_a_symlinked_ancestor(self):
        outside = self.base / 'outside'
        outside.mkdir()
        linked = self.base / 'linked'
        try:
            linked.symlink_to(outside, target_is_directory=True)
        except OSError:
            self.skipTest('directory symlinks unavailable')
        probe.BASE = linked
        with self.assertRaisesRegex(ValueError, 'links or junctions'):
            probe.prepare(linked / 'fixture')
        self.assertEqual(list(outside.iterdir()), [])

    def test_existing_suite_passes_and_independent_oracle_fails_on_real_bug(self):
        project = probe.prepare(self.out)
        temp = self.base / 'tmp'
        temp.mkdir()
        env = dict(os.environ, NOTES_PROJECT=str(project), PYTHONDONTWRITEBYTECODE='1',
                   TMPDIR=str(temp), TMP=str(temp), TEMP=str(temp), HOME=str(self.base))
        baseline = subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests'],
                                  cwd=project, env=env, capture_output=True, text=True, timeout=30)
        self.assertEqual(baseline.returncode, 0, baseline.stdout + baseline.stderr)
        result = subprocess.run([sys.executable, str(self.out / 'oracle/test_notes_outcome.py')],
                                cwd=project, env=env, capture_output=True, text=True, timeout=30)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('FAIL: test_pinned_first_once_stable_and_read_only', result.stderr)
        self.assertIn('FAILED (failures=1)', result.stderr)

    def test_known_good_fixture_fix_makes_the_same_checks_pass(self):
        project = probe.prepare(self.out)
        commands = project / 'src/notes/commands.py'
        source = commands.read_text(encoding='utf-8')
        self.assertEqual(source.count('for note in pinned + notes:'), 1)
        commands.write_text(source.replace('for note in pinned + notes:',
                                          'for note in pinned + [n for n in notes if not n.get("pinned")]:', 1),
                            encoding='utf-8')
        temp = self.base / 'tmp'
        temp.mkdir()
        env = dict(os.environ, NOTES_PROJECT=str(project), PYTHONDONTWRITEBYTECODE='1',
                   TMPDIR=str(temp), TMP=str(temp), TEMP=str(temp), HOME=str(self.base))
        for command in ([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests'],
                        [sys.executable, str(self.out / 'oracle/test_notes_outcome.py')]):
            result = subprocess.run(command, cwd=project, env=env, capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_hanging_candidate_is_reported_as_timeout(self):
        project = probe.prepare(self.out)
        (project / 'src/notes/commands.py').write_text('import time\ntime.sleep(20)\n', encoding='utf-8')
        temp = self.base / 'tmp'
        temp.mkdir()
        env = dict(os.environ, NOTES_PROJECT=str(project), PYTHONDONTWRITEBYTECODE='1',
                   TMPDIR=str(temp), TMP=str(temp), TEMP=str(temp), HOME=str(self.base))
        result = subprocess.run([sys.executable, str(self.out / 'oracle/test_notes_outcome.py'),
                                 'ListBehavior.test_pinned_first_once_stable_and_read_only'],
                                cwd=project, env=env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 1)
        self.assertIn('timed out after 5 seconds', result.stderr)

    def test_snapshot_includes_hidden_paths_and_excludes_only_root_git(self):
        project = probe.prepare(self.out)
        (project / '.git').mkdir()
        (project / '.git/config').write_text('git metadata', encoding='utf-8')
        hidden = project / '.aid/hidden-user-file'
        hidden.write_text('preserve', encoding='utf-8')
        before = snapshotter.snapshot(project)
        self.assertIn('.aid/hidden-user-file', before['paths'])
        self.assertNotIn('.git/config', before['paths'])
        hidden.write_text('changed', encoding='utf-8')
        after = snapshotter.snapshot(project)
        self.assertNotEqual(before['paths']['.aid/hidden-user-file'], after['paths']['.aid/hidden-user-file'])

    def test_snapshot_refuses_unreadable_directory_instead_of_skipping(self):
        project = probe.prepare(self.out)
        def failing_walk(root, followlinks, onerror):
            onerror(PermissionError('unreadable fixture directory'))
            yield root, [], []
        with mock.patch.object(snapshotter.os, 'walk', side_effect=failing_walk):
            with self.assertRaisesRegex(PermissionError, 'unreadable fixture directory'):
                snapshotter.snapshot(project)

    def test_snapshot_output_cannot_traverse_a_link_into_fixture(self):
        project = probe.prepare(self.out)
        link = self.base / 'output-link'
        try:
            link.symlink_to(project, target_is_directory=True)
        except OSError:
            self.skipTest('directory symlinks unavailable')
        result = subprocess.run([sys.executable, str(ROOT / 'tests/measure/outcome_snapshot.py'),
                                 '--project', str(project), '--output', str(link / 'snapshot.json')],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse((project / 'snapshot.json').exists())

    def test_snapshot_rejects_parent_traversal_into_fixture(self):
        project = probe.prepare(self.out)
        aliased = project / '..' / project.name
        result = subprocess.run([sys.executable, str(ROOT / 'tests/measure/outcome_snapshot.py'),
                                 '--project', str(aliased), '--output', str(project / 'snapshot.json')],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse((project / 'snapshot.json').exists())

    def test_snapshot_rejects_a_linked_fixture_root(self):
        project = probe.prepare(self.out)
        link = self.base / 'project-link'
        try:
            link.symlink_to(project, target_is_directory=True)
        except OSError:
            self.skipTest('directory symlinks unavailable')
        with self.assertRaisesRegex(ValueError, 'links or junctions'):
            snapshotter.snapshot(link)

    @unittest.skipIf(os.name == 'nt', 'directory chmod is POSIX-specific')
    def test_snapshot_records_root_mode(self):
        project = probe.prepare(self.out)
        before = snapshotter.snapshot(project)['root_mode']
        try:
            project.chmod(before ^ 0o100)
            after = snapshotter.snapshot(project)['root_mode']
            if before == after:
                self.skipTest('filesystem does not preserve POSIX mode changes')
            self.assertNotEqual(before, after)
        finally:
            project.chmod(before)

    def test_snapshot_rejects_a_file_swapped_for_a_link(self):
        project = probe.prepare(self.out)
        victim = project / 'README.md'
        saved = project / 'README.saved'
        available = self.base / 'link-check'
        try:
            available.symlink_to(victim)
        except OSError:
            self.skipTest('file symlinks unavailable')
        available.unlink()
        real_open = snapshotter.os.open
        swapped = [False]
        def swap_then_open(path, flags, *args, **kwargs):
            if Path(path) == victim and not swapped[0]:
                swapped[0] = True
                victim.rename(saved)
                victim.symlink_to(saved)
            return real_open(path, flags, *args, **kwargs)
        try:
            with mock.patch.object(snapshotter.os, 'open', side_effect=swap_then_open):
                with self.assertRaises((OSError, ValueError)):
                    snapshotter.snapshot(project)
            self.assertTrue(swapped[0])
        finally:
            if swapped[0]:
                victim.unlink()
                saved.rename(victim)


if __name__ == '__main__':
    unittest.main()
