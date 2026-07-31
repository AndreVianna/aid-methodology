// compose.mjs — Doorway chart composition and binding reader (feature-004).
//
// Placed here (rather than in either extractor) because both extractors —
// extract-engine and extract-sibling — need both functions, and putting either
// in the other would create a sibling import.
//
// composeDoorwayChart — pure prefix-and-offset splice.  Returns new node and
//   edge objects; never mutates the (deeply frozen) core.  Every doorway
//   prefix is exactly one node, so the offset is 1 on every page and the
//   core's c1…cN become n2…nN+1 identically everywhere.
//
// readDoorwayBinding — reads only the doorway's own body; never reads
//   any catalog or template file outside the body.  Implements the engine
//   ladder (Bind clause) and the sibling ladder (braced group, alias_of, W1).
//
// Pure exports — no import-time side effect.

// ── Engine binding pattern (generated doorways, both forms) ───────────────────

// Matches: Bind **VERB=`create`**, **ARTIFACT=`api`**
//          Bind **VERB=`fix`**,   **ARTIFACT="" (bare verb)**
// Group 1: verb value (inside backticks)
// Group 2: artifact value inside backticks, or undefined for the bare-verb form.
const _ENGINE_BIND_RE =
  /Bind \*\*VERB=`([^`]+)`\*\*, \*\*ARTIFACT=(?:`([^`]*)`|"" \(bare verb\))\*\*/;

// ── Sibling binding patterns ───────────────────────────────────────────────────

// Braced group: {verb: test, artifact: security}  or  {verb: document, artifact: ""}
// Group 1: verb; Group 2: raw artifact (may be `""` → '')
const _SIBLING_GROUP_RE = /\{verb:\s*([\w-]+),\s*artifact:\s*([^}]*)\}/;

// Pure alias: alias_of: aid-create-document  (null or non-aid values are not matched)
const _ALIAS_RE = /alias_of:\s*(aid-[\w-]+)/;

// Facet binding: **kind bound to security**  **genre bound to ADR** etc.
// Captured text is stripped of surrounding ** by the group.
const _BOUND_RE = /\*\*([^*]+ bound to [^*]+)\*\*/;

// ── composeDoorwayChart ───────────────────────────────────────────────────────

/**
 * Compose a doorway FlowChart by splicing a prefix (the doorway's own node and
 * its hop edge into the core) in front of a frozen core (engine or parent chart).
 *
 * Returns **new** node and edge objects — the core is read, never mutated.
 * No `structuredClone` of a frozen graph, no in-place property assignment on
 * core members.
 *
 * With one prefix node (the only case in practice), core nodes c1…cN become
 * n2…nN+1 in the composed chart (id = 'n' + (order + offset), order = order + offset).
 *
 * @param {object} params
 * @param {string}                   params.skill        Skill directory name
 * @param {import('./model.mjs').FlowNode[]} params.prefixNodes  Entry nodes (always exactly one)
 * @param {import('./model.mjs').FlowEdge[]} params.prefixEdges  Hop edges from prefix to core
 * @param {{ nodes, edges, exits, sources, warnings }} params.core
 *   Deeply frozen EngineCore or FlowChart acting as core.  Read-only.
 * @param {string}  params.confidence  'derived' | 'approximate'
 * @param {string}  [params.shape]     FlowChart.shape; set by the calling extractor
 * @param {string}  [params.extractor] FlowChart.extractor; set by the calling extractor
 * @returns {import('./model.mjs').FlowChart}
 */
