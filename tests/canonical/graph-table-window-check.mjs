// graph-table-window-check.mjs -- task-033's own non-vacuity proof for the
// table-only page's load-on-demand window, its "Load more" button and the
// filter-over-full-set property.
//
// WHY A SEPARATE SCRIPT RATHER THAN AN EXTRA CLASS INSIDE graph-view-dom.mjs
//   That file's own `assemble(true)` always concatenates graph-table.js into
//   its page regardless of `build-graph-src.mjs`'s `OWNER_EXCLUDES_TABLE_RENDERING`,
//   and it substitutes the CURRENT graph-skeleton.html byte for byte -- which,
//   since 2026-08-06 (eedacc3d), no longer declares a `[data-table-region]` at
//   all. So `mountShell()` there now always calls `mountTable` with a null
//   region and DT10 fails loudly the moment jsdom is resolvable (it SKIPS,
//   silently hiding this, whenever jsdom is absent -- which is every default
//   run that sets no AID_GRAPH_JSDOM). That is a pre-existing mismatch between
//   that harness and the shipped skeleton, not something task-033 introduced or
//   owns fixing (graph-skeleton.html is owned by a concurrent task). Mounting
//   `mountTable` DIRECTLY, against a container this script builds itself, is
//   both the correct shape for a table-ONLY page (which is never `mountShell`)
//   and a way to test task-033's own feature with no dependency on that mismatch.
//
// WHAT THIS PROVES, AND WHY THE FIXTURE IS SHAPED THE WAY IT IS
//   The fixture (TOTAL_ROWS rows) is LARGER than one window (PAGE_SIZE rows),
//   and exactly one row -- NEEDLE_ROW -- carries a unique word nowhere else in
//   the fixture, placed well past the first window. That is what gives
//   TWC07/TWC08 teeth: with only the first window rendered, the needle's row is
//   NOT in the DOM (checked directly, TWC07), so a check that merely re-scanned
//   the CURRENTLY RENDERED rows for the needle would find nothing -- exactly
//   the "filters the loaded window, not the whole set" bug this task's own
//   DETAIL.md names. The real behaviour is filtering through the STORE (whole
//   admitted set, upstream of this rendering entirely), so applying the SAME
//   text filter through `store.setLens` DOES surface that row (TWC08). Both
//   halves are asserted from the same running instance, so this is not a
//   redescription of the implementation -- a regression to a DOM-window-only
//   filter would make TWC08 fail exactly where TWC07 already shows the naive
//   scan fails today.
//
// PROTOCOL   GV \t PASS|FAIL|SKIP|NOTE \t <label>     (graph-view-model.mjs's own)
//
// USAGE
//   node graph-table-window-check.mjs <repo-root> <bundle-out-path>
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
	['TWC01', 'a first paint renders exactly one window (PAGE_SIZE rows), never the whole filtered set'],
	['TWC02', 'the needle row -- past the first window -- is absent from the rendered DOM before any interaction'],
	['TWC03', 'the caption and the window-status paragraph both state "Showing N of M" honestly at first paint'],
	['TWC04', 'the first paint announces the same "Showing N of M" sentence through the injected announcer, and graph-table.js creates no live-region element of its own'],
	['TWC05', 'the "Load more" control is a native, enabled <button type="button">, driven by keyboard alone (Enter/Space), and it extends the window'],
	['TWC06', 'after keyboard-only activation, focus lands on the next "Load more" button (or, once nothing remains, the window-status text) -- never dropped to <body>'],
	['TWC06b', 'repeated activation reaches every row and then removes the button, and the window-status caps at the true total ("Showing M of M"), never overshooting it'],
	['TWC06c', 'the convenience scroll listener calls the identical growth path the button calls, and is inert once nothing remains to load'],
	['TWC07', 'RE-STATED: with only the first window rendered, the needle row is absent -- so a hypothetical scan of the CURRENTLY RENDERED rows for the needle text finds nothing (the failure mode a window-local filter would exhibit)'],
	['TWC08', 'a text filter applied through the store -- the whole admitted set, never the rendered window -- surfaces the needle row that TWC07 showed was outside the window, and the window resets to its first page over the new, much smaller filtered total'],
	['TWC09', 'clearing the filter restores the full total and resets the window to its first page again, re-announcing both'],
	['TWC10', 'no console error was logged across the whole run'],
];

