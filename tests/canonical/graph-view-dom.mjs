// graph-view-dom.mjs -- the DOM half of the graph-view suite: assemble the page,
// boot the shell into a real document, and assert the rendered markup, the
// keyboard drive, the reveal and the determinism of the output.
//
// TWO MECHANICAL LIMITS, STATED BECAUSE THEY BOUND WHAT THIS FILE MAY CLAIM
//   1. jsdom does not execute an inline <script type="module"> at all: it parses
//      it and moves on. So the page's own module block cannot be left to run
//      itself. The same four files are loaded as one module and mountShell() is
//      called against the same assembled markup -- the same code, the same DOM
//      API and the same call the page's last line makes. What is NOT exercised is
//      the browser's own evaluation of that inline block; only a browser can
//      cover that, and no browser check belongs in this suite.
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
// PROTOCOL   GV \t PASS|FAIL|SKIP|NOTE \t <label>     (see graph-view-model.mjs)
//
// USAGE
//   node graph-view-dom.mjs <repo-root> <bundle.mjs> <work-dir>
//     <work-dir> receives graph.html (assembled), rendered.html (the same page
//     after boot, which is the markup a reader actually receives) and the three
//     link targets the page's own link check resolves.

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const repo = process.argv[2];
const bundlePath = process.argv[3];
const workDir = process.argv[4];

/** One entry per assertion class, so an absent runtime is recorded class by class
 *  rather than as a single line that hides how much did not run. */
