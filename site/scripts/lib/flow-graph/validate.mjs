// validate.mjs — FlowChart well-formedness validator: rules V1–V8.
//
// validateChart(chart) is a pure function over a FlowChart that returns
// { ok, errors }. It throws nothing and mutates nothing. The CALLER throws
// on any error; see buildFlowChart (task-029) for the throwing façade.
// chart.warnings are orthogonal — they record best-effort losses on an
// approximate chart and are never structural errors.
//
// Rules implemented here: V1–V8.
//
// V9 — "no residue text remains after extracting all known states" — is NOT
// implemented here by a deliberate owner decision (work STATE.md Q3, answered
// 2026-07-26). V9 tests leftover source text that exists only during parsing;
// FlowChart carries no field for it, so a validator handed a finished chart
// cannot evaluate V9 — it cannot distinguish "this state was never mentioned"
// from "this state was mentioned and its edge was dropped", which is exactly
// the KI-008 failure V9 exists to catch. V9 is enforced at extraction in
// advance.mjs (task-023), where the residue still exists. feature-003's SPEC
// states that validateChart implements V1–V9; that claim is incorrect on this
// point (seam S5 in delivery-003 STATE.md records the delta and the nine
// documents that carry the stale text). V1–V8 keep their feature-003 meanings;
// the gap is documented here, not closed by renumbering.
//
// Pure exports — no import-time side effect.

/**
 * @typedef {import('./model.mjs').FlowChart} FlowChart
 * @typedef {import('./model.mjs').FlowNode} FlowNode
 * @typedef {import('./model.mjs').FlowEdge} FlowEdge
 */

/** Regex for a valid node id: ^[A-Za-z][A-Za-z0-9_]{0,31}$ */
const ID_RE = /^[A-Za-z][A-Za-z0-9_]{0,31}$/;

/**
 * Validate a FlowChart for structural well-formedness.
 *
 * Applies rules V1–V8 from feature-003's well-formedness V-table. All rules
 * run unconditionally — early failures do not suppress later checks.
 *
 * V9 is enforced in advance.mjs during extraction; see the module-header
 * comment for the rationale and the authority citation (work STATE.md Q3).
 *
 * V1  nodes non-empty, ids unique, every id matching ^[A-Za-z][A-Za-z0-9_]{0,31}$
 * V2  entries.length >= 1 and every entry id is a node id (reads entries array,
 *     not node.kind — a node that is both an entry and an exit still satisfies this)
 * V3  exits.length >= 1 and every exit id is a node id (reads exits array,
 *     not node.kind)
 * V4  every edge.from and edge.to is a node id — no dangling edges; a
 *     self-edge (from === to) satisfies this trivially since the node exists
 * V5  no duplicate (from, to, condition) triple among edges
 * V6  every node is reachable by walking edges from some entry
 * V7  every node's provenance has a non-empty file under canonical/,
 *     1 <= startLine <= endLine, and an excerpt whose line count equals
 *     endLine - startLine + 1
 * V8  every label is non-empty and <= 60 Unicode code points, measured
 *     with Array.from (the same measure the shared truncator uses —
 *     String.length is never used in the measurement path)
 *
 * @param {FlowChart} chart
 * @returns {{ ok: boolean, errors: string[] }}
 */
