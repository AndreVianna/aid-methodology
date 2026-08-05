// coverage-predicate.mjs -- the one definition of the knowledge-base coverage
// predicate, executed in two runtimes over the same bytes.
//
// Purpose:
//   Decide, from a relationship table alone, which enumerated source artifacts
//   no knowledge-base node accounts for -- the class the gap ledger reports and
//   the class the graph view's Coverage lens highlights -- and, for the browser
//   only, which knowledge-base claims no project source backs. The ledger and
//   the lens are required to agree; they agree structurally because both call
//   these functions, rather than because two prose readings happen to match.
//
// Provides:
//   RELATION_CATEGORY                     frozen relation -> category over all
//                                         57 core vocabulary entries (31 pairs)
//   COVERAGE_BEARING                      frozen Set of the 4 relation names
//                                         whose definition asserts coverage
//   isCovered(nodeId, edges)              -> boolean
//   detectArtifactGaps({nodeIds, edges})  -> string[]  (sorted, unique)
//   kbUnbacked({nodes, edges})            -> string[]  (sorted, unique)
//
// Usage (Node, at generate time):
//   the sibling gap detector loads this module by a plain relative specifier,
//   binds `detectArtifactGaps` and `RELATION_CATEGORY` from it, and calls
//   `detectArtifactGaps({ nodeIds, edges })` with the enumerated inventory and
//   the parsed table. The `.mjs` extension alone makes that resolve, so no
//   package marker file is needed in this directory or above it.
//
// Usage (browser, at load time):
//   this file is inlined byte-identically as the first segment of the page's
//   single <script type="module">. The view's own files share that one module
//   scope and reference these exports directly, loading nothing themselves.
//
// Exit codes: none. This is a pure library -- it reads no file, writes no file,
//   touches no global, and neither exits nor throws. Every input arrives as
//   plain data from the caller; detecting and reporting a malformed input is
//   the caller's job, because only the caller knows how its runtime fails.
//
// Five boundary rules this file obeys, because two runtimes load the same bytes:
//   1. it loads nothing -- no module specifier of any kind, bare, relative or
//      built-in. Node reads this file as-is and the browser inlines it as-is;
//      a single loading statement would break one of the two;
//   2. it touches no host global -- no page or frame object, no cross-realm
//      global, no network call, no timer and no event -- so a Node process
//      needs no DOM shim and nothing can behave differently between runtimes;
//   3. only `export const` / `export function` at top level -- no export list
//      and no default export, so every declaration stays legal (and inert)
//      inside an inline module block;
//   4. every input and output is plain data -- arrays, objects, Map, Set --
//      never a path, a handle or a stream: all I/O stays in the callers;
//   5. no install-tree path reference and none of the three filename
//      placeholders, in code or in comments. The profile generator text-
//      processes this extension, so a path reference here would make each
//      rendered copy differ from this one and break the byte-identity gate.

// ---------------------------------------------------------------------------
// Shapes
// ---------------------------------------------------------------------------

/**
 * A node's class, from the `Kind` column of the relationship table. A closed
 * seven-value enum; `Kind` is data, never recovered by parsing an id.
 *
 * @typedef {('document'|'concept'|'fact'|'section'|'source-artifact'|'image'|'web-page')} Kind
 */

/**
 * One relationship-table row, reduced to the six cells this predicate reads.
 *
 * Both runtimes build this shape from the same final, post-extraction table, so
 * the predicate has one behaviour in both: the Node side reads the table file,
 * the browser side reads the table embedded in the page.
 *
 * The two `*Kind` cells are required. Condition 2 of the predicate is stated
 * over the endpoint's kind rather than over its id prefix, so an edge that
 * carries no kind for an endpoint can never satisfy it -- such an edge is
 * silently non-covering rather than an error, and a caller that omits the kinds
 * will see every candidate reported as a gap.
 *
 * @typedef {object} CoverageEdge
 * @property {string} sourceId    id in the row's `Source Id` cell
 * @property {Kind} sourceKind    the row's `Source Kind` cell
 * @property {string} targetId    id in the row's `Target Id` cell
 * @property {Kind} targetKind    the row's `Target Kind` cell
 * @property {string} s2t         the row's `S2T Relation` cell, read source -> target
 * @property {string} t2s         the row's `T2S Relation` cell, read target -> source
 */

