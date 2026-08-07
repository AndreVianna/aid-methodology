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
//
// GV13, GV16, GV28 -- authored in THIS pass (task-014 STAGE 3), each wiring in
// the second subject the earlier passes deferred:
//   GV13 reads canonical/aid/scripts/summarize/contrast-check.mjs and graph-css.css
//     from disk (the page cannot) and drives contrast-check.mjs --profile graph
//     over a REAL assembled fixture (component-css.css + graph-css.css, the same
//     order build-graph-src.mjs:262-263 substitutes). It found a REAL, VERIFIED
//     defect in contrast-check.mjs itself while doing so -- see the GV13 block's
//     own NOTE -- which is production work in a file this test task does not own
//     and is routed rather than muted, the same way GV23b routed its own gap.
//   GV16 reads canonical/aid/templates/graph/relationship-schema.yml from disk and
//     builds two SCRATCH bundles via in-process string patches (never a subprocess,
//     never graph-view-mutate.mjs, which is outside this task's two files) to prove
//     the coverage/lockstep checks bite: one grows the category vocabulary by one
//     entry, one drops the manifest's provenance-axis loop entirely.
//   GV28 builds its own small connected fixture (never FX.FIXTURE, whose one
//     coverage-gap node is degree-0 and therefore UNREACHABLE by any focus ball --
//     see D4/D6c below) so a live selection elsewhere in the graph still keeps
//     every other gap id inside the focus ball at focus.depth: 2.

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

/**
 * Build a SCRATCH module bundle -- the same four-file manifest order the page
 * itself concatenates in -- with ONE string-patch applied to exactly one file,
 * loaded via a plain in-process `import()` of a freshly written temp file
 * (never a subprocess, never graph-view-mutate.mjs, which is outside this
 * task's two owned files, and never the source tree under canonical/, S5).
 * Used by GV16 and GV28 to prove their own checks are decisive against a
 * mutated SUBJECT rather than merely descriptive of the unmutated one.
 *
 * @param {{file: 'predicate'|'model'|'controls'|'table', apply: (src: string) => string}} patch
 */
