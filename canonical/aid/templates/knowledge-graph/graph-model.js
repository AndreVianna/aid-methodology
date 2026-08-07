/* ============================================================================
 * graph-model.js -- the knowledge-relationship graph's view model.
 *
 * This is the whole interface the drawing rendering and the table rendering hold
 * against the shell. It parses the relationship table, holds the control state,
 * and projects the two into one derived structure that both renderings consume.
 * It draws nothing and touches no drawing API.
 *
 * WHERE THIS FILE RUNS
 *   Inside the page's single inline module block, concatenated after the shared
 *   coverage predicate and before the two renderings. That is one module scope,
 *   so this file DECLARES NO LOADING STATEMENT of any kind and reaches the shared
 *   predicate's exports -- RELATION_CATEGORY, COVERAGE_BEARING,
 *   detectArtifactGaps, kbUnbacked -- by plain reference. The entry point is a
 *   local file open, where a relative ES module cannot be loaded at all, so this
 *   is a property of the delivery and not a style preference.
 *
 *   Nothing here reads the network or a second file. The relationship table
 *   arrives as text from the payload element the page embeds, and it is the
 *   only input to `parseRelationships`/`project`: one file in, one picture out,
 *   so what a reader sees on screen is exactly what they can verify in the
 *   file. The one exception is storage, and it is narrow and named: § 13 below
 *   persists the reader's own checkbox-hide selection (task-034), which is
 *   reader-local state with no home in the relationship file and no effect on
 *   anything this header claims about the file being the sole input -- a
 *   restored selection is fed back in through the ordinary `filters.hiddenIds`
 *   lens key, the same door every other filter uses.
 *
 * WHAT IS AUTHORED ELSEWHERE AND WHY
 *   RELATION_CATEGORY -- the relation-to-category map over the whole core
 *   vocabulary -- is authored in the shared predicate module, not here. The gap
 *   detector needs it in a Node process, and a Node process must not load the
 *   view layer; this file is browser-only. So it is read from there, and this
 *   file adds no copy of it. `GraphModel.categories` is derived from it, so the
 *   filter axis and the palette read the vocabulary rather than a literal list.
 *
 * THE ONE RULE THAT DECIDES ENCODING
 *   A node's class comes from the table's Kind cell and from nowhere else. An
 *   identifier prefix is a different fact -- it says where an id came from -- and
 *   the two do not agree: `image` is spelled with either of two prefixes, and one
 *   prefix spans four kinds. So no colour, shape, filter, group or emphasis in
 *   this file is decided from a prefix. `Node.prefix` exists, and every place it
 *   is read is a place the question really is "where does this id come from":
 *   each such read carries a comment saying so. There are five, and they are
 *   enumerated at `Node`'s definition below.
 * ========================================================================== */


/* ==========================================================================
 * 1. The closed vocabularies
 *
 * Each of the three constants below is authored FROM the graph schema artifact
 * (`kinds:`, `provenance:`) or from the relation vocabulary, and the test suite
 * reads those files from disk and asserts equality. The page cannot read them: a
 * locally-opened page receives the relationship table and nothing else, so
 * naming a file the browser can never open as a load-time source would be a hole
 * rather than a contract. A frozen in-code constant bound to the file by a test
 * is the form that actually holds.
 * ========================================================================== */

/**
 * The seven-value node-kind enum, each with the colour TOKEN NAME and the shape
 * that carry it. Colour is a token name and never a value: the value is resolved
 * from the stylesheet at draw time, which is the only arrangement under which the
 * project's contrast checker can see the palette at all.
 *
 * Shape is not decoration. Colour is never the sole carrier of kind, so every
 * surface that shows a colour also shows this glyph, and a monochrome or
 * forced-colours rendering loses nothing but the colour.
 *
 * Key order is the schema artifact's `kinds:` order and is the order the kind
 * filter axis and the legend are built in.
 */
const KIND_ENCODING = Object.freeze({
	'document':        Object.freeze({ colourToken: '--gk-document',        glyph: '●', shape: 'circle',   shapeLabel: 'filled circle' }),
	'concept':         Object.freeze({ colourToken: '--gk-concept',         glyph: '◆', shape: 'diamond',  shapeLabel: 'filled diamond' }),
	'fact':            Object.freeze({ colourToken: '--gk-fact',            glyph: '▲', shape: 'triangle', shapeLabel: 'filled triangle, point up' }),
	'section':         Object.freeze({ colourToken: '--gk-section',         glyph: '■', shape: 'square',   shapeLabel: 'filled square' }),
	'source-artifact': Object.freeze({ colourToken: '--gk-source-artifact', glyph: '⬢', shape: 'hexagon',  shapeLabel: 'filled hexagon' }),
	'image':           Object.freeze({ colourToken: '--gk-image',           glyph: '⬟', shape: 'pentagon', shapeLabel: 'filled pentagon' }),
	'web-page':        Object.freeze({ colourToken: '--gk-web-page',        glyph: '○', shape: 'ring',     shapeLabel: 'ring, a circle with a hollow centre' }),
});

/** The three provenance values, in the schema artifact's `provenance:` order. */
const PROVENANCE_VALUES = Object.freeze(['declared', 'derived', 'inferred']);

/**
 * Which identifier prefixes each kind permits, as DATA rather than as a code
 * path, mirroring the schema artifact's own `kind|prefix,prefix` encoding.
 *
 * `image` is the branching case and the reason this is a set per kind rather
 * than one prefix per kind: an image may be in the repository or external, so
 * both prefixes are valid for it, and an implementation that assumed one prefix
 * per kind would reject every external image on a correct table.
 */
const KIND_PREFIXES = Object.freeze({
	'document':        Object.freeze(['kb']),
	'concept':         Object.freeze(['kb']),
	'fact':            Object.freeze(['kb']),
	'section':         Object.freeze(['kb']),
	'source-artifact': Object.freeze(['int']),
	'image':           Object.freeze(['int', 'ext']),
	'web-page':        Object.freeze(['ext']),
});

/**
 * The category palette: eight colour tokens over fourteen categories, each
 * category also carrying a line style.
 *
 * The eight categories holding a colour of their own are the ones the four
 * preset lenses key on, two per lens, because those are the categories a reader
 * must be able to tell apart WITHOUT filtering. The remaining six reuse a
 * holder's colour and are separated by line style.
 *
 * The generating rule, which an extension must obey: within any one colour,
 * every category carries a distinct line style. That makes the (colour, style)
 * pair unique across all fourteen. It also gives the bound -- a colour may hold
 * at most four categories, because four styles exist -- and `dash-dot` is left
 * unused by the core so the first added category per colour needs no
 * reassignment of an existing one.
 *
 * What line style can carry, stated rather than assumed: four styles cannot
 * distinguish fourteen categories, and no arrangement of eight colours and four
 * styles can. Distinctness within a colour is the strongest property it has. The
 * route to a category that does not depend on colour is threefold and none of it
 * is line style alone -- filtering to a category, the relationship name on hover
 * or selection, and the table rendering, where every name is always text.
 */
const CATEGORY_ENCODING = Object.freeze({
	'structure':      Object.freeze({ colourToken: '--gc-structure',      lineStyle: 'solid' }),
	'taxonomy':       Object.freeze({ colourToken: '--gc-taxonomy',       lineStyle: 'solid' }),
	'definition':     Object.freeze({ colourToken: '--gc-taxonomy',       lineStyle: 'dashed' }),
	'documentation':  Object.freeze({ colourToken: '--gc-documentation',  lineStyle: 'solid' }),
	'evidence':       Object.freeze({ colourToken: '--gc-evidence',       lineStyle: 'solid' }),
	'provenance':     Object.freeze({ colourToken: '--gc-provenance',     lineStyle: 'solid' }),
	'lineage':        Object.freeze({ colourToken: '--gc-lineage',        lineStyle: 'solid' }),
	'dependency':     Object.freeze({ colourToken: '--gc-dependency',     lineStyle: 'solid' }),
	'implementation': Object.freeze({ colourToken: '--gc-implementation', lineStyle: 'solid' }),
	'representation': Object.freeze({ colourToken: '--gc-structure',      lineStyle: 'dashed' }),
	'identity':       Object.freeze({ colourToken: '--gc-taxonomy',       lineStyle: 'dotted' }),
	'agreement':      Object.freeze({ colourToken: '--gc-evidence',       lineStyle: 'dashed' }),
	'annotation':     Object.freeze({ colourToken: '--gc-documentation',  lineStyle: 'dashed' }),
	'navigation':     Object.freeze({ colourToken: '--gc-structure',      lineStyle: 'dotted' }),
});

/** The four grouping dimensions plus the ungrouped scope, in control order. */
const GROUPING_VALUES = Object.freeze(['none', 'relation-category', 'document', 'node-kind', 'provenance']);

/** The three lens-level emphasis channels. */
const EMPHASIS_VALUES = Object.freeze(['none', 'coverage', 'provenance-chain']);

/** The group every edge-derived dimension puts an edgeless node in, listed last. */
const NO_RELATIONSHIPS_GROUP = 'no relationships';

/** The group the `document` dimension puts a node with neither document nor category in. */
const EXTERNAL_GROUP = 'external';

/** Label budget for the drawing/collapsed-cell label. A design choice, not a
 *  measurement: it is adjustable by the human visual gate. */
const LABEL_BUDGET = 32;

/* The kinds an unbacked-claim signal is defined over, and the kind that backs a
 * claim, are NOT declared here. Both are authored in the shared coverage
 * predicate and reached by plain reference, because this file shares that file's
 * module scope -- and because a second copy of the same knowledge is the thing a
 * rename would have preserved. Both are kinds and never prefixes: "is the thing
 * at the other end project source?" is a question about a class.
 *
 * THE SHARED SCOPE IS A CONSTRAINT, NOT A CONVENIENCE. Every file in the page's
 * one module block declares its top-level names in ONE scope, so a duplicated
 * name is not shadowing -- it is a SyntaxError, and the page does not run at all.
 * A rendering added to this block must therefore not redeclare a name any earlier
 * file declares. The generic helper names in this file are the likely
 * collisions -- 'basename', 'bump', 'clear', 'el', 'slug', 'unquote',
 * 'toInteger', 'ellipsise', 'prefixOf', 'compareStrings' -- so a rendering should
 * namespace its own helpers rather than assume a fresh scope. This is cheap to
 * check and the check belongs in the suite: concatenate the block and parse it.
 */

/** The kinds a fact must reach for its checkable anchor to be present. */
const FACT_BACKING_KINDS = Object.freeze(new Set(['source-artifact', 'image', 'web-page']));


/* ==========================================================================
 * 2. The table contract
 * ========================================================================== */

/** The header row, byte for byte. Column positions are fixed by asserting this
 *  and cells are then read by index. The loader does NOT locate a column by
 *  name and does not tolerate a different count: a name-matching loader would
 *  have absorbed the widening from eight columns to ten in silence while
 *  mis-reading one column as another. */
const HEADER_LITERAL = '| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |';

/** Cell indices, from the header literal above. */
const COL = Object.freeze({
	sourceId: 0, sourceKind: 1, sourceName: 2,
	targetId: 3, targetKind: 4, targetName: 5,
	s2t: 6, t2s: 7, provenance: 8, observation: 9,
});

const COLUMN_COUNT = 10;

/** The H1 the table lives under, from the file skeleton. */
const TABLE_HEADING = '# Relationships';

/** The unit separator that joins an edge key's four components -- the same
 *  separator and the same four components the table's own validator
 *  de-duplicated rows on, so the browser's identity of an edge is the identity
 *  the file was checked under. */
const KEY_SEP = '\u001F';


