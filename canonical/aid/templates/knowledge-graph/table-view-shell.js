/* ============================================================================
 * table-view-shell.js -- the table-only page's own, lean shell (task-033).
 *
 * WHY THIS FILE EXISTS RATHER THAN REUSING `mountShell`
 *   graph-controls.js's `mountShell` is the graph page's whole flow: it builds
 *   the lens-bar presets, the grouping/density/focus controls, the seven
 *   viewport actions, the legend, the group disclosures and the coverage panel
 *   -- every one of which is either about the DRAWING surface or a graph-only
 *   concept this page has no drawing surface for. Calling it here would put
 *   viewport buttons that write nothing and a legend for shapes this page never
 *   draws onto a page whose entire brief, in the owner's own words, is "with no
 *   graph .. without overloading .. with excessive data". So this file is a
 *   SEPARATE, PURPOSE-BUILT `bootTableView`/`tbvMountShell` pair -- not a copy
 *   of `mountShell`'s body with parts deleted, and not a second definition of
 *   anything `mountShell` already defines.
 *
 * WHAT IS REUSED, UNEDITED, FROM THE FILES CONCATENATED BEFORE THIS ONE
 *   graph-model.js    -- parseRelationships, createStore, INITIAL_LENS.
 *   graph-controls.js -- buildControlManifest (the SAME manifest the graph
 *                        page's controls are generated from -- this file reads
 *                        three of its axes and ignores the rest, rather than
 *                        authoring a second manifest), filterAxis (the SAME
 *                        function that builds each checkbox fieldset on the
 *                        graph page), el/clear/byId, CONTROL_ATTR, toggleValue,
 *                        detectPreferences/watchPreferences, raise,
 *                        reportConflicts, reportIntegrity.
 *   graph-table.js    -- mountTable, called directly with this page's own
 *                        `pageSize` and `announceWindow` (task-033's windowing
 *                        opt-in; see that file's own header), plus this page's
 *                        `filesRegion`/`conceptsRegion` mount points
 *                        (task-034) -- graph-table.js builds and wires the
 *                        Files tree and the Concepts table itself; this file
 *                        only points it at the two `<div>`s the skeleton
 *                        declares.
 *   Nothing above is redeclared here. This file's own top-level names are all
 *   prefixed `TBV_`/`tbv`, per the single-module-scope rule every view file in
 *   this page's one inline module block already follows.
 *
 * WHAT THIS PAGE DELIBERATELY DOES NOT BUILD, AND WHY THAT IS NOT A HOLE
 *   Grouping, density, the focus/select/open controls, the seven viewport
 *   actions, the four preset lenses, the legend and the coverage panel. Every
 *   one of those is either a property of the DRAWING rendering (which this
 *   page never mounts) or a control over it (grouping/density/focus existing
 *   to shape what the graph draws). A table with every row rendered -- windowed
 *   rather than density-thinned -- has no use for any of them, and the owner's
 *   own brief for this page is a page that stays lean, not a second copy of the
 *   graph page's whole control surface.
 * ========================================================================== */


/** This page's own page size (task-033's own illustrative figures: "extending
 *  the table by 200 rows", "cannot reach row 201"). A page-size contract, not a
 *  measurement -- adjustable without changing anything this file's callers
 *  depend on. */
const TBV_PAGE_SIZE = 200;

/** Published exactly like graph-controls.js's own `window.aidGraphView` --
 *  same rationale (an assertion needs a read-and-attach surface with no second
 *  way to drive the view), a DIFFERENT name because this is a different page
 *  with no viewport handle and no drawing model to publish. */
function tbvPublishHandle(value) {
	if (typeof window === 'undefined') return;
	window.aidTableView = value;
}

/**
 * Decode the embedded payload -- the SAME element, the SAME encoding and the
 * SAME error handling `mountShell` uses for its own copy of this element, but
 * not a call INTO that function: `mountShell` also builds the graph page's
 * whole control surface as its very next steps, which this page must not run.
 * Kept small and inline instead of factored into graph-controls.js, which is a
 * concurrent task's file this task does not edit.
 */
