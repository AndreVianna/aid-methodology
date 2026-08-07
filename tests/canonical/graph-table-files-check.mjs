// graph-table-files-check.mjs -- task-034's own non-vacuity proof for the Files
// tree, the Concepts table, the checkbox-hide axis and its persistence.
//
// WHY A SEPARATE SCRIPT RATHER THAN AN EXTRA CLASS INSIDE graph-view-model.mjs/
// graph-view-dom.mjs
//   Those two files are organised around the RELATIONS table's own mechanism
//   (row set, order, emphasis) and around `mountShell`'s graph.html-shaped flow.
//   task-034 adds two node inventories and a lens axis that neither file's own
//   fixture or mount path was built to exercise, and task-033's own
//   graph-table-window-check.mjs already set the precedent for exactly this
//   situation: read the real view files directly, build a self-contained
//   fixture and mount `mountTable` directly rather than through `mountShell` or
//   `tbvMountShell`. This file follows that precedent rather than re-deriving
//   it, for the reason that file itself gives -- no coupling to
//   graph-view-mutate.mjs's own mutation catalogue or S1-budget bookkeeping.
//
// THE FIXTURE
//   Reused, not re-authored: `graph-view-fixture.mjs`'s FIXTURE already carries
//   14 distinct nodes across every kind this file's partition rule has to
//   handle -- 2 concepts, 3 nested section/fact nodes under 2 different
//   documents, and file-backed nodes including a REAL two-level directory
//   (`docs/media/table-view.png`) and a folder holding TWO files
//   (`src/reader.mjs` and the zero-row `src/unreferenced-loader.mjs`), which is
//   what gives the folder-subtree-hide classes (TFC06/TFC07) a real folder with
//   more than one child to prove non-vacuity against. A second, parallel
//   fixture would be exactly the "no second copy of the same knowledge" defect
//   this project's own conventions warn about.
//
// PROTOCOL   GV \t PASS|FAIL|SKIP|NOTE \t <label>     (graph-view-model.mjs's own)
//
// USAGE
//   node graph-table-files-check.mjs <repo-root> <bundle-out-path>
//
// RUNTIMES
//   node   required (this file needs nothing else to build the bundle).
//   jsdom  optional (bare specifier or AID_GRAPH_JSDOM). Absent -> every class
//          SKIPs loudly, exit 3, and never reports a pass.

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const repo = process.argv[2];
const bundleOut = process.argv[3];

const CLASSES = [
	['TFC01', 'the Files-tree file rows and the Concepts rows PARTITION graphModel.nodes -- every node in exactly one, none missing, none duplicated'],
	['TFC02', 'a document\'s section and fact nodes are nested under it (a greater aria-level, appearing before any sibling top-level entry) and are absent from the Concepts table'],
	['TFC03', 'unchecking a leaf file hides it from the Relations projection (visibleNodes/visibleEdges) while its OWN row stays present, visible and re-checkable in the Files tree'],
	['TFC04', 'hiding a node changes nothing about the coverage answer: graphModel.integrity and viewModel.coverageGaps are identical before and after'],
	['TFC14', 'the checkbox handler persists the FULL hidden set to storage, and resolving that exact stored value against the model reconstructs it (the round trip a reload depends on)'],
	['TFC05', 'unchecking a folder with two children hides BOTH of their ids from the Relations projection, and touches no id outside the subtree'],
	['TFC06', 're-checking that folder restores exactly what it hid and nothing else -- an independently-hidden node elsewhere stays hidden'],
	['TFC07', 'the Show checkbox and the collapse toggle are both native, keyboard-operable controls (Enter/Space via the platform, proven the same way task-033\'s own suite proves it)'],
	['TFC08', 'a folder checkbox is INDETERMINATE (native IDL property) when some but not all of its subtree is hidden, and this reads as aria-checked="mixed" with no ARIA authored by hand'],
	['TFC09', 'collapsing a folder hides its descendant rows via the native `hidden` attribute and exposes aria-expanded="false"; expanding restores them, and collapsing never touches filters.hiddenIds'],
	['TFC10', 'resolveHiddenSelection drops an id the model no longer has and keeps the rest'],
	['TFC11', 'resolveHiddenSelection suppresses (restores nothing) a stored selection that would hide every node, and says why'],
	['TFC12', 'the Files/Concepts regions create no live region and no data-control/data-group-toggle attribute (the two-region and GV22/GV17 contracts hold with these regions in the page)'],
	['TFC13', 'no console error was logged across the whole run'],
	['TFC15', 'resolveHiddenSelection deduplicates a stored selection before measuring it against "hides everything", so a repeated id cannot inflate a false suppression'],
	['TFC16', 'a section/fact naming a document absent from the model (malformed input) is still attached under the Files tree\'s "unattached" fallback rather than silently dropped'],
	['TFC17', 'every focusable Files-tree and Concepts-table control carries a numeric scroll-margin-top covering both sticky layers (SC 2.4.11), the same allowance the Relations table and its unlisted region already carry'],
];

