/* ============================================================================
 * graph-table.js -- the accessible table rendering.
 *
 * The same relationships the drawing surface shows, presented as a real table:
 * one row per relationship, sorted from the column headers, navigable from the
 * keyboard, and usable with a screen reader. It is not a fallback hidden behind
 * the drawing. The drawing surface is visual-only, so THIS is the surface that
 * carries the accessibility standard for the whole artifact -- the conforming
 * alternate version -- and it mounts first and unconditionally, before the
 * drawing rendering is even looked for.
 *
 * WHERE THIS FILE RUNS
 *   Inside the page's single inline module block, concatenated after the shared
 *   coverage predicate, graph-model.js and graph-controls.js. That is ONE module
 *   scope, so this file declares no loading statement of any kind and reaches
 *   the shell's declarations -- registerRendering, el, clear, KIND_ENCODING --
 *   by plain reference. It reads no network, no second file and no storage: the
 *   projection arrives from the store and is the only input.
 *
 *   ONE SCOPE IS A CONSTRAINT. A duplicated top-level name is not shadowing, it
 *   is a SyntaxError and the page does not run at all. So every declaration
 *   below except the mount function itself is prefixed `TBL_`/`tbl`, and the
 *   generic helper names the earlier files own -- basename, bump, clear, el,
 *   slug, unquote, toInteger, ellipsise, prefixOf, compareStrings, narrate,
 *   project, byId -- are reused rather than redeclared. The check belongs in the
 *   suite: concatenate the block and parse it.
 *
 * THE SEVEN CONSUMER RULES, AND WHERE EACH IS HONOURED
 *   1. Render from the ViewModel; read the lens only for `sort`, this
 *      rendering's own private field. `tblSortOf` is the only lens read here.
 *   2. Take each edge's endpoints from `edgeFold`, and list NOTHING for a
 *      'collapsed' entry -- `tblRowRecords`.
 *   3. Take kind from `Node.kind` and colour and shape from `nodeEncoding`;
 *      never parse an identifier. `tblEndpoint` reads both maps and this file
 *      contains no prefix test of any kind: a prefix says where an id came
 *      from, which is a different fact from what class a node belongs to, and
 *      the two disagree -- one kind is spelled with either of two prefixes and
 *      one prefix spans four kinds.
 *   4. The ViewModel is treated as frozen. Nothing here writes to it.
 *   5. Hover changes appearance, never membership. This rendering registers no
 *      hover handler at all.
 *   6. The ViewModel instance is the one the drawing rendering receives, and it
 *      is recorded on the returned handle so that identity is assertable.
 *   7. Membership belongs to project(). The order below is a PERMUTATION of the
 *      rows the fold leaves standing -- never an addition, a removal or a
 *      re-selection -- which is what makes the Coverage listing exact rather
 *      than approximate.
 *
 * WHAT THIS FILE DOES NOT OWN
 *   Every filter control (the shell's panel, built from its manifest -- a
 *   per-column input would be a second widget on one field); the Open gesture
 *   (the shell's button in the selected-node detail region); the group
 *   expand/collapse disclosure (the shell's, and exactly one per foldable
 *   group); both live regions (the page has exactly two and this file writes to
 *   neither and creates no third); the legend, the coverage panel, the footer
 *   and the no-script fallback; and every colour value -- this file declares no
 *   colour token and contains no colour literal by any route.
 *
 * WHAT CARRIES A SORT CHANGE, SINCE NO LIVE REGION DOES
 *   The gesture's own control is the focused element and its `aria-sort` state
 *   change is conveyed there. Creating a third live region, or writing into one
 *   another module owns, would make "which region said that" unanswerable and
 *   risk doubled or lost announcements.
 *
 * WINDOWING (task-033, OPT IN, ABSENT BY DEFAULT)
 *   Every row rendered with no pagination was this file's rule for as long as
 *   the only caller was `graph.html`'s shell, where the filter and density
 *   controls are what bounds the rendered size and a partial table would break
 *   screen-reader row counts, find-in-page and printing. task-033's own
 *   table-only page has thousands of candidate rows and no drawing rendering to
 *   share the load with, so a real "Load more" affordance is added -- but it is
 *   OPT IN, through `context.pageSize` on `mountTable`, and it changes nothing
 *   for a caller that does not pass it: `graph.html` (which excludes the table
 *   entirely today, see `build-graph-src.mjs`'s `OWNER_EXCLUDES_TABLE_RENDERING`)
 *   would render exactly as before if the table were restored to it.
 *
 *   The "every live region is the caller's" rule above still holds. This file
 *   creates no live-region element of its own even in windowed mode -- it calls
 *   `context.announceWindow`, a function the caller injects, exactly the way it
 *   already reads `context.store` and writes to `context.region`. The caller
 *   owns the region that actually carries the announcement; this file only
 *   knows the sentence to put in it.
 *
 *   The button is the contract. `context.pageSize` also arms a `window` scroll
 *   listener as a CONVENIENCE that calls the identical growth function the
 *   button's click handler calls -- never a second, divergent path -- because a
 *   scroll-only trigger has no keyboard equivalent and this page exists to be
 *   the one every other rendering can fall back to.
 * ========================================================================== */


/* ==========================================================================
 * 1. The six Relations columns, and the value space of `sort`
 *
 * task-034 SLIMS this table from the file's ten columns to six: node KIND and
 * node NAME come out, because the Files tree and the Concepts table (§ 13) now
 * carry every node's own properties -- id, kind, name, provenance, coverage --
 * exactly once, where before they repeated on every relationship row naming
 * that node (86% of the cells this page rendered were exactly that repeat,
 * measured against the live `relationships.md`). This table keeps only
 * relationship information: both identifiers (still the row's own tie back to
 * the file, and still where the coverage/selection badges live -- see D3's
 * total mapping below, unchanged in substance), both relation readings,
 * provenance and observation.
 *
 * Six is now the CONTRACT COUNT this file's own comment used to state as ten:
 * the number is normative and changing it is a breaking change by design,
 * which is why the column count is read from this array (`TBL_COLUMNS.length`)
 * rather than written as a literal anywhere -- see feature-009 SPEC.md D3,
 * revised in the same change as this file.
 *
 * Each descriptor carries its own sort key and its own cell builder, so the
 * header row, the comparator and the body cells are driven by ONE array. A
 * column cannot be sortable without being renderable, and a column cannot
 * render a value the comparator does not see.
 * ========================================================================== */

/** The literal `sort.column` value standing for the file's own row order. */
const TBL_FILE_ORDER = 'row';

const TBL_COLUMNS = Object.freeze([
	Object.freeze({
		token: 'source-id', label: 'Source Id', rowHeader: true,
		value: (record) => record.source.id,
		// The select control moves here from the (now-removed) Source Name cell:
		// every row still carries an Id cell for each endpoint, so this is the
		// minimal relocation -- not a new mechanism -- once Name leaves the table.
		cell: (record, view) => tblIdCell(record.source, view),
	}),
	Object.freeze({
		token: 'target-id', label: 'Target Id',
		value: (record) => record.target.id,
		cell: (record, view) => tblIdCell(record.target, view),
	}),
	Object.freeze({
		token: 's2t-relation', label: 'S2T Relation',
		value: (record) => record.s2t,
		// The chain badge lands here and not on the row, because the chain is a
		// property of THIS reading of the relationship.
		cell: (record) => [record.s2t, tblEdgeBadge(record.edgeEmphasis)],
	}),
	Object.freeze({
		token: 't2s-relation', label: 'T2S Relation',
		value: (record) => record.t2s,
		cell: (record) => [record.t2s],
	}),
	Object.freeze({
		token: 'provenance', label: 'Provenance',
		value: (record) => record.provenance,
		// Literal text and no badge tint. The tint would need a colour pair the
		// project's contrast checker does not already carry, and this feature
		// declares no new token; the column's own text is the carrier NFR-5 asks
		// for, and the Provenance lens's grouping is the shell's.
		cell: (record) => [record.provenance],
	}),
	Object.freeze({
		token: 'observation', label: 'Observation',
		// Rendered verbatim, empty cell included: the value is the file's.
		value: (record) => record.observation,
		cell: (record) => [record.observation],
	}),
]);

/** The whole `sort.column` domain: the ten column tokens plus the file order. */
const TBL_SORT_COLUMNS = Object.freeze(new Set(TBL_COLUMNS.map((column) => column.token).concat([TBL_FILE_ORDER])));

/** The three `aria-sort` values this surface uses, and the caret that echoes
 *  each one visibly. `aria-sort` is the carrier; the caret is the second,
 *  non-colour channel for the same fact. */
const TBL_SORT_CARETS = Object.freeze({
	'none': '↕',
	'ascending': '↑',
	'descending': '↓',
});

/** What activating a header in each state does next, in words, so the button's
 *  accessible name states the state AND the outcome. */
const TBL_SORT_NEXT_WORDING = Object.freeze({
	'none': 'not sorted by this column; activate to sort ascending',
	'ascending': 'sorted ascending; activate to sort descending',
	'descending': 'sorted descending; activate to return to the file order',
});


/* ==========================================================================
 * 2. Emphasis -- a text badge per class, and a total mapping
 *
 * No eleventh column is added. The two emphasis channels land on the elements
 * they are keyed over, and the mapping is total over BOTH value spaces so no
 * class can render as nothing:
 *
 *   nodeEmphasis  kb-unbacked / artifact-undocumented / focus -> a text badge
 *                 in that endpoint's Id cell
 *   edgeEmphasis  chain -> a text badge in the S2T Relation cell
 *   either        dimmed -> data-emphasis="dimmed" on the row, and nothing else
 *   either        normal -> nothing
 *
 * `dimmed` is the one class with no text carrier, and that is sound rather than
 * an exception: it is the COMPLEMENT of the marked set, so "this row is in the
 * highlighted set" is readable as text and "this row is not" is readable as the
 * absence of that text. No information rests on the visual de-emphasis. Giving
 * it a badge would put a marker on the majority of rows and bury the signal.
 *
 * Each badge variant is one the shared stylesheet already ships and the
 * project's contrast checker already lists as a pair, so this file adds no
 * colour token and no new pair. No variant NAMES a colour either: a class whose
 * name were a colour word would read as a colour literal to a grep for one, and
 * would say what the tint is rather than what the mark means.
 * ========================================================================== */