function tbvDecodePayload(root) {
	const payload = root.querySelector('#graph-relationships');
	const encoded = (payload ? payload.textContent : '').replace(/\s+/g, '');
	if (encoded === '') return '';
	return new TextDecoder().decode(Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0)));
}

/** The window's own live-region sink, passed to `mountTable` as
 *  `context.announceWindow`. graph-table.js creates no live-region element of
 *  its own (see its header) -- this is the caller-owned region it writes into,
 *  on THIS page the one polite region the skeleton declares. */
function tbvAnnounceWindow(root) {
	return (text) => {
		const region = root.querySelector('[data-status]');
		if (region) region.textContent = text;
	};
}

/**
 * The filter panel: the text search, the orphan toggle, and the three
 * checkbox fieldsets -- reusing `filterAxis` (unedited) for the three, so the
 * DOM those three axes build here is generated by the identical function the
 * graph page's own controls use, over the identical manifest entries.
 *
 * @param {object} ctx {root, store, graphModel, manifest}
 */
function tbvMountFilters(ctx) {
	const grid = ctx.root.querySelector('[data-controls-grid]');
	clear(grid);

	// The text search -- the one design-choice axis (AUTHORED_CONTROLS' own
	// entry), reused for the SAME reason the graph page carries it: the fastest
	// route to a known row is to type a name or an identifier.
	const textInput = el('input', { type: 'search', id: 'filter-text', [CONTROL_ATTR]: 'filter-text', placeholder: 'name or identifier' });
	textInput.addEventListener('input', () => { ctx.store.setLens({ 'filters.text': textInput.value }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('label', { for: 'filter-text', text: 'Find by name' }),
		textInput,
	]));

	// The orphan toggle -- default on, same default and same reasoning as the
	// graph page's copy: an isolated node is what the coverage lens and the gap
	// ledger exist to surface, so hiding one has to be a deliberate act.
	const orphanBox = el('input', { type: 'checkbox', id: 'filter-show-orphans', [CONTROL_ATTR]: 'filter-show-orphans' });
	orphanBox.addEventListener('change', () => { ctx.store.setLens({ 'filters.showOrphans': orphanBox.checked }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('span', { class: 'control-group-label', text: 'Isolated nodes' }),
		el('label', { class: 'toggle-row', for: 'filter-show-orphans' }, [orphanBox, 'Show nodes with no recorded relationship']),
	]));

	// The three enumerable filter axes -- `filterAxis` itself, called exactly
	// the way graph-controls.js's own `mountControls` calls it, over the SAME
	// manifest and the SAME describe callbacks.
	grid.appendChild(filterAxis(ctx.store, ctx.manifest, 'filters.categories', 'Relationship category', (value) => {
		const encoding = CATEGORY_ENCODING[value];
		return [
			el('span', { class: 'filter-swatch ls-' + encoding.lineStyle + ' c-' + slug(value), 'aria-hidden': 'true' }),
			value + ' (' + encoding.lineStyle + ')',
		];
	}));
	grid.appendChild(filterAxis(ctx.store, ctx.manifest, 'filters.kinds', 'Node kind', (value) => [
		el('span', { class: 'filter-glyph k-' + slug(value), 'aria-hidden': 'true', text: KIND_ENCODING[value].glyph }),
		value + ' (' + KIND_ENCODING[value].shapeLabel + ')',
	]));
	grid.appendChild(filterAxis(ctx.store, ctx.manifest, 'filters.provenance', 'Provenance', (value) => [value]));

	return {
		refresh(lens) {
			if (textInput.value !== lens['filters.text']) textInput.value = lens['filters.text'];
			orphanBox.checked = lens['filters.showOrphans'] !== false;
			for (const axis of ['filters.categories', 'filters.kinds', 'filters.provenance']) {
				const admitted = new Set(lens[axis]);
				for (const entry of ctx.manifest) {
					if (entry.axis !== axis) continue;
					const box = byId(ctx.root, entry.id);
					if (box) box.checked = admitted.has(entry.value);
				}
			}
		},
	};
}

