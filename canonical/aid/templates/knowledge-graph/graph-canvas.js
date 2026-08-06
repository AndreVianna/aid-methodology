/* ============================================================================
 * graph-canvas.js -- the drawing rendering (feature-008, task-017).
 *
 * The second of the two peer renderings. It draws visibleNodes/visibleEdges as
 * a live, physically-simulated bitmap and hosts every pointer gesture the
 * drawing surface offers. It is visual-only -- the table rendering carries the
 * accessibility standard for the whole artifact -- and it mounts LAST, after
 * the table, and OPTIONALLY: with no working library or no WebGL context it
 * degrades to `mode: 'unavailable'` and the rest of the page stays fully
 * usable (AC-S10).
 *
 * WHERE THIS FILE RUNS
 *   Inside the page's single inline module block, concatenated after
 *   graph-model.js, graph-controls.js and graph-table.js (`build-graph-src.mjs`
 *   :181, auto-detected -- no edit there landed this file). That is ONE module
 *   scope, so this file declares no loading statement and reaches
 *   `registerRendering`, `el`, `clear`, `byId`, `KIND_ENCODING`,
 *   `CATEGORY_ENCODING`, `compareStrings` by plain reference. ONE SCOPE IS A
 *   CONSTRAINT: every top-level declaration below except `mountCanvas` itself
 *   is prefixed `GC_`/`gc`, and the generic names the earlier files own --
 *   basename, bump, clear, el, slug, unquote, toInteger, ellipsise, prefixOf,
 *   compareStrings, narrate, project, byId -- are reused rather than
 *   redeclared.
 *
 * THE TWO GLOBALS THIS FILE READS, AND WHAT IT ASSUMES OF EACH
 *   `d3` and `PIXI` are read as GLOBALS from classic `<script src>` builds
 *   loaded before this module block -- never imported, never fetched. Neither
 *   is vendored yet (packaging is task-023's, which depends on this file); the
 *   contract below is what task-023 has to satisfy, stated at the CAPABILITY
 *   level rather than by exact symbol, because the adopted version is
 *   feature-002 Stage 3's to fix:
 *     - `d3`: a force-simulation build exposing `forceSimulation(nodes)`,
 *       chainable `.force(name, force)` with `forceManyBody()`, `forceLink
 *       (links).id(fn)`, `forceCenter(x, y)`, `forceCollide(radius)`, and
 *       `.alpha()/.alphaTarget()/.restart()/.stop()/.on('tick', fn)` -- the
 *       d3-force v2/v3 shape.
 *     - `PIXI`: a WebGL 2D scene-graph library exposing `new PIXI.WebGLRenderer()`
 *       (no constructor arguments -- v8 moved every option to the separate,
 *       asynchronous `renderer.init({view, width, height, antialias,
 *       backgroundAlpha})`, a `Promise<void>`), `PIXI.Container`, `PIXI.Graphics`
 *       with `lineStyle`/`beginFill`/`drawCircle`/`drawRect`/`drawPolygon`/
 *       `moveTo`/`lineTo`, and `PIXI.Text`. This module drives its own
 *       `requestAnimationFrame` loop and calls `renderer.render(stage)`
 *       explicitly, only once `init()` has resolved -- the "draw call this
 *       feature controls the timing of" the SPEC names -- rather than PIXI's
 *       own ticker.
 *   Absence of either global, a failure constructing the renderer, no WebGL
 *   context obtainable from a scratch canvas, OR a later rejection of the
 *   renderer's own asynchronous `init()` all resolve to the SAME outcome:
 *   `mode: 'unavailable'` (AC-S10) -- the last of those arrives after
 *   `mountCanvas` has already returned, so it is a TRANSITION into that state
 *   (`gcTransitionToUnavailable`) rather than a return from it.
 *
 * WHAT THIS FILE NEVER READS
 *   `Node.prefix` is read NOWHERE in this file, and no prefix literal (`kb`,
 *   `int`, `ext`) appears in it: a node's class for every drawing purpose
 *   comes from `Node.kind` and the projection's own maps, never from where an
 *   id came from. `lensState.zoom` is the ONLY `LensState` field this file
 *   reads (AC-S2) -- no membership, emphasis, grouping, fold or label decision
 *   is computed here; every one of those is `project()`'s alone and arrives
 *   already decided on the `ViewModel`.
 *
 * COLOUR: RESOLVED FROM CSS, NEVER A LITERAL, NEVER INSIDE A FRAME
 *   Every colour this file draws with is read from a CSS custom property
 *   (`--gk-*`/`--gc-*`) or, under forced-colours, from the `.gc-colour-probe`
 *   element's computed `color`/`backgroundColor` (graph-css.css). That read
 *   happens exactly at two invalidation points -- a `data-theme` change and a
 *   `forcedColours` preference change -- and is cached in `GC_PALETTE`
 *   (private structure `palette`, D2). The frame path performs no DOM style
 *   read of any kind (AC-S4, AC-S5).
 * ========================================================================== */


/* ==========================================================================
 * 1. Constants -- every one a labelled design choice, none a requirement's
 *    figure. Tuning belongs to the mandatory human visual gate.
 * ========================================================================== */

/** Ring length for the per-frame instrumentation window (D3 `frames`). Sized
 *  to comfortably cover a steady-state sampling window and a drag window. */
const GC_FRAME_RING = 240;

/** Force constants, the one place they are tuned. `density`/grouping never
 *  reach here as a value -- FR-14a forbids exposing any physics parameter and
 *  no `LensState` field names one. */
const GC_FORCE = Object.freeze({
	charge: -220,
	linkDistance: 70,
	linkStrength: 0.5,
	collideRadius: 16,
	centerStrength: 0.04,
	groupStrength: 0.06,
});

/** The settle budget for the reduced-motion pre-first-paint layout: a fixed
 *  iteration cap with an early exit on a movement threshold. */
const GC_SETTLE_MAX_TICKS = 300;
const GC_SETTLE_MOVE_THRESHOLD = 0.01;

/** The idle threshold the live loop stops requesting frames at, and resumes
 *  from on any perturbation. */
const GC_IDLE_ALPHA = 0.001;

/** Viewport step factors for the keyboard-driven manifest controls (D8). */
const GC_ZOOM_STEP = 1.25;
const GC_PAN_STEP = 60;
const GC_ZOOM_MIN = 0.1;
const GC_ZOOM_MAX = 8;

/** Emphasis channel magnitudes -- the ordinal floor/ceiling, one place each. */
const GC_DIM_OPACITY = 0.35;
const GC_FOCUS_SCALE = 1.45;
const GC_CHAIN_WEIGHT = 2.5;
const GC_BASE_WEIGHT = 0.75;
const GC_BASE_RADIUS = 8;

/** Arrowhead length in world units, and the clearance left between a glyph's
 *  edge and the line or arrow tip that meets it.
 *
 *  Marks are drawn at their simulation position, which is the glyph's CENTRE,
 *  so an edge drawn plainly from one position to the other runs UNDER both
 *  glyphs and its arrow tip lands at the target's centre -- the arrow reads as
 *  pointing at nothing, and its direction is hidden by the glyph on top of it.
 *  `gcTrimSegment` pulls both ends back by the glyph radius plus this gap, so
 *  the tip touches the border instead.
 *
 *  The gap is deliberately non-zero: `GC_BASE_RADIUS` is a CIRCUMradius, and
 *  the flat-sided kinds (square, pentagon, diamond, hexagon) sit inside it, so
 *  a zero gap would still tuck the tip slightly under those shapes along their
 *  faces. A small constant clearance reads correctly for every kind without
 *  per-shape geometry. */
/**
 * How much the HOVERED mark alone is lifted -- a node's radius, an edge's stroke
 * weight -- plus the opacity a hovered mark is raised to.
 *
 * Scope, owner's ruling: **the hovered mark, and nothing else.** The SPEC also
 * described dimming the rest and lighting the neighbourhood, and
 * `reveal.neighbourhood` is computed on every hover for exactly that -- the owner
 * tried it and withdrew it: the label already says what the mark is, so
 * highlighting the one mark under the pointer is enough. So `neighbourhood` stays
 * published and deliberately undrawn.
 *
 * Size and weight rather than a ring, because a ring already means `focus`
 * (`emphasisDraw.ring`) -- and rather than colour, because colour already carries
 * kind on a node and category on an edge. Scale is also the one channel that
 * survives forced colours, where opacity is null and `markScale`/`weight` are
 * what the ordinal channel already rides on.
 *
 * Raising opacity matters as much as the size: under the Coverage and Provenance
 * lenses most marks are deliberately dimmed, and a dimmed mark that grows but
 * stays faint does not read as picked out.
 */
const GC_HOVER_SCALE = 1.4;
const GC_HOVER_WEIGHT = 2.6;
const GC_HOVER_OPACITY = 1;

const GC_ARROW_SIZE = 5;
const GC_EDGE_GAP = 1.5;

/** Clearance between a kind glyph's outline and its gap badge. Small on
 *  purpose: the badge has to read as belonging to that node rather than
 *  floating near it, and it is the only thing in the drawing whose meaning
 *  depends on which mark it is attached to. */
const GC_BADGE_CLEARANCE = 1.5;

/** Label legibility floor in CSS pixels, the on-canvas persistent label is
 *  suppressed (never shrunk) below it. Taken from `validate-visuals.mjs`'s own
 *  10px default as a reference point, not a citation of a shared value. */
const GC_LABEL_FLOOR_PX = 10;

/** The hover reveal chip: text size in CSS pixels (above the floor above, and
 *  held there at every zoom by counter-scaling rather than by shrinking), and
 *  the padding between the text and the chip's edge. */
const GC_LABEL_FONT_PX = 12;
const GC_LABEL_PAD = 4;
const GC_LABEL_FONT_FAMILY = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

/** Device-pixel-ratio cap on the backing store, so a high-DPR display cannot
 *  multiply fill cost without bound. */
const GC_DPR_CAP = 2;

/** Pointer-picking radius, in CSS pixels, around a mark's centre. */
const GC_PICK_RADIUS = 10;

/** The two gap badge glyphs, additive and never inside the kind glyph. */
const GC_BADGE = Object.freeze({ 'kb-unbacked': '≈', 'artifact-undocumented': '‡' });

/**
 * The gap badge's colour token per class -- SEVERITY, not kind, which is why it
 * is not on `KIND_ENCODING`'s axis and why the badge cannot reuse the node's own
 * colour: the fill already carries kind, and two meanings on one small mark
 * cannot both be read.
 *
 * These are the shared status tokens the surrounding document already defines
 * and theme-switches, and the SAME two `graph-table.js` gives these two classes
 * -- so the canvas and the table agree by construction rather than by a comment
 * asking someone to keep them in step. No colour literal is authored here
 * (AC-S4): the value is resolved from the stylesheet like every other token.
 *
 * Unbacked takes the error token and undocumented the warning token, per the
 * owner's severity ruling recorded on `gcDrawBadge`.
 */
const GC_BADGE_TOKEN = Object.freeze({ 'kb-unbacked': '--err', 'artifact-undocumented': '--warn' });

/** The stable console prefix AC-S10 fixes. */
const GC_WARN_PREFIX = 'graph.html: canvas unavailable';


/* ==========================================================================
 * 2. Capability -- both unavailability paths resolve here, once, at mount
 * ========================================================================== */