/* ==========================================================================
 * 3. LensState -- the control state, and the presets over it
 *
 * A FLAT, JSON-serialisable record. "Flat" is load-bearing and is what makes the
 * `filters.` namespace mechanically checkable: the record's own keys are the
 * dotted leaf names, so a preset patch is a plain object over the same key
 * space, `setLens` is a shallow merge, and "no preset patch contains a key in the
 * filters namespace" is a question about strings rather than about a traversal.
 * The record can be logged, diffed and replayed, and no field is a function, an
 * element handle or a renderer object.
 *
 * Fifteen members. Two of them are renderer-private and that carve-out is part
 * of the contract: `zoom` is the drawing rendering's and `sort` is the table's,
 * and NEITHER may affect which nodes or edges are present or emphasised.
 * Everything that decides membership or emphasis is in the other thirteen and
 * is interpreted exactly once, in `project()`.
 *
 * Two absences are also part of the contract:
 *
 *   - NO PHYSICS PARAMETERS. Repulsion, link distance and centre force are
 *     internal constants of the drawing rendering, tuned once. `density` means
 *     how much is drawn, not how the simulation behaves. There is no field a
 *     repulsion slider could write to, so the boundary is structural.
 *   - NO HOVER STATE. Hover reveals a relationship name and focuses a
 *     neighbourhood, and it is transient; routing it here would reproject on
 *     every pointer move. Hover may change appearance, never membership.
 *     Selection changes membership and goes through the store.
 *
 * `filters.hiddenIds` (task-034) is the checkbox-hide axis the Files/Concepts
 * tree exposes: a node id in this list is excluded at node admission, exactly
 * like a kind or provenance filter, and for the same structural reason none of
 * those touches coverage -- `verifyCoverage` runs once at load, before any lens
 * exists, over the WHOLE model. Hiding a node through this axis therefore can
 * never turn a satisfied KB claim into an unbacked one: the owner's own
 * measurement (32 of 319 claims losing their only backing artifact) was against
 * DROPPING a node from the data, which this axis never does. A reader who
 * unchecks a node is filtering the view, not editing `relationships.md`.
 * ========================================================================== */

const LENS_KEYS = Object.freeze([
	'preset',
	'grouping',
	'expandedGroups',
	'density',
	'filters.kinds',
	'filters.categories',
	'filters.provenance',
	'filters.showOrphans',
	'filters.text',
	'filters.hiddenIds',
	'focus.nodeId',
	'focus.depth',
	'emphasis',
	'zoom',
	'sort',
]);

/** The subset of the key space a preset patch may not touch. */
const FILTER_KEYS = Object.freeze(LENS_KEYS.filter((k) => k.indexOf('filters.') === 0));

/**
 * The initial state: the unfiltered whole, with no lens applied and nothing
 * folded. No preset is the default, because all four purposes this view serves
 * are equally primary -- privileging one would answer a question the reader has
 * not asked yet.
 *
 * Every one of the fifteen members is stated, so the record is total rather
 * than correct only where someone looked. `focus.depth`, `zoom`, `sort` and
 * `filters.text` are here for a second reason as well: each preset patch has to
 * differ from this record on at least one key it sets, and at Impact's depth of
 * two an unstated depth would have made that patch differ on nothing at all.
 */
const INITIAL_LENS = Object.freeze({
	'preset': null,
	'grouping': 'none',
	'expandedGroups': Object.freeze([]),
	'density': 1,
	'filters.kinds': Object.freeze(Object.keys(KIND_ENCODING)),
	'filters.categories': Object.freeze(distinctCategories()),
	'filters.provenance': PROVENANCE_VALUES,
	'filters.showOrphans': true,
	'filters.text': '',
	'filters.hiddenIds': Object.freeze([]),
	'focus.nodeId': null,
	'focus.depth': 1,
	'emphasis': 'none',
	'zoom': Object.freeze({ scale: 1, panX: 0, panY: 0 }),
	'sort': Object.freeze({ column: 'row', direction: 'asc' }),
});

/**
 * The four preset lenses, each a frozen partial assignment over LensState.
 *
 * That is the entire mechanism, and it is why arriving through a preset cannot
 * lock the view: the patch lands in the same record every control writes to, so
 * every control keeps working afterwards and nothing is ever disabled. A preset
 * is an entry point, not a mode.
 *
 * NO PATCH CONTAINS A KEY IN THE `filters.` NAMESPACE. That is a domain
 * restriction rather than a coincidence of these four: a filter therefore
 * composes with a lens rather than being reset by it, and a fifth preset could
 * not break the property without failing a test. The reciprocal half is that a
 * filter never writes `preset`, so the pressed state of the lens buttons keeps
 * reporting how the reader arrived, and the announced summary names both.
 */
const PRESETS = Object.freeze({
	'coverage': Object.freeze({
		'emphasis': 'coverage',
		'grouping': 'node-kind',
		'density': 1,
		'focus.nodeId': null,
	}),
	'overview': Object.freeze({
		'grouping': 'document',
		'expandedGroups': Object.freeze([]),
		'density': 3,
		'emphasis': 'none',
		'focus.nodeId': null,
	}),
	'impact': Object.freeze({
		'focus.depth': 2,
		'density': 1,
		'emphasis': 'none',
		'grouping': 'none',
	}),
	'provenance': Object.freeze({
		'emphasis': 'provenance-chain',
		'grouping': 'provenance',
		'density': 1,
	}),
});

/** Human wording for each preset, used in the announced text and the summary. */
const PRESET_LABELS = Object.freeze({
	'coverage': 'Coverage',
	'overview': 'Overview',
	'impact': 'Impact',
	'provenance': 'Provenance',
});

/**
 * The category set in the vocabulary's declared order, taken from the shared
 * relation map's value order rather than from a literal list here. A category
 * added to the vocabulary therefore reaches the filter axis, the palette check
 * and the legend without an edit in this file.
 *
 * @returns {string[]}
 */
function distinctCategories() {
	const seen = [];
	const have = new Set();
	for (const category of Object.values(RELATION_CATEGORY)) {
		if (!have.has(category)) { have.add(category); seen.push(category); }
	}
	return seen;
}


/* ==========================================================================
 * 4. The loader
 *
 * Five steps in order, each pinned to the file skeleton so this reader and the
 * emitter cannot disagree about where the table is.
 * ========================================================================== */

/** Thrown for any condition that makes the artifact unreadable. The shell
 *  catches it, fills the one alert region, and mounts neither rendering: a
 *  half-rendered picture from a broken file is the failure this whole view
 *  exists to prevent. */
class GraphLoadError extends Error {
	constructor(message, detail) {
		super(message);
		this.name = 'GraphLoadError';
		this.detail = detail || null;
	}
}

/**
 * Split one table line into its cells, honouring the escaped pipe.
 *
 * The table permits a literal pipe inside a cell, escaped. That matters here
 * more than it looks: a `fact` display name reproduces a knowledge-base anchor
 * string verbatim, and such a string may legitimately contain a pipe. A naive
 * split would turn a valid row into eleven cells and fail the column-count check
 * on correct input -- a fatal error on a good file, which is the worst failure
 * mode available.
 *
 * @param {string} line
 * @returns {string[]} the row's cells, trimmed, with escapes resolved
 */
function splitRow(line) {
	const text = line.replace(/\r$/, '');
	const segments = [];
	let current = '';
	for (let i = 0; i < text.length; i += 1) {
		const ch = text[i];
		if (ch === '\\' && text[i + 1] === '|') { current += '|'; i += 1; continue; }
		if (ch === '|') { segments.push(current); current = ''; continue; }
		current += ch;
	}
	segments.push(current);
	// The row is written with a leading and a trailing pipe, so the scan yields
	// one empty segment at each end. Drop exactly those two.
	if (segments.length >= 2 && segments[0].trim() === '') segments.shift();
	if (segments.length >= 1 && segments[segments.length - 1].trim() === '') segments.pop();
	return segments.map((cell) => cell.trim());
}

/** A line belongs to the table when its first non-whitespace character is a
 *  pipe. This is the stop rule, and it is the whole reason the coverage notes
 *  can sit in the same file without becoming part of the graph. */
function isTableLine(line) {
	return /^\s*\|/.test(line);
}

/** A delimiter row is dashes and pipes only. Written to accept any dash width,
 *  because the coverage notes' own tables are padded and the graph's is not. */
function isDelimiterRow(line) {
	return /^\s*\|[\s|:-]+\|\s*$/.test(line) && line.indexOf('-') !== -1;
}

/**
 * Read the leading frontmatter block, and only the leading one.
 *
 * A later `---` in the body is a thematic break, not a second frontmatter block;
 * scoping to the first block is also what the knowledge base's own frontmatter
 * readers do, so this reader and those agree on where frontmatter ends.
 *
 * @param {string[]} lines
 * @returns {{lines: string[], endIndex: number}} the block's inner lines and the
 *          index of the first line after it (0 and -1 style values avoided: an
 *          absent block yields an empty list and index 0)
 */
function readFrontmatter(lines) {
	if (lines.length === 0 || lines[0].trim() !== '---') return { lines: [], endIndex: 0 };
	for (let i = 1; i < lines.length; i += 1) {
		if (lines[i].trim() === '---') return { lines: lines.slice(1, i), endIndex: i + 1 };
	}
	return { lines: [], endIndex: 0 };
}

/** Strip one layer of matching quotes from a scalar. */
function unquote(value) {
	const v = value.trim();
	if (v.length >= 2 && ((v[0] === '"' && v[v.length - 1] === '"') || (v[0] === "'" && v[v.length - 1] === "'"))) {
		return v.slice(1, -1);
	}
	return v;
}

/** A single top-level scalar field of the frontmatter block. */
function frontmatterScalar(fmLines, key) {
	const prefix = key + ':';
	for (const line of fmLines) {
		if (line.indexOf(prefix) === 0) return unquote(line.slice(prefix.length));
	}
	return null;
}

/**
 * The recorded gap list from frontmatter: a block sequence of four-key mappings.
 *
 * This is a RECORD of what the generate-time run found, not the lens's source of
 * truth. It has two jobs. The view recomputes the same set with the shared
 * predicate and verifies its answer against this one; and it is the only route
 * by which a node that appears in NO relationship row can reach the page at all,
 * since the node set is otherwise built from the table's two identifier columns.
 *
 * Reading it is not a second extraction path: it is frontmatter of the one file
 * the view already renders from.
 *
 * Absence yields null, which is a warning and not an error -- a file written
 * before the field existed is not a corrupt file, and a false alarm here trains
 * a reader to ignore the real one.
 *
 * @param {string[]} fmLines
 * @returns {Array<{id: string, name: string, severity: string, qualifier: string}>|null}
 */
function frontmatterGaps(fmLines) {
	let start = -1;
	for (let i = 0; i < fmLines.length; i += 1) {
		if (/^kb_gaps:\s*$/.test(fmLines[i])) { start = i + 1; break; }
	}
	if (start === -1) return null;

	const entries = [];
	let current = null;
	for (let i = start; i < fmLines.length; i += 1) {
		const line = fmLines[i];
		if (line.trim() === '') continue;
		// A non-indented line ends the block.
		if (!/^\s/.test(line)) break;
		const item = line.match(/^\s*-\s*(.*)$/);
		if (item) {
			if (current) entries.push(current);
			current = {};
			const inline = item[1];
			if (inline) applyMappingLine(current, inline);
			continue;
		}
		if (current) applyMappingLine(current, line.trim());
	}
	if (current) entries.push(current);

	// A malformed entry is dropped rather than half-carried: an entry with no id
	// cannot be compared against anything, and one with no name cannot be
	// labelled, `name` being the only place a display name for a row-less node
	// exists. Dropping is visible -- the recomputed set will disagree and the
	// mismatch is reported -- whereas a half-record would render as an unnamed
	// mark nobody can act on.
	return entries.filter((e) => typeof e.id === 'string' && e.id !== '' && typeof e.name === 'string' && e.name !== '');
}

/** Apply one `key: value` pair of a frontmatter mapping entry. */
function applyMappingLine(target, text) {
	const at = text.indexOf(':');
	if (at === -1) return;
	const key = text.slice(0, at).trim();
	if (key !== 'id' && key !== 'name' && key !== 'severity' && key !== 'qualifier') return;
	target[key] = unquote(text.slice(at + 1));
}

/** The prefix of an id -- `kb`, `int` or `ext`. This is not the kind and is
 *  never used as one; see the enumeration at `Node`. */
function prefixOf(id) {
	const at = id.indexOf(':');
	return at === -1 ? '' : id.slice(0, at);
}

/**
 * Parse the relationship table into the graph model.
 *
 * @param {string} markdownText the whole file, verbatim
 * @returns {object} GraphModel
 * @throws {GraphLoadError} on any condition that makes the artifact unreadable
 */
