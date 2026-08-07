// graph-view-dom.mjs -- the DOM half of the graph-view suite: assemble BOTH of
// the two pages this rendering family now ships, boot each into a real
// document, and assert the rendered markup, the keyboard drive, the reveal
// and the determinism of the output.
//
// TWO PAGES, ONE FILE, SINCE eedacc3d/task-033
//   The owner removed the relationship table from graph.html (eedacc3d,
//   2026-08-06) -- the drawing surface's own peer rendering is gone from that
//   page. task-033 restored it on its own page, table.html, composed through
//   the SAME `mountTable`/`buildControlManifest`/`filterAxis` seams
//   (table-view-shell.js's own `tbvMountShell`, never `mountShell`, which
//   builds a whole control surface -- lens bar, grouping, viewport, legend --
//   this page does not have). So this file now boots TWO documents from TWO
//   skeletons:
//     - graph.html   (graph-skeleton.html + graph-controls.js's mountShell)
//     - table.html   (table-view-skeleton.html + table-view-shell.js's
//                     tbvMountShell)
//   GV17a-d, GV22b and GV24 assert the SHELL's own control manifest (lens bar,
//   grouping, focus, the (now empty) viewport axis, group disclosures) and
//   stay bound to graph.html, unchanged from before this split. Every DT10-DT30
//   class asserts the TABLE RENDERING's own DOM contract, and that contract now
//   lives on table.html -- so those classes are bound to THAT document. DT26
//   (the table-precedes-graph DOM order, meaningful only when both lived on one
//   page) is RETIRED as an ordering claim and REPLACED under the same id with
//   the property that still matters: this build carries no drawing rendering at
//   all. DT30 (in-page anchors resolve) moves to table.html, where the
//   dynamically-rendered anchors (the skip link, the caption's link to the
//   unlisted region) actually live now -- graph.html's own in-page anchor set is
//   the one static, unconditional `#top` skip link, which needs no DOM proof.
//
// TWO MECHANICAL LIMITS, STATED BECAUSE THEY BOUND WHAT THIS FILE MAY CLAIM
//   1. jsdom does not execute an inline <script type="module"> at all: it parses
//      it and moves on. So neither page's own module block is left to run
//      itself. Each page's own files are loaded as one module and its shell's
//      mount function is called against that page's assembled markup -- the
//      same code, the same DOM API and the same call each page's last line
//      makes. What is NOT exercised is the browser's own evaluation of that
//      inline block; only a browser can cover that, and no browser check
//      belongs in this suite.
//   2. jsdom implements no layout and no native key activation. Every measured
//      height is therefore 0, and a keydown on a <button> does not synthesise a
//      click the way a browser's Button pattern does. So each control is first
//      asserted to BE a native, enabled <button type="button"> -- which is what
//      makes Enter and Space work in a browser -- and then its activation
//      behaviour is invoked, which is exactly what those keys trigger. The
//      keydowns are dispatched too, but the load-bearing signal is the pair.
//
// jsdom IS NOT A REPOSITORY DEPENDENCY. When it cannot be resolved this file
// SKIPS LOUDLY -- one recorded SKIP per assertion class, exit 3 -- and never
// reports a pass. Everything provable without a document lives in
// graph-view-model.mjs, which needs nothing but Node.
//
// THE TABLE BUNDLE, AND WHY IT IS BUILT FROM `bundlePath` RATHER THAN DISK
//   `bundlePath` (this file's second CLI argument) is graph-view-mutate.mjs's
//   own output: the predicate + graph-model.js + graph-controls.js +
//   graph-table.js, in that order, optionally with ONE deliberate mutation
//   applied. test-graph-view-shell.sh's `dom_mutation_bites` (DT19b, DT21e)
//   depends on that mutation reaching the DOM assertions -- so the table's own
//   executable module is `bundlePath`'s bytes with table-view-shell.js appended
//   (never a second, independent read of graph-table.js/graph-model.js/
//   graph-controls.js from disk), which is what lets a mutation injected into
//   graph-table.js still make DT19b/DT21e fail exactly as it did before this
//   split.
//
// PROTOCOL   GV \t PASS|FAIL|SKIP|NOTE \t <label>     (see graph-view-model.mjs)
//
// USAGE
//   node graph-view-dom.mjs <repo-root> <bundle.mjs> <work-dir>
//     <work-dir> receives graph.html and table.html (assembled), rendered.html
//     and table-rendered.html (each page after boot, which is the markup a
//     reader actually receives) and the three link targets both pages' own
//     link checks resolve.

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const repo = process.argv[2];
const bundlePath = process.argv[3];
const workDir = process.argv[4];

/** One entry per assertion class, so an absent runtime is recorded class by class
 *  rather than as a single line that hides how much did not run. */
const CLASSES = [
	['DT10', 'the table page boots into a document with no thrown error and no console error'],
	['DT11', 'the rendered region is a real table: caption, thead, tbody, six column headers (task-034 slims ten to six), a row header per row'],
	['DT12', 'aria-sort is on the listed table\'s six column headers and on no other cell'],
	['DT13', 'the region creates no third live region and carries no shell control attribute'],
	['DT14', 'the caption states the drawn counts, the lens summary and both links, with their targets present'],
	['DT15', 'the skip link is the region\'s first element and its target is focusable'],
	['DT16', 'the region\'s tab stops are exactly the enumerated set'],
	['DT17', 'every control is a native button and driving it writes the expected control state'],
	['DT18', 'aria-sort transitions none -> ascending -> descending -> none under activation'],
	['DT19', 'every emphasis class renders its text badge, and a dimmed row renders none'],
	['DT20', 'an emptied table states why, and never renders that row when rows exist'],
	['DT21', 'the unlisted-nodes region is a real table naming every node no listed row names'],
	['DT22', 'the reveal scrolls the right element instantly, moves no focus, and re-arms'],
	['DT24', 'the same projection renders byte-identical markup twice'],
	['DT25', 'a width crossing re-emits at the same revision with no second reveal'],
	['DT26', 'this build carries no drawing rendering at all, and the table still renders completely'],
	['DT27', 'below the breakpoint the shortened label is aria-hidden and the full name is in the tree'],
	['DT28', 'the region\'s authored head survives the mount, so the shell can still write its counts'],
	['DT29', 'the rendered projection is the store\'s current ViewModel instance'],
	['DT30', 'every in-page anchor the table page emits resolves to an id in that page'],
	['GV17a', 'the CONTROL_MANIFEST<->data-control DOM bijection holds, every matched element native and focusable, at both gate widths'],
	['GV17b', 'every non-viewport manifest entry is driven by keyboard input alone and writes its own declared LensState effect'],
	['GV17c', 'the seven viewport entries write nothing with no handle registered, and write the handle\'s own transform with one'],
	['GV17d', 'a data-group-toggle element is focusable and keyboard-operable'],
	['GV22b', 'exactly one data-group-toggle element exists per foldable group and none for any other, before and after an expansion'],
	['GV24', 'after each of the four presets, every named control class stays present and enabled, and a write to each still changes LensState'],
	['GV29', 'a stored selection naming every node survives a full mountShell() boot as a VISIBLE notice in [data-conflicts], not merely as resolveHiddenSelection\'s own suppressed:true'],
];

function skipAll(reason) {
	for (const [id, label] of CLASSES) {
		process.stdout.write('GV\tSKIP\t' + id + ' ' + label + ' — ' + reason + '\n');
	}
	process.exit(3);
}

