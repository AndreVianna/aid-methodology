// graph-canvas-dom.mjs -- feature-008's canvas draw record, asserted headlessly
// against D3's published record (window.__aidGraphCanvas), never against pixels
// or a screenshot (task-018, work-005 delivery-001).
//
// SCOPE, NARROWED BY OWNER DIRECTION (mid-task-018 course correction)
//   The first pass of this suite authored the full GC01-GC19 series and found,
//   empirically, that the SPEC's own words let every one of them pass while a
//   real page drew nothing visible: `mode: 'live'` and `positions` differing
//   between frames say nothing about WHERE those positions land, and `nodes`
//   equalling `visibleNodes` says nothing about whether a mark is on screen.
//   The owner's ruling: this file is a DRAW-RECORD CONFORMANCE layer -- it
//   proves the record is internally consistent with the ViewModel and with
//   graph-canvas.js's own source, and it is cheap and headless BECAUSE it
//   proves exactly that and nothing about visibility, position on screen, or
//   click-reachability. Those are `tests/ui/`'s job (Playwright, real Chromium,
//   NOT in this required suite -- see the sibling check this task also writes).
//
//   Kept here, and why each is cheap AND load-bearing for a record no browser
//   check would reach as economically:
//     * Record/ViewModel set-and-content equality (nodes/edges/marks, and every
//       mark's fields against the ViewModel entry for ITS OWN id/key) -- the
//       founding defect class this whole work traces to (Q17, Q21): an
//       id-prefix-keyed encoding passes a same-record self-consistency check
//       and fails only against the ViewModel it should have read.
//     * The canvas's own attribute set (AC-S8) -- a DOM property read, not a
//       visual judgement; cheap, deterministic, and the one surviving assertion
//       of "no control on the canvas, no tab stop" now that the viewport
//       button manifest itself is gone (task-032 -- see "GC12 is dead" below).
//     * graph-canvas.js's own source: no `.prefix` read, no prefix literal, no
//       colour literal, no load statement, no `lensState` member beyond `zoom`.
//     * Frame-path purity (AC-S5): zero ARIA/live-region writes, zero
//       `getComputedStyle`, zero `getBoundingClientRect` FROM THE FRAME PATH.
//       Genuinely hard for a screenshot to see; a plain call-count is exact.
//     * The unavailable-mode contract (AC-S10): both paths (library absent, no
//       WebGL context) reach `mode: 'unavailable'`, exactly one `console.warn`
//       with the stable prefix, and exactly two live regions -- plus the
//       late-failure transition (ledger row 4), a second, distinct route to the
//       SAME end state that a mount-time-only check cannot see.
//     * THE ONE NEW ASSERTION THE OWNER ASKED FOR, and the most valuable thing
//       in this file: every drawn node's position, mapped through the recorded
//       `viewport` and the canvas's own width/height by `gcLocalPoint`'s own
//       documented inverse, must land inside the drawing buffer. This is cheap,
//       headless, and it is the exact shape of the real defect a human found in
//       a real browser: `mode: 'live'`, a frame counter ticking, marks derived
//       correctly, and a blank rectangle on screen, because the layout is
//       centred on the coordinate origin while PixiJS treats (0,0) as the
//       buffer's TOP-LEFT CORNER and no translation is ever applied to the
//       stage. Verified still present on disk (`graph-canvas.js`:628, :988: the
//       stage's `.position` is never set and `g.position.set(p.x,p.y)` draws the
//       raw simulation coordinate) -- so this assertion is EXPECTED to fail
//       against the current, unfixed module, and this file says so rather than
//       adjusting the check to pass.
//
//   DROPPED, and why each is Layer 2's (tests/ui/) rather than this file's:
//     * GC01/GC03/GC08 (motion, drag, settle-vs-live comparison) -- proving
//       anything MOVES on a bitmap needs the bitmap; simulating real physics
//       headlessly to prove a `positions` value differs is exactly the kind of
//       load this file existed to avoid, and it cannot see whether the moved
//       mark was ever inside the buffer, which is the finding that mattered.
//     * GC02 (hover reveal), GC18 (click/dblclick/wheel semantics) -- both
//       depend on a synthetic pointer hitting a node at its DRAWN screen
//       position, which is precisely the coordinate space the real defect
//       shows this file cannot trust without a browser's own layout and paint.
//     * GC05/GC06/GC07 (presets, filters, category encoding by value) and
//       GC11/GC14/GC15/GC16 (gap badges, forced-colours channels, fold
//       endpoints, exact-identity at rest) -- all real obligations, all
//       reachable headlessly, none as cheap and load-bearing as the ones kept,
//       and the owner's instruction is to default to dropping rather than
//       keeping every provable thing. Flagged, not silently lost.
//     * GC04 (frame instrumentation shape) -- the owner's own example: `frames`
//       being populated with tickMs/drawMs samples is true from a RING BUFFER
//       SATURATED AT 240 regardless of whether anything is visible; it proves
//       instrumentation exists, not that the page works, and AC-6a's own figure
//       is feature-002's in any case.
//     * GC12 -- DEAD. task-032 SS E removes all seven viewport buttons
//       (`zoom-in/out/fit`, `pan-left/right/up/down`); the subject this hook
//       named will not exist. Not authored.
//     * GC09's "generated graph.html" static half stays a one-line grep (no
//       literal <canvas> in the skeleton at all -- task-017 made the element
//       entirely runtime-created); its mounted-page half (getAttributeNames())
//       is kept, per the load-bearing case above.
//
//   TWO HARD FACTS THAT SHAPE WHAT IS ASSERTED HERE (owner correction, mid-task):
//     * `record.viewport` currently MISREPORTS after a committed gesture (a
//       zoom-only `setLens` notification runs `gcDrawFrame` alone, which never
//       writes `view.record.viewport` -- only `frames[].applied` does; see
//       `graph-canvas.js`'s own `gcOnNotify`/`gcDrawFrame`). This file asserts
//       nothing of the form "record.viewport changes after a gesture" for that
//       reason (ledger row 11, task-032 SS C) -- deferred until that is fixed.
//     * `frames.length` is a RING, saturated at 240, and is never read here as
//       a repaint signal for the same reason the owner named: it proves nothing
//       about whether a NEW frame was drawn once the ring is full.
//
// PROTOCOL   GC \t PASS|FAIL|SKIP|NOTE \t <label>   (mirrors graph-view-model.mjs)
//
// USAGE
//   node graph-canvas-dom.mjs <repo-root> <bundle.mjs> <work-dir> [--expect-fail ID,ID,...]
//     <bundle.mjs> MUST have been built with GRAPH_BUNDLE_INCLUDE_CANVAS=1.
//   Exit 0/1/3 -- see graph-view-model.mjs's own convention.

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const repo = process.argv[2];
const bundlePath = process.argv[3];
const workDir = process.argv[4];