function parseRelationships(markdownText) {
	const text = typeof markdownText === 'string' ? markdownText : '';
	const lines = text.split('\n');

	// --- Step 1: frontmatter -------------------------------------------------
	const fm = readFrontmatter(lines);
	const recordedGaps = frontmatterGaps(fm.lines);
	const sourceStamp = frontmatterScalar(fm.lines, 'generator') || '';

	// --- Step 2: the table heading ------------------------------------------
	let cursor = fm.endIndex;
	let headingAt = -1;
	for (let i = cursor; i < lines.length; i += 1) {
		if (lines[i].replace(/\r$/, '').trim() === TABLE_HEADING) { headingAt = i; break; }
	}
	if (headingAt === -1) {
		throw new GraphLoadError(
			'The relationship table could not be found: no "' + TABLE_HEADING + '" heading in the file.',
			{ expected: TABLE_HEADING, actual: null });
	}

	// The first non-blank line after the heading is the header row.
	cursor = headingAt + 1;
	while (cursor < lines.length && lines[cursor].trim() === '') cursor += 1;

	// --- Step 3: the header literal -----------------------------------------
	const headerActual = cursor < lines.length ? lines[cursor].replace(/\r$/, '').trim() : '';
	if (headerActual !== HEADER_LITERAL) {
		throw new GraphLoadError(
			'The relationship table header does not match the ten-column contract, so no column position can be trusted. '
			+ 'The view reads cells by position after asserting this line, and it does not guess.',
			{ expected: HEADER_LITERAL, actual: headerActual });
	}
	cursor += 1;

	// --- Step 4: the delimiter row ------------------------------------------
	if (cursor >= lines.length || !isDelimiterRow(lines[cursor])) {
		throw new GraphLoadError(
			'The relationship table header is not followed by a delimiter row.',
			{ expected: 'a delimiter row of ' + COLUMN_COUNT + ' columns', actual: cursor < lines.length ? lines[cursor] : null });
	}
	cursor += 1;

	// --- Step 5: the data rows, stopping at the first non-table line ---------
	// The stop rule is the whole mechanism by which the coverage notes can live
	// in the same file: the table runs from the header row to the first line
	// that is not a table row, and this parser stops there. It does not look
	// ahead, does not search for a second table, and does not treat the notes'
	// own tables as continuation rows.
	const nodes = new Map();
	const edges = [];
	const nameConflicts = [];
	const kindConflicts = [];
	const categories = distinctCategories();
	const categorySet = new Set(categories);
	let rowCount = 0;
	let stopOffset = text.length;

	for (; cursor < lines.length; cursor += 1) {
		const raw = lines[cursor];
		if (!isTableLine(raw)) {
			stopOffset = offsetOfLine(lines, cursor);
			break;
		}
		// The single delimiter row was consumed above, so every remaining table
		// line is a data row and none is skipped by shape -- a shape test here
		// could swallow a data row whose cells happened to look like dashes.
		const cells = splitRow(raw);
		rowCount += 1;
		const rowNumber = rowCount;

		if (cells.length !== COLUMN_COUNT) {
			throw new GraphLoadError(
				'Row ' + rowNumber + ' of the relationship table has ' + cells.length + ' cells where the contract fixes ' + COLUMN_COUNT + '.',
				{ row: rowNumber, expected: COLUMN_COUNT, actual: cells.length, line: raw });
		}

		const provenance = cells[COL.provenance];
		if (provenance === '') {
			throw new GraphLoadError(
				'Row ' + rowNumber + ' of the relationship table has an empty Provenance cell, which the schema requires by construction.',
				{ row: rowNumber });
		}
		if (PROVENANCE_VALUES.indexOf(provenance) === -1) {
			throw new GraphLoadError(
				'Row ' + rowNumber + ' carries the Provenance value "' + provenance + '", which is outside the closed set.',
				{ row: rowNumber, expected: PROVENANCE_VALUES.slice(), actual: provenance });
		}

		const s2t = cells[COL.s2t];
		const t2s = cells[COL.t2s];
		for (const relation of [s2t, t2s]) {
			if (!Object.prototype.hasOwnProperty.call(RELATION_CATEGORY, relation)) {
				throw new GraphLoadError(
					'Row ' + rowNumber + ' names the relation "' + relation + '", which is not in the loaded vocabulary. '
					+ 'The vocabulary is closed and loaded fail-closed, so an unknown relation is a broken artifact rather than an extra bucket.',
					{ row: rowNumber, relation: relation });
			}
		}

		const category = RELATION_CATEGORY[s2t];
		if (!categorySet.has(category) || !Object.prototype.hasOwnProperty.call(CATEGORY_ENCODING, category)) {
			// The palette cannot represent this category, so the view would draw
			// it as some other category's colour and style. Saying so is the
			// alternative to a silent collision.
			throw new GraphLoadError(
				'The relation "' + s2t + '" belongs to the category "' + category + '", which the palette has no encoding for. '
				+ 'A category added to the vocabulary needs a colour token and a line style before the view can draw it.',
				{ row: rowNumber, category: category });
		}

		const source = admitNode(nodes, cells[COL.sourceId], cells[COL.sourceKind], cells[COL.sourceName], rowNumber, nameConflicts, kindConflicts);
		const target = admitNode(nodes, cells[COL.targetId], cells[COL.targetKind], cells[COL.targetName], rowNumber, nameConflicts, kindConflicts);

		// The Observation cell is written as a single space when empty, so a lone
		// space is normalised back to nothing rather than carried as content.
		const observation = cells[COL.observation];

		edges.push({
			key: [source.id, target.id, s2t, t2s].join(KEY_SEP),
			sourceId: source.id,
			targetId: target.id,
			s2t: s2t,
			t2s: t2s,
			category: category,
			// A relationship reading the same in both directions has no
			// direction, and the ABSENCE of an arrowhead is the signal for it.
			// Deciding it here rather than in a draw loop is what stops the two
			// renderings disagreeing about whether a relationship is directed:
			// the table renders the same fact as a two-headed arrow.
			symmetric: s2t === t2s,
			provenance: provenance,
			observation: observation,
			row: rowNumber,
		});
	}

	// --- Degrees, one pass over the rows ------------------------------------
	for (const edge of edges) {
		const source = nodes.get(edge.sourceId);
		const target = nodes.get(edge.targetId);
		source.degree += 1;
		target.degree += 1;
		bump(source.degreeByKind, target.kind);
		bump(target.degreeByKind, source.kind);
	}

	// --- Row-less nodes, materialised from the recorded gap list -------------
	// An enumerated source artifact appearing in no row at all is the sharpest
	// instance of the defect the gap list exists to report -- something the
	// project considers significant with nothing said about it anywhere -- so it
	// must be impossible for the view to lose. The node set is built from the
	// table's identifier columns, so the view cannot discover these; the
	// recorded list is how they reach the page.
	//
	// The record synthesised for each is COMPLETE and carries no "synthetic"
	// flag. That is the load-bearing choice: every consumer that walks the
	// visible node set handles one correctly without knowing the class exists,
	// and a flag would invite a branch on it in two renderings.
	const tableArtifactIds = new Set();
	for (const node of nodes.values()) {
		if (node.kind === BACKING_KIND) tableArtifactIds.add(node.id);
	}
	const orphanIds = [];
	if (recordedGaps) {
		for (const entry of recordedGaps) {
			if (nodes.has(entry.id)) continue;
			orphanIds.push(entry.id);
			// The kind comes from WHICH LIST THE ENTRY CAME OUT OF -- the
			// recorded list is scoped to source artifacts by definition -- and
			// not from the identifier prefix, which spans two kinds and could
			// not decide it.
			const record = makeNode(entry.id, BACKING_KIND, entry.name);
			assertPrefixAgreement(record, 0);
			nodes.set(record.id, record);
		}
	}
	orphanIds.sort(compareStrings);

	// --- Short labels, once, over the full node set --------------------------
	// Computed here and never per projection, so a label cannot change when a
	// filter changes and the same node is never called two things in one
	// session. It also keeps the projection trivially pure.
	assignShortLabels(nodes);

	// --- Unbacked facts -----------------------------------------------------
	// A fact is a claim CARRYING a checkable source anchor, and it is emitted
	// together with the edge to the path that anchor cites -- so an unbacked
	// fact is structurally impossible in a well-formed artifact. If one appears,
	// the defect is in the extraction and not in the knowledge base, and
	// reporting it as a coverage signal would send the reader to fix their
	// knowledge base when the thing that is broken is the tool. It reaches the
	// reader through the integrity channel instead, and is excluded from the
	// unbacked-claim class by that class's own domain.
	const factBacked = new Set();
	for (const edge of edges) {
		const source = nodes.get(edge.sourceId);
		const target = nodes.get(edge.targetId);
		if (source.kind === 'fact' && FACT_BACKING_KINDS.has(target.kind)) factBacked.add(source.id);
		if (target.kind === 'fact' && FACT_BACKING_KINDS.has(source.kind)) factBacked.add(target.id);
	}
	const unbackedFacts = [];
	for (const node of nodes.values()) {
		if (node.kind === 'fact' && !factBacked.has(node.id)) unbackedFacts.push(node.id);
	}
	unbackedFacts.sort(compareStrings);

	const model = {
		nodes: nodes,
		edges: edges,
		rowCount: rowCount,
		categoryOf: new Map(Object.entries(RELATION_CATEGORY)),
		categories: categories,
		coverageBearing: COVERAGE_BEARING,
		recordedGaps: recordedGaps,
		integrity: null,
		nameConflicts: nameConflicts,
		kindConflicts: kindConflicts,
		coverage: null,
		sourceStamp: sourceStamp,
		// Not part of the published contract: the byte offset the table parse
		// stopped at, handed to the notes reader so the two regions are provably
		// disjoint rather than disjoint by inspection.
		stopOffset: stopOffset,
	};

	verifyCoverage(model, tableArtifactIds, orphanIds, unbackedFacts);
	return model;
}

/** Byte offset of a line index within the joined text. */
function offsetOfLine(lines, index) {
	let offset = 0;
	for (let i = 0; i < index; i += 1) offset += lines[i].length + 1;
	return offset;
}

/** Increment a counter in a Map. */
function bump(map, key) {
	map.set(key, (map.get(key) || 0) + 1);
}

/** Code-unit string order. Locale-independent, so the same model orders a result
 *  identically in every runtime. */
function compareStrings(a, b) {
	if (a < b) return -1;
	if (a > b) return 1;
	return 0;
}

/**
 * A node record.
 *
 * `Node = { id, kind, prefix, name, shortLabel, glyph, kbDoc, degree, degreeByKind }`
 *
 * `kind` is the table's Kind cell for the row this node was first seen on, and
 * it is one of the seven enum values. It is never recovered by parsing the id.
 *
 * `prefix` is `kb`, `int` or `ext`, parsed from the id, and it is NOT the kind.
 * Every place it is read is a place the question is "where does this id come
 * from or how is it spelled". Those places are enumerated rather than counted,
 * and there are five:
 *
 *   1. the kind/prefix agreement check at load, which is precisely a question
 *      about spelling;
 *   2. path semantics -- a repository-relative identifier IS its path with the
 *      prefix stripped, which is what lets the coverage predicate match an
 *      ancestor directory with no extra field. That read lives in the shared
 *      predicate, not here;
 *   3. the provenance lens's cross-side chain, which is the one thing a prefix
 *      names and no kind does;
 *   4. the `document` grouping dimension's split of an image into in-repo and
 *      external, because the Kind cell cannot say where an artifact lives;
 *   5. the open target and the label basis, which need the same split for the
 *      same reason -- only a path has a basename, and only a path can be opened
 *      as one.
 *
 * Sites 3 to 5 all ask one question -- where does the artifact live -- about the
 * one kind that spans two sides. A prefix read is a defect when it STANDS IN FOR
 * THE KIND, and none of these does.
 *
 * `glyph` is copied onto the record so a consumer walking the visible node set
 * needs no second lookup. The colour half is deliberately NOT copied: it reaches
 * a consumer as a token name through the projection, because the value has to be
 * resolved from the stylesheet at draw time for the palette to stay checkable.
 *
 * `kbDoc` is the document part of the id, and it is null for a concept. That is
 * not an omission: a concept identifier is deliberately not document-scoped,
 * which follows from the merge rule, so there is no document part to take. That
 * single null is what forces the `document` dimension to be kind-dependent
 * rather than keyed on this field.
 *
 * There is no qualification field, and this record relies on an invariant it
 * does not own: a node candidate that only a reading would qualify is never
 * emitted as a node at all. Were that relaxed, the coverage predicate would need
 * per-node qualification evidence in the browser, which the relationship table
 * does not carry and cannot fetch separately. That is the concrete cost, and it
 * is why the invariant is load-bearing rather than incidental.
 */
