#!/usr/bin/env python3
"""Purpose: verify compact direct works across both readers and dashboard path summary.
Usage: python dashboard/reader/tests/test_direct_work_contract.py
Exit codes: 0 when all cases pass, nonzero otherwise.
"""
import dataclasses
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))
from dashboard.reader import read_repo  # noqa: E402

NODE = shutil.which('node')
NODE_READER = """
import { readRepo } from './dashboard/server/reader.mjs';
const model = readRepo(process.argv[1]);
console.log(JSON.stringify({works: model.works, warnings: model.read.parse_warnings}));
"""
NODE_PATH_SUMMARY = """
import fs from 'node:fs';
import vm from 'node:vm';
const html = fs.readFileSync('dashboard/home.html', 'utf8');
const begin = html.indexOf('  function _pathSummary(work) {');
const end = html.indexOf('  // Two-part progress model:', begin);
if (begin < 0 || end < 0) throw new Error('path summary not found');
const summary = vm.runInNewContext(html.slice(begin, end) + '\\n_pathSummary', {_formatRecipe: () => ''});
console.log(JSON.stringify(JSON.parse(process.argv[1]).map(summary)));
"""
NODE_STAT_STRIP = """
import fs from 'node:fs';
import vm from 'node:vm';
const html = fs.readFileSync('dashboard/home.html', 'utf8');
const begin = html.indexOf('  function _renderStatStrip(work) {');
const end = html.indexOf('  function _renderFeaturesDisclosure(', begin);
if (begin < 0 || end < 0) throw new Error('stat strip function not found');
const strip = {style: {}, innerHTML: '', labels: [], appendChild(el) { this.labels.push(el.textContent); }};
const document = {getElementById: () => strip, createElement: () => ({})};
const render = vm.runInNewContext(html.slice(begin, end) + '\\n_renderStatStrip', {document});
render(JSON.parse(process.argv[1]));
console.log(JSON.stringify(strip.labels));
"""


