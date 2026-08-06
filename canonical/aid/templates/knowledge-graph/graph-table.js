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
 * ========================================================================== */


/* ==========================================================================
 * 1. The ten columns, and the value space of `sort`
 *
 * The rendered table has exactly the ten columns the relationship file has, in
 * the file's own order. Ten is a CONTRACT COUNT: the number is normative and
 * changing it is a breaking change by design, which is why the column count
 * below is read from this array rather than written as a literal anywhere.
 *
 * Each descriptor carries its own sort key and its own cell builder, so the
 * header row, the comparator and the body cells are driven by ONE array. A
 * column cannot be sortable without being renderable, and a column cannot
 * render a value the comparator does not see -- which is the property that
 * keeps a narrow viewport's shortened Name text out of the sort key.
 * ========================================================================== */

/** The literal `sort.column` value standing for the file's own row order. */
const TBL_FILE_ORDER = 'row';

const TBL_COLUMNS = Object.freeze([
	Object.freeze({
		token: 'source-id', label: 'Source Id', rowHeader: true,
		value: (record) => record.source.id,
		cell: (record) => tblIdCell(record.source),
	}),
	Object.freeze({
		token: 'source-kind', label: 'Source Kind',
		value: (record) => record.source.kind,
		cell: (record) => tblKindCell(record.source),
	}),
	Object.freeze({
		token: 'source-name', label: 'Source Name',
		value: (record) => record.source.label,
		cell: (record, view) => tblNameCell(record.source, view),
	}),
	Object.freeze({
		token: 'target-id', label: 'Target Id',
		value: (record) => record.target.id,
		cell: (record) => tblIdCell(record.target),
	}),
	Object.freeze({
		token: 'target-kind', label: 'Target Kind',
		value: (record) => record.target.kind,
		cell: (record) => tblKindCell(record.target),
	}),
	Object.freeze({
		token: 'target-name', label: 'Target Name',
		value: (record) => record.target.label,
		cell: (record, view) => tblNameCell(record.target, view),
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
 * @param {{store: object, graphModel: object, region: Element, surface: Element, root: (Document|Element)}} context
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

	const view = {
		store: context.store,
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
	};

	// The first element in the region, so one keystroke leaves the whole of it.
	// Deliberately NOT the shell's own `skip-link` element, which the page
	// structure check asserts and the shell owns.
	region.insertBefore(tblSkipLink(), region.firstChild);
	region.appendChild(view.host);

	tblWatchWidth(view);
	tblRender(view);
	context.store.subscribe((viewModel, lens) => { tblRender(view, viewModel, lens); });
	return view;
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
}

/** The listed table: caption, ten sortable headers, one row per ordered row. */
function tblRenderListed(view, viewModel, order, sort, unlistedCount) {
	const table = el('table', { class: 'tbl', 'data-relationship-table': true });
	table.appendChild(tblCaption(viewModel, unlistedCount));

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
		for (const record of order) body.appendChild(tblBodyRow(view, record, offset));
	}
	table.appendChild(body);
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

/** The Id cell: the identifier verbatim -- prefix included, which is how the
 *  cell text answers where the node comes from -- plus that endpoint's emphasis
 *  badge. The prefix is READ BY NOBODY here; it is present because it is part
 *  of the identifier the file carries. */
function tblIdCell(endpoint) {
	return [
		el('code', { class: TBL_EMPHASIS_CLASSES[endpoint.emphasis] || null, text: endpoint.id }),
		tblNodeBadge(endpoint.emphasis),
	];
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
 * The Name cell: the accessible name, and the row's select control.
 *
 * Content here is unbounded in length by construction -- a claim's display name
 * reproduces a knowledge-base anchor string verbatim -- so below the mobile
 * breakpoint the cell shows the projection's short label as its only VISIBLE
 * text and carries the full name beside it for the accessibility tree. The
 * shortened form therefore sits only inside `aria-hidden`, reaches no
 * accessibility tree, and appears nowhere above the breakpoint; the cell's
 * accessible name CONTAINS the full name rather than equalling it, because a
 * cell names itself from its contents and this cell also holds its button.
 */
function tblNameCell(endpoint, view) {
	const children = [];
	if (view.narrow) {
		children.push(el('span', { 'aria-hidden': 'true', text: endpoint.shortLabel }));
		children.push(el('span', { class: 'sr-only', text: endpoint.label }));
	} else {
		children.push(endpoint.label);
	}
	// A separating space, so the name and the control do not read as one word in
	// a text extraction of the cell.
	children.push(' ');
	children.push(tblSelectButton(view, endpoint));
	return children;
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

function tblCaption(viewModel, unlistedCount) {
	const children = [
		el('span', {
			text: tblPlural(viewModel.counts.edges, 'relationship', 'relationships') + ' listed, '
				+ viewModel.counts.hiddenEdges + ' hidden. ',
		}),
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

/** The sticky header's offset: the top bar's height, so the header pins below
 *  the bar rather than under it. */
function tblStickyTop(cell) {
	if (!cell.style) return;
	cell.style.top = TBL_TOP_BAR_PX + 'px';
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
	const push = () => { view.narrow = !!query.matches; tblRender(view); };
	if (typeof query.addEventListener === 'function') query.addEventListener('change', push);
	else if (typeof query.addListener === 'function') query.addListener(push);
}


/* ==========================================================================
 * 12. What this file publishes
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
};