/**
 * A node record, reduced to the two fields `kbUnbacked` reads. The browser's
 * full node record is a superset of this and may be passed unchanged.
 *
 * @typedef {object} CoverageNode
 * @property {string} id
 * @property {Kind} kind
 */

// ---------------------------------------------------------------------------
// The core relation vocabulary
// ---------------------------------------------------------------------------

/**
 * Every entry of the closed core relation vocabulary, mapped to the one
 * category it belongs to.
 *
 * Both directions of every asymmetric pair are keys, because a table row is
 * emitted in a normalised orientation and either direction may land in the
 * `S2T Relation` cell. 31 pairs -- 26 asymmetric (two entries each) and 5
 * symmetric (one entry each) -- give 57 entries across 14 categories.
 *
 * Authored here rather than beside the view model for three reasons: the
 * constant is frozen build-time data with no runtime state to be near; both
 * runtimes already reach this file, so no dependency edge is added; and the
 * view model is browser-only, which makes it the wrong home for data the
 * pipeline also needs. Keeping it here is also what makes the containment
 * `COVERAGE_BEARING` is subject to a check inside a single file.
 *
 * Declaration order is the vocabulary's declared category order, so a consumer
 * that needs the category list in that order may take the distinct values in
 * iteration order. No result computed in this file depends on key order.
 *
 * @type {Readonly<Record<string, string>>}
 */
export const RELATION_CATEGORY = Object.freeze({
	// structure -- one node is a constituent, a declared member, or an ordered
	// neighbour of the other.
	'has-part': 'structure',
	'part-of': 'structure',
	'has-member': 'structure',
	'member-of': 'structure',
	'precedes': 'structure',
	'follows': 'structure',

	// taxonomy -- one concept is a generalisation, a specialisation, or an
	// associate of another concept.
	'broader-than': 'taxonomy',
	'narrower-than': 'taxonomy',
	'related-concept': 'taxonomy',

	// definition -- one node introduces or exemplifies the term the other is.
	'defines': 'definition',
	'defined-by': 'definition',
	'exemplifies': 'definition',
	'exemplified-by': 'definition',

	// documentation -- one node records or names facts about the other.
	'documents': 'documentation',
	'documented-by': 'documentation',
	'mentions': 'documentation',
	'mentioned-in': 'documentation',

	// evidence -- one node is cited as the checkable support for a claim in
	// the other.
	'cites': 'evidence',
	'cited-by': 'evidence',
	'cites-as-evidence': 'evidence',
	'cited-as-evidence-by': 'evidence',

	// provenance -- one node was derived from, generated from, or reproduced
	// from the other.
	'derived-from': 'provenance',
	'source-of': 'provenance',
	'generated-by': 'provenance',
	'generates': 'provenance',
	'quotes': 'provenance',
	'quoted-in': 'provenance',

	// lineage -- one node is a later version of, or a replacement for, the other.
	'supersedes': 'lineage',
	'superseded-by': 'lineage',
	'revision-of': 'lineage',
	'has-revision': 'lineage',

	// dependency -- one node requires, invokes, or is jointly constrained with
	// the other in order to function.
	'depends-on': 'dependency',
	'dependency-of': 'dependency',
	'invokes': 'dependency',
	'invoked-by': 'dependency',
	'lockstep-with': 'dependency',

	// implementation -- one node realises or verifies the specification the
	// other states.
	'implements': 'implementation',
	'implemented-by': 'implementation',
	'tests': 'implementation',
	'tested-by': 'implementation',

	// representation -- one node is a rendering, an encoding, or a depiction
	// of the other.
	'renders-to': 'representation',
	'rendered-from': 'representation',
	'illustrated-by': 'representation',
	'illustrates': 'representation',

	// identity -- the two nodes denote the same thing, or are equivalent or
	// alternative presentations of it.
	'same-as': 'identity',
	'similar-to': 'identity',
	'alternate-of': 'identity',
	'canonical-form-of': 'identity',
	'has-canonical-form': 'identity',

	// agreement -- one node supports, confirms, contradicts, or refutes a
	// claim in the other.
	'supports': 'agreement',
	'supported-by': 'agreement',
	'contradicts': 'agreement',
	'contradicted-by': 'agreement',

	// annotation -- one node qualifies or comments on the other without
	// asserting an independent claim.
	'annotates': 'annotation',
	'annotated-by': 'annotation',

	// navigation -- one node directs a reader to the other for related or
	// supplementary reading.
	'cross-references': 'navigation',
	'cross-referenced-by': 'navigation',
});