/** @returns {boolean} the two library globals are present at the capability
 *  level this file depends on. `PIXI.Renderer` is a TYPE-ONLY export in v8 --
 *  no runtime constructor exists under that name -- so this probes for
 *  `PIXI.WebGLRenderer`, exactly the constructor `mountCanvas` below actually
 *  calls. Never probe for one symbol and construct another: that gap is what
 *  let this capability check pass while construction always failed. */
function gcHasLibraries() {
	return typeof d3 !== 'undefined' && typeof d3.forceSimulation === 'function'
		&& typeof PIXI !== 'undefined' && typeof PIXI.WebGLRenderer === 'function';
}

/** @returns {boolean} a WebGL context can be obtained from a scratch canvas,
 *  independent of whether PIXI itself can construct a renderer. */
function gcHasWebGL() {
	try {
		const probe = document.createElement('canvas');
		const ctx = probe.getContext('webgl2') || probe.getContext('webgl') || probe.getContext('experimental-webgl');
		return !!ctx;
	} catch (error) {
		return false;
	}
}


/* ==========================================================================
 * 3. The palette cache -- D2's `palette`
 * ========================================================================== */

/** Every colour TOKEN NAME this file will ever resolve, taken from the
 *  vocabularies graph-model.js already builds rather than re-typed here. */
function gcColourTokens() {
	const tokens = new Set();
	for (const entry of Object.values(KIND_ENCODING)) tokens.add(entry.colourToken);
	for (const entry of Object.values(CATEGORY_ENCODING)) tokens.add(entry.colourToken);
	// The gap badge's severity tokens are on neither encoding's axis, so they
	// have to be added explicitly or `gcResolvePalette` would never resolve them
	// and every badge would fall back to the forced foreground.
	for (const token of Object.values(GC_BADGE_TOKEN)) tokens.add(token);
	return Array.from(tokens);
}

/** Find or create the hidden forced-colours probe element, once. */
function gcEnsureProbe(root) {
	let probe = root.querySelector('.gc-colour-probe');
	if (!probe) {
		probe = el('div', { class: 'gc-colour-probe', 'aria-hidden': 'true' });
		(root.body || root).appendChild(probe);
	}
	return probe;
}

/**
 * Resolve every token this build uses against the current stylesheet, plus
 * the two forced-colours system colours from the probe. Called ONLY at mount
 * and at the two invalidation points (a `data-theme` flip, a `forcedColours`
 * preference flip) -- never inside the frame path (AC-S4, AC-S5).
 *
 * @param {Document} root
 * @returns {Map<string,string>}
 */
function gcResolvePalette(root) {
	const style = getComputedStyle(root.documentElement);
	const probe = gcEnsureProbe(root);
	const probeStyle = getComputedStyle(probe);
	const map = new Map();
	for (const token of gcColourTokens()) map.set(token, style.getPropertyValue(token).trim());
	map.set('__forced_fg', probeStyle.color);
	map.set('__forced_bg', probeStyle.backgroundColor);
	return map;
}

/** The colour a mark draws with: the resolved token, or the single forced
 *  foreground when forced-colours is active -- never a literal either way. */
function gcColourFor(palette, token, forcedColours) {
	if (forcedColours) return palette.get('__forced_fg') || 'CanvasText';
	return palette.get(token) || palette.get('__forced_fg') || 'CanvasText';
}


/* ==========================================================================
 * 4. Deterministic seeding and the private `positions` structure (D2)
 * ========================================================================== */

/** A small, stable string hash (FNV-1a), so a node's initial position is a
 *  pure function of its id and one fixture yields one arrangement across
 *  runs (GC08/GC16). */
function gcHash(text) {
	let h = 0x811c9dc5;
	for (let i = 0; i < text.length; i += 1) {
		h ^= text.charCodeAt(i);
		h = Math.imul(h, 0x01000193);
	}
	return h >>> 0;
}

/** A deterministic seed position for a fresh node, spread over a large disc
 *  so the initial layout is not degenerate at the origin. */
function gcSeedPosition(id) {
	const h = gcHash(id);
	const angle = (h % 3600) / 3600 * Math.PI * 2;
	const radius = 40 + ((h >>> 8) % 400);
	return { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius };
}

/** A newly-admitted node's placement: the centroid of its already-placed
 *  neighbours (or of its group where it has none), else the deterministic
 *  seed. A membership change therefore rearranges the picture locally instead
 *  of relaunching it (AC-S3). */
function gcPlaceNewNode(id, positions, neighbourIds) {
	const known = neighbourIds.filter((n) => positions.has(n));
	if (known.length > 0) {
		let sx = 0, sy = 0;
		for (const n of known) { const p = positions.get(n); sx += p.x; sy += p.y; }
		return { x: sx / known.length + (gcHash(id) % 20) - 10, y: sy / known.length + (gcHash(id + '#') % 20) - 10 };
	}
	return gcSeedPosition(id);
}


/* ==========================================================================
 * 5. The draw record -- D3's published interface, `window.__aidGraphCanvas`
 * ========================================================================== */

/** A fresh, empty record, the shape every consumer can rely on regardless of
 *  `mode`. */
function gcEmptyRecord() {
	return {
		revision: 0,
		mode: 'unavailable',
		forcedColours: false,
		nodes: [],
		edges: [],
		marks: { nodes: [], edges: [] },
		reveal: { kind: null, target: null, text: '', neighbourhood: [] },
		captions: { counts: '', groups: [] },
		viewport: { scale: 1, panX: 0, panY: 0 },
		positions: {},
		frames: [],
	};
}

/** Publish the one global this file creates, mirroring graph-controls.js's own
 *  `publishHandle` -- one name, read-and-attach, never a second write route. */
function gcPublishRecord(record) {
	if (typeof window !== 'undefined') window.__aidGraphCanvas = record;
	return record;
}

/**
 * Derive this projection's marks from the `ViewModel` alone (AC-10, AC-S1).
 * `sourceId`/`targetId` on an edge mark are `edgeFold`'s resolved endpoints,
 * never `Edge.sourceId`/`targetId` (rule 7) -- so the drawn line is always
 * between the ids the fold names and the raw ids are cited on the mark only
 * to let an assertion name the row it came from.
 *
 * @param {object} viewModel
 * @param {boolean} forcedColours
 * @returns {{nodeMarks: Map, edgeMarks: Map}}
 */
function gcDeriveMarks(viewModel, forcedColours) {
	const nodeMarks = new Map();
	for (const node of viewModel.visibleNodes) {
		const encoding = viewModel.nodeEncoding.get(node.id);
		const emphasis = viewModel.nodeEmphasis.get(node.id) || 'normal';
		const gapBadge = viewModel.coverageGaps.kbUnbacked.indexOf(node.id) !== -1 ? 'kb-unbacked'
			: (viewModel.coverageGaps.artifactUndocumented.indexOf(node.id) !== -1 ? 'artifact-undocumented' : null);
		nodeMarks.set(node.id, {
			id: node.id,
			kind: node.kind,
			glyph: node.glyph,
			colourToken: encoding ? encoding.colourToken : null,
			emphasis: emphasis,
			emphasisDraw: gcNodeEmphasisDraw(emphasis, forcedColours),
			gapBadge: gapBadge,
			labelDrawn: false,
		});
	}

	const edgeMarks = new Map();
	for (const edge of viewModel.visibleEdges) {
		const fold = viewModel.edgeFold.get(edge.key);
		if (fold === 'collapsed') continue;
		const encoding = viewModel.edgeEncoding.get(edge.key);
		const emphasis = viewModel.edgeEmphasis.get(edge.key) || 'normal';
		edgeMarks.set(edge.key, {
			key: edge.key,
			row: edge.row,
			sourceId: fold.sourceId,
			targetId: fold.targetId,
			category: edge.category,
			colourToken: encoding ? encoding.colourToken : null,
			lineStyle: encoding ? encoding.lineStyle : 'solid',
			arrowhead: encoding ? encoding.arrowhead : false,
			emphasis: emphasis,
			emphasisDraw: gcEdgeEmphasisDraw(emphasis, forcedColours),
		});
	}

	return { nodeMarks: nodeMarks, edgeMarks: edgeMarks };
}

/** One node class's drawn channels. Colour-mode carries the ordinal in
 *  opacity; forced-colours carries it in mark scale instead (§ Forced
 *  colours), so `opacity` is `null` there and never both are active at once. */
function gcNodeEmphasisDraw(emphasis, forcedColours) {
	const focus = emphasis === 'focus';
	const dimmed = emphasis === 'dimmed';
	const scale = focus ? GC_FOCUS_SCALE : 1;
	return {
		opacity: forcedColours ? null : (dimmed ? GC_DIM_OPACITY : 1),
		markScale: forcedColours ? (dimmed ? 1 : scale) : scale,
		ring: focus,
	};
}

/** One edge class's drawn channels -- stroke weight is the forced-colours
 *  substitute for opacity, free because no relation property ever drives
 *  width (the `Strength` column was dropped). */
function gcEdgeEmphasisDraw(emphasis, forcedColours) {
	const chain = emphasis === 'chain';
	const dimmed = emphasis === 'dimmed';
	const weight = chain ? GC_CHAIN_WEIGHT : GC_BASE_WEIGHT;
	return {
		opacity: forcedColours ? null : (dimmed ? GC_DIM_OPACITY : 1),
		weight: forcedColours ? weight : GC_BASE_WEIGHT,
	};
}


/* ==========================================================================
 * 6. mountCanvas -- the whole flow
 * ========================================================================== */

/**
 * @param {{store: object, graphModel: object, region: Element, surface: Element, root: (Document|Element)}} context
 * @returns {{viewportFor: function(string): (object|undefined)}|undefined}
 */