const CLASSES = [
	['DT10', 'the shell boots into a document with no thrown error and no console error'],
	['DT11', 'the rendered region is a real table: caption, thead, tbody, ten column headers, a row header per row'],
	['DT12', 'aria-sort is on the listed table\'s ten column headers and on no other cell'],
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
	['DT26', 'the table region precedes the graph region and renders completely with no canvas in the build'],
	['DT27', 'below the breakpoint the shortened label is aria-hidden and the full name is in the tree'],
	['DT28', 'the region\'s authored head survives the mount, so the shell can still write its counts'],
	['DT29', 'the rendered projection is the store\'s current ViewModel instance'],
	['DT30', 'every in-page anchor the page emits resolves to an id in the page'],
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
// Assemble the page -- a stand-in for the assembly step features 010/012 own.
// It performs exactly the substitutions the skeleton declares and fails loudly on
// any placeholder left behind, so it cannot quietly produce a different page.
// ---------------------------------------------------------------------------
const T = (rel) => fs.readFileSync(path.join(repo, rel), 'utf8');
const G = (name) => T('canonical/aid/templates/knowledge-graph/' + name);

function assemble(withTable) {
	const files = withTable ? ['graph-model.js', 'graph-controls.js', 'graph-table.js'] : ['graph-model.js', 'graph-controls.js'];
	const ceiling = T('canonical/aid/templates/graph/scale-ceiling.yml').match(/^node_ceiling:\s*(.*)$/m);
	const value = ceiling ? ceiling[1].trim() : '';
	const subs = {
		'{{LANG}}': 'en',
		'{{PROJECT_NAME}}': 'Graph view suite',
		'{{GENERATION_DATE}}': '2026-01-01',
		'{{SOURCE_STAMP}}': '<code>build-relationships.sh</code>',
		'{{INLINE_CSS}}': T('canonical/aid/templates/knowledge-summary/component-css.css') + '\n\n' + G('graph-css.css'),
		'{{RELATIONSHIPS_BASE64}}': Buffer.from(FX.FIXTURE, 'utf8').toString('base64'),
		'{{INLINE_COVERAGE_PREDICATE}}': T('canonical/aid/scripts/graph/coverage-predicate.mjs'),
		'{{INLINE_GRAPH_JS}}': files.map(G).join('\n'),
		'{{INLINE_LIGHTBOX_JS}}': T('canonical/aid/templates/knowledge-summary/lightbox.js'),
		'{{PREREQUISITES}}': '\t\t<li>No network access is required and none is made.</li>',
		'{{SCALE_CEILING_NOTE}}': value === ''
			? '\t<p class="prereqs">No node-count ceiling is declared for this project.</p>'
			: '\t<p class="prereqs">This project declares a node-count ceiling of ' + value + '.</p>',
	};
	let html = G('graph-skeleton.html');
	for (const [key, val] of Object.entries(subs)) {
		if (!html.includes(key)) { throw new Error('skeleton placeholder missing: ' + key); }
		html = html.split(key).join(val);
	}
	const leftover = html.match(/\{\{[A-Z_]+\}\}/g);
	if (leftover) throw new Error('unsubstituted placeholders: ' + leftover.join(', '));
	return html;
}

fs.mkdirSync(workDir, { recursive: true });
const pageHtml = assemble(true);
fs.writeFileSync(path.join(workDir, 'graph.html'), pageHtml);
// The page's own relative-link check resolves against the page's directory, so
// the three targets are written HERE as fixtures rather than borrowed from the
// repository's knowledge base -- the suite must not couple to KB content.
fs.writeFileSync(path.join(workDir, 'relationships.md'), FX.FIXTURE);
fs.writeFileSync(path.join(workDir, 'INDEX.md'), '# Knowledge Base index (suite fixture)\n');
fs.writeFileSync(path.join(workDir, 'external-sources.md'), '# External sources (suite fixture)\n\n## mdn-webgl\n');

// Assembly needs no DOM. It is separable on purpose: the page's own structural,
// accessibility and link checks can then run over an assembled page on a machine
// with no jsdom at all, which is what keeps that group from skipping with this one.
if (process.argv.includes('--assemble-only')) {
	process.stdout.write('assembled=' + path.join(workDir, 'graph.html') + ' bytes=' + Buffer.byteLength(pageHtml) + '\n');
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
	skipAll('jsdom is not resolvable here (it is not a repository dependency; set AID_GRAPH_JSDOM to its '
		+ 'package entry module to enable this half), so no DOM assertion in this class was run');
}

const M = await import(pathToFileURL(bundlePath).href);

// ---------------------------------------------------------------------------
// A document, with the two page reads this view makes made answerable
// ---------------------------------------------------------------------------
function makeDom(narrow) {
	const dom = new JSDOM(pageHtml, {
		runScripts: 'dangerously', pretendToBeVisual: true,
		url: pathToFileURL(path.join(workDir, 'graph.html')).href,
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

const consoleErrors = [];
const realError = console.error;
console.error = (...args) => { consoleErrors.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ')); };
const wide = makeDom(false);
const store = M.mountShell(wide.doc);
console.error = realError;

const doc = wide.doc;
const region = doc.querySelector('[data-table-region]');
const vm = () => store.getViewModel();
const reset = () => store.setLens(M.INITIAL_LENS);

// ---------------------------------------------------------------------------
// Readers over the rendered DOM
// ---------------------------------------------------------------------------
const listedTable = () => region.querySelector('table[data-relationship-table]');
const bodyRows = () => Array.from(region.querySelectorAll('table[data-relationship-table] tbody tr[data-row]'));
const colHeaders = () => Array.from(region.querySelectorAll('table[data-relationship-table] thead th'));
const renderedRows = () => bodyRows().map((tr) => ({
	row: Number(tr.getAttribute('data-row')),
	emphasis: tr.getAttribute('data-emphasis'),
	cells: Array.from(tr.children).map((c) => c.textContent),
	badges: Array.from(tr.querySelectorAll('.badge')).map((b) => b.textContent),
}));
const unlistedRows = () => Array.from(region.querySelectorAll('[data-unlisted-node]'));
const unlistedIds = () => unlistedRows().map((tr) => tr.getAttribute('data-unlisted-node'));
const selects = () => Array.from(region.querySelectorAll('[data-row-select]'));
const headerFor = (token) => region.querySelector('th[data-column="' + token + '"]');

/** Activate a control the way the platform's own Button pattern would, and report
 *  whether it IS that platform element. */
function activate(element) {
	const native = element.tagName === 'BUTTON' && element.getAttribute('type') === 'button' && !element.disabled;
	element.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
	element.dispatchEvent(new wide.window.KeyboardEvent('keydown', { key: ' ', bubbles: true }));
	element.click();
	return native;
}

// ===========================================================================
ok('DT10', 'the shell boots into a document with no thrown error and no console error',
	!!store && consoleErrors.length === 0 && !!listedTable(), consoleErrors.join(' | ').slice(0, 160));

ok('DT11', 'the rendered region is a real table: caption first, thead, tbody, ten column headers',
	listedTable().firstElementChild.tagName === 'CAPTION'
	&& !!listedTable().querySelector('thead') && !!listedTable().querySelector('tbody')
	&& colHeaders().length === 10 && colHeaders().every((th) => th.getAttribute('scope') === 'col'),
	colHeaders().length + ' column headers');
ok('DT11b', 'the ten header labels reconstruct the relationship file\'s own header literal',
	'| ' + colHeaders().map((th) => th.querySelector('button').textContent.replace(/[↕↑↓]/g, '').trim()).join(' | ') + ' |' === FX.HEADER,
	'| ' + colHeaders().map((th) => th.querySelector('button').textContent.replace(/[↕↑↓]/g, '').trim()).join(' | ') + ' |');
ok('DT11c', 'every body row is one row header plus nine cells, and the count equals the drawn row count',
	bodyRows().length === vm().counts.edges && bodyRows().length > 0
	&& bodyRows().every((tr) => tr.querySelectorAll('th[scope="row"]').length === 1 && tr.querySelectorAll('td').length === 9),
	bodyRows().length + ' rows');
ok('DT11d', 'every cell of every row carries the ViewModel value for that column',
	(() => {
		const viewModel = vm();
		for (const tr of bodyRows()) {
			const row = Number(tr.getAttribute('data-row'));
			const edge = viewModel.visibleEdges.find((e) => e.row === row);
			const fold = viewModel.edgeFold.get(edge.key);
			const expect = [
				edge.sourceId, viewModel.visibleNodes.find((n) => n.id === fold.sourceId).kind, viewModel.nodeLabels.get(fold.sourceId),
				edge.targetId, viewModel.visibleNodes.find((n) => n.id === fold.targetId).kind, viewModel.nodeLabels.get(fold.targetId),
				edge.s2t, edge.t2s, edge.provenance, edge.observation,
			];
			for (let i = 0; i < 10; i += 1) {
				if (expect[i] !== '' && tr.children[i].textContent.indexOf(expect[i]) === -1) return false;
			}
		}
		return true;
	})());

ok('DT12', 'aria-sort is on the listed table\'s ten column headers and on NO other cell in the region',
	colHeaders().every((th) => th.getAttribute('aria-sort') === 'none')
	&& Array.from(region.querySelectorAll('th')).filter((th) => th.hasAttribute('aria-sort')).length === 10,
	Array.from(region.querySelectorAll('th')).filter((th) => th.hasAttribute('aria-sort')).length + ' th carry it');
ok('DT13', 'the region creates no third live region and carries neither shell control attribute',
	region.querySelectorAll('[aria-live], [role="alert"], [role="status"], [role="log"]').length === 0
	&& region.querySelectorAll('[data-control], [data-group-toggle]').length === 0);

const caption = () => listedTable().querySelector('caption');
ok('DT14', 'the caption opens with the two drawn ROW counts, quotes the lens summary and cites the file',
	caption().textContent.indexOf(vm().counts.edges + ' relationships listed, ' + vm().counts.hiddenEdges + ' hidden') === 0
	&& caption().textContent.indexOf(vm().lensSummary) !== -1
	&& !!caption().querySelector('a[href="./relationships.md"]'),
	caption().textContent.slice(0, 80));
ok('DT14b', 'the caption\'s link to the unlisted region is emitted with the region itself, so it cannot dangle',
	!!caption().querySelector('a[href="#graph-table-unlisted"]') && !!doc.getElementById('graph-table-unlisted'));

ok('DT15', 'the skip link is the region\'s FIRST element and targets the span after both tables',
	region.firstElementChild.tagName === 'A' && region.firstElementChild.getAttribute('href') === '#graph-table-end'
	&& !!doc.getElementById('graph-table-end')
	&& doc.getElementById('graph-table-end').getAttribute('tabindex') === '-1');
doc.getElementById('graph-table-end').focus();
ok('DT15b', 'and that target receives focus', doc.activeElement === doc.getElementById('graph-table-end'));

const focusables = () => Array.from(region.querySelectorAll('a[href], button, input, select, textarea, summary, [tabindex]'))
	.filter((e) => e.getAttribute('tabindex') !== '-1');
const expectedStops = () => 1 + 1 + (caption().querySelector('a[href^="#"]') ? 1 : 0)
	+ 10 + 2 * bodyRows().length + unlistedRows().length;
ok('DT16', 'the tab stops are exactly the skip link, the caption links, one per column header, two per listed row and one per unlisted row',
	focusables().length === expectedStops() && focusables().length > 20,
	focusables().length + ' vs ' + expectedStops());
ok('DT16b', 'no cell and no disclosure summary is focusable',
	region.querySelectorAll('td[tabindex], th[tabindex], summary').length === 0);
ok('DT16c', 'every link the region emits is a real href anchor, which Enter activates',
	Array.from(region.querySelectorAll('a')).every((a) => !!a.getAttribute('href')));

// --- The keyboard drive -----------------------------------------------------
let native = true;
const depthBefore = store.getLens()['focus.depth'];
let effects = 0;
const allSelects = selects();
for (const button of allSelects) {
	const id = button.getAttribute('data-row-select');
	native = activate(button) && native;
	if (store.getLens()['focus.nodeId'] === id && store.getLens()['focus.depth'] === depthBefore) effects += 1;
	reset();
}
ok('DT17', 'every select control, driven by keyboard alone, writes {focus.nodeId} and leaves focus.depth untouched',
	effects === allSelects.length && allSelects.length > 0 && native, effects + '/' + allSelects.length);
ok('DT17b', 'two select controls per listed row and one per unlisted row, none of them a shell control',
	bodyRows().every((tr) => tr.querySelectorAll('[data-row-select]').length === 2)
	&& unlistedRows().every((tr) => tr.querySelectorAll('[data-row-select]').length === 1)
	&& selects().every((b) => !b.hasAttribute('data-control')));
ok('DT17c', 'each select control names the endpoint by its FULL accessible name',
	selects().every((b) => b.getAttribute('aria-label') === 'Select ' + vm().nodeLabels.get(b.getAttribute('data-row-select'))));

let sortNative = true;
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const ascending = headerFor('provenance').getAttribute('aria-sort');
const others = colHeaders().filter((th) => th.getAttribute('aria-sort') !== 'none').length;
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const descending = headerFor('provenance').getAttribute('aria-sort');
sortNative = activate(headerFor('provenance').querySelector('button')) && sortNative;
const backToFile = colHeaders().every((th) => th.getAttribute('aria-sort') === 'none');
ok('DT18', 'activating a header three times reads ascending, descending, then none on all ten',
	ascending === 'ascending' && others === 1 && descending === 'descending' && backToFile && sortNative,
	ascending + ' / ' + descending + ' / ' + (backToFile ? 'none x10' : 'not reset'));
ok('DT18b', 'and the third activation returns the control state to the file order',
	same(store.getLens()['sort'], { column: 'row', direction: 'asc' }), JSON.stringify(store.getLens()['sort']));
reset();

// --- Badges, and dimmed as the complement -----------------------------------
store.applyPreset('coverage');
const badgeTexts = ids(Array.from(region.querySelectorAll('tbody tr .badge')).map((b) => b.textContent));
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
reset();
store.applyPreset('provenance');
ok('DT19c', 'the Provenance lens renders the chain badge as text on the S2T reading',
	Array.from(region.querySelectorAll('tbody tr td .badge')).some((b) => b.textContent === 'chain'));
reset();
store.setLens({ 'focus.nodeId': 'kb:alpha.md' });
ok('DT19d', 'a selection renders its own text badge',
	Array.from(region.querySelectorAll('.badge')).some((b) => b.textContent === 'selected'));
reset();

// --- The empty state --------------------------------------------------------
store.setLens(Object.assign({}, M.INITIAL_LENS, { 'filters.categories': ['structure'], 'focus.nodeId': FX.FILTERED_OUT_NODE }));
const empty = region.querySelector('tbody tr[data-empty-state]');
ok('DT20', 'an emptied table states why, spanning all ten columns and quoting the lens summary',
	!!empty && empty.querySelector('td').getAttribute('colspan') === '10'
	&& empty.textContent.indexOf(vm().lensSummary) !== -1
	&& empty.textContent.indexOf('Controls panel') !== -1 && !empty.querySelector('a'));
ok('DT20b', 'and the node it could not list is named in the unlisted region instead',
	unlistedIds().includes(FX.FILTERED_OUT_NODE), unlistedIds().join(','));
reset();
ok('DT20c', 'the empty-state row is absent whenever rows are listed', !region.querySelector('tbody tr[data-empty-state]'));

// --- The unlisted region ----------------------------------------------------
ok('DT21', 'the unlisted region is a real table with a caption, three column headers and a row header per row',
	!!region.querySelector('#graph-table-unlisted table caption')
	&& region.querySelectorAll('#graph-table-unlisted thead th[scope="col"]').length === 3
	&& unlistedRows().every((tr) => tr.querySelectorAll('th[scope="row"]').length === 1));
ok('DT21b', 'its three column headers wrap no sort control and carry no aria-sort',
	Array.from(region.querySelectorAll('#graph-table-unlisted thead th'))
		.every((th) => !th.hasAttribute('aria-sort') && !th.querySelector('button')));
ok('DT21c', 'the zero-row artifact\'s Name cell states the fact in words, from the projection',
	(() => {
		const row = region.querySelector('[data-unlisted-node="' + FX.ZERO_ROW_NODE + '"]');
		return !!row && row.children[2].textContent.indexOf('— no recorded relationships') !== -1;
	})());
ok('DT21d', 'every drawn node is named in the region -- in a listed row or in the unlisted table',
	(() => {
		for (const lens of [{}, { grouping: 'document' }, { emphasis: 'coverage' }]) {
			reset();
			if (Object.keys(lens).length) store.setLens(lens);
			const named = ids(bodyRows().flatMap((tr) => [tr.children[0], tr.children[3]])
				.map((cell) => cell.querySelector('code').textContent).concat(unlistedIds()));
			const expect = ids(vm().visibleNodes.map((n) => n.id));
			// An empty drawn set would satisfy the containment vacuously.
			if (expect.length === 0) return false;
			if (expect.some((id) => !named.includes(id))) return false;
		}
		return true;
	})());
reset();
store.setLens({ grouping: 'document' });
ok('DT21e', 'including a document whose every row the fold collapsed, whose degree is NOT zero',
	unlistedIds().includes(FX.FOLD_ONLY_NODE) && store.getGraphModel().nodes.get(FX.FOLD_ONLY_NODE).degree > 0,
	FX.FOLD_ONLY_NODE + ' degree ' + store.getGraphModel().nodes.get(FX.FOLD_ONLY_NODE).degree);
reset();

// --- The reveal -------------------------------------------------------------
function revealed(setup) {
	wide.scrolls.length = 0;
	const before = doc.activeElement;
	setup();
	const call = wide.scrolls[wide.scrolls.length - 1] || null;
	return { call: call, focusMoved: doc.activeElement !== before };
}
const firstRowNaming = (id) => renderedRows().find((r) => r.cells[0].indexOf(id) === 0 || r.cells[3].indexOf(id) === 0);
let r = revealed(() => { region.querySelector('[data-row-select="kb:concept:graph-view"]').click(); });
ok('DT22', 'a select brings the first row of the CURRENT order naming that node into view, instantly, moving no focus',
	!!r.call && r.call.options.behavior === 'instant'
	&& r.call.element.getAttribute('data-row') === String(firstRowNaming('kb:concept:graph-view').row)
	&& !r.focusMoved,
	r.call ? 'row ' + r.call.element.getAttribute('data-row') + ' ' + JSON.stringify(r.call.options) : 'no scroll');
ok('DT22b', 'and the scrolled element carries a scroll margin covering both sticky layers',
	!!r.call && /^\d+px$/.test(r.call.element.style.scrollMarginTop), r.call ? r.call.element.style.scrollMarginTop : 'none');
r = revealed(() => { store.setLens({ 'filters.text': '' }); });
ok('DT22c', 'a re-projection that leaves the marked id alone scrolls nothing', r.call === null);
reset();
store.setLens({ sort: { column: 'source-id', direction: 'desc' } });
r = revealed(() => { region.querySelector('[data-row-select="kb:alpha.md"]').click(); });
ok('DT22d', 'at a non-default sort the revealed row is the first of THAT order',
	!!r.call && r.call.element.getAttribute('data-row') === String(firstRowNaming('kb:alpha.md').row),
	r.call ? 'row ' + r.call.element.getAttribute('data-row') : 'no scroll');
reset();
r = revealed(() => { store.setLens({ grouping: 'document' }); region.querySelector('[data-row-select="' + FX.FOLD_ONLY_NODE + '"]').click(); });
ok('DT22e', 'where every row naming the node is collapsed, its unlisted-region row is revealed instead',
	!!r.call && r.call.element.getAttribute('data-unlisted-node') === FX.FOLD_ONLY_NODE
	&& r.call.options.behavior === 'instant' && !r.focusMoved);
reset();
region.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click();
store.applyPreset('coverage');
r = revealed(() => { region.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click(); });
ok('DT22f', 'a re-selection after a focus-clearing preset reveals AGAIN -- the clearing rule',
	store.getLens()['focus.nodeId'] === FX.FILTERED_OUT_NODE && !!r.call && !r.focusMoved);
reset();

// --- Determinism, the width crossing, and the peer contract ------------------
function mountFresh(lens) {
	const fresh = makeDom(false);
	const s = M.mountShell(fresh.doc);
	if (lens) s.setLens(lens);
	const markup = fresh.doc.querySelector('[data-table-region]').innerHTML;
	return markup;
}
const lensForDeterminism = { grouping: 'document', emphasis: 'coverage', sort: { column: 'target-name', direction: 'desc' } };
const first = mountFresh(lensForDeterminism);
const second = mountFresh(lensForDeterminism);
globalThis.window = wide.window; globalThis.document = wide.doc;
ok('DT24', 'two independent mounts at the same control state produce byte-identical markup',
	first === second && first.length > 1000, 'lengths ' + first.length + ' / ' + second.length);

const wq = makeDom(false);
const wqStore = M.mountShell(wq.doc);
const wqRegion = wq.doc.querySelector('[data-table-region]');
const wideMarkup = wqRegion.innerHTML;
const revisionBefore = wqStore.getViewModel().revision;
wq.scrolls.length = 0;
wq.fire(true);
const narrowMarkup = wqRegion.innerHTML;
wq.fire(false);
ok('DT25', 'a width crossing re-emits the rows at the SAME revision, changes the markup, fires no second reveal, and reverses byte for byte',
	wqStore.getViewModel().revision === revisionBefore && narrowMarkup !== wideMarkup
	&& wq.scrolls.length === 0 && wqRegion.innerHTML === wideMarkup,
	'revision ' + revisionBefore + ', scrolls ' + wq.scrolls.length);
globalThis.window = wide.window; globalThis.document = wide.doc;

const renderings = doc.querySelector('.renderings');
ok('DT26', 'the table region precedes the graph region in DOM order and neither is nested in the other',
	renderings.children[0].hasAttribute('data-table-region')
	&& renderings.children[1].classList.contains('graph-region')
	&& !doc.querySelector('.graph-region [data-table-region]'));
ok('DT26b', 'this build carries no drawing rendering at all, and the table still rendered completely',
	doc.querySelector('[data-graph-canvas]') === null
	&& !doc.querySelector('[data-graph-placeholder]').hidden
	&& bodyRows().length > 0,
	'placeholder shown, ' + bodyRows().length + ' rows listed');

// --- The responsive Name cell ------------------------------------------------
const shortForm = store.getGraphModel().nodes.get('kb:alpha.md#fact:renderer-choice').shortLabel;
const fullForm = vm().nodeLabels.get('kb:alpha.md#fact:renderer-choice');
ok('DT27', 'above the breakpoint the shortened form appears nowhere in the region',
	shortForm.indexOf('…') !== -1 && region.textContent.indexOf(shortForm) === -1, shortForm);
const narrow = makeDom(true);
const narrowStore = M.mountShell(narrow.doc);
const narrowRegion = narrow.doc.querySelector('[data-table-region]');
const factCell = Array.from(narrowRegion.querySelectorAll('tbody tr[data-row] td'))
	.find((td) => td.textContent.indexOf(shortForm) !== -1);
ok('DT27b', 'below it the visible text is the short label inside aria-hidden, with the full name in an .sr-only span beside it',
	!!factCell && factCell.querySelector('span[aria-hidden="true"]').textContent === shortForm
	&& !!factCell.querySelector('span.sr-only') && factCell.querySelector('span.sr-only').textContent === fullForm
	&& factCell.textContent.indexOf(fullForm) !== -1);
ok('DT27c', 'the unlisted region shortens nothing at either width, and the shortening adds no tab stop',
	Array.from(narrowRegion.querySelectorAll('#graph-table-unlisted tbody tr')).map((tr) => tr.children[2])
		.every((td) => !td.querySelector('span[aria-hidden="true"]')
			&& td.textContent.indexOf(narrowStore.getViewModel().nodeLabels.get(td.parentElement.getAttribute('data-unlisted-node'))) === 0)
	&& Array.from(narrowRegion.querySelectorAll('span[tabindex]')).filter((s) => s.getAttribute('tabindex') !== '-1').length === 0);
globalThis.window = wide.window; globalThis.document = wide.doc;

ok('DT28', 'the region\'s authored head survives the mount, so the shell can still write its counts',
	!!region.querySelector('.region-head h2') && !!region.querySelector('[data-counts]')
	&& region.querySelector('[data-counts]').textContent.indexOf('relationships drawn') !== -1,
	region.querySelector('[data-counts]').textContent);

// --- The seam: identity of the projection, and the private row order ---------
const direct = makeDom(false);
globalThis.window = direct.window; globalThis.document = direct.doc;
const directModel = M.parseRelationships(FX.FIXTURE);
const directStore = M.createStore(directModel, M.INITIAL_LENS);
const directRegion = direct.doc.querySelector('[data-table-region]');
const handle = M.mountTable({
	store: directStore, graphModel: directModel, region: directRegion,
	surface: direct.doc.querySelector('[data-graph-surface]'), root: direct.doc,
});
let identity = handle.renderedFrom === directStore.getViewModel();
for (const preset of Object.keys(M.PRESETS)) {
	directStore.applyPreset(preset);
	if (handle.renderedFrom !== directStore.getViewModel()) identity = false;
}
ok('DT29', 'the rendered projection IS the store\'s current ViewModel instance, initially and after every preset',
	identity && !!directRegion.querySelector('table[data-relationship-table]'));
directStore.setLens(M.INITIAL_LENS);
ok('DT29b', 'the row order is cached against the revision alone',
	handle.rowOrder.orderedFor === directStore.getViewModel().revision);
directRegion.querySelector('[data-row-select="' + FX.FILTERED_OUT_NODE + '"]').click();
const recorded = handle.rowOrder.focusRevealed;
directStore.applyPreset('coverage');
ok('DT29c', 'a select records the revealed id, and a rebuild finding no marked id clears it',
	recorded === FX.FILTERED_OUT_NODE && handle.rowOrder.focusRevealed === null,
	recorded + ' -> ' + String(handle.rowOrder.focusRevealed));
globalThis.window = wide.window; globalThis.document = wide.doc;

// ---------------------------------------------------------------------------
// The rendered page, written out for the bash side's validator run, and the
// in-page anchor check performed HERE.
//
// WHY THE ANCHOR CHECK IS HERE AND NOT LEFT TO THE PAGE VALIDATOR
//   validate-html-output.sh's L1 builds a bash associative array keyed on every
//   `id="..."` SUBSTRING it can find, and aborts with `bad array subscript` on an
//   empty key. A serialized DOM writes valueless attributes as `attr=""`, and the
//   shell's own `data-controls-grid` then contains the substring `id=""` -- so L1
//   cannot run over the rendered page at all. That defect is routed to
//   feature-011; it is NOT worked around silently. The obligation itself -- every
//   in-page href resolves to an id in the page -- is asserted here instead, over
//   the same rendered markup, and the bash side skips the shipped L1 loudly.
// ---------------------------------------------------------------------------
reset();
const rendered = '<!DOCTYPE html>\n' + doc.documentElement.outerHTML;
fs.writeFileSync(path.join(workDir, 'rendered.html'), rendered);
const anchors = ids((rendered.match(/href="#[^"]+"/g) || []).map((h) => h.slice(7, -1)));
const idAttrs = new Set((rendered.match(/\sid="[^"]*"/g) || []).map((a) => a.slice(5, -1)));
const dangling = anchors.filter((a) => !idAttrs.has(a));
ok('DT30', 'every in-page anchor the rendered page emits resolves to an id in that page',
	anchors.length >= 4 && dangling.length === 0,
	anchors.length + ' anchors: ' + anchors.join(' '));
note('DT30 asserted here rather than by validate-html-output.sh L1, which aborts with "bad array subscript" on '
	+ 'the empty id="" substring a serialized `data-controls-grid=""` produces (defect routed to feature-011)');

const failed = results.filter((x) => x.kind === 'FAIL');
process.exit(failed.length === 0 ? 0 : 1);