/**
 * The relation names that count as coverage, read in the knowledge-base ->
 * artifact direction. Condition 3 of the predicate.
 *
 * The selection is made pair by pair rather than by whole category, against one
 * criterion: read that direction, a pair's definition must assert at least one
 * of (a) aboutness -- the knowledge-base endpoint is a record *of* the
 * artifact; (b) citation as support -- it names the artifact as something a
 * reader can consult or check a claim against; or (c) derivation -- its content
 * came *from* the artifact. Anything less is co-location.
 *
 *   `documents`           (a) an authored record of the target
 *   `cites`               (b) names the target as a reference a reader may consult
 *   `cites-as-evidence`   (b) the checkable support for one specific claim
 *   `derived-from`        (c) the content of the source came from the target
 *
 * Category granularity cannot express this: `mentions` sits in the same
 * category as `documents` and its own definition disclaims both (a) and (b), so
 * admitting the category wholesale would let a bare mention clear a gap --
 * which is exactly what condition 3 exists to prevent. `annotation`'s single
 * pair disclaims coverage the same way.
 *
 * Membership is by `relation` key, so a pair whose knowledge-base -> artifact
 * reading is its `inverse` name is not a member.
 *
 * A reviewable copy of this set is kept beside the vocabulary artifact in the
 * graph template directory, and a test asserts the two are equal. Nothing loads
 * that copy at run time: passing the vocabulary in would create a second way
 * for the two to disagree.
 *
 * `Object.freeze` marks the Set non-extensible; the Set's own mutators are not
 * blocked by it, and calling one is a contract violation.
 *
 * @type {ReadonlySet<string>}
 */
export const COVERAGE_BEARING = Object.freeze(new Set([
	'documents',
	'cites',
	'cites-as-evidence',
	'derived-from',
]));

// ---------------------------------------------------------------------------
// Internal constants
// ---------------------------------------------------------------------------

// The four knowledge-base kinds -- condition 2 of the predicate. Stated over
// kinds rather than over the `kb:` prefix: it selects the same rows today,
// since all four kinds are pinned to that prefix, but a kind-keyed condition
// cannot silently widen when a prefix's meaning does.
const KB_KINDS = Object.freeze(new Set(['document', 'concept', 'fact', 'section']));

// The domain of the lens-only unbacked signal: the two kinds that make a claim
// a source should back. `fact` is excluded because an unbacked fact is
// structurally impossible -- a fact node is emitted with its anchor edge, so an
// unbacked one means the extraction is corrupt, which is an integrity warning
// and not a coverage gap. `section` is excluded because a container makes no
// claim of its own, and including it would flood the signal with the most
// numerous kind in the graph.
const KB_UNBACKED_KINDS = Object.freeze(new Set(['document', 'concept']));

// The kind that backs a knowledge-base claim. An in-repo image shares the
// path-bearing prefix with a source artifact but is not a checkable source for
// a claim, which is why this test reads the kind and not the prefix.
const BACKING_KIND = 'source-artifact';

