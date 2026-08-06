// graph-view-gv.mjs -- the shell-level LensState/CONTROL_MANIFEST fixture layer
// that GV06-GV28 needed and task-014 did not have time to build on first pass.
// This is the SECOND wave of that task: it authors the fixture layer and drives
// as many of GV06-GV28 as the layer can reach with NO DOM.
//
// PROTOCOL -- identical to graph-view-model.mjs, so the bash suite's `consume`
// helper turns every line into a real assert.sh outcome with no new plumbing:
//     GV \t PASS|FAIL|SKIP|NOTE \t <label>
//
// USAGE
//   node graph-view-gv.mjs <bundle.mjs> <repo-root>
//
// THE FIXTURE LAYER
//   graph-view-fixture.mjs's shared FIXTURE (imported as FX below) is reused
//   wherever its shape already fits -- GV06/GV07/GV10 all build on it rather
//   than duplicating a second thirteen-row table. Where GV06/GV09/GV11/GV12/GV21
//   need a PROPERTY the shared fixture does not have (a wrong kb_gaps list, a
//   malformed header, an escaped pipe, a Kind/prefix mismatch, a document backed
//   only by an in-repo image), `buildFile()` below assembles a small,
//   purpose-built relationships.md from FX's own row records or from a literal
//   row list -- never from a second copy of the header or delimiter literals,
//   both of which are read from the bundle under test (`M.HEADER_LITERAL`) or
//   from FX (`FX.HEADER`).
//
// WHAT THIS FILE DOES NOT REACH, AND WHY (see the suite's own header comment for
// the authoritative list; restated here beside the code that stops short)
//   GV13, GV16 -- need contrast-check.mjs / relationship-schema.yml wired in as
//     a second subject; not attempted in this pass.
//   GV17, GV19, GV22, GV24 -- need a real DOM (`data-control` bijection,
//     feature-003's slug algorithm, the fold's keyboard-driven both-directions
//     proof, or a live per-preset write-back through the DOM). Deferred to the
//     DOM half (graph-view-dom.mjs), which SKIPS LOUDLY without jsdom -- adding
//     them here rather than there would misrepresent them as headless-provable.
//   GV23's console half was asserted and FAILED on the frozen tree until
//     task-031 gave render-graph-view.sh a console summary (via
//     build-graph-src.mjs, its own generator) -- see the GV23 block below,
//     unedited by that task, which is the oracle that found the gap and now
//     confirms the fix.

import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const bundlePath = process.argv[2];
const repoRoot = process.argv[3];
if (!bundlePath || !repoRoot) {
	process.stdout.write('GV\tFAIL\tGV00 harness — bundle path and repo root are both required\n');
	process.exit(1);
}

const results = [];
function emit(kind, label) { results.push({ kind, label }); process.stdout.write('GV\t' + kind + '\t' + label + '\n'); }
function ok(id, label, condition, detail) {
	const text = id + ' ' + label + (detail === undefined || detail === null || detail === '' ? '' : ' [' + detail + ']');
	emit(condition ? 'PASS' : 'FAIL', condition ? text : text + ' — assertion did not hold');
	return !!condition;
}
function note(text) { emit('NOTE', text); }
const ids = (list) => Array.from(new Set(list)).sort();
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

let M;
try {
	M = await import(pathToFileURL(bundlePath).href);
} catch (error) {
	emit('FAIL', 'GV00 the four view files load as one module — ' + (error && error.message ? error.message : error));
	process.exit(1);
}
const FX = await import('./graph-view-fixture.mjs');

// ---------------------------------------------------------------------------
// THE FIXTURE LAYER
// ---------------------------------------------------------------------------

/** Rebuild a table row line from one of FX.FIXTURE_ROWS's parsed records --
 *  never from a second literal copy of a row already authored there. */
function rowLine(r) {
	return '| ' + [r.sourceId, r.sourceKind, r.sourceName, r.targetId, r.targetKind, r.targetName,
		r.s2t, r.t2s, r.provenance, r.observation === '' ? ' ' : r.observation].join(' | ') + ' |';
}

/**
 * Assemble a minimal relationships.md. `header` defaults to the bundle's own
 * HEADER_LITERAL (never a second copy typed here); `rows` is an array of
 * already-formed row strings; `gaps` is an array of {id, name} kb_gaps entries.
 */
function buildFile({ header, rows, gaps, notes }) {
	const H = header !== undefined ? header : M.HEADER_LITERAL;
	const D = '|---|---|---|---|---|---|---|---|---|---|';
	const gapsYaml = gaps && gaps.length
		? 'kb_gaps:\n' + gaps.map((g) => '  - id: "' + g.id + '"\n    name: "' + g.name + '"\n    severity: "HIGH"\n    qualifier: "entry-point"\n').join('')
		: '';
	return '---\nkb-category: primary\nsource: generated\ngenerator: test\n' + gapsYaml
		+ 'tags: [C2]\nowner: architect\n---\n\n# Relationships\n\n' + H + '\n' + D + '\n'
		+ rows.join('\n') + '\n' + (notes || '');
}