export function composeDoorwayChart({
  skill,
  prefixNodes,
  prefixEdges,
  core,
  confidence,
  shape = 'engine-doorway',
  extractor = 'compose',
}) {
  const offset = prefixNodes.length; // always 1

  // Build the id offset map: core node id → composed 'nN' id.
  // New id is 'n' + (node.order + offset); new order is node.order + offset.
  const offsetMap = new Map();
  for (const node of core.nodes) {
    offsetMap.set(node.id, 'n' + (node.order + offset));
  }

  // Compose nodes: shallow-copy each prefix node, then new objects for core.
  const nodes = [
    ...prefixNodes.map((n) => ({ ...n })),
    ...core.nodes.map((n) => ({
      ...n,
      id: offsetMap.get(n.id),
      order: n.order + offset,
    })),
  ];

  // Compose edges: shallow-copy prefix edges, then new objects for core with
  // from/to remapped through offsetMap.
  const edges = [
    ...prefixEdges.map((e) => ({ ...e })),
    ...core.edges.map((e) => ({
      ...e,
      from: offsetMap.get(e.from) ?? e.from,
      to: offsetMap.get(e.to) ?? e.to,
    })),
  ];

  // entries = [n1] by construction — the prefix node is the sole entry because
  // the hop edge(s) give the core's former entry nodes an in-edge (in-degree > 0).
  const entries = [prefixNodes[0].id];

  // exits = core's exit ids shifted through the offset map.
  const exits = core.exits.map((id) => offsetMap.get(id) ?? id);

  // sources = ASCII-sorted union of prefix provenance files + core sources.
  const sourceSet = new Set(core.sources);
  for (const n of prefixNodes) {
    if (n.provenance?.file) sourceSet.add(n.provenance.file);
  }
  const sources = [...sourceSet].sort();

  // warnings = core warnings (prefix-level warnings, e.g. W1, are added by caller).
  const warnings = core.warnings.slice();

  // Sort nodes by order ascending.
  const sortedNodes = nodes.slice().sort((a, b) => a.order - b.order);

  // Sort edges by (from.order, to.order, condition) for determinism.
  const nodeById = new Map(sortedNodes.map((n) => [n.id, n]));
  const sortedEdges = edges.slice().sort((a, b) => {
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
    title: skill + '\u2014 state flow',
    nodes: sortedNodes,
    edges: sortedEdges,
    entries,
    exits,
    sources,
    warnings,
  };
}

// ── readDoorwayBinding ────────────────────────────────────────────────────────

/**
 * @typedef {object} DoorwayBinding
 * @property {'engine'|'sibling'} kind       Which ladder matched.
 * @property {string|null}        verb        Bound verb ('create', 'fix', etc.).
 * @property {string|null}        artifact    Bound artifact ('' for bare verb; null when none).
 * @property {string|null}        aliasOf     Pure-alias target skill name, or null.
 * @property {string|null}        bound       Facet binding string for the hop condition, or null.
 * @property {null}               parent      Always null here; set by the sibling parent resolver (task-036).
 * @property {import('./model.mjs').Provenance} provenance  The body line the binding was read from.
 * @property {string[]}           warnings    W1 if no binding matched.
 */

/**
 * Read the doorway's own body to extract its verb/artifact binding.
 *
 * Implements both ladders:
 *
 * **Engine ladder** (for engine-doorway shapes):
 *   `Bind **VERB=`create`**, **ARTIFACT=`api`**`
 *   `Bind **VERB=`fix`**,   **ARTIFACT="" (bare verb)**`
 *
 * **Sibling ladder** (for sibling-doorway shapes):
 *   Braced group: `{verb: test, artifact: security}`  or  `{verb: document, artifact: ""}`
 *   Alias form:   `alias_of: aid-create-document`
 *   No-binding fallback: W1 warning, null verb/artifact.
 *
 * Reads **only** the doorway's own body and what it is handed — never
 * `shortcut-catalog.yml`, and never any other file. This module imports no I/O at
 * all, which is the real guarantee; the source-text guard in the test is a
 * cheaper restatement of it.
 *
 * The reason is not mere consistency with the classifier's body-only rule. The
 * engine's own Invocation Contract names the doorway body as the source of
 * `{verb}` and `{artifact}`. Reading the catalogue would report what a doorway
 * *should* bind; reading the body reports what it *does* — and a build/catalogue
 * drift, which the engine explicitly handles at INTAKE as "a build defect", would
 * otherwise be invisible on the very page that has it.
 *
 * @param {object} params
 * @param {string} params.body          Body text (after frontmatter).
 * @param {number} params.bodyStartLine 1-based line number of body's first line in the full file.
 * @param {string} params.sourcePath    Repo-root-relative POSIX path of the SKILL.md file.
 * @returns {DoorwayBinding}
 */
export function readDoorwayBinding({ body, bodyStartLine, sourcePath }) {
  const bodyLines = body.split('\n').map((l) => l.replace(/\r$/, ''));
  const warnings = [];

  // Scan line by line; engine ladder first, then sibling ladder.
  for (let i = 0; i < bodyLines.length; i++) {
    const line = bodyLines[i];
    const fileLine = bodyStartLine + i; // 1-based file line

    // ── Engine ladder: Bind clause ───────────────────────────────────────
    const engineMatch = line.match(_ENGINE_BIND_RE);
    if (engineMatch) {
      const verb = engineMatch[1];
      // group 2 present → backtick artifact; absent → bare-verb form (artifact = '')
      const artifact = engineMatch[2] !== undefined ? engineMatch[2] : '';
      const provenance = _makeProvenance(sourcePath, fileLine, line);
      const bound = _findBound(bodyLines);
      return {
        kind: 'engine',
        verb,
        artifact,
        aliasOf: null,
        bound,
        parent: null,
        provenance,
        warnings,
      };
    }

    // ── Sibling ladder: braced {verb, artifact} group ────────────────────
    const groupMatch = line.match(_SIBLING_GROUP_RE);
    if (groupMatch) {
      const verb = groupMatch[1];
      let artifact = groupMatch[2].trim();
      // `artifact: ""` → empty string (bare/no artifact for this sibling)
      if (artifact === '""') artifact = '';
      const provenance = _makeProvenance(sourcePath, fileLine, line);
      const bound = _findBound(bodyLines);
      return {
        kind: 'sibling',
        verb,
        artifact,
        aliasOf: null,
        bound,
        parent: null,
        provenance,
        warnings,
      };
    }

    // ── Sibling ladder: alias_of ─────────────────────────────────────────
    const aliasMatch = line.match(_ALIAS_RE);
    if (aliasMatch) {
      const aliasOf = aliasMatch[1];
      const provenance = _makeProvenance(sourcePath, fileLine, line);
      return {
        kind: 'sibling',
        verb: null,
        artifact: null,
        aliasOf,
        bound: null,
        parent: null,
        provenance,
        warnings,
      };
    }
  }

  // ── W1: no binding form matched ───────────────────────────────────────────
  warnings.push(
    `[gen-skills] W1: no binding form matched in the body of ${sourcePath}`
  );
  const provenance = _makeProvenance(sourcePath, bodyStartLine, bodyLines[0] ?? '');
  return {
    kind: 'sibling',
    verb: null,
    artifact: null,
    aliasOf: null,
    bound: null,
    parent: null,
    provenance,
    warnings,
  };
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/**
 * Build a single-line Provenance for a body line.
 *
 * @param {string} file      Repo-root-relative POSIX path.
 * @param {number} fileLine  1-based line number in the full file.
 * @param {string} excerpt   Verbatim line text.
 * @returns {import('./model.mjs').Provenance}
 */
function _makeProvenance(file, fileLine, excerpt) {
  return {
    file,
    startLine: fileLine,
    endLine: fileLine,
    sourceKind: 'skill',
    excerpt,
  };
}

/**
 * Search body lines for the facet binding pattern `**X bound to Y**`.
 * Returns the stripped capture (e.g. 'kind bound to security'), or null.
 *
 * @param {string[]} bodyLines  0-indexed body lines (CRLF stripped).
 * @returns {string|null}
 */
function _findBound(bodyLines) {
  for (const line of bodyLines) {
    const m = line.match(_BOUND_RE);
    if (m) return m[1].trim();
  }
  return null;
}
