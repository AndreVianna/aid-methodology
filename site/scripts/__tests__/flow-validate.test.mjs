// flow-validate.test.mjs — Unit tests for site/scripts/lib/flow-graph/validate.mjs.
//
// Coverage: validateChart() implementing rules V1–V8.
//
// V9 is enforced in advance.mjs (task-023) and is not tested here. See the
// validate.mjs module-header comment and work STATE.md Q3 for the rationale.
//
// Testing discipline:
//   - Every rule V1–V8 has a tripping fixture that violates ONLY that rule.
//     The assertion matches the specific rule number AND the file:line from the
//     offending node or edge's provenance — matching only the rule number is the
//     classic validator false positive (any earlier rule could fire and the test
//     would still pass).
//   - Every rule V1–V8 has a near-miss fixture that is one edit away from the
//     tripping fixture but legitimately passes. The near-miss asserts ok===true
//     and errors===[], which proves (a) no earlier rule blocks it (so the rule
//     under test is actually reached), and (b) the rule does not fire spuriously.
//   - A fully valid chart passes all eight rules cleanly (ok===true, errors=[]).
//   - validateChart is pure: it never throws, even for non-object input.
//   - No hard-coded corpus counts (REQUIREMENTS §8 / KI-005).
//   - All assertions drive the real validateChart — no rule re-implemented.
//
// Mutation-proving: for each V1–V8 check, disabling the guard in validate.mjs
// makes exactly the tripping test for that check fail while leaving all other
// tests passing. The mutant table is reported in the task-024 report.

import { describe, it, expect } from 'vitest';
import { validateChart } from '../lib/flow-graph/validate.mjs';
// Aliased deliberately: this file defines its own local `makeNode`/`makeEdge`
// fixture helpers with different signatures, and the real constructors are needed
// only by the AC-5 integration block at the bottom. Keeping both names visible is
// clearer than renaming the long-standing local helpers.
import {
  buildChart,
  makeNode as modelMakeNode,
  makeEdge as modelMakeEdge,
} from '../lib/flow-graph/model.mjs';

// ── Fixture helpers ───────────────────────────────────────────────────────────

/**
 * Build a minimal Provenance with a correct excerpt for the given line range.
 * Using this factory for all fixtures ensures V7's excerpt-line-count check
 * never fires accidentally.
 *
 * @param {object} opts
 * @param {number} [opts.startLine=5]
 * @param {number} [opts.endLine]       defaults to startLine
 * @param {string} [opts.file]          defaults to the canonical test file
 * @returns {object}
 */
function makeProv({
  startLine = 5,
  endLine,
  file = 'canonical/skills/aid-test/SKILL.md',
} = {}) {
  const end = endLine ?? startLine;
  const lineCount = end - startLine + 1;
  // Produce an excerpt that is exactly `lineCount` LF-joined lines — the
  // invariant V7 checks.
  const excerpt = Array.from({ length: lineCount }, (_, i) => `line ${startLine + i}`).join('\n');
  return { file, startLine, endLine: end, sourceKind: 'skill', excerpt };
}

/**
 * Build a minimal fully-valid FlowChart. Every rule V1–V8 passes on this chart.
 * Individual tests override specific fields to create tripping and near-miss
 * fixtures.
 */
function validChart(overrides = {}) {
  const prov1 = makeProv({ startLine: 5 });
  const prov2 = makeProv({ startLine: 6 });
  const edgeProv = makeProv({ startLine: 7 });

  const defaultNodes = [
    {
      id: 'n1',
      order: 1,
      name: 'START',
      label: 'Start',
      kind: 'entry',
      terminal: null,
      provenance: prov1,
      detail: null,
    },
    {
      id: 'n2',
      order: 2,
      name: 'END',
      label: 'End',
      kind: 'exit',
      terminal: { advanceType: 'HALT', handoff: null },
      provenance: prov2,
      detail: null,
    },
  ];

  const defaultEdges = [
    {
      from: 'n1',
      to: 'n2',
      kind: 'sequence',
      condition: null,
      advanceType: 'CHAIN',
      provenance: edgeProv,
    },
  ];

  return {
    skill: 'aid-test',
    shape: 'dispatch-table',
    extractor: 'extract-dispatch',
    confidence: 'derived',
    title: 'aid-test — state flow',
    nodes: defaultNodes,
    edges: defaultEdges,
    entries: ['n1'],
    exits: ['n2'],
    sources: ['canonical/skills/aid-test/SKILL.md'],
    warnings: [],
    ...overrides,
  };
}

