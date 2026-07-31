// model.mjs — FlowChart / FlowNode / FlowEdge / Provenance model,
//             n1..nN id assignment, kind/entries/exits computation,
//             shared code-point truncator, and serializeChart().
//
// All ids are assigned n1…nN by node.order (1-based source order).
// kind, entries, and exits are derived by buildChart() from the node/edge data.
//
// Pure exports — no import-time side effect.

// ── Type definitions (JSDoc) ──────────────────────────────────────────────────

/**
 * @typedef {object} Provenance
 * @property {string} file        Repo-root-relative POSIX path, always under canonical/
 * @property {number} startLine   1-based, inclusive
 * @property {number} endLine     1-based, inclusive, >= startLine
 * @property {string} sourceKind  'skill' | 'worker' | 'engine' | 'sibling'
 * @property {string} excerpt     Verbatim LF-joined slice of [startLine, endLine]
 */

/**
 * @typedef {object} Terminal
 * @property {string}      advanceType  'CHAIN'|'HALT'|'PAUSE-FOR-USER-ACTION'|'PAUSE-FOR-USER-DECISION'|'UNSPECIFIED'
 * @property {string|null} handoff      Verbatim prose from the advance clause, or null
 */

/**
 * @typedef {object} FlowNode
 * @property {string}         id         n1…nN, matches ^[A-Za-z][A-Za-z0-9_]{0,31}$
 * @property {number}         order      1-based position in source order
 * @property {string}         name       State name, verbatim and uppercase-preserving
 * @property {string}         label      ≤ 60 Unicode code points, non-empty (FR-3/NFR-1)
 * @property {string}         kind       'entry'|'step'|'decision'|'loop-back'|'exit'
 * @property {Terminal|null}  terminal   { advanceType, handoff } on exits; null otherwise
 * @property {Provenance}     provenance Required
 * @property {Provenance|null} detail    Full step definition; excerpt omitted for large ranges
 */

/**
 * @typedef {object} FlowEdge
 * @property {string}      from        Node id
 * @property {string}      to          Node id
 * @property {string}      kind        'sequence'|'branch'|'loop-back'|'re-entry'
 * @property {string|null} condition   ≤ 80 code points or null
 * @property {string}      advanceType 'CHAIN'|'HALT'|'PAUSE-FOR-USER-ACTION'|'PAUSE-FOR-USER-DECISION'|'UNSPECIFIED'
 * @property {Provenance}  provenance  The exact line the edge was read from
 */

/**
 * @typedef {object} FlowChart
 * @property {string}     skill       Directory name under canonical/skills/
 * @property {string}     shape       'dispatch-table'|'inline-states'|'sibling-doorway'|'engine-doorway'|'residual'
 * @property {string}     extractor   Which extractor produced this chart
 * @property {string}     confidence  'derived' | 'approximate'
 * @property {string}     title       '<skill> — state flow'
 * @property {FlowNode[]} nodes       Ordered by order ascending
 * @property {FlowEdge[]} edges       Ordered by (from.order, to.order, condition)
 * @property {string[]}   entries     Node ids (AC-3 authority)
 * @property {string[]}   exits       Node ids (AC-3 authority)
 * @property {string[]}   sources     Repo-root-relative files, ASCII-sorted
 * @property {string[]}   warnings    Best-effort losses
 */

// ── Truncator ─────────────────────────────────────────────────────────────────

/**
 * Truncate text to at most `limit` Unicode code points.
 *
 * Measurement and slicing always use Array.from so surrogate pairs are never
 * split. If the text is already within the limit it is returned unchanged.
 * When truncation is needed:
 *   - Searches for the last whitespace at index ≤ limit-1 (0-based). If found,
 *     cuts just before it, strips trailing whitespace and any trailing
 *     `,` `;` `:` `—` (U+2014) `-`, and appends `…` (U+2026).
 *   - If no whitespace exists at or before that index, hard-cuts at exactly
 *     limit-1 code points and appends `…`, making the bound unconditional.
 *
 * Callers use this for both the ≤ 60 code-point label bound and the ≤ 80
 * code-point condition bound.
 *
 * @param {string} text
 * @param {number} limit  Maximum code points (e.g. 60 for labels, 80 for conditions)
 * @returns {string}
 */