const TBL_NODE_BADGES = Object.freeze({
	// Severity ordering, owner's ruling 2026-08-06: an UNBACKED claim outranks an
	// UNDOCUMENTED artifact, so it takes the error variant and undocumented the
	// warning one. These two were previously the other way round, which also put
	// this table in direct contradiction with the canvas.
	//
	// The rationale, because a future reader will otherwise reasonably assume the
	// opposite: an unbacked claim is WRONG information, not missing information.
	// A reader trusts it and acts on it, it is indistinguishable from a sound
	// claim by reading it, and it corrupts the Knowledge Base that this project
	// designates its single source of truth. An undocumented artifact announces
	// itself by existing and leaves the KB intact, merely incomplete. The
	// counter-argument -- that undocumented code is unknowable at scale -- is
	// about the total remediation effort a gap represents, not about how severe
	// one item is, and a badge marks one item.
	//
	// `graph-canvas.js`'s `GC_BADGE_TOKEN` carries the same ordering over the
	// same two status tokens. Change one and you must change the other.
	'kb-unbacked': Object.freeze({ text: 'no source', variant: 'badge-err' }),
	'artifact-undocumented': Object.freeze({ text: 'no KB doc', variant: 'badge-warn' }),
	// The accent variant, so the selection's badge and the selection's focus
	// outline -- which the shared emphasis rule already draws in the accent -- read
	// as one signal rather than two.
	'focus': Object.freeze({ text: 'selected', variant: 'badge-accent' }),
});

const TBL_EDGE_BADGES = Object.freeze({
	'chain': Object.freeze({ text: 'chain', variant: 'badge-info' }),
});

/** The emphasis classes with a shared visual treatment already authored -- a
 *  weight, an outline or an underline, never a colour of their own. */
const TBL_EMPHASIS_CLASSES = Object.freeze({
	'kb-unbacked': 'em-kb-unbacked',
	'artifact-undocumented': 'em-artifact-undocumented',
	'focus': 'em-focus',
});


/* ==========================================================================
 * 3. Identifiers, and the two sizes read from the design tokens
 * ========================================================================== */

/** The skip target, after BOTH tables, so one keystroke leaves every row. */
const TBL_END_ID = 'graph-table-end';

/** The unlisted-nodes region and its heading. The caption's link to the region
 *  and the region itself are emitted in the same pass, so the href/id pair is
 *  created together and the page's anchor check can never see a dangling one. */
const TBL_UNLISTED_ID = 'graph-table-unlisted';
const TBL_UNLISTED_HEAD_ID = 'graph-table-unlisted-heading';

/** Top-bar height, read from the shared design tokens (§ Spacing & sizing).
 *  The bar is sticky, and so is the reused table header rule, so a focused row
 *  control has TWO layers that can obscure it and both have to be accounted
 *  for: the header is offset by this much instead of pinning to the viewport
 *  edge, and every focusable inside the body carries a scroll margin covering
 *  the bar plus the MEASURED header height. */
const TBL_TOP_BAR_PX = 60;

/** The mobile breakpoint, from the same table. Not a second scale. */
const TBL_MOBILE_MAX_PX = 768;

/** Minimum hit area for an interactive control, from the accessibility
 *  checklist's touch-target item. Expressed in `rem` so it scales with the
 *  reader's text size rather than pinning to a device pixel. */
const TBL_HIT_AREA = '2.75rem';

/** How near the bottom of the document the convenience scroll listener fires,
 *  in pixels. Not a design token: it is slack for the listener's own imprecise
 *  read of `scrollHeight`, and it has no visible effect of its own. */
const TBL_SCROLL_TRIGGER_PX = 200;


/* ==========================================================================
 * 4. The mount point
 *
 * The shell mounts this rendering FIRST and UNCONDITIONALLY -- before the
 * drawing rendering, and even where no drawing rendering exists -- which is the
 * load-order form of "peer rendering, not fallback". Registration happens at
 * this file's top level, so it has run by the time the shell boots one
 * microtask later; the shell also probes this function by name, and either
 * route reaches the same function.
 * ========================================================================== */

/**
 * @param {{store: object, graphModel: object, region: Element, surface: Element,
 *          root: (Document|Element), pageSize: (number|undefined),
 *          announceWindow: (function(string): void|undefined),
 *          filesRegion: (Element|undefined), conceptsRegion: (Element|undefined)}} context
 *          `pageSize` and `announceWindow` are the windowing opt-in (task-033),
 *          both absent by default -- see the file header. `pageSize` is the
 *          number of rows a first paint (and each "Load more") reveals;
 *          `announceWindow` is a caller-owned sink for the one sentence this
 *          rendering has to report ("Showing N of M ..."), never a live-region
 *          element this file would have to create itself. `filesRegion` and
 *          `conceptsRegion` (task-034) are the Files-tree and Concepts-table
 *          mount points, optional and independent of each other and of
 *          `region` -- a caller that supplies neither gets exactly the
 *          Relations table this file rendered before task-034, which is what
 *          keeps this function backward compatible with a build that composes
 *          itself without the node inventories.
 * @returns {object|undefined} this rendering's private state. The shell discards
 *          it -- the handle it keeps is the drawing rendering's viewport handle.
 *          It is returned for the same reason the shell publishes one global: an
 *          assertion about the row order and the reveal needs somewhere to read
 *          that state from, and the rendered DOM is the thing under test.
 */
function mountTable(context) {
	const region = context && context.region ? context.region : null;
	if (!region || !context.store) {
		// A silent non-mount is the worst outcome available here, so it is
		// reported on the same channel and with the same shape the shell uses for
		// a build-level defect: a stable console line a headless check can assert
		// on. It cannot use the alert region, which carries a load-time failure
		// and is written at most once per load, and this is neither.
		console.error('graph.html: the relationship table rendering found no region to mount into');
		return undefined;
	}

	const pageSize = context && Number.isInteger(context.pageSize) && context.pageSize > 0 ? context.pageSize : null;

	const view = {
		store: context.store,
		graphModel: context.graphModel || context.store.getGraphModel(),
		root: context.root || null,
		region: region,
		// Everything this rendering emits per projection lives inside ONE host
		// element, which is what lets a rebuild clear its own output without
		// touching the region's authored head -- whose counts element the shell
		// writes on every notification.
		host: el('div', { 'data-table-view': true }),
		// RowOrder. Private, non-authoritative, and the only state this module
		// holds. `order` and `orderedFor` are rebuilt together per revision;
		// `focusRevealed` survives that rebuild and is cleared by any rebuild
		// that finds no marked id -- both rules, because one without the other
		// either scrolls twice for one selection or suppresses a re-selection
		// after a preset clears the selection.
		rowOrder: { order: [], orderedFor: -1, focusRevealed: null },
		rowElements: new Map(),
		unlistedElements: new Map(),
		narrow: false,
		renderedFrom: null,
		renderedLens: null,
		// Windowing (task-033). `windowed` is false and `windowCount` is Infinity
		// with no `pageSize` -- every row renders, exactly as before this task.
		windowed: pageSize !== null,
		pageSize: pageSize,
		windowCount: pageSize || Infinity,
		announceWindow: typeof (context && context.announceWindow) === 'function' ? context.announceWindow : null,
		loadMoreButton: null,
		windowStatusElement: null,
		// Files tree / Concepts table (task-034). Regions are OPTIONAL; a caller
		// that supplies neither gets this rendering exactly as it behaved before
		// task-034 -- see the doc comment above.
		filesRegion: (context && context.filesRegion) || null,
		conceptsRegion: (context && context.conceptsRegion) || null,
		// The tree's SHAPE (which folder holds which node, and each folder's
		// subtree) is a property of the model alone and does not change with the
		// lens, so it is built ONCE here rather than on every render -- only the
		// per-row checkbox/coverage state is re-derived per render.
		filesTree: null,
		// Per-folder/per-document disclosure state, UI-local and never persisted
		// (task-034's DETAIL.md persists the HIDE selection, not the collapse
		// state) -- a `Set` of tree keys that are collapsed. Empty means
		// "everything expanded", the default.
		collapsedKeys: new Set(),
	};

	// The first element in the region, so one keystroke leaves the whole of it.
	// Deliberately NOT the shell's own `skip-link` element, which the page
	// structure check asserts and the shell owns.
	region.insertBefore(tblSkipLink(), region.firstChild);
	region.appendChild(view.host);

	if (view.filesRegion) view.filesTree = tblBuildFilesTree(view.graphModel);

	// Restore the reader's checkbox-hide selection (task-034 Scope C), BEFORE
	// the first render, so the first paint already reflects it rather than
	// flashing an unfiltered view for one frame. Applied through the ordinary
	// `filters.hiddenIds` lens key -- the same door a checkbox change uses --
	// so a restore and a live edit go through one mechanism, never two.
	tblRestoreHiddenSelection(view);

	tblWatchWidth(view);
	tblRenderAll(view);
	context.store.subscribe((viewModel, lens) => {
		// A NEW projection from the store -- a filter, a sort, a selection, any
		// lens change at all -- resets the window to its first page and
		// re-announces the totals against it. Window GROWTH from "Load more"
		// never goes through the store (see tblLoadMore below), so this reset
		// can never undo it, and a filter is always read against the whole
		// admitted set rather than against whatever window happened to be open.
		if (view.windowed) view.windowCount = view.pageSize;
		tblRenderAll(view, viewModel, lens);
	});
	if (view.windowed) tblWatchScroll(view);
	return view;
}

/** Re-render every region this mount owns from the CURRENT store state --
 *  the Relations table (unchanged mechanism) plus, where the caller supplied a
 *  mount point for it, the Files tree and/or the Concepts table (task-034).
 *  One call site for "the store changed", so the three regions cannot drift
 *  out of sync with each other or with the lens. */
function tblRenderAll(view, viewModel, lensState) {
	tblRender(view, viewModel, lensState);
	if (view.filesRegion) tblRenderFilesTree(view);
	if (view.conceptsRegion) tblRenderConcepts(view);
}