// The prefix carried by an id that *is* a repo-relative path with the prefix
// stripped. This is the one place a prefix is read, and it is read for what a
// prefix legitimately answers -- how the id is spelled, and whether it can be
// compared as a path -- never as a stand-in for a node's kind.
const PATH_PREFIX = 'int:';

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/**
 * Compare two ids by UTF-16 code unit, ascending. Locale-independent, so both
 * runtimes order a result set identically; `localeCompare` would not be.
 *
 * @param {string} a
 * @param {string} b
 * @returns {number} -1, 0 or 1
 */
function compareIds(a, b) {
	if (a < b) return -1;
	if (a > b) return 1;
	return 0;
}

/**
 * Reduce any iterable of candidate ids to the sorted, duplicate-free list of
 * its non-empty string members. Anything else in the iterable is ignored: a
 * malformed candidate is the caller's to detect, and echoing it back into a
 * result set would put a non-id where consumers expect an id.
 *
 * @param {Iterable<unknown>|null|undefined} ids
 * @returns {string[]} ascending by code unit, unique
 */
function sortedUniqueIds(ids) {
	if (!ids || typeof ids === 'string' || typeof ids[Symbol.iterator] !== 'function') return [];
	const seen = new Set();
	for (const id of ids) {
		if (typeof id === 'string' && id !== '') seen.add(id);
	}
	return Array.from(seen).sort(compareIds);
}

/**
 * Snapshot an edge collection into an array, so a one-shot iterable is not
 * consumed by the first candidate tested against it.
 *
 * @param {Iterable<CoverageEdge>|null|undefined} edges
 * @returns {CoverageEdge[]}
 */
function materialiseEdges(edges) {
	if (Array.isArray(edges)) return edges;
	if (!edges || typeof edges === 'string' || typeof edges[Symbol.iterator] !== 'function') return [];
	return Array.from(edges);
}

/**
 * Normalise a node collection into an array of `{id, kind}` records.
 *
 * Accepts a `Map` keyed by id -- the shape the view model holds -- or any
 * iterable of node records. A record with no string id is ignored.
 *
 * @param {Map<string, {kind?: Kind}>|Iterable<CoverageNode>|null|undefined} nodes
 * @returns {CoverageNode[]} in the collection's own iteration order
 */
function nodeRecords(nodes) {
	if (!nodes) return [];
	const out = [];
	if (nodes instanceof Map) {
		for (const [id, record] of nodes) {
			if (typeof id === 'string' && id !== '') {
				out.push({ id, kind: record && record.kind });
			}
		}
		return out;
	}
	if (typeof nodes === 'string' || typeof nodes[Symbol.iterator] !== 'function') return [];
	for (const record of nodes) {
		if (record && typeof record.id === 'string' && record.id !== '') {
			out.push({ id: record.id, kind: record.kind });
		}
	}
	return out;
}

/**
 * The kind of one endpoint of an edge.
 *
 * The row's own `Kind` cell is the carrier and is preferred. Where a caller
 * passes edge records that omit it -- the view model's edge record carries the
 * two ids but not the two kinds -- a node index resolves it instead. The two
 * are independent carriers of the same column, not one checked against itself.
 *
 * @param {CoverageEdge} edge
 * @param {('source'|'target')} side
 * @param {Map<string, Kind>|null} kindById node index, or null for no fallback
 * @returns {Kind|null}
 */
function endpointKind(edge, side, kindById) {
	const declared = side === 'source' ? edge.sourceKind : edge.targetKind;
	if (typeof declared === 'string' && declared !== '') return declared;
	if (!kindById) return null;
	const id = side === 'source' ? edge.sourceId : edge.targetId;
	if (typeof id !== 'string') return null;
	const resolved = kindById.get(id);
	return typeof resolved === 'string' && resolved !== '' ? resolved : null;
}