export function truncate(text, limit) {
  const cps = Array.from(text);
  if (cps.length <= limit) return text;

  // Search for the last whitespace at index 0..limit-1 (so cut + '…' ≤ limit).
  let cutAt = -1;
  for (let i = limit - 1; i >= 0; i--) {
    if (/\s/.test(cps[i])) {
      cutAt = i;
      break;
    }
  }

  if (cutAt >= 0) {
    // Keep code points 0..cutAt-1 (cut before the whitespace character),
    // then strip any trailing whitespace and punctuation.
    let result = cps.slice(0, cutAt).join('');
    result = result.replace(/[\s,;:\u2014\-]+$/u, '');
    return result + '\u2026';
  }

  // No whitespace boundary: hard-cut at exactly limit-1 code points.
  return cps.slice(0, limit - 1).join('') + '\u2026';
}

// ── Provenance constructor ─────────────────────────────────────────────────────

/**
 * Create a Provenance record.
 *
 * @param {object} params
 * @param {string} params.file       Repo-root-relative POSIX path under canonical/
 * @param {number} params.startLine  1-based, inclusive
 * @param {number} params.endLine    1-based, inclusive, >= startLine
 * @param {string} params.sourceKind 'skill' | 'worker' | 'engine' | 'sibling'
 * @param {string} params.excerpt    Verbatim LF-joined slice of [startLine, endLine]
 * @returns {Provenance}
 */
export function makeProvenance({ file, startLine, endLine, sourceKind, excerpt }) {
  return { file, startLine, endLine, sourceKind, excerpt };
}

// ── Node / Edge constructors ───────────────────────────────────────────────────

/**
 * Create a raw FlowNode (without id or kind — both assigned by buildChart).
 *
 * @param {object}         params
 * @param {number}         params.order      1-based source-order position
 * @param {string}         params.name       State name, verbatim
 * @param {string}         params.label      Short derived label, ≤ 60 code points
 * @param {Provenance}     params.provenance Required provenance record
 * @param {Terminal|null}  [params.terminal] Non-null only on exit nodes
 * @param {Provenance|null} [params.detail]  Full section/worker range
 * @returns {Omit<FlowNode, 'id' | 'kind'>}
 */
export function makeNode({ order, name, label, provenance, terminal = null, detail = null }) {
  return { order, name, label, terminal, provenance, detail };
}

/**
 * Create a FlowEdge.
 *
 * @param {object}    params
 * @param {string}    params.from        Source node id
 * @param {string}    params.to          Target node id
 * @param {string}    params.kind        'sequence'|'branch'|'loop-back'|'re-entry'
 * @param {string|null} params.condition ≤ 80 code points or null
 * @param {string}    params.advanceType 'CHAIN'|'HALT'|'PAUSE-FOR-USER-ACTION'|'PAUSE-FOR-USER-DECISION'|'UNSPECIFIED'
 * @param {Provenance} params.provenance The source line provenance
 * @returns {FlowEdge}
 */
export function makeEdge({ from, to, kind, condition, advanceType, provenance }) {
  return { from, to, kind, condition, advanceType, provenance };
}

// ── Chart builder ─────────────────────────────────────────────────────────────

/**
 * Build a complete FlowChart from raw nodes and edges.
 *
 * Assigns n1..nN ids by node.order (id = 'n' + order), computes kind for each
 * node, derives entries and exits, and sorts edges by (from.order, to.order,
 * condition).
 *
 * @param {object}    params
 * @param {string}    params.skill       Directory name under canonical/skills/
 * @param {string}    params.shape       Classifier shape
 * @param {string}    params.extractor   Extractor identifier
 * @param {string}    params.confidence  'derived' | 'approximate'
 * @param {Array<Omit<FlowNode,'id'|'kind'>>} params.nodes  Raw nodes in source order
 * @param {FlowEdge[]} params.edges      Raw edges (from/to must reference valid ids)
 * @param {string[]}  params.sources     Repo-root-relative source files
 * @param {string[]}  [params.warnings]  Pre-existing warning messages
 * @returns {FlowChart}
 */