function makeNode(id, kind, name) {
	return {
		id: id,
		kind: kind,
		prefix: prefixOf(id),
		name: name,
		shortLabel: name,
		glyph: KIND_ENCODING[kind].glyph,
		kbDoc: kbDocOf(id, kind),
		degree: 0,
		degreeByKind: new Map(),
	};
}

/** The document part of an id, for the three document-scoped kinds. */
function kbDocOf(id, kind) {
	if (kind !== 'document' && kind !== 'section' && kind !== 'fact') return null;
	const body = id.slice(id.indexOf(':') + 1);
	const hash = body.indexOf('#');
	return hash === -1 ? body : body.slice(0, hash);
}

/**
 * Record a node from one endpoint of one row, or reconcile it with the record
 * already held for that id.
 *
 * A Kind outside the enum is a load error and not an eighth bucket: the Kind
 * vocabulary is closed and loaded fail-closed, exactly like the relation
 * vocabulary. A Kind that disagrees with its own id's prefix is likewise fatal,
 * and the branching case is handled as DATA rather than as a code path: an image
 * permits either prefix, and rejecting the external one is the specific bug a
 * naive one-prefix-per-kind implementation commits.
 *
 * The same id carrying two different Kinds, or two different names, is recorded
 * rather than fatal -- first occurrence wins -- because the file's own validator
 * forbids both at generate time, so meeting one here means a broken artifact
 * that is still worth showing with a prominent callout. They are recorded
 * separately: a kind conflict changes colour, shape and every kind-keyed filter,
 * whereas a name conflict changes only a label.
 */
function admitNode(nodes, id, kind, name, rowNumber, nameConflicts, kindConflicts) {
	if (id === '') {
		throw new GraphLoadError('Row ' + rowNumber + ' has an empty identifier cell.', { row: rowNumber });
	}
	if (!Object.prototype.hasOwnProperty.call(KIND_ENCODING, kind)) {
		throw new GraphLoadError(
			'Row ' + rowNumber + ' carries the Kind value "' + kind + '", which is outside the closed seven-value set.',
			{ row: rowNumber, expected: Object.keys(KIND_ENCODING), actual: kind });
	}

	const existing = nodes.get(id);
	if (existing) {
		if (existing.kind !== kind) kindConflicts.push({ id: id, kept: existing.kind, seen: kind, row: rowNumber });
		if (existing.name !== name) nameConflicts.push({ id: id, kept: existing.name, seen: name, row: rowNumber });
		return existing;
	}

	const record = makeNode(id, kind, name);
	assertPrefixAgreement(record, rowNumber);
	nodes.set(id, record);
	return record;
}

/** Prefix-read site 1: the kind/prefix agreement check. The question here IS
 *  about how the id is spelled, which is what a prefix answers. */
function assertPrefixAgreement(node, rowNumber) {
	const permitted = KIND_PREFIXES[node.kind];
	if (permitted.indexOf(node.prefix) === -1) {
		throw new GraphLoadError(
			'The identifier "' + node.id + '" is spelled with the "' + node.prefix + ':" prefix, which the Kind "'
			+ node.kind + '" does not permit.',
			{ row: rowNumber, id: node.id, kind: node.kind, prefix: node.prefix, permitted: permitted.slice() });
	}
}


/* ==========================================================================
 * 5. The coverage-notes reader -- a second reader over a disjoint region
 *
 * The stop rule leaves the notes unread, and leaving them unread permanently
 * would be a loss: they are the answer to "is this picture thin because the
 * knowledge base is thin, or because the tool failed", and they are already in
 * the file the view has in hand.
 *
 * Four rules bound this reader, and together they are why the single-input rule
 * survives:
 *
 *   1. IT CANNOT CONTRIBUTE TO MEMBERSHIP. Its result reaches one projection
 *      field, which the projection copies through untouched, and is consumed by
 *      the legend, the coverage panel and the table's captions. No value from it
 *      appears in any node set, edge set, fold or emphasis map. The structural
 *      guarantee is that the projection never receives it as anything else.
 *   2. IT IS NOT A SECOND EXTRACTION PATH. It reads the same bytes of the same
 *      file the view already renders from. What is forbidden is a second
 *      extraction, not a second region.
 *   3. IT HARDCODES NO ROW SET. The two fixed tables have fixed rows, but the
 *      EXTRA rows are owned by their producers and more may arrive. Reading them
 *      generically is the only form that does not go stale.
 *   4. ABSENCE IS NOT AN ERROR. A file predating the notes yields null and the
 *      panel says the run's coverage report was unavailable.
 * ========================================================================== */

/**
 * @param {string} markdownText the whole file, verbatim
 * @param {number} stopOffset the byte offset the table parse stopped at
 * @returns {object|null} CoverageReport, or null when there is no notes section
 */
