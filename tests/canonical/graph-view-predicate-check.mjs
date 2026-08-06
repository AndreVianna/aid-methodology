// graph-view-predicate-check.mjs -- the Node-side half of the D10 predicate group
// (GV03-GV05): importing the shared module in a bare process, and the two
// doc<->code lockstep containments that need no DOM at all.
//
// GV01 (the greppable boundary rules) and GV02 (byte-identity of the browser's
// inlined copy against a REAL generated graph.html) live in the bash suite
// itself: GV01 is pure text-pattern matching over files already on disk, and
// GV02 piggybacks on the SAME render-graph-view.sh invocation the BLD group
// drives for oracle (b) -- one subject invocation, not a second one just to
// re-derive a substring check S1 would then have to justify twice.
//
// PROTOCOL   GV \t PASS|FAIL \t <label>     (see graph-view-model.mjs; the wire
// tag and the SPEC's "GV" assertion-id prefix are the same three characters by
// coincidence, not by re-use of one for the other -- the bash suite's consume()
// only ever reads the tag, never the label's own leading token.)
//
// USAGE
//   node graph-view-predicate-check.mjs <repo-root>

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const repo = process.argv[2];
if (!repo) {
	process.stdout.write('GV\tFAIL\tGV03 harness — repo root is required\n');
	process.exit(1);
}

const results = [];
function ok(id, label, condition, detail) {
	const text = id + ' ' + label + (detail ? ' [' + detail + ']' : '');
	const line = 'GV\t' + (condition ? 'PASS' : 'FAIL') + '\t' + text + (condition ? '' : ' — assertion did not hold');
	results.push(!!condition);
	process.stdout.write(line + '\n');
}

const predicatePath = path.join(repo, 'canonical/aid/scripts/graph/coverage-predicate.mjs');
const bearingPath = path.join(repo, 'canonical/aid/templates/graph/coverage-bearing.yml');

let mod;
try {
	mod = await import(pathToFileURL(predicatePath).href);
} catch (error) {
	process.stdout.write('GV\tFAIL\tGV03 importing coverage-predicate.mjs in a bare Node process succeeds — '
		+ (error && error.message ? error.message : String(error)) + '\n');
	process.exit(1);
}
const { RELATION_CATEGORY, COVERAGE_BEARING, detectArtifactGaps } = mod;

// ---------------------------------------------------------------------------
// GV03 -- the plain import binds RELATION_CATEGORY, and detectArtifactGaps
// returns the expected NON-TRIVIAL set over a fixture built here (not empty,
// not "every candidate", so a predicate that always says yes or always says no
// both fail this).
// ---------------------------------------------------------------------------
const fixtureEdges = [
	{ sourceId: 'kb:x.md', sourceKind: 'document', targetId: 'int:covered.txt', targetKind: 'source-artifact', s2t: 'documents', t2s: 'documented-by' },
	{ sourceId: 'kb:x.md', sourceKind: 'document', targetId: 'int:mentioned-only.txt', targetKind: 'source-artifact', s2t: 'mentions', t2s: 'mentioned-in' },
];
const gaps = detectArtifactGaps({ nodeIds: ['int:covered.txt', 'int:mentioned-only.txt', 'int:absent.txt'], edges: fixtureEdges });
ok('GV03', 'the bare-Node import binds RELATION_CATEGORY and detectArtifactGaps returns the exact expected gap set over a built fixture',
	typeof RELATION_CATEGORY === 'object' && RELATION_CATEGORY['has-part'] === 'structure'
	&& JSON.stringify(gaps) === JSON.stringify(['int:absent.txt', 'int:mentioned-only.txt']),
	JSON.stringify(gaps));

// ---------------------------------------------------------------------------
// GV04 -- COVERAGE_BEARING equals the coverage_bearing: sequence in the
// reviewable yml copy, read from disk (never imported -- that would be a second
// way for the two to disagree, per the yml's own header).
// ---------------------------------------------------------------------------
let ymlSet = null;
try {
	const ymlText = fs.readFileSync(bearingPath, 'utf8');
	const m = ymlText.match(/coverage_bearing:\r?\n((?:[ \t]*-[ \t].+\r?\n?)+)/);
	if (m) {
		ymlSet = new Set(m[1].split(/\r?\n/).filter((l) => l.trim() !== '').map((l) => l.replace(/^[ \t]*-[ \t]*/, '').trim()));
	}
} catch { /* ymlSet stays null; reported below as a failure, never a crash */ }
const bearingArr = Array.from(COVERAGE_BEARING || []);
const gv04 = !!ymlSet && ymlSet.size > 0 && ymlSet.size === bearingArr.length && bearingArr.every((v) => ymlSet.has(v));
ok('GV04', 'COVERAGE_BEARING (coverage-predicate.mjs) equals the coverage_bearing: sequence in coverage-bearing.yml',
	gv04, bearingArr.join(',') + ' vs ' + (ymlSet ? Array.from(ymlSet).join(',') : 'unparsed'));

// ---------------------------------------------------------------------------
// GV05 -- COVERAGE_BEARING subseteq keys(RELATION_CATEGORY), a containment
// inside this one file.
// ---------------------------------------------------------------------------
const categoryKeys = new Set(Object.keys(RELATION_CATEGORY || {}));
const gv05 = bearingArr.length > 0 && bearingArr.every((k) => categoryKeys.has(k));
ok('GV05', 'COVERAGE_BEARING is a subset of keys(RELATION_CATEGORY)', gv05, bearingArr.join(','));

process.exit(results.every(Boolean) ? 0 : 1);