export function buildChart({
  skill,
  shape,
  extractor,
  confidence,
  nodes: rawNodes,
  edges: rawEdges,
  sources,
  warnings: initialWarnings = [],
}) {
  // Mutable warnings array — may grow if exits fallback fires.
  const warnings = [...initialWarnings];

  // ── 1. Assign ids: n1..nN by order ────────────────────────────────────────
  const nodes = rawNodes
    .slice()
    .sort((a, b) => a.order - b.order)
    .map((n) => ({ ...n, id: 'n' + n.order, kind: 'step' }));

  const idByOrder = new Map(nodes.map((n) => [n.order, n.id]));
  const nodeById = new Map(nodes.map((n) => [n.id, n]));

  // ── 2. Compute entries ────────────────────────────────────────────────────
  // entries = every in-degree-0 node + lowest-order node of any weakly-connected
  // component that has no in-degree-0 node (a pure cycle).
  //
  // SELF-EDGES ARE EXCLUDED from the in-degree count, and that exclusion is
  // load-bearing rather than tidiness. An edge from a node to itself is not a way
  // INTO that node: if its only incoming edge is its own loop, nothing else can
  // reach it, so it is an entry in exactly the sense this rule means. Counting the
  // self-edge left such a node with in-degree 1 — not an entry, and reachable from
  // no entry — so V6 rejected the whole chart.
  //
  // Found via three real skills, all with the same shape: `DELIVERY-GATE` in
  // aid-execute, and `SPIKE` and `BLOCKED` in aid-specify each had in-degree 1
  // sourced entirely from themselves. Those charts failed validation, and since
  // task-029's façade throws on a validator error, all three pages would have
  // failed to build rather than rendering an imperfect chart.
  //
  // The pure-cycle fallback below already anticipated cycles with no entry; a
  // one-node cycle is the degenerate case it did not cover.
  const inDegree = new Map(nodes.map((n) => [n.id, 0]));
  for (const e of rawEdges) {
    if (e.from === e.to) continue;
    inDegree.set(e.to, (inDegree.get(e.to) ?? 0) + 1);
  }

  const zeroDegreeIds = new Set(
    nodes.filter((n) => inDegree.get(n.id) === 0).map((n) => n.id)
  );

  // Build undirected adjacency for WCC discovery.
  const adj = new Map(nodes.map((n) => [n.id, new Set()]));
  for (const e of rawEdges) {
    adj.get(e.from)?.add(e.to);
    adj.get(e.to)?.add(e.from);
  }

  const visited = new Set();
  const entryIdSet = new Set(zeroDegreeIds);

  for (const node of nodes) {
    if (visited.has(node.id)) continue;

    // BFS to collect the weakly-connected component.
    const component = [];
    const queue = [node.id];
    visited.add(node.id);
    while (queue.length > 0) {
      const curr = queue.shift();
      component.push(curr);
      for (const nbr of adj.get(curr) ?? []) {
        if (!visited.has(nbr)) {
          visited.add(nbr);
          queue.push(nbr);
        }
      }
    }

    // If this component has no in-degree-0 node, it is a pure cycle.
    // Add the lowest-order node as the synthetic entry.
    const hasEntry = component.some((id) => zeroDegreeIds.has(id));
    if (!hasEntry) {
      const lowestOrder = component.reduce((min, id) => {
        const ord = nodeById.get(id).order;
        return ord < min ? ord : min;
      }, Infinity);
      entryIdSet.add(idByOrder.get(lowestOrder));
    }
  }

  const entries = [...entryIdSet].sort(
    (a, b) => nodeById.get(a).order - nodeById.get(b).order
  );

  // ── 3. Compute exits ──────────────────────────────────────────────────────
  // exits = nodes with terminal !== null.
  // Fallback: if none, designate the highest-order node and record a warning.
  let exitNodes = nodes.filter((n) => n.terminal !== null);

  if (exitNodes.length === 0) {
    const highest = nodes.reduce((max, n) => (n.order > max.order ? n : max));
    warnings.push(
      `[gen-skills] exits fallback: no terminal-advance node found in '${skill}'; ` +
      `designating highest-order node '${highest.name}' (${highest.id}) as exit`
    );
    // Mutate the highest-order node to carry a minimal terminal.
    highest.terminal = { advanceType: 'UNSPECIFIED', handoff: null };
    exitNodes = [highest];
  }

  const exits = exitNodes
    .sort((a, b) => a.order - b.order)
    .map((n) => n.id);

  const exitIdSet = new Set(exits);

  // ── 4. Compute kind for each node ─────────────────────────────────────────
  // Precedence: exit > entry > decision > loop-back > step.
  // decision = 2+ outgoing branch edges.
  // loop-back = at least one outgoing loop-back edge.
  const branchCount = new Map(nodes.map((n) => [n.id, 0]));
  const hasLoopBackOut = new Set();

  for (const e of rawEdges) {
    if (e.kind === 'branch') {
      branchCount.set(e.from, (branchCount.get(e.from) ?? 0) + 1);
    }
    if (e.kind === 'loop-back') {
      hasLoopBackOut.add(e.from);
    }
  }

  for (const node of nodes) {
    if (exitIdSet.has(node.id)) {
      node.kind = 'exit';
    } else if (entryIdSet.has(node.id)) {
      node.kind = 'entry';
    } else if ((branchCount.get(node.id) ?? 0) >= 2) {
      node.kind = 'decision';
    } else if (hasLoopBackOut.has(node.id)) {
      node.kind = 'loop-back';
    } else {
      node.kind = 'step';
    }
  }

  // ── 5. Sort edges by (from.order, to.order, condition) ────────────────────
  const edges = rawEdges.slice().sort((a, b) => {
    const fromA = nodeById.get(a.from)?.order ?? 0;
    const fromB = nodeById.get(b.from)?.order ?? 0;
    if (fromA !== fromB) return fromA - fromB;

    const toA = nodeById.get(a.to)?.order ?? 0;
    const toB = nodeById.get(b.to)?.order ?? 0;
    if (toA !== toB) return toA - toB;

    const ca = a.condition ?? '';
    const cb = b.condition ?? '';
    return ca < cb ? -1 : ca > cb ? 1 : 0;
  });

  return {
    skill,
    shape,
    extractor,
    confidence,
    title: skill + ' \u2014 state flow',
    nodes,
    edges,
    entries,
    exits,
    sources: sources.slice().sort(),
    warnings,
  };
}

