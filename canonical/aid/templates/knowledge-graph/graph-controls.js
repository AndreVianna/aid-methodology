/* ============================================================================
 * graph-controls.js -- the shell: the control manifest, the control DOM, the two
 * live regions, the system-preference detection, and the two mount points the
 * drawing rendering and the table rendering attach to.
 *
 * Concatenated after graph-model.js in the page's single inline module block, so
 * it declares no loading statement and reaches that file's declarations by plain
 * reference.
 *
 * WHY THE CONTROLS ARE BUILT FROM A MANIFEST RATHER THAN WRITTEN IN THE MARKUP
 *   The criterion the control surface answers to is not "can a keyboard reach the
 *   controls that exist" -- it is "is the full set of controls the requirements
 *   name actually present". Those are different questions, and only the second
 *   one catches the failure the criterion exists for: a control PAINTED ON THE
 *   DRAWING SURFACE is simply absent from the set a keyboard drive walks, so it
 *   passes the first question while failing the standard outright.
 *
 *   So the control DOM is generated from one array. A control cannot exist
 *   without an entry and an entry cannot exist without a control, and the
 *   enumerable axes' entries are DERIVED FROM THE DATA THE MODEL ALREADY HOLDS
 *   rather than re-typed beside it -- which is the load-bearing direction, because
 *   a bijection against the manifest is only as good as the manifest. Add a
 *   category to the vocabulary and the filter offers it with no edit here.
 *
 * WHAT IS DELIBERATELY NOT IN THE MANIFEST, AND WHY THAT IS NOT A HOLE
 *   A group's expand/collapse disclosure. The manifest is built once at load from
 *   the model, while which groups exist changes with every lens and every filter,
 *   so an entry per group would make the bijection false the moment a filter
 *   removed a group. The disclosure therefore carries its own attribute, and its
 *   completeness is asserted in the other direction instead: one focusable
 *   disclosure per group the fold governs, and none for any other group. It is a
 *   real button, so the keyboard obligation is met by construction.
 * ========================================================================== */


/* ==========================================================================
 * 1. The control manifest
 * ========================================================================== */

/** Attribute the bijection is asserted over. */
const CONTROL_ATTR = 'data-control';

/** Attribute the per-projection group disclosure carries INSTEAD, so it stays
 *  outside that bijection. */
const GROUP_TOGGLE_ATTR = 'data-group-toggle';

/**
 * The seven viewport actions. Their keyboard equivalents are required, and their
 * VALUES are not this file's to know: a zoom step factor and the extent a "fit"
 * has to cover are layout state private to the drawing rendering. So each entry's
 * handler asks that rendering for the resulting transform and writes what comes
 * back. With no drawing rendering present the entries stay present, focusable and
 * never disabled, and write nothing -- there is nothing drawn to transform.
 */
const VIEWPORT_ACTIONS = Object.freeze(['zoom-in', 'zoom-out', 'zoom-fit', 'pan-left', 'pan-right', 'pan-up', 'pan-down']);

const VIEWPORT_LABELS = Object.freeze({
	'zoom-in': 'Zoom in',
	'zoom-out': 'Zoom out',
	'zoom-fit': 'Fit graph to view',
	'pan-left': 'Pan left',
	'pan-right': 'Pan right',
	'pan-up': 'Pan up',
	'pan-down': 'Pan down',
});

/**
 * The controls no data set enumerates. They are AUTHORED, and each carries the
 * clause that requires it -- or, for exactly one of them, the literal
 * `design-choice` with its reason in the entry.
 *
 * The text search is that one. No requirement asks for it: the requirement names
 * three filter axes plus the orphan toggle, and this is a fourth, added because
 * the fastest way to reach a known node in a graph of this size is to type its
 * name. It is labelled the way every other design choice here is labelled rather
 * than given a citation it does not have -- an invented citation would be the one
 * failure mode this whole arrangement exists to prevent. It is not enumerable, so
 * the coverage assertion is unaffected, and the bijection and the keyboard drive
 * bind it exactly like a required control.
 */
const AUTHORED_CONTROLS = Object.freeze([
	Object.freeze({ id: 'grouping', requirement: 'FR-14a', axis: 'grouping', value: null }),
	Object.freeze({ id: 'density', requirement: 'FR-14a', axis: 'density', value: null }),
	Object.freeze({ id: 'focus-node', requirement: 'FR-14a', axis: 'focus', value: null }),
	Object.freeze({ id: 'focus-depth', requirement: 'FR-14a', axis: 'depth', value: null }),
	Object.freeze({ id: 'filter-show-orphans', requirement: 'FR-14a', axis: 'orphan-toggle', value: null }),
	Object.freeze({ id: 'node-select', requirement: 'FR-14a', axis: 'select', value: null }),
	Object.freeze({ id: 'node-open', requirement: 'FR-14a', axis: 'open', value: null }),
	Object.freeze({
		id: 'filter-text',
		requirement: 'design-choice',
		axis: 'filters.text',
		value: null,
		rationale: 'No requirement asks for a text filter. It is added because the fastest route to a '
			+ 'known node in a graph of this size is to type its name, and it is labelled a design '
			+ 'choice rather than given a citation it does not have.',
	}),
].concat(VIEWPORT_ACTIONS.map((action) => Object.freeze({
	id: action, requirement: 'NFR-6', axis: 'viewport', value: action,
}))));

/** A value turned into an attribute-safe token. Values are category names, kind
 *  names and provenance names -- all lowercase words and hyphens -- so this is a
 *  guard rather than a transformation anything relies on. */