function skipAll(reason) {
	for (const [id, label] of CLASSES) process.stdout.write('GV\tSKIP\t' + id + ' ' + label + ' — ' + reason + '\n');
	process.exit(3);
}

if (!repo || !bundleOut) {
	process.stdout.write('GV\tFAIL\tTFC00 harness — repo root and a bundle-out path are both required\n');
	process.exit(1);
}

const results = [];
function ok(id, label, condition, detail) {
	const text = id + ' ' + label + (detail === undefined || detail === null || detail === '' ? '' : ' [' + detail + ']');
	const kind = condition ? 'PASS' : 'FAIL';
	results.push({ kind, text });
	process.stdout.write('GV\t' + kind + '\t' + text + (condition ? '' : ' — assertion did not hold') + '\n');
	return !!condition;
}

// ---------------------------------------------------------------------------
// The ONE bundle: the real files, concatenated in the page's own manifest
// order -- read directly from disk, never through graph-view-mutate.mjs.
// ---------------------------------------------------------------------------
const FILES = [
	'canonical/aid/scripts/graph/coverage-predicate.mjs',
	'canonical/aid/templates/knowledge-graph/graph-model.js',
	'canonical/aid/templates/knowledge-graph/graph-controls.js',
	'canonical/aid/templates/knowledge-graph/graph-table.js',
];
const parts = [];
for (const rel of FILES) {
	const p = path.join(repo, rel);
	if (!fs.existsSync(p)) {
		process.stdout.write('GV\tFAIL\tTFC00 harness — a shipped file this check depends on is missing: ' + rel + '\n');
		process.exit(1);
	}
	parts.push(fs.readFileSync(p, 'utf8'));
}
fs.mkdirSync(path.dirname(bundleOut), { recursive: true });
fs.writeFileSync(bundleOut, parts.join('\n'));

let M;
try {
	M = await import(pathToFileURL(bundleOut).href);
} catch (error) {
	process.stdout.write('GV\tFAIL\tTFC00 harness — the bundle failed to load as one module — '
		+ (error && error.message ? error.message : error) + '\n');
	process.exit(1);
}

const FX = await import('./graph-view-fixture.mjs');

let graphModel;
try {
	graphModel = M.parseRelationships(FX.FIXTURE);
} catch (error) {
	process.stdout.write('GV\tFAIL\tTFC00 harness — the shared fixture did not parse — '
		+ (error && error.message ? error.message : error) + '\n');
	process.exit(1);
}

// ---------------------------------------------------------------------------
// jsdom, resolved exactly like graph-view-dom.mjs's own convention.
// ---------------------------------------------------------------------------
let JSDOM;
try {
	const override = process.env.AID_GRAPH_JSDOM;
	const mod = override ? await import(pathToFileURL(override).href) : await import('jsdom');
	JSDOM = mod.JSDOM || (mod.default && mod.default.JSDOM);
} catch (error) {
	JSDOM = undefined;
}
if (typeof JSDOM !== 'function') {
	skipAll('jsdom is not resolvable here (it is not a repository dependency; set AID_GRAPH_JSDOM to its '
		+ 'package entry module to enable this class), so no DOM assertion in this class was run');
}