// ===========================================================================
// GV06 -- a deliberately WRONG kb_gaps reports the exact mismatch, and the
// shell still projects (the headless analogue of "both renderings still mount")
// ===========================================================================
{
	const rows = FX.FIXTURE_ROWS.map(rowLine);
	// int:src/reader.mjs is a real, backed source-artifact in the table (rows
	// 4-6): recording IT as a gap is a false positive the view must disagree
	// with, and DROPPING the real gap (int:tests/orphan-check.sh) from kb_gaps
	// is a false negative the view must also disagree with. Both at once is
	// what makes viewOnly and ledgerOnly each non-empty and distinct.
	const text = buildFile({ rows, gaps: [{ id: 'int:src/reader.mjs', name: 'src/reader.mjs' }] });
	let model, store, vm, threw = false;
	try {
		model = M.parseRelationships(text);
		store = M.createStore(model, M.INITIAL_LENS);
		vm = store.getViewModel();
	} catch (e) { threw = true; }
	const viewOnly = model && ids(model.integrity.viewOnly);
	const ledgerOnly = model && ids(model.integrity.ledgerOnly);
	const union = vm && ids(vm.coverageGaps.artifactUndocumented);
	ok('GV06', 'a deliberately wrong kb_gaps reports the exact viewOnly/ledgerOnly ids and the union publishes both, with no load failure',
		!threw && same(viewOnly, ['int:tests/orphan-check.sh']) && same(ledgerOnly, ['int:src/reader.mjs'])
		&& same(union, ['int:src/reader.mjs', 'int:tests/orphan-check.sh']) && model.integrity.status === 'mismatch',
		'viewOnly=' + (viewOnly || []).join(',') + ' ledgerOnly=' + (ledgerOnly || []).join(','));
	note('GV06 "both renderings still mount" is asserted at its headless analogue -- project()/createStore complete with '
		+ 'no thrown load error -- because this file drives no DOM; the DOM half is deferred (see file header).');
}

// ===========================================================================
// GV07 -- the zero-row artifact: density both-halves, its own single-node
// group under grouping=document, and its label suffix
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const zeroId = FX.ZERO_ROW_NODE;
	const zero = model.nodes.get(zeroId);

	const atDensity1 = store.getViewModel().visibleNodes.some((n) => n.id === zeroId);
	store.setLens({ density: 5 });
	const vm5 = store.getViewModel();
	const atDensity5 = vm5.visibleNodes.some((n) => n.id === zeroId);
	const inGapSet5 = vm5.coverageGaps.artifactUndocumented.includes(zeroId);
	const inOrigin5 = vm5.coverageOrigin.has(zeroId);
	// The VALUE, not merely presence: a zero-row node that IS in kb_gaps and has
	// no table row of its own is the 'ledger-only' half of the coverage origin
	// map, never 'verified' (which would need a real table row) nor 'view-only'
	// (which would need the opposite: a row with no ledger entry).
	const originValue5 = vm5.coverageOrigin.get(zeroId);
	// "no mismatch alarm" -- the fixture's kb_gaps and its recomputed set agree
	// everywhere, so the whole-model integrity status is 'verified', never
	// 'mismatch'. This is the load-time check GV07's own criterion names; GV06
	// is the sibling case that deliberately breaks it.
	const noMismatchAlarm = model.integrity.status === 'verified';
	store.setLens(M.INITIAL_LENS);

	store.setLens({ grouping: 'document' });
	const vmg = store.getViewModel();
	const zeroGroup = vmg.groups.find((g) => g.nodeIds.includes(zeroId));
	const singleGroup = !!zeroGroup && zeroGroup.nodeIds.length === 1 && zeroGroup.foldable === 0 && !vmg.foldedInto.has(zeroId);
	store.setLens(M.INITIAL_LENS);

	// Membership of the "no relationships" group under the TWO EDGE-DERIVED
	// grouping dimensions (relation-category, provenance) -- distinct from the
	// KIND-derived `document` dimension checked above, where the zero-row node
	// gets its OWN single-node group instead. A node with no surviving edge has
	// no category and no provenance to key on, so both edge-derived dimensions
	// must fall back to the dedicated NO_RELATIONSHIPS_GROUP bucket.
	store.setLens({ grouping: 'relation-category' });
	const vmRC = store.getViewModel();
	const rcGroup = vmRC.groups.find((g) => g.nodeIds.includes(zeroId));
	const inNoRelRC = !!rcGroup && rcGroup.key === M.NO_RELATIONSHIPS_GROUP;
	store.setLens(M.INITIAL_LENS);

	store.setLens({ grouping: 'provenance' });
	const vmProv = store.getViewModel();
	const provGroup = vmProv.groups.find((g) => g.nodeIds.includes(zeroId));
	const inNoRelProv = !!provGroup && provGroup.key === M.NO_RELATIONSHIPS_GROUP;
	store.setLens(M.INITIAL_LENS);

	const label = store.getViewModel().nodeLabels.get(zeroId);

	ok('GV07', 'the zero-row kb_gaps node is a complete record: present at density 1, thinned like any node at density 5 while the GAP SET is never thinned (its id still in coverageOrigin at the "ledger-only" VALUE), no integrity mismatch alarm, its own single-node group under grouping=document, membership of the "no relationships" group under BOTH edge-derived dimensions (relation-category, provenance), and a labelled "no recorded relationships"',
		!!zero && zero.kind === 'source-artifact' && zero.degree === 0
		&& atDensity1 && !atDensity5 && inGapSet5 && inOrigin5 && originValue5 === 'ledger-only'
		&& noMismatchAlarm
		&& singleGroup
		&& inNoRelRC && inNoRelProv
		&& label === zero.name + ' — no recorded relationships',
		'd1=' + atDensity1 + ' d5=' + atDensity5 + ' gapSet@d5=' + inGapSet5 + ' origin=' + originValue5
		+ ' integrity=' + model.integrity.status + ' group=' + JSON.stringify(zeroGroup)
		+ ' rcGroup=' + (rcGroup ? rcGroup.key : null) + ' provGroup=' + (provGroup ? provGroup.key : null));
}

// ===========================================================================
// GV08 -- every rendered copy of coverage-predicate.mjs under profiles/ is
// byte-identical to the canonical file
// ===========================================================================
{
	const canonicalPath = path.join(repoRoot, 'canonical/aid/scripts/graph/coverage-predicate.mjs');
	const canonicalBytes = fs.readFileSync(canonicalPath);
	const profilesDir = path.join(repoRoot, 'profiles');
	const found = [];
	if (fs.existsSync(profilesDir)) {
		for (const profile of fs.readdirSync(profilesDir)) {
			const walk = (dir) => {
				for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
					const p = path.join(dir, entry.name);
					if (entry.isDirectory()) walk(p);
					else if (entry.name === 'coverage-predicate.mjs') found.push(p);
				}
			};
			const profileDir = path.join(profilesDir, profile);
			if (fs.statSync(profileDir).isDirectory()) walk(profileDir);
		}
	}
	const mismatched = found.filter((p) => !fs.readFileSync(p).equals(canonicalBytes));
	ok('GV08', 'every rendered copy of coverage-predicate.mjs under profiles/ is byte-identical to the canonical file',
		found.length > 0 && mismatched.length === 0,
		found.length + ' copies found' + (mismatched.length ? ', mismatched: ' + mismatched.join(',') : ''));
}