function parseCoverageNotes(markdownText, stopOffset) {
	const text = typeof markdownText === 'string' ? markdownText : '';
	const from = typeof stopOffset === 'number' && stopOffset >= 0 && stopOffset <= text.length ? stopOffset : 0;
	const region = text.slice(from);
	if (region.indexOf('## Coverage notes') === -1) return null;

	const lines = region.split('\n');
	const report = { nodeKinds: [], exclusions: [], extra: [] };
	let table = null;
	let expectedCells = 0;

	for (const raw of lines) {
		const line = raw.replace(/\r$/, '');
		const heading = line.match(/^###\s+(.*)$/);
		if (heading) {
			const name = heading[1].trim();
			if (name === 'Node kinds') { table = 'nodeKinds'; expectedCells = 4; }
			else if (name === 'Enumeration exclusions') { table = 'exclusions'; expectedCells = 3; }
			else { table = null; expectedCells = 0; }
			continue;
		}
		if (/^##\s/.test(line) && !/^###/.test(line)) {
			if (line.trim() !== '## Coverage notes') { table = null; expectedCells = 0; }
			continue;
		}
		if (!table || !isTableLine(line) || isDelimiterRow(line)) continue;

		const cells = splitRow(line);
		if (cells.length !== expectedCells) continue;
		if (table === 'nodeKinds') {
			if (cells[0] === 'Kind') continue;
			const known = Object.prototype.hasOwnProperty.call(KIND_ENCODING, cells[0]);
			const row = { kind: cells[0], carrier: cells[1], status: cells[2], nodes: toInteger(cells[3]) };
			// The fixed rows are the seven kinds; anything else below the block is
			// an extra row, read as whatever is present rather than against a
			// hardcoded key set.
			if (known) report.nodeKinds.push(row);
			else report.extra.push({ table: 'nodeKinds', key: cells[0], cells: cells.slice() });
		} else {
			if (cells[0] === 'Exclusion') continue;
			report.exclusions.push({ exclusion: cells[0], applied: cells[1], note: cells[2] });
		}
	}
	return report;
}

/** A cell's integer value, or null when it does not carry one. */
function toInteger(cell) {
	const m = String(cell).match(/-?\d+/);
	return m ? parseInt(m[0], 10) : null;
}


/* ==========================================================================
 * 6. Coverage -- recomputed here, verified against the record
 *
 * The gap set is a property of the DATA and not of the lens, so it is computed
 * once per load and never per lens application. That is what makes the equality
 * the requirements ask for bind unconditionally on the SET: a mark for a gap
 * node thins with every other node at a high density level, while the list the
 * lens, the coverage panel and the ledger comparison all read is unchanged.
 *
 * Three sets, and the third is the one that must never raise an alarm:
 *
 *   viewOnly   = recomputed \ recorded                -> a real mismatch
 *   ledgerOnly = (recorded n in-table) \ recomputed   -> a real mismatch
 *   orphans    = recorded \ in-table                  -> EXPECTED, never one
 *
 * `orphans` is excluded BY THE SHAPE OF THE SET DEFINITION rather than by a
 * guard clause: `ledgerOnly` is intersected with the in-table artifact ids
 * precisely so a node the view could never have seen is not counted against it.
 * There is no code path on which a row-less node reaches the error channel, and
 * it cannot be made to fire on one by a later edit without changing that
 * intersection, which is a visible change. A run that finds row-less nodes is a
 * NORMAL run, and an alarm firing every time would train the reader to dismiss
 * the one that matters.
 *
 * The published set is always the UNION of the two. A disagreement therefore
 * cannot hide a gap on either surface -- hiding one is the only failure mode
 * here that costs a reader something -- and the origin of each id is published
 * beside it.
 * ========================================================================== */

/**
 * Project the edge list into the shape the shared predicate reads.
 *
 * THE SEAM, AND THE CHOICE MADE AT IT. The predicate's coverage test asks for
 * the OTHER endpoint's kind, and the edge record above carries the two
 * identifiers but not the two kinds. Two ways to close that: widen the edge
 * record, or join the kinds from the node map at the call site. The join is
 * taken, for three reasons.
 *
 *   - The edge record is a fixed cross-feature contract with a stated field
 *     list, consumed by both renderings. Widening it changes that contract for
 *     two features that do not need the extra fields.
 *   - It keeps ONE authored carrier of the Kind column. `Node.kind` is that
 *     carrier, a conflicting Kind for one id is reconciled there once and
 *     recorded once, and a per-row copy would be a second carrier that could
 *     disagree with the first.
 *   - The resulting shape is exactly the predicate's own documented input type,
 *     so the seam stays the predicate's rather than becoming a local widening
 *     the predicate has to tolerate.
 *
 * The kind is read from the node record's own `kind` field. It is not derived
 * from the identifier and not read from any sibling field of the row: an
 * identifier is correct about where a node came from and wrong about what class
 * it belongs to, and a lookup keyed on the wrong one of those would pass every
 * test written over a corpus where the two happen to agree.
 *
 * Built once per load, not per lens application.
 *
 * @param {Map<string, object>} nodes
 * @param {object[]} edges
 * @returns {object[]} CoverageEdge records
 */
function toCoverageEdges(nodes, edges) {
	const out = [];
	for (const edge of edges) {
		const source = nodes.get(edge.sourceId);
		const target = nodes.get(edge.targetId);
		out.push({
			sourceId: edge.sourceId,
			sourceKind: source ? source.kind : undefined,
			targetId: edge.targetId,
			targetKind: target ? target.kind : undefined,
			s2t: edge.s2t,
			t2s: edge.t2s,
		});
	}
	return out;
}

/**
 * Recompute the two coverage classes, compare the first against the record, and
 * attach the outcome to the model.
 *
 * Idempotent: called by the loader, which needs the row-less set in order to
 * materialise those nodes at all, and called again by the store before any
 * subscriber exists so that the verdict is surfaced at exactly the point the
 * flow specifies. The second call returns the first call's result.
 *
 * @param {object} model
 * @param {Set<string>} [tableArtifactIds]
 * @param {string[]} [orphanIds]
 * @param {string[]} [unbackedFacts]
 */
function verifyCoverage(model, tableArtifactIds, orphanIds, unbackedFacts) {
	if (model.integrity && model.coverageSets) return model.integrity;

	const coverageEdges = toCoverageEdges(model.nodes, model.edges);

	// The candidate set the browser can offer is the source artifacts the table
	// contains. The pipeline offers the full enumerated inventory, which is
	// wider; that difference is expected and is exactly what the record carries
	// across. Membership of the class is decided from the node's KIND.
	const inTable = tableArtifactIds instanceof Set ? tableArtifactIds : new Set(
		Array.from(model.nodes.values()).filter((n) => n.kind === BACKING_KIND).map((n) => n.id));

	const candidates = [];
	for (const node of model.nodes.values()) {
		if (node.kind === BACKING_KIND && inTable.has(node.id)) candidates.push(node.id);
	}
	const recomputed = detectArtifactGaps({ nodeIds: candidates, edges: coverageEdges });
	const recomputedSet = new Set(recomputed);

	const recorded = model.recordedGaps ? model.recordedGaps.map((e) => e.id) : [];
	const recordedSet = new Set(recorded);

	const viewOnly = recomputed.filter((id) => !recordedSet.has(id));
	const ledgerOnly = recorded.filter((id) => inTable.has(id) && !recomputedSet.has(id)).sort(compareStrings);
	const orphans = Array.isArray(orphanIds)
		? orphanIds.slice()
		: recorded.filter((id) => !inTable.has(id)).sort(compareStrings);

	const union = Array.from(new Set(recomputed.concat(recorded))).sort(compareStrings);
	const origin = new Map();
	for (const id of union) {
		const inView = recomputedSet.has(id);
		const inRecord = recordedSet.has(id);
		origin.set(id, inView && inRecord ? 'verified' : (inRecord ? 'ledger-only' : 'view-only'));
	}

	const unbacked = kbUnbacked({ nodes: model.nodes, edges: coverageEdges });

	let status;
	if (!model.recordedGaps) status = 'unverified';
	else if (viewOnly.length === 0 && ledgerOnly.length === 0) status = 'verified';
	else status = 'mismatch';

	model.integrity = Object.freeze({
		status: status,
		viewOnly: Object.freeze(viewOnly),
		ledgerOnly: Object.freeze(ledgerOnly),
		orphans: Object.freeze(orphans),
		unbackedFacts: Object.freeze(Array.isArray(unbackedFacts) ? unbackedFacts.slice() : []),
	});
	model.coverageSets = Object.freeze({
		kbUnbacked: Object.freeze(unbacked),
		artifactUndocumented: Object.freeze(union),
		origin: origin,
	});
	return model.integrity;
}

const EMPTY_COVERAGE_SETS = Object.freeze({
	kbUnbacked: Object.freeze([]),
	artifactUndocumented: Object.freeze([]),
	origin: new Map(),
});


/* ==========================================================================
 * 7. Label shortening
 *
 * The stored name is never truncated -- that is the table's rule and this file
 * keeps it. What is shortened is a separate, presentation-only value used for
 * drawing and for the table's collapsed cell. The ACCESSIBLE NAME IS NEVER THE
 * SHORTENED FORM, so no screen-reader user is handed a truncated identifier, and
 * the text filter matches the stored name and the id and never this.
 *
 * Computed once at load over the FULL node set. If uniqueness were resolved over
 * the visible set instead, a label would change whenever a filter changed and
 * one node would be called two things in one session.
 *
 * Budget 32 characters -- a design choice, adjustable by the human visual gate,
 * not a measurement. Middle ellipsis, keeping head and tail, because the
 * distinguishing part of a path and of an anchor string is at the end.
 * ========================================================================== */

/**
 * The basis a kind's short label is shortened FROM.
 *
 * Prefix-read site 5: the in-repo/external split of an image. Only a path has a
 * basename, so this row needs to know where the artifact lives, and the Kind
 * cell cannot say.
 */
function labelBasis(node) {
	const body = node.id.slice(node.id.indexOf(':') + 1);
	switch (node.kind) {
		case 'document':
			return basename(node.name || body);
		case 'source-artifact':
			return basename(node.name || body);
		case 'image':
			return node.prefix === 'int' ? basename(node.name || body) : (node.name || body);
		case 'section':
		case 'fact':
			return afterSeparator(node.name);
		case 'concept':
			return node.name;
		case 'web-page':
			return node.name;
		default:
			return node.name;
	}
}

function basename(path) {
	const at = path.lastIndexOf('/');
	return at === -1 ? path : path.slice(at + 1);
}

/** The part of `<doc> § <heading>` after the separator; the whole string when
 *  there is no separator. */
function afterSeparator(name) {
	const at = name.indexOf(' § ');
	return at === -1 ? name : name.slice(at + 3);
}

/** Middle-ellipsise to a budget, keeping head and tail. */
function ellipsise(text, budget) {
	if (text.length <= budget) return text;
	if (budget <= 1) return '…';
	const keep = budget - 1;
	const head = Math.ceil(keep / 2);
	const tail = keep - head;
	return text.slice(0, head) + '…' + (tail > 0 ? text.slice(text.length - tail) : '');
}

/**
 * Assign every node its short label, resolving collisions to the point of
 * uniqueness.
 *
 * A basename is not unique in a real repository -- the same file name exists at
 * several paths -- so where a basis collides, the budget for that colliding set
 * is widened in fixed steps until the forms differ or the full basis is reached.
 * Should two FULL bases be equal, which the file's own rule permits since it
 * binds one name per id and not one id per name, the label becomes the ID, which
 * is unique by construction. So the procedure always terminates and always
 * yields distinct labels.
 */
function assignShortLabels(nodes) {
	// Ascending id order, so the outcome does not depend on the order the rows
	// happened to arrive in.
	const records = Array.from(nodes.values()).sort((a, b) => compareStrings(a.id, b.id));

	const bases = new Map();
	const budgets = new Map();
	for (const node of records) {
		bases.set(node.id, labelBasis(node) || node.id);
		budgets.set(node.id, LABEL_BUDGET);
	}

	const STEP = 8;
	for (;;) {
		const byLabel = new Map();
		for (const node of records) {
			const label = ellipsise(bases.get(node.id), budgets.get(node.id));
			if (!byLabel.has(label)) byLabel.set(label, []);
			byLabel.get(label).push(node);
		}

		// Widen only the budgets that still have room. Every iteration that does
		// not stop strictly increases at least one budget toward a bound, and the
		// bound is the basis length, so the loop runs a finite number of times.
		let widened = false;
		for (const group of byLabel.values()) {
			if (group.length < 2) continue;
			for (const node of group) {
				const room = bases.get(node.id).length;
				if (budgets.get(node.id) < room) {
					budgets.set(node.id, Math.min(room, budgets.get(node.id) + STEP));
					widened = true;
				}
			}
		}
		if (widened) continue;

		// Nothing left to widen, so whatever still collides has equal FULL bases
		// -- which the file's own rule permits, since it binds one name per id and
		// not one id per name. The id decides it, and an id is unique by
		// construction, so this pass cannot leave a collision behind.
		for (const group of byLabel.values()) {
			if (group.length < 2) continue;
			for (const node of group) {
				bases.set(node.id, node.id);
				budgets.set(node.id, node.id.length);
			}
		}
		break;
	}

	for (const node of records) node.shortLabel = ellipsise(bases.get(node.id), budgets.get(node.id));
}


/* ==========================================================================
 * 8. The open target
 *
 * Selecting a node and opening what it stands for are two different gestures, so
 * exploring the graph never navigates out of it by accident. This computes the
 * second one's target. It is pure, so it is testable with no page.
 *
 * The page sits beside the knowledge base's documents, two levels below the
 * repository root, and every target below is written from there.
 *
 * A web page's target is the file that RESOLVES the key, not a URL. The table
 * carries only the key by design -- the external-sources file remains the single
 * place that resolves it -- and the view has the table and nothing else, so it
 * holds a key it cannot resolve. Naming the resolving file is honest, is
 * mechanically checkable, and keeps the single-input rule intact.
 * ========================================================================== */

/**
 * @param {object} model GraphModel
 * @param {string} nodeId
 * @returns {string|null} the target, or null for an unknown id
 */
function openTargetFor(model, nodeId) {
	const node = model.nodes.get(nodeId);
	if (!node) return null;
	const body = node.id.slice(node.id.indexOf(':') + 1);

	switch (node.kind) {
		case 'document':
			return './' + node.kbDoc;
		case 'section': {
			const hash = body.indexOf('#');
			return './' + node.kbDoc + (hash === -1 ? '' : '#' + body.slice(hash + 1));
		}
		case 'fact':
			// The file, with NO fragment. A fact's fragment is a synthetic
			// identifier rather than a document anchor, so appending it would
			// emit a dead link on every fact node.
			return './' + node.kbDoc;
		case 'concept':
			return conceptTarget(model, node);
		case 'source-artifact':
			// Prefix-read site 5: a repository-relative identifier IS the path
			// this target needs.
			return '../../' + body;
		case 'image':
			return node.prefix === 'int' ? '../../' + body : externalTarget(body);
		case 'web-page':
			return externalTarget(body);
		default:
			return null;
	}
}

/** The external-sources file, anchored to the key's row where the key gives one. */
function externalTarget(key) {
	const slug = String(key).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
	return './external-sources.md' + (slug ? '#' + slug : '');
}

/**
 * A concept's defining document, else the highest-provenance mentioning
 * document. Ordering is declared over derived over inferred, tie-broken by
 * ascending document path so the choice is deterministic -- which the
 * projection's purity requires and which also means two runs never disagree.
 *
 * For a concept id qualified by a document, that qualifier IS the defining
 * document.
 */
function conceptTarget(model, node) {
	const body = node.id.slice(node.id.indexOf(':') + 1);
	const at = body.lastIndexOf('@');
	if (at !== -1) return './' + body.slice(at + 1);

	let best = null;
	for (const edge of model.edges) {
		let otherId = null;
		if (edge.sourceId === node.id) otherId = edge.targetId;
		else if (edge.targetId === node.id) otherId = edge.sourceId;
		if (!otherId) continue;
		const other = model.nodes.get(otherId);
		if (!other || other.kind !== 'document') continue;
		const rank = PROVENANCE_VALUES.indexOf(edge.provenance);
		const candidate = { rank: rank === -1 ? PROVENANCE_VALUES.length : rank, doc: other.kbDoc || otherId };
		if (!best || candidate.rank < best.rank || (candidate.rank === best.rank && compareStrings(candidate.doc, best.doc) < 0)) {
			best = candidate;
		}
	}
	return best ? './' + best.doc : null;
}


/* ==========================================================================
 * 9. project() -- the derived projection both renderings consume
 *
 * A pure function: same inputs, same output, no page access, no clock, no
 * randomness. It is also the accessibility model kept beside the visual one,
 * which is why the announced text and the per-mark labels are FIELDS on the
 * result rather than strings each rendering composes for itself. Three surfaces
 * reading one structure is what keeps them from drifting apart.
 *
 * The lens is interpreted EXACTLY ONCE, here. No rule about membership or
 * emphasis is left as a convention the two renderings are asked to honour: the
 * fold states the drawn set itself, and each edge's drawn endpoints are a field
 * rather than something a renderer resolves.
 *
 * Order of operations, because several steps interact and the order is the
 * contract:
 *
 *   1. admit nodes  -- kind, density, orphan toggle, text
 *   2. admit rows   -- category, provenance, text, and both endpoints admitted
 *   3. partition    -- the grouping dimension, over the admitted nodes
 *   4. fold         -- only the `document` dimension folds; record it
 *   5. focus        -- resolved THROUGH the fold, then a breadth-first ball
 *   6. state the drawn sets, the classes, the labels and the counts
 *
 * The fold is applied LAST and it wins. Selecting a section and then choosing
 * the `document` dimension moves the focus class to that section's document
 * rather than stranding it on a node neither rendering draws, and the selection
 * itself is untouched in the lens state, so expanding restores it exactly.
 * ========================================================================== */

/**
 * @param {object} graphModel
 * @param {object} lensState a full LensState record
 * @returns {object} ViewModel
 */
function project(graphModel, lensState) {
	const lens = lensState || INITIAL_LENS;
	const nodes = graphModel.nodes;
	const coverageSets = graphModel.coverageSets || EMPTY_COVERAGE_SETS;

	const kindFilter = new Set(lens['filters.kinds'] || []);
	const categoryFilter = new Set(lens['filters.categories'] || []);
	const provenanceFilter = new Set(lens['filters.provenance'] || []);
	const showOrphans = lens['filters.showOrphans'] !== false;
	const needle = String(lens['filters.text'] || '').toLowerCase();
	// task-034: the checkbox-hide axis. A VIEW filter, exactly like the three
	// above -- it never reaches `verifyCoverage`, which already ran, once, over
	// the whole model before this function was first called (`createStore`).
	// Hiding a node here can therefore never move a coverage badge or a gap
	// count; it only removes the node (and every row naming it) from what this
	// projection draws.
	const hiddenIds = new Set(lens['filters.hiddenIds'] || []);
	const density = clampInt(lens['density'], 1, 5, 1);
	const grouping = GROUPING_VALUES.indexOf(lens['grouping']) === -1 ? 'none' : lens['grouping'];
	const emphasisMode = EMPHASIS_VALUES.indexOf(lens['emphasis']) === -1 ? 'none' : lens['emphasis'];
	const depth = clampInt(lens['focus.depth'], 1, 6, 1);
	const expanded = new Set(lens['expandedGroups'] || []);

	// --- 1. Node admission ---------------------------------------------------
	// The text axis matches the stored name and the id, never the short label.
	// At NODE level it is that direct test; at ROW level it is the same test over
	// the row's four identifier and name cells, which is a disjunction over the
	// two endpoints -- so a reader who types a name sees the matched node IN ITS
	// CONTEXT rather than only edges between two matches.
	const matchesText = (node) => needle === ''
		|| node.id.toLowerCase().indexOf(needle) !== -1
		|| String(node.name).toLowerCase().indexOf(needle) !== -1;

	const admitted = new Set();
	for (const node of nodes.values()) {
		if (!kindFilter.has(node.kind)) continue;
		// task-034: the reader's own checkbox-hide. Checked first among the
		// per-node exclusions so it reads as what it is -- an explicit reader
		// choice -- rather than as a side effect of some other axis.
		if (hiddenIds.has(node.id)) continue;
		// An isolated node is precisely what the coverage lens and the gap
		// ledger exist to surface, so hiding one is a deliberate act and the
		// toggle defaults on.
		if (!showOrphans && node.degree === 0) continue;
		// Level 1 thins NOTHING. The level is stated as a level rather than as a
		// minimum degree exactly so that the level meant to exclude nothing does
		// not exclude a row-less node. Above level 1 the reader has asked for
		// less, and a row-less gap node thins like any other node -- the gap SET
		// is what is never thinned, and it is computed once per load.
		if (density > 1 && node.degree < density) continue;
		admitted.add(node.id);
	}

	// --- 2. Row admission ---------------------------------------------------
	const surviving = [];
	for (const edge of graphModel.edges) {
		if (!categoryFilter.has(edge.category)) continue;
		if (!provenanceFilter.has(edge.provenance)) continue;
		if (!admitted.has(edge.sourceId) || !admitted.has(edge.targetId)) continue;
		if (needle !== '') {
			const source = nodes.get(edge.sourceId);
			const target = nodes.get(edge.targetId);
			if (!matchesText(source) && !matchesText(target)) continue;
		}
		surviving.push(edge);
	}

	// The pre-fold visible set: every endpoint of a surviving row, every admitted
	// row-less node, and the selection. `foldable` is counted over THIS set, so
	// it does not move when a group is expanded.
	const preFold = new Set();
	for (const edge of surviving) { preFold.add(edge.sourceId); preFold.add(edge.targetId); }
	const rawFocus = lens['focus.nodeId'];
	const focusExists = typeof rawFocus === 'string' && nodes.has(rawFocus);
	for (const node of nodes.values()) {
		if (node.degree === 0 && admitted.has(node.id)) preFold.add(node.id);
	}
	if (focusExists && admitted.has(rawFocus)) preFold.add(rawFocus);

	// --- 3. Partition --------------------------------------------------------
	const groupKeyOf = buildGrouping(graphModel, grouping, surviving);
	const memberOf = new Map();
	for (const id of preFold) memberOf.set(id, groupKeyOf(nodes.get(id)));

	// --- 4. The fold ---------------------------------------------------------
	// A group folds only where it has a NODE HEAD, and under the `document`
	// dimension that is exactly the document groups, whose head is the document
	// itself. Its non-head members -- a section or a fact, and no other kind --
	// are the members the fold governs. No other branch has a node head: an
	// artifact or an in-repo image is a single-node group that is its own head,
	// and the category and external groups are keyed on a LABEL rather than on a
	// node, so every member of those is drawn.
	//
	// So only a section and a fact ever fold, and `document` is today the only
	// folding dimension. Every other yields no foldable member and an empty
	// record: one code path with an empty case, not a mode.
	const headOfGroup = new Map();
	if (grouping === 'document') {
		for (const id of preFold) {
			const node = nodes.get(id);
			if (node.kind === 'document') headOfGroup.set(memberOf.get(id), id);
		}
	}

	const foldableByGroup = new Map();
	for (const id of preFold) {
		const groupKey = memberOf.get(id);
		const head = headOfGroup.get(groupKey);
		if (head !== undefined && head !== id) foldableByGroup.set(groupKey, (foldableByGroup.get(groupKey) || 0) + 1);
	}

	const foldedInto = new Map();
	for (const id of Array.from(preFold).sort(compareStrings)) {
		const groupKey = memberOf.get(id);
		const head = headOfGroup.get(groupKey);
		if (head === undefined || head === id) continue;
		if (expanded.has(groupKey)) continue;
		foldedInto.set(id, head);
	}
	const resolve = (id) => (foldedInto.has(id) ? foldedInto.get(id) : id);

	// --- 5. Focus, resolved through the fold ---------------------------------
	const focusId = focusExists ? resolve(rawFocus) : null;
	let ball = null;
	let distance = null;
	if (focusId !== null && (preFold.has(rawFocus) || preFold.has(focusId) || nodes.has(focusId))) {
		const adjacency = new Map();
		for (const edge of surviving) {
			const a = resolve(edge.sourceId);
			const b = resolve(edge.targetId);
			if (a === b) continue;
			if (!adjacency.has(a)) adjacency.set(a, new Set());
			if (!adjacency.has(b)) adjacency.set(b, new Set());
			adjacency.get(a).add(b);
			adjacency.get(b).add(a);
		}
		// Depth is applied to the UNDIRECTED adjacency, because "what does this
		// change touch" is not a directional question. Direction stays visible
		// in the arrowheads.
		distance = new Map([[focusId, 0]]);
		let frontier = [focusId];
		for (let d = 1; d <= depth && frontier.length > 0; d += 1) {
			const next = [];
			for (const id of frontier) {
				for (const neighbour of (adjacency.get(id) || [])) {
					if (distance.has(neighbour)) continue;
					distance.set(neighbour, d);
					next.push(neighbour);
				}
			}
			frontier = next;
		}
		ball = new Set(distance.keys());
	}

	// --- 6. The drawn sets ---------------------------------------------------
	const visibleEdges = [];
	const edgeFold = new Map();
	for (const edge of surviving) {
		const a = resolve(edge.sourceId);
		const b = resolve(edge.targetId);
		if (ball && (!ball.has(a) || !ball.has(b))) continue;
		visibleEdges.push(edge);
		// A row whose two ends resolve to one node is collapsed: neither surface
		// draws or lists it. That is the accepted cost of synthesising no
		// aggregate edge -- a document's internal structure disappears INTO the
		// document rather than into a self-loop -- and it buys every surface the
		// ability to cite the row a claim came from, which an aggregate edge
		// would have no key for. Two rows between one pair of heads stay two
		// entries.
		edgeFold.set(edge.key, a === b ? 'collapsed' : Object.freeze({ sourceId: a, targetId: b }));
	}

	const drawnIds = new Set();
	for (const edge of visibleEdges) {
		const entry = edgeFold.get(edge.key);
		if (entry === 'collapsed') { drawnIds.add(resolve(edge.sourceId)); continue; }
		drawnIds.add(entry.sourceId);
		drawnIds.add(entry.targetId);
	}
	for (const node of nodes.values()) {
		if (node.degree !== 0 || !admitted.has(node.id)) continue;
		if (ball && !ball.has(resolve(node.id))) continue;
		drawnIds.add(resolve(node.id));
	}
	if (focusId !== null && admitted.has(rawFocus)) drawnIds.add(focusId);

	// The two halves of the fold's own invariant, applied in order so that they
	// cannot collide: EVERY HEAD THE RECORD NAMES IS DRAWN, and NO KEY OF IT IS.
	// A head is drawn because its folded member was going to be, which is what
	// makes the density level thin sub-document detail rather than the documents
	// it folds into: a head reached only through a folded member survives even
	// where its own degree is under the level. A head outside the focus ball is
	// not added, and its member is outside the ball too, so the two stay
	// consistent.
	for (const head of foldedInto.values()) {
		if (ball && !ball.has(head)) continue;
		drawnIds.add(head);
	}
	for (const member of foldedInto.keys()) drawnIds.delete(member);

	const visibleNodes = Array.from(drawnIds).sort(compareStrings).map((id) => nodes.get(id)).filter(Boolean);
	const visibleIds = new Set(visibleNodes.map((n) => n.id));

	// The published record carries only the members the fold actually removed
	// from the drawn set. A member whose head is not drawn was removed by a
	// filter rather than by the fold, so recording it here would name a
	// destination nobody can see.
	const publishedFold = new Map();
	for (const [member, head] of foldedInto) {
		if (visibleIds.has(head)) publishedFold.set(member, head);
	}

	// --- Groups, over the drawn members --------------------------------------
	const groups = buildGroups(grouping, graphModel, visibleNodes, memberOf, groupKeyOf, foldableByGroup, expanded);

	// --- Counts, commensurable by construction ------------------------------
	const drawnEdgeCount = visibleEdges.reduce((n, e) => n + (edgeFold.get(e.key) === 'collapsed' ? 0 : 1), 0);
	const counts = Object.freeze({
		nodes: visibleNodes.length,
		edges: drawnEdgeCount,
		hiddenNodes: nodes.size - visibleNodes.length,
		hiddenEdges: graphModel.rowCount - drawnEdgeCount,
	});

	// --- Emphasis ------------------------------------------------------------
	const kbUnbackedSet = new Set(coverageSets.kbUnbacked);
	const artifactGapSet = new Set(coverageSets.artifactUndocumented);
	const chainKeys = new Set();
	if (emphasisMode === 'provenance-chain') {
		for (const edge of visibleEdges) {
			if (edgeFold.get(edge.key) === 'collapsed') continue;
			if (isChainRow(nodes, edge)) chainKeys.add(edge.key);
		}
	}
	const chainNodes = new Set();
	for (const edge of visibleEdges) {
		if (!chainKeys.has(edge.key)) continue;
		const entry = edgeFold.get(edge.key);
		if (entry === 'collapsed') continue;
		chainNodes.add(entry.sourceId);
		chainNodes.add(entry.targetId);
	}

	const nodeEmphasis = new Map();
	for (const node of visibleNodes) {
		nodeEmphasis.set(node.id, classifyNode(node, {
			focusId: focusId,
			distance: distance,
			emphasisMode: emphasisMode,
			kbUnbackedSet: kbUnbackedSet,
			artifactGapSet: artifactGapSet,
			chainNodes: chainNodes,
		}));
	}

	const edgeEmphasis = new Map();
	for (const edge of visibleEdges) {
		if (edgeFold.get(edge.key) === 'collapsed') continue;
		if (emphasisMode === 'provenance-chain') edgeEmphasis.set(edge.key, chainKeys.has(edge.key) ? 'chain' : 'dimmed');
		else edgeEmphasis.set(edge.key, 'normal');
	}

	// --- Labels and encodings ------------------------------------------------
	// Keyed over the drawn nodes AND the folded members, so a group disclosure
	// and a "folded into" affordance can name a member without reaching into the
	// model. Emphasis is NOT keyed that way: no class may land on a node neither
	// rendering draws.
	const labelledIds = Array.from(new Set(Array.from(visibleIds).concat(Array.from(publishedFold.keys())))).sort(compareStrings);
	const nodeLabels = new Map();
	const nodeShortLabels = new Map();
	const nodeEncoding = new Map();
	for (const id of labelledIds) {
		const node = nodes.get(id);
		if (!node) continue;
		// The extra fact about a row-less node -- that it has no recorded
		// relationship at all, the more severe of the two coverage findings --
		// is appended to the ACCESSIBLE NAME. That is already the name on every
		// surface, so both renderings pick the marker up through machinery they
		// already have and neither can render it differently from the other. It
		// is text and never colour, so it survives forced-colours mode, and it
		// reaches the announced text, where a purely visual "this mark has no
		// lines attached" would reach nobody using a screen reader. It is NOT
		// appended to the short label, whose whole purpose is to fit a budget.
		nodeLabels.set(id, node.degree === 0 ? node.name + ' — no recorded relationships' : node.name);
		nodeShortLabels.set(id, node.shortLabel);
		const encoding = KIND_ENCODING[node.kind];
		nodeEncoding.set(id, Object.freeze({ colourToken: encoding.colourToken, glyph: encoding.glyph }));
	}

	const edgeEncoding = new Map();
	for (const edge of visibleEdges) {
		const encoding = CATEGORY_ENCODING[edge.category];
		edgeEncoding.set(edge.key, Object.freeze({
			colourToken: encoding.colourToken,
			lineStyle: encoding.lineStyle,
			arrowhead: !edge.symmetric,
		}));
	}

	// --- Narration -----------------------------------------------------------
	const narration = narrate(graphModel, lens, {
		counts: counts,
		grouping: grouping,
		emphasisMode: emphasisMode,
		focusNode: focusId === null ? null : nodes.get(focusId),
		focusIsolated: focusId !== null && nodes.has(focusId) && nodes.get(focusId).degree === 0,
		categoryFilter: categoryFilter,
		kindFilter: kindFilter,
		provenanceFilter: provenanceFilter,
		needle: lens['filters.text'] || '',
		showOrphans: showOrphans,
		density: density,
		depth: depth,
	});

	return {
		visibleEdges: visibleEdges,
		visibleNodes: visibleNodes,
		groups: groups,
		foldedInto: publishedFold,
		edgeFold: edgeFold,
		nodeEmphasis: nodeEmphasis,
		edgeEmphasis: edgeEmphasis,
		nodeLabels: nodeLabels,
		nodeShortLabels: nodeShortLabels,
		nodeEncoding: nodeEncoding,
		edgeEncoding: edgeEncoding,
		coverageGaps: Object.freeze({
			kbUnbacked: coverageSets.kbUnbacked,
			artifactUndocumented: coverageSets.artifactUndocumented,
		}),
		coverageOrigin: coverageSets.origin,
		coverage: graphModel.coverage,
		lensSummary: narration.summary,
		announcement: narration.announcement,
		canvasAlt: narration.canvasAlt,
		revision: 0,
		counts: counts,
	};
}

function clampInt(value, min, max, fallback) {
	const n = typeof value === 'number' && isFinite(value) ? Math.round(value) : fallback;
	return n < min ? min : (n > max ? max : n);
}

/**
 * Is this row on a cross-side chain?
 *
 * Prefix-read site 3, and the one place a prefix is the RIGHT key. The lens's
 * subject is the chain from knowledge-base content out to source and external
 * origins, and "which side does this identifier come from" is exactly what a
 * prefix names and no kind does. The vocabulary makes the same distinction from
 * its own end: a lineage relation was split out of provenance precisely so that
 * document-to-document supersession does not enter a lens whose whole point is
 * the cross-side chain.
 *
 * The chain is the DIRECT cross-side row: one endpoint spelled on the
 * knowledge-base side, the other a source artifact, an image or a web page. That
 * is a choice, and it is stated as one -- a multi-hop reading would need a path
 * search whose result is not a per-row class, and the requirement's own wording
 * is the cross-side chain rather than every row reachable on one.
 */
function isChainRow(nodes, edge) {
	const source = nodes.get(edge.sourceId);
	const target = nodes.get(edge.targetId);
	if (!source || !target) return false;
	const originKinds = FACT_BACKING_KINDS;
	return (source.prefix === 'kb' && originKinds.has(target.kind))
		|| (target.prefix === 'kb' && originKinds.has(source.kind));
}

/**
 * One class per node, as a TOTAL PRECEDENCE over five values. Two inputs assign
 * classes and the map holds one class per id, so an order is required rather
 * than optional, and the focus takes it.
 *
 *   1. the fold-resolved selection is `focus`, whatever else applies to it;
 *   2. else, under the coverage lens, its gap class. The two gap classes are
 *      keyed on DISJOINT kinds, so they cannot contend and no order between them
 *      is needed;
 *   3. else `dimmed`, where the active lens or the selection dims it;
 *   4. else `normal`.
 *
 * Ranking the focus first loses no fact, because both are published
 * independently: the gap sets are their own field, computed once per load, and
 * the selection is in the lens state. A surface wanting both draws the gap
 * marker from the set and the focus treatment from here. The opposite order left
 * no marked id at all when a gap node was selected, which broke the reveal and
 * the badge that a selection is supposed to drive.
 */
function classifyNode(node, ctx) {
	if (ctx.focusId !== null && node.id === ctx.focusId) return 'focus';
	if (ctx.emphasisMode === 'coverage') {
		if (ctx.kbUnbackedSet.has(node.id)) return 'kb-unbacked';
		if (ctx.artifactGapSet.has(node.id)) return 'artifact-undocumented';
		return 'dimmed';
	}
	if (ctx.emphasisMode === 'provenance-chain') return ctx.chainNodes.has(node.id) ? 'normal' : 'dimmed';
	// A selection highlights its neighbourhood and dims the rest. Within the
	// drawn ball "the rest" is everything beyond the immediate neighbourhood, so
	// a node two or more hops out is dimmed. A design choice at the ring
	// boundary; the requirement fixes only that a selection dims something.
	if (ctx.distance && ctx.distance.get(node.id) > 1) return 'dimmed';
	return 'normal';
}


/* ==========================================================================
 * 10. Grouping
 * ========================================================================== */

/**
 * The group-key function for a dimension.
 *
 * The `document` dimension is KIND-DEPENDENT rather than a bare document key,
 * and it has to be: a document key is null for a concept and for every artifact,
 * so keying on it would put every artifact and every concept in one ungrouped
 * bucket, which is the opposite of what this dimension is for.
 *
 * This defines the dimension itself, not a behaviour a preset adds. A preset is
 * a frozen value patch and nothing else, so a dimension whose meaning depended
 * on how the reader arrived would break the one mechanism that keeps the two
 * renderings agreeing.
 */
function buildGrouping(graphModel, grouping, surviving) {
	if (grouping === 'none') return () => 'all';
	if (grouping === 'node-kind') return (node) => node.kind;

	if (grouping === 'document') {
		return (node) => {
			switch (node.kind) {
				// Both are document-scoped by grammar, so the document part is
				// populated and the fold is exact.
				case 'section':
				case 'fact':
					return node.kbDoc || EXTERNAL_GROUP;
				case 'document':
					return node.kbDoc || node.id;
				// Its own single-node group, as its own head. Prefix-read site 4:
				// this row and the last need to know where the artifact lives,
				// and the Kind cell cannot say.
				case 'source-artifact':
					return node.id;
				case 'image':
					return node.prefix === 'int' ? node.id : EXTERNAL_GROUP;
				// A concept has no single parent document by construction, so
				// there is no document to fold into; it groups by the category of
				// the relationship it participates in.
				case 'concept':
					return conceptCategory(graphModel, surviving, node);
				case 'web-page':
					return EXTERNAL_GROUP;
				default:
					return EXTERNAL_GROUP;
			}
		};
	}

	// The two edge-derived dimensions. A node with no surviving row goes to a
	// dedicated group listed last: these dimensions are derived from rows and
	// such a node has none, so a dedicated group neither invents a value nor
	// drops the node.
	const byNode = new Map();
	const rank = grouping === 'provenance'
		? (edge) => PROVENANCE_VALUES.indexOf(edge.provenance)
		: null;
	for (const edge of surviving) {
		const value = grouping === 'provenance' ? edge.provenance : edge.category;
		const order = rank ? rank(edge) : 0;
		for (const id of [edge.sourceId, edge.targetId]) {
			const held = byNode.get(id);
			if (!held || order < held.order) byNode.set(id, { value: value, order: order });
		}
	}
	return (node) => {
		const held = byNode.get(node.id);
		return held ? held.value : NO_RELATIONSHIPS_GROUP;
	};
}

/**
 * The category a concept groups under when it participates in more than one.
 *
 * The requirement is silent, so this is an author decision and is stated as one:
 * the category of its highest-provenance incident row, declared over derived
 * over inferred, tie-broken by the category's position in the vocabulary's
 * declared order. It reuses the provenance ordering the open target already
 * fixes, so the view has one precedence rule rather than two, and it is total
 * and deterministic -- which the projection's purity requires. Left to fall out,
 * an implementation would pick arbitrarily, because "group by relationship
 * category" is not single-valued for a merged concept.
 */
function conceptCategory(graphModel, surviving, node) {
	let best = null;
	for (const edge of surviving) {
		if (edge.sourceId !== node.id && edge.targetId !== node.id) continue;
		const provenanceRank = PROVENANCE_VALUES.indexOf(edge.provenance);
		const candidate = {
			provenanceRank: provenanceRank === -1 ? PROVENANCE_VALUES.length : provenanceRank,
			categoryRank: graphModel.categories.indexOf(edge.category),
			category: edge.category,
		};
		if (!best
			|| candidate.provenanceRank < best.provenanceRank
			|| (candidate.provenanceRank === best.provenanceRank && candidate.categoryRank < best.categoryRank)) {
			best = candidate;
		}
	}
	return best ? best.category : NO_RELATIONSHIPS_GROUP;
}

/**
 * The group list, in a deterministic order per dimension.
 *
 * `foldable` is the count the fold GOVERNS and is independent of expansion,
 * which is what keeps the disclosure's presence off a count that expanding would
 * drive to zero -- the defect that made expanding a group delete the only
 * control able to collapse it again. `expanded` is the aria-expanded value
 * verbatim, so no consumer derives it.
 */
function buildGroups(grouping, graphModel, visibleNodes, memberOf, groupKeyOf, foldableByGroup, expandedSet) {
	if (grouping === 'none') {
		return Object.freeze([Object.freeze({
			key: 'all',
			label: 'All nodes',
			nodeIds: Object.freeze(visibleNodes.map((n) => n.id)),
			foldable: 0,
			expanded: false,
		})]);
	}

	const drawnByGroup = new Map();
	for (const node of visibleNodes) {
		const key = memberOf.has(node.id) ? memberOf.get(node.id) : groupKeyOf(node);
		if (!drawnByGroup.has(key)) drawnByGroup.set(key, []);
		drawnByGroup.get(key).push(node.id);
	}
	// A group whose every member folded away still exists, and its foldable
	// count is what its disclosure is keyed on.
	for (const key of foldableByGroup.keys()) if (!drawnByGroup.has(key)) drawnByGroup.set(key, []);

	const keys = Array.from(drawnByGroup.keys()).sort((a, b) => {
		const ra = groupRank(grouping, graphModel, a);
		const rb = groupRank(grouping, graphModel, b);
		return ra === rb ? compareStrings(a, b) : ra - rb;
	});

	return Object.freeze(keys.map((key) => {
		const foldable = foldableByGroup.get(key) || 0;
		return Object.freeze({
			key: key,
			label: key,
			nodeIds: Object.freeze(drawnByGroup.get(key).slice().sort(compareStrings)),
			foldable: foldable,
			expanded: foldable > 0 && expandedSet.has(key),
		});
	}));
}

/** Sort rank for a group key, so the group list is deterministic and reads in the
 *  order the dimension's own vocabulary declares. */
function groupRank(grouping, graphModel, key) {
	if (key === NO_RELATIONSHIPS_GROUP) return 9000;
	if (grouping === 'node-kind') {
		const at = Object.keys(KIND_ENCODING).indexOf(key);
		return at === -1 ? 8000 : at;
	}
	if (grouping === 'provenance') {
		const at = PROVENANCE_VALUES.indexOf(key);
		return at === -1 ? 8000 : at;
	}
	if (grouping === 'relation-category') {
		const at = graphModel.categories.indexOf(key);
		return at === -1 ? 8000 : at;
	}
	// The `document` dimension: document groups, then own-head single-node
	// groups, then the concept category groups, then the external group last.
	if (key === EXTERNAL_GROUP) return 8500;
	if (graphModel.categories.indexOf(key) !== -1) return 5000 + graphModel.categories.indexOf(key);
	if (key.indexOf(':') !== -1) return 3000;
	return 1000;
}


/* ==========================================================================
 * 11. Narration -- the text every surface shares
 * ========================================================================== */

function narrate(graphModel, lens, ctx) {
	const lensName = lens['preset'] ? PRESET_LABELS[lens['preset']] + ' lens' : 'No preset lens';
	const parts = [lensName];

	const totalCategories = graphModel.categories.length;
	if (ctx.categoryFilter.size < totalCategories) parts.push('filtered to ' + ctx.categoryFilter.size + ' of ' + totalCategories + ' categories');
	const totalKinds = Object.keys(KIND_ENCODING).length;
	if (ctx.kindFilter.size < totalKinds) parts.push('filtered to ' + ctx.kindFilter.size + ' of ' + totalKinds + ' node kinds');
	if (ctx.provenanceFilter.size < PROVENANCE_VALUES.length) parts.push('filtered to ' + ctx.provenanceFilter.size + ' of ' + PROVENANCE_VALUES.length + ' provenance values');
	if (ctx.needle !== '') parts.push('matching "' + ctx.needle + '"');
	if (!ctx.showOrphans) parts.push('isolated nodes hidden');
	if (ctx.grouping !== 'none') parts.push('grouped by ' + ctx.grouping);
	parts.push('density ' + ctx.density + ' of 5');
	if (ctx.focusNode) {
		parts.push('focused on ' + ctx.focusNode.name + ' at depth ' + ctx.depth);
		if (ctx.focusIsolated) parts.push('no recorded relationships');
	}

	const summary = parts.join(', ') + '.';
	const shown = ctx.counts.nodes + ' of ' + (ctx.counts.nodes + ctx.counts.hiddenNodes) + ' nodes and '
		+ ctx.counts.edges + ' of ' + (ctx.counts.edges + ctx.counts.hiddenEdges) + ' relationships shown';

	return {
		summary: summary,
		announcement: summary + ' ' + shown + '.',
		canvasAlt: 'Relationship graph. ' + shown + '. ' + summary
			+ ' The same relationships are listed as text in the relationship table below.',
	};
}


/* ==========================================================================
 * 12. The store -- the only interface the two renderings hold
 * ========================================================================== */

/**
 * @param {object} graphModel
 * @param {object} [initialLens]
 * @param {{reducedMotion?: boolean, forcedColours?: boolean}} [preferences]
 * @returns {object} Store
 */
function createStore(graphModel, initialLens, preferences) {
	// Verify the recomputed gap set against the record here, before any
	// subscriber exists, because it is a property of the data rather than of the
	// lens. The loader already computed it -- it needs the row-less set in order
	// to materialise those nodes -- so this call is the verification point, not a
	// second computation.
	verifyCoverage(graphModel);

	let lens = normaliseLens(initialLens || INITIAL_LENS);
	let viewModel = withRevision(project(graphModel, lens), 1);
	let revision = 1;

	// The two system preferences live HERE and in neither record. A preference is
	// not lens state and not a function of the lens, and the projection is pure
	// with no page access, so a field on either record would make a preference a
	// product of a projection it is not. The shell detects each, passes the pair
	// in, and this publishes it: one route both renderings read, the page read
	// left where every other one is, and a flip reprojecting nothing.
	let prefs = Object.freeze({
		reducedMotion: !!(preferences && preferences.reducedMotion),
		forcedColours: !!(preferences && preferences.forcedColours),
	});

	const listeners = new Set();
	const prefListeners = new Set();

	function notify(changedKeys) {
		for (const listener of Array.from(listeners)) listener(viewModel, freezeLens(lens), changedKeys);
	}

	return {
		getViewModel() { return viewModel; },
		getLens() { return freezeLens(lens); },
		getGraphModel() { return graphModel; },

		getPreferences() { return prefs; },
		setPreferences(patch) {
			const next = Object.freeze({
				reducedMotion: patch && 'reducedMotion' in patch ? !!patch.reducedMotion : prefs.reducedMotion,
				forcedColours: patch && 'forcedColours' in patch ? !!patch.forcedColours : prefs.forcedColours,
			});
			if (next.reducedMotion === prefs.reducedMotion && next.forcedColours === prefs.forcedColours) return prefs;
			prefs = next;
			// No reprojection, no revision bump and no lens notification: nothing
			// about membership or emphasis depends on a preference.
			for (const listener of Array.from(prefListeners)) listener(prefs);
			return prefs;
		},
		subscribePreferences(listener) {
			prefListeners.add(listener);
			return () => { prefListeners.delete(listener); };
		},

		setLens(patch) {
			const changed = [];
			const next = Object.assign({}, lens);
			for (const key of Object.keys(patch || {})) {
				if (LENS_KEYS.indexOf(key) === -1) continue;
				next[key] = patch[key];
				changed.push(key);
			}
			lens = normaliseLens(next);
			revision += 1;
			viewModel = withRevision(project(graphModel, lens), revision);
			notify(Object.freeze(changed));
			return viewModel;
		},

		applyPreset(name) {
			const patch = PRESETS[name];
			if (!patch) return viewModel;
			const next = Object.assign({}, lens, patch, { 'preset': name });
			lens = normaliseLens(next);
			revision += 1;
			viewModel = withRevision(project(graphModel, lens), revision);
			notify(Object.freeze(Object.keys(patch).concat(['preset'])));
			return viewModel;
		},

		openTarget(nodeId) { return openTargetFor(graphModel, nodeId); },

		subscribe(listener) {
			listeners.add(listener);
			return () => { listeners.delete(listener); };
		},
	};
}

/** Stamp the monotonic revision onto a fresh projection. */
function withRevision(viewModel, revision) {
	viewModel.revision = revision;
	return Object.freeze(viewModel);
}

/** Fill in any absent member from the initial record, so the projection always
 *  receives a total LensState however partial a caller's starting record was. */
function normaliseLens(candidate) {
	const out = {};
	for (const key of LENS_KEYS) {
		out[key] = Object.prototype.hasOwnProperty.call(candidate, key) ? candidate[key] : INITIAL_LENS[key];
	}
	return out;
}

/** A frozen copy: mutating what a consumer is handed does nothing, which is what
 *  keeps every write on the one path through setLens. */
function freezeLens(lens) {
	return Object.freeze(Object.assign({}, lens));
}


/* ==========================================================================
 * 13. Hidden-node selection persistence (task-034)
 *
 * THE ONE EXCEPTION TO THIS FILE'S OWN HEADER CLAIM OF TOUCHING NO STORAGE.
 * The checkbox-hide selection has no home in `relationships.md` -- it is
 * reader-local, not data -- and it has to reach two different pages (this
 * page's table, which WRITES it, and the drawing rendering's page, which only
 * READS it) through one shared key, or the two could disagree about what a
 * reader hid, or a re-open of one page could silently forget what the other
 * just remembered. Putting the one key algorithm and the one read/write pair
 * here, rather than authoring it a second time in each page's own shell, is
 * the same "no second copy of the same knowledge" rule the rest of this file
 * follows -- see the header's own note on `RELATION_CATEGORY`.
 *
 * Three small functions are the whole of the exception:
 *   - `hiddenSelectionKey` is pure string arithmetic, no storage read at all.
 *   - `readHiddenSelection`/`writeHiddenSelection` touch `localStorage`, each
 *     guarded in a `try`/`catch` exactly like `lightbox.js`'s own theme
 *     persistence (the one other place this page family remembers anything
 *     across a reload) -- a private-browsing tab or a `localStorage`-less
 *     embedding degrades to "nothing remembered", never to a thrown error.
 *   - `resolveHiddenSelection` is pure (no storage, no page): it validates a
 *     raw stored list against the CURRENT model, which is what lets it be
 *     tested with no `localStorage` and no `window` at all.
 * ========================================================================== */

/**
 * The storage key for a page's checkbox-hide selection, scoped to the
 * DIRECTORY the page was opened from rather than to its own filename.
 *
 * That scope, and not the full path, is what the graph page and this page's
 * table SHARE: `graph.html` and `table.html` are siblings written into the
 * same generated `.aid/knowledge/` directory by the same run, so one reader
 * action on either page has to be visible on the other. Scoping to the full
 * path would put each page's own selection under a different key and the two
 * pages could never agree; scoping to the directory is also what keeps two
 * DIFFERENT projects' pages from colliding even where a browser gives every
 * `file://` page the same static origin (`null`), because the key itself
 * carries the directory rather than relying on the browser's own origin
 * partitioning.
 *
 * @param {string} pathname e.g. `document.location.pathname`
 * @returns {string}
 */
function hiddenSelectionKey(pathname) {
	const path = typeof pathname === 'string' ? pathname : '';
	const dir = path.slice(0, path.lastIndexOf('/') + 1);
	return 'aid-graph-hidden::' + dir;
}

/**
 * Read the raw stored selection for the CURRENT page (`location`/`localStorage`
 * read from the ambient global, never passed in -- there is exactly one real
 * page this ever runs against). Absence is never an error: a page opened for
 * the first time, a private-browsing tab, or an embedding with no
 * `localStorage` at all every read the same way, as "nothing stored yet".
 *
 * @returns {string[]|null} the raw list, unvalidated against any model --
 *          `resolveHiddenSelection` does that -- or `null` when there is
 *          nothing to restore
 */
function readHiddenSelection() {
	try {
		if (typeof localStorage === 'undefined' || typeof location === 'undefined') return null;
		const raw = localStorage.getItem(hiddenSelectionKey(location.pathname));
		if (!raw) return null;
		const parsed = JSON.parse(raw);
		return Array.isArray(parsed) ? parsed.filter((id) => typeof id === 'string') : null;
	} catch (error) {
		return null;
	}
}

/**
 * Write the selection for the CURRENT page, or clear it when given an empty
 * list -- so "the reader unhid everything" is recorded as ABSENCE rather than
 * as an empty array a later reader of the raw key could mistake for "nothing
 * has ever been hidden here".
 *
 * @param {string[]} ids
 */
function writeHiddenSelection(ids) {
	try {
		if (typeof localStorage === 'undefined' || typeof location === 'undefined') return;
		const key = hiddenSelectionKey(location.pathname);
		if (!Array.isArray(ids) || ids.length === 0) localStorage.removeItem(key);
		else localStorage.setItem(key, JSON.stringify(ids));
	} catch (error) { /* storage unavailable -- the session still works, just unremembered */ }
}

/**
 * Resolve a raw stored selection against the CURRENT model. Pure -- no
 * storage, no page -- so it is testable with neither.
 *
 * Three rules, all from task-034's DETAIL.md, and none of them fatal:
 *
 *   1. an id the model no longer has (the extraction changed, a file was
 *      renamed) is DROPPED, not fatal -- the rest of the selection still
 *      restores;
 *   2. a selection that would hide EVERY node in the model restores NOTHING
 *      and says so (`suppressed: true`) -- an empty-looking graph that is
 *      actually just fully filtered reads as broken, which is worse than an
 *      unfiltered one;
 *   3. an empty or absent stored selection is not a restore at all -- the
 *      common case, a page with nothing ever hidden on it.
 *
 * @param {object} graphModel
 * @param {string[]|null} storedIds
 * @returns {{hiddenIds: string[], dropped: string[], suppressed: boolean}}
 */
function resolveHiddenSelection(graphModel, storedIds) {
	if (!Array.isArray(storedIds) || storedIds.length === 0) {
		return { hiddenIds: [], dropped: [], suppressed: false };
	}
	const kept = [];
	const dropped = [];
	for (const id of storedIds) {
		if (graphModel.nodes.has(id)) kept.push(id);
		else dropped.push(id);
	}
	const totalNodes = graphModel.nodes.size;
	if (totalNodes > 0 && kept.length >= totalNodes) {
		return { hiddenIds: [], dropped: dropped, suppressed: true };
	}
	return { hiddenIds: kept, dropped: dropped, suppressed: false };
}


/* ==========================================================================
 * 14. What this file publishes
 *
 * Declared here as one list rather than scattered across the file, so a reader
 * can see the whole surface at once. In the page these are plain declarations in
 * a shared module scope; the export keyword makes the same file loadable by a
 * test process with no change to a byte of behaviour.
 * ========================================================================== */

export {
	// The table and the notes
	parseRelationships,
	parseCoverageNotes,
	GraphLoadError,
	HEADER_LITERAL,
	// The projection and the store
	project,
	createStore,
	// The control state
	INITIAL_LENS,
	LENS_KEYS,
	FILTER_KEYS,
	PRESETS,
	PRESET_LABELS,
	// Hidden-node selection persistence (task-034)
	hiddenSelectionKey,
	readHiddenSelection,
	writeHiddenSelection,
	resolveHiddenSelection,
	// The vocabularies and the palette
	KIND_ENCODING,
	KIND_PREFIXES,
	PROVENANCE_VALUES,
	CATEGORY_ENCODING,
	GROUPING_VALUES,
	EMPHASIS_VALUES,
	LABEL_BUDGET,
	NO_RELATIONSHIPS_GROUP,
	EXTERNAL_GROUP,
	// Helpers a rendering or a test needs
	openTargetFor,
	distinctCategories,
};