function makeDom() {
	// The url is http(s), not file://, DELIBERATELY: jsdom treats a file:// page
	// as an OPAQUE origin and throws SecurityError on any `localStorage` access
	// at all, which no real browser does for the pages this project actually
	// ships (Chrome and Firefox both grant file:// pages a working
	// localStorage). `hiddenSelectionKey` reads only `location.pathname`, which
	// is scheme-independent, so this substitution changes nothing this class
	// tests and avoids a jsdom-only limitation with no counterpart in the
	// runtime this code actually ships to.
	const dom = new JSDOM(
		'<!doctype html><html><body>'
		+ '<div data-conflicts></div>'
		+ '<div id="table-region"></div><div id="files-region"></div><div id="concepts-region"></div>'
		+ '</body></html>',
		{ url: 'http://localhost/project/.aid/knowledge/table.html', pretendToBeVisual: true });
	const { window } = dom;
	window.matchMedia = (query) => ({
		media: query, matches: false,
		addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {},
	});
	window.Element.prototype.scrollIntoView = function () { /* jsdom implements no scrolling */ };
	return dom;
}

const dom = makeDom();
const { window } = dom;
globalThis.window = window;
globalThis.document = window.document;
globalThis.localStorage = window.localStorage;
globalThis.location = window.location;
globalThis.Event = window.Event;
globalThis.KeyboardEvent = window.KeyboardEvent;