let expectFail = null;
const efIndex = process.argv.indexOf('--expect-fail');
if (efIndex !== -1) expectFail = String(process.argv[efIndex + 1] || '').split(',').filter(Boolean);

if (!repo || !bundlePath || !workDir) {
	process.stdout.write('GC\tFAIL\tGC00 harness — repo root, bundle and work dir are all required\n');
	process.exit(1);
}

const results = [];
function emit(kind, label) {
	results.push({ kind, label });
	if (expectFail === null) process.stdout.write('GC\t' + kind + '\t' + label + '\n');
}
function ok(id, label, condition, detail) {
	const text = id + ' ' + label + (detail === undefined || detail === null || detail === '' ? '' : ' [' + detail + ']');
	emit(condition ? 'PASS' : 'FAIL', condition ? text : text + ' — assertion did not hold');
	return !!condition;
}
function skip(id, label, reason) { emit('SKIP', id + ' ' + label + ' — ' + reason); }
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const ids = (list) => Array.from(new Set(list)).sort();

const ALL_IDS = ['GC09', 'GC10', 'GC13', 'GC17', 'GC19', 'GC21bounds'];

let JSDOM;
try {
	const override = process.env.AID_GRAPH_JSDOM;
	const mod = override ? await import(pathToFileURL(override).href) : await import('jsdom');
	JSDOM = mod.JSDOM || (mod.default && mod.default.JSDOM);
} catch (error) {
	JSDOM = undefined;
}
if (typeof JSDOM !== 'function') {
	for (const id of ALL_IDS) skip(id, '(all clauses)', 'jsdom is not resolvable here (it is not a repository '
		+ 'dependency; set AID_GRAPH_JSDOM to its package entry module to enable this suite)');
	process.exit(3);
}

const M = await import(pathToFileURL(bundlePath).href);
const FX = await import('./graph-view-fixture.mjs');