registerRendering('table', mountTable);


/* ==========================================================================
 * 5. Rendering
 *
 * Every row is rendered. No pagination and no virtualisation: a partially
 * present table breaks screen-reader row counts, the browser's own
 * find-in-page, and printing. What bounds the rendered size is the reader's own
 * density and filter controls, which is where the control surface puts it.
 *
 * Rows are re-emitted in place on every notification and nothing here declares
 * motion of any kind, so a sort, a filter and a lens change all land with no
 * movement to suppress under a reduced-motion preference.
 * ========================================================================== */

function tblRender(view, viewModel, lensState) {
	const model = viewModel || view.store.getViewModel();
	const lens = lensState || view.store.getLens();
	const sort = tblSortOf(lens);
	// Built ONCE per render and threaded through, so a node lookup is a map hit
	// rather than a scan of the drawn set per row and per unlisted entry.
	const index = tblNodeIndex(model);
	const order = tblOrderFor(view, model, sort, index);
	const unlisted = tblUnlistedNodes(model);

	view.renderedFrom = model;
	view.renderedLens = lens;
	view.rowElements = new Map();
	view.unlistedElements = new Map();

	clear(view.host);
	tblRenderListed(view, model, order, sort, unlisted.length);
	if (unlisted.length > 0) tblRenderUnlisted(view, model, unlisted, index);
	// Emitted after BOTH tables, and on every pass, so the skip link's target
	// exists whenever the link does.
	view.host.appendChild(el('span', { id: TBL_END_ID, tabindex: '-1' }));

	tblRevealFocus(view, model, order);
	tblAnnounceWindow(view, order.length);
}

/**
 * The one sentence windowing has to report, at every checkpoint that changes
 * it: first paint, a "Load more" click, and any re-filter. `shown` is capped at
 * `total` even when `windowCount` has grown past it, so the sentence is never
 * "showing more than exist".
 */
function tblWindowSummary(shown, total) {
	return 'Showing ' + Math.min(shown, total) + ' of ' + tblPlural(total, 'relationship', 'relationships') + '.';
}

/** Calls the caller-owned announcer, if windowing is on and one was supplied.
 *  Creates no live region of its own -- see the file header. */
function tblAnnounceWindow(view, total) {
	if (!view.windowed || typeof view.announceWindow !== 'function') return;
	view.announceWindow(tblWindowSummary(view.windowCount, total));
}

/**
 * Grow the window by one page and re-render from the LAST projection this view
 * saw -- never through the store, which is what keeps this action from
 * colliding with the store-subscribe reset above. `windowCount` is allowed to
 * exceed `order.length`; every reader of it (the slice below, and the summary
 * sentence above) caps against the real total instead of against this number.
 */
function tblLoadMore(view) {
	if (!view.windowed) return;
	view.windowCount += view.pageSize;
	tblRender(view, view.renderedFrom, view.renderedLens);
}

/**
 * The scroll listener -- a CONVENIENCE on top of the "Load more" button, never
 * a second path: it calls the identical `tblLoadMore`, so a keyboard or
 * screen-reader user who cannot fire a scroll gesture loses nothing, and a
 * mouse user who never touches the button still reaches every row. Guarded by
 * `view.loadMoreButton` -- null once every filtered row is already rendered --
 * so it stops firing the moment there is nothing left to load, rather than
 * calling a no-op on every subsequent scroll.
 */
function tblWatchScroll(view) {
	if (typeof window === 'undefined' || typeof window.addEventListener !== 'function') return;
	let pending = false;
	window.addEventListener('scroll', () => {
		if (pending || !view.loadMoreButton) return;
		const doc = typeof document !== 'undefined' ? document.documentElement : null;
		if (!doc) return;
		const nearBottom = (window.innerHeight + window.scrollY) >= (doc.scrollHeight - TBL_SCROLL_TRIGGER_PX);
		if (!nearBottom) return;
		pending = true;
		tblLoadMore(view);
		pending = false;
	}, { passive: true });
}

/** The listed table: caption, ten sortable headers, one row per ordered row --
 *  or, windowed, one row per row in the current WINDOW of the ordered rows,
 *  plus the window's own status text and its "Load more" control. */
function tblRenderListed(view, viewModel, order, sort, unlistedCount) {
	const windowedOrder = view.windowed ? order.slice(0, view.windowCount) : order;

	const table = el('table', { class: 'tbl', 'data-relationship-table': true });
	table.appendChild(tblCaption(viewModel, unlistedCount, view.windowed ? { shown: windowedOrder.length, total: order.length } : null));

	const headRow = el('tr', {});
	for (const column of TBL_COLUMNS) headRow.appendChild(tblHeaderCell(view, column, sort));
	const head = el('thead', {}, [headRow]);
	table.appendChild(head);

	// Appended before the body is built, so the sticky header's own height can
	// be MEASURED rather than guessed: the scroll margin every focusable in the
	// body carries has to cover the top bar and this header together, and only
	// one of the two is a documented figure.
	view.host.appendChild(el('div', { class: 'tbl-wrap' }, [table]));
	const offset = TBL_TOP_BAR_PX + tblMeasuredHeight(head);

	const body = el('tbody', {});
	if (order.length === 0) {
		// A blank body is indistinguishable from a broken one, so an emptied
		// table says why. It quotes the projection's own summary rather than
		// inspecting the filters, because this module may read only `sort`, and
		// it names the control panel in words rather than linking it: the shell
		// fixes no id for that panel, so an in-page link here would depend on
		// one and add a third anchor input to the page check.
		body.appendChild(el('tr', { 'data-empty-state': true }, [
			el('td', { colspan: String(TBL_COLUMNS.length) }, [
				'No relationship row survives the current lens and filters. ' + viewModel.lensSummary
				+ ' Widen or clear a filter in the Controls panel above this table to list rows again.',
			]),
		]));
	} else {
		for (const record of windowedOrder) body.appendChild(tblBodyRow(view, record, offset));
	}
	table.appendChild(body);

	if (view.windowed) tblRenderWindowControls(view, order.length, windowedOrder.length);
}

/**
 * The window's own status text, and its "Load more" button when rows remain
 * outside the current window. The button IS the contract (see the file
 * header): it is a real, focusable, native `<button type="button">`, so `Enter`
 * and `Space` operate it by the platform's own behaviour with nothing here to
 * re-implement, exactly like every other control this file emits.
 *
 * Placed OUTSIDE `.tbl-wrap` and after it, never inside the scrolling table
 * wrapper -- a control living inside a horizontally-scrolling region would
 * itself need a scroll-margin accounting `tblScrollMargin` does not compute for
 * it, and it is not a table cell.
 */
function tblRenderWindowControls(view, total, shown) {
	view.loadMoreButton = null;

	const status = el('p', { class: 'tbl-window-status', 'data-window-status': true, tabindex: '-1' },
		[tblWindowSummary(shown, total)]);
	view.host.appendChild(status);
	view.windowStatusElement = status;

	if (shown >= total) return; // Every filtered row already rendered; nothing left to load.

	const button = el('button', { type: 'button', 'data-load-more': true }, ['Load more relationships']);
	tblSizeControl(button);
	button.addEventListener('click', () => {
		tblLoadMore(view);
		// Focus follows the gesture: the button that fired is destroyed and
		// rebuilt by the render it just caused (this module re-emits its whole
		// host on every render, never patches it), so keyboard focus is moved
		// explicitly rather than left to fall back to <body>. The new button,
		// when rows still remain; the status text otherwise, which carries a
		// tabindex for exactly this.
		const next = view.host.querySelector('[data-load-more]');
		if (next) next.focus();
		else if (view.windowStatusElement) view.windowStatusElement.focus();
	});
	view.host.appendChild(button);
	view.loadMoreButton = button;
}

/** One `<tr>`: a row header for the Source Id and nine cells. */
function tblBodyRow(view, record, offset) {
	const row = el('tr', {
		'data-row': String(record.row),
		'data-emphasis': record.dimmed ? 'dimmed' : 'normal',
		class: record.dimmed ? 'em-dimmed' : null,
	});
	tblScrollMargin(row, offset);
	for (const column of TBL_COLUMNS) {
		const children = column.cell(record, view);
		const cell = column.rowHeader ? el('th', { scope: 'row' }, children) : el('td', {}, children);
		row.appendChild(cell);
	}
	for (const button of row.querySelectorAll('button')) tblScrollMargin(button, offset);
	view.rowElements.set(record.row, row);
	return row;
}

/**
 * The unlisted-nodes region.
 *
 * The table is one row per RELATIONSHIP, so a node participating in no listed
 * row has no row of its own -- and the sharpest defect this whole view exists
 * to surface is exactly that: an artifact the project considers significant
 * with nothing said about it anywhere. Such a node therefore gets a region of
 * its own, so the table can never silently omit something the graph draws.
 *
 * Forcing these nodes into the listed table was considered and rejected: a row
 * with a real (Id, Kind, Name) triple and seven em-dashes claims a relationship
 * the file does not contain, breaks the caption's count of relationships, and
 * costs a screen-reader user seven empty-cell announcements first.
 */