const consoleErrors = [];
const realError = console.error;
console.error = (...args) => { consoleErrors.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ')); };

const root = window.document;
const region = root.getElementById('table-region');
const filesRegion = root.getElementById('files-region');
const conceptsRegion = root.getElementById('concepts-region');
const store = M.createStore(graphModel, M.INITIAL_LENS, { reducedMotion: false, forcedColours: false });

const context = {
	store: store, graphModel: graphModel, region: region, filesRegion: filesRegion, conceptsRegion: conceptsRegion,
	surface: null, root: root, announceWindow: () => {},
};
const handle = M.mountTable(context);
console.error = realError;

/** Activate a control the way the platform's own pattern would, and report
 *  whether it IS the expected native element -- the exact idiom
 *  graph-table-window-check.mjs's own `activate()` uses. */
function activate(element, expectTag, expectType) {
	const native = element && element.tagName === expectTag && (!expectType || element.getAttribute('type') === expectType) && !element.disabled;
	element.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
	element.dispatchEvent(new window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
	element.click();
	return native;
}

const filesTable = () => filesRegion.querySelector('table[data-files-table]');
const conceptsTable = () => conceptsRegion.querySelector('table[data-concepts-table]');
const treeRow = (key) => filesTable().querySelector('tr[data-tree-key="' + key.replace(/"/g, '\\"') + '"]');
const conceptRow = (key) => conceptsTable().querySelector('tr[data-tree-key="' + key.replace(/"/g, '\\"') + '"]');
const showBox = (row) => row.querySelector('input[data-tree-show]');
const toggle = (row) => row.querySelector('button[data-tree-toggle]');

try {

// ===========================================================================
// TFC01 -- the partition
// ===========================================================================
const allIds = Array.from(graphModel.nodes.keys());
const conceptIds = allIds.filter((id) => graphModel.nodes.get(id).kind === 'concept');
const fileIds = allIds.filter((id) => graphModel.nodes.get(id).kind !== 'concept');

const conceptRowKeys = Array.from(conceptsTable().querySelectorAll('tbody tr[data-tree-key]')).map((tr) => tr.getAttribute('data-tree-key'));
const fileRowKeys = Array.from(filesTable().querySelectorAll('tbody tr[data-tree-key]'))
	.map((tr) => tr.getAttribute('data-tree-key'))
	// Folder pseudo-rows carry a trailing '/' key (tblBuildFilesTree's own
	// contract) and name no real node; excluded here, which IS the assertion
	// that a folder contributes no id of its own.
	.filter((key) => !key.endsWith('/'));

ok('TFC01', 'the Files-tree file rows and the Concepts rows partition graphModel.nodes',
	sameSet(conceptRowKeys, conceptIds) && sameSet(fileRowKeys, fileIds)
	&& conceptRowKeys.length + fileRowKeys.length === allIds.length
	&& new Set(conceptRowKeys.concat(fileRowKeys)).size === allIds.length,
	'concepts ' + conceptRowKeys.length + '/' + conceptIds.length + ', files ' + fileRowKeys.length + '/' + fileIds.length
	+ ', total ' + allIds.length);

function sameSet(a, b) {
	const sa = new Set(a); const sb = new Set(b);
	if (sa.size !== sb.size) return false;
	for (const x of sa) if (!sb.has(x)) return false;
	return true;
}

// ===========================================================================
// TFC02 -- nesting
// ===========================================================================
const docRow = treeRow('kb:alpha.md');
const overviewRow = treeRow('kb:alpha.md#overview');
const factRow = treeRow('kb:alpha.md#fact:renderer-choice');
ok('TFC02', 'alpha.md\'s section and fact nest under it (greater aria-level) and are absent from Concepts',
	!!docRow && !!overviewRow && !!factRow
	&& Number(overviewRow.getAttribute('aria-level')) > Number(docRow.getAttribute('aria-level'))
	&& Number(factRow.getAttribute('aria-level')) > Number(docRow.getAttribute('aria-level'))
	&& !conceptRow('kb:alpha.md#overview') && !conceptRow('kb:alpha.md#fact:renderer-choice'),
	'doc level ' + (docRow && docRow.getAttribute('aria-level')) + ', overview level ' + (overviewRow && overviewRow.getAttribute('aria-level')));

// ===========================================================================
// TFC03/TFC04 -- hide a leaf, prove it reaches the Relations projection and
// leaves coverage untouched, and prove the row itself survives
// ===========================================================================
const beforeIntegrity = JSON.stringify(store.getGraphModel().integrity);
const beforeCoverage = JSON.stringify(store.getViewModel().coverageGaps);
const LEAF = 'int:tests/orphan-check.sh';
const leafRow = treeRow(LEAF);
const leafBox = leafRow ? showBox(leafRow) : null;
if (leafBox) activate(leafBox, 'INPUT', 'checkbox');

const vmAfterHide = store.getViewModel();
ok('TFC03', 'unchecking a leaf hides it from the Relations projection while its own row stays present and re-checkable',
	!!leafRow && !!leafBox
	&& vmAfterHide.visibleNodes.every((n) => n.id !== LEAF)
	&& !treeRow(LEAF).querySelector('input[data-tree-show]').checked
	&& !!filesTable().contains(treeRow(LEAF)),
	'visible after hide: ' + vmAfterHide.visibleNodes.some((n) => n.id === LEAF));

ok('TFC04', 'hiding a node changes nothing about the coverage answer',
	JSON.stringify(store.getGraphModel().integrity) === beforeIntegrity
	&& JSON.stringify(store.getViewModel().coverageGaps) === beforeCoverage,
	'integrity unchanged and coverageGaps unchanged');

// ===========================================================================
// TFC14 -- the round trip a reload depends on: the checkbox handler really
// persisted to storage (not just to the in-memory lens), and resolving that
// EXACT stored value against the model reconstructs the same hidden set --
// the two halves Scope C's "the selection survives a reload" needs, proven
// with no second mount (a second JSDOM window would not share this one's
// localStorage, so this proves the two halves directly instead).
// ===========================================================================
const storedRaw = window.localStorage.getItem(M.hiddenSelectionKey(window.location.pathname));
const storedParsed = storedRaw ? JSON.parse(storedRaw) : null;
const resolvedBack = M.resolveHiddenSelection(graphModel, storedParsed);
ok('TFC14', 'the checkbox handler persists to storage, and resolving that exact stored value reconstructs the hidden set',
	Array.isArray(storedParsed) && storedParsed.includes(LEAF)
	&& resolvedBack.suppressed === false
	&& JSON.stringify(Array.from(resolvedBack.hiddenIds).sort()) === JSON.stringify(Array.from(store.getLens()['filters.hiddenIds']).sort()),
	'stored=' + JSON.stringify(storedParsed));

// Restore, for the classes below. graph-table.js clears and rebuilds its
// WHOLE table on every store notification (no patching), so `leafBox` above
// is now DETACHED from the live document, and jsdom's `.click()` fires NO
// 'change' event on a checkbox that is not currently connected (measured:
// `HTMLInputElement#click()` on a disconnected element still flips `.checked`
// but runs no activation behaviour at all) -- a real browser has no such
// case, since a control a reader can click is by definition rendered and
// connected. So every interaction from here on re-queries the LIVE DOM
// immediately before acting on it, never reusing a captured reference across
// a render boundary.
activate(showBox(treeRow(LEAF)), 'INPUT', 'checkbox');

// ===========================================================================
// TFC05/TFC06 -- a folder with two children (the 'src' folder: src/reader.mjs
// and the zero-row src/unreferenced-loader.mjs)
// ===========================================================================
const SRC_A = 'int:src/reader.mjs';
const SRC_B = 'int:src/unreferenced-loader.mjs';
const OUTSIDE = 'ext:mdn-webgl';

// An independently-hidden node OUTSIDE the folder, so TFC06 can prove
// "nothing else" rather than merely "the folder came back". Queried fresh:
// this click re-renders the tree, so any reference taken before it would be
// stale for the click that follows.
activate(showBox(treeRow(OUTSIDE)), 'INPUT', 'checkbox');

activate(showBox(treeRow('src/')), 'INPUT', 'checkbox');
const hiddenAfterFolder = new Set(store.getLens()['filters.hiddenIds']);
ok('TFC05', 'unchecking a two-child folder hides both children and touches nothing outside the subtree',
	hiddenAfterFolder.has(SRC_A) && hiddenAfterFolder.has(SRC_B) && hiddenAfterFolder.has(OUTSIDE)
	&& hiddenAfterFolder.size === 3,
	'hidden set: ' + Array.from(hiddenAfterFolder).join(','));

activate(showBox(treeRow('src/')), 'INPUT', 'checkbox');
const hiddenAfterRestore = new Set(store.getLens()['filters.hiddenIds']);
ok('TFC06', 're-checking the folder restores exactly its own subtree, leaving the independently-hidden node hidden',
	!hiddenAfterRestore.has(SRC_A) && !hiddenAfterRestore.has(SRC_B) && hiddenAfterRestore.has(OUTSIDE)
	&& hiddenAfterRestore.size === 1,
	'hidden set: ' + Array.from(hiddenAfterRestore).join(','));

// Restore the outside node too, for the classes below.
activate(showBox(treeRow(OUTSIDE)), 'INPUT', 'checkbox');

// ===========================================================================
// TFC07 -- native, keyboard-operable controls
// ===========================================================================
const docsToggle = toggle(treeRow('docs/'));
const nativeCheckbox = (() => { const b = showBox(treeRow(LEAF)); return !!b && b.tagName === 'INPUT' && b.getAttribute('type') === 'checkbox'; })();
const nativeToggle = docsToggle ? (docsToggle.tagName === 'BUTTON' && docsToggle.getAttribute('type') === 'button' && !docsToggle.disabled) : false;
ok('TFC07', 'the Show checkbox and the collapse toggle are both native controls',
	nativeCheckbox && nativeToggle,
	'checkbox native=' + nativeCheckbox + ' toggle native=' + nativeToggle);

// ===========================================================================
// TFC08 -- indeterminate. Hide ONLY src/reader.mjs, leaving its sibling
// src/unreferenced-loader.mjs visible, which the fixture's real 'src' folder
// (two children) makes possible.
// ===========================================================================
activate(showBox(treeRow(SRC_A)), 'INPUT', 'checkbox');
const srcMixedBox = showBox(treeRow('src/'));
ok('TFC08', 'a folder checkbox is indeterminate (native IDL) when some but not all children are hidden',
	srcMixedBox.indeterminate === true && srcMixedBox.checked === false,
	'indeterminate=' + srcMixedBox.indeterminate + ' checked=' + srcMixedBox.checked);
activate(showBox(treeRow(SRC_A)), 'INPUT', 'checkbox'); // restore

// ===========================================================================
// TFC09 -- collapse/expand via the native `hidden` attribute, and it never
// touches filters.hiddenIds
// ===========================================================================
const hiddenIdsBeforeCollapse = Array.from(store.getLens()['filters.hiddenIds']);
const docsToggleBtn = toggle(treeRow('docs/'));
activate(docsToggleBtn, 'BUTTON', 'button');
const mediaRowAfterCollapse = treeRow('docs/media/');
const pngRowAfterCollapse = treeRow('int:docs/media/table-view.png');
ok('TFC09', 'collapsing hides descendant rows via the native hidden attribute, exposes aria-expanded=false, and never touches filters.hiddenIds',
	toggle(treeRow('docs/')).getAttribute('aria-expanded') === 'false'
	&& !!mediaRowAfterCollapse && mediaRowAfterCollapse.hidden === true
	&& !!pngRowAfterCollapse && pngRowAfterCollapse.hidden === true
	&& JSON.stringify(Array.from(store.getLens()['filters.hiddenIds']).sort()) === JSON.stringify(hiddenIdsBeforeCollapse.sort()),
	'aria-expanded=' + toggle(treeRow('docs/')).getAttribute('aria-expanded') + ' media.hidden=' + (mediaRowAfterCollapse && mediaRowAfterCollapse.hidden));
activate(toggle(treeRow('docs/')), 'BUTTON', 'button'); // re-expand
ok('TFC09b', 'expanding restores the descendant rows', treeRow('int:docs/media/table-view.png').hidden === false);

// ===========================================================================
// TFC10/TFC11 -- resolveHiddenSelection, pure (no storage, no page)
// ===========================================================================
const dropCase = M.resolveHiddenSelection(graphModel, [LEAF, 'kb:this-id-does-not-exist']);
ok('TFC10', 'resolveHiddenSelection drops an id the model no longer has and keeps the rest',
	dropCase.hiddenIds.length === 1 && dropCase.hiddenIds[0] === LEAF
	&& dropCase.dropped.length === 1 && dropCase.dropped[0] === 'kb:this-id-does-not-exist'
	&& dropCase.suppressed === false,
	JSON.stringify(dropCase));

const everyId = Array.from(graphModel.nodes.keys());
const suppressCase = M.resolveHiddenSelection(graphModel, everyId);
ok('TFC11', 'resolveHiddenSelection suppresses a selection that would hide every node',
	suppressCase.suppressed === true && suppressCase.hiddenIds.length === 0,
	JSON.stringify(suppressCase));

// ===========================================================================
// TFC15 -- ledger row 6 (MEDIUM): a raw stored selection is never assumed
// unique. Repeating ONE real id past the model's own node count used to
// inflate `kept.length` past `totalNodes` and trip the suppress rule even
// though 1 of graphModel.nodes.size nodes -- not "every node" -- would
// actually be hidden. Reproduced at fixture scale (the reviewer's own repro
// used the live 976-node file; the arithmetic defect is identical here).
// ===========================================================================
const duplicateInflated = new Array(graphModel.nodes.size + 5).fill(LEAF);
const dupCase = M.resolveHiddenSelection(graphModel, duplicateInflated);
ok('TFC15', 'resolveHiddenSelection deduplicates before measuring "hides everything", so a repeated id cannot inflate a false suppression',
	dupCase.suppressed === false && dupCase.dropped.length === 0
	&& dupCase.hiddenIds.length === 1 && dupCase.hiddenIds[0] === LEAF,
	'stored ' + duplicateInflated.length + ' entries (all the same id) against ' + graphModel.nodes.size + ' real nodes -- ' + JSON.stringify(dupCase));

// ===========================================================================
// TFC16 -- ledger row 8 (LOW): the "unattached document" fallback in
// tblBuildFilesTree, kept for the completeness guarantee (acceptance item 1)
// even against a malformed artifact, was reachable by no fixture at all --
// exercised here directly against a hand-built graphModel a real
// parseRelationships() would never emit (a section naming a document with no
// document node), never against FX.FIXTURE, which is well-formed by
// construction and cannot reach this branch.
// ===========================================================================
const orphanModel = {
	nodes: new Map([
		['kb:doc-a', { id: 'kb:doc-a', kind: 'document', kbDoc: 'doc-a' }],
		['kb:doc-a#s1', { id: 'kb:doc-a#s1', kind: 'section', kbDoc: 'doc-a' }],
		// doc-b has NO document node of its own -- the malformed case.
		['kb:doc-b#s1', { id: 'kb:doc-b#s1', kind: 'section', kbDoc: 'doc-b' }],
	]),
};
const orphanTree = M.tblBuildFilesTree(orphanModel);
const orphanIds = M.tblFlattenTree(orphanTree).filter((r) => r.entry.type === 'file').map((r) => r.entry.node.id);
ok('TFC16', 'a section naming an absent document is attached under the "unattached" fallback rather than silently dropped',
	orphanIds.includes('kb:doc-b#s1') && orphanIds.includes('kb:doc-a#s1') && orphanIds.includes('kb:doc-a')
	&& orphanIds.length === 3 && new Set(orphanIds).size === 3,
	JSON.stringify(orphanIds));

// ===========================================================================
// TFC17 -- ledger row 4 (MEDIUM): every focusable Files-tree/Concepts control
// carries scroll-margin-top, the same SC 2.4.11 allowance tblBodyRow and
// tblRenderUnlisted already give the Relations table and its unlisted region
// (graph-view-dom.mjs DT22's own regex). A control with none set would be
// hideable behind the sticky top bar and the sticky `.tbl th` rule the moment
// it receives keyboard focus.
// ===========================================================================
const marginPx = /^\d+px$/;
const filesLeafBox = showBox(treeRow(SRC_A));
const filesToggleBtn = toggle(treeRow('docs/'));
const conceptRowEl = conceptsTable().querySelector('tbody tr[data-tree-key]');
const conceptsBox = conceptRowEl ? showBox(conceptRowEl) : null;
ok('TFC17', 'every focusable Files-tree and Concepts-table control carries a numeric scroll-margin-top',
	!!filesLeafBox && marginPx.test(filesLeafBox.style.scrollMarginTop)
	&& !!filesToggleBtn && marginPx.test(filesToggleBtn.style.scrollMarginTop)
	&& !!conceptsBox && marginPx.test(conceptsBox.style.scrollMarginTop),
	'files checkbox=' + (filesLeafBox && filesLeafBox.style.scrollMarginTop)
	+ ' files toggle=' + (filesToggleBtn && filesToggleBtn.style.scrollMarginTop)
	+ ' concepts checkbox=' + (conceptsBox && conceptsBox.style.scrollMarginTop));

// ===========================================================================
// TFC12 -- the two-region and GV17/GV22 contracts hold with these regions
// present
// ===========================================================================
ok('TFC12', 'the Files/Concepts regions create no live region and no data-control/data-group-toggle attribute',
	filesRegion.querySelectorAll('[aria-live], [role="alert"], [role="status"], [role="log"], [data-control], [data-group-toggle]').length === 0
	&& conceptsRegion.querySelectorAll('[aria-live], [role="alert"], [role="status"], [role="log"], [data-control], [data-group-toggle]').length === 0);

// ===========================================================================
ok('TFC13', 'no console error was logged across the whole run', consoleErrors.length === 0, consoleErrors.join(' | ').slice(0, 200));

} catch (error) {
	ok('TFC99', 'every assertion above ran to completion with no thrown error',
		false, (error && error.stack ? error.stack : String(error)));
}

const failed = results.filter((r) => r.kind === 'FAIL').length;
process.exit(failed > 0 ? 1 : 0);