function mountCanvas(context) {
	const surface = context && context.surface ? context.surface : null;
	if (!surface || !context.store) {
		console.error('graph.html: the drawing rendering found no surface to mount into');
		return undefined;
	}
	const root = context.root && context.root.nodeType ? (context.root.ownerDocument || document) : document;
	const store = context.store;

	if (!gcHasLibraries() || !gcHasWebGL()) {
		return gcMountUnavailable(surface, store);
	}

	let renderer;
	let canvasEl;
	try {
		canvasEl = document.createElement('canvas');
		// This module writes NO attribute on the element it creates here beyond
		// the `width`/`height` the sizing rule (`gcResize`) sets once this is
		// appended below -- those two ARE the drawing buffer itself, and they
		// are the only attributes AC-S8 is stated against. `role="img"` and
		// `aria-label` are the shell's to write (`graph-controls.js`, owned per
		// feature-007 :1718): once `mountCanvas` returns, the shell finds this
		// element by tag, scoped to the drawing surface it already holds, and
		// writes both there -- no marker attribute of any kind needs to exist
		// on this element for that lookup to work.
		// `WebGLRenderer`'s own constructor takes NO arguments in v8 -- every
		// option v7's single-call `new PIXI.Renderer({...})` accepted moved to
		// the separate, asynchronous `init()` kicked off below, once `view` (D2)
		// exists to hand its rejection to.
		renderer = new PIXI.WebGLRenderer();
	} catch (error) {
		return gcMountUnavailable(surface, store);
	}

	surface.appendChild(canvasEl);
	const stage = new PIXI.Container();
	const edgeLayer = new PIXI.Container();
	const nodeLayer = new PIXI.Container();
	const labelLayer = new PIXI.Container();
	stage.addChild(edgeLayer, nodeLayer, labelLayer);

	const view = {
		root: root,
		store: store,
		surface: surface,
		canvas: canvasEl,
		renderer: renderer,
		stage: stage,
		edgeLayer: edgeLayer,
		nodeLayer: nodeLayer,
		labelLayer: labelLayer,
		// D2's four private structures.
		positions: new Map(),
		palette: gcResolvePalette(root),
		index: gcMakeIndex(),
		text: new Map(),
		// The one graph-private viewport transform.
		viewport: { scale: 1, panX: 0, panY: 0 },
		simulation: null,
		record: gcEmptyRecord(),
		hover: null,
		drag: null,
		// The last press: which mark was under the pointer when the button went
		// down, and whether the pointer then moved far enough to be a drag. Held
		// separately from `drag` because `gcOnPointerUp` clears that before the
		// platform dispatches `click`, and because selection must read the press
		// rather than re-pick -- see `gcOnClick`.
		press: null,
		frameHandle: null,
		lastNodeIds: new Set(),
		lastGroupKey: '',
		// The ONLY thing gated on `renderer.init()` settling. Every draw call up
		// to and including `gcDrawFrame` runs exactly as it always has -- the
		// stage's children are rebuilt on every tick regardless -- only the
		// actual GPU `render()` call (`gcResize`, `gcDrawFrame`) is withheld
		// until this turns true, so a tick that lands before `init()` resolves
		// is deferred, never dropped.
		rendererReady: false,
	};

	gcWatchTheme(view);
	view.unsubscribePreferences = store.subscribePreferences((prefs) => gcOnPreferencesChange(view, prefs));

	gcResize(view);
	if (typeof ResizeObserver === 'function') {
		const ro = new ResizeObserver(() => gcResize(view));
		ro.observe(surface);
		view.resizeObserver = ro;
	}

	gcBindPointerEvents(view);

	const prefs = store.getPreferences();
	view.record.mode = prefs.reducedMotion ? 'settled' : 'live';
	gcSyncViewport(view, store.getLens());
	gcApplyProjection(view, store.getViewModel(), true);

	view.unsubscribe = store.subscribe((viewModel, lens, changedKeys) => { gcOnNotify(view, viewModel, lens, changedKeys); });

	// The deferred half of construction. `mountCanvas` itself returns
	// synchronously below, before this promise ever settles -- its caller
	// (`graph-controls.js` :923) reads `handle.viewportFor` the instant this
	// call returns, so nothing here is awaited and `mountCanvas` exports no
	// promise of its own. A resolve flips `rendererReady` and performs the
	// one `render()` call every prior tick withheld (`view.stage`'s children
	// are already current, built by those same withheld ticks); a reject --
	// no WebGL context obtainable from THIS canvas via THIS renderer, despite
	// the scratch probe in `gcHasWebGL` above having found one from a
	// DIFFERENT canvas -- transitions the already-mounted view into the
	// AC-S10 end state, after the fact (`gcTransitionToUnavailable`).
	renderer.init({ view: canvasEl, antialias: true, backgroundAlpha: 0, width: 10, height: 10 }).then(() => {
		view.rendererReady = true;
		if (view.renderer && typeof view.renderer.resize === 'function') {
			view.renderer.resize(view.canvas.width, view.canvas.height);
		}
		if (view.renderer && typeof view.renderer.render === 'function') view.renderer.render(view.stage);
	}).catch((error) => gcTransitionToUnavailable(view, error));

	return {
		viewportFor(action) { return gcViewportFor(view, action); },
	};
}

registerRendering('canvas', mountCanvas);

/** The `mode: 'unavailable'` path (AC-S10). No canvas, no gesture bound, a
 *  static sentence as ordinary text -- never a live region -- and one
 *  console.warn with the stable prefix. */
function gcMountUnavailable(surface, store) {
	const record = gcEmptyRecord();
	record.forcedColours = !!(store.getPreferences && store.getPreferences().forcedColours);
	const vm = store.getViewModel ? store.getViewModel() : null;
	if (vm) record.revision = vm.revision;
	gcPublishRecord(record);
	surface.appendChild(el('p', { class: 'graph-placeholder', text:
		'The live drawing surface needs a working WebGL context and this browser, or this build, does '
		+ 'not provide one. Nothing is lost: the relationship table below carries every relationship as '
		+ 'text, with the same lenses and the same filters applied to it.' }));
	console.warn(GC_WARN_PREFIX, { hasLibraries: gcHasLibraries(), hasWebGL: gcHasWebGL() });
	return undefined;
}

/**
 * The late-failure transition (ledger row 4, AC-S10). `gcMountUnavailable`
 * above only ever runs BEFORE a canvas exists -- `mountCanvas` has already
 * returned before `renderer.init()` can settle, so a rejection here finds a
 * canvas appended, gestures bound, the store subscribed to and (maybe) a
 * simulation already running. This neutralises every one of those in place,
 * then hands off to `gcMountUnavailable` for the actual end state -- ONE
 * fresh `mode: 'unavailable'` record published, ONE static sentence appended
 * to the same surface, ONE `console.warn` with `GC_WARN_PREFIX` -- so the two
 * paths converge on one outcome rather than producing two.
 *
 * `error` is deliberately not surfaced through a second warning of its own:
 * AC-S10 fixes exactly one `console.warn`, and `gcMountUnavailable` already
 * issues it.
 *
 * What this deliberately does NOT do: unbind the window-level `mousemove`/
 * `mouseup` listeners `gcBindPointerEvents` attached, or drop `view` itself.
 * Both are inert once `view.canvas` is detached (a detached element receives
 * no real pointer events, so `gcOnPointerDown` can never re-arm `view.drag`)
 * and `view.drag` is nulled below (so a drag already in flight at the exact
 * moment of this transition cannot keep publishing frames afterwards). A
 * general teardown (`gcUnmount`) that reclaims those listeners themselves,
 * and everything else this file never tears down (`view.themeObserver`
 * aside), is ledger row 6's, not this one's.
 *
 * @param {object} view
 * @param {*} error the `init()` rejection reason, unused beyond this comment
 */
function gcTransitionToUnavailable(view, error) {
	if (typeof view.unsubscribe === 'function') view.unsubscribe();
	if (typeof view.unsubscribePreferences === 'function') view.unsubscribePreferences();
	if (view.simulation) view.simulation.stop();
	view.simulation = null;
	if (view.resizeObserver) view.resizeObserver.disconnect();
	view.resizeObserver = null;
	if (view.themeObserver) view.themeObserver.disconnect();
	view.themeObserver = null;
	if (view.frameHandle) {
		if (typeof cancelAnimationFrame === 'function') cancelAnimationFrame(view.frameHandle);
		if (typeof clearTimeout === 'function') clearTimeout(view.frameHandle);
		view.frameHandle = null;
	}
	if (view.wheelCommitTimer) { clearTimeout(view.wheelCommitTimer); view.wheelCommitTimer = null; }
	view.drag = null;
	if (view.canvas && view.canvas.parentNode) view.canvas.parentNode.removeChild(view.canvas);
	view.rendererReady = false;
	view.renderer = null;
	gcMountUnavailable(view.surface, view.store);
}


/* ==========================================================================
 * 7. The spatial index (D2) -- this module's own code over `positions`
 * ========================================================================== */

/** A flat scan over the last-drawn node marks. Picking is bounded by the
 *  drawn node count, which the reader's own density and filter controls
 *  already bound; no third vendored library is needed for it. */
function gcMakeIndex() {
	return {
		entries: [],
		rebuild(positions, nodeIds) {
			this.entries = nodeIds.map((id) => ({ id: id, p: positions.get(id) })).filter((e) => e.p);
		},
		nearest(x, y, maxDist) {
			let best = null;
			let bestDist = maxDist * maxDist;
			for (const entry of this.entries) {
				const dx = entry.p.x - x;
				const dy = entry.p.y - y;
				const d2 = dx * dx + dy * dy;
				if (d2 <= bestDist) { bestDist = d2; best = entry.id; }
			}
			return best;
		},
	};
}


/* ==========================================================================
 * 8. Theme invalidation (D2 -- "verified, not assumed")
 * ========================================================================== */

/** A `MutationObserver` on `<html data-theme>`, the complete and cheapest
 *  invalidation trigger for the palette cache. No `getComputedStyle` call is
 *  made inside a frame. */
function gcWatchTheme(view) {
	if (typeof MutationObserver !== 'function') return;
	const target = view.root.documentElement;
	const observer = new MutationObserver(() => {
		view.palette = gcResolvePalette(view.root);
		gcRepaintUnchanged(view);
	});
	observer.observe(target, { attributes: true, attributeFilter: ['data-theme'] });
	view.themeObserver = observer;
}


/* ==========================================================================
 * 9. Resize -- preserves the viewport, re-places and re-heats nothing (AC-S3)
 * ========================================================================== */

function gcResize(view) {
	const rect = view.surface.getBoundingClientRect();
	const width = Math.max(1, Math.round(rect.width));
	const height = Math.max(1, Math.round(rect.height));
	const dpr = Math.min(GC_DPR_CAP, (typeof window !== 'undefined' && window.devicePixelRatio) || 1);
	const bw = Math.max(1, Math.round(width * dpr));
	const bh = Math.max(1, Math.round(height * dpr));
	view.canvas.width = bw;
	view.canvas.height = bh;
	view.width = width;
	view.height = height;
	// Gated on `rendererReady` (D2, `mountCanvas`), not merely on the method's
	// existence: v8's `WebGLRenderer.resize`/`.render` exist on the instance
	// from construction but throw if called before `init()` has resolved --
	// unlike v7, where construction and readiness were the same event.
	if (view.rendererReady && view.renderer && typeof view.renderer.resize === 'function') view.renderer.resize(bw, bh);
	// The stage transform depends on `view.width`/`view.height` (the centre
	// term) as well as on `dpr`, so it is NOT set here -- `gcDrawFrame` applies
	// it on every frame, and the draw below is one of those frames. Caching
	// `dpr` is this function's only remaining transform responsibility, since
	// it is what sized the backing buffer.
	view.dpr = dpr;
	gcDrawFrame(view, { tickMs: 0 });
}


/* ==========================================================================
 * 10. Notification handling -- step 5's classification
 * ========================================================================== */

function gcOnNotify(view, viewModel, lens, changedKeys) {
	// `zoom` is the ONLY `LensState` field this file reads (AC-S2, rule 1).
	// A write that came from this feature's own gesture already applied the
	// transform locally; a write that came from the shell's keyboard-driven
	// control (D8) has not, so the sync below is what actually moves the
	// canvas for that path. It is idempotent where the two already agree.
	gcSyncViewport(view, lens);
	if (Array.isArray(changedKeys) && changedKeys.length === 1 && changedKeys[0] === 'zoom') {
		// Apply the transform. No layout, no re-place, no re-heat.
		gcDrawFrame(view, { tickMs: 0 });
		return;
	}
	if (Array.isArray(changedKeys) && changedKeys.length === 1 && changedKeys[0] === 'sort') {
		// The table's own private field.
		return;
	}
	gcApplyProjection(view, viewModel, false);
}

/** Sync the private viewport transform from `lensState.zoom`, the one field
 *  this file reads from `LensState`. A no-op where the two already agree,
 *  which is the common case for a gesture that already applied the
 *  transform locally before committing it. */
function gcSyncViewport(view, lens) {
	const zoom = lens && lens.zoom;
	if (!zoom) return;
	if (zoom.scale === view.viewport.scale && zoom.panX === view.viewport.panX && zoom.panY === view.viewport.panY) return;
	view.viewport = { scale: zoom.scale, panX: zoom.panX, panY: zoom.panY };
}