function tblRenderUnlisted(view, viewModel, nodes, index) {
	const heading = el('h3', { id: TBL_UNLISTED_HEAD_ID, text: 'Nodes with no listed relationship row' });

	const table = el('table', { class: 'tbl', 'data-unlisted-table': true });
	table.appendChild(el('caption', {}, [
		tblPlural(nodes.length, 'node', 'nodes') + ' the graph draws that no listed relationship row names: '
		+ 'an enumerated source artifact with no recorded relationship at all, or a node whose every row is '
		+ 'folded into a group head. Each is named here, so no node the graph draws is absent from this table.',
	]));

	// Three column headers, wrapping no sort control, so `aria-sort` appears on
	// none of them: they are not sortable columns and saying otherwise would be
	// a state a reader cannot reach.
	table.appendChild(el('thead', {}, [el('tr', {}, [
		el('th', { scope: 'col', text: 'Id' }),
		el('th', { scope: 'col', text: 'Kind' }),
		el('th', { scope: 'col', text: 'Name' }),
	])]));

	view.host.appendChild(el('section', { id: TBL_UNLISTED_ID, 'aria-labelledby': TBL_UNLISTED_HEAD_ID }, [
		heading,
		el('div', { class: 'tbl-wrap' }, [table]),
	]));
	const offset = TBL_TOP_BAR_PX + tblMeasuredHeight(table.querySelector('thead'));

	const body = el('tbody', {});
	for (const node of nodes) {
		const endpoint = tblEndpoint(viewModel, node.id, index);
		const row = el('tr', {
			'data-unlisted-node': endpoint.id,
			'data-emphasis': endpoint.emphasis === 'dimmed' ? 'dimmed' : 'normal',
			class: endpoint.emphasis === 'dimmed' ? 'em-dimmed' : null,
		});
		tblScrollMargin(row, offset);
		// The row header, the emphasis badge's placement and the (Id, Kind,
		// Name) triple are the listed table's, so a node reads the same way in
		// both. The Name column shortens NOTHING here: this table is three
		// columns wide, and the accessible name already ends with the
		// no-recorded-relationships fact that the column exists to carry.
		row.appendChild(el('th', { scope: 'row' }, tblIdCell(endpoint)));
		row.appendChild(el('td', {}, tblKindCell(endpoint)));
		row.appendChild(el('td', {}, [endpoint.label, ' ', tblSelectButton(view, endpoint)]));
		for (const button of row.querySelectorAll('button')) tblScrollMargin(button, offset);
		body.appendChild(row);
		view.unlistedElements.set(endpoint.id, row);
	}
	table.appendChild(body);
}


/* ==========================================================================
 * 6. Cells
 * ========================================================================== */

/**
 * The Id cell: the identifier verbatim -- prefix included, which is how the
 * cell text answers where the node comes from -- that endpoint's emphasis
 * badge, and (task-034) the row's select control for that endpoint.
 *
 * The select control moves here from the Name cell, which the Relations table
 * no longer carries (D3, task-034): every row still has an Id cell for each
 * endpoint, so the FR-14a/D7a select gesture keeps exactly the mechanism it
 * had -- one control per endpoint, writing `{'focus.nodeId': id}` -- just
 * relocated to the cell that survived the slimming. `view` is optional so this
 * function stays usable from a context with no select control to offer (none
 * today; kept consistent with `tblNameCell`'s own optional `view`).
 *
 * The prefix is READ BY NOBODY here; it is present because it is part of the
 * identifier the file carries.
 */
function tblIdCell(endpoint, view) {
	const children = [
		el('code', { class: TBL_EMPHASIS_CLASSES[endpoint.emphasis] || null, text: endpoint.id }),
		tblNodeBadge(endpoint.emphasis),
	];
	if (view) {
		children.push(' ');
		children.push(tblSelectButton(view, endpoint));
	}
	return children;
}

/** The Kind cell: the closed enum's value as TEXT, plus the kind's shape glyph.
 *  Both come from the projection -- the value from the node record's own Kind
 *  field, the glyph and the colour class from the node encoding -- so two nodes
 *  sharing an identifier prefix and differing in kind render differently, and
 *  two nodes of one kind spelled with different prefixes render alike. */
function tblKindCell(endpoint) {
	return [
		endpoint.glyph ? el('span', { class: endpoint.kindClass || null, 'aria-hidden': 'true', text: endpoint.glyph + ' ' }) : null,
		endpoint.kind,
	];
}

/**
 * The Name cell's TEXT form (task-034) -- no button, no endpoint-cell coupling.
 * Used by the Files tree and the Concepts table (§ 13), which name a NODE
 * rather than a relationship endpoint and carry their own, single select
 * surface per row (the Show checkbox), not this rendering's node-select
 * gesture.
 *
 * Content here is unbounded in length by construction -- a `fact` display name
 * reproduces a knowledge-base anchor string verbatim -- so below the mobile
 * breakpoint the cell shows the short label as its only VISIBLE text and
 * carries the full name beside it for the accessibility tree, exactly the
 * shortened-cell contract feature-007 AC-S8 and this feature's AC-S7 describe
 * for a Name cell generally: the shortened form sits only inside
 * `aria-hidden`, reaches no accessibility tree, and appears nowhere above the
 * breakpoint.
 *
 * @param {string} label the full accessible name
 * @param {string} shortLabel the shortened, presentation-only form
 * @param {boolean} narrow
 */
function tblTreeNameText(label, shortLabel, narrow) {
	if (!narrow || shortLabel === label) return [label];
	return [
		el('span', { 'aria-hidden': 'true', text: shortLabel }),
		el('span', { class: 'sr-only', text: label }),
	];
}

/** A text badge, or nothing. Never colour alone: the meaning is the text. */
function tblNodeBadge(emphasis) {
	const badge = TBL_NODE_BADGES[emphasis];
	return badge ? el('span', { class: 'badge ' + badge.variant, text: badge.text }) : null;
}

function tblEdgeBadge(emphasis) {
	const badge = TBL_EDGE_BADGES[emphasis];
	return badge ? el('span', { class: 'badge ' + badge.variant, text: badge.text }) : null;
}


/* ==========================================================================
 * 7. The two controls this rendering emits
 *
 * Both are native `<button>` elements, so `Enter` and `Space` operate each one
 * by the platform's own button behaviour and nothing here re-implements it.
 * Neither carries the shell's control attribute and neither carries its group
 * attribute: this DOM is per projection while the shell's manifest is built
 * once at load, so a manifest entry per row would falsify the manifest-to-DOM
 * bijection the moment a filter removed a row, and a second disclosure per
 * group would falsify "exactly one per foldable group".
 * ========================================================================== */

/**
 * Select, one per ENDPOINT rather than one per row.
 *
 * The file normalises every row so the source identifier sorts first, so a node
 * whose id sorts last in every row it appears on would be unselectable from a
 * source-only control.
 *
 * It writes the single dotted key. The control state is a FLAT record with
 * dotted field names, so the shallow merge leaves the focus depth untouched and
 * the drawing surface's neighbourhood moves to this node at the depth the
 * reader already chose. It navigates nowhere -- opening an artifact is the
 * shell's separate gesture, two steps from a row and deliberately so.
 */
function tblSelectButton(view, endpoint) {
	const button = el('button', {
		type: 'button',
		'data-row-select': endpoint.id,
		'aria-label': 'Select ' + endpoint.label,
	}, ['Select']);
	tblSizeControl(button);
	button.addEventListener('click', () => { view.store.setLens({ 'focus.nodeId': endpoint.id }); });
	return button;
}

/**
 * One sort control per column header, cycling ascending, descending, then back
 * to the file's own order.
 *
 * `aria-sort` lives on the `<th scope="col">` and on no other cell: never on a
 * row header, which is not a sortable column, and never in the unlisted region,
 * whose headers wrap no control. At most one of the ten carries a non-`none`
 * value, and when the sort is the file's order every one of them carries
 * `none` -- the platform-correct statement of "not sorted by this column",
 * which also gives the reader a way back to the file's order with no extra
 * control.
 */
function tblHeaderCell(view, column, sort) {
	const state = tblAriaSort(sort, column.token);
	const th = el('th', { scope: 'col', 'aria-sort': state, 'data-column': column.token });
	// The reused header rule pins to the viewport edge, which the sticky top bar
	// would then cover.
	tblStickyTop(th);

	const button = el('button', {
		type: 'button',
		'data-sort-column': column.token,
		'aria-label': column.label + ', ' + TBL_SORT_NEXT_WORDING[state],
	}, [
		column.label,
		el('span', { 'aria-hidden': 'true', text: ' ' + TBL_SORT_CARETS[state] }),
	]);
	tblSizeControl(button);
	button.addEventListener('click', () => { view.store.setLens({ 'sort': tblNextSort(sort, column.token) }); });
	th.appendChild(button);
	return th;
}

/** The region's first element, and what bounds its traversal: one keystroke
 *  leaves every row of both tables. */
function tblSkipLink() {
	return el('a', { href: '#' + TBL_END_ID }, ['Skip relationship table']);
}


/* ==========================================================================
 * 8. The caption
 *
 * Screen readers read it on table entry, so the reader learns the scope before
 * the data. It states the DRAWN counts, so the caption and the shell's own
 * header can never disagree, and the projection's summary sentence rather than
 * one composed here.
 *
 * The two counts are the two ROW figures. The node figures are the shell's
 * header's, and reporting a node count in a relationship count's sentence is
 * how two surfaces start disagreeing about what was hidden.
 * ========================================================================== */

function tblCaption(viewModel, unlistedCount, windowInfo) {
	// Windowed and unwindowed open with two DIFFERENT sentences, deliberately:
	// the unwindowed one states the two DRAWN counts (every one of which has a
	// row in the DOM), and the windowed one states what is actually IN THE DOM
	// against the filtered total -- the property the file header's "partially
	// present table" warning is about. Restating the drawn-count sentence here
	// while only `windowInfo.shown` rows exist would be exactly that defect:
	// screen readers, find-in-page and printing would all be told a count the
	// table does not back.
	const opening = windowInfo
		? el('span', { text: tblWindowSummary(windowInfo.shown, windowInfo.total) + ' '
			+ viewModel.counts.hiddenEdges + ' more hidden by the current filters. ' })
		: el('span', {
			text: tblPlural(viewModel.counts.edges, 'relationship', 'relationships') + ' listed, '
				+ viewModel.counts.hiddenEdges + ' hidden. ',
		});
	const children = [
		opening,
		el('span', { text: viewModel.lensSummary + ' ' }),
		el('span', {}, ['Every cell is taken from ', el('a', { href: './relationships.md' }, ['relationships.md']), '.']),
	];
	if (unlistedCount > 0) {
		children.push(el('span', {}, [
			' ',
			el('a', { href: '#' + TBL_UNLISTED_ID }, [
				'No listed row names ' + tblPlural(unlistedCount, 'node', 'nodes') + ' the graph draws',
			]),
			'.',
		]));
	}
	return el('caption', {}, children);
}


/* ==========================================================================
 * 9. The row set, and the order over it
 * ========================================================================== */