function slug(value) {
	return String(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

/**
 * Build the control manifest for a model.
 *
 * The published contract names this array; because it must be derived from the
 * model rather than authored as a literal, the authored name is this builder and
 * the built array is what the shell holds and what a test asserts over.
 *
 * @param {object} graphModel
 * @returns {ReadonlyArray<{id: string, requirement: string, axis: string, value: (string|null)}>}
 */
function buildControlManifest(graphModel) {
	const entries = [];

	// The lens buttons, from the preset table's own keys.
	for (const preset of Object.keys(PRESETS)) {
		entries.push(Object.freeze({ id: 'lens-' + slug(preset), requirement: 'FR-13', axis: 'preset', value: preset }));
	}

	// Axis 1: relationship category, from the loaded vocabulary. Not a literal
	// list here -- a fifteenth category reaches this axis on its own.
	for (const category of graphModel.categories) {
		entries.push(Object.freeze({ id: 'filter-category-' + slug(category), requirement: 'FR-6a', axis: 'filters.categories', value: category }));
	}

	// Axis 2: node kind, from the closed kind enum.
	for (const kind of Object.keys(KIND_ENCODING)) {
		entries.push(Object.freeze({ id: 'filter-kind-' + slug(kind), requirement: 'FR-14a', axis: 'filters.kinds', value: kind }));
	}

	// Axis 3: provenance, from the closed provenance enum.
	for (const provenance of PROVENANCE_VALUES) {
		entries.push(Object.freeze({ id: 'filter-provenance-' + slug(provenance), requirement: 'FR-14a', axis: 'filters.provenance', value: provenance }));
	}

	for (const authored of AUTHORED_CONTROLS) entries.push(authored);

	return Object.freeze(entries);
}


/* ==========================================================================
 * 2. Registration -- how the two renderings attach
 * ========================================================================== */

const registrations = new Map();

/**
 * Register a rendering. Called at the TOP LEVEL of the rendering's own file, so
 * it has run by the time the shell boots.
 *
 * @param {('table'|'canvas')} name
 * @param {function(object): (object|undefined)} mount receives the mount context
 *        and may return a handle. For the drawing rendering that handle is the
 *        viewport handle described at `mountShell`.
 */
function registerRendering(name, mount) {
	if (typeof mount === 'function') registrations.set(name, mount);
}

/**
 * The mount function for a rendering, whether it registered itself or only
 * declared the name the layout fixes for it.
 *
 * Both routes are accepted because a silent non-mount is the worst outcome
 * available here: a rendering that is present in the build but never called
 * leaves the reader a blank region with no explanation. The probe runs after
 * every file's top-level body has finished, so a declaration of any shape is
 * already initialised and the probe cannot trip over one.
 */
function resolveMount(name, declared) {
	if (registrations.has(name)) return registrations.get(name);
	return typeof declared === 'function' ? declared : null;
}


/* ==========================================================================
 * 3. Small DOM helpers
 * ========================================================================== */

function el(tag, attrs, children) {
	const node = document.createElement(tag);
	if (attrs) {
		for (const key of Object.keys(attrs)) {
			const value = attrs[key];
			if (value === null || value === undefined || value === false) continue;
			if (key === 'text') { node.textContent = String(value); continue; }
			node.setAttribute(key, value === true ? '' : String(value));
		}
	}
	for (const child of (children || [])) {
		if (child === null || child === undefined) continue;
		node.appendChild(typeof child === 'string' ? document.createTextNode(child) : child);
	}
	return node;
}

function clear(node) {
	while (node.firstChild) node.removeChild(node.firstChild);
}

function byId(root, id) {
	return root.querySelector('#' + id);
}

/** Toggle one value in an array-valued filter axis. */
function toggleValue(list, value, on) {
	const set = new Set(list);
	if (on) set.add(value); else set.delete(value);
	return Array.from(set);
}


/* ==========================================================================
 * 4. Building the control DOM
 * ========================================================================== */

/**
 * @param {object} ctx {root, store, graphModel, manifest}
 * @returns {{refresh: function(object, object): void}}
 */
function mountControls(ctx) {
	const root = ctx.root;
	const store = ctx.store;
	const model = ctx.graphModel;

	// --- The lens bar -------------------------------------------------------
	const lensBar = root.querySelector('[data-lens-bar]');
	clear(lensBar);
	lensBar.appendChild(el('span', { class: 'lens-bar-label', text: 'Preset lenses' }));
	for (const entry of ctx.manifest.filter((e) => e.axis === 'preset')) {
		const button = el('button', {
			type: 'button',
			class: 'lens-btn',
			id: entry.id,
			'aria-pressed': 'false',
			[CONTROL_ATTR]: entry.id,
			text: PRESET_LABELS[entry.value],
		});
		// Never disabled. A preset is an entry point and not a mode, so arriving
		// through one takes nothing away -- including the ability to press
		// another one.
		button.addEventListener('click', () => { store.applyPreset(entry.value); });
		lensBar.appendChild(button);
	}

	// --- The control panel --------------------------------------------------
	const grid = root.querySelector('[data-controls-grid]');
	clear(grid);

	// Grouping. The relationship-category option is here as a real option
	// alongside the other four values, because category is a grouping dimension
	// and not only a filter axis.
	const groupingSelect = el('select', { id: 'grouping', [CONTROL_ATTR]: 'grouping' },
		GROUPING_VALUES.map((value) => el('option', { value: value, text: groupingLabel(value) })));
	groupingSelect.addEventListener('change', () => { store.setLens({ 'grouping': groupingSelect.value }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('label', { for: 'grouping', text: 'Group by' }),
		groupingSelect,
		el('span', { class: 'control-hint', text: 'Only the document dimension folds sections and facts away.' }),
	]));

	// Density. This is VIEW density -- how much is drawn -- and it is not an
	// exposure of the simulation's physics. Repulsion, link distance and centre
	// force are internal constants of the drawing rendering, and there is no
	// state a slider for one of them could write to.
	const densityRange = el('input', {
		type: 'range', min: '1', max: '5', step: '1', id: 'density', [CONTROL_ATTR]: 'density',
		'aria-describedby': 'density-hint',
	});
	densityRange.addEventListener('input', () => { store.setLens({ 'density': parseInt(densityRange.value, 10) }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('label', { for: 'density', text: 'View density' }),
		densityRange,
		el('span', { class: 'control-hint', id: 'density-hint', text: 'Level 1 draws everything. Levels 2 to 5 hide nodes with fewer connections.' }),
	]));

	// The text search. The one design-choice control.
	const textInput = el('input', { type: 'search', id: 'filter-text', [CONTROL_ATTR]: 'filter-text', placeholder: 'name or identifier' });
	textInput.addEventListener('input', () => { store.setLens({ 'filters.text': textInput.value }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('label', { for: 'filter-text', text: 'Find by name' }),
		textInput,
	]));

	// The focus node and its depth, plus the two node gestures. Selecting and
	// opening are separate, so exploring never navigates out of the view by
	// accident, and the open control is a real button because a double click has
	// no keyboard equivalent.
	const focusSelect = el('select', { id: 'focus-node', [CONTROL_ATTR]: 'focus-node' });
	focusSelect.addEventListener('change', () => { store.setLens({ 'focus.nodeId': focusSelect.value || null }); });
	const depthInput = el('input', { type: 'number', min: '1', max: '6', step: '1', id: 'focus-depth', [CONTROL_ATTR]: 'focus-depth' });
	depthInput.addEventListener('change', () => { store.setLens({ 'focus.depth': parseInt(depthInput.value, 10) }); });
	const selectButton = el('button', { type: 'button', class: 'btn-ghost', id: 'node-select', [CONTROL_ATTR]: 'node-select', text: 'Select node' });
	selectButton.addEventListener('click', () => { store.setLens({ 'focus.nodeId': focusSelect.value || null }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('label', { for: 'focus-node', text: 'Selected node' }),
		focusSelect,
		el('label', { for: 'focus-depth', text: 'Neighbourhood depth' }),
		depthInput,
		selectButton,
	]));

	// The orphan toggle. Default on, and the default is the reasoning: an
	// isolated node is precisely what the coverage lens and the gap ledger exist
	// to surface, so hiding one has to be a deliberate act.
	const orphanBox = el('input', { type: 'checkbox', id: 'filter-show-orphans', [CONTROL_ATTR]: 'filter-show-orphans' });
	orphanBox.addEventListener('change', () => { store.setLens({ 'filters.showOrphans': orphanBox.checked }); });
	grid.appendChild(el('div', { class: 'control-group' }, [
		el('span', { class: 'control-group-label', text: 'Isolated nodes' }),
		el('label', { class: 'toggle-row', for: 'filter-show-orphans' }, [orphanBox, 'Show nodes with no recorded relationship']),
	]));

	// The three filter axes. Each is a real fieldset with a real legend, and each
	// value is a real checkbox with a real label, generated from the manifest.
	grid.appendChild(filterAxis(store, ctx.manifest, 'filters.categories', 'Relationship category', (value) => {
		const encoding = CATEGORY_ENCODING[value];
		return [
			el('span', { class: 'filter-swatch ls-' + encoding.lineStyle + ' c-' + slug(value), 'aria-hidden': 'true' }),
			value + ' (' + encoding.lineStyle + ')',
		];
	}));
	grid.appendChild(filterAxis(store, ctx.manifest, 'filters.kinds', 'Node kind', (value) => [
		el('span', { class: 'filter-glyph k-' + slug(value), 'aria-hidden': 'true', text: KIND_ENCODING[value].glyph }),
		value + ' (' + KIND_ENCODING[value].shapeLabel + ')',
	]));
	grid.appendChild(filterAxis(store, ctx.manifest, 'filters.provenance', 'Provenance', (value) => [value]));

	// --- The viewport controls ----------------------------------------------
	const viewportBar = root.querySelector('[data-viewport-bar]');
	clear(viewportBar);
	for (const entry of ctx.manifest.filter((e) => e.axis === 'viewport')) {
		const button = el('button', {
			type: 'button', class: 'btn-ghost', id: entry.id, [CONTROL_ATTR]: entry.id,
			text: VIEWPORT_LABELS[entry.value],
		});
		button.addEventListener('click', () => {
			// One writer on this path. The step factor and the extent belong to
			// the drawing rendering; the resulting transform is written here.
			const handle = shellState.viewport;
			if (!handle || typeof handle.viewportFor !== 'function') return;
			const next = handle.viewportFor(entry.value);
			if (next) store.setLens({ 'zoom': next });
		});
		viewportBar.appendChild(button);
	}

	// --- The open gesture ---------------------------------------------------
	const openButton = root.querySelector('#node-open');
	openButton.setAttribute(CONTROL_ATTR, 'node-open');
	openButton.addEventListener('click', () => {
		const id = store.getLens()['focus.nodeId'];
		if (!id) return;
		const target = store.openTarget(id);
		if (target) window.location.href = target;
	});

	/** Reconcile every control's displayed value against the lens, so a preset
	 *  button and a slider can never disagree about the current density. The
	 *  controls are uncontrolled inputs written into the store on change; this is
	 *  the other half of that arrangement. */
	function refresh(viewModel, lens) {
		for (const entry of ctx.manifest) {
			if (entry.axis !== 'preset') continue;
			const button = byId(root, entry.id);
			if (button) button.setAttribute('aria-pressed', lens['preset'] === entry.value ? 'true' : 'false');
		}
		groupingSelect.value = lens['grouping'];
		densityRange.value = String(lens['density']);
		if (textInput.value !== lens['filters.text']) textInput.value = lens['filters.text'];
		depthInput.value = String(lens['focus.depth']);
		orphanBox.checked = lens['filters.showOrphans'] !== false;

		for (const axis of ['filters.categories', 'filters.kinds', 'filters.provenance']) {
			const admitted = new Set(lens[axis]);
			for (const entry of ctx.manifest) {
				if (entry.axis !== axis) continue;
				const box = byId(root, entry.id);
				if (box) box.checked = admitted.has(entry.value);
			}
		}

		// The focus list offers every node in the model, ordered by name, so a
		// reader can select a node that the current filters have hidden and see
		// the view move to it. Rebuilt only when the node set it lists changes.
		if (focusSelect.options.length === 0) {
			const options = [el('option', { value: '', text: '(none)' })];
			for (const node of Array.from(model.nodes.values()).sort((a, b) => (a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)))) {
				options.push(el('option', { value: node.id, text: node.name + ' — ' + node.kind }));
			}
			for (const option of options) focusSelect.appendChild(option);
		}
		focusSelect.value = lens['focus.nodeId'] || '';

		renderNodeDetail(root, store, viewModel, lens);
	}

	return { refresh: refresh };
}

function groupingLabel(value) {
	if (value === 'none') return 'none (no grouping)';
	return value;
}

/** One filter axis as a fieldset, its values generated from the manifest. */
function filterAxis(store, manifest, axis, legend, describe) {
	const values = el('div', { class: 'filter-values' });
	for (const entry of manifest) {
		if (entry.axis !== axis) continue;
		const box = el('input', { type: 'checkbox', id: entry.id, [CONTROL_ATTR]: entry.id });
		box.addEventListener('change', () => {
			store.setLens({ [axis]: toggleValue(store.getLens()[axis], entry.value, box.checked) });
		});
		values.appendChild(el('label', { for: entry.id }, [box].concat(describe(entry.value))));
	}
	return el('fieldset', { class: 'filter-axis' }, [el('legend', { text: legend }), values]);
}


/* ==========================================================================
 * 5. The selected-node detail, and the group disclosures
 * ========================================================================== */

function renderNodeDetail(root, store, viewModel, lens) {
	const host = root.querySelector('[data-node-detail]');
	clear(host);
	const id = lens['focus.nodeId'];
	const model = store.getGraphModel();
	const node = id ? model.nodes.get(id) : null;
	if (!node) {
		// The Open control stays enabled with nothing selected -- no control is
		// ever disabled here -- and pressing it with no selection does nothing.
		host.appendChild(el('p', { class: 'control-hint', text: 'No node selected. Choose one in the controls above, or select one in either rendering.' }));
		return;
	}

	const target = store.openTarget(node.id);
	const emphasis = viewModel.nodeEmphasis.get(node.id) || 'not drawn';
	host.appendChild(el('dl', {}, [
		el('dt', { text: 'Name' }), el('dd', { text: viewModel.nodeLabels.get(node.id) || node.name }),
		el('dt', { text: 'Identifier' }), el('dd', {}, [el('code', { text: node.id })]),
		el('dt', { text: 'Kind' }), el('dd', {}, [
			el('span', { class: 'k-' + slug(node.kind), 'aria-hidden': 'true', text: node.glyph + ' ' }),
			node.kind + ' (' + KIND_ENCODING[node.kind].shapeLabel + ')',
		]),
		el('dt', { text: 'Recorded relationships' }), el('dd', { text: String(node.degree) }),
		el('dt', { text: 'Emphasis in this view' }), el('dd', { text: emphasis }),
		el('dt', { text: 'Opens' }), el('dd', {}, [el('code', { text: target || 'nothing resolvable' })]),
	]));
}

/**
 * The group list, and its disclosures.
 *
 * Presence is keyed on the count the fold GOVERNS, not on the count currently
 * folded away. That is the whole point: a count of what is hidden goes to zero
 * when a group is expanded, and a disclosure keyed on it would delete itself the
 * moment it was used, leaving no control able to collapse the group again.
 */
function renderGroups(root, store, viewModel) {
	const host = root.querySelector('[data-groups]');
	const region = root.querySelector('[data-groups-region]');
	if (!host) return;
	clear(host);
	const showable = viewModel.groups.length > 1 || viewModel.groups.some((g) => g.foldable > 0);
	if (region) region.hidden = !showable;
	if (!showable) return;

	for (const group of viewModel.groups) {
		const row = el('li', { class: 'group-row' });
		if (group.foldable > 0) {
			// The COUNT is the number of members the fold governs, and it does not
			// change when the group is expanded -- but the WORDING has to, or a
			// disclosure reading "2 folded away" would sit beside an aria-expanded
			// of true and describe the opposite of the state it is in.
			const members = group.foldable === 1 ? '1 member' : group.foldable + ' members';
			const toggle = el('button', {
				type: 'button',
				class: 'group-toggle',
				'aria-expanded': group.expanded ? 'true' : 'false',
				[GROUP_TOGGLE_ATTR]: group.key,
			}, [group.label + ' — ' + members + (group.expanded ? ' shown; activate to fold' : ' folded; activate to show')]);
			toggle.addEventListener('click', () => {
				const lens = store.getLens();
				const next = new Set(lens['expandedGroups']);
				if (next.has(group.key)) next.delete(group.key); else next.add(group.key);
				store.setLens({ 'expandedGroups': Array.from(next) });
			});
			row.appendChild(toggle);
		} else {
			row.appendChild(el('span', { text: group.label }));
		}
		row.appendChild(el('span', { class: 'group-count', text: group.nodeIds.length + ' drawn' }));
		host.appendChild(row);
	}
}


/* ==========================================================================
 * 6. The legend and the coverage panel
 * ========================================================================== */

/** Every glyph, every colour and every line style, IN WORDS. Colour is never the
 *  sole carrier of anything, so the legend has to say what each channel means
 *  rather than only show it. Written once at load. */
function renderLegend(root, graphModel) {
	const host = root.querySelector('[data-legend]');
	clear(host);

	const kinds = el('dl', {});
	kinds.appendChild(el('dt', { text: 'Node kind — colour and shape' }));
	for (const kind of Object.keys(KIND_ENCODING)) {
		const encoding = KIND_ENCODING[kind];
		kinds.appendChild(el('dd', {}, [el('span', { class: 'legend-row' }, [
			el('span', { class: 'filter-glyph k-' + slug(kind), 'aria-hidden': 'true', text: encoding.glyph }),
			kind + ' — ' + encoding.shapeLabel,
		])]));
	}

	const categories = el('dl', {});
	categories.appendChild(el('dt', { text: 'Relationship category — colour and line style' }));
	for (const category of graphModel.categories) {
		const encoding = CATEGORY_ENCODING[category];
		if (!encoding) continue;
		categories.appendChild(el('dd', {}, [el('span', { class: 'legend-row' }, [
			el('span', { class: 'filter-swatch ls-' + encoding.lineStyle + ' c-' + slug(category), 'aria-hidden': 'true' }),
			category + ' — ' + encoding.lineStyle + ' line',
		])]));
	}

	// The coverage gap badge. Its own section rather than a line inside
	// "Emphasis", because it is NOT on the emphasis axis: its source is
	// `coverageGaps` membership, so a selected gap node keeps its badge where an
	// emphasis-derived mark would lose it. Describing it under Emphasis would
	// have taught the reader the wrong model.
	//
	// ONE character AND one size for both, because the canvas draws them that way
	// -- the owner compared three arms against four and two sizes against one, and
	// chose three arms at one size. Colour is the only difference. A second
	// character or a size bump here would claim a distinction the canvas does not
	// draw, which is the failure mode a legend exists to avoid.
	const gaps = el('dl', {}, [
		el('dt', { text: 'Coverage gap — asterisk beside the node' }),
		el('dd', {}, [el('span', { class: 'legend-row' }, [
			el('span', { class: 'filter-glyph gap-kb-unbacked', 'aria-hidden': 'true', text: '✱' }),
			'unbacked claim — nothing in the source backs it',
		])]),
		el('dd', {}, [el('span', { class: 'legend-row' }, [
			el('span', { class: 'filter-glyph gap-artifact-undocumented', 'aria-hidden': 'true', text: '✱' }),
			'undocumented artifact — no knowledge-base document describes it',
		])]),
		el('dd', { text: 'The red asterisk is the more severe of the two: an unbacked claim is wrong information rather than missing information. A node with neither gap carries no asterisk, and the table below states both classes in words.' }),
	]);

	const direction = el('dl', { class: 'legend-prose' }, [
		el('dt', { text: 'Direction' }),
		el('dd', { text: 'An arrowhead reads source to target, and touches the border of the node it points at. A relationship that reads the same in both directions has NO arrowhead, and that absence is the signal for it.' }),
		el('dt', { text: 'Emphasis' }),
		el('dd', { text: 'A selected node is outlined with a ring. Under the Coverage lens everything well-formed is dimmed, so the gaps stand out. Under the Provenance lens the rows of a cross-side chain keep full contrast and the rest are dimmed. In the relationship table the same two gap classes are marked with a wavy rule and a double rule instead, because a table has no room for a badge.' }),
		el('dt', { text: 'Relationship names' }),
		el('dd', { text: 'Not painted on every line. They appear on hover and on selection, and every one of them is always present as text in the relationship table.' }),
		el('dt', { text: 'Mouse' }),
		el('dd', { text: 'Scroll to zoom. Drag to pan. Click a node to select it; hover a node or a line to read its name.' }),
	]);

	host.appendChild(el('div', { class: 'legend-grid' }, [kinds, categories, gaps, direction]));
}

/**
 * The run's own report of what it could see and what it deliberately did not.
 *
 * This is the reporting channel and nothing else: no value read here decides what
 * appears in the graph. It is the answer to "is this picture thin because the
 * knowledge base is thin, or because the tool failed", which a picture alone
 * cannot give.
 */
function renderCoveragePanel(root, graphModel, viewModel) {
	const host = root.querySelector('[data-coverage-panel]');
	clear(host);
	const report = viewModel.coverage;

	if (!report) {
		host.appendChild(el('p', { class: 'callout warn' },
			['The run’s coverage report was unavailable, so this view cannot say how complete the picture is. '
				+ 'That is expected for a relationship file written before the report existed.']));
	} else {
		const rows = [];
		for (const entry of report.nodeKinds) {
			const present = new Set();
			for (const node of graphModel.nodes.values()) if (node.kind === entry.kind) present.add(node.id);
			const enumerated = entry.nodes === null ? null : entry.nodes;
			const missing = enumerated === null ? null : enumerated - present.size;
			rows.push(el('tr', {}, [
				el('td', {}, [el('span', { class: 'k-' + slug(entry.kind), 'aria-hidden': 'true', text: KIND_ENCODING[entry.kind] ? KIND_ENCODING[entry.kind].glyph + ' ' : '' }), entry.kind]),
				el('td', { text: entry.carrier }),
				el('td', { text: entry.status }),
				el('td', { text: enumerated === null ? 'not stated' : String(enumerated) }),
				el('td', { text: String(present.size) }),
				el('td', { text: missing === null ? '—' : String(missing) }),
			]));
		}
		host.appendChild(el('div', { class: 'tbl-wrap' }, [el('table', { class: 'tbl' }, [
			el('caption', { class: 'sr-only', text: 'Node kinds the run enumerated, and how many of each reached the relationship table' }),
			el('thead', {}, [el('tr', {}, [
				el('th', { scope: 'col', text: 'Kind' }), el('th', { scope: 'col', text: 'Carrier convention' }),
				el('th', { scope: 'col', text: 'Status' }), el('th', { scope: 'col', text: 'Enumerated' }),
				el('th', { scope: 'col', text: 'In the table' }), el('th', { scope: 'col', text: 'Not drawable' }),
			])]),
			el('tbody', {}, rows),
		])]));

		if (report.exclusions.length > 0) {
			host.appendChild(el('div', { class: 'tbl-wrap' }, [el('table', { class: 'tbl' }, [
				el('caption', { class: 'sr-only', text: 'Enumeration exclusions the run applied' }),
				el('thead', {}, [el('tr', {}, [
					el('th', { scope: 'col', text: 'Exclusion' }), el('th', { scope: 'col', text: 'Applied' }), el('th', { scope: 'col', text: 'Note' }),
				])]),
				el('tbody', {}, report.exclusions.map((row) => el('tr', {}, [
					el('td', { text: row.exclusion }), el('td', { text: row.applied }), el('td', { text: row.note }),
				]))),
			])]));
		}

		if (report.extra.length > 0) {
			const list = el('ul', {});
			for (const extra of report.extra) list.appendChild(el('li', { text: extra.key + ': ' + extra.cells.slice(1).join(' · ') }));
			host.appendChild(el('h3', { text: 'Additional notes recorded by the run' }));
			host.appendChild(list);
		}
	}

	// The gap classes, and which of them has a ledger counterpart. A reader has
	// to be able to tell the two apart: one is reported in the gap ledger and one
	// exists only in this view.
	const gaps = viewModel.coverageGaps;
	const origins = viewModel.coverageOrigin;
	const originCount = (which) => Array.from(origins.values()).filter((v) => v === which).length;
	host.appendChild(el('h3', { text: 'Coverage findings' }));
	host.appendChild(el('ul', {}, [
		el('li', { text: 'Undocumented source artifacts: ' + gaps.artifactUndocumented.length
			+ ' (' + originCount('verified') + ' confirmed by both this view and the recorded ledger, '
			+ originCount('ledger-only') + ' recorded only, ' + originCount('view-only') + ' found only by this view). '
			+ 'This is the class the gap ledger reports.' }),
		el('li', { text: 'Unbacked knowledge-base claims: ' + gaps.kbUnbacked.length
			+ '. This class is surfaced by the Coverage lens only and has no ledger counterpart.' }),
		el('li', { text: 'Source artifacts with no relationship row at all: ' + graphModel.integrity.orphans.length
			+ '. These reach the view through the recorded ledger, because the node set is built from the table’s '
			+ 'identifier columns and the view cannot discover them. Their absence from the table is expected and is not a mismatch.' }),
		el('li', { text: 'Facts with no checkable source edge: ' + graphModel.integrity.unbackedFacts.length
			+ '. A fact carries its anchor by construction, so any of these is a defect in the extraction rather than a gap in the knowledge base.' }),
	]));
}


/* ==========================================================================
 * 7. The two live regions
 *
 * EXACTLY TWO, and no more. The polite one carries lens changes. The alert one
 * carries whichever load-time failure occurred -- an unreadable table, or a
 * disagreement with the recorded gap set -- and is written at most once per load,
 * which holds because the two are mutually exclusive rather than because a guard
 * prevents the second: an unreadable table mounts neither rendering, so the gap
 * comparison never runs. Two regions with disjoint purposes and a fixed count
 * stay checkable; a third would make "which region said that" unanswerable.
 *
 * The drawing surface's own text alternative is NOT a live region and is not
 * announced on change.
 * ========================================================================== */

const shellState = { viewport: null };

/**
 * Publish the shell's handle, and the reason it exists.
 *
 * The page's files live inside one inline module block, so none of their bindings
 * is reachable from outside it. That is usually a virtue -- nothing leaks -- but it
 * makes one obligation unrunnable: the control surface has to be DRIVEN BY KEYBOARD
 * AND ITS EFFECT ON THE CONTROL STATE ASSERTED, and an assertion needs somewhere to
 * read that state from. Without a handle the only observable is the rendered DOM,
 * which is the very thing under test.
 *
 * So exactly ONE name is published, and it is the whole seam: the store, the built
 * manifest, the model, and the shell's own slot for a viewport handle. It is a
 * read-and-attach surface, not a second way to drive the view -- every write still
 * goes through the store -- and it is the only global this view creates.
 *
 * @param {object} value
 */
function publishHandle(value) {
	if (typeof window === 'undefined') return;
	window.aidGraphView = value;
}

function announce(root, text) {
	const region = root.querySelector('[data-status]');
	if (region) region.textContent = text;
}

/** Fill the one alert region. Its container is present and EMPTY from load,
 *  because a live region has to exist before its content is injected in order to
 *  announce reliably -- which is why it is authored empty rather than inserted
 *  whole -- and the text is written one task after mount for the same reason. */
function raise(root, level, heading, paragraphs) {
	const banner = root.querySelector('[data-alert]');
	if (!banner) return;
	banner.className = 'callout ' + (level === 'error' ? 'err' : 'warn') + ' integrity-banner';
	setTimeout(() => {
		clear(banner);
		banner.appendChild(el('h4', { text: heading }));
		for (const paragraph of paragraphs) banner.appendChild(el('p', { text: paragraph }));
	}, 0);
}

/**
 * Report the outcome of the comparison against the recorded gap set.
 *
 * A mismatch is loud in three ways at once and none of them blanks the page: a
 * persistent, non-dismissible callout ahead of both renderings; an announcement;
 * and a console line with a stable prefix a headless check can assert on. The
 * reader is told in plain language what happened, both id lists, that the lens
 * shows the UNION so no gap is hidden either way, and the likely cause -- the
 * page and the relationship file coming from different runs.
 *
 * The rest of the view still renders. A blank page would tell the reader less
 * than a working view with an honest warning, and the artifact that does have to
 * be right -- the gap ledger -- is produced elsewhere and is unaffected by this
 * page.
 */
function reportIntegrity(root, graphModel) {
	const integrity = graphModel.integrity;

	if (integrity.status === 'unverified') {
		raise(root, 'warn', 'Gap ledger cross-check unavailable', [
			'This relationship file records no generated gap list, so the view could not check its own '
			+ 'coverage answer against one. The Coverage lens is showing this view’s own recomputation.',
			'A file written before that field existed is not a broken file, which is why this is a note and not an error.',
		]);
		return;
	}
	if (integrity.status !== 'mismatch') return;

	const lines = [];
	if (integrity.viewOnly.length > 0) lines.push('Found by this view but absent from the record: ' + integrity.viewOnly.join(', '));
	if (integrity.ledgerOnly.length > 0) lines.push('Present in the record but not found by this view: ' + integrity.ledgerOnly.join(', '));

	raise(root, 'error', 'Coverage disagreement between this view and the recorded gap list', [
		'This view recomputed the undocumented-source-artifact set from the relationship table and got a '
		+ 'different answer from the list recorded in that file. One of the two is stale, and the likely cause '
		+ 'is that this page and the relationship file came from different runs.',
		lines.join('. ') + '.',
		'Nothing is hidden by the disagreement: the Coverage lens shows the UNION of the two sets, so every '
		+ 'gap either side found is still surfaced, and each one records which side it came from. '
		+ 'The rest of the view is unaffected and still renders.',
	]);

	// Stable prefix, followed by the two lists, so a headless check can assert on
	// the string rather than on the rendered page.
	console.error('graph.html: kb_gaps integrity check failed',
		{ viewOnly: integrity.viewOnly.slice(), ledgerOnly: integrity.ledgerOnly.slice() });
}

/** A conflicting Kind or name for one identifier. Both are forbidden at generate
 *  time, so meeting one here means a broken artifact -- worth showing, with a
 *  callout, rather than refusing to render. They are reported separately because
 *  a kind conflict changes colour, shape and every kind-keyed filter, whereas a
 *  name conflict changes only a label. */
function reportConflicts(root, graphModel) {
	const host = root.querySelector('[data-conflicts]');
	clear(host);
	if (graphModel.kindConflicts.length > 0) {
		host.appendChild(el('div', { class: 'callout err' }, [
			el('h4', { text: 'The same identifier carries two different kinds' }),
			el('p', { text: 'The first occurrence wins, so colour, shape and every kind-keyed filter follow it. '
				+ 'Affected: ' + graphModel.kindConflicts.map((c) => c.id + ' (' + c.kept + ' kept, ' + c.seen + ' also seen)').join('; ') + '.' }),
		]));
	}
	if (graphModel.nameConflicts.length > 0) {
		host.appendChild(el('div', { class: 'callout warn' }, [
			el('h4', { text: 'The same identifier carries two different names' }),
			el('p', { text: 'The first occurrence wins. Affected: '
				+ graphModel.nameConflicts.map((c) => c.id + ' (' + c.kept + ' kept, ' + c.seen + ' also seen)').join('; ') + '.' }),
		]));
	}
}


/* ==========================================================================
 * 8. System preferences
 *
 * Detected HERE, in the shell, and published on the store. A preference is not
 * lens state and not a function of the lens, and the projection is pure with no
 * page access, so a field on either record would make a preference the product of
 * a projection it is not. One route, both renderings read it, the page read stays
 * where every other page read is, and a flip reprojects nothing.
 * ========================================================================== */

function detectPreferences() {
	if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
		return { reducedMotion: false, forcedColours: false };
	}
	return {
		reducedMotion: window.matchMedia('(prefers-reduced-motion: reduce)').matches,
		forcedColours: window.matchMedia('(forced-colors: active)').matches,
	};
}