/**
 * The whole flow, client-side, no server and no request -- this page's own
 * version of `mountShell`'s step sequence, narrowed to what a table-only page
 * needs: decode, parse, create the store, build the filter panel, mount the
 * table first and unconditionally (there is no "composed without it" branch
 * on this page -- see the skeleton's own comment), and report integrity and
 * conflicts through the same two callouts the graph page uses.
 *
 * @param {Document|Element} [scope]
 * @returns {object|null} the store, or null when the page could not be loaded
 */
function tbvMountShell(scope) {
	const root = scope || document;

	let text = '';
	try {
		text = tbvDecodePayload(root);
	} catch (error) {
		raise(root, 'error', 'The embedded relationship file could not be decoded', [
			'The page carries its relationship file as an encoded payload, and decoding it failed, so there is '
			+ 'nothing to render. The page and its generator are out of step.',
			String(error && error.message ? error.message : error),
		]);
		tbvPublishHandle({ store: null, graphModel: null, manifest: null, error: error });
		return null;
	}

	let graphModel;
	try {
		graphModel = parseRelationships(text);
	} catch (error) {
		const detail = error && error.detail ? error.detail : null;
		const paragraphs = [String(error && error.message ? error.message : error)];
		if (detail && typeof detail.expected === 'string' && typeof detail.actual === 'string') {
			paragraphs.push('Expected: ' + detail.expected);
			paragraphs.push('Actual:   ' + detail.actual);
		}
		paragraphs.push('Nothing is rendered from a table whose shape cannot be trusted: a picture drawn from '
			+ 'mis-read columns would look correct and be wrong, which is the failure this view exists to prevent.');
		raise(root, 'error', 'The relationship table could not be read', paragraphs);
		console.error('table.html: relationship table load failed', error);
		tbvPublishHandle({ store: null, graphModel: null, manifest: null, error: error });
		return null;
	}

	const store = createStore(graphModel, INITIAL_LENS, detectPreferences());
	watchPreferences(store);

	const manifest = buildControlManifest(graphModel);
	tbvPublishHandle({ store: store, graphModel: graphModel, manifest: manifest, error: null });

	reportIntegrity(root, graphModel);
	reportConflicts(root, graphModel);

	const filters = tbvMountFilters({ root: root, store: store, graphModel: graphModel, manifest: manifest });

	// The table mounts first and unconditionally -- there is no OTHER rendering
	// on this page for it to be "first" against, but the mount point is present
	// unconditionally exactly as feature-007's D2/step-6 requires of the graph
	// page's own table half, and the windowing opt-in is this page's own reason
	// to exist (task-033's DETAIL.md, Scope B). `filesRegion`/`conceptsRegion`
	// (task-034) are this page's own two additional, also-unconditional mount
	// points -- graph-table.js mounts each behind a null check exactly the way
	// it already mounts the Relations table, so a caller that omitted either
	// attribute would simply not get that table, with nothing here to notice.
	const region = root.querySelector('[data-table-region]');
	mountTable({
		store: store,
		graphModel: graphModel,
		region: region,
		filesRegion: root.querySelector('[data-files-region]'),
		conceptsRegion: root.querySelector('[data-concepts-region]'),
		surface: null,
		root: root,
		pageSize: TBV_PAGE_SIZE,
		announceWindow: tbvAnnounceWindow(root),
	});

	store.subscribe((viewModel, lens) => { filters.refresh(lens); });
	filters.refresh(store.getLens());

	return store;
}

/**
 * Schedule the shell. Deferred by one microtask, exactly like `bootGraphView`,
 * so every file concatenated after this one -- there are none, this file is
 * last in the manifest -- and every top-level registration this bundle makes
 * (graph-table.js's own `registerRendering('table', mountTable)`) has already
 * run by the time this looks for anything.
 */
function bootTableView() {
	if (typeof document === 'undefined') return;
	queueMicrotask(() => { tbvMountShell(document); });
}

export {
	TBV_PAGE_SIZE,
	tbvMountShell,
	bootTableView,
};