// ===========================================================================
// GV09 -- a header off by one column, in each direction, fails with both
// headers quoted
// ===========================================================================
{
	const nineCol = M.HEADER_LITERAL.replace(' | Observation |', ' |');
	const elevenCol = M.HEADER_LITERAL.replace('| Observation |', '| Observation | Extra |');
	const oneRow = [rowLine(FX.FIXTURE_ROWS[3])]; // a plain document<->source-artifact row

	function loadFails(header) {
		try {
			M.parseRelationships(buildFile({ header, rows: oneRow, gaps: [] }));
			return { threw: false };
		} catch (e) {
			return { threw: e instanceof M.GraphLoadError, detail: e.detail };
		}
	}
	const nine = loadFails(nineCol);
	const eleven = loadFails(elevenCol);
	ok('GV09', 'a nine-column and an eleven-column header each fail the load, both the expected and the actual header quoted in the error detail',
		nine.threw && eleven.threw
		&& nine.detail && nine.detail.expected === M.HEADER_LITERAL && nine.detail.actual === nineCol
		&& eleven.detail && eleven.detail.expected === M.HEADER_LITERAL && eleven.detail.actual === elevenCol,
		'nine=' + JSON.stringify(nine.detail) + ' eleven=' + JSON.stringify(eleven.detail));
}

// ===========================================================================
// GV10 -- a `## Coverage notes` pipe table changes NOTHING about the graph:
// same row count, same visibleNodes/visibleEdges/edgeFold/emphasis maps when
// the notes are replaced wholesale
// ===========================================================================
{
	const rows = FX.FIXTURE_ROWS.map(rowLine);
	const gaps = FX.LEDGER_IDS.map((id) => ({ id, name: id }));
	const notesA = '\n## Coverage notes\n\n### Node kinds\n\n| Kind | Carrier convention | Status | Nodes |\n'
		+ '|------|--------------------|--------|-------|\n| document | x | present | 3 |\n';
	// A DIFFERENT notes section: different row count, an extra pipe table, extra
	// prose -- everything FR-9a's D2d reader is scoped to ignore.
	const notesB = '\n## Coverage notes\n\nSome free text a future run might add.\n\n'
		+ '### Node kinds\n\n| Kind | Carrier convention | Status | Nodes |\n|------|--------------------|--------|-------|\n'
		+ '| document | y | absent | 999 |\n| concept | z | absent | 0 |\n\n'
		+ '| An | Unrelated | Table |\n|----|-----------|-------|\n| a | b | c |\n';

	const modelA = M.parseRelationships(buildFile({ rows, gaps, notes: notesA }));
	const modelB = M.parseRelationships(buildFile({ rows, gaps, notes: notesB }));
	const storeA = M.createStore(modelA, M.INITIAL_LENS);
	const storeB = M.createStore(modelB, M.INITIAL_LENS);
	const vmA = storeA.getViewModel();
	const vmB = storeB.getViewModel();

	const sameRowCount = modelA.rowCount === modelB.rowCount && modelA.rowCount === FX.FIXTURE_ROWS.length;
	const sameNodes = same(ids(vmA.visibleNodes.map((n) => n.id)), ids(vmB.visibleNodes.map((n) => n.id)));
	const sameEdges = same(ids(vmA.visibleEdges.map((e) => e.key)), ids(vmB.visibleEdges.map((e) => e.key)));
	const sameFold = same(Array.from(vmA.edgeFold.entries()).sort(), Array.from(vmB.edgeFold.entries()).sort());
	const sameEmphasis = same(Array.from(vmA.nodeEmphasis.entries()).sort(), Array.from(vmB.nodeEmphasis.entries()).sort());
	// "EVERY emphasis map", plural: the ViewModel carries a separate edgeEmphasis
	// map alongside nodeEmphasis (graph-model.js:1656-1660, 1723), and a defect
	// that let Coverage-notes content leak into EDGE classification specifically
	// would pass every check above undetected without this second comparison.
	const sameEdgeEmphasis = same(Array.from(vmA.edgeEmphasis.entries()).sort(), Array.from(vmB.edgeEmphasis.entries()).sort());
	ok('GV10', 'a fixture whose Coverage notes section is replaced wholesale (different rows, an extra pipe table, extra prose) yields the SAME pre-notes row count and the same visibleNodes/visibleEdges/edgeFold/EVERY emphasis map (nodeEmphasis AND edgeEmphasis)',
		sameRowCount && sameNodes && sameEdges && sameFold && sameEmphasis && sameEdgeEmphasis,
		'rowCount ' + modelA.rowCount + '==' + modelB.rowCount + ' edgeEmphasisSame=' + sameEdgeEmphasis);
}

// ===========================================================================
// GV11 -- an escaped pipe inside a fact display name parses to ten cells with
// the pipe restored
// ===========================================================================
{
	const pipeName = 'alpha.md \\u00a7 anchor \\| with a literal pipe';
	const row = '| int:src/reader.mjs | source-artifact | src/reader.mjs | kb:alpha.md#fact:pipe | fact | ' + pipeName + ' | cited-as-evidence-by | cites-as-evidence | declared |   |';
	const model = M.parseRelationships(buildFile({ rows: [row], gaps: [] }));
	const fact = Array.from(model.nodes.values()).find((n) => n.kind === 'fact');
	ok('GV11', 'a row carrying an escaped pipe inside a fact display name parses to ten cells with the pipe restored to a literal |',
		model.rowCount === 1 && !!fact && fact.name.indexOf('|') !== -1 && fact.name.indexOf('\\|') === -1,
		fact ? fact.name : '(no fact node)');
}