/**
 * The set of endpoint ids that count as "this artifact" for condition 1: the
 * node itself, plus every ancestor directory of it.
 *
 * A knowledge-base document that documents a directory covers the artifacts
 * inside it, so an edge landing on an ancestor covers the descendant. Ancestors
 * are derived by path, which needs no extra field: a path-prefixed id *is* its
 * repo-relative path with the prefix stripped, and a directory artifact's id
 * carries a trailing separator. A node is never its own ancestor, and an id
 * that is not path-prefixed has none.
 *
 * @param {string} nodeId
 * @returns {Set<string>} the node id and each of its ancestor directory ids
 */
function artifactEndpoints(nodeId) {
	const endpoints = new Set([nodeId]);
	if (!nodeId.startsWith(PATH_PREFIX)) return endpoints;
	const path = nodeId.slice(PATH_PREFIX.length);
	// A trailing separator marks a directory artifact and is excluded from the
	// scan, so a directory does not enumerate itself as its own ancestor.
	const limit = path.endsWith('/') ? path.length - 1 : path.length;
	for (let i = 0; i < limit; i += 1) {
		if (path[i] === '/') endpoints.add(PATH_PREFIX + path.slice(0, i + 1));
	}
	return endpoints;
}

// ---------------------------------------------------------------------------
// The predicate
// ---------------------------------------------------------------------------

/**
 * Is this source artifact covered by the knowledge base?
 *
 * A node is covered when at least one edge satisfies all three conditions:
 *
 *   1. the node is one of the edge's endpoints, or an ancestor path of the node
 *      is that endpoint;
 *   2. the *other* endpoint's kind is one of the four knowledge-base kinds
 *      (`document`, `concept`, `fact`, `section`);
 *   3. the relation naming the direction *from* that knowledge-base endpoint
 *      *to* the artifact is a member of `COVERAGE_BEARING`.
 *
 * Condition 3 reads one of the row's two relation cells, and which one is not
 * arbitrary: rows are emitted in a normalised orientation, so the
 * knowledge-base endpoint may land on either side. `S2T Relation` is read when
 * the knowledge-base node is the row's source, `T2S Relation` when it is the
 * row's target. That is what lets `COVERAGE_BEARING` hold four plain relation
 * names with no separate direction rule.
 *
 * Coverage counts from a row of any `Provenance`, inferred included -- no
 * condition reads that column. The asymmetry is deliberate: liberal about what
 * counts as coverage, strict about what counts as a qualified node.
 *
 * A node not covered is a gap. Condition 3 is what stops a bare mention from
 * clearing one.
 *
 * @param {string} nodeId          the candidate artifact's id
 * @param {Iterable<CoverageEdge>} edges  every row of the final table
 * @returns {boolean} true when at least one edge covers the node
 */
export function isCovered(nodeId, edges) {
	if (typeof nodeId !== 'string' || nodeId === '') return false;
	const rows = materialiseEdges(edges);
	if (rows.length === 0) return false;
	const artifactSide = artifactEndpoints(nodeId);
	for (const edge of rows) {
		if (!edge) continue;
		// Reading A: the knowledge-base node is the row's source, the artifact
		// its target, so the knowledge-base -> artifact relation is `s2t`.
		if (artifactSide.has(edge.targetId)
			&& KB_KINDS.has(edge.sourceKind)
			&& COVERAGE_BEARING.has(edge.s2t)) {
			return true;
		}
		// Reading B: the knowledge-base node is the row's target, the artifact
		// its source, so the knowledge-base -> artifact relation is `t2s`.
		if (artifactSide.has(edge.sourceId)
			&& KB_KINDS.has(edge.targetKind)
			&& COVERAGE_BEARING.has(edge.t2s)) {
			return true;
		}
	}
	return false;
}