/**
 * The rows this table lists: exactly the projection's rows whose fold entry is
 * not 'collapsed', reordered and nothing else. Never an addition, a removal or
 * a re-derivation -- membership belongs to the projection, and that single
 * restriction is what makes the Coverage listing exact rather than approximate.
 */
function tblRowRecords(viewModel, index) {
	const nodes = index || tblNodeIndex(viewModel);
	const records = [];
	for (const edge of viewModel.visibleEdges) {
		const fold = viewModel.edgeFold.get(edge.key);
		if (!fold || fold === 'collapsed') continue;
		records.push(tblRowRecord(viewModel, nodes, edge, fold));
	}
	return records;
}

function tblRowRecord(viewModel, index, edge, fold) {
	const record = {
		edge: edge,
		key: edge.key,
		row: edge.row,
		source: tblEndpoint(viewModel, fold.sourceId, index),
		target: tblEndpoint(viewModel, fold.targetId, index),
		s2t: edge.s2t,
		t2s: edge.t2s,
		provenance: edge.provenance,
		observation: edge.observation,
		edgeEmphasis: viewModel.edgeEmphasis.get(edge.key) || 'normal',
		values: null,
	};
	// `dimmed` is taken from EITHER map, because a selection assigns no edge class
	// at all and a row outside the focused neighbourhood is dimmed through its
	// endpoints. But it is the COMPLEMENT of the marked set, and that is what
	// decides the order of the two tests: a positively-marked row -- a gap
	// endpoint, the selection, or a chain reading -- is NOT in the dimmed
	// remainder, even though its other endpoint almost always is. Under the
	// Coverage lens every non-gap node is `dimmed`, so testing the maps first
	// would dim nearly every row including the gap rows, and "this row carries no
	// text badge" would stop being what the de-emphasis means -- which is the one
	// property the no-colour-only argument rests on.
	record.marked = TBL_NODE_BADGES[record.source.emphasis] !== undefined
		|| TBL_NODE_BADGES[record.target.emphasis] !== undefined
		|| TBL_EDGE_BADGES[record.edgeEmphasis] !== undefined;
	record.dimmed = !record.marked
		&& (record.edgeEmphasis === 'dimmed'
			|| record.source.emphasis === 'dimmed'
			|| record.target.emphasis === 'dimmed');

	const values = {};
	for (const column of TBL_COLUMNS) values[column.token] = column.value(record);
	values[TBL_FILE_ORDER] = record.row;
	record.values = values;
	return record;
}

/**
 * One endpoint, AS THE FOLD RESOLVES IT -- the id the row is drawn between and
 * listed as. Kind comes from the node record, the accessible name from the
 * label map, and the glyph and colour class from the encoding map. No branch
 * here reads an identifier's prefix.
 */
function tblEndpoint(viewModel, id, index) {
	const nodes = index || tblNodeIndex(viewModel);
	const node = nodes.get(id) || null;
	const encoding = viewModel.nodeEncoding.get(id) || null;
	const label = viewModel.nodeLabels.get(id);
	return {
		id: id,
		kind: node ? node.kind : '',
		label: typeof label === 'string' ? label : id,
		shortLabel: viewModel.nodeShortLabels.get(id) || (typeof label === 'string' ? label : id),
		emphasis: viewModel.nodeEmphasis.get(id) || 'normal',
		glyph: encoding ? encoding.glyph : '',
		kindClass: encoding ? tblTokenClass(encoding.colourToken) : '',
	};
}

function tblNodeIndex(viewModel) {
	const index = new Map();
	for (const node of viewModel.visibleNodes) index.set(node.id, node);
	return index;
}

/**
 * The nodes no listed row names: the drawn node set minus every id a
 * non-collapsed fold entry names. Three populations reach it, and the
 * derivation is over the FOLD rather than over a node's recorded degree because
 * a degree test would miss the second of them entirely:
 *
 *   1. a source artifact with no relationship row at all, materialised from the
 *      recorded gap list -- the sharpest gap, and the reason this region exists;
 *   2. a group head whose every incident row the fold collapsed. Its degree is
 *      one or more, so a degree test misses it;
 *   3. the selected node when it has no surviving rows, which the drawn node
 *      set admits by contract.
 *
 * A node whose rows were merely FILTERED out is not in this set and needs no
 * handling: it is not an endpoint of any surviving row, so it is not in the
 * drawn node set at all unless it is also (1) or (3).
 *
 * The region is not gated on a lens -- these nodes are a fact about the
 * projection, not a lens result -- is not exempt from the filters, and carries
 * no severity of its own.
 */
function tblUnlistedNodes(viewModel) {
	const named = new Set();
	for (const edge of viewModel.visibleEdges) {
		const fold = viewModel.edgeFold.get(edge.key);
		if (!fold || fold === 'collapsed') continue;
		named.add(fold.sourceId);
		named.add(fold.targetId);
	}
	// The drawn node set is already in ascending identifier order, so this
	// filter preserves a deterministic order without sorting again.
	return viewModel.visibleNodes.filter((node) => !named.has(node.id));
}

/**
 * The order, cached against the revision alone.
 *
 * `sort` is a control-state field, so a sort change goes through the store and
 * produces a new revision like any other change. Caching the order against the
 * revision is therefore total, and a second key on `sort` would be dead.
 */
function tblOrderFor(view, viewModel, sort, index) {
	if (view.rowOrder.orderedFor === viewModel.revision) return view.rowOrder.order;
	const records = tblRowRecords(viewModel, index);
	records.sort((a, b) => tblCompareRows(a, b, sort.column, sort.direction));
	view.rowOrder.order = records;
	view.rowOrder.orderedFor = viewModel.revision;
	return records;
}

/**
 * The comparator, and why the order is total.
 *
 * The primary key is the sorted column's VALUE and never its visible text,
 * which the responsive collapse can shorten -- so a narrow viewport cannot
 * reorder rows. Values are compared BY CODE UNIT and never by a locale
 * comparison, because a locale comparison would reorder rows by browser locale
 * and identifiers carry exact on-disk case. `desc` reverses the primary
 * comparison only, and the tie-break is the file row index ASCENDING in both
 * directions.
 *
 * The file row index is unique per row by construction, so no two rows compare
 * equal and the order is a function of the row set and the sort key alone. Over
 * a uniform column both directions therefore equal the file's own order, which
 * is the tie-break's doing rather than a defect. The file order is not a
 * special case: it is the same comparator over the row index, whose primary
 * comparison never ties, so the tie-break is unreachable for it.
 */
function tblCompareRows(a, b, column, direction) {
	const left = a.values[column];
	const right = b.values[column];
	let primary = left < right ? -1 : (left > right ? 1 : 0);
	if (direction === 'desc') primary = -primary;
	if (primary !== 0) return primary;
	return a.row < b.row ? -1 : (a.row > b.row ? 1 : 0);
}

/**
 * The one control-state field this rendering reads, normalised to its own
 * declared value space.
 *
 * A column outside that space falls back to the INITIAL value of the whole
 * field -- the file's own order, ascending -- and not to the file order in
 * whatever direction came with the rejected column: half-honouring a value the
 * other half of which was rejected would answer a garbage column with a
 * reversed file order, which no reader asked for.
 */
function tblSortOf(lens) {
	const held = lens ? lens['sort'] : null;
	if (!held || !TBL_SORT_COLUMNS.has(held.column)) return { column: TBL_FILE_ORDER, direction: 'asc' };
	return { column: held.column, direction: held.direction === 'desc' ? 'desc' : 'asc' };
}

/** ascending -> descending -> the file's own order. */
function tblNextSort(sort, token) {
	if (sort.column !== token) return { column: token, direction: 'asc' };
	if (sort.direction === 'asc') return { column: token, direction: 'desc' };
	return { column: TBL_FILE_ORDER, direction: 'asc' };
}

function tblAriaSort(sort, token) {
	if (sort.column !== token) return 'none';
	return sort.direction === 'desc' ? 'descending' : 'ascending';
}


/* ==========================================================================
 * 10. The reveal -- the select gesture's third clause
 *
 * Selecting a node sets the selection, focuses its neighbourhood, drives the
 * adjustable-depth view AND shows the node's rows in the table view. The file
 * row index is the only node-to-row tie in the page, so no other surface can
 * perform this.
 *
 * The target is the id the projection marks as the selection, which is already
 * resolved through the fold and keyed over the drawn node set alone, so it is
 * always a node this region names. That the mark exists is an upstream
 * guarantee and not this module's assumption: the node emphasis axis is a total
 * precedence whose first step is the fold-resolved selection, whatever else
 * applies to it.
 *
 * What is revealed is the first row of the CURRENT order naming it -- so the
 * reveal follows the reader's sort order rather than the file's -- or, where
 * every row naming it is collapsed or it names none, its unlisted-region row.
 * The scroll is the minimal one clearing both sticky layers and is
 * instantaneous by an explicit option: the shared stylesheet's own `html` rule
 * would otherwise animate it. It moves NO focus.
 * ========================================================================== */

function tblRevealFocus(view, viewModel, order) {
	const marked = tblFocusMarked(viewModel);
	if (marked === null) {
		// The clearing rule. Without it, select A, then a preset that clears the
		// selection, then select A again is not a "new" id and the reveal stays
		// suppressed for the rest of the session.
		view.rowOrder.focusRevealed = null;
		return;
	}
	if (marked === view.rowOrder.focusRevealed) return;
	view.rowOrder.focusRevealed = marked;

	const target = tblRevealTarget(view, order, marked);
	if (!target || typeof target.scrollIntoView !== 'function') return;
	target.scrollIntoView({ block: 'nearest', inline: 'nearest', behavior: 'instant' });
}

/** The one id the projection marks as the selection, or null. */
function tblFocusMarked(viewModel) {
	for (const entry of viewModel.nodeEmphasis) {
		if (entry[1] === 'focus') return entry[0];
	}
	return null;
}

function tblRevealTarget(view, order, id) {
	for (const record of order) {
		if (record.source.id !== id && record.target.id !== id) continue;
		const row = view.rowElements.get(record.row);
		if (row) return row;
	}
	return view.unlistedElements.get(id) || null;
}