if (!repo || !bundlePath || !workDir) {
	process.stdout.write('GV\tFAIL\tDT00 harness — repo root, bundle and work dir are all required\n');
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
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const ids = (list) => Array.from(new Set(list)).sort();

const FX = await import('./graph-view-fixture.mjs');

// ---------------------------------------------------------------------------
// Assemble the two pages -- a stand-in for the assembly steps
// build-graph-src.mjs/build-table-src.mjs own. Each performs exactly the
// substitutions its own skeleton declares and fails loudly on any placeholder
// left behind, so neither can quietly produce a different page.
// ---------------------------------------------------------------------------
const RD = (rel) => fs.readFileSync(path.join(repo, rel), 'utf8');
const G = (name) => RD('canonical/aid/templates/knowledge-graph/' + name);

function substitute(html, subs, label) {
	let out = html;
	for (const [key, val] of Object.entries(subs)) {
		if (!out.includes(key)) { throw new Error(label + ' placeholder missing: ' + key); }
		out = out.split(key).join(val);
	}
	const leftover = out.match(/\{\{[A-Z_]+\}\}/g);
	if (leftover) throw new Error(label + ' unsubstituted placeholders: ' + leftover.join(', '));
	return out;
}

/** graph.html -- mirrors build-graph-src.mjs's own OWNER_EXCLUDES_TABLE_RENDERING
 *  (= true today): the table never concatenates into THIS page any more, so the
 *  files list here matches the real producer's, not the pre-task-033 shape. */
function assembleGraph() {
	const files = ['graph-model.js', 'graph-controls.js'];
	const ceiling = RD('canonical/aid/templates/graph/scale-ceiling.yml').match(/^node_ceiling:\s*(.*)$/m);
	const value = ceiling ? ceiling[1].trim() : '';
	const subs = {
		'{{LANG}}': 'en',
		'{{PROJECT_NAME}}': 'Graph view suite',
		'{{GENERATION_DATE}}': '2026-01-01',
		'{{SOURCE_STAMP}}': '<code>build-relationships.sh</code>',
		'{{INLINE_CSS}}': RD('canonical/aid/templates/knowledge-summary/component-css.css') + '\n\n' + G('graph-css.css'),
		'{{RELATIONSHIPS_BASE64}}': Buffer.from(FX.FIXTURE, 'utf8').toString('base64'),
		'{{INLINE_COVERAGE_PREDICATE}}': RD('canonical/aid/scripts/graph/coverage-predicate.mjs'),
		'{{INLINE_GRAPH_JS}}': files.map(G).join('\n'),
		'{{INLINE_LIGHTBOX_JS}}': RD('canonical/aid/templates/knowledge-summary/lightbox.js'),
		'{{PREREQUISITES}}': '\t\t<li>No network access is required and none is made.</li>',
		'{{SCALE_CEILING_NOTE}}': value === ''
			? '\t<p class="prereqs">No node-count ceiling is declared for this project.</p>'
			: '\t<p class="prereqs">This project declares a node-count ceiling of ' + value + '.</p>',
	};
	return substitute(G('graph-skeleton.html'), subs, 'graph-skeleton.html');
}

/** table.html -- mirrors build-table-src.mjs's own viewFiles list and prerequisite
 *  set (three facts, no {{SCALE_CEILING_NOTE}}: this page draws nothing). */
function assembleTable() {
	const files = ['graph-model.js', 'graph-controls.js', 'graph-table.js', 'table-view-shell.js'];
	const subs = {
		'{{LANG}}': 'en',
		'{{PROJECT_NAME}}': 'Graph view suite',
		'{{GENERATION_DATE}}': '2026-01-01',
		'{{SOURCE_STAMP}}': '<code>build-table-src.mjs</code>',
		'{{INLINE_CSS}}': RD('canonical/aid/templates/knowledge-summary/component-css.css') + '\n\n' + G('graph-css.css'),
		'{{RELATIONSHIPS_BASE64}}': Buffer.from(FX.FIXTURE, 'utf8').toString('base64'),
		'{{INLINE_COVERAGE_PREDICATE}}': RD('canonical/aid/scripts/graph/coverage-predicate.mjs'),
		'{{INLINE_TABLE_VIEW_JS}}': files.map(G).join('\n'),
		'{{INLINE_LIGHTBOX_JS}}': RD('canonical/aid/templates/knowledge-summary/lightbox.js'),
		'{{PREREQUISITES}}': '\t\t<li>No network access is required and none is made.</li>',
	};
	return substitute(G('table-view-skeleton.html'), subs, 'table-view-skeleton.html');
}

fs.mkdirSync(workDir, { recursive: true });
const graphHtml = assembleGraph();
fs.writeFileSync(path.join(workDir, 'graph.html'), graphHtml);
const tableHtml = assembleTable();
fs.writeFileSync(path.join(workDir, 'table.html'), tableHtml);
// Both pages' own relative-link checks resolve against the page's directory, so
// the three targets are written HERE as fixtures rather than borrowed from the
// repository's knowledge base -- the suite must not couple to KB content.
fs.writeFileSync(path.join(workDir, 'relationships.md'), FX.FIXTURE);
fs.writeFileSync(path.join(workDir, 'INDEX.md'), '# Knowledge Base index (suite fixture)\n');
fs.writeFileSync(path.join(workDir, 'external-sources.md'), '# External sources (suite fixture)\n\n## mdn-webgl\n');

// Assembly needs no DOM. It is separable on purpose: each page's structural,
// accessibility and link checks can then run over an assembled page on a
// machine with no jsdom at all, which is what keeps that group from skipping
// with this one.
if (process.argv.includes('--assemble-only')) {
	process.stdout.write('assembled=' + path.join(workDir, 'graph.html') + ' bytes=' + Buffer.byteLength(graphHtml) + '\n');
	process.stdout.write('assembled=' + path.join(workDir, 'table.html') + ' bytes=' + Buffer.byteLength(tableHtml) + '\n');
	process.exit(0);
}

// jsdom is resolved by its bare specifier, or from an explicit path in
// AID_GRAPH_JSDOM (its package entry module) for a machine where it is installed
// outside this tree's resolution path. Absent both, every class below SKIPS -- one
// recorded skip per class, and never a pass.
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
		+ 'package entry module to enable this half), so no DOM assertion in this class was run');
}

const M = await import(pathToFileURL(bundlePath).href);

// The table page's own executable module: `bundlePath`'s bytes (possibly
// mutated -- see the file header) with table-view-shell.js appended, never a
// second, independent disk read of the three files `bundlePath` already
// carries. table-view-shell.js is never a graph-view-mutate.mjs mutation
// target, so appending it unedited cannot mask or add a defect of its own.
const tableBundlePath = path.join(workDir, 'table-bundle.mjs');
fs.writeFileSync(tableBundlePath, fs.readFileSync(bundlePath, 'utf8') + '\n'
	+ RD('canonical/aid/templates/knowledge-graph/table-view-shell.js'));
const T = await import(pathToFileURL(tableBundlePath).href);

// ---------------------------------------------------------------------------
// A document, with the two page reads each view makes made answerable.
// Every call sets `globalThis.window`/`document` (and the constructors below)
// to the DOM it just built -- which is what makes `document.createElement`
// inside the bundle's own `el()` helper land in the right document. Anything
// that boots a second, throwaway document mid-section (mountFresh, the width
// crossing, the narrow form, the seam test) MUST restore these globals back to
// the section's own primary document before that section's next store call --
// exactly the discipline this file already needed with one page, now applied
// on both sides of the split.
// ---------------------------------------------------------------------------
function bootDom(html, url, narrow) {
	const dom = new JSDOM(html, {
		runScripts: 'dangerously', pretendToBeVisual: true,
		url: pathToFileURL(url).href,
	});
	const { window } = dom;
	globalThis.window = window;
	globalThis.document = window.document;
	globalThis.Event = window.Event;
	globalThis.KeyboardEvent = window.KeyboardEvent;
	globalThis.MouseEvent = window.MouseEvent;
	globalThis.getComputedStyle = window.getComputedStyle.bind(window);
	// jsdom's own matchMedia always answers false, which would leave the
	// below-breakpoint form of the Name cell untestable. Both sides are made
	// reachable, and a crossing is made firable.
	const listeners = [];
	const state = { narrow: !!narrow };
	window.matchMedia = (query) => ({
		media: query,
		get matches() { return query.indexOf('max-width: 768px') !== -1 ? state.narrow : false; },
		addEventListener(name, fn) { if (name === 'change') listeners.push(fn); },
		removeEventListener() {}, addListener(fn) { listeners.push(fn); }, removeListener() {},
	});
	// jsdom implements no scrolling, so the reveal's one call is RECORDED rather
	// than performed -- which is also what makes its arguments assertable.
	const scrolls = [];
	window.Element.prototype.scrollIntoView = function (options) { scrolls.push({ element: this, options: options }); };
	return {
		window, doc: window.document, scrolls,
		fire: (value) => { state.narrow = value; for (const fn of listeners) fn(); },
	};
}
function makeDom(narrow) { return bootDom(graphHtml, path.join(workDir, 'graph.html'), narrow); }
function makeTableDom(narrow) { return bootDom(tableHtml, path.join(workDir, 'table.html'), narrow); }

// ---------------------------------------------------------------------------
// GRAPH page boot -- used only by GV17a-d/GV22b/GV24 below, which assert the
// SHELL's own control manifest and stay on graph.html unchanged. No table
// region exists on this page any more (graph-controls.js's own mountShell
// handles that silently -- "the page declares no table region ... composed
// that way on purpose", its own comment), so no `region`/table reader is
// built for this half.
// ---------------------------------------------------------------------------
const realErrorGraphBoot = console.error;
console.error = () => {};
const wide = makeDom(false);
const store = M.mountShell(wide.doc);
console.error = realErrorGraphBoot;
const doc = wide.doc;
const vm = () => store.getViewModel();
const reset = () => store.setLens(M.INITIAL_LENS);