// ── Serializer ─────────────────────────────────────────────────────────────────

/**
 * Serialize a FlowChart to a JSON string with fixed key order, 2-space indent,
 * and exactly one trailing LF. Line endings are normalized to LF only.
 *
 * Key order follows the field order of feature-003's schema tables:
 *   FlowChart: skill, shape, extractor, confidence, title, nodes, edges,
 *              entries, exits, sources, warnings
 *   FlowNode:  id, order, name, label, kind, terminal, provenance, detail
 *   FlowEdge:  from, to, kind, condition, advanceType, provenance
 *   Provenance: file, startLine, endLine, sourceKind, excerpt
 *
 * @param {FlowChart} chart
 * @returns {string}  JSON + trailing '\n', LF only.
 */
export function serializeChart(chart) {
  // Re-sort edges to guarantee determinism even if caller mutated the chart.
  const nodeById = new Map(chart.nodes.map((n) => [n.id, n]));
  const sortedEdges = chart.edges.slice().sort((a, b) => {
    const fromA = nodeById.get(a.from)?.order ?? 0;
    const fromB = nodeById.get(b.from)?.order ?? 0;
    if (fromA !== fromB) return fromA - fromB;

    const toA = nodeById.get(a.to)?.order ?? 0;
    const toB = nodeById.get(b.to)?.order ?? 0;
    if (toA !== toB) return toA - toB;

    const ca = a.condition ?? '';
    const cb = b.condition ?? '';
    return ca < cb ? -1 : ca > cb ? 1 : 0;
  });

  const obj = {
    skill: chart.skill,
    shape: chart.shape,
    extractor: chart.extractor,
    confidence: chart.confidence,
    title: chart.title,
    nodes: chart.nodes.map((n) => ({
      id: n.id,
      order: n.order,
      name: n.name,
      label: n.label,
      kind: n.kind,
      terminal: _serializeTerminal(n.terminal),
      provenance: _serializeProvenance(n.provenance),
      detail: n.detail === null ? null : _serializeProvenance(n.detail),
    })),
    edges: sortedEdges.map((e) => ({
      from: e.from,
      to: e.to,
      kind: e.kind,
      condition: e.condition,
      advanceType: e.advanceType,
      provenance: _serializeProvenance(e.provenance),
    })),
    entries: chart.entries,
    exits: chart.exits,
    sources: chart.sources,
    warnings: chart.warnings,
  };

  return JSON.stringify(obj, null, 2).replace(/\r\n/g, '\n') + '\n';
}

// ── Internal helpers ───────────────────────────────────────────────────────────

/**
 * Return a new Provenance object with keys in fixed schema order.
 *
 * @param {Provenance} p
 * @returns {object}
 */
function _serializeProvenance(p) {
  return {
    file: p.file,
    startLine: p.startLine,
    endLine: p.endLine,
    sourceKind: p.sourceKind,
    excerpt: p.excerpt,
  };
}

/**
 * Return a new Terminal object with keys in fixed schema order, or null.
 *
 * Every other nested object in the sidecar is normalized this way; `terminal` was
 * passed through as-is, which left AC-6 byte-identity resting on each producer
 * happening to build the literal in the same key order. Terminal objects are
 * constructed in `advance.mjs` and in all three extractors, so that is four
 * independent producers of one shape — normalizing here rather than trusting them
 * to agree is the same single-authority argument that applies to the truncator.
 *
 * Field order per feature-003's Provenance/Terminal schema: `{ advanceType, handoff }`.
 *
 * @param {{advanceType: string, handoff: string|null}|null} t
 * @returns {object|null}
 */
function _serializeTerminal(t) {
  if (t === null) return null;
  return {
    advanceType: t.advanceType,
    handoff: t.handoff,
  };
}