function watchPreferences(store) {
	if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return;
	const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
	const forced = window.matchMedia('(forced-colors: active)');
	const push = () => { store.setPreferences({ reducedMotion: motion.matches, forcedColours: forced.matches }); };
	for (const query of [motion, forced]) {
		if (typeof query.addEventListener === 'function') query.addEventListener('change', push);
		else if (typeof query.addListener === 'function') query.addListener(push);
	}
}


/* ==========================================================================
 * 9. mountShell -- the whole flow, client-side, no server and no request
 * ========================================================================== */

/**
 * Read the embedded relationship file, build the model, create the store, build
 * the controls, and mount both renderings.
 *
 * The payload is embedded base64-encoded, which matters twice over: the encoded
 * body cannot contain a `<`, so it can never be mis-parsed as markup, and a
 * markdown-typed script is the exact case the page validator's inline-engine
 * heuristic already excludes, so a large payload does not trip a check it has
 * nothing to do with.
 *
 * @param {Document|Element} [scope]
 * @returns {object|null} the store, or null when the page could not be loaded
 */
function mountShell(scope) {
	const root = scope || document;
	const payload = root.querySelector('#graph-relationships');
	let text = '';
	try {
		const encoded = (payload ? payload.textContent : '').replace(/\s+/g, '');
		text = encoded === ''
			? ''
			: new TextDecoder().decode(Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0)));
	} catch (error) {
		raise(root, 'error', 'The embedded relationship file could not be decoded', [
			'The page carries its relationship file as an encoded payload, and decoding it failed, so there is '
			+ 'nothing to render. The page and its generator are out of step.',
			String(error && error.message ? error.message : error),
		]);
		// Published even here, so a check can tell "did not boot" from "booted empty".
		publishHandle({ store: null, graphModel: null, manifest: null, shellState: shellState, error: error });
		return null;
	}

	let graphModel;
	try {
		graphModel = parseRelationships(text);
	} catch (error) {
		// A fatal load condition fills the SAME alert region a coverage
		// disagreement would, and mounts NEITHER rendering. The two writers
		// cannot collide, because a fatal parse never reaches the comparison.
		const detail = error && error.detail ? error.detail : null;
		const paragraphs = [String(error && error.message ? error.message : error)];
		if (detail && typeof detail.expected === 'string' && typeof detail.actual === 'string') {
			paragraphs.push('Expected: ' + detail.expected);
			paragraphs.push('Actual:   ' + detail.actual);
		}
		paragraphs.push('Nothing is rendered from a table whose shape cannot be trusted: a picture drawn from '
			+ 'mis-read columns would look correct and be wrong, which is the failure this view exists to prevent.');
		raise(root, 'error', 'The relationship table could not be read', paragraphs);
		console.error('graph.html: relationship table load failed', error);
		publishHandle({ store: null, graphModel: null, manifest: null, shellState: shellState, error: error });
		return null;
	}

	// Step 3: the coverage notes, over the region the table parse stopped before.
	// Reporting only, and a failure here degrades to nothing rather than blocking
	// the load. This is the one field the loader leaves for this step to fill,
	// and it is filled before the store exists.
	try {
		graphModel.coverage = parseCoverageNotes(text, graphModel.stopOffset);
	} catch (error) {
		graphModel.coverage = null;
	}

	const store = createStore(graphModel, INITIAL_LENS, detectPreferences());
	watchPreferences(store);

	const manifest = buildControlManifest(graphModel);
	shellState.manifest = manifest;
	shellState.store = store;
	publishHandle({ store: store, graphModel: graphModel, manifest: manifest, shellState: shellState, error: null });

	reportIntegrity(root, graphModel);
	reportConflicts(root, graphModel);

	const controls = mountControls({ root: root, store: store, graphModel: graphModel, manifest: manifest });
	renderLegend(root, graphModel);

	// Step 6. THE TABLE MOUNTS FIRST AND UNCONDITIONALLY, so the artifact is
	// complete and usable on a build where the drawing module is absent or where
	// the graphics context is unavailable. That is what makes the table a peer
	// rendering rather than a hidden fallback -- true at the level of load order
	// and not only in wording.
	const context = {
		store: store,
		graphModel: graphModel,
		region: root.querySelector('[data-table-region]'),
		surface: root.querySelector('[data-graph-surface]'),
		root: root,
	};

	const mountTableFn = resolveMount('table', typeof mountTable === 'function' ? mountTable : null);
	if (mountTableFn) {
		mountTableFn(context);
	} else {
		// A missing table rendering is a real defect, not a degraded mode: it is
		// the surface every conformance claim rests on. It is reported through the
		// ordinary callout channel rather than through the alert region, because
		// that region carries a LOAD-TIME failure and is written at most once per
		// load -- and a build defect is neither of the two failures it reports.
		const host = root.querySelector('[data-conflicts]');
		if (host) {
			host.appendChild(el('div', { class: 'callout err' }, [
				el('h4', { text: 'The relationship table rendering is not present in this build' }),
				el('p', { text: 'The text-equivalent rendering carries every relationship as text and is the '
					+ 'surface this view’s accessibility rests on, so without it the page is incomplete. '
					+ 'The relationship file itself is linked in the footer and remains fully readable.' }),
			]));
		}
		console.error('graph.html: the table rendering did not mount');
	}

	const mountCanvasFn = resolveMount('canvas', typeof mountCanvas === 'function' ? mountCanvas : null);
	if (mountCanvasFn) {
		const handle = mountCanvasFn(context);
		// The viewport handle, or nothing. With no handle the viewport controls
		// stay present, focusable and never disabled, and write nothing -- the
		// viewport transform is graph-only and there is nothing drawn to move.
		shellState.viewport = handle && typeof handle.viewportFor === 'function' ? handle : null;
		const placeholder = root.querySelector('[data-graph-placeholder]');
		if (placeholder) placeholder.hidden = true;
	}

	function paint(viewModel, lens) {
		controls.refresh(viewModel, lens);
		renderGroups(root, store, viewModel);
		renderCoveragePanel(root, graphModel, viewModel);

		const counts = root.querySelector('[data-counts]');
		if (counts) {
			counts.textContent = viewModel.counts.nodes + ' nodes drawn, ' + viewModel.counts.hiddenNodes + ' hidden; '
				+ viewModel.counts.edges + ' relationships drawn, ' + viewModel.counts.hiddenEdges + ' hidden';
		}

		// Written once per lens change and never per frame. Batching it at the
		// state boundary rather than the draw boundary is what keeps
		// accessibility-tree rebuilds off the frame path.
		announce(root, viewModel.announcement);
		const surface = root.querySelector('[data-graph-surface]');
		// The drawing module (feature-008, AC-S8) writes ONLY `width`/`height` on
		// the canvas it creates -- this shell owns `role` and `aria-label`
		// (feature-007 :1718) and finds the element by tag, scoped to the
		// drawing surface, so no marker attribute needs to exist for this lookup
		// to work. The WebGL capability probe (`graph-canvas.js`'s `gcHasWebGL`)
		// creates its own scratch canvas but never inserts it into the document,
		// so scoping to the surface -- rather than querying the whole page --
		// cannot pick that element up even if it somehow were reachable.
		const canvas = surface ? surface.querySelector('canvas') : null;
		if (canvas) {
			canvas.setAttribute('role', 'img');
			canvas.setAttribute('aria-label', viewModel.canvasAlt);
		}
		if (surface) surface.setAttribute('data-lens-revision', String(viewModel.revision));
	}

	store.subscribe(paint);
	paint(store.getViewModel(), store.getLens());
	return store;
}

/**
 * Schedule the shell.
 *
 * Deferred by one microtask rather than run inline, so that every file
 * concatenated after this one has finished its own top-level body before the
 * shell looks for a rendering to mount. The module block is deferred already, so
 * the document is parsed by the time any of this runs.
 */
function bootGraphView() {
	if (typeof document === 'undefined') return;
	queueMicrotask(() => { shellState.store = mountShell(document); });
}


export {
	buildControlManifest,
	AUTHORED_CONTROLS,
	VIEWPORT_ACTIONS,
	CONTROL_ATTR,
	GROUP_TOGGLE_ATTR,
	registerRendering,
	mountShell,
	bootGraphView,
	detectPreferences,
	shellState,
};