/** A mid-session preference flip (D1's separate preference route -- no
 *  `revision` bump, no `subscribe` notification). Repaints, re-resolves the
 *  palette, and transitions `mode` between `'live'` and `'settled'` -- the
 *  standing half of NFR-4, not only its load-time half. */
function gcOnPreferencesChange(view, prefs) {
	view.palette = gcResolvePalette(view.root);
	const wasSettled = view.record.mode === 'settled';
	const viewModel = view.store.getViewModel();
	const forcedColours = !!prefs.forcedColours;
	// `forcedColours` is baked into every mark's `emphasisDraw` at derive time
	// (`gcNodeEmphasisDraw`/`gcEdgeEmphasisDraw`) and read again by the frame
	// path from `view.record.forcedColours` (`gcDrawFrame`) -- so BOTH must be
	// refreshed on EVERY preference-change tick, not only when `reducedMotion`
	// also flips, and not only on a `revision`-changing `subscribe` notify.
	// Membership cannot change on this route (no `revision` bump here), so
	// `view.positions`/`view.simulation`/`view.lastNodeIds` are left untouched
	// below in every branch -- at rest, no mark moves (AC-S3).
	const { nodeMarks, edgeMarks } = gcDeriveMarks(viewModel, forcedColours);
	const nodeIds = Array.from(nodeMarks.keys());
	view.record.forcedColours = forcedColours;
	view.record.nodes = nodeIds;
	view.record.edges = Array.from(edgeMarks.keys());
	view.record.marks = { nodes: Array.from(nodeMarks.values()), edges: Array.from(edgeMarks.values()) };
	if (prefs.reducedMotion && !wasSettled) {
		if (!view.simulation) gcEnsureSimulation(view, nodeIds, edgeMarks, viewModel);
		gcSettleBeforeFirstPaint(view, viewModel);
		return;
	}
	if (!prefs.reducedMotion && wasSettled) {
		view.record.mode = 'live';
		gcReheat(view);
		return;
	}
	gcRepaintUnchanged(view);
}

/**
 * @param {object} view
 * @param {object} viewModel
 * @param {boolean} isFirst
 */
function gcApplyProjection(view, viewModel, isFirst) {
	const forcedColours = !!(view.store.getPreferences().forcedColours);
	const { nodeMarks, edgeMarks } = gcDeriveMarks(viewModel, forcedColours);
	const nodeIds = Array.from(nodeMarks.keys());
	const nextIds = new Set(nodeIds);

	// Drop positions for a node no longer in GraphModel at all (D2).
	for (const id of Array.from(view.positions.keys())) {
		if (!viewModel.visibleNodes.some((n) => n.id === id) && !nextIds.has(id)) view.positions.delete(id);
	}

	const groupKey = viewModel.groups.map((g) => g.key + ':' + g.nodeIds.join(',')).join('|');
	const setsChanged = !gcSameSet(view.lastNodeIds, nextIds);
	const groupsChanged = groupKey !== view.lastGroupKey;

	if (isFirst || setsChanged) {
		gcDiffPlaceNodes(view, viewModel, nextIds);
	}

	view.lastNodeIds = nextIds;
	view.lastGroupKey = groupKey;

	view.record = {
		revision: viewModel.revision,
		// `mode` is set exactly by: `mountCanvas` at capability failure
		// ('unavailable'), `gcSettleBeforeFirstPaint` ('settled') and
		// `gcOnPreferencesChange` (both transitions). It is carried through
		// here untouched -- a projection never decides it.
		mode: view.record.mode,
		forcedColours: forcedColours,
		nodes: nodeIds,
		edges: Array.from(edgeMarks.keys()),
		marks: { nodes: Array.from(nodeMarks.values()), edges: Array.from(edgeMarks.values()) },
		reveal: view.record.reveal,
		captions: gcBuildCaptions(viewModel),
		viewport: Object.assign({}, view.viewport),
		positions: gcPositionsSnapshot(view.positions, nodeIds),
		frames: view.record.frames || [],
	};
	gcPublishRecord(view.record);
	view.index.rebuild(view.positions, nodeIds);

	// Nothing structural changed: repaint from `positions` unchanged. The
	// simulation, if any, is left exactly as it was -- neither rebuilt nor
	// touched -- so at rest no mark moves (AC-S3). This is the one branch
	// that never calls `gcEnsureSimulation`.
	if (!isFirst && !setsChanged && !groupsChanged) {
		gcDrawFrame(view, { tickMs: 0 });
		return;
	}

	// The drawn sets or the partition changed (or this is the first paint):
	// (re)build the simulation's topology over the CURRENT positions -- every
	// surviving node keeps its coordinate, only a new id was placed above --
	// then heat it. `gcEnsureSimulation` itself never starts a tick.
	gcEnsureSimulation(view, nodeIds, edgeMarks, viewModel);

	const reducedMotion = !!(view.store.getPreferences().reducedMotion);
	if (isFirst && reducedMotion) {
		gcSettleBeforeFirstPaint(view, viewModel);
		return;
	}
	if (view.record.mode === 'settled') {
		// A perturbation under the standing settled mode resumes the loop
		// UNPAINTED and paints once at release (§ Reduced motion).
		gcSettleBeforeFirstPaint(view, viewModel);
		return;
	}
	gcReheat(view);
}

function gcSameSet(a, b) {
	if (!a || a.size !== b.size) return false;
	for (const id of a) if (!b.has(id)) return false;
	return true;
}

function gcPositionsSnapshot(positions, nodeIds) {
	const out = {};
	for (const id of nodeIds) { const p = positions.get(id); if (p) out[id] = { x: p.x, y: p.y }; }
	return out;
}

function gcBuildCaptions(viewModel) {
	const counts = viewModel.counts.nodes + ' of ' + (viewModel.counts.nodes + viewModel.counts.hiddenNodes) + ' nodes, '
		+ viewModel.counts.edges + ' of ' + (viewModel.counts.edges + viewModel.counts.hiddenEdges) + ' relationships';
	const groups = viewModel.groups.map((g) => ({
		label: g.label,
		foldedText: g.foldable > 0 ? (g.foldable + ' folded into this document') : null,
	}));
	return { counts: counts, groups: groups };
}

/** Diff the drawn node set against `positions`: keep every surviving id's
 *  entry untouched, place only the new ones, drop the departed. */
function gcDiffPlaceNodes(view, viewModel, nextIds) {
	const adjacency = new Map();
	for (const edge of viewModel.visibleEdges) {
		const fold = viewModel.edgeFold.get(edge.key);
		if (fold === 'collapsed') continue;
		if (!adjacency.has(fold.sourceId)) adjacency.set(fold.sourceId, []);
		if (!adjacency.has(fold.targetId)) adjacency.set(fold.targetId, []);
		adjacency.get(fold.sourceId).push(fold.targetId);
		adjacency.get(fold.targetId).push(fold.sourceId);
	}
	for (const id of nextIds) {
		if (view.positions.has(id)) continue;
		const seed = gcPlaceNewNode(id, view.positions, adjacency.get(id) || []);
		view.positions.set(id, { x: seed.x, y: seed.y, vx: 0, vy: 0, fx: null, fy: null });
	}
	for (const id of Array.from(view.positions.keys())) {
		if (!nextIds.has(id)) view.positions.delete(id);
	}
}


/* ==========================================================================
 * 11. The simulation
 * ========================================================================== */

function gcEnsureSimulation(view, nodeIds, edgeMarks, viewModel) {
	const nodeRecords = nodeIds.map((id) => Object.assign({ id: id }, view.positions.get(id)));
	const links = Array.from(edgeMarks.values()).filter((m) => m.sourceId !== m.targetId)
		.map((m) => ({ source: m.sourceId, target: m.targetId }));

	if (view.simulation) view.simulation.stop();
	const groupCentres = gcGroupCentres(viewModel, view.positions);
	const sim = d3.forceSimulation(nodeRecords)
		.force('charge', d3.forceManyBody().strength(GC_FORCE.charge))
		.force('link', d3.forceLink(links).id((d) => d.id).distance(GC_FORCE.linkDistance).strength(GC_FORCE.linkStrength))
		.force('center', d3.forceCenter(0, 0).strength(GC_FORCE.centerStrength))
		.force('collide', d3.forceCollide(GC_FORCE.collideRadius))
		.force('group', gcGroupForce(viewModel, groupCentres, GC_FORCE.groupStrength))
		.on('tick', () => gcOnTick(view, nodeRecords));
	sim.alphaTarget(0);
	// Deterministic regardless of the adopted d3-force build's own auto-start
	// behaviour at construction: this module decides when a heat begins, via
	// `gcReheat`/`gcSettleBeforeFirstPaint`, and never the mere act of
	// (re)building the simulation's topology -- which is what keeps an
	// emphasis-only re-projection from moving a mark (AC-S3).
	sim.stop();
	view.simulation = sim;
	view.simNodeRecords = nodeRecords;
}

/** A minimal custom force -- pulls each node toward its group's centroid, the
 *  layout half of what `groups` is for. */
function gcGroupForce(viewModel, centres, strength) {
	let nodes;
	function force(alpha) {
		for (const node of nodes) {
			const centre = centres.get(node.id);
			if (!centre) continue;
			node.vx = (node.vx || 0) + (centre.x - node.x) * strength * alpha;
			node.vy = (node.vy || 0) + (centre.y - node.y) * strength * alpha;
		}
	}
	force.initialize = (n) => { nodes = n; };
	return force;
}

function gcGroupCentres(viewModel, positions) {
	const centres = new Map();
	for (const group of viewModel.groups) {
		let sx = 0, sy = 0, n = 0;
		for (const id of group.nodeIds) {
			const p = positions.get(id);
			if (p) { sx += p.x; sy += p.y; n += 1; }
		}
		if (n === 0) continue;
		const centre = { x: sx / n, y: sy / n };
		for (const id of group.nodeIds) centres.set(id, centre);
	}
	return centres;
}

function gcOnTick(view, nodeRecords) {
	const t0 = (typeof performance !== 'undefined' ? performance.now() : Date.now());
	for (const rec of nodeRecords) {
		const p = view.positions.get(rec.id);
		if (p) { p.x = rec.x; p.y = rec.y; p.vx = rec.vx; p.vy = rec.vy; p.fx = rec.fx; p.fy = rec.fy; }
	}
	const tickMs = (typeof performance !== 'undefined' ? performance.now() : Date.now()) - t0;
	if (view.simulation && view.simulation.alpha() < GC_IDLE_ALPHA && !view.drag) {
		view.simulation.stop();
	}
	gcScheduleFrame(view, tickMs);
}

function gcReheat(view) {
	if (!view.simulation) return;
	view.simulation.alpha(1).restart();
}


/* ==========================================================================
 * 12. Reduced motion -- the settled render (NFR-4)
 * ========================================================================== */

/** Step the ALREADY-BUILT simulation (the caller's job -- `gcEnsureSimulation`
 *  -- since this runs both at first paint and at every later perturbation
 *  under the standing settled mode) to convergence, painting once at the end
 *  and never mid-loop. `mode` becomes/stays `'settled'`. */