// ===========================================================================
// GV12 -- the Kind enum is exercised at its prefix boundary: image+ext PASSES,
// image+kb FAILS, a non-image kind spelled with the wrong prefix FAILS, and the
// decisive kind-not-prefix colour/glyph split is cross-checked
// ===========================================================================
{
	const passRow = '| ext:gv12-pic | image | gv12-pic | kb:alpha.md | document | alpha.md | illustrates | illustrated-by | declared |   |';
	const failImageKb = '| kb:gv12-pic | image | gv12-pic | kb:alpha.md | document | alpha.md | illustrates | illustrated-by | declared |   |';
	const failArtifactKb = '| kb:gv12-thing | source-artifact | gv12-thing | kb:alpha.md | document | alpha.md | documented-by | documents | declared |   |';

	let passOk = false;
	try { M.parseRelationships(buildFile({ rows: [passRow], gaps: [] })); passOk = true; } catch (e) { passOk = false; }
	let imageKbThrew = false;
	try { M.parseRelationships(buildFile({ rows: [failImageKb], gaps: [] })); } catch (e) { imageKbThrew = e instanceof M.GraphLoadError; }
	let artifactKbThrew = false;
	try { M.parseRelationships(buildFile({ rows: [failArtifactKb], gaps: [] })); } catch (e) { artifactKbThrew = e instanceof M.GraphLoadError; }

	const distinctEncoding = M.KIND_ENCODING['web-page'].colourToken !== M.KIND_ENCODING['image'].colourToken
		&& M.KIND_ENCODING['web-page'].glyph !== M.KIND_ENCODING['image'].glyph;

	ok('GV12', '`image`+`ext:` passes, `image`+`kb:` fails, a `source-artifact` spelled with `kb:` fails (the general prefix/Kind agreement check, D1c check 4), and the closed encoding table gives `web-page` and `image` distinct colour tokens and glyphs',
		passOk && imageKbThrew && artifactKbThrew && distinctEncoding,
		'pass=' + passOk + ' imageKb=' + imageKbThrew + ' artifactKb=' + artifactKbThrew);
	note('GV12 the DECISIVE half of AC-S3 -- two ext: ids of different kinds receiving different node encodings, which no '
		+ 'id-deriving implementation can pass -- is already run by GT20-GT23 in graph-view-model.mjs over the shared fixture\'s '
		+ 'PREFIX_ORACLE; it is cross-referenced here via the static KIND_ENCODING table rather than re-run a second time.');
}

// ===========================================================================
// GV14 -- the (colour, line-style) pairs are pairwise distinct across the
// fourteen categories, and at most eight distinct colour tokens are used
// ===========================================================================
{
	const entries = Object.entries(M.CATEGORY_ENCODING);
	const pairKeys = entries.map(([, e]) => e.colourToken + '::' + e.lineStyle);
	const distinctPairs = new Set(pairKeys).size === pairKeys.length;
	const colourCount = new Set(entries.map(([, e]) => e.colourToken)).size;
	ok('GV14', 'over the fourteen categories the (colour, line-style) pairs are pairwise distinct (no colour holds two categories with the same line style), and at most eight distinct colour tokens are used',
		entries.length === 14 && distinctPairs && colourCount <= 8 && colourCount > 0,
		entries.length + ' categories, ' + colourCount + ' colours, pairs distinct=' + distinctPairs);
}

// ===========================================================================
// GV15 -- no preset patch touches the filters namespace, and applying every
// preset after setting a filter leaves that filter untouched
// ===========================================================================
{
	const noFilterKeyInPresets = Object.values(M.PRESETS).every((p) => !Object.keys(p).some((k) => k.indexOf('filters.') === 0));
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	store.setLens({ 'filters.categories': ['structure'] });
	let composed = true;
	for (const preset of Object.keys(M.PRESETS)) {
		store.applyPreset(preset);
		if (!same(store.getLens()['filters.categories'], ['structure'])) composed = false;
		store.setLens({ 'filters.categories': ['structure'] });
	}
	ok('GV15', 'for each preset, keys(PRESETS[p]) contains no filters.* key, and applying each preset after setting a single-category filter leaves filters.categories unchanged',
		noFilterKeyInPresets && composed && Object.keys(M.PRESETS).length === 4);
}