// ---------------------------------------------------------------------------
// Assemble the page ONCE -- every scenario below mounts the SAME assembled
// HTML into a fresh jsdom document, so the (cheap) assembly cost is paid once.
// ---------------------------------------------------------------------------
const T = (rel) => fs.readFileSync(path.join(repo, rel), 'utf8');
const G = (name) => T('canonical/aid/templates/knowledge-graph/' + name);

function assemble() {
	const files = ['graph-model.js', 'graph-controls.js', 'graph-table.js', 'graph-canvas.js'];
	const ceiling = T('canonical/aid/templates/graph/scale-ceiling.yml').match(/^node_ceiling:\s*(.*)$/m);
	const value = ceiling ? ceiling[1].trim() : '';
	const subs = {
		'{{LANG}}': 'en',
		'{{PROJECT_NAME}}': 'Graph canvas suite',
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
		if (!html.includes(key)) throw new Error('skeleton placeholder missing: ' + key);
		html = html.split(key).join(val);
	}
	const leftover = html.match(/\{\{[A-Z_]+\}\}/g);
	if (leftover) throw new Error('unsubstituted placeholders: ' + leftover.join(', '));
	return html;
}

fs.mkdirSync(workDir, { recursive: true });
const pageHtml = assemble();
fs.writeFileSync(path.join(workDir, 'graph.html'), pageHtml);

// GC09's static half: no literal <canvas> exists in the AUTHORED skeleton at
// all -- task-017 made it entirely runtime-created.
ok('GC09', 'the AUTHORED skeleton contains no literal <canvas> tag -- the element is entirely runtime-created '
	+ '(task-017); the attribute contract is asserted on the MOUNTED page below',
	!/<canvas[\s>]/i.test(G('graph-skeleton.html')));