function gcSettleBeforeFirstPaint(view, viewModel) {
	const sim = view.simulation;
	if (!sim) return;
	sim.stop();
	let iterations = 0;
	let moved = Infinity;
	while (iterations < GC_SETTLE_MAX_TICKS && moved > GC_SETTLE_MOVE_THRESHOLD) {
		moved = 0;
		sim.tick();
		for (const rec of view.simNodeRecords) {
			moved += Math.abs(rec.vx || 0) + Math.abs(rec.vy || 0);
			const p = view.positions.get(rec.id);
			if (p) { p.x = rec.x; p.y = rec.y; p.vx = 0; p.vy = 0; }
		}
		iterations += 1;
	}
	sim.stop();
	view.record.mode = 'settled';
	gcDrawFrame(view, { tickMs: 0 });
}

/** Resume a stopped simulation for a perturbation. Under `'settled'` the loop
 *  runs unpainted until it idles again and paints exactly once at release --
 *  the one exception being a drag's own pinned node, drawn per frame while
 *  every other mark holds still (§ Reduced motion). */
function gcRepaintUnchanged(view) {
	gcDrawFrame(view, { tickMs: 0 });
}


/* ==========================================================================
 * 13. The frame path -- ticks are scheduled here, nothing else runs in it
 * ========================================================================== */

function gcScheduleFrame(view, tickMs) {
	if (view.frameHandle) return;
	const raf = (typeof requestAnimationFrame === 'function') ? requestAnimationFrame : (fn) => setTimeout(fn, 16);
	view.frameHandle = raf(() => { view.frameHandle = null; gcDrawFrame(view, { tickMs: tickMs }); });
}

/** Device-pixel ratio, capped. Cached on the view by `gcResize` (which sizes
 *  the backing buffer with it); recomputed identically here so a frame that
 *  lands before the first resize still transforms correctly. */
function gcDevicePixelRatio(view) {
	if (view && typeof view.dpr === 'number' && view.dpr > 0) return view.dpr;
	return Math.min(GC_DPR_CAP, (typeof window !== 'undefined' && window.devicePixelRatio) || 1);
}

/**
 * Write `view.viewport` onto the PixiJS stage -- the ONE place the private
 * viewport transform becomes something the renderer can see.
 *
 * Marks are drawn at raw simulation coordinates (`gcDrawFrame` below places
 * each glyph at `positions.get(id)` verbatim), so pan, zoom AND the
 * centre-origin convention all have to arrive as a stage transform. This
 * function is the exact inverse of `gcLocalPoint`, which is what makes
 * picking and drawing agree:
 *
 *     gcLocalPoint:  world = (client - rect - size/2 - pan) / scale
 *     therefore:     buffer = world * (scale * dpr) + (pan + size/2) * dpr
 *
 * Two consequences worth stating, because both were live defects before this
 * existed and both are one symptom of one cause:
 *
 *   1. The simulation centres its layout on world (0,0). Without the
 *      `size/2` term the renderer put world (0,0) at the buffer's top-left
 *      corner, so every node with a negative coordinate -- about half of
 *      them -- drew outside the buffer, and the rest clustered in the
 *      corner. `gcLocalPoint` meanwhile already placed world (0,0) at the
 *      surface centre, so the pick space was offset from the draw space by
 *      half the surface: a click on a visible node picked nothing, and a
 *      click on empty centre picked a node drawn in the corner.
 *   2. Every gesture (wheel zoom, drag pan) and every `setLens({zoom})`
 *      round-trip updated `view.viewport` and repainted -- but the repaint
 *      re-emitted the same untransformed geometry, so no gesture ever moved
 *      a pixel. `gcOnNotify`'s "apply the transform" comment described a
 *      step that had no implementation.
 *
 * Called on every frame rather than only on resize: a gesture changes the
 * transform without changing the buffer size.
 */
function gcApplyStageTransform(view) {
	if (!view.stage) return;
	const dpr = gcDevicePixelRatio(view);
	const vp = view.viewport;
	const scale = dpr * vp.scale;
	const x = (vp.panX + view.width / 2) * dpr;
	const y = (vp.panY + view.height / 2) * dpr;
	if (view.stage.scale && view.stage.scale.set) view.stage.scale.set(scale, scale);
	if (view.stage.position && view.stage.position.set) view.stage.position.set(x, y);
}

/**
 * Draw edges, then nodes, then labels, then the caption; append one frame
 * sample. No ARIA write, no live-region write, no DOM style read, no layout
 * measurement (AC-S5) -- colours come from `view.palette`, sizes from
 * `view.width`/`view.height`, cached at the last resize.
 */
function gcDrawFrame(view, meta) {
	const t0 = (typeof performance !== 'undefined' ? performance.now() : Date.now());
	const forcedColours = view.record.forcedColours;
	const marks = view.record.marks || { nodes: [], edges: [] };
	const alpha = view.record.mode === 'settled' ? 0 : (view.simulation ? view.simulation.alpha() : 0);

	view.edgeLayer.removeChildren();
	view.nodeLayer.removeChildren();
	view.labelLayer.removeChildren();

	// Drawn glyph radius per node id, built once for this frame. The edge pass
	// needs it to stop each line at the glyph's border rather than its centre,
	// and only the node pass knows each mark's `markScale`. The ring/badge
	// additions are deliberately NOT included: an arrow should touch the SHAPE,
	// which is what the reader perceives as the node's edge.
	// The hovered mark, read from `reveal` at DRAW time rather than from an
	// emphasis class -- rule 6 forbids a hover writing a class, and the 2026-07-30
	// SPEC revision moved the highlight to `reveal` for exactly that reason. Only
	// the mark under the pointer is affected; its neighbourhood is not (see
	// `GC_HOVER_SCALE`).
	const reveal = view.record.reveal || {};
	const hoverNodeId = reveal.kind === 'node' ? reveal.target : null;
	const hoverEdgeKey = reveal.kind === 'edge' ? reveal.target : null;

	const glyphRadius = new Map();
	for (const mark of marks.nodes) {
		const lift = mark.id === hoverNodeId ? GC_HOVER_SCALE : 1;
		glyphRadius.set(mark.id, GC_BASE_RADIUS * mark.emphasisDraw.markScale * lift);
	}

	for (const mark of marks.edges) {
		const a = view.positions.get(mark.sourceId);
		const b = view.positions.get(mark.targetId);
		if (!a || !b) continue;
		// Both ends, not only the arrow end: a line emerging from under its
		// source glyph reads as starting nowhere just as badly.
		const seg = gcTrimSegment(
			a, b,
			(glyphRadius.get(mark.sourceId) || 0) + GC_EDGE_GAP,
			(glyphRadius.get(mark.targetId) || 0) + GC_EDGE_GAP,
		);
		if (!seg) continue;
		const g = new PIXI.Graphics();
		const colour = gcColourFor(view.palette, mark.colourToken, forcedColours);
		const hovered = mark.key === hoverEdgeKey;
		const width = mark.emphasisDraw.weight * GC_BASE_WEIGHT * (hovered ? GC_HOVER_WEIGHT : 1);
		const baseOpacity = mark.emphasisDraw.opacity == null ? 1 : mark.emphasisDraw.opacity;
		const opacity = hovered ? GC_HOVER_OPACITY : baseOpacity;
		if (typeof g.lineStyle === 'function') g.lineStyle(width, gcColourToNumber(colour), opacity);
		gcDrawDashedLine(g, seg.x1, seg.y1, seg.x2, seg.y2, mark.lineStyle);
		// Flush the line before the arrowhead's own fill. Without this the line
		// rendered ONLY as a side effect of that fill, so a symmetric edge --
		// which draws no arrowhead by design -- was invisible (see `gcStroke`).
		gcStroke(g, width, colour, opacity);
		if (mark.arrowhead) gcDrawArrowhead(g, seg.x1, seg.y1, seg.x2, seg.y2, colour);
		view.edgeLayer.addChild(g);
	}

	for (const mark of marks.nodes) {
		const p = view.positions.get(mark.id);
		if (!p) continue;
		const g = new PIXI.Graphics();
		const colour = gcColourFor(view.palette, mark.colourToken, forcedColours);
		// The map already carries the hover lift, so glyph, ring and badge all
		// grow together and the badge stays tucked to the outline.
		const radius = glyphRadius.get(mark.id);
		const opacity = mark.id === hoverNodeId
			? GC_HOVER_OPACITY
			: mark.emphasisDraw.opacity;
		gcDrawGlyph(g, mark.kind, radius, colour, opacity);
		if (mark.emphasisDraw.ring) gcDrawRing(g, radius + 4, colour);
		// The badge takes the SEVERITY colour, not the node's kind colour -- the
		// fill already spends kind, and reusing it would have made the badge a
		// second copy of information the glyph already carries.
		if (mark.gapBadge) {
			gcDrawBadge(g, mark.gapBadge, radius,
				gcColourFor(view.palette, GC_BADGE_TOKEN[mark.gapBadge], forcedColours), mark.kind);
		}
		g.position && g.position.set && g.position.set(p.x, p.y);
		view.nodeLayer.addChild(g);
	}

	// Last, so the chip sits above every mark: `labelLayer` is the topmost stage
	// child, and within the frame this is the only thing that fills it.
	gcDrawHoverLabel(view);

	// Marks above are placed in world coordinates; this is what maps them into
	// the buffer (pan, zoom, dpr and the centre origin). Must run before the
	// draw call, and on every frame -- a gesture changes the transform without
	// changing the buffer size, so a resize-only application would make every
	// gesture a no-op on screen.
	gcApplyStageTransform(view);

	// Gated on `rendererReady` (D2, `mountCanvas`): a tick that lands before
	// `renderer.init()` has resolved still rebuilds `stage`'s children above
	// (nothing about deriving the frame is skipped) but withholds the actual
	// GPU draw call. `mountCanvas`'s own `init().then()` performs the one
	// `render()` this withholds once ready, so the first paint is deferred,
	// never dropped.
	if (view.rendererReady && view.renderer && typeof view.renderer.render === 'function') view.renderer.render(view.stage);

	const frames = view.record.frames;
	frames.push({
		t: t0,
		tickMs: meta && typeof meta.tickMs === 'number' ? meta.tickMs : 0,
		drawMs: (typeof performance !== 'undefined' ? performance.now() : Date.now()) - t0,
		alpha: alpha,
		dragging: !!(view.drag && view.drag.nodeId),
		applied: Object.assign({}, view.viewport),
	});
	if (frames.length > GC_FRAME_RING) frames.shift();
	view.record.positions = gcPositionsSnapshot(view.positions, view.record.nodes);
	gcPublishRecord(view.record);

	if (view.simulation && view.simulation.alpha() >= GC_IDLE_ALPHA && view.record.mode !== 'settled') {
		gcScheduleFrame(view, 0);
	}
}

/** A colour string, resolved from CSS, turned into a PIXI-friendly number
 *  where the runtime supports it -- never a colour value authored in this
 *  file, only a format conversion of one already resolved from the
 *  stylesheet. */