@unittest.skipUnless(NODE, 'Node is required to verify the other dashboard reader')
class DirectWorkContract(unittest.TestCase):
    def setUp(self):
        scratch = ROOT / '.aid/.temp'
        scratch.mkdir(parents=True, exist_ok=True)
        self.tmp = tempfile.TemporaryDirectory(prefix='direct-reader-', dir=scratch)
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def work(self, name, path, lifecycle='Running', extra=''):
        work = self.root / '.aid' / 'works' / name
        work.mkdir(parents=True)
        pipeline = f'pipeline:\n  path: {path}\n  initiator: aid-change\n' if path else ''
        body = (pipeline + f'lifecycle: {lifecycle}\nphase: Execute\nactive_skill: aid-change\n'
                'started: 2026-10-27\nupdated: 2026-10-27\nminimum_grade: A\n'
                'user_approved: no\ngoal: Fix the duplicate entry\n' + extra)
        (work / 'STATE.yml').write_text(body, encoding='utf-8')
        return work

    def read_both(self):
        py = dataclasses.asdict(read_repo(self.root))
        node = subprocess.run([NODE, '--input-type=module', '-e', NODE_READER, str(self.root)],
                              cwd=ROOT, capture_output=True, text=True, check=True)
        js = json.loads(node.stdout)
        return (py['works'], py['read']['parse_warnings']), (js['works'], js['warnings'])

    def test_direct_work_has_no_invented_delivery_or_task(self):
        self.work('work-001-direct', 'direct')
        for works, warnings in self.read_both():
            with self.subTest(runtime=type(works[0]['lifecycle'])):
                self.assertEqual(len(works), 1)
                work = works[0]
                self.assertEqual(work['work_path'], 'direct')
                self.assertEqual(work['lifecycle'], 'Running')
                self.assertEqual(work['active_skill'], 'aid-change')
                self.assertEqual(work['objective'], 'Fix the duplicate entry', 'the actual direct goal must be visible')
                self.assertEqual(work['tasks'], [])
                self.assertEqual(work['deliverables'], [])
                self.assertEqual(work['features'], [])
                self.assertEqual(work['pending_inputs'], [])
                self.assertFalse(work['user_approved'])
                self.assertFalse(any('delivery' in str(w).lower() for w in warnings), warnings)

    def test_direct_missing_approval_is_not_fabricated(self):
        work = self.work('work-001-no-approval', 'direct')
        state = work / 'STATE.yml'
        state.write_text(state.read_text(encoding='utf-8').replace('user_approved: no\n', ''), encoding='utf-8')
        for works, _ in self.read_both():
            self.assertIsNone(works[0]['user_approved'], 'missing approval must not become an implied decision')
            self.assertEqual(works[0]['tasks'], [])
            self.assertEqual(works[0]['deliverables'], [])
            self.assertEqual(works[0]['pending_inputs'], [])

    def test_conflicting_nested_artifacts_fail_safe_and_warn_in_both_readers(self):
        work = self.work('work-001-conflict', 'direct')
        nested = work / 'deliveries/delivery-001/tasks/task-001'
        nested.mkdir(parents=True)
        (nested / 'STATE.yml').write_text('state: In Progress\n', encoding='utf-8')
        (nested.parent.parent / 'STATE.yml').write_text('delivery_state: Executing\n', encoding='utf-8')
        for works, warnings in self.read_both():
            with self.subTest(runtime=str(type(works[0]['lifecycle']))):
                self.assertEqual(works[0]['work_path'], 'direct')
                self.assertEqual(works[0]['tasks'], [], 'contradictory nested tasks must not be displayed')
                self.assertEqual(works[0]['deliverables'], [], 'contradictory delivery must not be displayed')
                self.assertTrue(any('direct' in str(w).lower() and ('conflict' in str(w).lower() or
                                'contradict' in str(w).lower()) for w in warnings), warnings)

    def test_direct_conflicting_flat_and_authored_pipeline_artifacts_are_diagnosed(self):
        cases = [
            ('flat', '', True),
            ('delivery', 'delivery_state: Executing\n', False),
            ('gate', 'delivery_gate:\n  issue_list:\n    - Pending issue\n', False),
            ('interview', 'interview:\n  state: In Progress\n', False),
            ('tasks', 'tasks_lifecycle:\n  task-001:\n    state: In Progress\n', False),
        ]
        for index, (name, extra, flat) in enumerate(cases, 1):
            work = self.work(f'work-{index:03d}-{name}', 'direct', extra=extra)
            if flat:
                task = work / 'tasks/task-001'
                task.mkdir(parents=True)
                (task / 'DETAIL.md').write_text('# A task\n', encoding='utf-8')
        for works, warnings in self.read_both():
            self.assertEqual(len(works), len(cases))
            for work in works:
                with self.subTest(work=work['work_id'], runtime=str(type(work['lifecycle']))):
                    self.assertEqual(work['work_path'], 'direct')
                    self.assertEqual(work['tasks'], [])
                    self.assertEqual(work['deliverables'], [])
                    self.assertTrue(any(work['work_id'] in str(w) and 'direct' in str(w).lower() and
                                    ('conflict' in str(w).lower() or 'contradict' in str(w).lower())
                                    for w in warnings), warnings)

    def test_direct_lifecycle_values_are_preserved_by_both_readers(self):
        states = ['Running', 'Paused-Awaiting-Input', 'Blocked', 'Completed', 'Canceled']
        for index, state in enumerate(states, 1):
            self.work(f'work-{index:03d}-{state.lower()}', 'direct', lifecycle=state)
        for works, _ in self.read_both():
            self.assertEqual([work['lifecycle'] for work in works], states)
            self.assertTrue(all(work['work_path'] == 'direct' and not work['tasks'] and
                                not work['deliverables'] for work in works))

    def test_lite_full_and_legacy_reading_is_preserved(self):
        lite = self.work('work-001-lite', 'lite', extra='delivery_state: Executing\ntasks_lifecycle:\n  task-001:\n    state: In Progress\n')
        task = lite / 'tasks/task-001'
        task.mkdir(parents=True)
        (task / 'DETAIL.md').write_text('# A task\n', encoding='utf-8')
        full = self.work('work-002-full', 'full')
        nested = full / 'deliveries/delivery-001/tasks/task-001'
        nested.mkdir(parents=True)
        (nested / 'STATE.yml').write_text('state: In Progress\n', encoding='utf-8')
        (nested.parent.parent / 'STATE.yml').write_text('delivery_state: Executing\n', encoding='utf-8')
        self.work('work-003-legacy', None)
        for works, _ in self.read_both():
            self.assertEqual([w['work_path'] for w in works], ['lite', 'full', None])
            self.assertEqual([len(w['tasks']) for w in works], [1, 1, 0])
            self.assertEqual([len(w['deliverables']) for w in works], [1, 1, 0])

    def test_visible_path_summary_is_direct_without_pipeline_artifacts(self):
        works = [{'work_path': 'direct', 'features': [], 'deliverables': [], 'tasks': []},
                 {'work_path': 'lite', 'kind': 'Fix', 'tasks': []},
                 {'work_path': 'full', 'features': [], 'deliverables': [], 'tasks': []}]
        result = subprocess.run([NODE, '--input-type=module', '-e', NODE_PATH_SUMMARY, json.dumps(works)],
                                cwd=ROOT, capture_output=True, text=True, check=True)
        direct, lite, full = json.loads(result.stdout)
        self.assertIn('direct', direct.lower())
        self.assertNotIn('identifying', direct.lower())
        for invented in ('task', 'delivery', 'feature', 'interview', 'approval', 'gate'):
            self.assertNotIn(invented, direct.lower())
        self.assertIn('lite', lite.lower())
        self.assertIn('full', full.lower())

    def test_visible_stat_strip_does_not_invent_direct_work_counts(self):
        work = {'work_path': 'direct', 'features': [], 'deliverables': [], 'tasks': []}
        result = subprocess.run([NODE, '--input-type=module', '-e', NODE_STAT_STRIP, json.dumps(work)],
                                cwd=ROOT, capture_output=True, text=True, check=True)
        labels = json.loads(result.stdout)
        self.assertTrue(any('direct' in label.lower() for label in labels), labels)
        self.assertFalse(any(any(word in label.lower() for word in ('task', 'delivery', 'deliverable', 'feature', 'gate', 'approval'))
                             for label in labels), labels)

    def test_resume_decision_table_prose_prioritizes_direct_lifecycle(self):
        # This verifies the authored decision table's order, not model behavior.
        gate = (ROOT / 'canonical/aid/templates/work-initiation-gate.md').read_text(encoding='utf-8')
        section = gate.split('### 3b.', 1)[1].split('**If the resolved route', 1)[0]
        rows = [line for line in section.splitlines() if line.startswith('|') and not line.startswith('|---')]
        def position(predicate, description):
            matches = [i for i, row in enumerate(rows) if predicate(row.lower())]
            self.assertTrue(matches, f'missing {description} decision in source table: {rows}')
            return matches[0]
        terminal = position(lambda r: 'completed' in r and 'canceled' in r and 'stop' in r, 'terminal')
        blocked = position(lambda r: 'direct' in r and 'blocked' in r, 'direct blocked')
        paused = position(lambda r: 'direct' in r and 'paused' in r, 'direct paused')
        running = position(lambda r: 'direct' in r and 'running' in r and 'aid-change' in r, 'direct running')
        execute = position(lambda r: 'aid-execute' in r and 'execute' in r, 'generic execute')
        self.assertLess(terminal, running)
        self.assertLess(blocked, running)
        self.assertLess(paused, running)
        self.assertLess(running, execute)
        self.assertLess(terminal, execute)


if __name__ == '__main__':
    unittest.main()