function skipAll(reason) {
	for (const [id, label] of CLASSES) process.stdout.write('GV\tSKIP\t' + id + ' ' + label + ' — ' + reason + '\n');
	process.exit(3);
}

if (!repo || !bundleOut) {
	process.stdout.write('GV\tFAIL\tTWC00 harness — repo root and a bundle-out path are both required\n');
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
// order (predicate, model, controls, table) -- read directly from disk, never
// through graph-view-mutate.mjs, so this script has no coupling to that file's
// mutation catalogue or its own S1-budget bookkeeping.
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
		process.stdout.write('GV\tFAIL\tTWC00 harness — a shipped file this check depends on is missing: ' + rel + '\n');
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
	process.stdout.write('GV\tFAIL\tTWC00 harness — the bundle failed to load as one module — '
		+ (error && error.message ? error.message : error) + '\n');
	process.exit(1);
}

// ---------------------------------------------------------------------------
// A fixture LARGER than one window (feature-009/task-033's own non-vacuity
// requirement), with one row -- the needle -- placed well past the first
// window and carrying a word that appears nowhere else in the fixture.
// ---------------------------------------------------------------------------
const PAGE_SIZE = 25;
const TOTAL_ROWS = 64;
const NEEDLE_ROW = 50;
const NEEDLE_WORD = 'needle-marker-zz9';

const pad = (n) => String(n).padStart(4, '0');
const rows = [];
for (let i = 1; i <= TOTAL_ROWS; i += 1) {
	const sourceId = 'kb:doc-' + pad(i) + '.md';
	const targetId = sourceId + '#s';
	const targetName = i === NEEDLE_ROW
		? 'doc-' + pad(i) + '.md § ' + NEEDLE_WORD + ' section'
		: 'doc-' + pad(i) + '.md § Section ' + i;
	rows.push('| ' + sourceId + ' | document | doc-' + pad(i) + '.md | ' + targetId + ' | section | '
		+ targetName + ' | has-part | part-of | declared |   |');
}
const HEADER = '| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |';
const DELIM = '|---|---|---|---|---|---|---|---|---|---|';
const FIXTURE = '# Relationships\n\n' + HEADER + '\n' + DELIM + '\n' + rows.join('\n') + '\n';

let graphModel;
try {
	graphModel = M.parseRelationships(FIXTURE);
} catch (error) {
	process.stdout.write('GV\tFAIL\tTWC00 harness — the self-built fixture did not parse — '
		+ (error && error.message ? error.message : error) + '\n');
	process.exit(1);
}
if (graphModel.edges.length !== TOTAL_ROWS) {
	process.stdout.write('GV\tFAIL\tTWC00 harness — the fixture did not round-trip: ' + graphModel.edges.length
		+ ' edges parsed, ' + TOTAL_ROWS + ' rows authored\n');
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
	skipAll('jsdom is not resolvable here (it IS a devDependency of the repo-root package.json, but is not installed in this environment; install it, or set AID_GRAPH_JSDOM to its '
		+ 'package entry module to enable this class), so no DOM assertion in this class was run');
}

const dom = new JSDOM('<!doctype html><html><body><div id="table-region"></div></body></html>', { pretendToBeVisual: true });
const { window } = dom;
globalThis.window = window;
globalThis.document = window.document;
globalThis.Event = window.Event;
globalThis.KeyboardEvent = window.KeyboardEvent;
// jsdom's own matchMedia always answers false; a table-only page has no narrow
// breakpoint under test here, so a plain false-for-everything stub is enough.
window.matchMedia = (query) => ({
	media: query, matches: false,
	addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {},
});
window.Element.prototype.scrollIntoView = function () { /* jsdom implements no scrolling */ };

const region = window.document.getElementById('table-region');
const store = M.createStore(graphModel, M.INITIAL_LENS, { reducedMotion: false, forcedColours: false });