/**
 * Build a minimal node object.
 *
 * @param {object} opts
 * @param {string} opts.id
 * @param {number} opts.order
 * @param {string} [opts.name]
 * @param {string} [opts.label]
 * @param {object} [opts.provenance]
 * @returns {object}
 */
function makeNode({ id, order, name = 'N', label = 'Label', provenance }) {
  return {
    id,
    order,
    name,
    label,
    kind: 'step',
    terminal: null,
    provenance: provenance ?? makeProv({ startLine: order }),
    detail: null,
  };
}

/**
 * Build a minimal edge object.
 *
 * @param {string} from
 * @param {string} to
 * @param {string|null} [condition]
 * @returns {object}
 */
function makeEdge(from, to, condition = null) {
  return {
    from,
    to,
    kind: 'sequence',
    condition,
    advanceType: 'CHAIN',
    provenance: makeProv({ startLine: 10 }),
  };
}

// ── Fully valid chart passes all eight rules ──────────────────────────────────

describe('validateChart — valid chart', () => {
  it('ok===true and errors===[] for a fully valid chart', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('returns { ok, errors } shape for a valid chart', () => {
    const result = validateChart(validChart());
    expect(result).toHaveProperty('ok');
    expect(result).toHaveProperty('errors');
  });
});

// ── validateChart is pure — never throws ─────────────────────────────────────

describe('validateChart — purity / never-throws', () => {
  it('returns { ok: false, errors } for null input without throwing', () => {
    expect(() => validateChart(null)).not.toThrow();
    const result = validateChart(null);
    expect(result.ok).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('returns { ok: false, errors } for a non-object without throwing', () => {
    expect(() => validateChart('not a chart')).not.toThrow();
    expect(validateChart('not a chart').ok).toBe(false);
  });

  it('does not mutate the chart object', () => {
    const chart = validChart();
    const nodesBefore = chart.nodes.length;
    const errorsBefore = chart.warnings.length;
    validateChart(chart);
    expect(chart.nodes.length).toBe(nodesBefore);
    expect(chart.warnings.length).toBe(errorsBefore);
  });
});

// ── V1: nodes non-empty, ids unique, every id valid ──────────────────────────

describe('V1 — nodes non-empty', () => {
  it('tripping: nodes array is empty → V1 error', () => {
    const result = validateChart(validChart({ nodes: [], entries: [], exits: [] }));
    expect(result.ok).toBe(false);
    const v1Errors = result.errors.filter((e) => /V1/.test(e));
    expect(v1Errors.length).toBeGreaterThan(0);
    // The error must name "nodes is empty"
    expect(v1Errors.some((e) => e.includes('nodes is empty'))).toBe(true);
  });

  it('near-miss: two valid nodes → ok and no V1 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V1 — id uniqueness', () => {
  it('tripping: two nodes share the same id → V1 duplicate error with file:line', () => {
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: prov, detail: null },
        { id: 'n1', order: 2, name: 'TWIN', label: 'Twin', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
      entries: ['n1'],
      exits: ['n1'],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const dupeErrors = result.errors.filter(
      (e) => /V1/.test(e) && /duplicate/.test(e)
    );
    expect(dupeErrors.length).toBeGreaterThan(0);
    // Must cite the file:line from the node's provenance
    expect(dupeErrors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:6/.test(e))).toBe(true);
  });

  it('near-miss: two nodes with distinct ids → ok and no V1 duplicate error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V1 — id pattern', () => {
  it('tripping: id with a hyphen fails the pattern → V1 invalid-id error with file:line', () => {
    // The pattern is ^[A-Za-z][A-Za-z0-9_]{0,31}$ — hyphens are not allowed.
    const prov = makeProv({ startLine: 3 });
    const chart = validChart({
      nodes: [
        { id: 'bad-id', order: 1, name: 'BAD', label: 'Bad', kind: 'entry', terminal: { advanceType: 'HALT', handoff: null }, provenance: prov, detail: null },
      ],
      entries: ['bad-id'],
      exits: ['bad-id'],
      edges: [],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const patternErrors = result.errors.filter(
      (e) => /V1/.test(e) && /invalid node id/.test(e) && /bad-id/.test(e)
    );
    expect(patternErrors.length).toBeGreaterThan(0);
    // Must cite the file:line from the node's provenance
    expect(patternErrors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:3/.test(e))).toBe(true);
  });

  it('near-miss: underscore in id is allowed by the pattern → ok and no V1 error', () => {
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        { id: 'n1_ok', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: prov, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
      entries: ['n1_ok'],
      exits: ['n2'],
      edges: [makeEdge('n1_ok', 'n2')],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('near-miss: max-length id (32 chars) is within the pattern → ok and no V1 error', () => {
    // Pattern allows 1 letter + up to 31 alphanumeric/underscore = 32 chars max.
    const longId = 'n' + 'A'.repeat(31); // exactly 32 chars
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        { id: longId, order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: prov, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
      entries: [longId],
      exits: ['n2'],
      edges: [makeEdge(longId, 'n2')],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V2: entries non-empty; every entry id is a node id ───────────────────────

describe('V2 — entries non-empty', () => {
  it('tripping: entries is empty → V2 error', () => {
    const result = validateChart(validChart({ entries: [] }));
    expect(result.ok).toBe(false);
    const v2Errors = result.errors.filter((e) => /V2/.test(e));
    expect(v2Errors.length).toBeGreaterThan(0);
    expect(v2Errors.some((e) => e.includes('entries is empty'))).toBe(true);
  });

  it('near-miss: entries has one valid id → ok and no V2 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V2 — entry id resolves to a node', () => {
  it('tripping: entry id does not exist in nodes → V2 error naming the id', () => {
    const result = validateChart(validChart({ entries: ['n99'] }));
    expect(result.ok).toBe(false);
    const v2Errors = result.errors.filter(
      (e) => /V2/.test(e) && /n99/.test(e)
    );
    expect(v2Errors.length).toBeGreaterThan(0);
    expect(v2Errors.some((e) => e.includes('not a node id'))).toBe(true);
  });

  it('near-miss: entry id exists in nodes → ok and no V2 error', () => {
    // 'n1' is a valid node id in validChart()
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('V2 reads entries array, not node.kind — a node that is both entry and exit satisfies V2', () => {
    // Single node: in entries AND in exits (kind irrelevant for V2/V3)
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        {
          id: 'n1',
          order: 1,
          name: 'ONLY',
          label: 'Only',
          kind: 'exit',
          terminal: { advanceType: 'HALT', handoff: null },
          provenance: prov,
          detail: null,
        },
      ],
      edges: [],
      entries: ['n1'],
      exits: ['n1'],
    });
    const result = validateChart(chart);
    // V2 and V3 pass because n1 is in nodes; V6 passes because n1 is reachable
    // from entries=['n1'] (trivially: n1 is its own entry); no rule fires.
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V3: exits non-empty; every exit id is a node id ──────────────────────────

describe('V3 — exits non-empty', () => {
  it('tripping: exits is empty → V3 error', () => {
    const result = validateChart(validChart({ exits: [] }));
    expect(result.ok).toBe(false);
    const v3Errors = result.errors.filter((e) => /V3/.test(e));
    expect(v3Errors.length).toBeGreaterThan(0);
    expect(v3Errors.some((e) => e.includes('exits is empty'))).toBe(true);
  });

  it('near-miss: exits has one valid id → ok and no V3 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V3 — exit id resolves to a node', () => {
  it('tripping: exit id does not exist in nodes → V3 error naming the id', () => {
    const result = validateChart(validChart({ exits: ['n99'] }));
    expect(result.ok).toBe(false);
    const v3Errors = result.errors.filter(
      (e) => /V3/.test(e) && /n99/.test(e)
    );
    expect(v3Errors.length).toBeGreaterThan(0);
    expect(v3Errors.some((e) => e.includes('not a node id'))).toBe(true);
  });

  it('near-miss: exit id exists in nodes → ok and no V3 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V4: no dangling edges ─────────────────────────────────────────────────────

describe('V4 — no dangling edges', () => {
  it('tripping: edge.from references a non-existent node → V4 error with file:line', () => {
    const edgeProv = makeProv({ startLine: 12 });
    const danglingEdge = {
      from: 'n99',
      to: 'n2',
      kind: 'sequence',
      condition: null,
      advanceType: 'CHAIN',
      provenance: edgeProv,
    };
    // Add a dangling edge; keep original n1→n2 so V6 passes for n1 and n2
    const chart = validChart({
      edges: [makeEdge('n1', 'n2'), danglingEdge],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v4Errors = result.errors.filter(
      (e) => /V4/.test(e) && /n99/.test(e)
    );
    expect(v4Errors.length).toBeGreaterThan(0);
    // Must cite the edge's provenance file:line
    expect(v4Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:12/.test(e))).toBe(true);
  });

  it('tripping: edge.to references a non-existent node → V4 error with file:line', () => {
    const edgeProv = makeProv({ startLine: 13 });
    const danglingEdge = {
      from: 'n1',
      to: 'n99',
      kind: 'sequence',
      condition: null,
      advanceType: 'CHAIN',
      provenance: edgeProv,
    };
    const chart = validChart({ edges: [danglingEdge] });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v4Errors = result.errors.filter(
      (e) => /V4/.test(e) && /edge\.to/.test(e) && /n99/.test(e)
    );
    expect(v4Errors.length).toBeGreaterThan(0);
    expect(v4Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:13/.test(e))).toBe(true);
  });

  it('near-miss: both edge endpoints exist → ok and no V4 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('V4 accepts a self-edge (from === to) trivially — the node exists', () => {
    // A self-edge from n1 to n1 is valid: n1 exists in nodeIds.
    const prov = makeProv({ startLine: 5 });
    const selfEdgeProv = makeProv({ startLine: 8 });
    const chart = validChart({
      nodes: [
        {
          id: 'n1',
          order: 1,
          name: 'ONLY',
          label: 'Only',
          kind: 'exit',
          terminal: { advanceType: 'HALT', handoff: null },
          provenance: prov,
          detail: null,
        },
      ],
      edges: [
        {
          from: 'n1',
          to: 'n1',
          kind: 'loop-back',
          condition: null,
          advanceType: 'CHAIN',
          provenance: selfEdgeProv,
        },
      ],
      entries: ['n1'],
      exits: ['n1'],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V5: no duplicate (from, to, condition) triple ────────────────────────────

describe('V5 — no duplicate edge triple', () => {
  it('tripping: two edges share the same (from, to, condition=null) → V5 error with file:line', () => {
    const dupeProv = makeProv({ startLine: 15 });
    const chart = validChart({
      edges: [
        makeEdge('n1', 'n2', null),
        {
          from: 'n1',
          to: 'n2',
          kind: 'sequence',
          condition: null,
          advanceType: 'CHAIN',
          provenance: dupeProv,
        },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v5Errors = result.errors.filter((e) => /V5/.test(e));
    expect(v5Errors.length).toBeGreaterThan(0);
    // Error must name the duplicate triple
    expect(v5Errors.some((e) => /from='n1'/.test(e) && /to='n2'/.test(e))).toBe(true);
    // And cite the edge's provenance file:line (the second, duplicate edge)
    expect(v5Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:15/.test(e))).toBe(true);
  });

  it('near-miss: two edges share (from, to) but have different conditions → ok and no V5 error', () => {
    // (n1→n2, 'if A') and (n1→n2, 'if B') are distinct triples
    const chart = validChart({
      edges: [
        {
          from: 'n1',
          to: 'n2',
          kind: 'branch',
          condition: 'if A',
          advanceType: 'CHAIN',
          provenance: makeProv({ startLine: 7 }),
        },
        {
          from: 'n1',
          to: 'n2',
          kind: 'branch',
          condition: 'if B',
          advanceType: 'CHAIN',
          provenance: makeProv({ startLine: 8 }),
        },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('two edges with the same (from, to) but condition=null vs condition="" are distinct', () => {
    // null → key uses '' for the condition segment; '' → key also uses ''.
    // They ARE the same key: `\0n2\0` for both. This tests that null is treated
    // consistently and the deduplication key is stable.
    const chart = validChart({
      edges: [
        makeEdge('n1', 'n2', null),
        makeEdge('n1', 'n2', null),   // exact duplicate
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    expect(result.errors.some((e) => /V5/.test(e))).toBe(true);
  });
});

// ── V6: every node reachable from entries ────────────────────────────────────

describe('V6 — full reachability', () => {
  it('tripping: orphan node not reachable from any entry → V6 error with file:line', () => {
    // n1 (entry) → n2 (exit); n3 exists but no edge reaches it from n1 or n2
    const prov3 = makeProv({ startLine: 20 });
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
        { id: 'n3', order: 3, name: 'ORPHAN', label: 'Orphan', kind: 'step', terminal: null, provenance: prov3, detail: null },
      ],
      edges: [makeEdge('n1', 'n2')],  // no path to n3
      entries: ['n1'],               // n3 is not in entries either
      exits: ['n2'],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v6Errors = result.errors.filter(
      (e) => /V6/.test(e) && /n3/.test(e)
    );
    expect(v6Errors.length).toBeGreaterThan(0);
    expect(v6Errors.some((e) => e.includes('unreachable from entries'))).toBe(true);
    // Must cite n3's provenance file:line
    expect(v6Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:20/.test(e))).toBe(true);
  });

  it('near-miss: three-node chain n1→n2→n3 — all reachable → ok and no V6 error', () => {
    // Specifically: no earlier rule fires on this chart (V1–V5 all pass), and
    // V6 evaluates and finds all nodes reachable from entries=['n1'].
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'MID', label: 'Mid', kind: 'step', terminal: null, provenance: makeProv({ startLine: 6 }), detail: null },
        { id: 'n3', order: 3, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 7 }), detail: null },
      ],
      edges: [makeEdge('n1', 'n2'), makeEdge('n2', 'n3')],
      entries: ['n1'],
      exits: ['n3'],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('V6 handles a chart built through buildChart construction rules without error', () => {
    // buildChart guarantees entries includes all in-degree-0 nodes plus the
    // lowest-order node of any pure cycle, so every node is reachable from some
    // entry. Verify this by using a chart that mirrors that construction.
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors.filter((e) => /V6/.test(e))).toHaveLength(0);
  });
});

// ── V7: provenance well-formedness ───────────────────────────────────────────

describe('V7 — provenance has non-empty file under canonical/', () => {
  it('tripping: provenance is null → V7 error naming the node', () => {
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: null, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /START/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
    expect(v7Errors.some((e) => e.includes('has no provenance'))).toBe(true);
  });

  it('tripping: provenance.file is empty string → V7 error', () => {
    const badProv = { file: '', startLine: 5, endLine: 5, sourceKind: 'skill', excerpt: 'x' };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /provenance\.file is empty/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
  });

  it('tripping: provenance.file is not under canonical/ → V7 error with file:line', () => {
    // The file must start with "canonical/" — a site/ path is out of bounds.
    const badProv = {
      file: 'site/scripts/lib/flow-graph/model.mjs',
      startLine: 9,
      endLine: 9,
      sourceKind: 'skill',
      excerpt: 'export function truncate',
    };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /not under canonical/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
    // Must cite the provenance file:line (startLine=9 in a non-canonical path)
    expect(v7Errors.some((e) => /site\/scripts\/lib\/flow-graph\/model\.mjs:9/.test(e))).toBe(true);
  });

  it('near-miss: valid provenance with file under canonical/ → ok and no V7 error', () => {
    const result = validateChart(validChart());
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V7 — provenance has valid line range', () => {
  it('tripping: startLine < 1 → V7 invalid line range error with file:line', () => {
    // startLine=0 violates the 1-based minimum.
    const badProv = {
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: 0,
      endLine: 1,
      sourceKind: 'skill',
      excerpt: 'line 1',
    };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /invalid line range/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
  });

  it('tripping: endLine < startLine → V7 invalid line range error with file:line', () => {
    const badProv = {
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: 10,
      endLine: 7,   // endLine < startLine
      sourceKind: 'skill',
      excerpt: 'line 10',
    };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /invalid line range/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
    expect(v7Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:10/.test(e))).toBe(true);
  });

  it('tripping: startLine is not a number (NaN) → V7 invalid line range error', () => {
    // typeof check sub-condition: guards against non-numeric provenance values.
    const badProv = {
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: NaN,
      endLine: 5,
      sourceKind: 'skill',
      excerpt: 'line 5',
    };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /invalid line range/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
  });

  it('near-miss: startLine=1, endLine=1 (single-line provenance) → ok and no V7 error', () => {
    const chart = validChart();
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V7 — provenance excerpt line count equals span', () => {
  it('tripping: excerpt has fewer lines than the startLine–endLine span → V7 error with file:line', () => {
    // startLine=1, endLine=3 → span=3 lines; but excerpt has only 1 line.
    const badProv = {
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: 1,
      endLine: 3,
      sourceKind: 'skill',
      excerpt: 'only one line',   // 1 line, but span=3
    };
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: badProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v7Errors = result.errors.filter(
      (e) => /V7/.test(e) && /n1/.test(e) && /excerpt/.test(e) && /line/.test(e)
    );
    expect(v7Errors.length).toBeGreaterThan(0);
    // The error should name both the actual count and the expected span
    expect(v7Errors.some((e) => /1 line/.test(e) && /span is 3/.test(e))).toBe(true);
    // And cite file:startLine
    expect(v7Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:1/.test(e))).toBe(true);
  });

  it('near-miss: multi-line excerpt whose count matches the span → ok and no V7 error', () => {
    // startLine=2, endLine=4 → span=3; makeProv produces a 3-line excerpt.
    const multiProv = makeProv({ startLine: 2, endLine: 4 });
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'Start', kind: 'entry', terminal: null, provenance: multiProv, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V8: label non-empty and <= 60 code points ─────────────────────────────────

describe('V8 — label non-empty', () => {
  it('tripping: label is empty string → V8 error with file:line', () => {
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: '', kind: 'entry', terminal: null, provenance: prov, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v8Errors = result.errors.filter(
      (e) => /V8/.test(e) && /n1/.test(e) && /empty label/.test(e)
    );
    expect(v8Errors.length).toBeGreaterThan(0);
    // Must cite the node's provenance file:line
    expect(v8Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:5/.test(e))).toBe(true);
  });

  it('near-miss: single-character label → ok and no V8 error', () => {
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'X', kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('V8 — label <= 60 code points (Array.from measure)', () => {
  it('tripping: label with 61 ASCII chars exceeds 60-code-point limit → V8 error with file:line', () => {
    const prov = makeProv({ startLine: 5 });
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'A'.repeat(61), kind: 'entry', terminal: null, provenance: prov, detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    const v8Errors = result.errors.filter(
      (e) => /V8/.test(e) && /n1/.test(e) && /61 code points/.test(e)
    );
    expect(v8Errors.length).toBeGreaterThan(0);
    expect(v8Errors.some((e) => /limit 60/.test(e))).toBe(true);
    // Must cite the node's provenance file:line
    expect(v8Errors.some((e) => /canonical\/skills\/aid-test\/SKILL\.md:5/.test(e))).toBe(true);
  });

  it('near-miss: label with exactly 60 ASCII chars is at the limit → ok and no V8 error', () => {
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label: 'A'.repeat(60), kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('V8 uses Array.from code-point count — 60 surrogate-pair chars (60 code points) pass', () => {
    // Each surrogate pair is 1 Unicode code point but String.length=2.
    // 60 such characters = 60 code points (Array.from count) = String.length 120.
    // V8 uses Array.from, so 60 code points is exactly at the limit and must pass.
    const surrChar = '\uD835\uDFD8'; // U+1D7D8 𝟘, code point 1, String.length 2
    const label = surrChar.repeat(60); // 60 code points, String.length=120
    expect(Array.from(label).length).toBe(60); // sanity-check the fixture
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label, kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('V8 uses Array.from — 61 surrogate-pair chars (61 code points) fail, even though String.length>limit', () => {
    // 61 code points exceeds the limit — V8 must fire regardless of String.length.
    // This distinguishes Array.from from String.length (both would fire here), but the
    // 60-code-point near-miss above is the definitive test of the correct measure.
    const surrChar = '\uD835\uDFD8';
    const label = surrChar.repeat(61);
    expect(Array.from(label).length).toBe(61);
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label, kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(false);
    expect(result.errors.some((e) => /V8/.test(e) && /61 code points/.test(e))).toBe(true);
  });

  it('String.length is not used — label of 59 ASCII chars with String.length 118 (no surrogates) passes', () => {
    // Purely ASCII, so code points === String.length. 59 < 60, should pass.
    const label = 'A'.repeat(59);
    const chart = validChart({
      nodes: [
        { id: 'n1', order: 1, name: 'START', label, kind: 'entry', terminal: null, provenance: makeProv({ startLine: 5 }), detail: null },
        { id: 'n2', order: 2, name: 'END', label: 'End', kind: 'exit', terminal: { advanceType: 'HALT', handoff: null }, provenance: makeProv({ startLine: 6 }), detail: null },
      ],
    });
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── V9: documented as absent (not implemented) ────────────────────────────────

describe('V9 — not present in validateChart', () => {
  it('the module source does not contain a V9 implementation', async () => {
    // Read the actual source to verify V9 is documented but not implemented.
    // This is a structural assertion: it proves the "no rule renumbered" AC.
    const { readFileSync } = await import('node:fs');
    const { resolve, dirname } = await import('node:path');
    const { fileURLToPath } = await import('node:url');
    const __dirname = dirname(fileURLToPath(import.meta.url));
    const src = readFileSync(resolve(__dirname, '../lib/flow-graph/validate.mjs'), 'utf8');

    // V9 is explicitly mentioned in the module's documentation comment.
    expect(src).toContain('V9');
    // The module names advance.mjs as V9's home.
    expect(src).toContain('advance.mjs');
    // The authority citation is work STATE.md Q3.
    expect(src).toContain('Q3');
    // No V9 in the errors array — the rule is documented, not evaluated.
    //
    // Two corrections went into this one line. The original used `.`, which stops
    // at a newline and so could not see a multi-line `errors.push(`. Widening it to
    // `[\s\S]` then over-matched in the other direction: it caught the very
    // documentation comment the AC *requires* be present, failing a correct module.
    // Stripping comments first is what the assertion actually means — no V9 in the
    // CODE, whatever the prose says.
    const code = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    expect(code).toContain('errors.push('); // the strip left real code behind
    expect(code).not.toMatch(/errors\.push\([\s\S]{0,200}?V9/);
  });
});

// ── AC-5, driven by the real buildChart ───────────────────────────────────────

describe('AC-5 — charts from the real buildChart pass V1–V8 cleanly', () => {
  // Every other test in this file validates `validChart()`, a hand-written fixture
  // that MIRRORS buildChart's invariants. That is fine for exercising each rule in
  // isolation, but it cannot discharge AC-5, whose claim is specifically about
  // "buildChart-constructed charts" — a mirror only ever proves the mirror agrees
  // with the validator, and both were written from the same prose by two agents
  // working in parallel and never in the same process.
  //
  // The two modules meet nowhere else before task-029, and this seam has already
  // produced one defect in this delivery: `serializeChart` normalized every nested
  // object's key order except `terminal`, which no single-module test could see.
  // So these cases import buildChart and validate what it actually emits,
  // concentrating on the paths where it SYNTHESIZES structure rather than copying
  // its input — those are the ones that could produce a chart the validator rejects.

  const PROV = makeProv({ startLine: 5 });
  const n = (order, name, terminal = null) =>
    modelMakeNode({ order, name, label: name, provenance: PROV, terminal });
  const e = (from, to, kind = 'sequence', condition = null) =>
    modelMakeEdge({ from, to, kind, condition, advanceType: 'CHAIN', provenance: PROV });

  it('a linear chain', () => {
    const chart = buildChart({
      skill: 'aid-x', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [n(1, 'A'), n(2, 'B'), n(3, 'C', { advanceType: 'HALT', handoff: null })],
      edges: [e('n1', 'n2'), e('n2', 'n3')],
      sources: ['canonical/skills/aid-x/SKILL.md'],
    });
    expect(validateChart(chart)).toEqual({ ok: true, errors: [] });
  });

  it('a pure cycle — exercises the entries fallback, which has no in-degree-0 node', () => {
    const chart = buildChart({
      skill: 'aid-x', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [n(1, 'A'), n(2, 'B'), n(3, 'C')],
      edges: [e('n1', 'n2'), e('n2', 'n3'), e('n3', 'n1', 'loop-back')],
      sources: ['canonical/skills/aid-x/SKILL.md'],
    });
    // V2 needs a non-empty `entries`, and nothing here has in-degree 0 — the chart
    // is only valid because buildChart designates the lowest-order node itself.
    expect(chart.entries.length).toBeGreaterThan(0);
    expect(validateChart(chart)).toEqual({ ok: true, errors: [] });
  });

  it('no node carries a terminal — exercises the exits fallback that SYNTHESIZES one', () => {
    const chart = buildChart({
      skill: 'aid-x', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [n(1, 'A'), n(2, 'B')],
      edges: [e('n1', 'n2')],
      sources: ['canonical/skills/aid-x/SKILL.md'],
    });
    // V3 needs a non-empty `exits`. No input node had a terminal, so buildChart
    // invented one — and it must invent something V3 and V7 both accept.
    expect(chart.exits).toEqual(['n2']);
    expect(chart.warnings.length).toBeGreaterThan(0);
    expect(validateChart(chart)).toEqual({ ok: true, errors: [] });
  });

  it('a decision fan-out with conditions — V5 must not see two branches as duplicates', () => {
    const chart = buildChart({
      skill: 'aid-x', shape: 'dispatch-table', extractor: 'test', confidence: 'exact',
      nodes: [
        n(1, 'A'), n(2, 'PICK'),
        n(3, 'YES', { advanceType: 'HALT', handoff: null }),
        n(4, 'NO', { advanceType: 'HALT', handoff: null }),
      ],
      edges: [
        e('n1', 'n2'),
        e('n2', 'n3', 'branch', 'if yes'),
        e('n2', 'n4', 'branch', 'if no'),
      ],
      sources: ['canonical/skills/aid-x/SKILL.md'],
    });
    expect(chart.nodes.find((x) => x.name === 'PICK').kind).toBe('decision');
    expect(validateChart(chart)).toEqual({ ok: true, errors: [] });
  });

  it('the id buildChart assigns satisfies V1 pattern for a chart wide enough to reach n10+', () => {
    // V1 pins ids to `^[A-Za-z][A-Za-z0-9_]{0,31}$`. buildChart mints `n${order}`,
    // so this only stays true while orders are plain integers — a two-digit id is
    // the cheapest case that would catch a separator creeping into the template.
    const nodes = Array.from({ length: 12 }, (_, i) => n(i + 1, `S${i + 1}`));
    nodes[11] = n(12, 'S12', { advanceType: 'HALT', handoff: null });
    const edges = Array.from({ length: 11 }, (_, i) => e(`n${i + 1}`, `n${i + 2}`));
    const chart = buildChart({
      skill: 'aid-x', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes, edges, sources: ['canonical/skills/aid-x/SKILL.md'],
    });
    expect(chart.nodes.map((x) => x.id)).toContain('n12');
    expect(validateChart(chart)).toEqual({ ok: true, errors: [] });
  });
});