/**
 * The undocumented-artifact set: every candidate no knowledge-base node covers.
 *
 * The candidate set is the caller's, and the difference between the two callers
 * is expected rather than a mismatch. The pipeline passes the full enumerated
 * `source-artifact` inventory, which includes nodes appearing in no table row
 * at all -- an artifact the project considers significant with nothing said
 * about it anywhere is the sharpest instance of the defect this set exists to
 * report, not an exception to it, and computing over table rows alone would
 * make that finding invisible. The browser can only pass the ids the table
 * contains; the ids it therefore cannot see reach the page through the recorded
 * result instead, and the union of the two is what each surface publishes.
 *
 * This function does not filter the candidates and does not re-derive their
 * kind. Deciding that a candidate belongs to the class is the caller's job,
 * done from the node's kind -- never from an id prefix standing in for one,
 * since the path-bearing prefix spans both `source-artifact` and in-repo
 * `image`, and an unreferenced image is not undocumented project source.
 *
 * @param {object} args
 * @param {Iterable<string>} args.nodeIds candidate `source-artifact` ids
 * @param {Iterable<CoverageEdge>} args.edges every row of the final table
 * @returns {string[]} the uncovered candidate ids, ascending by code unit,
 *                     duplicate-free
 */
export function detectArtifactGaps({ nodeIds, edges } = {}) {
	const candidates = sortedUniqueIds(nodeIds);
	const rows = materialiseEdges(edges);
	const gaps = [];
	for (const id of candidates) {
		if (!isCovered(id, rows)) gaps.push(id);
	}
	return gaps;
}

/**
 * The unbacked-claim set: every `document` or `concept` node with no incident
 * edge to a node whose kind is `source-artifact`.
 *
 * This is a lens-only signal, computed in the browser and written to no
 * carrier. It is a different class from the undocumented-artifact set above,
 * over a different domain, and it produces no ledger row: the defect it names
 * sits *in* the knowledge-base node, so a row would point a reviewer at the
 * claim rather than at the thing that is undocumented, and the kinds in its
 * domain qualify by kind and carry no significance qualifier for a severity to
 * derive from.
 *
 * The test is kind-keyed at both ends. It asks whether the thing on the other
 * end of the edge is project source, which is a question about a class, so
 * reading the path-bearing prefix instead would count an in-repo image as
 * backing a claim -- a picture is not a checkable source. A `web-page` does not
 * back one either, which keeps the test faithful to its project-source reading.
 *
 * Unlike coverage, this test reads no relation: any incident edge to a source
 * artifact backs the claim, in either direction.
 *
 * `nodes` is required because an id cannot supply a kind -- the knowledge-base
 * prefix spans four kinds, only two of which are in the domain -- and because
 * it resolves the other endpoint's kind for edge records that carry only ids.
 *
 * @param {object} args
 * @param {Map<string, {kind?: Kind}>|Iterable<CoverageNode>} args.nodes every node
 * @param {Iterable<CoverageEdge>} args.edges every row of the final table
 * @returns {string[]} the unbacked node ids, ascending by code unit,
 *                     duplicate-free
 */
export function kbUnbacked({ nodes, edges } = {}) {
	const records = nodeRecords(nodes);
	if (records.length === 0) return [];

	// First occurrence wins, matching the loader's rule for an id whose kind
	// differs between occurrences -- a condition the table's own validation
	// rejects at generate time.
	const kindById = new Map();
	for (const record of records) {
		if (!kindById.has(record.id) && typeof record.kind === 'string' && record.kind !== '') {
			kindById.set(record.id, record.kind);
		}
	}

	// One pass over the rows collects every id with an incident source-artifact
	// edge, so the domain scan below is a lookup rather than a second scan.
	const backed = new Set();
	for (const edge of materialiseEdges(edges)) {
		if (!edge) continue;
		if (endpointKind(edge, 'target', kindById) === BACKING_KIND
			&& typeof edge.sourceId === 'string') {
			backed.add(edge.sourceId);
		}
		if (endpointKind(edge, 'source', kindById) === BACKING_KIND
			&& typeof edge.targetId === 'string') {
			backed.add(edge.targetId);
		}
	}

	const unbacked = [];
	for (const record of records) {
		if (KB_UNBACKED_KINDS.has(record.kind) && !backed.has(record.id)) {
			unbacked.push(record.id);
		}
	}
	return sortedUniqueIds(unbacked);
}