const consoleErrors = [];
const realError = console.error;
console.error = (...args) => { consoleErrors.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ')); };

const announcements = [];
const context = {
	store: store,
	graphModel: graphModel,
	region: region,
	surface: null,
	root: window.document,
	pageSize: PAGE_SIZE,
	announceWindow: (text) => { announcements.push(text); },
};
const handle = M.mountTable(context);
console.error = realError;

// ---------------------------------------------------------------------------
// Readers over the rendered DOM -- the SAME idiom graph-view-dom.mjs uses.
// ---------------------------------------------------------------------------
const bodyRows = () => Array.from(region.querySelectorAll('table[data-relationship-table] tbody tr[data-row]'));
const loadMoreButton = () => region.querySelector('[data-load-more]');
const windowStatus = () => region.querySelector('[data-window-status]');
const hostText = () => region.textContent;

/** Activate a control the way the platform's own Button pattern would, and
 *  report whether it IS that platform element -- the exact idiom
 *  graph-view-dom.mjs's own `activate()` uses, so "keyboard operable" here
 *  means the same thing it means everywhere else in this suite. */
function activate(element) {
	const native = element.tagName === 'BUTTON' && element.getAttribute('type') === 'button' && !element.disabled;
	element.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
	element.dispatchEvent(new window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
	element.click();
	return native;
}

// ===========================================================================
// Wrapped in one try/catch: a defect severe enough to remove an element this
// script assumes (e.g. the window-status paragraph, under a mutation that
// disables windowing outright) must still report every class it reached as a
// clean FAIL rather than crash the process -- which is itself part of the
// non-vacuity discipline: a check that can only ever pass OR silently crash
// with no verdict is not distinguishable from one that was never run.
// ===========================================================================
try {

ok('TWC01', 'a first paint renders exactly one window, never the whole filtered set',
	bodyRows().length === PAGE_SIZE && graphModel.edges.length === TOTAL_ROWS && PAGE_SIZE < TOTAL_ROWS,
	bodyRows().length + ' rows rendered of ' + TOTAL_ROWS + ' total, window=' + PAGE_SIZE);

ok('TWC02', 'the needle row is absent from the rendered DOM before any interaction',
	hostText().indexOf(NEEDLE_WORD) === -1 && bodyRows().every((tr) => Number(tr.getAttribute('data-row')) !== NEEDLE_ROW),
	'needle at row ' + NEEDLE_ROW + ', first window rows 1..' + PAGE_SIZE);

const firstSummary = 'Showing ' + PAGE_SIZE + ' of ' + TOTAL_ROWS + ' relationships.';
ok('TWC03', 'the caption and the window-status paragraph both state "Showing N of M" honestly at first paint',
	!!windowStatus() && windowStatus().textContent === firstSummary
	&& region.querySelector('caption').textContent.indexOf(firstSummary) === 0,
	'status="' + (windowStatus() ? windowStatus().textContent : '(none)') + '"');

ok('TWC04', 'the first paint announces the same sentence through the injected announcer, and this file creates no live region of its own',
	announcements.length === 1 && announcements[0] === firstSummary
	&& region.querySelectorAll('[aria-live], [role="alert"], [role="status"], [role="log"]').length === 0,
	JSON.stringify(announcements));

const button1 = loadMoreButton();
let native1 = false;
if (button1) native1 = activate(button1);
ok('TWC05', 'the "Load more" control is a native, enabled button, driven by keyboard alone, and it extends the window',
	!!button1 && native1 && bodyRows().length === PAGE_SIZE * 2,
	'native=' + native1 + ' rows-after=' + bodyRows().length);

const afterFirstLoad = 'Showing ' + Math.min(PAGE_SIZE * 2, TOTAL_ROWS) + ' of ' + TOTAL_ROWS + ' relationships.';
const focusedAfterLoad = window.document.activeElement;
ok('TWC06', 'after keyboard-only activation, focus lands on the next control rather than being dropped',
	!!focusedAfterLoad && (focusedAfterLoad === loadMoreButton() || focusedAfterLoad === windowStatus())
	&& windowStatus().textContent === afterFirstLoad,
	'activeElement=' + (focusedAfterLoad ? focusedAfterLoad.tagName + '[' + (focusedAfterLoad.getAttribute('data-load-more') !== null ? 'load-more' : focusedAfterLoad.getAttribute('data-window-status')) + ']' : 'none'));

// Drive it to the end -- the needle (row 50) is now within reach by growth
// alone, which is a DIFFERENT route from the filter TWC08 proves; both are
// asserted so growth-to-completion and filter-to-completion are both covered.
let clicks = 1;
while (loadMoreButton() && clicks < 20) { activate(loadMoreButton()); clicks += 1; }
ok('TWC06b', 'repeated activation reaches every row, then removes the button, and the status caps at the true total',
	bodyRows().length === TOTAL_ROWS && !loadMoreButton()
	&& windowStatus().textContent === 'Showing ' + TOTAL_ROWS + ' of ' + TOTAL_ROWS + ' relationships.',
	bodyRows().length + '/' + TOTAL_ROWS + ' after ' + clicks + ' activation(s)');

// --- Reset to a fresh first-window state for the scroll and filter classes -
store.setLens(M.INITIAL_LENS);
ok('TWC06c-setup', 'a lens reset (any store notification) puts the window back to its first page',
	bodyRows().length === PAGE_SIZE, bodyRows().length + ' rows after reset');

// The scroll listener is a CONVENIENCE that calls the IDENTICAL growth path --
// simulate "near the bottom" geometry and dispatch a real 'scroll' event, with
// no button click at all, and require the SAME effect activation produces.
Object.defineProperty(window.document.documentElement, 'scrollHeight', { value: 100000, configurable: true });
Object.defineProperty(window, 'innerHeight', { value: 800, configurable: true, writable: true });
Object.defineProperty(window, 'scrollY', { value: 100000, configurable: true, writable: true });
window.dispatchEvent(new window.Event('scroll'));
ok('TWC06c', 'the convenience scroll listener, with no click at all, grows the window by exactly one page',
	bodyRows().length === PAGE_SIZE * 2, bodyRows().length + ' rows after one simulated near-bottom scroll (expected ' + (PAGE_SIZE * 2) + ')');

// Drain it via scroll alone, then confirm it goes inert once nothing remains --
// the guard this file's own header names (`view.loadMoreButton` null once
// `shown >= total`), asserted by NOT growing past the true total.
for (let i = 0; i < 10 && loadMoreButton(); i += 1) window.dispatchEvent(new window.Event('scroll'));
ok('TWC06c-drain', 'the scroll listener alone reaches every row and then goes inert (never overshoots the true total)',
	bodyRows().length === TOTAL_ROWS && !loadMoreButton(),
	bodyRows().length + '/' + TOTAL_ROWS);

// --- The crux: filter-over-full-set, against a fresh first-window state -----
store.setLens(M.INITIAL_LENS);
ok('TWC07', 'RE-STATED with a fresh first window: the needle row is absent, so a scan of the RENDERED rows alone would find nothing',
	bodyRows().length === PAGE_SIZE && hostText().indexOf(NEEDLE_WORD) === -1,
	bodyRows().length + ' rows rendered, needle row ' + NEEDLE_ROW + ' not among them');

store.setLens({ 'filters.text': NEEDLE_WORD });
const filteredRows = bodyRows();
ok('TWC08', 'a text filter through the store surfaces the needle row that was outside the rendered window, over the WHOLE admitted set',
	filteredRows.length === 1 && Number(filteredRows[0].getAttribute('data-row')) === NEEDLE_ROW
	&& hostText().indexOf(NEEDLE_WORD) !== -1
	&& windowStatus().textContent === 'Showing 1 of 1 relationship.'
	&& announcements[announcements.length - 1] === 'Showing 1 of 1 relationship.',
	filteredRows.length + ' row(s), data-row=' + (filteredRows[0] ? filteredRows[0].getAttribute('data-row') : '(none)'));

store.setLens({ 'filters.text': '' });
ok('TWC09', 'clearing the filter restores the full total and resets the window to its first page again',
	bodyRows().length === PAGE_SIZE
	&& windowStatus().textContent === firstSummary
	&& announcements[announcements.length - 1] === firstSummary,
	bodyRows().length + ' rows, status="' + windowStatus().textContent + '"');

ok('TWC10', 'no console error was logged across the whole run',
	consoleErrors.length === 0, consoleErrors.join(' | ').slice(0, 200));

} catch (error) {
	ok('TWC99', 'every assertion above ran to completion with no thrown error',
		false, (error && error.message ? error.message : String(error)));
}

const failed = results.filter((r) => r.kind === 'FAIL').length;
process.exit(failed > 0 ? 1 : 0);