// ---------------------------------------------------------------------------
// TABLE page boot -- DT10-DT30 below assert the table RENDERING's own DOM
// contract, which now lives on table.html (task-033) rather than on
// graph.html (the owner removed it there, eedacc3d). Booted through
// `tbvMountShell`, this page's own purpose-built shell -- never `mountShell`,
// which builds a control surface this page does not have.
// ---------------------------------------------------------------------------
const consoleErrors = [];
const realError = console.error;
console.error = (...args) => { consoleErrors.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ')); };
const twide = makeTableDom(false);
const tstore = T.tbvMountShell(twide.doc);
console.error = realError;
const tdoc = twide.doc;
const tregion = tdoc.querySelector('[data-table-region]');
if (!tregion) {
	// A defensive FAIL rather than the uncaught TypeError this exact null
	// dereference produced before this file's own table/graph split: table.html
	// declares `[data-table-region]` unconditionally (table-view-skeleton.html),
	// so a null region here means that markup regressed, not that this suite
	// mis-assembled the page.
	process.stdout.write('GV\tFAIL\tDT00 harness — table.html has no [data-table-region] to mount into; '
		+ 'table-view-skeleton.html may have lost its unconditional mount point\n');
	process.exit(1);
}
const tvm = () => tstore.getViewModel();
const treset = () => tstore.setLens(T.INITIAL_LENS);

// ---------------------------------------------------------------------------
// Readers over the rendered table DOM
// ---------------------------------------------------------------------------
const listedTable = () => tregion.querySelector('table[data-relationship-table]');
const bodyRows = () => Array.from(tregion.querySelectorAll('table[data-relationship-table] tbody tr[data-row]'));
const colHeaders = () => Array.from(tregion.querySelectorAll('table[data-relationship-table] thead th'));
const renderedRows = () => bodyRows().map((tr) => ({
	row: Number(tr.getAttribute('data-row')),
	emphasis: tr.getAttribute('data-emphasis'),
	cells: Array.from(tr.children).map((c) => c.textContent),
	badges: Array.from(tr.querySelectorAll('.badge')).map((b) => b.textContent),
}));
const unlistedRows = () => Array.from(tregion.querySelectorAll('[data-unlisted-node]'));
const unlistedIds = () => unlistedRows().map((tr) => tr.getAttribute('data-unlisted-node'));
const selects = () => Array.from(tregion.querySelectorAll('[data-row-select]'));
const headerFor = (token) => tregion.querySelector('th[data-column="' + token + '"]');

/** Activate a control the way the platform's own Button pattern would, and report
 *  whether it IS that platform element. */
function activate(element) {
	const native = element.tagName === 'BUTTON' && element.getAttribute('type') === 'button' && !element.disabled;
	element.dispatchEvent(new twide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
	element.dispatchEvent(new twide.window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
	element.click();
	return native;
}

// ===========================================================================
ok('DT10', 'the table page boots into a document with no thrown error and no console error',
	!!tstore && consoleErrors.length === 0 && !!listedTable(), consoleErrors.join(' | ').slice(0, 160));

// task-034 slims the Relations table from the file's ten columns to six --
// Source Id, Target Id, S2T Relation, T2S Relation, Provenance, Observation --
// because node kind and node name now live on the Files tree and the
// Concepts table (one row per NODE) rather than repeating on every
// relationship row naming that node. `RELATIONS_HEADER` is this table's own
// six-column literal and is deliberately NOT `FX.HEADER` (the FILE's ten
// columns, unchanged): the two are different contracts now, by design
// (feature-009 SPEC.md D3, revised in the same change).
const RELATIONS_HEADER = '| Source Id | Target Id | S2T Relation | T2S Relation | Provenance | Observation |';

ok('DT11', 'the rendered region is a real table: caption first, thead, tbody, six column headers',
	listedTable().firstElementChild.tagName === 'CAPTION'
	&& !!listedTable().querySelector('thead') && !!listedTable().querySelector('tbody')
	&& colHeaders().length === 6 && colHeaders().every((th) => th.getAttribute('scope') === 'col'),
	colHeaders().length + ' column headers');
ok('DT11b', 'the six header labels reconstruct this table\'s own (slimmed) header literal',
	'| ' + colHeaders().map((th) => th.querySelector('button').textContent.replace(/[↕↑↓]/g, '').trim()).join(' | ') + ' |' === RELATIONS_HEADER,
	'| ' + colHeaders().map((th) => th.querySelector('button').textContent.replace(/[↕↑↓]/g, '').trim()).join(' | ') + ' |');
ok('DT11c', 'every body row is one row header plus five cells, and the count equals the drawn row count',
	bodyRows().length === tvm().counts.edges && bodyRows().length > 0
	&& bodyRows().every((tr) => tr.querySelectorAll('th[scope="row"]').length === 1 && tr.querySelectorAll('td').length === 5),
	bodyRows().length + ' rows');
ok('DT11d', 'every cell of every row carries the ViewModel value for that column',
	(() => {
		const viewModel = tvm();
		for (const tr of bodyRows()) {
			const row = Number(tr.getAttribute('data-row'));
			const edge = viewModel.visibleEdges.find((e) => e.row === row);
			const fold = viewModel.edgeFold.get(edge.key);
			const expect = [edge.sourceId, edge.targetId, edge.s2t, edge.t2s, edge.provenance, edge.observation];
			for (let i = 0; i < 6; i += 1) {
				if (expect[i] !== '' && tr.children[i].textContent.indexOf(expect[i]) === -1) return false;
			}
		}
		return true;
	})());

ok('DT12', 'aria-sort is on the listed table\'s six column headers and on NO other cell in the region',
	colHeaders().every((th) => th.getAttribute('aria-sort') === 'none')
	&& Array.from(tregion.querySelectorAll('th')).filter((th) => th.hasAttribute('aria-sort')).length === 6,
	Array.from(tregion.querySelectorAll('th')).filter((th) => th.hasAttribute('aria-sort')).length + ' th carry it');
ok('DT13', 'the region creates no third live region and carries neither shell control attribute',
	tregion.querySelectorAll('[aria-live], [role="alert"], [role="status"], [role="log"]').length === 0
	&& tregion.querySelectorAll('[data-control], [data-group-toggle]').length === 0);

const caption = () => listedTable().querySelector('caption');
// The table page ALWAYS opts into windowing (table-view-shell.js's own
// TBV_PAGE_SIZE), so graph-table.js's caption ALWAYS takes its WINDOWED
// opening sentence -- "Showing <shown> of <total> relationships. <hidden>
// more hidden ..." -- never the unwindowed "N relationships listed, N hidden"
// form graph.html's own (never-windowed) table mount used before this page
// existed. graph-table.js's own header names this a deliberate two-sentence
// split (tblCaption's own comment): the windowed sentence states what is
// ACTUALLY IN THE DOM, which for this fixture (13 rows, well under the 200-row
// window) means shown === total === bodyRows().length.
ok('DT14', 'the caption opens with the WINDOWED "Showing N of M" sentence and the hidden count, quotes the lens summary and cites the file',
	caption().textContent.indexOf('Showing ' + bodyRows().length + ' of ' + tvm().counts.edges + ' relationships. '
		+ tvm().counts.hiddenEdges + ' more hidden by the current filters. ') === 0
	&& caption().textContent.indexOf(tvm().lensSummary) !== -1
	&& !!caption().querySelector('a[href="./relationships.md"]'),
	caption().textContent.slice(0, 100));
ok('DT14b', 'the caption\'s link to the unlisted region is emitted with the region itself, so it cannot dangle',
	!!caption().querySelector('a[href="#graph-table-unlisted"]') && !!tdoc.getElementById('graph-table-unlisted'));

ok('DT15', 'the skip link is the region\'s FIRST element and targets the span after both tables',
	tregion.firstElementChild.tagName === 'A' && tregion.firstElementChild.getAttribute('href') === '#graph-table-end'
	&& !!tdoc.getElementById('graph-table-end')
	&& tdoc.getElementById('graph-table-end').getAttribute('tabindex') === '-1');
tdoc.getElementById('graph-table-end').focus();
ok('DT15b', 'and that target receives focus', tdoc.activeElement === tdoc.getElementById('graph-table-end'));

const focusables = () => Array.from(tregion.querySelectorAll('a[href], button, input, select, textarea, summary, [tabindex]'))
	.filter((e) => e.getAttribute('tabindex') !== '-1');
const expectedStops = () => 1 + 1 + (caption().querySelector('a[href^="#"]') ? 1 : 0)
	+ 6 + 2 * bodyRows().length + unlistedRows().length;
ok('DT16', 'the tab stops are exactly the skip link, the caption links, one per column header, two per listed row and one per unlisted row',
	focusables().length === expectedStops() && focusables().length > 20,
	focusables().length + ' vs ' + expectedStops());
ok('DT16b', 'no cell and no disclosure summary is focusable',
	tregion.querySelectorAll('td[tabindex], th[tabindex], summary').length === 0);
ok('DT16c', 'every link the region emits is a real href anchor, which Enter activates',
	Array.from(tregion.querySelectorAll('a')).every((a) => !!a.getAttribute('href')));

// --- The keyboard drive -----------------------------------------------------
let native = true;
const depthBefore = tstore.getLens()['focus.depth'];
let effects = 0;
const allSelects = selects();
for (const button of allSelects) {
	const id = button.getAttribute('data-row-select');
	native = activate(button) && native;
	if (tstore.getLens()['focus.nodeId'] === id && tstore.getLens()['focus.depth'] === depthBefore) effects += 1;
	treset();
}
ok('DT17', 'every select control, driven by keyboard alone, writes {focus.nodeId} and leaves focus.depth untouched',
	effects === allSelects.length && allSelects.length > 0 && native, effects + '/' + allSelects.length);
ok('DT17b', 'two select controls per listed row and one per unlisted row, none of them a shell control',
	bodyRows().every((tr) => tr.querySelectorAll('[data-row-select]').length === 2)
	&& unlistedRows().every((tr) => tr.querySelectorAll('[data-row-select]').length === 1)
	&& selects().every((b) => !b.hasAttribute('data-control')));
ok('DT17c', 'each select control names the endpoint by its FULL accessible name',
	selects().every((b) => b.getAttribute('aria-label') === 'Select ' + tvm().nodeLabels.get(b.getAttribute('data-row-select'))));

let sortNative = true;
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const ascending = headerFor('provenance').getAttribute('aria-sort');
const others = colHeaders().filter((th) => th.getAttribute('aria-sort') !== 'none').length;
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const descending = headerFor('provenance').getAttribute('aria-sort');
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const backToFile = colHeaders().every((th) => th.getAttribute('aria-sort') === 'none');
ok('DT18', 'activating a header three times reads ascending, descending, then none on all six',
	ascending === 'ascending' && others === 1 && descending === 'descending' && backToFile && sortNative,
	ascending + ' / ' + descending + ' / ' + (backToFile ? 'none x10' : 'not reset'));
ok('DT18b', 'and the third activation returns the control state to the file order',
	same(tstore.getLens()['sort'], { column: 'row', direction: 'asc' }), JSON.stringify(tstore.getLens()['sort']));
treset();

// --- Badges, and dimmed as the complement -----------------------------------
tstore.applyPreset('coverage');
const badgeTexts = ids(Array.from(tregion.querySelectorAll('tbody tr .badge')).map((b) => b.textContent));
const markedRows = bodyRows().filter((tr) => !!tr.querySelector('.badge'));
const dimmedRows = bodyRows().filter((tr) => tr.getAttribute('data-emphasis') === 'dimmed');
ok('DT19', 'the two gap classes render as distinct TEXT badges',
	badgeTexts.includes('no source') && badgeTexts.includes('no KB doc'), badgeTexts.join(','));
ok('DT19b', 'a badged row is never in the dimmed remainder, and the two sets partition the listed rows',
	markedRows.length > 0 && dimmedRows.length > 0
	&& markedRows.every((tr) => tr.getAttribute('data-emphasis') === 'normal')
	&& dimmedRows.every((tr) => !tr.querySelector('.badge'))
	&& markedRows.length + dimmedRows.length === bodyRows().length,
	markedRows.length + ' marked + ' + dimmedRows.length + ' dimmed = ' + bodyRows().length);
treset();
tstore.applyPreset('provenance');
ok('DT19c', 'the Provenance lens renders the chain badge as text on the S2T reading',
	Array.from(tregion.querySelectorAll('tbody tr td .badge')).some((b) => b.textContent === 'chain'));
treset();
tstore.setLens({ 'focus.nodeId': 'kb:alpha.md' });
ok('DT19d', 'a selection renders its own text badge',
	Array.from(tregion.querySelectorAll('.badge')).some((b) => b.textContent === 'selected'));
treset();

// --- The empty state --------------------------------------------------------
// `'focus.depth': 1` is EXPLICIT here (owner's 2026-08-07 default change): with
// no ball at all (focus.depth: null, the new default) a selection whose own
// rows a filter removed does not touch anyone else's, so the table would not
// empty. An explicit depth-1 ball around an isolated focus point (the filter
// leaves it no surviving edge to start a BFS from) is empty, which is what
// empties every row -- reproducing the property this id has always tested.
tstore.setLens(Object.assign({}, T.INITIAL_LENS, { 'filters.categories': ['structure'], 'focus.nodeId': FX.FILTERED_OUT_NODE, 'focus.depth': 1 }));
const empty = tregion.querySelector('tbody tr[data-empty-state]');
ok('DT20', 'an emptied table states why, spanning all six columns and quoting the lens summary',
	!!empty && empty.querySelector('td').getAttribute('colspan') === '6'
	&& empty.textContent.indexOf(tvm().lensSummary) !== -1
	&& empty.textContent.indexOf('Controls panel') !== -1 && !empty.querySelector('a'));
ok('DT20b', 'and the node it could not list is named in the unlisted region instead',
	unlistedIds().includes(FX.FILTERED_OUT_NODE), unlistedIds().join(','));
treset();
ok('DT20c', 'the empty-state row is absent whenever rows are listed', !tregion.querySelector('tbody tr[data-empty-state]'));

// --- The unlisted region ----------------------------------------------------
ok('DT21', 'the unlisted region is a real table with a caption, three column headers and a row header per row',
	!!tregion.querySelector('#graph-table-unlisted table caption')
	&& tregion.querySelectorAll('#graph-table-unlisted thead th[scope="col"]').length === 3
	&& unlistedRows().every((tr) => tr.querySelectorAll('th[scope="row"]').length === 1));
ok('DT21b', 'its three column headers wrap no sort control and carry no aria-sort',
	Array.from(tregion.querySelectorAll('#graph-table-unlisted thead th'))
		.every((th) => !th.hasAttribute('aria-sort') && !th.querySelector('button')));
ok('DT21c', 'the zero-row artifact\'s Name cell states the fact in words, from the projection',
	(() => {
		const row = tregion.querySelector('[data-unlisted-node="' + FX.ZERO_ROW_NODE + '"]');
		return !!row && row.children[2].textContent.indexOf('— no recorded relationships') !== -1;
	})());
ok('DT21d', 'every drawn node is named in the region -- in a listed row or in the unlisted table',
	(() => {
		for (const lens of [{}, { grouping: 'document' }, { emphasis: 'coverage' }]) {
			treset();
			if (Object.keys(lens).length) tstore.setLens(lens);
			// Target Id is column index 1 in the slimmed six-column layout
			// (Source Id, Target Id, S2T, T2S, Provenance, Observation) --
			// task-034 moved it from index 3 in the file's own ten.
			const named = ids(bodyRows().flatMap((tr) => [tr.children[0], tr.children[1]])
				.map((cell) => cell.querySelector('code').textContent).concat(unlistedIds()));
			const expect = ids(tvm().visibleNodes.map((n) => n.id));
			// An empty drawn set would satisfy the containment vacuously.
			if (expect.length === 0) return false;
			if (expect.some((id) => !named.includes(id))) return false;
		}
		return true;
	})());
treset();
tstore.setLens({ grouping: 'document' });
ok('DT21e', 'including a document whose every row the fold collapsed, whose degree is NOT zero',
	unlistedIds().includes(FX.FOLD_ONLY_NODE) && tstore.getGraphModel().nodes.get(FX.FOLD_ONLY_NODE).degree > 0,
	FX.FOLD_ONLY_NODE + ' degree ' + tstore.getGraphModel().nodes.get(FX.FOLD_ONLY_NODE).degree);
treset();

// --- The reveal -------------------------------------------------------------
function revealed(setup) {
	twide.scrolls.length = 0;
	const before = tdoc.activeElement;
	setup();
	const call = twide.scrolls[twide.scrolls.length - 1] || null;
	return { call: call, focusMoved: tdoc.activeElement !== before };
}
// Target Id is column index 1 in the slimmed six-column layout -- see DT21d's
// own note.
const firstRowNaming = (id) => renderedRows().find((r) => r.cells[0].indexOf(id) === 0 || r.cells[1].indexOf(id) === 0);
let r = revealed(() => { tregion.querySelector('[data-row-select="kb:concept:graph-view"]').click(); });
ok('DT22', 'a select brings the first row of the CURRENT order naming that node into view, instantly, moving no focus',
	!!r.call && r.call.options.behavior === 'instant'
	&& r.call.element.getAttribute('data-row') === String(firstRowNaming('kb:concept:graph-view').row)
	&& !r.focusMoved,
	r.call ? 'row ' + r.call.element.getAttribute('data-row') + ' ' + JSON.stringify(r.call.options) : 'no scroll');
ok('DT22b', 'and the scrolled element carries a scroll margin covering both sticky layers',
	!!r.call && /^\d+px$/.test(r.call.element.style.scrollMarginTop), r.call ? r.call.element.style.scrollMarginTop : 'none');
r = revealed(() => { tstore.setLens({ 'filters.text': '' }); });
ok('DT22c', 'a re-projection that leaves the marked id alone scrolls nothing', r.call === null);
treset();
tstore.setLens({ sort: { column: 'source-id', direction: 'desc' } });
r = revealed(() => { tregion.querySelector('[data-row-select="kb:alpha.md"]').click(); });
ok('DT22d', 'at a non-default sort the revealed row is the first of THAT order',
	!!r.call && r.call.element.getAttribute('data-row') === String(firstRowNaming('kb:alpha.md').row),
	r.call ? 'row ' + r.call.element.getAttribute('data-row') : 'no scroll');
treset();
r = revealed(() => { tstore.setLens({ grouping: 'document' }); tregion.querySelector('[data-row-select="' + FX.FOLD_ONLY_NODE + '"]').click(); });
ok('DT22e', 'where every row naming the node is collapsed, its unlisted-region row is revealed instead',
	!!r.call && r.call.element.getAttribute('data-unlisted-node') === FX.FOLD_ONLY_NODE
	&& r.call.options.behavior === 'instant' && !r.focusMoved);
treset();
tregion.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click();
tstore.applyPreset('coverage');
r = revealed(() => { tregion.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click(); });
ok('DT22f', 'a re-selection after a focus-clearing preset reveals AGAIN -- the clearing rule',
	tstore.getLens()['focus.nodeId'] === FX.FILTERED_OUT_NODE && !!r.call && !r.focusMoved);
treset();

// --- Determinism, the width crossing, and the peer contract ------------------
function mountFresh(lens) {
	const fresh = makeTableDom(false);
	const s = T.tbvMountShell(fresh.doc);
	if (lens) s.setLens(lens);
	const markup = fresh.doc.querySelector('[data-table-region]').innerHTML;
	return markup;
}
// 'target-name' no longer exists as a sort column (task-034 removed it from
// TBL_COLUMNS); 'target-id' is its replacement here -- same intent (a column
// other than the file's own order), still present after the slimming.
const lensForDeterminism = { grouping: 'document', emphasis: 'coverage', sort: { column: 'target-id', direction: 'desc' } };
const first = mountFresh(lensForDeterminism);
const second = mountFresh(lensForDeterminism);
globalThis.window = twide.window; globalThis.document = tdoc;
ok('DT24', 'two independent mounts at the same control state produce byte-identical markup',
	first === second && first.length > 1000, 'lengths ' + first.length + ' / ' + second.length);

const wq = makeTableDom(false);
const wqStore = T.tbvMountShell(wq.doc);
const wqRegion = wq.doc.querySelector('[data-table-region]');
// task-034 moves the responsive Name cell off the Relations table (which no
// longer has a Name column at all) onto the Files tree, so THAT is the region
// whose markup a width crossing now changes -- the Relations region's own
// markup is width-invariant by construction (none of its six columns reads
// `view.narrow`), which is the correct, and not merely coincidental, effect
// of the slimming.
const wqFilesRegion = wq.doc.querySelector('[data-files-region]');
const wideMarkup = wqRegion.innerHTML;
const wideFilesMarkup = wqFilesRegion ? wqFilesRegion.innerHTML : null;
const revisionBefore = wqStore.getViewModel().revision;
wq.scrolls.length = 0;
wq.fire(true);
const narrowMarkup = wqRegion.innerHTML;
const narrowFilesMarkup = wqFilesRegion ? wqFilesRegion.innerHTML : null;
wq.fire(false);
ok('DT25', 'a width crossing re-emits at the SAME revision, changes the Files region\'s markup, fires no second reveal, and reverses byte for byte',
	wqStore.getViewModel().revision === revisionBefore && narrowFilesMarkup !== wideFilesMarkup
	&& wq.scrolls.length === 0 && wqRegion.innerHTML === wideMarkup && wqFilesRegion.innerHTML === wideFilesMarkup,
	'revision ' + revisionBefore + ', scrolls ' + wq.scrolls.length);
globalThis.window = twide.window; globalThis.document = tdoc;

// DT26 WAS "the table region precedes the graph region in DOM order and
// neither is nested in the other" -- an ordering that made sense only while
// both renderings lived on one page. Since eedacc3d/task-033 they are on two
// separate pages, so an ordering claim between them is not a weaker test, it
// is a test of nothing: RETIRED as an ordering claim. Replaced, under the
// SAME id (test-graph-table-view.sh's own TV09b already cites DT26 for
// exactly this property), with the property that still matters now: this
// build carries no drawing rendering at all -- no <canvas> anywhere in
// table.html's own bundle, which never concatenates graph-canvas.js and never
// will (table-view-shell.js's own header) -- and the table still renders
// completely despite that.
ok('DT26', 'this build carries no drawing rendering at all (no <canvas> anywhere in the page), and the table still renders completely',
	tdoc.querySelector('canvas') === null && bodyRows().length > 0,
	bodyRows().length + ' rows listed, canvas present=' + (tdoc.querySelector('canvas') !== null));

// --- The responsive Name cell ------------------------------------------------
// task-034 moves node names -- and with them, the shortened-cell contract --
// off the Relations table (which no longer carries a Name column at all) and
// onto the Files tree / Concepts table (§ 13). `kb:alpha.md#fact:renderer-choice`
// is a `fact`, nested under `kb:alpha.md` in the Files tree, so this is where
// its Name cell now lives.
const tfilesRegion = tdoc.querySelector('[data-files-region]');
const shortForm = tstore.getGraphModel().nodes.get('kb:alpha.md#fact:renderer-choice').shortLabel;
const fullForm = tvm().nodeLabels.get('kb:alpha.md#fact:renderer-choice');
ok('DT27', 'above the breakpoint the shortened form appears nowhere in the Files region',
	shortForm.indexOf('…') !== -1 && !!tfilesRegion && tfilesRegion.textContent.indexOf(shortForm) === -1, shortForm);
const narrow = makeTableDom(true);
const narrowStore = T.tbvMountShell(narrow.doc);
const narrowRegion = narrow.doc.querySelector('[data-table-region]');
const narrowFilesRegion = narrow.doc.querySelector('[data-files-region]');
const factCell = narrowFilesRegion
	? Array.from(narrowFilesRegion.querySelectorAll('tr[data-tree-key] th, tr[data-tree-key] td'))
		.find((cell) => cell.textContent.indexOf(shortForm) !== -1)
	: null;
// The Files tree's own tree-guide spans ALSO carry aria-hidden="true" (they
// are presentation, per this file's own comment), so the short-label span is
// picked out by its TEXT rather than assumed to be the first aria-hidden
// child -- a plain `querySelector` here would grab an empty guide span
// instead and fail this assertion on a CORRECT implementation.
const shortSpan = factCell
	? Array.from(factCell.querySelectorAll('span[aria-hidden="true"]')).find((s) => s.textContent === shortForm)
	: null;
ok('DT27b', 'below it the visible text is the short label inside aria-hidden, with the full name in an .sr-only span beside it',
	!!shortSpan
	&& !!factCell.querySelector('span.sr-only') && factCell.querySelector('span.sr-only').textContent === fullForm
	&& factCell.textContent.indexOf(fullForm) !== -1);
ok('DT27c', 'the unlisted region shortens nothing at either width, and the shortening adds no tab stop',
	Array.from(narrowRegion.querySelectorAll('#graph-table-unlisted tbody tr')).map((tr) => tr.children[2])
		.every((td) => !td.querySelector('span[aria-hidden="true"]')
			&& td.textContent.indexOf(narrowStore.getViewModel().nodeLabels.get(td.parentElement.getAttribute('data-unlisted-node'))) === 0)
	&& Array.from(narrowRegion.querySelectorAll('span[tabindex]')).filter((s) => s.getAttribute('tabindex') !== '-1').length === 0);
globalThis.window = twide.window; globalThis.document = tdoc;

// `[data-counts]` WAS this id's own final clause -- "so the shell can still
// write its counts". That element is graph-controls.js's own mountShell
// writing into graph-skeleton.html's region-head (grep confirms it: the ONLY
// author of `data-counts` is `mountShell`, and the ONLY skeleton declaring
// that span is graph-skeleton.html). table-view-skeleton.html's own
// region-head never carried one -- there is no shell on this page to write
// it. And unlike the old combined page (where `[data-table-region]` was the
// WHOLE `<section>`, per eedacc3d~1, so `.region-head` was ITS OWN
// descendant), table-view-skeleton.html's `[data-table-region]` is a plain
// `<div>` and `.region-head` is its SIBLING under `.graph-region` -- so this
// id now reads `tdoc`, not `tregion`, to reach it at all.
ok('DT28', 'the region\'s authored head (its own <h2>) survives the mount untouched -- mountTable only ever '
	+ 'writes into [data-table-region] itself, never its .region-head sibling',
	!!tdoc.querySelector('.region-head h2') && tdoc.querySelector('.region-head h2').textContent.trim() !== '',
	tdoc.querySelector('.region-head h2') ? tdoc.querySelector('.region-head h2').textContent : '(none)');

// --- The seam: identity of the projection, and the private row order ---------
const direct = makeTableDom(false);
globalThis.window = direct.window; globalThis.document = direct.doc;
const directModel = T.parseRelationships(FX.FIXTURE);
const directStore = T.createStore(directModel, T.INITIAL_LENS);
const directRegion = direct.doc.querySelector('[data-table-region]');
const handle = T.mountTable({
	store: directStore, graphModel: directModel, region: directRegion,
	surface: direct.doc.querySelector('[data-graph-surface]'), root: direct.doc,
});
let identity = handle.renderedFrom === directStore.getViewModel();
for (const preset of Object.keys(T.PRESETS)) {
	directStore.applyPreset(preset);
	if (handle.renderedFrom !== directStore.getViewModel()) identity = false;
}
ok('DT29', 'the rendered projection IS the store\'s current ViewModel instance, initially and after every preset',
	identity && !!directRegion.querySelector('table[data-relationship-table]'));
directStore.setLens(T.INITIAL_LENS);
ok('DT29b', 'the row order is cached against the revision alone',
	handle.rowOrder.orderedFor === directStore.getViewModel().revision);
directRegion.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click();
const recorded = handle.rowOrder.focusRevealed;
directStore.applyPreset('coverage');
ok('DT29c', 'a select records the revealed id, and a rebuild finding no marked id clears it',
	recorded === FX.FILTERED_OUT_NODE && handle.rowOrder.focusRevealed === null,
	recorded + ' -> ' + String(handle.rowOrder.focusRevealed));

// Table half done -- hand `globalThis.window`/`document` back to the GRAPH
// page's own primary document before GV17a-d/GV22b/GV24 run: those blocks'
// `reset()` (== `store.setLens(M.INITIAL_LENS)`) needs `document` to resolve
// to graph.html's own document for its re-render, exactly the discipline this
// file's own header names.
globalThis.window = wide.window; globalThis.document = doc;

// ===========================================================================
// GV17 -- the CONTROL_MANIFEST<->DOM `data-control` bijection over a generated
// `graph.html`, every matched element focusable, each driven by keyboard input
// alone with its LensState effect asserted (the seven viewport entries with
// AND without a registered viewport handle), and every `data-group-toggle`
// element focusable and keyboard-operable (its COMPLETENESS is GV22b's).
// Asserted at both gate widths, so the mobile <details> collapse markup
// cannot be read as dropping either kind -- jsdom implements no layout, so
// this reads the TREE, not the paint, which is exactly this file's own
// stated limit (see the file header).
// ===========================================================================
{
	function isNativeFocusable(e) {
		if (e.hasAttribute('disabled') || e.getAttribute('tabindex') === '-1') return false;
		if (e.tagName === 'BUTTON') return e.getAttribute('type') === 'button';
		return e.tagName === 'SELECT' || e.tagName === 'INPUT';
	}
	function controlEls(document) { return Array.from(document.querySelectorAll('[' + M.CONTROL_ATTR + ']')); }

	reset();
	const manifestIds17 = ids(M.shellState.manifest.map((e) => e.id));
	const wideEls = controlEls(doc);
	const wideIds = wideEls.map((e) => e.getAttribute(M.CONTROL_ATTR));
	const bijectionWide = same(ids(wideIds), manifestIds17) && new Set(wideIds).size === wideIds.length;
	const focusableWide = wideEls.every(isNativeFocusable);

	const narrowDom17 = makeDom(true);
	const narrowStore17 = M.mountShell(narrowDom17.doc);
	const narrowEls17 = controlEls(narrowDom17.doc);
	const narrowIds17 = narrowEls17.map((e) => e.getAttribute(M.CONTROL_ATTR));
	const bijectionNarrow = same(ids(narrowIds17), manifestIds17) && new Set(narrowIds17).size === narrowIds17.length;
	const focusableNarrow = narrowEls17.every(isNativeFocusable);
	void narrowStore17;

	ok('GV17a', 'the manifest\'s id set and the DOM\'s data-control id set are the SAME set with no duplicate on either side, at both the wide and the narrow gate width, and every matched element is a native, enabled, focusable control',
		manifestIds17.length > 0 && bijectionWide && focusableWide && bijectionNarrow && focusableNarrow,
		manifestIds17.length + ' manifest ids, ' + wideIds.length + ' wide / ' + narrowIds17.length + ' narrow data-control elements');

	// --- Every non-viewport entry driven by keyboard input alone, its
	// LensState effect asserted. `reset()` runs immediately before each entry,
	// so the effect measured is that entry's alone and not a residue of the one
	// before it. Non-vacuous by construction: every driven value is chosen to
	// DIFFER from the control's own current (default) value, so an unwired
	// handler leaves `before === after` and the drive is reported as failed --
	// verified during authorship by disabling the spacing handler in a SCRATCH
	// copy of graph-controls.js (never the source tree, S5) and confirming this
	// exact check goes red against it. ---
	function drive(entry) {
		reset();
		const el = doc.querySelector('[' + M.CONTROL_ATTR + '="' + entry.id + '"]');
		if (!el) return { ok: false, why: 'no element' };
		if (!isNativeFocusable(el)) return { ok: false, why: 'not a native focusable control' };
		const axis = entry.axis;
		if (axis === 'preset') {
			const before = store.getLens().preset;
			el.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
			el.click();
			return { ok: store.getLens().preset === entry.value && entry.value !== before };
		}
		if (axis === 'filters.categories' || axis === 'filters.kinds' || axis === 'filters.provenance') {
			// Space toggles a checkbox exactly like a click, in every browser.
			const before = store.getLens()[axis].includes(entry.value);
			el.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
			el.click();
			const after = store.getLens()[axis].includes(entry.value);
			return { ok: after !== before };
		}
		if (axis === 'viewport') return null; // asserted separately below, with/without a handle
		// The nine AUTHORED, non-enumerable controls: one entry, one id, driven by
		// the id rather than the axis -- each keyboard-consistent per this file's
		// own stated mechanical limit (a select's/range's/number's real keyboard
		// behaviour is a value write plus the event that write fires, jsdom
		// synthesising neither the arrow-key nor the native selection change).
		switch (entry.id) {
			case 'grouping': {
				const before = store.getLens().grouping;
				const next = Array.from(el.options).map((o) => o.value).find((v) => v !== before);
				el.value = next;
				el.dispatchEvent(new wide.window.Event('change', { bubbles: true }));
				return { ok: store.getLens().grouping === next && next !== before };
			}
			case 'spacing': {
				const before = store.getLens().spacing;
				el.value = String(before + 1 > 5 ? before - 1 : before + 1);
				el.dispatchEvent(new wide.window.Event('input', { bubbles: true }));
				return { ok: store.getLens().spacing === Number(el.value) && Number(el.value) !== before };
			}
			case 'focus-node': {
				const opt = Array.from(el.options).find((o) => o.value !== '');
				el.value = opt.value;
				el.dispatchEvent(new wide.window.Event('change', { bubbles: true }));
				return { ok: store.getLens()['focus.nodeId'] === opt.value };
			}
			case 'focus-depth': {
				// A `range`, driven by `input` like every other slider in this switch --
				// not `change`, which is what it fired back when it was a `number`
				// input. Two writes rather than one: first a non-zero level, to prove
				// the default (null, drawn as 0) actually moves; then 0 itself, because
				// 0 is not "depth zero" but the control's own spelling of "no limit" and
				// has to write `null`, not the number 0 -- the one clause this case
				// exists to catch since the promotion off the old capped `number` input.
				const before = store.getLens()['focus.depth'];
				el.value = '5';
				el.dispatchEvent(new wide.window.Event('input', { bubbles: true }));
				const wroteFive = store.getLens()['focus.depth'] === 5 && 5 !== before;
				el.value = '0';
				el.dispatchEvent(new wide.window.Event('input', { bubbles: true }));
				const wroteNull = store.getLens()['focus.depth'] === null;
				return { ok: wroteFive && wroteNull, why: 'wroteFive=' + wroteFive + ' wroteNull=' + wroteNull };
			}
			// The two plain boolean checkboxes. Same gesture, different lens key, so the
			// key is LOOKED UP rather than the case being copied -- a copied case is how
			// the second checkbox ends up asserting the first one's key and passing
			// green without ever reading its own.
			case 'filter-show-orphans':
			case 'filter-show-hub': {
				const lensKey = { 'filter-show-orphans': 'filters.showOrphans', 'filter-show-hub': 'filters.showHub' }[entry.id];
				const before = store.getLens()[lensKey];
				el.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
				el.click();
				return { ok: store.getLens()[lensKey] === !before, why: lensKey + ' ' + before + ' -> ' + store.getLens()[lensKey] };
			}
			case 'node-select': {
				// Isolated from the paired select's OWN 'change' handler (D7's first
				// gesture): the select's value is written directly with no 'change'
				// dispatched, so only the button's own click can be responsible for
				// the effect measured here.
				const focusSelectEl = doc.querySelector('[' + M.CONTROL_ATTR + '="focus-node"]');
				const opt = Array.from(focusSelectEl.options).find((o) => o.value !== '');
				focusSelectEl.value = opt.value;
				el.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
				el.click();
				return { ok: store.getLens()['focus.nodeId'] === opt.value };
			}
			case 'node-open': {
				// D7's second gesture opens a target rather than writing LensState, so
				// its "effect" is the CALL it makes -- observed by a spy on the
				// store's own openTarget (the store object is a plain, unfrozen
				// literal; the click handler reads `store.openTarget` at call time,
				// so the override is seen), restored immediately after. jsdom's own
				// "navigation not implemented" notice on the resulting
				// `window.location.href` write is expected, not a defect, and is
				// suppressed here the same way DT10 suppresses console.error during
				// boot.
				store.setLens({ 'focus.nodeId': 'kb:alpha.md' });
				const realOpenTarget = store.openTarget;
				let calledWith = null;
				store.openTarget = (id) => { calledWith = id; return realOpenTarget(id); };
				const realConsoleError = console.error;
				console.error = () => {};
				el.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
				el.click();
				console.error = realConsoleError;
				store.openTarget = realOpenTarget;
				return { ok: calledWith === 'kb:alpha.md' };
			}
			case 'filter-text': {
				el.value = 'gv17-probe';
				el.dispatchEvent(new wide.window.Event('input', { bubbles: true }));
				return { ok: store.getLens()['filters.text'] === 'gv17-probe' };
			}
			default:
				return { ok: false, why: 'unhandled id: ' + entry.id };
		}
	}
	const nonViewportEntries = M.shellState.manifest.filter((e) => e.axis !== 'viewport');
	const driveResults = nonViewportEntries.map((e) => ({ entry: e, result: drive(e) }));
	const driveFailures = driveResults.filter((d) => !d.result || !d.result.ok);
	reset();
	ok('GV17b', 'every non-viewport manifest entry (' + nonViewportEntries.length + ' of them, covering every enumerable axis plus the ten authored controls) is driven by keyboard input alone and writes the LensState effect its own handler declares',
		nonViewportEntries.length > 0 && driveFailures.length === 0,
		driveFailures.map((d) => d.entry.id + (d.result ? ' (' + d.result.why + ')' : ' (no result)')).join(', '));

	// --- The viewport axis: EMPTY, by the owner's decision on 2026-08-06.
	//
	// This hook used to assert that all seven viewport buttons (zoom in/out/fit,
	// pan left/right/up/down) were present, focusable and wired to the
	// `shellState.viewport` handle. Those buttons are gone -- the owner removed
	// them from the panel because the mouse gestures (wheel to zoom, drag to pan)
	// do the same job without spending a third of the panel's height on it.
	//
	// So the assertion is INVERTED rather than deleted, and that matters: an
	// emptied enumerable axis is exactly the kind of change that leaves other
	// assertions passing VACUOUSLY (GV24 below maps over this axis and its
	// `.every()` goes trivially true on an empty array). Asserting the emptiness
	// directly is what stops "no controls" from reading the same as "controls all
	// fine" -- and it goes red the moment an entry reappears in the manifest
	// without a DOM control to match, which is the bijection GV17a guards.
	//
	// What is NOT asserted here any more, deliberately: that a registered
	// `shellState.viewport` handle writes zoom. Nothing in the shell calls
	// `viewportFor` now, so there is no production path left to exercise -- and a
	// test that called the handle itself would be asserting the test's own call,
	// not the shell's. The consequence for keyboard users is real and is recorded
	// as tech debt (W5-16), not hidden behind a green test.
	reset();
	const viewportEntries = M.shellState.manifest.filter((e) => e.axis === 'viewport');
	const viewportDomControls = Array.from(doc.querySelectorAll('[' + M.CONTROL_ATTR + ']'))
		.filter((el) => M.VIEWPORT_ACTIONS.includes(el.getAttribute(M.CONTROL_ATTR)));
	const handleSeamIntact = typeof M.shellState.viewport !== 'undefined';
	reset();
	ok('GV17c', 'the viewport axis is empty in BOTH the manifest and the DOM -- zero viewport entries, and not one control carrying any of the seven viewport action ids -- so the removed buttons cannot silently return, and the `shellState.viewport` seam still exists for a future re-wiring',
		viewportEntries.length === 0 && viewportDomControls.length === 0 && handleSeamIntact,
		viewportEntries.length + ' manifest entries, ' + viewportDomControls.length + ' DOM controls ('
			+ viewportDomControls.map((el) => el.getAttribute(M.CONTROL_ATTR)).join(', ') + '), seam=' + handleSeamIntact);

	// --- The density axis: GONE, by the owner's decision on 2026-08-07 -- the
	// same vacuity shape GV17c guards for the viewport axis, over the control
	// that used to filter nodes by connection count. Asserted directly, in
	// both the manifest and the DOM, rather than left to read as an absence
	// nothing checks: a stray `data-control="density"` element (or a manifest
	// entry naming it) would otherwise pass every OTHER check silently, the
	// same way a returned viewport button would have before GV17c existed.
	reset();
	const densityManifestEntries = M.shellState.manifest.filter((e) => e.id === 'density' || e.axis === 'density');
	const densityDomControls = Array.from(doc.querySelectorAll('[' + M.CONTROL_ATTR + '="density"]'));
	reset();
	ok('GV33', 'the density axis is empty in BOTH the manifest and the DOM -- zero manifest entries naming it and not one element carrying data-control="density" -- so the removed degree filter cannot silently return',
		densityManifestEntries.length === 0 && densityDomControls.length === 0,
		densityManifestEntries.length + ' manifest entries, ' + densityDomControls.length + ' DOM controls');

	// --- The `focus-depth` control's `max` attribute is DEPTH_MAX itself, never
	// a re-typed literal: a ceiling change in graph-model.js that left the
	// control's own markup behind would otherwise let the reader's slider
	// promise a depth the projection silently clamps below.
	reset();
	const depthEl34 = doc.querySelector('[' + M.CONTROL_ATTR + '="focus-depth"]');
	const depthMaxAttr = depthEl34 ? depthEl34.getAttribute('max') : null;
	reset();
	ok('GV34', 'the focus-depth control is a range whose max attribute equals DEPTH_MAX (' + M.DEPTH_MAX + '), read from the constant rather than asserted as a literal',
		!!depthEl34 && depthEl34.tagName === 'INPUT' && depthEl34.getAttribute('type') === 'range'
		&& depthMaxAttr === String(M.DEPTH_MAX),
		'tag=' + (depthEl34 ? depthEl34.tagName : null) + ' type=' + (depthEl34 ? depthEl34.getAttribute('type') : null) + ' max=' + depthMaxAttr);

	// --- Group-toggle completeness is GV22b's; here only presence,
	// focusability and keyboard-operability, over a lens with at least one
	// foldable group (grouping: 'document', where the fixture guarantees one --
	// see GV22a in graph-view-gv.mjs). ---
	reset();
	store.setLens({ grouping: 'document' });
	const toggles17 = Array.from(doc.querySelectorAll('[' + M.GROUP_TOGGLE_ATTR + ']'));
	const toggleFocusable = toggles17.length > 0 && toggles17.every(isNativeFocusable);
	const toggleKey17 = toggles17[0] ? toggles17[0].getAttribute(M.GROUP_TOGGLE_ATTR) : null;
	const beforeExpanded17 = toggles17[0] ? toggles17[0].getAttribute('aria-expanded') : null;
	if (toggles17[0]) {
		toggles17[0].dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
		toggles17[0].click();
	}
	// The click's own handler rebuilds the group host from scratch (renderGroups
	// clears and repopulates it), so the ELEMENT captured before the click is
	// detached afterward -- the toggle carrying the same key is re-queried
	// rather than read off the stale reference (a defect this exact block
	// caught in itself during authorship, before it ever reached this file).
	const toggleAfter17 = toggleKey17 ? doc.querySelector('[' + M.GROUP_TOGGLE_ATTR + '="' + toggleKey17 + '"]') : null;
	const afterExpanded17 = toggleAfter17 ? toggleAfter17.getAttribute('aria-expanded') : null;
	reset();
	ok('GV17d', 'at least one data-group-toggle element exists under a foldable grouping, every one present is a native focusable button, and activating one flips its own aria-expanded',
		toggleFocusable && beforeExpanded17 !== null && afterExpanded17 !== null && beforeExpanded17 !== afterExpanded17,
		toggles17.length + ' toggles, ' + beforeExpanded17 + ' -> ' + afterExpanded17);
}

// ===========================================================================
// GV22b -- the one DOM-shaped clause of GV22 (D6c, FR-13, D8, AC-8): exactly
// one focusable `data-group-toggle` element exists per group whose `foldable`
// is non-zero -- before AND after an expansion -- and none for any other
// group. Every OTHER clause of GV22 (foldedInto, groups[].foldable/expanded,
// edgeFold, counts, the focus-through-the-fold precedence, and the absence of
// any fold under the four other dimensions) is a plain GraphModel/ViewModel
// property and is asserted headless as GV22a in graph-view-gv.mjs -- see that
// block's own header for why task-014 STAGE 3's "needs a real DOM"
// classification over-scoped this id.
// ===========================================================================
{
	function isNativeFocusable22(e) {
		if (e.hasAttribute('disabled') || e.getAttribute('tabindex') === '-1') return false;
		if (e.tagName === 'BUTTON') return e.getAttribute('type') === 'button';
		return e.tagName === 'SELECT' || e.tagName === 'INPUT';
	}
	reset();
	store.setLens({ grouping: 'document' });
	const vmGroups22 = vm();
	const foldableGroups22 = vmGroups22.groups.filter((g) => g.foldable > 0).map((g) => g.key);
	const nonFoldableGroups22 = vmGroups22.groups.filter((g) => g.foldable === 0).map((g) => g.key);

	function toggleCountsMatch22() {
		const toggleEls = Array.from(doc.querySelectorAll('[' + M.GROUP_TOGGLE_ATTR + ']'));
		const toggleKeys = toggleEls.map((e) => e.getAttribute(M.GROUP_TOGGLE_ATTR));
		const exactlyOneEach = foldableGroups22.every((key) => toggleKeys.filter((k) => k === key).length === 1);
		const noneForOthers = nonFoldableGroups22.every((key) => !toggleKeys.includes(key));
		const allFocusable = toggleEls.every(isNativeFocusable22);
		return exactlyOneEach && noneForOthers && allFocusable && toggleKeys.length === foldableGroups22.length;
	}
	const beforeOk22 = toggleCountsMatch22();

	// Expand exactly one foldable group and re-check the SAME invariant --
	// verified during authorship to be decisive by adding a stray
	// data-group-toggle attribute to an arbitrary non-foldable-group element
	// and confirming `noneForOthers` catches it.
	const target22 = foldableGroups22[0];
	store.setLens({ expandedGroups: [target22] });
	const afterOk22 = toggleCountsMatch22();

	reset();
	ok('GV22b', 'exactly one focusable data-group-toggle element exists per group whose foldable is non-zero, and none for any other group -- both BEFORE and AFTER expanding one of them',
		foldableGroups22.length >= 2 && beforeOk22 && afterOk22,
		'foldable=' + foldableGroups22.join(',') + ' nonfoldable=' + nonFoldableGroups22.length
		+ ' before=' + beforeOk22 + ' after=' + afterOk22);
}

// ===========================================================================
// GV24 -- after each of the four presets is applied, the grouping <select>,
// the spacing range, every zoom/pan keyboard control and every filter control
// is present and NOT disabled, and a subsequent write to each still changes
// LensState -- AC-8's "then all of them remain usable" over every control the
// criterion names. The zoom/pan controls' write goes through the viewport
// handle (D8, the same seam GV17c exercises), so that half is asserted with
// one registered. GV15 asserts a DIFFERENT property (a preset does not RESET
// a filter); this id asserts that every control class stays USABLE, which
// GV15's own fixture does not check.
// ===========================================================================
{
	function isNativeFocusable24(e) {
		if (e.hasAttribute('disabled') || e.getAttribute('tabindex') === '-1') return false;
		if (e.tagName === 'BUTTON') return e.getAttribute('type') === 'button';
		return e.tagName === 'SELECT' || e.tagName === 'INPUT';
	}
	// No `shellState.viewport` stub is installed: nothing this hook drives reads
	// it now that the viewport buttons are gone, and setup that no assertion
	// depends on is just a claim that something is exercised when it is not.
	const perPreset = [];
	for (const presetName of Object.keys(M.PRESETS)) {
		reset();
		store.applyPreset(presetName);

		const groupingEl = doc.querySelector('[' + M.CONTROL_ATTR + '="grouping"]');
		const spacingEl = doc.querySelector('[' + M.CONTROL_ATTR + '="spacing"]');
		// The viewport axis is intentionally empty (the owner removed the seven
		// buttons on 2026-08-06), so it is NOT mapped over here. Mapping an empty
		// axis and calling `.every(Boolean)` on the result reads green while
		// proving nothing -- the vacuity trap. Its emptiness is asserted once, and
		// on purpose, by GV17c above.
		const filterEls = M.shellState.manifest.filter((e) => ['filters.categories', 'filters.kinds', 'filters.provenance'].includes(e.axis))
			.map((e) => doc.querySelector('[' + M.CONTROL_ATTR + '="' + e.id + '"]'));

		const allPresent = !!groupingEl && !!spacingEl && filterEls.every(Boolean);
		const allEnabled = allPresent && isNativeFocusable24(groupingEl) && isNativeFocusable24(spacingEl)
			&& filterEls.every(isNativeFocusable24);

		// A write to each changes LensState -- proven by driving one of each kind
		// and requiring the value to move from what THIS preset itself set it to.
		const groupingBefore = store.getLens().grouping;
		const groupingNext = Array.from(groupingEl.options).map((o) => o.value).find((v) => v !== groupingBefore);
		groupingEl.value = groupingNext;
		groupingEl.dispatchEvent(new wide.window.Event('change', { bubbles: true }));
		const groupingWrote = store.getLens().grouping === groupingNext && groupingNext !== groupingBefore;

		const spacingBefore = store.getLens().spacing;
		spacingEl.value = String(spacingBefore + 1 > 5 ? spacingBefore - 1 : spacingBefore + 1);
		spacingEl.dispatchEvent(new wide.window.Event('input', { bubbles: true }));
		const spacingWrote = store.getLens().spacing === Number(spacingEl.value) && Number(spacingEl.value) !== spacingBefore;

		// The viewport write is not driven here: with the seven buttons removed
		// there is no control to drive, and `viewportEls[0]` would be `undefined`
		// -- a TypeError, not a clean red. GV17c asserts the axis is empty.

		const filterEntry = M.shellState.manifest.filter((e) => ['filters.categories', 'filters.kinds', 'filters.provenance'].includes(e.axis))[0];
		const filterAxisBefore = store.getLens()[filterEntry.axis].includes(filterEntry.value);
		filterEls[0].dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
		filterEls[0].click();
		const filterAxisAfter = store.getLens()[filterEntry.axis].includes(filterEntry.value);
		const filterWrote = filterAxisAfter !== filterAxisBefore;

		perPreset.push({
			preset: presetName, allPresent, allEnabled, groupingWrote, spacingWrote, filterWrote,
			ok: allPresent && allEnabled && groupingWrote && spacingWrote && filterWrote,
		});
	}
	reset();
	const failing24 = perPreset.filter((p) => !p.ok);
	ok('GV24', 'after each of the four presets, the grouping select, the spacing range and every filters.categories/kinds/provenance control stays present and enabled, and a write to one of each kind still changes LensState (the viewport entries are excluded because there are none -- see GV17c)',
		perPreset.length === 4 && failing24.length === 0,
		JSON.stringify(perPreset));
}

// ===========================================================================
// GV29 -- ledger row 1's fix, proven past the pure function. `resolveHiddenSelection`
// returning `suppressed: true` (TFC11's own subject) is necessary but not
// sufficient: the reviewer's first-pass finding was that `restoreHiddenSelection`'s
// notice into `[data-conflicts]` was written, then unconditionally erased eight
// lines later by `reportConflicts`'s own `clear(host)` on the SAME element --
// so the graph page reported NOTHING for a suppressed selection while every
// existing check (which only ever drove the pure function in isolation) still
// passed. This is the one check that drives the defect's own reproduction
// route -- a REAL localStorage, seeded before a REAL `mountShell()` boot --
// past the point the bug lived, past `reportConflicts`, to the notice a reader
// would actually see.
//
// Needs a document booted at an `http://` URL: jsdom throws SecurityError on
// ANY `localStorage` access under `file://`'s opaque origin (the same
// limitation graph-table-files-check.mjs's own header documents), so this
// section boots its OWN fresh document rather than reusing `wide` (booted at
// a `file://` path for the rest of this file's classes) and restores every
// global it touches afterwards -- the same discipline `mountFresh` and the
// width-crossing sections already follow.
// ===========================================================================
{
	const priorLocalStorage = globalThis.localStorage;
	const priorLocation = globalThis.location;

	const suppressDom = new JSDOM(graphHtml, {
		runScripts: 'dangerously', pretendToBeVisual: true,
		url: 'http://localhost/project/.aid/knowledge/graph.html',
	});
	globalThis.window = suppressDom.window;
	globalThis.document = suppressDom.window.document;
	globalThis.localStorage = suppressDom.window.localStorage;
	globalThis.location = suppressDom.window.location;
	globalThis.Event = suppressDom.window.Event;
	globalThis.KeyboardEvent = suppressDom.window.KeyboardEvent;
	globalThis.MouseEvent = suppressDom.window.MouseEvent;
	globalThis.getComputedStyle = suppressDom.window.getComputedStyle.bind(suppressDom.window);
	suppressDom.window.matchMedia = () => ({
		matches: false, media: '',
		addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {},
	});

	// Every real node id THIS fixture's graph.html carries -- read from the
	// already-booted `wide` store rather than re-parsed, since both documents
	// embed the identical FX.FIXTURE payload. The actual "hide everything"
	// case, not a stand-in for it.
	const everyRealId = Array.from(store.getGraphModel().nodes.keys());
	suppressDom.window.localStorage.setItem(
		M.hiddenSelectionKey(suppressDom.window.location.pathname),
		JSON.stringify(everyRealId));

	const realConsoleError29 = console.error;
	console.error = () => {};
	const suppressStore = M.mountShell(suppressDom.window.document);
	console.error = realConsoleError29;

	const conflictsHost = suppressDom.window.document.querySelector('[data-conflicts]');
	const notice = conflictsHost
		? Array.from(conflictsHost.querySelectorAll('h4'))
			.find((h) => h.textContent === 'A saved selection would have hidden everything, so nothing was hidden')
		: null;
	const hiddenIdsAfter = suppressStore ? suppressStore.getLens()['filters.hiddenIds'] : undefined;

	ok('GV29', 'a stored selection naming every node survives a full mountShell() boot as a visible notice in [data-conflicts] (ledger row 1), and filters.hiddenIds stays empty -- nothing was actually hidden',
		!!suppressStore && !!notice && Array.isArray(hiddenIdsAfter) && hiddenIdsAfter.length === 0,
		'notice ' + (notice ? 'present' : 'ABSENT') + ', hiddenIds ' + JSON.stringify(hiddenIdsAfter));

	globalThis.localStorage = priorLocalStorage;
	globalThis.location = priorLocation;
	globalThis.window = wide.window;
	globalThis.document = doc;
	globalThis.getComputedStyle = wide.window.getComputedStyle.bind(wide.window);
}

// ---------------------------------------------------------------------------
// The two rendered pages, written out for the bash side's validator run, and
// the in-page anchor check performed HERE, against table.html -- the page
// whose dynamically-rendered anchors (the skip link, the caption's link to
// the unlisted region) actually exist. graph.html's own in-page anchor set is
// the one static, unconditional `#top` skip link (its own `<main id="top">`
// is authored, never generated), which needs no DOM proof.
//
// WHY THE ANCHOR CHECK IS HERE AND NOT LEFT TO THE PAGE VALIDATOR
//   validate-html-output.sh's L1 builds a bash associative array keyed on every
//   `id="..."` SUBSTRING it can find, and aborts with `bad array subscript` on an
//   empty key. A serialized DOM writes valueless attributes as `attr=""`, and the
//   shell's own `data-controls-grid` then contains the substring `id=""` -- so L1
//   cannot run over the rendered page at all (either page: both skeletons declare
//   that attribute). That defect is routed to feature-011; it is NOT worked
//   around silently. The obligation itself -- every in-page href resolves to an
//   id in the page -- is asserted here instead, over the same rendered markup,
//   and the bash side skips the shipped L1 loudly.
// ---------------------------------------------------------------------------
globalThis.window = twide.window; globalThis.document = tdoc;
treset();
const tableRendered = '<!DOCTYPE html>\n' + tdoc.documentElement.outerHTML;
fs.writeFileSync(path.join(workDir, 'table-rendered.html'), tableRendered);
const anchors = ids((tableRendered.match(/href="#[^"]+"/g) || []).map((h) => h.slice(7, -1)));
const idAttrs = new Set((tableRendered.match(/\sid="[^"]*"/g) || []).map((a) => a.slice(5, -1)));
const dangling = anchors.filter((a) => !idAttrs.has(a));
// The floor is table.html's own real anchor count (the static `#top` skip
// link, plus the table rendering's own skip link -> #graph-table-end and its
// caption's link -> #graph-table-unlisted) -- not the combined page's old,
// larger count. It still fires on a collapse (any one of the three vanishing)
// and never on growth (a future anchor only raises the count further).
ok('DT30', 'every in-page anchor the rendered TABLE page emits resolves to an id in that page',
	anchors.length >= 3 && dangling.length === 0,
	anchors.length + ' anchors: ' + anchors.join(' '));
note('DT30 asserted here against table.html\'s booted markup rather than by validate-html-output.sh L1, which '
	+ 'aborts with "bad array subscript" on the empty id="" substring a serialized `data-controls-grid=""` '
	+ 'produces (defect routed to feature-011). graph.html carries no dynamically-rendered anchor of its own any '
	+ 'more -- its sole in-page anchor (the static `#top` skip link) needs no DOM proof.');

globalThis.window = wide.window; globalThis.document = doc;
reset();
const rendered = '<!DOCTYPE html>\n' + doc.documentElement.outerHTML;
fs.writeFileSync(path.join(workDir, 'rendered.html'), rendered);

const failed = results.filter((x) => x.kind === 'FAIL');
process.exit(failed.length === 0 ? 0 : 1);