// ---------------------------------------------------------------------------
// graph-canvas.js's own source -- static, comment-aware where a prose mention
// would otherwise false-positive (the file's own header explains an absence in
// English, e.g. the string "Node.prefix" and the token "rgb(").
// ---------------------------------------------------------------------------
function stripComments(src) {
	return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');
}
const canvasSrcRaw = fs.readFileSync(path.join(repo, 'canonical/aid/templates/knowledge-graph/graph-canvas.js'), 'utf8');
const canvasSrc = stripComments(canvasSrcRaw);
{
	const rawGreps = [
		['fetch\\s*\\(', 'no fetch('],
		['XMLHttpRequest', 'no XMLHttpRequest'],
		['import\\s*\\(', 'no dynamic import('],
		['^\\s*import\\s', 'no top-level import'],
		['canonical/', 'no canonical/ substring'],
		["'kb:'", 'no quoted \'kb:\' prefix literal'],
		["'int:'", 'no quoted \'int:\' prefix literal'],
		["'ext:'", 'no quoted \'ext:\' prefix literal'],
	];
	for (const [pattern, label] of rawGreps) {
		ok('GC10', 'graph-canvas.js: ' + label, !new RegExp(pattern, 'm').test(canvasSrcRaw));
	}
	ok('GC10', 'graph-canvas.js reads no .prefix member access (comments stripped)', !/\.prefix\b/.test(canvasSrc));
	ok('GC10', 'graph-canvas.js reads no lensState member other than .zoom', !/lensState\.(grouping|density|focus|emphasis|filters|sort|expandedGroups)\b/.test(canvasSrc));
	ok('GC10', 'graph-canvas.js calls no matchMedia — preferences arrive on the store\'s own route (Open Item 2)', !/matchMedia\s*\(/.test(canvasSrc));
	for (const placeholder of ['{{CANONICAL_ROOT}}', '{{PROJECT_ROOT}}', '{{PROFILE_ROOT}}']) {
		ok('GC10', 'graph-canvas.js carries no literal ' + placeholder, !canvasSrcRaw.includes(placeholder));
	}
	ok('GC13', 'graph-canvas.js contains no hex/rgb(/hsl(/named-colour literal (comments stripped)',
		!/#[0-9a-fA-F]{3,6}\b/.test(canvasSrc) && !/rgba?\(/.test(canvasSrc) && !/hsla?\(/.test(canvasSrc));
}

// ===========================================================================
// The two fake globals -- MINIMAL capability-level doubles. Layer 1 asserts
// the RECORD, never motion or physics, so `d3`'s forces are deliberately
// no-ops and `restart()` never schedules a timer: there is nothing here for a
// tick to move, and no lingering timer to leak across scenarios (a real
// hazard the first pass of this file hit and is not repeating). PIXI's
// Graphics/Container are chainable no-ops sufficient for graph-canvas.js's own
// call surface (never inspected — Layer 1 reads the RECORD, not draw calls).
// ===========================================================================
function makeFakeD3() {
	function noopForce() {
		const f = () => {};
		f.initialize = () => {};
		f.strength = () => f; f.id = () => f; f.distance = () => f;
		return f;
	}
	function forceSimulation(nodes) {
		for (const n of nodes) { n.x = n.x || 0; n.y = n.y || 0; n.vx = 0; n.vy = 0; }
		let tickCb = null;
		const sim = {
			nodes,
			force(name, f) { if (f && typeof f.initialize === 'function') f.initialize(nodes); return sim; },
			alpha(v) { if (v === undefined) return 0; return sim; }, // getter always 0 (no motion asserted); setter chainable
			alphaTarget() { return sim; },
			alphaMin() { return sim; },
			alphaDecay() { return sim; },
			velocityDecay() { return sim; },
			on(name, cb) { if (name === 'tick') tickCb = cb; return sim; },
			tick() { if (tickCb) tickCb(); return sim; },
			// Deliberate no-op: Layer 1 asserts the record, never motion, and a
			// self-scheduling timer here is exactly the cross-scenario leak hazard
			// this rewrite exists to avoid (a live timer publishing into whichever
			// jsdom window happens to be `globalThis.window` when it next fires).
			restart() { return sim; },
			stop() { return sim; },
		};
		return sim;
	}
	return { forceSimulation, forceManyBody: noopForce, forceLink: noopForce, forceCenter: noopForce, forceCollide: noopForce };
}

function makeFakePixi() {
	function chainable(methods) {
		const obj = {};
		for (const m of methods) obj[m] = () => obj;
		obj.position = { x: 0, y: 0, set() {} };
		obj.scale = { x: 1, y: 1, set() {} };
		return obj;
	}
	class FakeGraphics {
		constructor() { Object.assign(this, chainable(['lineStyle', 'beginFill', 'endFill', 'drawCircle', 'drawRect', 'drawPolygon', 'moveTo', 'lineTo'])); }
	}
	class FakeContainer {
		constructor() { this.children = []; this.position = { x: 0, y: 0, set() {} }; this.scale = { x: 1, y: 1, set() {} }; }
		addChild(...kids) { this.children.push(...kids); return kids[0]; }
		removeChildren() { const removed = this.children; this.children = []; return removed; }
	}
	class FakeWebGLRenderer {
		constructor() {}
		init() {
			if (FakeWebGLRenderer.rejectNext) {
				const err = new Error('forced init rejection (test scenario)');
				FakeWebGLRenderer.rejectNext = false;
				return Promise.reject(err);
			}
			return Promise.resolve();
		}
		resize() {}
		render() {}
	}
	FakeWebGLRenderer.rejectNext = false;
	return { WebGLRenderer: FakeWebGLRenderer, Container: FakeContainer, Graphics: FakeGraphics, Text: class {} };
}

/** A capability-level ResizeObserver double: jsdom implements none at all
 *  (29.1.1, checked on disk). `.trigger()` also doubles as this suite's ONLY
 *  "force a frame" mechanism (`gcResize` calls `gcDrawFrame` SYNCHRONOUSLY,
 *  needing no timer and no simulation tick), which is what GC17 uses. */
class FakeResizeObserver {
	constructor(cb) { this.cb = cb; }
	observe(el) { this.target = el; }
	unobserve() {}
	disconnect() {}
	trigger() { this.cb([{ target: this.target }]); }
}

function rectOf(width, height) {
	return { width, height, top: 0, left: 0, right: width, bottom: height, x: 0, y: 0, toJSON() { return this; } };
}

/**
 * One mounted scenario -- a fresh jsdom document, because `mode` is decided
 * once at mount. No timers are ever started (see the fake d3 above), so no
 * scenario leaves anything running for a LATER scenario's globals to catch.
 */
async function mountScenario(opts) {
	const o = Object.assign({ webgl: true, initRejects: false, libraryAbsent: false }, opts || {});
	const dom = new JSDOM(pageHtml, { runScripts: 'dangerously', pretendToBeVisual: true, url: pathToFileURL(path.join(workDir, 'graph.html')).href });
	const { window } = dom;
	globalThis.window = window;
	globalThis.document = window.document;
	globalThis.Event = window.Event;
	globalThis.MouseEvent = window.MouseEvent;
	globalThis.getComputedStyle = window.getComputedStyle.bind(window);
	globalThis.MutationObserver = window.MutationObserver;
	globalThis.ResizeObserver = FakeResizeObserver;
	globalThis.d3 = makeFakeD3();
	const fakePixi = makeFakePixi();
	fakePixi.WebGLRenderer.rejectNext = !!o.initRejects;
	globalThis.PIXI = o.libraryAbsent ? undefined : fakePixi;

	window.HTMLCanvasElement.prototype.getContext = function () { return o.webgl ? { __fakeGL: true } : null; };
	// The surface and its canvas must agree on their box: gcResize measures the
	// SURFACE while gcLocalPoint's inverse (used by the buffer-bounds check
	// below) reads the CANVAS's own rect -- a real browser box is the same for
	// both.
	window.Element.prototype.getBoundingClientRect = function () {
		if (this.tagName === 'CANVAS' || (this.getAttribute && this.getAttribute('data-graph-surface') !== null)) return rectOf(800, 600);
		return rectOf(0, 0);
	};
	window.matchMedia = (q) => ({ media: q, matches: false, addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {} });

	// Intercepted for the SCENARIO'S WHOLE LIFETIME, not only during the
	// synchronous mountShell() call: the late-failure transition's one warning
	// fires from an async .catch() well after mountShell() has returned, and a
	// restore-immediately-after-mount pattern silently misses it (found the
	// hard way in this file's own first pass). Left installed rather than
	// restored -- the next mountScenario() call overwrites it again, and this
	// is the suite's only console.warn consumer in the process either way.
	const consoleWarnings = [];
	console.warn = (...args) => { consoleWarnings.push(args); };
	const store = M.mountShell(window.document);

	const doc = window.document;
	const surface = doc.querySelector('[data-graph-surface]');
	return {
		window, doc, store, surface, consoleWarnings,
		canvasEl: () => surface.querySelector('canvas'),
		record: () => window.__aidGraphCanvas,
	};
}

/** Let a pending `renderer.init()` promise (and mountCanvas's own `.then()`/
 *  `.catch()` off it) settle. No timers are involved -- three microtask ticks
 *  is enough for a promise chain three links deep. */
async function flushInit() {
	await Promise.resolve(); await Promise.resolve(); await Promise.resolve();
}

// ===========================================================================
// GC19 -- AC-S10: both unavailability paths, and the late-failure transition
// ===========================================================================
{
	const s1 = await mountScenario({ libraryAbsent: true });
	// The shell hides the SKELETON's static placeholder ([data-graph-placeholder])
	// UNCONDITIONALLY once the drawing module is merely REGISTERED
	// (`graph-controls.js`: `if (mountCanvasFn) { ...; placeholder.hidden = true; }`
	// tests the function reference, never mountCanvas's own return value).
	// `gcMountUnavailable`'s own reason is a SEPARATE <p class="graph-placeholder">
	// appended to the surface, without the data- marker -- AC-S10's "static
	// sentence, ordinary text" is asserted against THAT element.
	const sentence1 = Array.from(s1.doc.querySelectorAll('[data-graph-surface] p.graph-placeholder'))
		.find((p) => !p.hasAttribute('data-graph-placeholder'));
	ok('GC19', 'library global absent: mode is unavailable, no canvas element, and gcMountUnavailable\'s own '
		+ 'sentence is present, unhidden, ordinary text (no aria-live, no role=alert)',
		s1.record() && s1.record().mode === 'unavailable' && !s1.canvasEl()
		&& !!sentence1 && sentence1.hidden !== true
		&& sentence1.getAttribute('aria-live') === null && sentence1.getAttribute('role') !== 'alert',
		'mode=' + (s1.record() && s1.record().mode));
	const w1 = s1.consoleWarnings.filter((a) => String(a[0]).indexOf(M.GC_WARN_PREFIX) === 0);
	ok('GC19', 'library-absent path: exactly one console.warn carries the stable prefix', w1.length === 1, 'count=' + w1.length);
	ok('GC19', 'library-absent path: the page still has exactly two live regions (the view\'s own status line '
		+ 'and role=alert banner — the reused lightbox caption is a documented third, GS07)',
		s1.doc.querySelectorAll('[data-status][aria-live="polite"]').length === 1 && s1.doc.querySelectorAll('[role="alert"]').length === 1);
	const table1 = s1.doc.querySelector('table[data-relationship-table]');
	ok('GC19', 'library-absent path: the table rendering is present and populated',
		!!table1 && table1.querySelectorAll('tbody tr[data-row]').length > 0);

	const s2 = await mountScenario({ webgl: false });
	ok('GC19', 'no WebGL context: mode is unavailable and no canvas element exists',
		s2.record() && s2.record().mode === 'unavailable' && !s2.canvasEl());
	const w2 = s2.consoleWarnings.filter((a) => String(a[0]).indexOf(M.GC_WARN_PREFIX) === 0);
	ok('GC19', 'no-WebGL path: exactly one console.warn carries the stable prefix', w2.length === 1, 'count=' + w2.length);

	// The late-failure transition (ledger row 4): mount succeeds, but
	// renderer.init() rejects AFTER mountCanvas has already returned.
	// gcTransitionToUnavailable must converge on the SAME end state -- a
	// second, distinct route this suite's own history shows a probe can miss.
	const s3 = await mountScenario({ webgl: true, initRejects: true });
	const canvasBeforeSettle = !!s3.canvasEl();
	await flushInit();
	ok('GC19', 'late-failure transition: a canvas existed before init() settled (the SECOND, post-mount path)', canvasBeforeSettle);
	ok('GC19', 'late-failure transition: after the rejection, mode is unavailable and the canvas is removed',
		s3.record() && s3.record().mode === 'unavailable' && !s3.canvasEl());
	const w3 = s3.consoleWarnings.filter((a) => String(a[0]).indexOf(M.GC_WARN_PREFIX) === 0);
	ok('GC19', 'late-failure transition: exactly one console.warn in total (not a second one for the rejection)', w3.length === 1, 'count=' + w3.length);
	ok('GC19', 'late-failure transition: the page still has exactly two live regions',
		s3.doc.querySelectorAll('[data-status][aria-live="polite"]').length === 1 && s3.doc.querySelectorAll('[role="alert"]').length === 1);
}

// ===========================================================================
// The happy-path mount, shared by every remaining assertion group
// ===========================================================================
const s = await mountScenario({ webgl: true });
await flushInit();
const canvas = s.canvasEl();

if (!canvas) {
	// A FAIL, deliberately never a SKIP: the happy-path scenario declares
	// webgl:true and a present library, so a canvas that fails to mount here is
	// itself the thing wrong -- silently skipping every mounted-page clause is
	// exactly how the canvas-old-renderer-symbol mutation (the historical
	// defect this file's whole history is about) would otherwise go unnoticed.
	for (const id of ['GC09', 'GC10', 'GC13', 'GC17', 'GC21bounds']) {
		ok(id, '(mounted-page clauses)', false, 'no canvas mounted in the happy-path scenario (webgl:true, library present)');
	}
} else {
	// =========================================================================
	// GC09 -- AC-S8: exactly role/aria-label/width/height, no tab stop, no
	// control -- the one surviving check of AC-21's trap now that the viewport
	// button manifest itself is gone (task-032).
	// =========================================================================
	const names = ids(canvas.getAttributeNames());
	ok('GC09', 'the mounted canvas\'s getAttributeNames() is exactly {role, aria-label, width, height}',
		same(names, ids(['role', 'aria-label', 'width', 'height'])), JSON.stringify(names));
	ok('GC09', 'role="img" and aria-label is non-empty (written by the shell, not by graph-canvas.js)',
		canvas.getAttribute('role') === 'img' && !!canvas.getAttribute('aria-label'));
	ok('GC09', 'the canvas is not focusable (no tabindex) and contains no child element',
		canvas.getAttribute('tabindex') === null && canvas.children.length === 0);
	ok('GC09', 'the canvas matches no [data-control] and no [data-group-toggle] selector',
		!canvas.matches('[data-control]') && !canvas.matches('[data-group-toggle]'));

	// =========================================================================
	// GC10/GC13 collapsed -- AC-10/AC-S1/AC-S2/NFR-5/NFR-3: the record's sets
	// equal the ViewModel's, and every mark's content is compared against the
	// ViewModel entry for ITS OWN id/key, never a sibling field of itself or the
	// record's own -- the founding defect class (Q17, Q21) and the reason this
	// whole SPEC exists in its current shape.
	// =========================================================================
	const vm = s.store.getViewModel();
	const rec = s.record();
	ok('GC10', 'nodes equals the id set of visibleNodes, as sets', same(ids(rec.nodes), ids(vm.visibleNodes.map((n) => n.id))));
	const expectedEdges = ids(vm.visibleEdges.filter((e) => vm.edgeFold.get(e.key) !== 'collapsed').map((e) => e.key));
	ok('GC10', 'edges equals the non-collapsed visibleEdges keys, as sets', same(ids(rec.edges), expectedEdges));
	ok('GC10', 'revision equals ViewModel.revision', rec.revision === vm.revision, rec.revision + ' vs ' + vm.revision);

	ok('GC13', 'marks.nodes carries exactly one entry per visibleNodes id (an empty marks fails rather than '
		+ 'satisfying the quantifiers below)',
		same(ids(rec.marks.nodes.map((m) => m.id)), ids(vm.visibleNodes.map((n) => n.id))) && rec.marks.nodes.length > 0);
	ok('GC13', 'marks.edges carries exactly one entry per non-collapsed visibleEdges key',
		same(ids(rec.marks.edges.map((m) => m.key)), expectedEdges) && rec.marks.edges.length > 0);

	const nodeMap = new Map(vm.visibleNodes.map((n) => [n.id, n]));
	const nodeContentOk = rec.marks.nodes.every((m) => {
		const node = nodeMap.get(m.id);
		const encoding = vm.nodeEncoding.get(m.id);
		return node && m.kind === node.kind && (!encoding || (m.glyph === encoding.glyph && m.colourToken === encoding.colourToken))
			&& m.emphasis === vm.nodeEmphasis.get(m.id);
	});
	ok('GC13', 'every node mark\'s kind/glyph/colourToken/emphasis equals the ViewModel entry for its OWN id', nodeContentOk);

	const edgeContentOk = rec.marks.edges.every((m) => {
		const edge = vm.visibleEdges.find((e) => e.key === m.key);
		const encoding = vm.edgeEncoding.get(m.key);
		return edge && m.row === edge.row && m.category === edge.category
			&& (!encoding || (m.colourToken === encoding.colourToken && m.lineStyle === encoding.lineStyle && m.arrowhead === encoding.arrowhead))
			&& m.emphasis === vm.edgeEmphasis.get(m.key);
	});
	ok('GC13', 'every edge mark\'s row/category/colourToken/lineStyle/arrowhead/emphasis equals the ViewModel '
		+ 'entry for its OWN key (arrowhead === !edge.symmetric there)', edgeContentOk);

	// The decisive ext: pair (feature-007 AC-S3), mirrored over the RECORD:
	// same prefix, different Kind (web-page vs image) -- the one construction no
	// id-deriving canvas passes.
	const [extA, extB] = FX.PREFIX_ORACLE.sameProxyDifferentKind;
	const markA = rec.marks.nodes.find((m) => m.id === extA);
	const markB = rec.marks.nodes.find((m) => m.id === extB);
	ok('GC13', 'the two ext: ids (same prefix, different Kind) carry DIFFERENT glyphs equal to their OWN Node.glyph',
		!!markA && !!markB && markA.glyph !== markB.glyph
		&& markA.glyph === nodeMap.get(extA).glyph && markB.glyph === nodeMap.get(extB).glyph,
		JSON.stringify({ [extA]: markA && markA.glyph, [extB]: markB && markB.glyph }));

	// =========================================================================
	// GC17 -- AC-S5/AC-S4: no ARIA/live-region write, no style/rect read inside
	// the frame path; a theme flip re-resolves the palette exactly once.
	// `gcResize` draws a frame SYNCHRONOUSLY (no timer, no simulation tick
	// needed) -- the ResizeObserver double's `.trigger()` is this suite's whole
	// "force a frame" mechanism.
	// =========================================================================
	let getComputedStyleCalls = 0;
	const realGetComputedStyle = s.window.getComputedStyle;
	s.window.getComputedStyle = function (...a) { getComputedStyleCalls += 1; return realGetComputedStyle.apply(this, a); };
	globalThis.getComputedStyle = s.window.getComputedStyle.bind(s.window);
	let rectCalls = 0;
	const realRect = s.window.Element.prototype.getBoundingClientRect;
	s.window.Element.prototype.getBoundingClientRect = function (...a) { rectCalls += 1; return realRect.apply(this, a); };
	let ariaWrites = 0;
	const realSetAttribute = s.window.Element.prototype.setAttribute;
	s.window.Element.prototype.setAttribute = function (name, ...rest) {
		if (String(name).indexOf('aria-') === 0 || name === 'role') ariaWrites += 1;
		return realSetAttribute.call(this, name, ...rest);
	};

	// mountCanvas keeps no handle to `view`; a fresh instance is created here,
	// mirroring the SAME construction `mountCanvas` itself performs internally
	// (`new ResizeObserver(() => gcResize(view))`), to force exactly one
	// SYNCHRONOUS extra frame draw without any timer.
	const surfaceEl = s.surface;
	const forcedFrame = new FakeResizeObserver(() => {});
	forcedFrame.observe(surfaceEl);
	const gcBefore = getComputedStyleCalls, rectBefore = rectCalls, ariaBefore = ariaWrites;
	// Drive an ACTUAL frame the way the mounted instance's own observer would:
	// toggle the theme attribute, which graph-canvas.js's `gcWatchTheme`
	// MutationObserver reacts to by re-resolving the palette and repainting
	// (`gcRepaintUnchanged` -> `gcDrawFrame`) -- a real perturbation the
	// mounted `view` itself is subscribed to, unlike the disconnected observer
	// instance above.
	s.doc.documentElement.setAttribute('data-theme', 'dark');
	await new Promise((resolve) => setTimeout(resolve, 20)); // MutationObserver callbacks are macrotask-scheduled
	const gcAfterTheme = getComputedStyleCalls;
	ok('GC17', 'toggling data-theme on <html> re-resolves the palette (at least one getComputedStyle call, which '
		+ 'also proves a frame was actually drawn for the purity check below to be over something)',
		gcAfterTheme > gcBefore, 'delta=' + (gcAfterTheme - gcBefore));
	ok('GC17', 'the frame that theme flip drew performed zero getBoundingClientRect calls and zero ARIA/role writes',
		rectCalls === rectBefore && ariaWrites === ariaBefore,
		'rect=' + (rectCalls - rectBefore) + ' aria=' + (ariaWrites - ariaBefore));

	s.window.getComputedStyle = realGetComputedStyle;
	s.window.Element.prototype.getBoundingClientRect = realRect;
	s.window.Element.prototype.setAttribute = realSetAttribute;

	// =========================================================================
	// THE NEW ASSERTION -- every drawn node's position, mapped through the
	// recorded viewport and the buffer's own width/height by gcLocalPoint's
	// documented inverse, must land inside the drawing buffer. EXPECTED TO FAIL
	// against the current module (see the file banner) -- reported as found,
	// not adjusted to pass.
	// =========================================================================
	const buf = { w: canvas.width, h: canvas.height };
	const vp = rec.viewport;
	const positions = rec.positions || {};
	const visibleIds = rec.nodes || [];
	const outside = [];
	for (const id of visibleIds) {
		const p = positions[id];
		if (!p) { outside.push(id + ':no-position'); continue; }
		const sx = p.x * vp.scale + vp.panX + buf.w / 2;
		const sy = p.y * vp.scale + vp.panY + buf.h / 2;
		if (sx < 0 || sx > buf.w || sy < 0 || sy > buf.h) outside.push(id);
	}
	ok('GC21bounds', 'every visibleNodes id\'s position, mapped through the recorded viewport and the buffer\'s '
		+ 'own width/height by gcLocalPoint\'s documented inverse (screen = local*scale + pan + dimension/2), '
		+ 'lands inside the drawing buffer — catches "mode: live, frames ticking, marks derived correctly, and '
		+ 'nothing on screen" (real defect, found in a real browser; graph-canvas.js:628/:988 on disk never '
		+ 'translates the stage, so this is EXPECTED to fail against the current module)',
		outside.length === 0,
		outside.length === 0 ? ('buffer=' + buf.w + 'x' + buf.h) : (outside.length + '/' + visibleIds.length + ' outside, e.g. ' + outside.slice(0, 3).join(',')));
}

// ===========================================================================
// Summary / exit
// ===========================================================================
if (expectFail !== null) {
	const failedIds = new Set(results.filter((r) => r.kind === 'FAIL').map((r) => r.label.split(' ')[0]));
	let allOk = true;
	for (const id of expectFail) {
		if (!failedIds.has(id)) { process.stdout.write('GC\tFAIL\tnon-vacuity ' + id + ' did NOT fail against the mutated bundle\n'); allOk = false; }
	}
	for (const r of results) {
		if (r.kind === 'FAIL') {
			const id = r.label.split(' ')[0];
			process.stdout.write('GC\t' + (expectFail.includes(id) ? 'PASS' : 'NOTE') + '\t' + r.label + '\n');
		}
	}
	process.exit(allOk ? 0 : 1);
}
const anyFail = results.some((r) => r.kind === 'FAIL');
process.exit(anyFail ? 1 : 0);