/* ==========================================================================
 * 11. Small helpers
 *
 * Namespaced, because this file shares one module scope with three others.
 * ========================================================================== */

/** A colour TOKEN NAME turned into the shared stylesheet's class for it. The
 *  token comes from the projection, so the class is keyed on the node's kind or
 *  the row's category and on nothing else -- and no colour VALUE is named here
 *  or anywhere else in this file. */
function tblTokenClass(token) {
	const name = String(token || '').replace(/^--/, '');
	if (name.indexOf('gk-') === 0) return 'k-' + name.slice(3);
	if (name.indexOf('gc-') === 0) return 'c-' + name.slice(3);
	return '';
}

function tblPlural(count, one, many) {
	return count + ' ' + (count === 1 ? one : many);
}

/** The minimum hit area, applied to every control this rendering emits. */
function tblSizeControl(button) {
	if (!button.style) return;
	button.style.minWidth = TBL_HIT_AREA;
	button.style.minHeight = TBL_HIT_AREA;
}

/**
 * The sticky header's vertical offset is OWNED BY THE STYLESHEET, not set here.
 *
 * This used to write `top: 60px` inline, to clear the page's sticky top bar. That
 * reasoning holds only if the header sticks to the VIEWPORT, and it does not:
 * the table is wrapped in `.tbl-wrap`, which sets `overflow-x: auto`, and CSS
 * computes the other axis of a non-visible overflow to `auto` as well -- so the
 * wrapper is itself a scroll container and sticky resolves against IT. Measured
 * in Chromium: the wrapper's computed `overflow-y` is `auto`.
 *
 * The inline 60px therefore did not clear anything. It pushed the header row 60px
 * DOWN from the top of its own scroll container, directly over the first body
 * rows -- which is exactly the overlap the owner reported. The correct offset
 * against that container is 0, and it is set in `graph-css.css` beside the rest of
 * the table's sticky rules, where the row-header column's horizontal pinning also
 * lives and can be reasoned about together.
 *
 * Kept as a named no-op rather than deleted at the call site, so the call site
 * still says what it is doing and this explanation has somewhere to live.
 */
function tblStickyTop() {
	/* Intentionally empty -- see above. */
}

/** The scroll margin covering BOTH sticky layers, so a focused row control is
 *  not obscured by either -- whether the browser scrolled to it on focus or the
 *  reveal above scrolled to it. */
function tblScrollMargin(element, offset) {
	if (!element.style) return;
	element.style.scrollMarginTop = offset + 'px';
}

/** A measured height, or zero where the environment provides no layout. */
function tblMeasuredHeight(element) {
	if (!element || typeof element.getBoundingClientRect !== 'function') return 0;
	const box = element.getBoundingClientRect();
	const height = box && typeof box.height === 'number' ? box.height : 0;
	return height > 0 ? Math.ceil(height) : 0;
}

/**
 * Which of the two Name-cell forms to render.
 *
 * A media query rather than a measurement, and the SAME breakpoint the shared
 * stylesheet uses -- this rendering introduces no second breakpoint scale. A
 * crossing re-emits the rows at the same revision, which the cached order makes
 * cheap and which cannot re-fire the reveal, because the revealed id is
 * unchanged.
 */
function tblWatchWidth(view) {
	if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return;
	const query = window.matchMedia('(max-width: ' + TBL_MOBILE_MAX_PX + 'px)');
	view.narrowQuery = query;
	view.narrow = !!query.matches;
	const push = () => { view.narrow = !!query.matches; tblRenderAll(view); };
	if (typeof query.addEventListener === 'function') query.addEventListener('change', push);
	else if (typeof query.addListener === 'function') query.addListener(push);
}


/* ==========================================================================
 * 13. The Files tree and the Concepts table (task-034)
 *
 * Two more inventories over EVERY node in the model -- not the lens-filtered
 * `viewModel.visibleNodes` the Relations table reads above, but
 * `view.graphModel.nodes` itself. That is the design this task exists to
 * state: a node's own properties (id, kind, name, provenance, coverage) are
 * the same whatever the lens is doing to the EDGES, and showing every node
 * unconditionally is what makes the completeness guarantee -- every node has
 * a home, none is missing, none is duplicated -- something the lens cannot
 * break by filtering an edge away.
 *
 * THE PARTITION. `kind === 'concept'` -> Concepts (flat, 32 today, over the
 * live fixture). Every other kind -> Files: `section`/`fact` nest under the
 * `document` their id names (`kbDocOf`, graph-model.js), and everything else
 * (`document`, `source-artifact`, `image`, `web-page`) is a file-tree leaf,
 * positioned by its repository path where it has one and under a synthetic
 * "External sources" bucket where it does not (an external `image`, or any
 * `web-page`). That is an EXHAUSTIVE rule over the seven-kind enum -- every
 * node either is a concept or is not -- so the partition needs no enumeration
 * of what "file" means and cannot silently miss a kind a future schema change
 * adds.
 *
 * THE CHECKBOX HIDES FROM VIEW, NEVER FROM DATA. Unchecking a row writes every
 * real node id in its subtree into `filters.hiddenIds` (graph-model.js
 * §§ 3, 9); re-checking removes exactly that subtree's ids and nothing else --
 * acceptance item 4's own wording. Both tables and the Relations table read
 * the SAME store, so a hide is visible everywhere in the same tick, and
 * nothing here re-derives coverage: the badge each row shows comes straight
 * from `viewModel.coverageGaps`, computed once at load and untouched by this
 * axis (graph-model.js `verifyCoverage` runs before any lens exists).
 *
 * PERSISTENCE (Scope C). `tblRestoreHiddenSelection` runs once, at mount,
 * before the first render. Every subsequent checkbox edit calls
 * `writeHiddenSelection` with the FULL current hidden-id list, so what is
 * remembered is always the resolved set the store is actually applying, never
 * a UI-local approximation of it.
 *
 * WHAT IS NOT HERE. No windowing (task-034's DETAIL.md: 520 and 32 rows,
 * neither needs one -- windowing stays the Relations table's, over its 3550).
 * No select control: the FR-14a/D7a node-select gesture stays on the
 * Relations table's Id cells (§ 6), which are what the reveal mechanism
 * (§ 10) already knows how to scroll to.
 * ========================================================================== */

const TBL_EXTERNAL_BUCKET_NAME = 'External sources';

/** True for a node with no repository path of its own -- an external image or
 *  any web page -- which the Files tree buckets together rather than
 *  inventing a path for. Prefix-read: the in-repo/external split of an image
 *  is exactly the question graph-model.js's own `Node` doc calls out as a
 *  correct prefix read (its site 4/5), reused here rather than re-derived. */
function tblIsExternalFile(node) {
	if (node.kind === 'web-page') return true;
	if (node.kind === 'image') return node.prefix !== 'int';
	return false;
}

/** The repository-relative path a Files-tree leaf sorts into: the id with its
 *  prefix removed. Meaningful only for a node `tblIsExternalFile` says is NOT
 *  external. */
function tblRepoPath(node) {
	return node.id.slice(node.id.indexOf(':') + 1);
}

/**
 * Build the Files tree once per mount. A pure function of `graphModel` alone
 * (no lens, no store), so it needs building only once -- the model itself
 * changes only at load.
 *
 * A FOLDER entry is `{type:'folder', key, name, children}`; a FILE entry is
 * `{type:'file', key, node, children}`, `children` non-empty only for a
 * `document` entry, holding its nested `section`/`fact` file entries. `key` is
 * a real node id for a file and a synthetic path (trailing `/`) for a folder
 * -- the two spaces never collide, because no node id in this vocabulary ends
 * in `/`.
 *
 * @param {object} graphModel
 * @returns {object} the root folder entry (itself never rendered as a row)
 */
function tblBuildFilesTree(graphModel) {
	const root = { type: 'folder', key: '', name: '', children: [], byName: new Map() };
	const nested = new Map(); // kbDoc -> [section/fact node, ...]
	const fileNodes = [];

	for (const node of graphModel.nodes.values()) {
		if (node.kind === 'concept') continue;
		if (node.kind === 'section' || node.kind === 'fact') {
			const doc = node.kbDoc || '';
			if (!nested.has(doc)) nested.set(doc, []);
			nested.get(doc).push(node);
			continue;
		}
		fileNodes.push(node);
	}

	function folderFor(segments) {
		let cursor = root;
		let soFar = '';
		for (const seg of segments) {
			soFar = soFar === '' ? seg : soFar + '/' + seg;
			if (!cursor.byName.has(seg)) {
				const folder = { type: 'folder', key: soFar + '/', name: seg, children: [], byName: new Map() };
				cursor.byName.set(seg, folder);
				cursor.children.push(folder);
			}
			cursor = cursor.byName.get(seg);
		}
		return cursor;
	}

	const attachedDocs = new Set();
	for (const node of fileNodes.slice().sort((a, b) => compareStrings(a.id, b.id))) {
		const fileEntry = { type: 'file', key: node.id, node: node, children: [] };
		let folder;
		if (tblIsExternalFile(node)) {
			folder = folderFor([TBL_EXTERNAL_BUCKET_NAME]);
		} else {
			const segments = tblRepoPath(node).split('/');
			segments.pop();
			folder = folderFor(segments);
		}
		folder.children.push(fileEntry);
		if (node.kind === 'document') {
			const docKey = node.kbDoc || node.id;
			attachedDocs.add(docKey);
			for (const child of (nested.get(docKey) || []).slice().sort((a, b) => compareStrings(a.id, b.id))) {
				fileEntry.children.push({ type: 'file', key: child.id, node: child, children: [] });
			}
		}
	}

	// A section/fact naming a document this model has no node for cannot
	// happen on a well-formed artifact -- the schema requires a document node
	// for every `kb:<doc>#...` id a section/fact is extracted from -- but is
	// attached here rather than silently dropped, so the completeness
	// guarantee (acceptance item 1) holds even against a malformed one.
	for (const [doc, members] of nested) {
		if (attachedDocs.has(doc)) continue;
		const folder = folderFor([TBL_EXTERNAL_BUCKET_NAME, 'unattached: ' + (doc || '(no document)')]);
		for (const child of members.slice().sort((a, b) => compareStrings(a.id, b.id))) {
			folder.children.push({ type: 'file', key: child.id, node: child, children: [] });
		}
	}

	(function sortTree(folder) {
		folder.children.sort((a, b) => {
			if (a.type !== b.type) return a.type === 'folder' ? -1 : 1;
			const an = a.type === 'folder' ? a.name : a.node.id;
			const bn = b.type === 'folder' ? b.name : b.node.id;
			return compareStrings(an, bn);
		});
		for (const child of folder.children) if (child.children.length > 0 || child.type === 'folder') sortTree(child);
	})(root);

	return root;
}