// ===========================================================================
// GV18 -- openTarget for every kind, incl. a fact href with NO fragment, a
// concept resolved by the provenance fallback, and the external-sources target
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const factTarget = store.openTarget('kb:alpha.md#fact:renderer-choice');
	const sectionTarget = store.openTarget('kb:alpha.md#overview');
	const docTarget = store.openTarget('kb:alpha.md');
	const conceptTarget = store.openTarget('kb:concept:graph-view');
	const webTarget = store.openTarget('ext:mdn-webgl');
	const artifactTarget = store.openTarget('int:src/reader.mjs');
	const imageIntTarget = store.openTarget('int:docs/media/table-view.png');
	const imageExtTarget = store.openTarget('ext:wcag-contrast-figure');

	// --- The two D7b sub-clauses GV18 skipped, over a dedicated fixture -------
	// (a) the DEFINING-DOCUMENT (@doc) route: an id qualified by a document is
	// resolved from the id ALONE, consulting no edge at all -- so this is
	// decisive against an implementation that always falls through to the
	// provenance search.
	// The node's ONLY edge points to a DIFFERENT document (other-doc.md) than the
	// one its @-qualifier names (zeta.md) -- deliberately, so the @doc route and
	// what the provenance-fallback search would have computed DISAGREE. That
	// disagreement is what makes this fixture decisive: an implementation that
	// (incorrectly) fell through to the edge search regardless of the @-qualifier
	// would answer './other-doc.md', not './zeta.md'.
	const docRouteModel = M.parseRelationships(buildFile({
		rows: ['| kb:other-doc.md | document | other-doc.md | kb:concept:widget@zeta.md | concept | widget | defines | defined-by | declared |   |'],
		gaps: [],
	}));
	const docRouteStore = M.createStore(docRouteModel, M.INITIAL_LENS);
	const docRouteTarget = docRouteStore.openTarget('kb:concept:widget@zeta.md');

	// (b) the fallback's OWN TIE-BREAK: two candidate documents at the SAME
	// provenance rank. `kb:zulu.md` is written FIRST in table-row order and
	// `kb:yankee.md` second, so a "first surviving edge wins" implementation
	// (no real tie-break) would answer zulu.md -- the wrong, non-alphabetical
	// document -- while the declared tie-break (ascending document path) must
	// answer yankee.md. The two orderings disagree, which is what makes this
	// fixture decisive rather than accidentally passing either way.
	const tieModel = M.parseRelationships(buildFile({
		rows: [
			'| kb:zulu.md | document | zulu.md | kb:concept:tiebreak-thing | concept | tiebreak thing | related-concept | related-concept | declared |   |',
			'| kb:yankee.md | document | yankee.md | kb:concept:tiebreak-thing | concept | tiebreak thing | related-concept | related-concept | declared |   |',
		],
		gaps: [],
	}));
	const tieStore = M.createStore(tieModel, M.INITIAL_LENS);
	const tieTarget = tieStore.openTarget('kb:concept:tiebreak-thing');

	ok('GV18', 'openTarget resolves the D7b href for document/section/fact/concept/source-artifact/image(both sides)/web-page, with a FACT href carrying NO fragment, a web-page/external-image target resolving to ./external-sources.md, a concept\'s @doc qualifier resolving from the id alone, and the fallback\'s own tie-break over two equal-rank candidate documents resolving to the alphabetically-first one',
		factTarget === './alpha.md'
		&& sectionTarget.indexOf('./alpha.md#') === 0
		&& docTarget === './alpha.md'
		&& conceptTarget === './alpha.md'
		&& webTarget.indexOf('./external-sources.md') === 0
		&& artifactTarget === '../../src/reader.mjs'
		&& imageIntTarget === '../../docs/media/table-view.png'
		&& imageExtTarget.indexOf('./external-sources.md') === 0
		&& docRouteTarget === './zeta.md'
		&& tieTarget === './yankee.md',
		JSON.stringify({ factTarget, sectionTarget, docTarget, conceptTarget, webTarget, artifactTarget, imageIntTarget, imageExtTarget, docRouteTarget, tieTarget }));
}

// ===========================================================================
// GV20 -- nodeShortLabels is stable across a filter change and a lens change;
// nodeLabels is never the shortened form
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const subject = 'int:src/reader.mjs';
	const before = model.nodes.get(subject).shortLabel;
	store.setLens({ 'filters.categories': ['structure'] });
	const afterFilter = store.getViewModel().nodeShortLabels.get(subject) || model.nodes.get(subject).shortLabel;
	store.setLens(M.INITIAL_LENS);
	store.applyPreset('coverage');
	const afterLens = store.getViewModel().nodeShortLabels.get(subject) || model.nodes.get(subject).shortLabel;
	store.setLens(M.INITIAL_LENS);

	const factId = 'kb:alpha.md#fact:renderer-choice';
	const vm = store.getViewModel();
	const neverShortened = vm.nodeLabels.get(factId) === FX.LONG_FACT_NAME && vm.nodeShortLabels.get(factId) !== vm.nodeLabels.get(factId)
		&& vm.nodeShortLabels.get(factId).length < vm.nodeLabels.get(factId).length;

	// --- The two label-collision sub-clauses GV20 skipped, over a dedicated
	// colliding-basename fixture (never in the shared FX fixture, per assignment).
	// `ellipsiseLike` is a LOCAL re-implementation of the file's own documented
	// middle-ellipsise algorithm (graph-model.js's `ellipsise`, keep=budget-1,
	// head=ceil(keep/2), tail=keep-head) -- used ONLY to prove the PRECONDITION
	// (that the two names really do collide at the initial LABEL_BUDGET) holds,
	// never to decide the actual assertion, which reads only the real model's
	// `shortLabel`.
	function ellipsiseLike(text, budget) {
		if (text.length <= budget) return text;
		if (budget <= 1) return '…';
		const keep = budget - 1;
		const head = Math.ceil(keep / 2);
		const tail = keep - head;
		return text.slice(0, head) + '…' + (tail > 0 ? text.slice(text.length - tail) : '');
	}
	// (a) EQUAL BUDGETED FORMS, distinct full names: two 50-char concept names
	// sharing the same first 20 and last 20 characters (so they collide at
	// LABEL_BUDGET=32's head(16)/tail(15) window) but differing at position 25,
	// inside every widened window up to budget 48 and only exposed once the
	// budget widens all the way to their full 50-character length. Resolving to
	// DISTINCT labels therefore proves the widening machinery ran, not that the
	// two names never collided.
	const head20 = 'A'.repeat(20);
	const tail20 = 'B'.repeat(20);
	const nameWidenA = head20 + 'aaaaaaaaaa' + tail20;
	const nameWidenB = head20 + 'aaaaaXaaaa' + tail20;
	// (b) EQUAL FULL NAMES: two distinct ids sharing one literal name, which no
	// amount of widening can ever distinguish, so the file's own rule resolves
	// each to its id instead.
	const dupName = 'Exact Duplicate Name';
	const collisionModel = M.parseRelationships(buildFile({
		rows: [
			'| kb:doc-widen.md | document | doc-widen.md | kb:concept:widen-a | concept | ' + nameWidenA + ' | related-concept | related-concept | declared |   |',
			'| kb:doc-widen.md | document | doc-widen.md | kb:concept:widen-b | concept | ' + nameWidenB + ' | related-concept | related-concept | declared |   |',
			'| kb:doc-dup.md | document | doc-dup.md | kb:concept:dup-a | concept | ' + dupName + ' | related-concept | related-concept | declared |   |',
			'| kb:doc-dup.md | document | doc-dup.md | kb:concept:dup-b | concept | ' + dupName + ' | related-concept | related-concept | declared |   |',
		],
		gaps: [],
	}));
	const widenA = collisionModel.nodes.get('kb:concept:widen-a');
	const widenB = collisionModel.nodes.get('kb:concept:widen-b');
	const dupA = collisionModel.nodes.get('kb:concept:dup-a');
	const dupB = collisionModel.nodes.get('kb:concept:dup-b');
	const widenPreconditionCollides = ellipsiseLike(nameWidenA, M.LABEL_BUDGET) === ellipsiseLike(nameWidenB, M.LABEL_BUDGET);
	// Distinct labels AND NEITHER is its own id: the terminal id-fallback (proven
	// separately by dupResolvesToIds below) would ALSO yield two distinct labels
	// for two DIFFERENT ids, which would make this check pass even if widening
	// itself were disabled -- so ruling out the id-fallback route is what makes
	// this sub-clause test the WIDENING mechanism specifically, not merely "some
	// mechanism resolved it".
	const widenResolvesDistinct = !!widenA && !!widenB && widenA.shortLabel !== widenB.shortLabel
		&& widenA.shortLabel !== widenA.id && widenB.shortLabel !== widenB.id;
	const dupResolvesToIds = !!dupA && !!dupB && dupA.shortLabel === dupA.id && dupB.shortLabel === dupB.id;

	ok('GV20', 'nodeShortLabels is stable across a filter change and a lens change, nodeLabels is never the shortened form for a name past the label budget, two nodes with EQUAL BUDGETED forms (colliding at LABEL_BUDGET) resolve to DISTINCT labels via widening, and two nodes with EQUAL FULL names resolve to their ids',
		before === afterFilter && before === afterLens && neverShortened
		&& widenPreconditionCollides && widenResolvesDistinct
		&& dupResolvesToIds,
		'before=' + before + ' afterFilter=' + afterFilter + ' afterLens=' + afterLens
		+ ' widenCollidesAt32=' + widenPreconditionCollides + ' widenDistinct=' + widenResolvesDistinct
		+ ' dupToIds=' + dupResolvesToIds);
}