async function buildScratchBundle(patch) {
	const files = {
		predicate: fs.readFileSync(path.join(repoRoot, 'canonical/aid/scripts/graph/coverage-predicate.mjs'), 'utf8'),
		model: fs.readFileSync(path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-model.js'), 'utf8'),
		controls: fs.readFileSync(path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-controls.js'), 'utf8'),
		table: fs.readFileSync(path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-table.js'), 'utf8'),
	};
	const key = patch.file;
	const before = files[key];
	const after = patch.apply(before);
	if (after === before) throw new Error('scratch-bundle mutation pattern not found in ' + key);
	files[key] = after;
	const bundle = [files.predicate, files.model, files.controls, files.table].join('\n');
	const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gv-scratch-'));
	const scratchBundlePath = path.join(tmp, 'bundle.mjs');
	fs.writeFileSync(scratchBundlePath, bundle);
	const mod = await import(pathToFileURL(scratchBundlePath).href);
	fs.rmSync(tmp, { recursive: true, force: true });
	return mod;
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
// GV07 -- the zero-row artifact: its own single-node group under
// grouping=document, its membership of the "no relationships" group under
// grouping=provenance, and its label suffix
//
// Density's own thinning clause and the relation-category grouping clause
// were removed here on the owner's 2026-08-07 control changes: the density
// axis is gone entirely (nothing replaces its per-level thinning behaviour --
// GV07 never needed a substitute, since the "gap set is never thinned"
// property this used to demonstrate is a load-time, lens-independent fact
// already covered unconditionally by GT12/GT12b in graph-view-model.mjs), and
// `relation-category` no longer exists in GROUPING_VALUES (GV26 asserts its
// absence). What is UNCHANGED and kept below: the provenance dimension is
// still edge-derived and a degree-0 node still falls back to
// NO_RELATIONSHIPS_GROUP under it, exactly as before.
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const zeroId = FX.ZERO_ROW_NODE;
	const zero = model.nodes.get(zeroId);

	// "no mismatch alarm" -- the fixture's kb_gaps and its recomputed set agree
	// everywhere, so the whole-model integrity status is 'verified', never
	// 'mismatch'. This is the load-time check GV07's own criterion names; GV06
	// is the sibling case that deliberately breaks it.
	const noMismatchAlarm = model.integrity.status === 'verified';

	store.setLens({ grouping: 'document' });
	const vmg = store.getViewModel();
	const zeroGroup = vmg.groups.find((g) => g.nodeIds.includes(zeroId));
	const singleGroup = !!zeroGroup && zeroGroup.nodeIds.length === 1 && zeroGroup.foldable === 0 && !vmg.foldedInto.has(zeroId);
	store.setLens(M.INITIAL_LENS);

	// Membership of the "no relationships" group under the ONE EDGE-DERIVED
	// grouping dimension left, provenance -- distinct from the KIND-derived
	// `document` dimension checked above, where the zero-row node gets its OWN
	// single-node group instead. A node with no surviving edge has no
	// provenance to key on, so this dimension must fall back to the dedicated
	// NO_RELATIONSHIPS_GROUP bucket.
	store.setLens({ grouping: 'provenance' });
	const vmProv = store.getViewModel();
	const provGroup = vmProv.groups.find((g) => g.nodeIds.includes(zeroId));
	const inNoRelProv = !!provGroup && provGroup.key === M.NO_RELATIONSHIPS_GROUP;
	store.setLens(M.INITIAL_LENS);

	const label = store.getViewModel().nodeLabels.get(zeroId);

	ok('GV07', 'the zero-row kb_gaps node is a complete record: no integrity mismatch alarm, its own single-node group under grouping=document, membership of the "no relationships" group under grouping=provenance, and a labelled "no recorded relationships"',
		!!zero && zero.kind === 'source-artifact' && zero.degree === 0
		&& noMismatchAlarm
		&& singleGroup
		&& inNoRelProv
		&& label === zero.name + ' — no recorded relationships',
		'integrity=' + model.integrity.status + ' group=' + JSON.stringify(zeroGroup)
		+ ' provGroup=' + (provGroup ? provGroup.key : null));
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
// GV13 -- the graph palette is COMPLETE, CHECKABLE and LITERAL-FREE (AC-S4).
// Two second subjects, both read from disk because the page cannot read either:
// graph-css.css (feature-007's own declaration) and contrast-check.mjs (the
// checker feature-011 parameterised, --profile kb-summary|graph). This block
// asserts the FEATURE-SIDE property -- the declaration is complete and every
// declared token is FOUND by a run of the checker -- and deliberately does NOT
// re-assert the checker's OWN extraction/pairing behaviour, which
// test-validator-profiles.sh already covers over synthetic fixtures.
// ===========================================================================
{
	const cssPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-css.css');
	const cssText = fs.readFileSync(cssPath, 'utf8');
	const componentCssText = fs.readFileSync(
		path.join(repoRoot, 'canonical/aid/templates/knowledge-summary/component-css.css'), 'utf8');
	const contrastCheckPath = path.join(repoRoot, 'canonical/aid/scripts/summarize/contrast-check.mjs');

	/** The flat `<selector> { ... }` block's own body, exactly as contrast-check.mjs
	 *  itself extracts one (`[^}]*`, no nested rule) -- never a second copy of the
	 *  selector text typed as a literal elsewhere in this file. */
	function block(text, selector) {
		const re = new RegExp(selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*\\{([^}]*)\\}');
		const m = re.exec(text);
		return m ? m[1] : null;
	}
	const lightBlock = block(cssText, 'html:root');
	const darkBlock = block(cssText, 'html[data-theme="dark"]:root');

	/** Every custom-property NAME declared in a block body, under a given
	 *  character class -- `a-z-` reproduces the checker's own extraction
	 *  charset; `A-Za-z0-9_-` is broader, so a name the narrow charset would
	 *  silently drop still surfaces here and trips the size comparison below. */
	function tokenNames(body, charset) {
		const names = [];
		const re = new RegExp('--([' + charset + ']+)\\s*:', 'g');
		let m;
		while ((m = re.exec(body)) !== null) names.push(m[1]);
		return names;
	}
	const lightNarrow = tokenNames(lightBlock || '', 'a-z-');
	const darkNarrow = tokenNames(darkBlock || '', 'a-z-');
	const lightBroad = tokenNames(lightBlock || '', 'A-Za-z0-9_-');
	const darkBroad = tokenNames(darkBlock || '', 'A-Za-z0-9_-');
	const charsetOk = lightBlock !== null && darkBlock !== null
		&& lightBroad.length === lightNarrow.length && darkBroad.length === darkNarrow.length
		&& lightNarrow.every((n) => /^[a-z-]+$/.test(n)) && darkNarrow.every((n) => /^[a-z-]+$/.test(n));
	const bothBlocksSame = same(ids(lightNarrow), ids(darkNarrow)) && lightNarrow.length > 0;
	const allAreGkGc = lightNarrow.every((n) => n.indexOf('gk-') === 0 || n.indexOf('gc-') === 0);

	/** Assemble the page the way `assemble.sh`/build-graph-src.mjs would (its own
	 *  INLINE_CSS substitution, build-graph-src.mjs:262-263): component-css.css
	 *  THEN graph-css.css, nothing else -- no real graph.html exists yet
	 *  (feature-010's to assemble), so this is the synthetic stand-in every block
	 *  in this suite that needs one builds for itself. */
	function assembledFixture(graphCssText) {
		return '<!doctype html><html><head><style>\n' + componentCssText + '\n\n' + graphCssText + '\n</style></head><body></body></html>';
	}
	function runContrastCheck(graphCssText) {
		const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gv13-'));
		const f = path.join(tmp, 'graph.html');
		fs.writeFileSync(f, assembledFixture(graphCssText));
		let out = '';
		try {
			out = execFileSync('node', [contrastCheckPath, f, '--profile', 'graph'],
				{ encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
		} catch (e) { out = (e.stdout || '') + (e.stderr || ''); }
		fs.rmSync(tmp, { recursive: true, force: true });
		return out;
	}
	/** Every one of `tokens` was FOUND -- its pair label printed -- under BOTH
	 *  theme sections and BOTH backgrounds. This reads presence only, never the
	 *  pass/fail glyph or the ratio: whether the checker's own contrast ARITHMETIC
	 *  is correct is that suite's question, not this one's (see the NOTE below). */
	function foundEverywhere(out, tokens) {
		const split = out.indexOf('[dark theme]');
		const lightSection = split === -1 ? out : out.slice(0, split);
		const darkSection = split === -1 ? '' : out.slice(split);
		return tokens.length > 0 && tokens.every((t) => lightSection.indexOf('--' + t + ' on --bg') !== -1
			&& lightSection.indexOf('--' + t + ' on --bg-elev') !== -1
			&& darkSection.indexOf('--' + t + ' on --bg') !== -1
			&& darkSection.indexOf('--' + t + ' on --bg-elev') !== -1);
	}

	const realOut = runContrastCheck(cssText);
	const realFound = foundEverywhere(realOut, lightNarrow);

	// --- Non-vacuity for the "found" check: a token the FILE declares that the
	// checker's own hardcoded GRAPH_KIND_TOKENS/GRAPH_CATEGORY_TOKENS array does
	// NOT know about is exactly the drift this check exists to catch. A scratch
	// copy of graph-css.css, never the source tree (S5), adds one. ---
	const gv13LightMarker = '--gk-document: #1E3A8A;';
	const gv13DarkMarker = '--gk-document: #A8C7FF;';
	if (cssText.indexOf(gv13LightMarker) === -1 || cssText.indexOf(gv13DarkMarker) === -1) {
		throw new Error('GV13 mutation pattern not found in graph-css.css -- update the marker');
	}
	const mutatedCss = cssText
		.replace(gv13LightMarker, gv13LightMarker + '\n\t--gk-extra-kind: #123456;')
		.replace(gv13DarkMarker, gv13DarkMarker + '\n\t--gk-extra-kind: #654321;');
	const mutatedOut = runContrastCheck(mutatedCss);
	const mutationCaught = !foundEverywhere(mutatedOut, lightNarrow.concat(['gk-extra-kind']));
	const mutationDoesNotBreakTheRealTokens = foundEverywhere(mutatedOut, lightNarrow);

	// --- AC-S4's other half: no colour literal in the drawing code ----------
	const canvasPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-canvas.js');
	const modelPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-model.js');
	const canvasSrc = fs.readFileSync(canvasPath, 'utf8');
	const modelSrc = fs.readFileSync(modelPath, 'utf8');
	// A real rgb()/rgba() CALL needs a digit (or a decimal point) right after the
	// open paren; graph-canvas.js's own comment mentioning the STRING "rgb()" (in
	// gcColourToNumber's doc comment) has neither, and must NOT trip this --
	// proven by literalCheckBites below, which appends a REAL call and requires
	// the same regex to catch it.
	function noLiteral(src) {
		return !/#[0-9a-fA-F]{3,8}\b/.test(src) && !/rgba?\(\s*[\d.]/.test(src);
	}
	const canvasClean = noLiteral(canvasSrc);
	const modelClean = noLiteral(modelSrc);
	const mutatedCanvasHex = canvasSrc + "\nconst gv13PoisonHex = '#1E3A8A';\n";
	const mutatedCanvasRgb = canvasSrc + "\nconst gv13PoisonRgb = 'rgb(30, 58, 138)';\n";
	const literalCheckBites = !noLiteral(mutatedCanvasHex) && !noLiteral(mutatedCanvasRgb);

	ok('GV13', 'every --gk-*/--gc-* token graph-css.css declares is present in BOTH theme blocks, matches the checker\'s own [a-z-]+ charset exactly (no declared property falls outside it), is FOUND by a run of the parameterised contrast-check.mjs over the REAL assembled page (component-css.css + graph-css.css), a token the file adds ahead of the checker\'s own hardcoded list is caught rather than silently passing, and no hex or rgb( literal appears in graph-canvas.js or graph-model.js',
		// The COUNT is asserted, not just the per-token quantifiers, and it is the count
		// that moved: 15 -> 16 when task-035 added `--gk-project` for the project hub's
		// star. It has to stay a literal rather than be derived from the file, because
		// every `every(...)` above is trivially TRUE over a shorter list -- a palette that
		// silently lost a token would satisfy all of them.
		charsetOk && bothBlocksSame && allAreGkGc && lightNarrow.length === 16
		&& realFound && mutationCaught && mutationDoesNotBreakTheRealTokens
		&& canvasClean && modelClean && literalCheckBites,
		'tokens=' + lightNarrow.length + ' bothBlocksSame=' + bothBlocksSame + ' realFound=' + realFound
		+ ' mutationCaught=' + mutationCaught + ' canvasClean=' + canvasClean + ' modelClean=' + modelClean);

	note('GV13 found a REAL, VERIFIED defect in contrast-check.mjs itself, which is NOT this test task\'s to fix '
		+ '(the file is outside this task\'s two owned files): its plain `:root` fallback selector TEXT-MATCHES as a '
		+ 'SUBSTRING of `html:root {` (the graph light block\'s own selector). In the real assembled page, an earlier '
		+ '`:root { color-scheme: ... }` block (component-css.css, empty of custom properties) forces the extractor '
		+ 'past its first match, and the NEXT match it accepts is the GRAPH block rather than the intended `:root, '
		+ 'html[data-theme="light"]` chrome block. That pollutes `light` with the graph tokens\' LIGHT values, which '
		+ 'then survive the dark merge\'s `{...graphDarkRaw, ...dark}` spread (graphDarkRaw first, the already-'
		+ 'polluted `dark` second) and overwrite the correct dark values -- so contrast-check.mjs --profile graph '
		+ 'reports the LIGHT gk-*/gc-* colours checked against the DARK background for all sixteen tokens, and the '
		+ 'real page\'s dark-theme graph contrast is UNVERIFIED by the tool, not merely undertested. Manually '
		+ 'verified against the real values: --gk-document (#A8C7FF) on the dark theme\'s --bg (#0B1220) is 10.9:1, '
		+ 'comfortably over the 3:1 target -- so this is a checker defect, not a palette defect. GV13 does not '
		+ 'assert the pass/fail VERDICT for exactly this reason, and reads only whether each token is FOUND; the '
		+ 'ratio bug is production work in a file this test task does not own, routed here as a finding for a '
		+ 'follow-up the same way GV23b routed its own gap.');
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
// GV16 -- CONTROL_MANIFEST's coverage, and the doc<->code lockstep GV04 uses,
// over KIND_ENCODING and PROVENANCE_VALUES against relationship-schema.yml.
// The published contract names an array called CONTROL_MANIFEST; the actual
// export is `buildControlManifest(graphModel)`, the BUILDER -- see its own doc
// comment in graph-controls.js ("the authored name is this builder and the
// built array is what... a test asserts over"). This block calls it, never
// re-authors its shape.
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const manifest = M.buildControlManifest(model);

	const byAxis = (axis) => manifest.filter((e) => e.axis === axis).map((e) => e.value);
	const coversExactly = (values, domain) => same(ids(values), ids(domain)) && values.length === domain.length;

	const coversCategories = coversExactly(byAxis('filters.categories'), model.categories);
	const coversKinds = coversExactly(byAxis('filters.kinds'), Object.keys(M.KIND_ENCODING));
	const coversProvenance = coversExactly(byAxis('filters.provenance'), M.PROVENANCE_VALUES);
	const coversPresets = coversExactly(byAxis('preset'), Object.keys(M.PRESETS));

	// --- The doc<->code lockstep: KIND_ENCODING's keys and PROVENANCE_VALUES
	// are authored FROM relationship-schema.yml's `kinds:` and `provenance:`
	// lists (graph-model.js:1-79's own doc comment) -- read from disk here
	// because the page never can (D3, D8 assertion 1). Order matters too: both
	// constants' own comments state they follow the schema artifact's order. ---
	const schemaPath = path.join(repoRoot, 'canonical/aid/templates/graph/relationship-schema.yml');
	const schemaText = fs.readFileSync(schemaPath, 'utf8');
	const schemaKinds = Array.from(schemaText.matchAll(/^\s*-\s*"([a-z-]+)\|[^"]*"\s*$/gm)).map((m) => m[1]);
	const provMatch = schemaText.match(/^provenance:\s*\[([^\]]*)\]/m);
	const schemaProvenance = provMatch ? provMatch[1].split(',').map((s) => s.trim()) : [];

	const kindEncodingMatchesSchema = schemaKinds.length > 0 && same(Object.keys(M.KIND_ENCODING), schemaKinds);
	const provenanceMatchesSchema = schemaProvenance.length > 0 && same(M.PROVENANCE_VALUES.slice(), schemaProvenance);

	// --- Non-vacuity, half 1: the lockstep really discriminates. A one-entry
	// mutation of a COPY of the parsed schema arrays (never the file) must flip
	// each comparison, proving `same()` over these two pairs is not vacuously
	// true regardless of content. ---
	const kindsMutated = schemaKinds.slice(0, -1); // drop the last kind
	const provMutated = schemaProvenance.concat(['gv16-extra']); // add a value
	const lockstepBites = !same(Object.keys(M.KIND_ENCODING), kindsMutated)
		&& !same(M.PROVENANCE_VALUES.slice(), provMutated);

	// --- Non-vacuity, half 2: "a fixture vocabulary with an extra category
	// fails until the axis grows." Grow RELATION_CATEGORY by one entry in a
	// scratch bundle and require the manifest to cover the new category with
	// NO other edit -- proving the category axis is read from the model at
	// call time and is not a hardcoded list. ---
	const growthMarker = "'cross-referenced-by': 'navigation',\n});";
	const M16grow = await buildScratchBundle({
		file: 'predicate',
		apply: (src) => src.replace(growthMarker, "'cross-referenced-by': 'navigation',\n\t'gv16-extra-relation': 'gv16-extra-category',\n});"),
	});
	const model16grow = M16grow.parseRelationships(FX.FIXTURE);
	const manifest16grow = M16grow.buildControlManifest(model16grow);
	const growthCovered = manifest16grow.some((e) => e.axis === 'filters.categories' && e.value === 'gv16-extra-category')
		&& model16grow.categories.includes('gv16-extra-category');

	// --- Non-vacuity, half 3: mutate the SUBJECT (buildControlManifest itself)
	// to drop the provenance-axis loop entirely, and require the SAME coverage
	// check used above to go red against it -- proving the check is decisive,
	// not merely descriptive. ---
	const dropMarker = "\tfor (const provenance of PROVENANCE_VALUES) {\n"
		+ "\t\tentries.push(Object.freeze({ id: 'filter-provenance-' + slug(provenance), requirement: 'FR-14a', axis: 'filters.provenance', value: provenance }));\n"
		+ '\t}\n';
	const M16drop = await buildScratchBundle({
		file: 'controls',
		apply: (src) => src.replace(dropMarker, ''),
	});
	const model16drop = M16drop.parseRelationships(FX.FIXTURE);
	const manifest16drop = M16drop.buildControlManifest(model16drop);
	const dropDetected = !coversExactly(manifest16drop.filter((e) => e.axis === 'filters.provenance').map((e) => e.value), M16drop.PROVENANCE_VALUES);

	ok('GV16', 'CONTROL_MANIFEST (buildControlManifest\'s built array) covers every category of the fixture vocabulary, every value of keys(KIND_ENCODING), every value of PROVENANCE_VALUES and every key of PRESETS; those two constants equal relationship-schema.yml\'s kinds: and provenance: lists (order included); a category the vocabulary grows by one is covered with no further edit (the manifest reads the model, not a literal); and a manifest with the provenance-axis loop removed is caught by the SAME coverage check',
		coversCategories && coversKinds && coversProvenance && coversPresets
		&& kindEncodingMatchesSchema && provenanceMatchesSchema && lockstepBites
		&& growthCovered && dropDetected,
		'categories=' + coversCategories + ' kinds=' + coversKinds + ' provenance=' + coversProvenance
		+ ' presets=' + coversPresets + ' schemaKinds=' + schemaKinds.length + ' schemaProv=' + schemaProvenance.join(',')
		+ ' growthCovered=' + growthCovered + ' dropDetected=' + dropDetected);
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
// GV19 -- every `section` fragment equals feature-003 D2a-1's slug algorithm
// applied to the heading, and where a document's own `## Contents` links that
// heading, the two fragments are identical.
//
// task-014 STAGE 3's own header comment classified this id as needing "a real
// DOM" and deferred it to graph-view-dom.mjs (tech-debt W5-9). That premise did
// not survive re-validation: D2a-1's authority is `rel_slug_heading`, a bash
// function in feature-003's relationship-schema.sh (harvest-declared.sh:1124),
// and a `## Contents` link is plain markdown text -- no page, no browser and no
// jsdom is involved in binding the two. This block drives the REAL function as
// a subprocess (never a JS re-implementation of D2a-1) and compares it against
// a self-authored fixture document (S5), never against an on-disk KB doc whose
// headings could drift independently of this test.
// ===========================================================================
{
	const schemaSh = path.join(repoRoot, 'canonical/aid/scripts/graph/relationship-schema.sh');
	/** The REAL rel_slug_heading, invoked exactly as harvest-declared.sh invokes
	 *  it (`LC_ALL=C`, sourced, called positionally) -- never a second, JS-side
	 *  copy of D2a-1's five steps. */
	function slugHeading(text) {
		return execFileSync('bash',
			['-c', 'set -euo pipefail; export LC_ALL=C; source "$1"; rel_slug_heading "$2"', 'gv19', schemaSh, text],
			{ encoding: 'utf8' });
	}

	// Two headings exercising D2a-1's own documented quirks -- an ampersand
	// (deleted, not replaced, so it leaves a double hyphen behind) and an arrow
	// (three literal hyphens, D2a-1's own no-run-collapsing rule) -- the same
	// shape as the real on-disk instance the SPEC's changelog cites
	// (architecture.md's "Build & Distribute Architecture ... canonical ->
	// profiles -> packages"), reproduced here as an authored fixture (S5) rather
	// than read off that file, so a future edit to that document's headings
	// cannot perturb this suite.
	const headingA = 'Build & Ship (canonical -> profiles)';
	const headingB = 'Overview';
	const slugA = slugHeading(headingA);
	const slugB = slugHeading(headingB);

	const fixtureDoc = '# Title\n\n## Contents\n\n- [' + headingA + '](#' + slugA + ')\n- [' + headingB + '](#' + slugB + ')\n\n'
		+ '## ' + headingA + '\n\nBody.\n\n## ' + headingB + '\n\nBody.\n';
	/** The Contents link's OWN fragment, read back out of the fixture text by a
	 *  plain regex keyed on the LITERAL heading label -- never on the slug this
	 *  block already computed -- so a defect that made the two diverge would be
	 *  caught rather than a slug compared against itself. */
	function contentsFragmentFor(label) {
		const re = new RegExp('\\[' + label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\]\\(#([^)]+)\\)');
		const m = re.exec(fixtureDoc);
		return m ? m[1] : null;
	}
	const contentsA = contentsFragmentFor(headingA);
	const contentsB = contentsFragmentFor(headingB);

	// A section node id embeds the slug verbatim (D7b's `kb:<doc>#<heading-slug>`
	// grammar) and openTarget's `section` case is a plain passthrough of that
	// fragment (graph-model.js:1314-1317) -- exercised here over a REAL model
	// rather than asserted as a string operation this file performs itself.
	const sectionId = 'kb:gv19-doc.md#' + slugA;
	const row = '| kb:gv19-doc.md | document | gv19-doc.md | ' + sectionId + ' | section | ' + headingA
		+ ' | has-part | part-of | declared |   |';
	const gv19Model = M.parseRelationships(buildFile({ rows: [row], gaps: [] }));
	const gv19Store = M.createStore(gv19Model, M.INITIAL_LENS);
	const openTargetForSection = gv19Store.openTarget(sectionId);

	// Non-vacuity: a heading mutated by one character must change the slug
	// D2a-1 computes, so `slugA === contentsA` is not vacuously true regardless
	// of content -- the REAL subprocess is shown to discriminate, not merely
	// echo its input.
	const slugMutated = slugHeading(headingA + 'x');

	ok('GV19', 'a heading exercising D2a-1\'s ampersand-deletion and non-collapsing-hyphen rules, and a plain heading, both slugify -- via a REAL subprocess of feature-003\'s own rel_slug_heading -- to the SAME fragment the fixture document\'s own ## Contents link to each heading uses; the section node id built from that slug resolves through openTarget to the identical fragment; and a one-character heading mutation changes the computed slug',
		slugA.length > 0 && slugB.length > 0 && slugA === contentsA && slugB === contentsB
		&& openTargetForSection === './gv19-doc.md#' + slugA
		&& slugMutated !== slugA,
		'slugA=' + slugA + ' contentsA=' + contentsA + ' slugB=' + slugB + ' contentsB=' + contentsB
		+ ' openTarget=' + openTargetForSection + ' mutated=' + slugMutated);
	note('GV19 needs no DOM and no jsdom: the fragment obligation is a text-to-text comparison against a REAL '
		+ 'subprocess of feature-003\'s own rel_slug_heading (relationship-schema.sh), over a self-authored fixture '
		+ '(S5). task-014 STAGE 3\'s "needs a real DOM" classification for this id is corrected by this block -- see '
		+ 'the task hand-off.');
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
// GV22a -- the Overview fold, both directions (D6c, FR-13, D8, AC-8), at the
// GraphModel/ViewModel level. This id's one truly DOM-shaped clause -- "exactly
// one focusable data-group-toggle element exists per group whose foldable is
// non-zero ... before and after an expansion, and none for any other group" --
// is asserted separately as GV22b in graph-view-dom.mjs, over a real page;
// task-014 STAGE 3's "needs a real DOM" classification covered this id
// wholesale, which over-scoped it -- every OTHER clause here is a plain
// ViewModel/GraphModel property, asserted headless like every other GV id in
// this file. See the task-014 hand-off for the correction.
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	// The `document` dimension's group KEY is the document's bare NAME (e.g.
	// 'alpha.md'), not its `kb:`-prefixed node id -- confirmed by reading the
	// live `groups[].key` values rather than assumed, after an earlier draft of
	// this block silently proved nothing by adding the WRONG key to
	// `expandedGroups` (a real premise this task-014 pass caught in itself, not
	// only in W5-9's own premise).
	const groupKeyAlpha = 'alpha.md';
	const headId = 'kb:alpha.md';
	const memberSection = 'kb:alpha.md#overview';
	const memberFact = 'kb:alpha.md#fact:renderer-choice';

	store.setLens({ grouping: 'document' });
	const vm = store.getViewModel();
	const group = vm.groups.find((g) => g.key === groupKeyAlpha);
	const membersNotVisible = !vm.visibleNodes.some((n) => n.id === memberSection) && !vm.visibleNodes.some((n) => n.id === memberFact);
	const foldedIntoOk = vm.foldedInto.get(memberSection) === headId && vm.foldedInto.get(memberFact) === headId;
	const foldableOk = !!group && group.foldable === 2;
	const hiddenNodesCoversFold = vm.counts.hiddenNodes >= 2;
	const expandedFalse = !!group && group.expanded === false;

	// Row 9 (alpha.md -has-part-> #overview) resolves both ends to the SAME
	// head, so its edgeFold is the literal 'collapsed' while the ROW ITSELF
	// stays in visibleEdges with its own id/key/row untouched (graph-model.js's
	// own comment: "neither surface draws or lists it... two rows... stay two
	// entries" -- the row is retained, only its fold state changes).
	const collapsedEdge = vm.visibleEdges.find((e) => e.row === 9);
	const collapsedOk = !!collapsedEdge && vm.edgeFold.get(collapsedEdge.key) === 'collapsed'
		&& collapsedEdge.sourceId === headId && collapsedEdge.targetId === memberSection && collapsedEdge.key.indexOf('has-part') !== -1;
	const hiddenEdgesCoversFold = vm.counts.hiddenEdges >= 1;

	// --- Expansion, and its reversal -----------------------------------------
	store.setLens({ expandedGroups: [groupKeyAlpha] });
	const vmExpanded = store.getViewModel();
	const groupExpanded = vmExpanded.groups.find((g) => g.key === groupKeyAlpha);
	const restored = vmExpanded.visibleNodes.some((n) => n.id === memberSection) && vmExpanded.visibleNodes.some((n) => n.id === memberFact);
	const foldableUnchanged = !!groupExpanded && groupExpanded.foldable === 2;
	const expandedTrueOk = !!groupExpanded && groupExpanded.expanded === true;
	const foldedIntoEmptiedForGroup = !vmExpanded.foldedInto.has(memberSection) && !vmExpanded.foldedInto.has(memberFact);

	store.setLens({ expandedGroups: [] });
	const vmRefolded = store.getViewModel();
	const refolded = !vmRefolded.visibleNodes.some((n) => n.id === memberSection) && !vmRefolded.visibleNodes.some((n) => n.id === memberFact);

	// --- Focus resolves through the fold: a folded section as focus.nodeId ---
	store.setLens(M.INITIAL_LENS);
	store.setLens({ grouping: 'document', 'focus.nodeId': memberSection });
	const vmFocus = store.getViewModel();
	const focusResolvedAway = !vmFocus.visibleNodes.some((n) => n.id === memberSection);
	const headCarriesFocus = vmFocus.nodeEmphasis.get(headId) === 'focus';

	// --- Counts are total over the WHOLE model at this lens ------------------
	store.setLens(M.INITIAL_LENS);
	store.setLens({ grouping: 'document' });
	const vmCounts = store.getViewModel();
	const countsNodesTotal = vmCounts.counts.nodes + vmCounts.counts.hiddenNodes === model.nodes.size;
	const countsEdgesTotal = vmCounts.counts.edges + vmCounts.counts.hiddenEdges === model.rowCount;

	// --- No fold at all under the three OTHER dimensions ---------------------
	// (`relation-category` dropped from this list on 2026-08-07 -- it no
	// longer exists in GROUPING_VALUES, see GV26 -- leaving 'document' plus
	// three others rather than four.)
	let noFoldElsewhere = true;
	const elsewhereDetail = [];
	for (const otherGrouping of ['none', 'node-kind', 'provenance']) {
		store.setLens(M.INITIAL_LENS);
		store.setLens({ grouping: otherGrouping });
		const vmOther = store.getViewModel();
		const clean = vmOther.foldedInto.size === 0 && vmOther.groups.every((g) => g.foldable === 0);
		if (!clean) noFoldElsewhere = false;
		elsewhereDetail.push(otherGrouping + '=' + clean);
	}
	store.setLens(M.INITIAL_LENS);

	ok('GV22a', 'under grouping=document a folded document\'s section AND fact members are absent from visibleNodes, present in foldedInto mapping to the document, counted in groups[].foldable (2) and in counts.hiddenNodes, with that group\'s expanded false; the has-part row between the document and its folded section keeps its own id/key/row in visibleEdges while its edgeFold reads \'collapsed\', and is counted in counts.hiddenEdges; adding the group\'s key to expandedGroups restores both members, leaves foldable unchanged, sets expanded true and empties the group\'s share of foldedInto, and removing the key folds them again; a folded section held as focus.nodeId stays absent from visibleNodes while its document carries nodeEmphasis \'focus\' instead; counts.nodes+hiddenNodes and counts.edges+hiddenEdges are each total over the WHOLE model; and foldedInto is empty with every foldable 0 under all three other grouping dimensions',
		membersNotVisible && foldedIntoOk && foldableOk && hiddenNodesCoversFold && expandedFalse
		&& collapsedOk && hiddenEdgesCoversFold
		&& restored && foldableUnchanged && expandedTrueOk && foldedIntoEmptiedForGroup
		&& refolded
		&& focusResolvedAway && headCarriesFocus
		&& countsNodesTotal && countsEdgesTotal
		&& noFoldElsewhere,
		'group=' + JSON.stringify(group) + ' collapsedEdge=' + JSON.stringify(collapsedEdge) + ' restored=' + restored
		+ ' refolded=' + refolded + ' focusResolvedAway=' + focusResolvedAway + ' headCarriesFocus=' + headCarriesFocus
		+ ' countsNodesTotal=' + countsNodesTotal + ' countsEdgesTotal=' + countsEdgesTotal + ' elsewhere=' + elsewhereDetail.join(','));
	note('GV22a\'s one DOM-shaped clause -- the data-group-toggle bijection over foldable groups, before and after an '
		+ 'expansion -- is asserted separately as GV22b in graph-view-dom.mjs, over a real page; this block covers '
		+ 'every other clause, headless, needing neither a page nor jsdom.');
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
// GV25 -- INITIAL_LENS is stated TOTAL over all sixteen fields (task-034 added
// `filters.hiddenIds`, the checkbox-hide axis; `density` was removed and
// `spacing`, the layout axis, was added 2026-08-07; task-035 added
// `filters.showHub`, the project hub), and every preset differs from it on at
// least one key the preset sets
// ===========================================================================
{
	const expectedKeys = ['preset', 'grouping', 'expandedGroups', 'spacing', 'filters.kinds', 'filters.categories',
		'filters.provenance', 'filters.showOrphans', 'filters.showHub', 'filters.text', 'filters.hiddenIds',
		'focus.nodeId', 'focus.depth', 'emphasis', 'zoom', 'sort'];
	const total = M.LENS_KEYS.length === 16 && expectedKeys.every((k) => M.LENS_KEYS.includes(k))
		&& expectedKeys.every((k) => Object.prototype.hasOwnProperty.call(M.INITIAL_LENS, k));
	// The three enumerable filter axes, checked by VALUE against their own full
	// domain -- never merely their KEY presence (`total` above already covers
	// presence). A regression that narrowed any one of them to a proper subset
	// of its domain must fail here. `filters.hiddenIds`'s own domain is the
	// EMPTY set at the initial state (nothing is hidden until a reader hides
	// it), so it is asserted directly rather than folded into this triple.
	const kindsTotal = same(ids(M.INITIAL_LENS['filters.kinds']), ids(Object.keys(M.KIND_ENCODING)));
	const categoriesTotal = same(ids(M.INITIAL_LENS['filters.categories']), ids(M.distinctCategories()));
	const provenanceTotal = same(ids(M.INITIAL_LENS['filters.provenance']), ids(M.PROVENANCE_VALUES));
	const hiddenIdsEmpty = same(M.INITIAL_LENS['filters.hiddenIds'], []);
	const shapeOk = M.INITIAL_LENS.preset === null && M.INITIAL_LENS.grouping === 'none'
		&& same(M.INITIAL_LENS.expandedGroups, []) && M.INITIAL_LENS.spacing === 3
		&& kindsTotal && categoriesTotal && provenanceTotal && hiddenIdsEmpty
		&& M.INITIAL_LENS['filters.text'] === '' && M.INITIAL_LENS['filters.showOrphans'] === true
		// task-035. Default ON because with nothing selected the hub is the origin a
		// finite `focus.depth` is measured from -- off, the depth control narrows nothing.
		&& M.INITIAL_LENS['filters.showHub'] === true
		&& M.INITIAL_LENS.emphasis === 'none' && M.INITIAL_LENS['focus.nodeId'] === null && M.INITIAL_LENS['focus.depth'] === null
		&& same(M.INITIAL_LENS.zoom, { scale: 1, panX: 0, panY: 0 }) && same(M.INITIAL_LENS.sort, { column: 'row', direction: 'asc' });
	let noneIsPrivileged = true;
	for (const preset of Object.keys(M.PRESETS)) {
		const patch = M.PRESETS[preset];
		const differs = Object.keys(patch).some((k) => !same(patch[k], M.INITIAL_LENS[k]));
		if (!differs) noneIsPrivileged = false;
	}
	ok('GV25', 'INITIAL_LENS states all sixteen LensState fields (total, not merely correct where checked), the four enumerable filter axes each admitting their initial domain by VALUE, the two boolean filter flags both on, and each of the four presets differs from it on at least one key the preset sets, so no preset is privileged as the default',
		total && shapeOk && noneIsPrivileged && Object.keys(M.PRESETS).length === 4,
		'keys=' + M.LENS_KEYS.length + ' kindsTotal=' + kindsTotal + ' categoriesTotal=' + categoriesTotal
		+ ' provenanceTotal=' + provenanceTotal + ' hiddenIdsEmpty=' + hiddenIdsEmpty
		+ ' showHub=' + M.INITIAL_LENS['filters.showHub']);
}

// ===========================================================================
// GV26 -- INVERTED on the owner's 2026-08-07 finding: `relation-category` is
// REMOVED from GROUPING_VALUES's domain because it grouped NODES by a property
// only RELATIONSHIPS carry -- a node touching several categories resolved,
// arbitrarily, to whichever surviving edge came first in row order. The
// grouping `<select>` is still built from GROUPING_VALUES itself (greppable),
// which is exactly why removing the one value needed no edit to the control
// file to remove the option (graph-controls.js's own comment now says so).
// What used to be this id's own partition proof (a node's group is its first
// surviving edge's category) is gone with the dimension; what stays true and
// is asserted here instead is that each of the four SURVIVING values still
// partitions every visible node into exactly one group -- no id left out, none
// counted twice.
// ===========================================================================
{
	const controlsPath = path.join(repoRoot, 'canonical/aid/templates/knowledge-graph/graph-controls.js');
	const controlsSrc = fs.readFileSync(controlsPath, 'utf8');
	const selectBuiltFromDomain = /GROUPING_VALUES\.map\(/.test(controlsSrc)
		&& /el\('select', \{ id: 'grouping'/.test(controlsSrc);

	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);

	const partitionResults = M.GROUPING_VALUES.map((value) => {
		store.setLens({ grouping: value });
		const vm = store.getViewModel();
		const seen = new Set();
		let noOverlap = true;
		for (const g of vm.groups) {
			for (const id of g.nodeIds) {
				if (seen.has(id)) noOverlap = false;
				seen.add(id);
			}
		}
		const totalPartitioned = vm.groups.reduce((n, g) => n + g.nodeIds.length, 0) === vm.visibleNodes.length;
		const everyNodeCovered = vm.visibleNodes.every((n) => seen.has(n.id));
		store.setLens(M.INITIAL_LENS);
		return { value, ok: noOverlap && totalPartitioned && everyNodeCovered };
	});
	const allPartition = partitionResults.every((r) => r.ok);

	ok('GV26', '`relation-category` is ABSENT from GROUPING_VALUES\'s domain (removed: it grouped nodes by a property only relationships carry, resolved arbitrarily to whichever surviving edge came first); the grouping `<select>` is still built from that exact domain (greppable), so the option disappeared with no control-file edit; and each of the four remaining values (' + M.GROUPING_VALUES.join(', ') + ') still partitions every visible node into exactly one group',
		!M.GROUPING_VALUES.includes('relation-category') && M.GROUPING_VALUES.length === 4
		&& selectBuiltFromDomain && allPartition,
		partitionResults.map((r) => r.value + '=' + r.ok).join(' '));
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
	// A REAL before-snapshot of the four projected channels this block claims are
	// preference-independent. Taken here, ahead of the flips, because the comparison
	// below is only meaningful against a value captured before them.
	const snapshot = (vm) => JSON.stringify({
		nodes: vm.visibleNodes.map((n) => n.id),
		emphasis: Array.from(vm.nodeEmphasis.entries()).sort(),
		encoding: Array.from(vm.nodeEncoding.entries()).map(([k, v]) => [k, v.colourToken, v.glyph]).sort(),
		counts: vm.counts,
	});
	const snapshotBefore = snapshot(store.getViewModel());

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
	// nodeEncoding/counts under both values of both preferences.
	//
	// REWRITTEN 2026-08-07, and the old version is worth recording because it was
	// VACUOUS. It compared `visibleNodes`' ids against "the model's node ids filtered
	// to those present in visibleNodes" -- a tautology, true of any projection
	// whatsoever, and it made no reference to the flips it claimed to be testing.
	// task-035 broke it by accident and that is what exposed it: the project hub is
	// in `visibleNodes` and NOT in `model.nodes`, so the filtered side dropped it and
	// the two sets finally differed. The clause was failing for the one reason it
	// could ever fail, which is not the reason it was written for.
	//
	// It now compares a snapshot taken BEFORE the three flips against one taken
	// after, over all four channels the comment names. That can actually fail -- if
	// any preference ever reached `project()` it would -- which the old form could
	// not.
	const vmAfter = store.getViewModel();
	const stableViewModel = vmAfter.visibleNodes.length > 0
		&& snapshot(vmAfter) === snapshotBefore;

	ok('GV27', 'getPreferences() returns both keys and ITSELF follows each flip true/false/true across three writes (not only the subscribePreferences listener\'s copy); subscribePreferences receives all three pairs; the flips leave `revision` unchanged and notify NO `subscribe` listener; the ViewModel is stable across the flips',
		reachable && getPreferencesFollows && notified && notProjected && stableViewModel,
		'events=' + JSON.stringify(prefEvents) + ' getPrefs=' + JSON.stringify({ afterA, afterB, afterC }) + ' rev ' + revisionBefore + '->' + revisionAfter + ' subscribeFired=' + subscribeFired + ' snapshotStable=' + (snapshot(vmAfter) === snapshotBefore));
	note('GV27 "createStore at its default pair with no DOM still projects" is proven by construction: this whole GV suite '
		+ 'runs createStore() headless, with no document, throughout.');
}

// ===========================================================================
// GV28 -- the five-value nodeEmphasis precedence (D4) and the edge axis's own
// exhaustion (D6f), over BOTH axes and over a fixture built for this block
// specifically -- never FX.FIXTURE, whose one coverage-gap node
// (ZERO_ROW_NODE) has degree 0 and is therefore UNREACHABLE by any focus ball
// (D6c step 5's adjacency has no edge to walk from it), which would make
// "every other gap id keeps its class under a live selection elsewhere"
// untestable with a live focus.nodeId set anywhere but that node itself.
// ===========================================================================
{
	// hub.md is BACKED (edge to hub-src.mjs, a source-artifact, any relation) and
	// carries no gap class of its own -- the "dimmed remainder" control.
	// orphan-doc.md has no incident source-artifact edge at all -- kb-unbacked.
	// hub-src.mjs is covered (documented-by/documents IS coverage-bearing) --
	// the covered artifact, a second "dimmed remainder" control on the OTHER
	// gap class's kind.
	// gap-src.mjs has a row but its relation (mentioned-in/mentions) is NOT
	// coverage-bearing -- artifact-undocumented, and connected (not zero-row),
	// so it stays inside a focus ball centred on orphan-doc.md at depth 2.
	const rows = [
		'| int:gv28-hub-src.mjs | source-artifact | gv28-hub-src.mjs | kb:gv28-hub.md | document | gv28-hub.md | documented-by | documents | declared |   |',
		'| kb:gv28-hub.md | document | gv28-hub.md | kb:gv28-orphan-doc.md | document | gv28-orphan-doc.md | cross-references | cross-referenced-by | declared |   |',
		'| int:gv28-gap-src.mjs | source-artifact | gv28-gap-src.mjs | kb:gv28-hub.md | document | gv28-hub.md | mentioned-in | mentions | declared |   |',
	];
	const model = M.parseRelationships(buildFile({ rows, gaps: [] }));
	const store = M.createStore(model, M.INITIAL_LENS);

	const kbUnbackedId = 'kb:gv28-orphan-doc.md';
	const gapArtifactId = 'int:gv28-gap-src.mjs';
	const dimmedHubId = 'kb:gv28-hub.md';
	const dimmedCoveredArtifactId = 'int:gv28-hub-src.mjs';

	const FIVE = new Set(['normal', 'dimmed', 'kb-unbacked', 'artifact-undocumented', 'focus']);
	function nodeTotalOverFive(vm) {
		return vm.nodeEmphasis.size === vm.visibleNodes.length
			&& vm.visibleNodes.every((n) => vm.nodeEmphasis.has(n.id))
			&& Array.from(vm.nodeEmphasis.values()).every((v) => FIVE.has(v));
	}
	function edgeTotalOverDrawn(vm) {
		const drawnKeys = vm.visibleEdges.filter((e) => vm.edgeFold.get(e.key) !== 'collapsed').map((e) => e.key);
		return drawnKeys.length > 0 && drawnKeys.every((k) => vm.edgeEmphasis.has(k)) && vm.edgeEmphasis.size === drawnKeys.length;
	}

	// --- (a) emphasis: 'coverage', no selection: each gap id carries its OWN
	// gap class, and a node with neither class is 'dimmed' (D4 rule 3's
	// fall-through for the coverage lens, over BOTH kinds a gap class could
	// have applied to). ---
	store.setLens({ emphasis: 'coverage' });
	const vmCov = store.getViewModel();
	const covNoSelectOk = vmCov.nodeEmphasis.get(kbUnbackedId) === 'kb-unbacked'
		&& vmCov.nodeEmphasis.get(gapArtifactId) === 'artifact-undocumented'
		&& vmCov.nodeEmphasis.get(dimmedHubId) === 'dimmed'
		&& vmCov.nodeEmphasis.get(dimmedCoveredArtifactId) === 'dimmed';

	// --- (b) selecting the kb-unbacked gap id (focus.depth: 2, so the ball
	// still reaches every other node in this small connected graph): that id
	// and NO OTHER becomes 'focus'; it stays in coverageGaps.kbUnbacked; the
	// OTHER gap id keeps ITS OWN class; the two non-gap nodes stay 'dimmed' --
	// so the precedence is exercised where a coverage class, 'dimmed' AND
	// 'focus' all apply in the SAME projection, not only where one does. ---
	store.setLens({ 'focus.nodeId': kbUnbackedId, 'focus.depth': 2 });
	const vmSel = store.getViewModel();
	const selectionOk = vmSel.nodeEmphasis.get(kbUnbackedId) === 'focus'
		&& vmSel.coverageGaps.kbUnbacked.includes(kbUnbackedId)
		&& vmSel.nodeEmphasis.get(gapArtifactId) === 'artifact-undocumented'
		&& vmSel.nodeEmphasis.get(dimmedHubId) === 'dimmed'
		&& vmSel.nodeEmphasis.get(dimmedCoveredArtifactId) === 'dimmed'
		&& vmSel.nodeEmphasis.get(kbUnbackedId) !== 'kb-unbacked'
		&& vmSel.nodeEmphasis.get(gapArtifactId) !== 'focus';

	// --- (c) the SAME live selection under 'provenance-chain' and under
	// 'none' likewise yields 'focus' on the selected id -- rule 1 is checked
	// before either mode's own rule, in both directions. ---
	store.setLens({ emphasis: 'provenance-chain' });
	const vmChainSel = store.getViewModel();
	const focusUnderChain = vmChainSel.nodeEmphasis.get(kbUnbackedId) === 'focus';

	store.setLens({ emphasis: 'none' });
	const vmNoneSel = store.getViewModel();
	const focusUnderNone = vmNoneSel.nodeEmphasis.get(kbUnbackedId) === 'focus';

	// --- (d) totality over all four projections: every visibleNodes id has
	// EXACTLY one nodeEmphasis entry and every entry is one of the five. ---
	const totalOk = nodeTotalOverFive(vmCov) && nodeTotalOverFive(vmSel) && nodeTotalOverFive(vmChainSel) && nodeTotalOverFive(vmNoneSel);

	// --- (e) the edge axis, with the SAME live focus.nodeId in each
	// projection: every drawn row is 'chain' or 'dimmed' under
	// 'provenance-chain' (both values actually occurring -- row 2, kb<->kb, is
	// never a chain; rows 1 and 3, int<->kb, always are) and 'normal' under
	// the other two, so no selection invents an edge class and no drawn row is
	// unclassed. ---
	const chainValues = Array.from(vmChainSel.edgeEmphasis.values());
	const edgeChainOk = edgeTotalOverDrawn(vmChainSel)
		&& chainValues.every((v) => v === 'chain' || v === 'dimmed')
		&& chainValues.includes('chain') && chainValues.includes('dimmed');
	const edgeCoverageOk = edgeTotalOverDrawn(vmSel) && Array.from(vmSel.edgeEmphasis.values()).every((v) => v === 'normal');
	const edgeNoneOk = edgeTotalOverDrawn(vmNoneSel) && Array.from(vmNoneSel.edgeEmphasis.values()).every((v) => v === 'normal');

	store.setLens(M.INITIAL_LENS);

	// --- Non-vacuity: mutate the SUBJECT itself -- classifyNode's coverage-mode
	// fall-through, D4 rule 3 -- so a node with neither gap class returns
	// 'normal' instead of 'dimmed', and require the SAME clause (a)/(b) checks
	// used above to go red against it. Scratch bundle, never the source tree
	// (S5), never graph-view-mutate.mjs (outside this task's two files). ---
	const dimmedFallbackMarker = "if (ctx.artifactGapSet.has(node.id)) return 'artifact-undocumented';\n\t\treturn 'dimmed';\n\t}";
	const M28mut = await buildScratchBundle({
		file: 'model',
		apply: (src) => src.replace(dimmedFallbackMarker, "if (ctx.artifactGapSet.has(node.id)) return 'artifact-undocumented';\n\t\treturn 'normal';\n\t}"),
	});
	const model28mut = M28mut.parseRelationships(buildFile({ rows, gaps: [] }));
	const store28mut = M28mut.createStore(model28mut, M28mut.INITIAL_LENS);
	store28mut.setLens({ emphasis: 'coverage' });
	const vmCovMut = store28mut.getViewModel();
	// covNoSelectOk's own condition, recomputed against the mutated subject: the
	// two non-gap nodes are 'normal' under the mutation rather than 'dimmed', so
	// the SAME boolean expression flips.
	const covNoSelectOkMut = vmCovMut.nodeEmphasis.get(kbUnbackedId) === 'kb-unbacked'
		&& vmCovMut.nodeEmphasis.get(gapArtifactId) === 'artifact-undocumented'
		&& vmCovMut.nodeEmphasis.get(dimmedHubId) === 'dimmed'
		&& vmCovMut.nodeEmphasis.get(dimmedCoveredArtifactId) === 'dimmed';
	const mutationBites = !covNoSelectOkMut
		&& vmCovMut.nodeEmphasis.get(dimmedHubId) === 'normal'
		&& vmCovMut.nodeEmphasis.get(dimmedCoveredArtifactId) === 'normal';

	ok('GV28', 'the nodeEmphasis precedence (D4) over a fixture carrying a document in kb-unbacked, a source-artifact in artifact-undocumented, a dimmed remainder on both non-gap kinds, and a chain row alongside a non-chain row: under emphasis: \'coverage\' with no selection each gap id carries its own gap class and the remainder is \'dimmed\'; selecting the kb-unbacked id gives it and no other \'focus\' while it stays in coverageGaps.kbUnbacked and every other id keeps its own class, exercising a coverage class, \'dimmed\' and \'focus\' all in the SAME projection; the same live selection under \'provenance-chain\' and under \'none\' likewise yields \'focus\'; every visibleNodes id has exactly one nodeEmphasis entry and every entry is one of the five values; on the edge axis, with the SAME live focus.nodeId, every drawn row is \'chain\' or \'dimmed\' under \'provenance-chain\' (both values occurring) and \'normal\' under the other two, so no drawn row is ever unclassed; and a mutated classifyNode whose coverage fall-through returns \'normal\' instead of \'dimmed\' is caught by this SAME check',
		covNoSelectOk && selectionOk && focusUnderChain && focusUnderNone && totalOk
		&& edgeChainOk && edgeCoverageOk && edgeNoneOk && mutationBites,
		'covNoSelect=' + covNoSelectOk + ' selection=' + selectionOk + ' chainFocus=' + focusUnderChain
		+ ' noneFocus=' + focusUnderNone + ' total=' + totalOk + ' edgeChain=' + edgeChainOk
		+ ' mutationBites=' + mutationBites
		+ ' edgeCoverage=' + edgeCoverageOk + ' edgeNone=' + edgeNoneOk);
}

// ===========================================================================
// GV30 -- `spacing` (added 2026-08-07, replacing the removed `density` axis)
// changes NO node set. Projecting the SAME fixture at every level 1..5 leaves
// counts.nodes and counts.edges identical -- exactly the property that
// distinguishes it from the degree filter it replaces, and it is
// headless-checkable because `spacing` reaches no projection code at all
// (graph-model.js's own LENS_KEYS comment: "the ONE key here that no
// projection reads").
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const perLevel = [1, 2, 3, 4, 5].map((level) => {
		store.setLens({ spacing: level });
		const vmLevel = store.getViewModel();
		return { level, nodes: vmLevel.counts.nodes, edges: vmLevel.counts.edges };
	});
	store.setLens(M.INITIAL_LENS);
	const allSame = perLevel.every((r) => r.nodes === perLevel[0].nodes && r.edges === perLevel[0].edges);

	ok('GV30', 'projecting the fixture at every spacing level 1..5 leaves counts.nodes and counts.edges IDENTICAL -- spacing changes no node set, only how far apart the drawing rendering lets marks settle',
		allSame && perLevel[0].nodes > 0,
		perLevel.map((r) => r.level + ':' + r.nodes + 'n/' + r.edges + 'e').join(' '));
}

// ===========================================================================
// GV31 -- `focus.depth: null` (the new default, replacing the old
// capped-at-6 `number` input that defaulted to 1) applies NO focus ball at
// all: selecting a node with no depth limit leaves counts.nodes/counts.edges
// EXACTLY equal to the unselected counts, never narrowed to the selected
// node's connected component. The same selection at depth 1 then narrows
// STRICTLY, which is what proves the no-limit case is an absence of
// filtering and not merely "a very large radius" landing on the same answer
// by coincidence.
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	const unselected = store.getViewModel().counts;

	store.setLens({ 'focus.nodeId': 'kb:alpha.md' });
	const noLimit = store.getViewModel().counts;
	const sameAsUnselected = noLimit.nodes === unselected.nodes && noLimit.edges === unselected.edges;

	store.setLens({ 'focus.depth': 1 });
	const depth1 = store.getViewModel().counts;
	const strictlySmaller = depth1.nodes < noLimit.nodes && depth1.edges < noLimit.edges;
	store.setLens(M.INITIAL_LENS);

	ok('GV31', 'selecting a node with focus.depth: null (the default) leaves counts.nodes/counts.edges IDENTICAL to the unselected state -- no ball is applied at all; the same selection at depth 1 is strictly smaller',
		sameAsUnselected && strictlySmaller,
		'unselected=' + unselected.nodes + 'n/' + unselected.edges + 'e noLimit=' + noLimit.nodes + 'n/' + noLimit.edges
		+ 'e depth1=' + depth1.nodes + 'n/' + depth1.edges + 'e');
}

// ===========================================================================
// GV32 -- DEPTH_MAX (exported so no assertion re-types the ceiling as a
// literal) is the clamp a depth ABOVE it collapses to. The fixture's
// reachable component from kb:alpha.md is exhausted at depth 2, well inside
// the ceiling, so a count comparison ALONE cannot tell "clamped to 50" apart
// from "not clamped at all, but still stops at the same component" -- both
// read 11n/12e regardless. The DECISIVE half reads `lensSummary`'s own text
// (`narrate()` reports the CLAMPED depth number, never the raw one): a depth
// requested past the ceiling must be announced as depth DEPTH_MAX, not as the
// raw number the reader asked for.
// ===========================================================================
{
	const model = M.parseRelationships(FX.FIXTURE);
	const store = M.createStore(model, M.INITIAL_LENS);
	store.setLens({ 'focus.nodeId': 'kb:alpha.md', 'focus.depth': M.DEPTH_MAX });
	const atCeiling = store.getViewModel();
	store.setLens({ 'focus.depth': M.DEPTH_MAX + 949 });
	const pastCeiling = store.getViewModel();
	store.setLens(M.INITIAL_LENS);
	const countsClamp = pastCeiling.counts.nodes === atCeiling.counts.nodes && pastCeiling.counts.edges === atCeiling.counts.edges;
	const summaryNamesCeiling = pastCeiling.lensSummary.indexOf('at depth ' + M.DEPTH_MAX) !== -1;
	const summaryDoesNotNameRaw = pastCeiling.lensSummary.indexOf('at depth ' + (M.DEPTH_MAX + 949)) === -1;

	ok('GV32', 'a focus.depth requested past DEPTH_MAX (' + M.DEPTH_MAX + ') clamps to it: counts.nodes/counts.edges at depth ' + (M.DEPTH_MAX + 949) + ' equal those at depth ' + M.DEPTH_MAX + ' itself, AND (the decisive half) lensSummary announces the CLAMPED depth (' + M.DEPTH_MAX + '), never the raw requested one',
		countsClamp && summaryNamesCeiling && summaryDoesNotNameRaw && typeof M.DEPTH_MAX === 'number' && M.DEPTH_MAX > 0,
		'atCeiling=' + atCeiling.counts.nodes + 'n/' + atCeiling.counts.edges + 'e pastCeiling=' + pastCeiling.counts.nodes + 'n/' + pastCeiling.counts.edges
		+ 'e summary="' + pastCeiling.lensSummary + '"');
}

// ===========================================================================
// Verdict
// ===========================================================================
const failed = results.filter((r) => r.kind === 'FAIL');
process.exit(failed.length === 0 ? 0 : 1);