/** Every REAL node id in an entry's subtree: itself (if a file) plus every
 *  descendant file's id. A folder contributes no id of its own -- it is a
 *  synthetic grouping, never something `filters.hiddenIds` could name. */
function tblSubtreeIds(entry, out) {
	const ids = out || [];
	if (entry.type === 'file') ids.push(entry.node.id);
	for (const child of entry.children) tblSubtreeIds(child, ids);
	return ids;
}

/**
 * Flatten a tree into DFS pre-order rows, each carrying the KEYS of every
 * ancestor that has children (so is collapsible) -- the set `tblRenderFilesTree`
 * tests a row's visibility against. The root contributes no row of its own.
 *
 * @param {object} root
 * @returns {Array<{entry: object, depth: number, ancestorKeys: string[]}>}
 */
function tblFlattenTree(root) {
	const rows = [];
	(function walk(folder, depth, ancestors) {
		for (const entry of folder.children) {
			rows.push({ entry: entry, depth: depth, ancestorKeys: ancestors.slice() });
			if (entry.children.length > 0) walk(entry, depth + 1, ancestors.concat([entry.key]));
		}
	})(root, 1, []);
	return rows;
}

/** The store's CURRENT checkbox-hide set, read fresh on every render -- the
 *  same discipline every other lens field in this file follows (§ 1 rule 1),
 *  never cached across a render. */
function tblHiddenSet(view) {
	return new Set(view.store.getLens()['filters.hiddenIds'] || []);
}

/**
 * Write a NEXT hidden-id list: through the store, so the Relations table, the
 * graph and both node tables all move in the same tick, and to storage
 * (Scope C) -- always the FULL resolved set the store is now applying, never
 * a UI-local approximation of it, so a later restore reconstructs exactly
 * this state.
 */
function tblCommitHidden(view, nextIds) {
	const list = Array.from(new Set(nextIds));
	view.store.setLens({ 'filters.hiddenIds': list });
	writeHiddenSelection(list);
}

/** Toggle one row: add its subtree to the hidden set (unchecked) or remove it
 *  (checked) -- and nothing OUTSIDE that subtree, which is acceptance item 4's
 *  own wording ("restores exactly what was hidden and nothing else"). */
function tblToggleHidden(view, entry, hide) {
	const subtree = tblSubtreeIds(entry);
	const current = tblHiddenSet(view);
	if (hide) for (const id of subtree) current.add(id);
	else for (const id of subtree) current.delete(id);
	tblCommitHidden(view, Array.from(current));
}

/** Every node id's provenance values, over the WHOLE model -- built once per
 *  render (one pass over the edges) so the Files tree and the Concepts table
 *  can each look a node's provenance up rather than scanning the edge list
 *  once per row. Node records carry no provenance field of their own: a
 *  relationship's provenance is a property of the EDGE (graph-model.js
 *  `Edge.provenance`), so a node's is the set of values across every edge
 *  naming it. */
function tblProvenanceIndex(graphModel) {
	const index = new Map();
	for (const edge of graphModel.edges) {
		if (!index.has(edge.sourceId)) index.set(edge.sourceId, new Set());
		if (!index.has(edge.targetId)) index.set(edge.targetId, new Set());
		index.get(edge.sourceId).add(edge.provenance);
		index.get(edge.targetId).add(edge.provenance);
	}
	return index;
}

/** A node's provenance, as text: the one value it has everywhere it appears,
 *  or every distinct value it has where they differ, joined -- so no
 *  information is dropped by picking one arbitrarily -- or an explicit
 *  statement for a node this model records no edge for at all. */
function tblProvenanceText(index, id) {
	const set = index.get(id);
	if (!set || set.size === 0) return 'no relationships';
	return Array.from(set).sort(compareStrings).join(', ');
}

/**
 * A node's coverage class, independent of the lens -- read straight from the
 * two sets `viewModel.coverageGaps` carries (computed once at load; see
 * graph-model.js `verifyCoverage`) rather than from `nodeEmphasis`, which only
 * carries this distinction while the Coverage preset is active. The Files
 * tree and Concepts table state a node's coverage state UNCONDITIONALLY
 * (task-034 Scope A1), so they read a field that never goes quiet under a
 * different lens.
 */
function tblStaticCoverageClass(kbUnbackedSet, artifactGapSet, id) {
	if (kbUnbackedSet.has(id)) return 'kb-unbacked';
	if (artifactGapSet.has(id)) return 'artifact-undocumented';
	return null;
}

/** The kind glyph and colour class for a plain node record -- the same shapes
 *  `tblKindCell` already renders for a Relations-row endpoint, adapted for a
 *  node this file reads directly rather than through `nodeEncoding` (which is
 *  keyed over the lens-filtered drawn set, and these tables read every node
 *  whether the lens currently draws it or not). */
function tblKindOf(node) {
	const encoding = KIND_ENCODING[node.kind];
	return { kind: node.kind, glyph: encoding ? encoding.glyph : '', kindClass: encoding ? tblTokenClass(encoding.colourToken) : '' };
}

/** The Id cell for a Files-tree or Concepts row: the identifier verbatim plus
 *  its coverage badge -- no select control (§ 13's own header: that gesture
 *  stays on the Relations table). */
function tblTreeIdCell(node, coverageClass) {
	return [
		el('code', { class: TBL_EMPHASIS_CLASSES[coverageClass] || null, text: node.id }),
		coverageClass ? tblNodeBadge(coverageClass) : null,
	];
}

/**
 * The Show checkbox for one row: checked when NO id in its subtree is hidden,
 * unchecked when EVERY id in it is, indeterminate -- the native IDL property,
 * which browsers map to `aria-checked="mixed"` for assistive technology with
 * no ARIA authored here -- when some but not all are. A folder's own checkbox
 * therefore always reflects its subtree rather than carrying separate state
 * of its own, which is what makes acceptance item 4 ("re-checking restores
 * exactly what was hidden and nothing else") a property of this one
 * computation rather than something a handler has to remember separately.
 */
function tblShowCheckbox(view, entry, label) {
	const subtree = tblSubtreeIds(entry);
	const hidden = tblHiddenSet(view);
	const hiddenCount = subtree.filter((id) => hidden.has(id)).length;
	const box = el('input', {
		type: 'checkbox',
		'data-tree-show': entry.key,
		'aria-label': 'Show ' + label,
	});
	box.checked = hiddenCount === 0;
	box.indeterminate = hiddenCount > 0 && hiddenCount < subtree.length;
	tblSizeControl(box);
	box.addEventListener('change', () => { tblToggleHidden(view, entry, !box.checked); });
	return box;
}

/**
 * The collapse/expand disclosure for a row with children -- a real button, so
 * `Enter` and `Space` operate it with nothing here re-implementing anything,
 * and `aria-expanded` is the SAME carrier the shell's own group disclosures
 * use (feature-007's precedent, named in this file's own "what must not
 * regress" note) -- so a collapsed folder's state is exposed to assistive
 * technology exactly the way an existing, already-reviewed disclosure states
 * it. The marker attribute, `data-tree-toggle`, is spelled DIFFERENTLY from
 * the shell's own group-disclosure marker on purpose (see this file's static
 * grep for that literal, TV08a) -- keeping this row out of feature-007's
 * "exactly one disclosure per foldable GROUP" count, since a lens grouping and
 * a file-tree folder are different concepts and must not share one counter.
 */
function tblTreeToggle(view, entry, label) {
	const collapsed = view.collapsedKeys.has(entry.key);
	const button = el('button', {
		type: 'button',
		'data-tree-toggle': entry.key,
		'aria-expanded': collapsed ? 'false' : 'true',
		'aria-label': (collapsed ? 'Expand ' : 'Collapse ') + label,
	}, [collapsed ? '▸' : '▾']);
	tblSizeControl(button);
	button.addEventListener('click', () => {
		if (view.collapsedKeys.has(entry.key)) view.collapsedKeys.delete(entry.key);
		else view.collapsedKeys.add(entry.key);
		tblRenderFilesTree(view);
	});
	return button;
}

/**
 * The Name cell: connecting-line guides for every ancestor level (indentation
 * is presentation, per this file's "what must not regress" note -- the
 * STRUCTURAL carrier of nesting is `aria-level`, set on the `<tr>` itself,
 * below), the row's own disclosure button where it has children, and the
 * text form § 6's `tblTreeNameText` already renders for a Relations endpoint,
 * reused here verbatim.
 */
function tblTreeNameCell(view, row, label, shortLabel) {
	const children = [];
	for (let i = 1; i < row.depth; i += 1) children.push(el('span', { class: 'tbl-tree-guide', 'aria-hidden': 'true' }));
	if (row.entry.children.length > 0) children.push(tblTreeToggle(view, row.entry, label));
	else children.push(el('span', { class: 'tbl-tree-guide tbl-tree-leaf', 'aria-hidden': 'true' }));
	for (const part of tblTreeNameText(label, shortLabel, view.narrow)) children.push(part);
	return [el('span', { class: 'tbl-tree-cell' }, children)];
}

/** The six shared column headers both node tables use -- Files and Concepts
 *  carry "the same property columns, same checkboxes" (task-034 Scope A2), so
 *  one function builds both header rows rather than two copies drifting
 *  apart. */
function tblNodeTableHead() {
	return el('thead', {}, [el('tr', {}, [
		el('th', { scope: 'col', text: 'Show' }),
		el('th', { scope: 'col', text: 'Name' }),
		el('th', { scope: 'col', text: 'Id' }),
		el('th', { scope: 'col', text: 'Kind' }),
		el('th', { scope: 'col', text: 'Provenance' }),
		el('th', { scope: 'col', text: 'Coverage' }),
	])]);
}