// ===========================================================================
// GV21 -- the unbacked-fact / kb-unbacked domain split is KIND-keyed, not
// prefix-keyed: an in-repo image does not back a document, and a section is in
// neither signal
// ===========================================================================
{
	const rows = [
		'| kb:delta.md | document | delta.md | kb:delta.md#overview | section | delta.md § Overview | has-part | part-of | declared |   |',
		'| kb:delta.md | document | delta.md | kb:delta.md#fact:orphan | fact | delta.md § an unbacked fact | has-part | part-of | declared |   |',
		'| int:docs/media/gv21-diagram.png | image | docs/media/gv21-diagram.png | kb:delta.md | document | delta.md | illustrates | illustrated-by | declared |   |',
	];
	const model = M.parseRelationships(buildFile({ rows, gaps: [] }));
	const store = M.createStore(model, M.INITIAL_LENS);
	store.applyPreset('coverage');
	const vm = store.getViewModel();

	const deltaIsUnbacked = vm.coverageGaps.kbUnbacked.includes('kb:delta.md')
		&& vm.nodeEmphasis.get('kb:delta.md') === 'kb-unbacked';
	const factIsUnbackedFact = model.integrity.unbackedFacts.includes('kb:delta.md#fact:orphan')
		&& vm.nodeEmphasis.get('kb:delta.md#fact:orphan') !== 'kb-unbacked'
		&& vm.nodeEmphasis.get('kb:delta.md#fact:orphan') !== 'artifact-undocumented';
	const sectionInNeither = !vm.coverageGaps.kbUnbacked.includes('kb:delta.md#overview')
		&& !model.integrity.unbackedFacts.includes('kb:delta.md#overview')
		&& vm.nodeEmphasis.get('kb:delta.md#overview') !== 'kb-unbacked'
		&& vm.nodeEmphasis.get('kb:delta.md#overview') !== 'artifact-undocumented';

	ok('GV21', 'a document whose only incident edge reaches an in-repo IMAGE is in kb-unbacked (kind-keyed, not prefix-keyed); an unbacked fact reaches integrity.unbackedFacts and no coverage emphasis class; a section with no such edge is in neither signal',
		deltaIsUnbacked && factIsUnbackedFact && sectionInNeither,
		'delta=' + vm.nodeEmphasis.get('kb:delta.md') + ' fact=' + vm.nodeEmphasis.get('kb:delta.md#fact:orphan') + ' section=' + vm.nodeEmphasis.get('kb:delta.md#overview'));
	note('GV21 this is the decisive case named in the SPEC: a PREFIX-keyed kb-unbacked test (treating any `int:` neighbour '
		+ 'as backing) would have wrongly EXCLUDED kb:delta.md from kb-unbacked here, because docs/media/gv21-diagram.png is '
		+ '`int:`-prefixed. The KIND-keyed test used here (Kind === source-artifact only) correctly includes it.');
}