export function validateChart(chart) {
  const errors = [];

  // Defend against completely non-object input without throwing.
  if (!chart || typeof chart !== 'object') {
    return { ok: false, errors: ['[gen-skills] validate: chart is not an object'] };
  }

  const nodes = Array.isArray(chart.nodes) ? chart.nodes : [];
  const edges = Array.isArray(chart.edges) ? chart.edges : [];
  const entries = Array.isArray(chart.entries) ? chart.entries : [];
  const exits = Array.isArray(chart.exits) ? chart.exits : [];
  const skill = typeof chart.skill === 'string' ? chart.skill : '(unknown)';

  // ── V1: nodes non-empty; ids unique; every id matches the id pattern ─────────
  if (nodes.length === 0) {
    errors.push(`[gen-skills] validate: V1: nodes is empty (${skill})`);
  } else {
    const seenIds = new Set();
    for (const node of nodes) {
      const loc = _provLoc(node.provenance);
      if (!ID_RE.test(node.id)) {
        errors.push(
          `[gen-skills] validate: V1: invalid node id '${node.id}' (${loc})`
        );
      }
      if (seenIds.has(node.id)) {
        errors.push(
          `[gen-skills] validate: V1: duplicate node id '${node.id}' (${loc})`
        );
      } else {
        seenIds.add(node.id);
      }
    }
  }

  // Authoritative node id set — used by all subsequent rules.
  const nodeIds = new Set(nodes.map((n) => n.id));

  // ── V2: entries non-empty; every entry id is a node id ───────────────────────
  if (entries.length === 0) {
    errors.push(`[gen-skills] validate: V2: entries is empty (${skill})`);
  } else {
    for (const id of entries) {
      if (!nodeIds.has(id)) {
        errors.push(
          `[gen-skills] validate: V2: entry id '${id}' is not a node id (${skill})`
        );
      }
    }
  }

  // ── V3: exits non-empty; every exit id is a node id ──────────────────────────
  if (exits.length === 0) {
    errors.push(`[gen-skills] validate: V3: exits is empty (${skill})`);
  } else {
    for (const id of exits) {
      if (!nodeIds.has(id)) {
        errors.push(
          `[gen-skills] validate: V3: exit id '${id}' is not a node id (${skill})`
        );
      }
    }
  }

  // ── V4: no dangling edges — every from and to must be a node id ──────────────
  // A self-edge (from === to) is satisfied trivially: if the node exists, the
  // check passes for both endpoints without special-casing.
  for (const edge of edges) {
    const loc = _provLoc(edge.provenance);
    if (!nodeIds.has(edge.from)) {
      errors.push(
        `[gen-skills] validate: V4: edge.from '${edge.from}' is not a node id (${loc})`
      );
    }
    if (!nodeIds.has(edge.to)) {
      errors.push(
        `[gen-skills] validate: V4: edge.to '${edge.to}' is not a node id (${loc})`
      );
    }
  }

  // ── V5: no duplicate (from, to, condition) triple ────────────────────────────
  const tripleSeen = new Set();
  for (const edge of edges) {
    const key = `${edge.from}\0${edge.to}\0${edge.condition ?? ''}`;
    if (tripleSeen.has(key)) {
      const loc = _provLoc(edge.provenance);
      errors.push(
        `[gen-skills] validate: V5: duplicate edge (from='${edge.from}', ` +
        `to='${edge.to}', condition=${JSON.stringify(edge.condition)}) (${loc})`
      );
    } else {
      tripleSeen.add(key);
    }
  }

  // ── V6: every node reachable by walking edges from some entry ─────────────────
  // Only edges whose endpoints are both valid node ids contribute to reachability;
  // dangling edges (caught by V4) are skipped here so V6 is independent.
  const adj = new Map(nodes.map((n) => [n.id, []]));
  for (const edge of edges) {
    if (nodeIds.has(edge.from) && nodeIds.has(edge.to)) {
      adj.get(edge.from).push(edge.to);
    }
  }

  const reachable = new Set();
  const queue = [...entries.filter((id) => nodeIds.has(id))];
  for (const id of queue) reachable.add(id);
  let qi = 0;
  while (qi < queue.length) {
    const curr = queue[qi++];
    for (const next of adj.get(curr) ?? []) {
      if (!reachable.has(next)) {
        reachable.add(next);
        queue.push(next);
      }
    }
  }

  for (const node of nodes) {
    if (!reachable.has(node.id)) {
      const loc = _provLoc(node.provenance);
      errors.push(
        `[gen-skills] validate: V6: node '${node.id}' ('${node.name}') ` +
        `is unreachable from entries (${loc})`
      );
    }
  }

  // ── V7: every node's provenance is well-formed ────────────────────────────────
  for (const node of nodes) {
    const p = node.provenance;

    if (!p || typeof p !== 'object') {
      errors.push(
        `[gen-skills] validate: V7: node '${node.id}' ('${node.name}') ` +
        `has no provenance (${skill})`
      );
      continue;
    }

    if (!p.file || typeof p.file !== 'string' || p.file.trim() === '') {
      errors.push(
        `[gen-skills] validate: V7: node '${node.id}' ('${node.name}') ` +
        `provenance.file is empty (${skill})`
      );
    } else if (!p.file.startsWith('canonical/')) {
      const loc = _provLoc(p);
      errors.push(
        `[gen-skills] validate: V7: node '${node.id}' ('${node.name}') ` +
        `provenance.file is not under canonical/ ('${p.file}') (${loc})`
      );
    }

    if (
      !Number.isFinite(p.startLine) ||
      !Number.isFinite(p.endLine) ||
      p.startLine < 1 ||
      p.endLine < p.startLine
    ) {
      const loc = _provLoc(p);
      errors.push(
        `[gen-skills] validate: V7: node '${node.id}' ('${node.name}') ` +
        `provenance has invalid line range startLine=${p.startLine} ` +
        `endLine=${p.endLine} (${loc})`
      );
    } else {
      const expectedLines = p.endLine - p.startLine + 1;
      const actualLines =
        typeof p.excerpt === 'string' ? p.excerpt.split('\n').length : 0;
      if (actualLines !== expectedLines) {
        const loc = _provLoc(p);
        errors.push(
          `[gen-skills] validate: V7: node '${node.id}' ('${node.name}') ` +
          `provenance excerpt has ${actualLines} line(s) but ` +
          `startLine–endLine span is ${expectedLines} (${loc})`
        );
      }
    }
  }

  // ── V8: every label non-empty and <= 60 Unicode code points ───────────────────
  // Measurement uses Array.from, matching the shared truncator in model.mjs
  // exactly — String.length is not used in the measurement path.
  for (const node of nodes) {
    const loc = _provLoc(node.provenance);
    const label = node.label;
    if (typeof label !== 'string' || label === '') {
      errors.push(
        `[gen-skills] validate: V8: node '${node.id}' ('${node.name}') ` +
        `has empty label (${loc})`
      );
    } else {
      const cpLen = Array.from(label).length;
      if (cpLen > 60) {
        errors.push(
          `[gen-skills] validate: V8: node '${node.id}' ('${node.name}') ` +
          `label has ${cpLen} code points (limit 60) (${loc})`
        );
      }
    }
  }

  // ── V9: NOT IMPLEMENTED HERE ──────────────────────────────────────────────────
  // See module-header comment for the full rationale and authority citation
  // (work STATE.md Q3). V9 is enforced in advance.mjs (task-023).

  return { ok: errors.length === 0, errors };
}

// ── Internal helpers ───────────────────────────────────────────────────────────

/**
 * Format a provenance record as "file:startLine: first-line-of-excerpt" for
 * use in error messages. Returns a descriptive fallback when provenance is
 * absent or lacks a file field.
 *
 * @param {object|null|undefined} provenance
 * @returns {string}
 */
function _provLoc(provenance) {
  if (!provenance || typeof provenance !== 'object') return '(no provenance)';
  const { file, startLine, excerpt } = provenance;
  if (!file) return '(no file)';
  const line = typeof startLine === 'number' ? startLine : '?';
  const first = typeof excerpt === 'string' ? excerpt.split('\n')[0] : '';
  return `${file}:${line}: ${first}`;
}