/**
 * The Files tree region: a collapsible table over EVERY file-backed node in
 * the model (§ 13's partition) -- 520 rows today, none of it windowed. `role`
 * is set to `treegrid` on the table itself, and `aria-level` plus
 * `aria-expanded` on each row, which is the ARIA treegrid pattern for exactly
 * this shape (a table whose rows form a hierarchy) -- the STRUCTURAL carrier
 * "what must not regress" asks for, with the native `<table>`/`<th
 * scope>`/`<caption>` machinery underneath it unchanged, so H1 validity holds
 * exactly as it does for the other two tables.
 */
function tblRenderFilesTree(view) {
	const container = view.filesRegion;
	if (!container) return;
	clear(container);
	if (!view.filesTree) return;

	const graphModel = view.graphModel;
	const viewModel = view.store.getViewModel();
	const kbUnbackedSet = new Set(viewModel.coverageGaps.kbUnbacked);
	const artifactGapSet = new Set(viewModel.coverageGaps.artifactUndocumented);
	const provenance = tblProvenanceIndex(graphModel);
	const rows = tblFlattenTree(view.filesTree);
	const fileRows = rows.filter((r) => r.entry.type === 'file');
	const hidden = tblHiddenSet(view);
	const hiddenCount = fileRows.filter((r) => hidden.has(r.entry.node.id)).length;

	const table = el('table', { class: 'tbl', 'data-files-table': true, role: 'treegrid', 'aria-label': 'Project files' });
	table.appendChild(el('caption', {}, [
		tblPlural(fileRows.length, 'file, document or image', 'files, documents and images') + ', with sections and facts '
		+ 'nested under their document, in a collapsible folder tree. '
		+ (hiddenCount > 0 ? hiddenCount + ' hidden from this view and from the graph by the Show checkbox. ' : '')
		+ 'Unchecking a row never changes relationships.md or the coverage counts.',
	]));
	table.appendChild(tblNodeTableHead());

	const body = el('tbody', {});
	for (const row of rows) {
		const entry = row.entry;
		const isFolder = entry.type === 'folder';
		const label = isFolder ? entry.name : (viewModel.nodeLabels.get(entry.node.id) || entry.node.name);
		const shortLabel = isFolder ? entry.name : (viewModel.nodeShortLabels.get(entry.node.id) || label);
		const rowHidden = row.ancestorKeys.some((key) => view.collapsedKeys.has(key));

		const tr = el('tr', { 'data-tree-key': entry.key, 'aria-level': String(row.depth) });
		if (rowHidden) tr.hidden = true;
		if (entry.children.length > 0) tr.setAttribute('aria-expanded', view.collapsedKeys.has(entry.key) ? 'false' : 'true');

		tr.appendChild(el('td', {}, [tblShowCheckbox(view, entry, label)]));
		tr.appendChild(el('th', { scope: 'row' }, tblTreeNameCell(view, row, label, shortLabel)));
		if (isFolder) {
			tr.appendChild(el('td', { text: '—' }));
			tr.appendChild(el('td', { text: '—' }));
			tr.appendChild(el('td', { text: '—' }));
			tr.appendChild(el('td', { text: '—' }));
		} else {
			const coverageClass = tblStaticCoverageClass(kbUnbackedSet, artifactGapSet, entry.node.id);
			tr.appendChild(el('td', {}, tblTreeIdCell(entry.node, coverageClass)));
			tr.appendChild(el('td', {}, tblKindCell(tblKindOf(entry.node))));
			tr.appendChild(el('td', { text: tblProvenanceText(provenance, entry.node.id) }));
			tr.appendChild(el('td', { text: coverageClass ? TBL_NODE_BADGES[coverageClass].text : 'ok' }));
		}
		body.appendChild(tr);
	}
	table.appendChild(body);
	container.appendChild(el('div', { class: 'tbl-wrap' }, [table]));
}

/** The Concepts table: a FLAT list of every `concept` node -- 32 today -- with
 *  the same six columns and the same checkbox the Files tree carries (Scope
 *  A2), no tree and no windowing: a concept has no path to sort into a folder
 *  and no document to nest under (§ 13's own header explains why). */
function tblRenderConcepts(view) {
	const container = view.conceptsRegion;
	if (!container) return;
	clear(container);

	const graphModel = view.graphModel;
	const viewModel = view.store.getViewModel();
	const kbUnbackedSet = new Set(viewModel.coverageGaps.kbUnbacked);
	const artifactGapSet = new Set(viewModel.coverageGaps.artifactUndocumented);
	const provenance = tblProvenanceIndex(graphModel);

	const concepts = Array.from(graphModel.nodes.values()).filter((n) => n.kind === 'concept').sort((a, b) => compareStrings(a.id, b.id));
	const hidden = tblHiddenSet(view);
	const hiddenCount = concepts.filter((n) => hidden.has(n.id)).length;

	const table = el('table', { class: 'tbl', 'data-concepts-table': true });
	table.appendChild(el('caption', {}, [
		tblPlural(concepts.length, 'concept', 'concepts') + ' defined in the Knowledge Base, flat: a concept has no '
		+ 'path and no single document to nest under. '
		+ (hiddenCount > 0 ? hiddenCount + ' hidden from this view and from the graph by the Show checkbox. ' : '')
		+ 'Unchecking a row never changes relationships.md or the coverage counts.',
	]));
	table.appendChild(tblNodeTableHead());

	const body = el('tbody', {});
	for (const node of concepts) {
		const label = viewModel.nodeLabels.get(node.id) || node.name;
		const shortLabel = viewModel.nodeShortLabels.get(node.id) || label;
		const entry = { type: 'file', key: node.id, node: node, children: [] };
		const coverageClass = tblStaticCoverageClass(kbUnbackedSet, artifactGapSet, node.id);

		const tr = el('tr', { 'data-tree-key': node.id });
		tr.appendChild(el('td', {}, [tblShowCheckbox(view, entry, label)]));
		tr.appendChild(el('th', { scope: 'row' }, tblTreeNameText(label, shortLabel, view.narrow)));
		tr.appendChild(el('td', {}, tblTreeIdCell(node, coverageClass)));
		tr.appendChild(el('td', {}, tblKindCell(tblKindOf(node))));
		tr.appendChild(el('td', { text: tblProvenanceText(provenance, node.id) }));
		tr.appendChild(el('td', { text: coverageClass ? TBL_NODE_BADGES[coverageClass].text : 'ok' }));
		body.appendChild(tr);
	}
	table.appendChild(body);
	container.appendChild(el('div', { class: 'tbl-wrap' }, [table]));
}

/**
 * Restore the reader's stored checkbox-hide selection, once, before the first
 * render (Scope C). Uses `resolveHiddenSelection`/`readHiddenSelection`
 * (graph-model.js §13; module scope, concatenated before this file) rather
 * than re-deriving either rule here -- see that file's own header for why the
 * key algorithm and the read/write pair live there and not per page.
 */
function tblRestoreHiddenSelection(view) {
	const stored = readHiddenSelection();
	const resolved = resolveHiddenSelection(view.graphModel, stored);
	if (resolved.hiddenIds.length > 0) view.store.setLens({ 'filters.hiddenIds': resolved.hiddenIds });
	if (resolved.suppressed) {
		tblReportSelectionNotice(view,
			'Your saved view selection could not be restored because it would have hidden every file, concept and '
			+ 'relationship. Nothing was hidden -- check the boxes you want hidden again.');
	} else if (resolved.dropped.length > 0) {
		tblReportSelectionNotice(view,
			tblPlural(resolved.dropped.length, 'item', 'items') + ' from your saved view selection no longer exist '
			+ 'and were dropped; the rest of the selection was restored.');
	}
}

/** A persistent, non-live notice about the restore -- the shell's own
 *  `[data-conflicts]` callout host, the SAME element `reportConflicts`
 *  (graph-controls.js) writes into, so this is one more producer of an
 *  EXISTING channel rather than a new live region (the page already has
 *  exactly two, and this file creates neither -- see TV05a). */
function tblReportSelectionNotice(view, message) {
	const host = view.root && typeof view.root.querySelector === 'function' ? view.root.querySelector('[data-conflicts]') : null;
	if (!host) return;
	host.appendChild(el('div', { class: 'callout warn', 'data-hidden-selection-notice': true }, [message]));
}


/* ==========================================================================
 * 14. What this file publishes
 *
 * In the page these are plain declarations in a shared module scope; the export
 * keyword makes the same file loadable by a test process with no change to a
 * byte of behaviour.
 * ========================================================================== */

export {
	mountTable,
	// The row set, the order and the comparator -- pure, so they are testable
	// with no page.
	tblRowRecords,
	tblUnlistedNodes,
	tblCompareRows,
	tblNextSort,
	tblAriaSort,
	tblSortOf,
	tblTokenClass,
	tblFocusMarked,
	// The window's own pure sentence-builder (task-033) -- pure, so it is
	// testable with no page and no store.
	tblWindowSummary,
	// The column contract and the two badge maps.
	TBL_COLUMNS,
	TBL_SORT_COLUMNS,
	TBL_FILE_ORDER,
	TBL_NODE_BADGES,
	TBL_EDGE_BADGES,
	TBL_END_ID,
	TBL_UNLISTED_ID,
	TBL_MOBILE_MAX_PX,
	TBL_TOP_BAR_PX,
	// The Files tree and the Concepts table (task-034) -- pure builders/helpers
	// first, so they are testable with no page, then the two renderers and the
	// restore entry point.
	TBL_EXTERNAL_BUCKET_NAME,
	tblIsExternalFile,
	tblRepoPath,
	tblBuildFilesTree,
	tblSubtreeIds,
	tblFlattenTree,
	tblHiddenSet,
	tblCommitHidden,
	tblToggleHidden,
	tblProvenanceIndex,
	tblProvenanceText,
	tblStaticCoverageClass,
	tblKindOf,
	tblRenderFilesTree,
	tblRenderConcepts,
	tblRestoreHiddenSelection,
};