// ===========================================================================
// GV23 -- runtime prerequisites, incl. a working WebGL context, are stated in
// the generated footer AND in the run's console summary
// ===========================================================================
{
	const skeletonPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-skeleton.html');
	const skeleton = fs.readFileSync(skeletonPath, 'utf8');
	const footerHasWebGL = /working WebGL context is required/.test(skeleton);
	const footerNamesTableFallback = /relationship table remains fully[\s\S]{0,20}usable/i.test(skeleton);

	const renderScript = path.join(repoRoot, 'canonical/aid/scripts/graph/render-graph-view.sh');
	const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gv23-'));
	const fixtureFile = path.join(tmp, 'relationships.md');
	const renderedHtmlPath = path.join(tmp, 'graph.html');
	fs.writeFileSync(fixtureFile, FX.FIXTURE);
	let consoleOut = '';
	try {
		consoleOut = execFileSync('bash', [renderScript, '--relationships', fixtureFile, '--output', renderedHtmlPath,
			'--src', path.join(tmp, 'graph-src'), '--project-name', 'GV23', '--generation-date', '2026-01-01'],
			{ encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
	} catch (e) {
		consoleOut = (e.stdout || '') + (e.stderr || '');
	}
	// Read the REAL rendered page's network disclosure BEFORE the tmp dir is
	// removed. The static skeleton has no such sentence to grep -- it is filled
	// in only at render time, from the {{PREREQUISITES}} placeholder computed in
	// build-graph-src.mjs:233-250 (task-031 moved this off the old :192-194
	// ternary onto the single-authoring-site fact array) -- so the skeleton was
	// the wrong subject for this question; the real generated graph.html is the
	// right one.
	const renderedHtml = fs.existsSync(renderedHtmlPath) ? fs.readFileSync(renderedHtmlPath, 'utf8') : '';
	const renderedHasNetworkDisclosure = /No network access is required and none is made\./.test(renderedHtml);
	fs.rmSync(tmp, { recursive: true, force: true });
	const consoleHasWebGL = /WebGL/.test(consoleOut);

	note('GV23a the REAL rendered graph.html DOES carry the network-access disclosure ("No network access is required '
		+ 'and none is made."), injected via the {{PREREQUISITES}} placeholder computed in build-graph-src.mjs:233-250 -- '
		+ 'verified above by reading THIS block\'s own end-to-end render (found=' + renderedHasNetworkDisclosure + '). '
		+ 'The static graph-skeleton.html necessarily lacks the literal word "network", because that sentence is a '
		+ 'render-time substitution, not a missing disclosure; grepping the skeleton was the wrong target for this '
		+ 'question and is not attempted here.');

	ok('GV23a', 'the generated graph.html footer names a working WebGL context as a runtime prerequisite, explicitly, with the table view stated as usable without one, AND the REAL rendered page (not the static skeleton) discloses network access explicitly',
		footerHasWebGL && footerNamesTableFallback && renderedHasNetworkDisclosure,
		'webgl=' + footerHasWebGL + ' fallback=' + footerNamesTableFallback + ' network=' + renderedHasNetworkDisclosure);
	ok('GV23b', 'the run\'s OWN console summary also states the runtime prerequisites, WebGL among them',
		consoleHasWebGL,
		'console output: ' + (consoleOut.trim().slice(0, 200) || '(empty)'));
	if (!consoleHasWebGL) {
		note('GV23b is a REAL FINDING, not a suite defect: render-graph-view.sh prints no summary line at all on success '
			+ '(verified by reading the script -- its only echo statements are on the --help and node-missing error paths). '
			+ 'AC-6/GV23 name the console summary as a second, independent carrier of the runtime prerequisites; today only '
			+ 'the footer (GV23a) carries them. This is production work outside a TEST task\'s authority to fix -- routed here '
			+ 'as a finding for a follow-up DEV task, the same way GH03 routed its own defect to feature-011.');
	}
}

// ===========================================================================
// GV25 -- INITIAL_LENS is stated TOTAL over all fourteen fields, and every
// preset differs from it on at least one key the preset sets
// ===========================================================================
{
	const expectedKeys = ['preset', 'grouping', 'expandedGroups', 'density', 'filters.kinds', 'filters.categories',
		'filters.provenance', 'filters.showOrphans', 'filters.text', 'focus.nodeId', 'focus.depth', 'emphasis', 'zoom', 'sort'];
	const total = M.LENS_KEYS.length === 14 && expectedKeys.every((k) => M.LENS_KEYS.includes(k))
		&& expectedKeys.every((k) => Object.prototype.hasOwnProperty.call(M.INITIAL_LENS, k));
	// The three enumerable filter axes, checked by VALUE against their own full
	// domain -- never merely their KEY presence (`total` above already covers
	// presence). A regression that narrowed any one of them to a proper subset
	// of its domain must fail here.
	const kindsTotal = same(ids(M.INITIAL_LENS['filters.kinds']), ids(Object.keys(M.KIND_ENCODING)));
	const categoriesTotal = same(ids(M.INITIAL_LENS['filters.categories']), ids(M.distinctCategories()));
	const provenanceTotal = same(ids(M.INITIAL_LENS['filters.provenance']), ids(M.PROVENANCE_VALUES));
	const shapeOk = M.INITIAL_LENS.preset === null && M.INITIAL_LENS.grouping === 'none'
		&& same(M.INITIAL_LENS.expandedGroups, []) && M.INITIAL_LENS.density === 1
		&& kindsTotal && categoriesTotal && provenanceTotal
		&& M.INITIAL_LENS['filters.text'] === '' && M.INITIAL_LENS['filters.showOrphans'] === true
		&& M.INITIAL_LENS.emphasis === 'none' && M.INITIAL_LENS['focus.nodeId'] === null && M.INITIAL_LENS['focus.depth'] === 1
		&& same(M.INITIAL_LENS.zoom, { scale: 1, panX: 0, panY: 0 }) && same(M.INITIAL_LENS.sort, { column: 'row', direction: 'asc' });
	let noneIsPrivileged = true;
	for (const preset of Object.keys(M.PRESETS)) {
		const patch = M.PRESETS[preset];
		const differs = Object.keys(patch).some((k) => !same(patch[k], M.INITIAL_LENS[k]));
		if (!differs) noneIsPrivileged = false;
	}
	ok('GV25', 'INITIAL_LENS states all fourteen LensState fields (total, not merely correct where checked), the three enumerable filter axes each admitting their WHOLE domain by VALUE, and each of the four presets differs from it on at least one key the preset sets, so no preset is privileged as the default',
		total && shapeOk && noneIsPrivileged && Object.keys(M.PRESETS).length === 4,
		'kindsTotal=' + kindsTotal + ' categoriesTotal=' + categoriesTotal + ' provenanceTotal=' + provenanceTotal);
}

// ===========================================================================
// GV26 -- relation category is a real grouping dimension, not only a filter
// axis: the control's domain includes it, the select is built from that same
// domain (greppable), and project() partitions groups by category under it
// ===========================================================================
{
	const controlsPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-controls.js');
	const controlsSrc = fs.readFileSync(controlsPath, 'utf8');
	const selectBuiltFromDomain = /GROUPING_VALUES\.map\(/.test(controlsSrc)
		&& /el\('select', \{ id: 'grouping'/.test(controlsSrc);

	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	store.setLens({ grouping: 'relation-category' });
	const vm = store.getViewModel();
	const nonEmptyGroups = vm.groups.length > 0;
	const keysAreCategories = vm.groups.every((g) => model.categories.includes(g.key) || g.key === M.NO_RELATIONSHIPS_GROUP);

	// The grouping's own rule (graph-model.js's edge-derived-dimension branch):
	// a node's group is its FIRST surviving edge's category, in table row order;
	// a node touching no surviving edge goes to the dedicated NO_RELATIONSHIPS
	// group. Recomputed here from vm.visibleEdges rather than asserted as a
	// literal, so a change to the tie-break fails this rather than passing it.
	const expectedGroupOf = new Map();
	for (const edge of vm.visibleEdges) {
		for (const id of [edge.sourceId, edge.targetId]) {
			if (!expectedGroupOf.has(id)) expectedGroupOf.set(id, edge.category);
		}
	}
	const partitionsByCategory = vm.visibleNodes.every((node) => {
		const expectedKey = expectedGroupOf.has(node.id) ? expectedGroupOf.get(node.id) : M.NO_RELATIONSHIPS_GROUP;
		const group = vm.groups.find((g) => g.nodeIds.includes(node.id));
		return !!group && group.key === expectedKey;
	});
	const totalPartitioned = vm.groups.reduce((n, g) => n + g.nodeIds.length, 0) === vm.visibleNodes.length;
	store.setLens(M.INITIAL_LENS);

	ok('GV26', '`relation-category` is in GROUPING_VALUES\'s domain and the grouping `<select>` is built from that exact domain (greppable); projecting with it partitions every visible node into the group its first surviving edge\'s category names, over GraphModel.categories',
		M.GROUPING_VALUES.includes('relation-category') && selectBuiltFromDomain
		&& nonEmptyGroups && keysAreCategories && partitionsByCategory && totalPartitioned);
}

// ===========================================================================
// GV27 -- the two system preferences are reachable through the store and are
// NOT projected: a flip changes neither `revision` nor any `subscribe` result
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS, { reducedMotion: false, forcedColours: false });
	const p0 = store.getPreferences();

	let subscribeFired = false;
	const unsub = store.subscribe(() => { subscribeFired = true; });
	const revisionBefore = store.getViewModel().revision;

	let prefEvents = [];
	const unsubPref = store.subscribePreferences((p) => { prefEvents.push(p); });

	store.setPreferences({ reducedMotion: true });
	const afterA = store.getPreferences();
	store.setPreferences({ forcedColours: true });
	const afterB = store.getPreferences();
	store.setPreferences({ reducedMotion: false, forcedColours: false });
	const afterC = store.getPreferences();

	const revisionAfter = store.getViewModel().revision;
	unsub(); unsubPref();

	const reachable = p0.reducedMotion === false && p0.forcedColours === false;
	// getPreferences() ITSELF -- not only the subscribePreferences callback --
	// must follow each flip in turn: a constant answer here would fail this
	// (SPEC.md:1821, "each value following ... set true and false in turn"),
	// distinct from `notified` below which checks the LISTENER'S copy.
	const getPreferencesFollows = afterA.reducedMotion === true && afterA.forcedColours === false
		&& afterB.reducedMotion === true && afterB.forcedColours === true
		&& afterC.reducedMotion === false && afterC.forcedColours === false;
	const notified = prefEvents.length === 3
		&& prefEvents[0].reducedMotion === true && prefEvents[1].forcedColours === true
		&& prefEvents[2].reducedMotion === false && prefEvents[2].forcedColours === false;
	const notProjected = revisionBefore === revisionAfter && !subscribeFired;

	// The same LensState projects non-empty, identical visibleNodes/nodeEmphasis/
	// nodeEncoding/counts under both values of both preferences -- proven by the
	// fact that project() itself takes no preferences argument at all, and by
	// requiring the ViewModel snapshot to be unaffected by the flips above.
	const vmAfter = store.getViewModel();
	const stableViewModel = vmAfter.visibleNodes.length > 0
		&& same(ids(vmAfter.visibleNodes.map((n) => n.id)), ids(model.nodes.size ? Array.from(model.nodes.keys()).filter((id) => vmAfter.visibleNodes.some((n) => n.id === id)) : []));

	ok('GV27', 'getPreferences() returns both keys and ITSELF follows each flip true/false/true across three writes (not only the subscribePreferences listener\'s copy); subscribePreferences receives all three pairs; the flips leave `revision` unchanged and notify NO `subscribe` listener; the ViewModel is stable across the flips',
		reachable && getPreferencesFollows && notified && notProjected && stableViewModel,
		'events=' + JSON.stringify(prefEvents) + ' getPrefs=' + JSON.stringify({ afterA, afterB, afterC }) + ' rev ' + revisionBefore + '->' + revisionAfter + ' subscribeFired=' + subscribeFired);
	note('GV27 "createStore at its default pair with no DOM still projects" is proven by construction: this whole GV suite '
		+ 'runs createStore() headless, with no document, throughout.');
}

// ===========================================================================
// Verdict
// ===========================================================================
const failed = results.filter((r) => r.kind === 'FAIL');
process.exit(failed.length === 0 ? 0 : 1);
