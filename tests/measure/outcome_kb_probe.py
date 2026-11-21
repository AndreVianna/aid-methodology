#!/usr/bin/env python3
"""Prepare a small, source-backed KB task; do not invoke a model.

The separate oracle is not claimed to be hidden from an agent.
"""
import argparse
import hashlib
import json
import os
import shutil
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / '.aid/.temp'
FIXTURE = ROOT / 'tests/measure/fixture'
FILES = ('README.md', '.aid/knowledge/PROJECT.md', '.aid/knowledge/INDEX.md',
         '.aid/knowledge/architecture.md', '.aid/knowledge/capability-inventory.md',
         '.aid/knowledge/module-map.md', 'src/notes/__init__.py', 'src/notes/__main__.py',
         'src/notes/commands.py', 'src/notes/store.py', 'tests/test_store.py')
REQUEST = '''Continue the already allocated aid-outcome work for this small notes task.
The list command should show pinned notes first and every note exactly once,
with insertion order preserved within each group. Listing must not change saved
notes. Preserve existing add and pin behavior. Record one requirements document,
consult the relevant project KB and current source, implement and test the fix,
and self-check the whole result. Obtain the independent review required by the
trial; if it is unavailable, report the result unverified. You are authorized to
update affected fixture-local KB facts after confirming the implementation.
Do not push, merge,
access the network, add dependencies, or modify unrelated files.
'''
AUTHORING = '''---
kb-category: primary
source: hand-authored
objective: Review criteria for the disposable notes project.
summary: Requires correct behavior, preservation of data and relevant tests.
sources: [README.md, src/notes/commands.py, src/notes/store.py, tests/test_store.py]
---

# Notes authoring and review criteria

| ID | Applies to | Kind | Criterion | Severity | Why |
|---|---|---|---|---|---|
| G-01 | * | validate | Meet the confirmed task outcomes. | HIGH | Missing required behavior prevents the user completing the work. |
| G-02 | * | validate | Preserve unrelated files and saved note data. | HIGH | Unintended changes can damage user data. |
| G-03 | * | validate | Add or run relevant tests and disclose missing evidence. | MEDIUM | Untested behavior may hide regressions. |
'''
CONNECTORS = '''# Connectors Index

This disposable fixture has no configured connectors.
'''
ORACLE = '''import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(os.environ['NOTES_PROJECT']).resolve()

class ListBehavior(unittest.TestCase):
    def call(self, folder, *args):
        env = dict(os.environ, PYTHONPATH=str(ROOT / 'src'), PYTHONDONTWRITEBYTECODE='1')
        try:
            return subprocess.run([sys.executable, '-m', 'notes', *args], cwd=folder,
                                  env=env, capture_output=True, text=True, timeout=5)
        except subprocess.TimeoutExpired:
            self.fail('notes command timed out after 5 seconds: ' + ' '.join(args))

    def test_pinned_first_once_stable_and_read_only(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as folder:
            path = Path(folder) / 'notes.json'
            rows = [{'id': i, 'text': 'note '+str(i), 'created': '2026-01-01',
                     **({'pinned': True} if i in (2, 4) else {})} for i in range(1, 5)]
            path.write_text(json.dumps(rows), encoding='utf-8')
            before = path.read_bytes()
            result = self.call(folder, 'list')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(),
                             [f'{i}\\t2026-01-01\\tnote {i}' for i in (2, 4, 1, 3)])
            self.assertEqual(path.read_bytes(), before)

    def test_existing_add_and_pin_cli_behavior_is_preserved(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as folder:
            first, second = self.call(folder, 'add', 'alpha'), self.call(folder, 'add', 'beta')
            self.assertEqual((first.returncode, first.stdout.strip()), (0, 'added note 1'))
            self.assertEqual((second.returncode, second.stdout.strip()), (0, 'added note 2'))
            pinned = self.call(folder, 'pin', '1')
            self.assertEqual((pinned.returncode, pinned.stdout.strip()), (0, 'pinned note 1'))
            path = Path(folder) / 'notes.json'
            rows, before = json.loads(path.read_text(encoding='utf-8')), path.read_bytes()
            self.assertEqual([(row['id'], row['text'], row.get('pinned', False)) for row in rows],
                             [(1, 'alpha', True), (2, 'beta', False)])
            missing = self.call(folder, 'pin', '9')
            self.assertEqual(missing.returncode, 1)
            self.assertIn('no note 9', missing.stderr)
            self.assertEqual(path.read_bytes(), before)

    def test_empty_list_does_not_create_a_store(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as folder:
            result = self.call(folder, 'list')
            self.assertEqual((result.returncode, result.stdout), (0, ''))
            self.assertFalse((Path(folder) / 'notes.json').exists())

if __name__ == '__main__':
    unittest.main()
'''