function gcColourToNumber(colour) {
	const hex = typeof colour === 'string' ? colour.match(/^#([0-9a-fA-F]{6})$/) : null;
	if (hex) return parseInt(hex[1], 16);
	// A system colour keyword (e.g. `CanvasText`) or an `rgb()` string is
	// returned as-is rather than converted: it is left for PIXI/the canvas
	// backend to resolve natively where the call site accepts a string. No
	// literal colour value is authored on this path -- `colour` is always
	// already resolved from the stylesheet or the probe (AC-S4).
	return colour;
}

/**
 * Draw the hover reveal as a chip beside the hovered mark -- the node's full
 * label, or the edge's relationship phrase.
 *
 * `gcRefreshReveal` already computes WHAT to say and publishes it as
 * `record.reveal`, for both kinds. This is the only thing that puts it on
 * screen: nothing else reads `reveal` (a grep for it in `graph-controls.js`
 * returns nothing), so before this existed the specified behaviour -- "the
 * relationship's name appears when a reader hovers or selects rather than being
 * painted" -- had the state, the text and the hit-testing all working and no
 * output at all, and `labelLayer` was cleared on every frame and never filled.
 *
 * Constant on-screen size, not constant world size. The chip is counter-scaled
 * by `1 / viewport.scale`, so the stage's `dpr * scale` leaves a net `dpr`:
 * crisp, and legible at every zoom instead of vanishing when zoomed out. That
 * is what holds it above `GC_LABEL_FLOOR_PX` without ever shrinking it, which
 * is the distinction that constant means.
 *
 * Appearance only (AC-S7): this adds no mark, writes no store field and touches
 * no emphasis class, so the drawn MARK sets are identical before, during and
 * after a hover. A transient chip is not a mark -- and drawing one is the
 * behaviour AC-S7's own feature requires, so the two do not conflict.
 */
function gcDrawHoverLabel(view) {
	const reveal = view.record.reveal;
	if (!reveal || !reveal.kind || !reveal.text) return;
	// Capability guard in this file's own idiom. Unlike the renderer probe, a
	// missing `Text` cannot hide total non-function: every mark still draws, and
	// only the chip is absent.
	if (typeof PIXI.Text !== 'function') return;

	// Anchor in world coordinates, plus the clearance to keep off the mark.
	let ax = 0;
	let ay = 0;
	let clear = GC_EDGE_GAP;
	if (reveal.kind === 'node') {
		const p = view.positions.get(reveal.target);
		if (!p) return;
		const mark = (view.record.marks.nodes || []).find((m) => m.id === reveal.target);
		ax = p.x;
		ay = p.y;
		clear = GC_BASE_RADIUS * (mark ? mark.emphasisDraw.markScale : 1) + GC_EDGE_GAP + 2;
	} else {
		// `neighbourhood` is `[sourceId, targetId]` for an edge reveal, so the
		// midpoint needs no second lookup of the edge itself.
		const a = view.positions.get(reveal.neighbourhood[0]);
		const b = view.positions.get(reveal.neighbourhood[1]);
		if (!a || !b) return;
		ax = (a.x + b.x) / 2;
		ay = (a.y + b.y) / 2;
		clear = GC_EDGE_GAP + 4;
	}

	const fg = view.palette.get('__forced_fg') || 'CanvasText';
	const bg = view.palette.get('__forced_bg') || 'Canvas';
	const label = new PIXI.Text({
		text: reveal.text,
		style: { fontFamily: GC_LABEL_FONT_FAMILY, fontSize: GC_LABEL_FONT_PX, fill: gcColourToNumber(fg) },
	});
	// PIXI measures the text itself -- no DOM style read and no layout
	// measurement enters the frame path (AC-S5).
	const inv = 1 / view.viewport.scale;
	const w = (label.width + GC_LABEL_PAD * 2) * inv;
	const h = (label.height + GC_LABEL_PAD * 2) * inv;

	// Up and to the right of the mark by default, flipped where that would put
	// the chip outside the visible world rect -- which is the inverse of the
	// stage transform, the same relation `gcLocalPoint` uses.
	let x = ax + clear;
	let y = ay - clear - h;
	const vx1 = (view.width / 2 - view.viewport.panX) / view.viewport.scale;
	const vy0 = (-view.height / 2 - view.viewport.panY) / view.viewport.scale;
	if (x + w > vx1) x = ax - clear - w;
	if (y < vy0) y = ay + clear;

	const chip = new PIXI.Graphics();
	if (typeof chip.beginFill === 'function') chip.beginFill(gcColourToNumber(bg), 0.9);
	if (typeof chip.drawRect === 'function') chip.drawRect(x, y, w, h);
	if (typeof chip.endFill === 'function') chip.endFill();
	if (typeof chip.lineStyle === 'function') chip.lineStyle(1 * inv, gcColourToNumber(fg), 0.35);
	if (typeof chip.drawRect === 'function') chip.drawRect(x, y, w, h);
	view.labelLayer.addChild(chip);

	if (label.scale && label.scale.set) label.scale.set(inv, inv);
	if (label.position && label.position.set) label.position.set(x + GC_LABEL_PAD * inv, y + GC_LABEL_PAD * inv);
	view.labelLayer.addChild(label);
}

/**
 * Flush a stroked path, which PixiJS v8 does NOT do implicitly.
 *
 * This file was written in the v7 idiom -- `lineStyle(...)` and then a path --
 * and in v7 that was the whole story. In v8 `lineStyle` only sets a style: the
 * path is committed by a `fill()` or `stroke()` call, and **a stroke-only shape
 * with neither draws absolutely nothing, silently.** Measured in this exact
 * build (PixiJS 8.14.0, in-page):
 *
 *   lineStyle + moveTo/lineTo, nothing after  ->  local bounds 0 x 0
 *   the same, then stroke({...})              ->  local bounds 22 x 22
 *   lineStyle + drawCircle, nothing after     ->  local bounds 0 x 0
 *
 * Three things were invisible for this one reason, and only the first was
 * noticed because the other two are conditional:
 *   1. the gap badge's asterisk -- stroke-only;
 *   2. `gcDrawRing`, so the focus/selection ring has NEVER drawn;
 *   3. **symmetric edges.** An edge's line rendered only as a side effect of the
 *      arrowhead's `endFill()` happening to flush the pending path -- and a
 *      symmetric relation draws NO arrowhead by design, "the absence being the
 *      signal". So every symmetric edge was a line to nowhere. Measured: the
 *      identical sequence minus the arrowhead gives bounds 0 x 0.
 *
 * `stroke({...})` accepts the v7 path builders as well as the native ones, so
 * this is additive -- no call site has to be rewritten into the v8 idiom.
 */
function gcStroke(g, width, colour, alpha) {
	if (typeof g.stroke !== 'function') return;
	g.stroke({ width: width, color: gcColourToNumber(colour), alpha: alpha == null ? 1 : alpha });
}

function gcDrawDashedLine(g, x1, y1, x2, y2, lineStyle) {
	if (typeof g.moveTo !== 'function') return;
	g.moveTo(x1, y1);
	if (lineStyle === 'solid' || !lineStyle) { g.lineTo(x2, y2); return; }
	const pattern = lineStyle === 'dashed' ? [8, 5] : [2, 4];
	const dx = x2 - x1, dy = y2 - y1;
	const len = Math.sqrt(dx * dx + dy * dy) || 1;
	const ux = dx / len, uy = dy / len;
	let drawn = 0, i = 0, on = true;
	let cx = x1, cy = y1;
	while (drawn < len) {
		const step = Math.min(pattern[i % 2], len - drawn);
		const nx = cx + ux * step, ny = cy + uy * step;
		if (on) g.lineTo(nx, ny); else g.moveTo(nx, ny);
		cx = nx; cy = ny; drawn += step; i += 1; on = !on;
	}
}

/**
 * Pull a segment's two ends back by `trimA` and `trimB`, so a line drawn
 * centre-to-centre instead meets each glyph's border. Returns `null` when the
 * two glyphs are close enough that nothing legible is left between them --
 * drawing a zero-or-negative-length segment there would put an arrowhead at a
 * meaningless angle (`atan2` on a degenerate vector), so the caller skips the
 * edge's stroke rather than drawing a wrong one.
 */
function gcTrimSegment(a, b, trimA, trimB) {
	const dx = b.x - a.x;
	const dy = b.y - a.y;
	const len = Math.sqrt(dx * dx + dy * dy);
	if (!(len > 0)) return null;
	// Leave at least one arrow's length of visible segment; below that the edge
	// is noise between two touching glyphs.
	if (len - trimA - trimB < GC_ARROW_SIZE) return null;
	const ux = dx / len;
	const uy = dy / len;
	return {
		x1: a.x + ux * trimA,
		y1: a.y + uy * trimA,
		x2: b.x - ux * trimB,
		y2: b.y - uy * trimB,
	};
}

function gcDrawArrowhead(g, x1, y1, x2, y2, colour) {
	if (typeof g.drawPolygon !== 'function' && typeof g.beginFill !== 'function') return;
	const angle = Math.atan2(y2 - y1, x2 - x1);
	const size = GC_ARROW_SIZE;
	const bx = x2 - Math.cos(angle) * size;
	const by = y2 - Math.sin(angle) * size;
	const p1 = { x: bx + Math.cos(angle + Math.PI / 2) * (size / 2), y: by + Math.sin(angle + Math.PI / 2) * (size / 2) };
	const p2 = { x: bx + Math.cos(angle - Math.PI / 2) * (size / 2), y: by + Math.sin(angle - Math.PI / 2) * (size / 2) };
	if (typeof g.beginFill === 'function') g.beginFill(gcColourToNumber(colour));
	if (typeof g.drawPolygon === 'function') g.drawPolygon([x2, y2, p1.x, p1.y, p2.x, p2.y]);
	if (typeof g.endFill === 'function') g.endFill();
}

/** One glyph per `KIND_ENCODING` shape -- the authority for the mapping is
 *  graph-model.js's own table and it is not restated here beyond the shape
 *  name each kind already carries. */
function gcDrawGlyph(g, kind, radius, colour, opacity) {
	const shape = KIND_ENCODING[kind] ? KIND_ENCODING[kind].shape : 'circle';
	const alpha = opacity == null ? 1 : opacity;
	if (typeof g.beginFill === 'function') g.beginFill(gcColourToNumber(colour), alpha);
	switch (shape) {
		case 'circle':
			if (typeof g.drawCircle === 'function') g.drawCircle(0, 0, radius);
			break;
		case 'ring':
			if (typeof g.lineStyle === 'function') g.lineStyle(2, gcColourToNumber(colour), alpha);
			if (typeof g.drawCircle === 'function') g.drawCircle(0, 0, radius);
			break;
		case 'square':
			if (typeof g.drawRect === 'function') g.drawRect(-radius, -radius, radius * 2, radius * 2);
			break;
		case 'diamond':
			if (typeof g.drawPolygon === 'function') g.drawPolygon([0, -radius, radius, 0, 0, radius, -radius, 0]);
			break;
		case 'triangle':
			if (typeof g.drawPolygon === 'function') g.drawPolygon([0, -radius, radius, radius, -radius, radius]);
			break;
		case 'hexagon':
			if (typeof g.drawPolygon === 'function') g.drawPolygon(gcPolygonPoints(6, radius));
			break;
		case 'pentagon':
			if (typeof g.drawPolygon === 'function') g.drawPolygon(gcPolygonPoints(5, radius));
			break;
		default:
			if (typeof g.drawCircle === 'function') g.drawCircle(0, 0, radius);
	}
	if (typeof g.endFill === 'function') g.endFill();
}

function gcPolygonPoints(sides, radius) {
	const points = [];
	for (let i = 0; i < sides; i += 1) {
		const a = (Math.PI * 2 * i) / sides - Math.PI / 2;
		points.push(Math.cos(a) * radius, Math.sin(a) * radius);
	}
	return points;
}

function gcDrawRing(g, radius, colour) {
	if (typeof g.lineStyle === 'function') g.lineStyle(2, gcColourToNumber(colour), 1);
	if (typeof g.drawCircle === 'function') g.drawCircle(0, 0, radius);
	// Stroke-only, so it needs the explicit flush -- without it this ring has
	// never appeared on screen at all (see `gcStroke`).
	gcStroke(g, 2, colour, 1);
}

/**
 * The gap badge -- additive, beside the mark, never inside it, and never a
 * function of `nodeEmphasis` (its source is `coverageGaps` alone, D1).
 *
 * A three-arm asterisk, per the owner, in the two severity colours -- one shape
 * and one size for both, with colour the only difference between the two classes.
 * See `GC_BADGE_ASTERISK` for why that satisfies AC-15 and what the residual is:
 * the asterisk's PRESENCE is the non-colour channel the criterion's first clause
 * asks for, and it is the presence, not the tint, that survives forced colours.
 *
 * Previously this looked `GC_BADGE` up only to decide WHETHER to draw, then
 * drew an identical 3px filled dot for both classes and discarded the glyph.
 * So the two states were indistinguishable and AC-15's second clause was
 * unsatisfied -- the owner spotted it by eye on the first real page.
 *
 * Why the badge sits OUTSIDE the glyph rather than becoming its border: the
 * node's fill already carries `kind` and a ring already means `focus`
 * (`emphasisDraw.ring`), so a coloured or drawn border would collide with two
 * existing channels at once. The SPEC settled this deliberately -- "a badge
 * beside the mark instead of a hollow centre" -- and the offset below keeps it
 * clear of both.
 *
 * Why an asterisk and specifically NOT a dot -- the owner's reason, and it is a
 * constraint on any future change here: **a circle is already the `document`
 * kind's glyph**, so a small circular badge reads as a tiny document sitting
 * next to the node. The rule generalises past that one case: the badge must not
 * reuse ANY shape from `KIND_ENCODING`'s vocabulary, which is exactly
 * `circle`, `ring`, `square`, `diamond`, `triangle`, `pentagon`, `hexagon`. An
 * asterisk is in none of them, which is what makes it unambiguous -- and it
 * cannot be confused with the `ring` kind either, the way a hollow dot could.
 *
 * Severity ordering, owner's ruling: an unbacked claim outranks an undocumented
 * artifact, because it is wrong information rather than missing information --
 * a reader trusts it and acts on it, it looks identical to a sound claim, and it
 * corrupts the KB that this project designates the single source of truth. An
 * undocumented file announces itself by existing. `graph-table.js` carries the
 * same ordering so the two views agree.
 */
const GC_BADGE_ASTERISK = Object.freeze({
	// IDENTICAL geometry for both -- three arms (six rays), one size, one weight,
	// the owner's choice after comparing the alternatives on the real page. Arm
	// count and size were each tried as the severity channel and each rejected:
	// three arms reads better than four, and one size reads better than two.
	// COLOUR alone therefore separates the two classes.
	//
	// That still satisfies AC-15, and it is worth being precise about why, because
	// the criterion has two clauses and only the first constrains the channel.
	// "Every id in `coverageGaps` is drawn and is distinguishable by a non-colour
	// channel" -- satisfied by the asterisk's PRESENCE, which is a non-colour
	// difference from a node that has no badge, and it survives forced colours.
	// "And the two gap classes are distinguishable from each other" -- names no
	// channel, so colour may carry it.
	//
	// The residual is real and named rather than designed around: a reader with
	// red-green deficiency may not separate these two tints. What covers them is
	// the path this whole view is built on -- the canvas is visual-only and the
	// relationship table is the conforming alternative, and it states the two
	// classes in WORDS ("no source", "no KB doc"), as does the hover label. So the
	// distinction is never colour-only for the page, only for the bitmap.
	'kb-unbacked': Object.freeze({ arms: 3, radius: 4, weight: 1.2 }),
	'artifact-undocumented': Object.freeze({ arms: 3, radius: 4, weight: 1.2 }),
});

/** An asterisk: `arms` lines through a common centre, evenly spaced over the
 *  full turn, so `arms` strokes read as `arms * 2` rays. Its own helper because
 *  the badge is the only thing that draws one and the arm count is the channel
 *  that separates the two gap classes. */
function gcDrawAsterisk(g, cx, cy, radius, arms, weight, colour) {
	if (typeof g.lineStyle !== 'function' || typeof g.moveTo !== 'function' || typeof g.lineTo !== 'function') return;
	g.lineStyle(weight, gcColourToNumber(colour), 1);
	for (let i = 0; i < arms; i++) {
		const angle = (Math.PI / arms) * i;
		const dx = Math.cos(angle) * radius;
		const dy = Math.sin(angle) * radius;
		g.moveTo(cx - dx, cy - dy);
		g.lineTo(cx + dx, cy + dy);
	}
	gcStroke(g, weight, colour, 1);
}

/** How far a kind's outline actually reaches from the mark's centre, which is
 *  NOT always `radius`. Every shape draws inside its circumradius except the
 *  square, whose corners sit at `radius * sqrt(2)` -- and the badge is placed
 *  toward the upper-right corner, so the square is the one case that would be
 *  overlapped by a badge positioned off the plain radius. (The triangle's far
 *  corners are also at `radius * sqrt(2)`, but they are at the BOTTOM, away from
 *  the badge.) Used to tuck the badge close to the outline without ever landing
 *  inside the kind glyph, which the SPEC forbids. */
function gcGlyphOuterRadius(kind, radius) {
	const shape = KIND_ENCODING[kind] ? KIND_ENCODING[kind].shape : 'circle';
	return shape === 'square' ? radius * Math.SQRT2 : radius;
}

function gcDrawBadge(g, badgeClass, radius, colour, kind) {
	const spec = GC_BADGE_ASTERISK[badgeClass];
	if (!spec || !Object.prototype.hasOwnProperty.call(GC_BADGE, badgeClass)) return;
	// Placed on the upper-right diagonal, just clear of the outline rather than
	// at a flat offset from `radius`. A flat offset read as detached: on the
	// diagonal it put the badge sqrt(2) times further out than it looked, so the
	// badge floated instead of reading as attached to its node.
	const d = gcGlyphOuterRadius(kind, radius) + spec.radius + GC_BADGE_CLEARANCE;
	gcDrawAsterisk(g, d / Math.SQRT2, -d / Math.SQRT2, spec.radius, spec.arms, spec.weight, colour);
}


/* ==========================================================================
 * 14. Interaction
 * ========================================================================== */

function gcBindPointerEvents(view) {
	const canvas = view.canvas;
	canvas.addEventListener('mousemove', (event) => gcOnPointerMove(view, event));
	canvas.addEventListener('mouseleave', () => gcOnPointerLeave(view));
	canvas.addEventListener('mousedown', (event) => gcOnPointerDown(view, event));
	window.addEventListener('mousemove', (event) => gcOnPointerDrag(view, event));
	window.addEventListener('mouseup', (event) => gcOnPointerUp(view, event));
	canvas.addEventListener('click', (event) => gcOnClick(view, event));
	canvas.addEventListener('dblclick', (event) => gcOnDblClick(view, event));
	canvas.addEventListener('wheel', (event) => gcOnWheel(view, event), { passive: false });
}

function gcLocalPoint(view, clientX, clientY) {
	const rect = view.canvas.getBoundingClientRect();
	const cx = clientX - rect.left - view.width / 2;
	const cy = clientY - rect.top - view.height / 2;
	return { x: (cx - view.viewport.panX) / view.viewport.scale, y: (cy - view.viewport.panY) / view.viewport.scale };
}

/** Shortest distance from a point to a segment, this module's own code (like
 *  `index`, D2) -- an edge mark has no hit area PIXI hands back, so picking
 *  one needs the same private geometry a node's picking already uses. */
function gcDistanceToSegment(px, py, x1, y1, x2, y2) {
	const dx = x2 - x1, dy = y2 - y1;
	const lenSq = dx * dx + dy * dy;
	let t = lenSq > 0 ? ((px - x1) * dx + (py - y1) * dy) / lenSq : 0;
	t = Math.max(0, Math.min(1, t));
	const cx = x1 + t * dx, cy = y1 + t * dy;
	const ex = px - cx, ey = py - cy;
	return Math.sqrt(ex * ex + ey * ey);
}

/** The nearest edge mark within `maxDist`, or `null`. Two rows between the
 *  same drawn pair are two distinct marks here too -- this scans every
 *  edge mark and picks the closest, never a pair (AC-S6). */
function gcNearestEdge(view, x, y, maxDist) {
	let best = null;
	let bestDist = maxDist;
	for (const mark of view.record.marks.edges) {
		const a = view.positions.get(mark.sourceId);
		const b = view.positions.get(mark.targetId);
		if (!a || !b) continue;
		const d = gcDistanceToSegment(x, y, a.x, a.y, b.x, b.y);
		if (d <= bestDist) { bestDist = d; best = mark.key; }
	}
	return best;
}

/** Hover changes appearance only. Nothing is written to the store and the
 *  drawn sets are identical before, during and after (AC-S7). A node takes
 *  priority over an edge at the same point, matching the pick radius each
 *  already uses for its own gesture. */
function gcOnPointerMove(view, event) {
	if (view.drag) return;
	const p = gcLocalPoint(view, event.clientX, event.clientY);
	const pickRadius = GC_PICK_RADIUS / view.viewport.scale;
	const nodeId = view.index.nearest(p.x, p.y, pickRadius);
	const edgeKey = nodeId ? null : gcNearestEdge(view, p.x, p.y, pickRadius);
	if (nodeId === view.hover && edgeKey === view.hoverEdge) return;
	view.hover = nodeId;
	view.hoverEdge = edgeKey;
	gcRefreshReveal(view);
	gcDrawFrame(view, { tickMs: 0 });
}

function gcOnPointerLeave(view) {
	if (view.hover === null && !view.hoverEdge) return;
	view.hover = null;
	view.hoverEdge = null;
	gcRefreshReveal(view);
	gcDrawFrame(view, { tickMs: 0 });
}

/** Published as `reveal` (D3), never as an emphasis class -- hover is local
 *  and transient and no hover may write one (rule 6). */
function gcRefreshReveal(view) {
	const viewModel = view.store.getViewModel();
	if (view.hover) {
		const neighbourhood = [view.hover];
		for (const mark of view.record.marks.edges) {
			if (mark.sourceId === view.hover) neighbourhood.push(mark.targetId);
			if (mark.targetId === view.hover) neighbourhood.push(mark.sourceId);
		}
		view.record.reveal = {
			kind: 'node', target: view.hover,
			text: viewModel.nodeLabels.get(view.hover) || '',
			neighbourhood: neighbourhood,
		};
	} else if (view.hoverEdge) {
		// `s2t` (also `t2s` when symmetric) lives on the raw `Edge`, not on the
		// mark (D1) -- the mark carries only what the bitmap draws with.
		const edge = viewModel.visibleEdges.find((e) => e.key === view.hoverEdge);
		const mark = view.record.marks.edges.find((m) => m.key === view.hoverEdge);
		view.record.reveal = edge && mark ? {
			kind: 'edge', target: view.hoverEdge, text: edge.s2t,
			neighbourhood: [mark.sourceId, mark.targetId],
		} : { kind: null, target: null, text: '', neighbourhood: [] };
	} else {
		view.record.reveal = { kind: null, target: null, text: '', neighbourhood: [] };
	}
}

/**
 * How far the pointer must travel before a press becomes a DRAG.
 *
 * Without a threshold there is no such thing as a click on this surface: every
 * press immediately began a gesture, which had two visible consequences the owner
 * reported as one bug ("the graph is moving a little to the right but no node is
 * selected").
 *
 * Pressing a node pinned it and re-heated the simulation on the spot, so the whole
 * layout shifted under a pointer that had not moved. Measured on the real page
 * with a stationary pointer and an ordinary human dwell of ~160ms between press
 * and release: **the pressed node travelled 64px**, against a pick radius of 10.
 * The `click` handler then re-picked at the pointer, found nothing within six pick
 * radii, and selected nothing. The gesture destroyed its own target.
 *
 * So a press now commits to nothing until the pointer proves it is a drag, and
 * selection reads the id captured AT PRESS TIME rather than re-picking afterwards
 * -- press is the one moment the pointer and the mark are known to coincide.
 */
const GC_DRAG_THRESHOLD_PX = 4;

function gcOnPointerDown(view, event) {
	const p = gcLocalPoint(view, event.clientX, event.clientY);
	const id = view.index.nearest(p.x, p.y, GC_PICK_RADIUS / view.viewport.scale);
	// NOTHING is pinned, nothing is re-heated and no pan begins here. All of it is
	// deferred to `gcOnPointerDrag`, once the movement threshold says this is a
	// drag rather than a click.
	view.drag = {
		nodeId: id,
		started: false,
		startX: event.clientX,
		startY: event.clientY,
		origin: null,
		startViewport: Object.assign({}, view.viewport),
	};
	// What a following `click` will select. Kept OUTSIDE `view.drag` because
	// `gcOnPointerUp` clears that before the platform dispatches `click`, and
	// because it must survive to `dblclick` too -- which re-picked and drifted for
	// exactly the same reason.
	view.press = { nodeId: id, moved: false };
}

function gcOnPointerDrag(view, event) {
	if (!view.drag) return;
	const dx = event.clientX - view.drag.startX;
	const dy = event.clientY - view.drag.startY;

	if (!view.drag.started) {
		if (Math.sqrt(dx * dx + dy * dy) < GC_DRAG_THRESHOLD_PX) return;
		view.drag.started = true;
		// A gesture that moved is not a selection, whatever it started on.
		if (view.press) view.press.moved = true;
		if (view.drag.nodeId) {
			// The pin and the re-heat happen HERE, at the first real movement,
			// rather than at the press. Under `mode: 'settled'` the re-heat is
			// deferred further still, to the release: the simulation stays stopped
			// so every other mark holds still, and only the pinned node is driven
			// by the pointer (§ Reduced motion). Live mode re-heats now, and the
			// neighbours follow through the link/collide forces.
			const pos = view.positions.get(view.drag.nodeId);
			view.drag.origin = pos ? { x: pos.x, y: pos.y } : null;
			if (pos) { pos.fx = pos.x; pos.fy = pos.y; }
			if (view.record.mode !== 'settled') gcReheat(view);
		}
	}

	if (view.drag.nodeId) {
		const p = gcLocalPoint(view, event.clientX, event.clientY);
		const pos = view.positions.get(view.drag.nodeId);
		if (pos) { pos.x = p.x; pos.y = p.y; pos.fx = p.x; pos.fy = p.y; }
		gcDrawFrame(view, { tickMs: 0 });
	} else {
		view.viewport = { scale: view.drag.startViewport.scale, panX: view.drag.startViewport.panX + dx, panY: view.drag.startViewport.panY + dy };
		gcDrawFrame(view, { tickMs: 0 });
	}
}

/** A gesture in flight applies its transform locally; the store write --
 *  `setLens({zoom})`, once, whole -- happens only at the gesture's end. */
function gcOnPointerUp(view, event) {
	if (!view.drag) return;
	// Only a gesture that PASSED THE THRESHOLD has anything to undo or commit. A
	// press that never moved pinned nothing, re-heated nothing and panned nothing,
	// so releasing it must do nothing either -- it is a click, and the click
	// handler owns it.
	const started = view.drag.started;
	const wasNodeDrag = started && !!view.drag.nodeId;
	const wasViewportDrag = started && !view.drag.nodeId;
	const settled = view.record.mode === 'settled';
	if (wasNodeDrag) {
		const pos = view.positions.get(view.drag.nodeId);
		if (pos) { pos.fx = null; pos.fy = null; }
	}
	view.drag = null;
	if (wasViewportDrag) view.store.setLens({ zoom: Object.assign({}, view.viewport) });
	if (wasNodeDrag && settled) {
		// The deferred re-heat: settle once more from the dropped position and
		// paint exactly once at the release.
		gcSettleBeforeFirstPaint(view, view.store.getViewModel());
	} else if (wasNodeDrag) {
		gcDrawFrame(view, { tickMs: 0 });
	}
}

/**
 * Select the node that was under the pointer AT PRESS TIME.
 *
 * It does NOT re-pick. Re-picking is what made selection unusable: the graph is a
 * live simulation, so by the time `click` is dispatched the mark has moved --
 * measured at 64px for an ordinary ~160ms press against a 10px pick radius -- and
 * the handler reliably found nothing under a pointer that had never moved. Press
 * is the one instant at which the pointer and the mark are known to coincide, so
 * press is what decides.
 *
 * A gesture that moved past the drag threshold selects nothing: that was a drag,
 * and finishing a drag on top of some node is not a request to select it.
 *
 * A click on EMPTY SURFACE CLEARS the selection, which is the only mouse gesture
 * that clears one -- before this, nothing on the drawing surface could, and the
 * sole route was the shell's "Selected node" dropdown and its "(none)" option, in
 * a collapsed panel above the graph. A reader who selects a node by clicking it
 * reasonably expects to unselect the same way, and clearing is a real action here
 * rather than a cosmetic one: `focus.nodeId` drives the neighbourhood the whole
 * projection is built around.
 *
 * Safe against the pan gesture by construction: a pan travels more than
 * `GC_DRAG_THRESHOLD_PX` and so is never a click. Only a genuine stationary press
 * on nothing reaches the clear.
 *
 * Only the FIRST click of a sequence selects (`MouseEvent.detail`); the repeat that
 * precedes a real `dblclick` is ignored, which is the whole of the double-click
 * accommodation (AC-S9). One dotted key and no other write, on either path.
 */
function gcOnClick(view, event) {
	if (event.detail > 1) return;
	const press = view.press;
	if (!press || press.moved) return;
	// `null` is `focus.nodeId`'s own cleared value -- the same one `INITIAL_LENS`
	// and the presets carry -- so this writes the field's existing empty state
	// rather than inventing a sentinel.
	view.store.setLens({ 'focus.nodeId': press.nodeId || null });
}

/** Same rule as `gcOnClick`, for the same measured reason: the id comes from the
 *  press, never from a re-pick. `view.press` is deliberately NOT cleared by the
 *  single-click handler, because a double click is two presses and the second one
 *  has already overwritten it with the value this needs. */
function gcOnDblClick(view, event) {
	const press = view.press;
	if (!press || press.moved || !press.nodeId) return;
	const target = view.store.openTarget(press.nodeId);
	if (target) window.location.href = target;
}

/** Wheel scales the viewport about the pointer. Applied locally and repainted
 *  on EVERY event so zoom never feels dead mid-gesture; the `setLens({zoom})`
 *  commit itself is deferred to the gesture's end. Wheel has no native "end"
 *  event (unlike a pointer drag, which ends at `mouseup`), so "end" here is a
 *  trailing idle window: each new event resets the timer, and only the timer
 *  that survives uncancelled fires -- exactly one commit for one continuous
 *  scroll burst, matching the Interaction table and GC18's singular hook. */
function gcOnWheel(view, event) {
	event.preventDefault();
	const factor = event.deltaY < 0 ? GC_ZOOM_STEP : 1 / GC_ZOOM_STEP;
	const nextScale = gcClamp(view.viewport.scale * factor, GC_ZOOM_MIN, GC_ZOOM_MAX);
	view.viewport = Object.assign({}, view.viewport, { scale: nextScale });
	gcDrawFrame(view, { tickMs: 0 });
	gcScheduleWheelCommit(view);
}

/** The trailing-edge debounce that stands in for a wheel gesture's missing
 *  "end" event. Stored on `view` (alongside `resizeObserver`/`themeObserver`,
 *  which this file also never tears down) so a future teardown path -- this
 *  file has none today -- would have a single handle to clear. */
const GC_WHEEL_GESTURE_IDLE_MS = 150;

function gcScheduleWheelCommit(view) {
	if (view.wheelCommitTimer) clearTimeout(view.wheelCommitTimer);
	view.wheelCommitTimer = setTimeout(() => {
		view.wheelCommitTimer = null;
		view.store.setLens({ zoom: Object.assign({}, view.viewport) });
	}, GC_WHEEL_GESTURE_IDLE_MS);
}

function gcClamp(value, min, max) { return value < min ? min : (value > max ? max : value); }


/* ==========================================================================
 * 15. The viewport handle (D8) -- the shell's own control writes the result
 * ========================================================================== */

/**
 * @param {object} view
 * @param {string} action one of the seven manifest tokens
 * @returns {{scale:number, panX:number, panY:number}|undefined}
 */
function gcViewportFor(view, action) {
	const current = view.viewport;
	switch (action) {
		case 'zoom-in':
			return { scale: gcClamp(current.scale * GC_ZOOM_STEP, GC_ZOOM_MIN, GC_ZOOM_MAX), panX: current.panX, panY: current.panY };
		case 'zoom-out':
			return { scale: gcClamp(current.scale / GC_ZOOM_STEP, GC_ZOOM_MIN, GC_ZOOM_MAX), panX: current.panX, panY: current.panY };
		case 'zoom-fit':
			return gcFitViewport(view);
		case 'pan-left':
			return { scale: current.scale, panX: current.panX + GC_PAN_STEP, panY: current.panY };
		case 'pan-right':
			return { scale: current.scale, panX: current.panX - GC_PAN_STEP, panY: current.panY };
		case 'pan-up':
			return { scale: current.scale, panX: current.panX, panY: current.panY + GC_PAN_STEP };
		case 'pan-down':
			return { scale: current.scale, panX: current.panX, panY: current.panY - GC_PAN_STEP };
		default:
			return undefined;
	}
}

/** A fit is a function of the drawn extent, which lives in `positions`. */
function gcFitViewport(view) {
	const points = Array.from(view.positions.values());
	if (points.length === 0) return { scale: 1, panX: 0, panY: 0 };
	let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
	for (const p of points) {
		if (p.x < minX) minX = p.x; if (p.x > maxX) maxX = p.x;
		if (p.y < minY) minY = p.y; if (p.y > maxY) maxY = p.y;
	}
	const w = Math.max(1, maxX - minX);
	const h = Math.max(1, maxY - minY);
	const scale = gcClamp(Math.min((view.width || 400) / w, (view.height || 400) / h) * 0.9, GC_ZOOM_MIN, GC_ZOOM_MAX);
	return { scale: scale, panX: -((minX + maxX) / 2) * scale, panY: -((minY + maxY) / 2) * scale };
}


/* ==========================================================================
 * 16. What this file publishes
 *
 * In the page these are plain declarations in a shared module scope; the
 * export keyword makes the same file loadable by a test process with no
 * change to a byte of behaviour.
 * ========================================================================== */

export {
	mountCanvas,
	gcHasLibraries,
	gcHasWebGL,
	gcDeriveMarks,
	gcNodeEmphasisDraw,
	gcEdgeEmphasisDraw,
	gcResolvePalette,
	gcColourFor,
	gcSeedPosition,
	gcPlaceNewNode,
	gcViewportFor,
	gcFitViewport,
	gcEmptyRecord,
	GC_WARN_PREFIX,
	GC_FRAME_RING,
};