def prepare(out):
    root = ROOT.absolute()
    try:
        parts = BASE.absolute().relative_to(root).parts
    except ValueError as exc:
        raise ValueError('fixture base must be inside the project') from exc
    cursor = root
    for part in parts:
        cursor = cursor / part
        if not os.path.lexists(cursor):
            cursor.mkdir()
        info = cursor.lstat()
        if (not stat.S_ISDIR(info.st_mode) or stat.S_ISLNK(info.st_mode) or
                getattr(info, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0)):
            raise ValueError('fixture base must not traverse links or junctions')
    BASE.resolve().relative_to(ROOT.resolve())
    out = Path(out).absolute()
    if out.parent != BASE.absolute() or out.name in ('', '.', '..'):
        raise ValueError('fixture must be a new direct child of .aid/.temp')
    out.mkdir(exist_ok=False)
    project = out / 'project'
    project.mkdir()
    hashes = {}
    for name in FILES:
        source, target = FIXTURE / name, project / name
        if source.is_symlink() or not source.is_file():
            raise ValueError('fixture input is missing or linked: ' + name)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        hashes[name] = {'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
    architecture = project / '.aid/knowledge/architecture.md'
    text = architecture.read_text(encoding='utf-8')
    old = 'Each call reads the whole JSON\n  file, changes it in memory, and writes it back.'
    new = ('Reads load the JSON list; add and successful pin change it in memory and write it back. '
           'Listing only reads.')
    if text.count(old) != 1:
        raise ValueError('unexpected source KB architecture; fixture preserved')
    text = text.replace(old, new)
    old = ' A file the user asks for, such as an export, is written by the command that produces it (see State).'
    if text.count(old) != 1:
        raise ValueError('unexpected source KB export claim; fixture preserved')
    text = text.replace(old, '')
    old = ('An export file the user asks for (for example `notes.csv`) is output, not state: no\n'
           'command reads it back, and it does not change `notes.json`.')
    if text.count(old) != 1:
        raise ValueError('unexpected source KB export state; fixture preserved')
    architecture.write_text(text.replace(old, 'The baseline exposes no export command.'), encoding='utf-8')
    card = project / '.aid/knowledge/PROJECT.md'
    text = card.read_text(encoding='utf-8')
    old = 'Python and the standard library; no external runtime dependencies.'
    if text.count(old) != 1:
        raise ValueError('unexpected source project card; fixture preserved')
    card.write_text(text.replace(old, 'Python 3.10+ and the standard library; no external runtime dependencies.'),
                    encoding='utf-8')
    index = project / '.aid/knowledge/INDEX.md'
    with index.open('a', encoding='utf-8') as stream:
        stream.write('| `authoring-conventions.md` | Review criteria for work in this fixture. |\n')
    (project / '.aid/knowledge/authoring-conventions.md').write_text(AUTHORING, encoding='utf-8')
    connectors = project / '.aid/connectors'
    connectors.mkdir()
    (connectors / 'INDEX.md').write_text(CONNECTORS, encoding='utf-8')
    inventory = project / '.aid/knowledge/capability-inventory.md'
    text = inventory.read_text(encoding='utf-8')
    old = 'summary: Lists each command, what it does, and what it stores, as the code currently implements them.'
    new = 'summary: Lists commands and intended behavior, including a known baseline list defect.'
    if text.count(old) != 1:
        raise ValueError('unexpected source KB inventory; fixture preserved')
    text = text.replace(old, new)
    old = '| `list` | Prints every note once as id, timestamp and text:'
    if text.count(old) != 1:
        raise ValueError('unexpected source KB list entry; fixture preserved')
    text = text.replace(old, '| `list` | Intended: print every note once as id, timestamp and text:')
    text += ('\n## Known baseline discrepancy\n\n'
             'The list command is intended to show every note exactly once, pinned first. '
             'The current `src/notes/commands.py` loop uses `pinned + notes`, so pinned '
             'notes are duplicated. Recheck this fact after fixing the implementation.\n')
    inventory.write_text(text, encoding='utf-8')
    for name in FILES:
        hashes[name]['fixture_sha256'] = hashlib.sha256((project / name).read_bytes()).hexdigest()
    for name in ('.aid/knowledge/authoring-conventions.md', '.aid/connectors/INDEX.md'):
        hashes[name] = {'source': 'fixture-authored',
                        'fixture_sha256': hashlib.sha256((project / name).read_bytes()).hexdigest()}
    (out / 'request.txt').write_text(REQUEST, encoding='utf-8')
    (out / 'oracle').mkdir()
    (out / 'oracle/test_notes_outcome.py').write_text(ORACLE, encoding='utf-8')
    (out / 'inputs.json').write_text(json.dumps(hashes, indent=2) + '\n', encoding='utf-8')
    return project


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    try:
        print(prepare(args.output))
        return 0
    except (OSError, ValueError) as exc:
        print('outcome KB probe: ' + str(exc))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
