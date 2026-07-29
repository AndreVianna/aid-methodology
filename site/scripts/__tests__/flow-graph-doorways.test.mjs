// flow-graph-doorways.test.mjs — Unit tier for the doorway pipeline.
//
// Four test groups, all using inline fixtures:
//   1. Binding extraction — every rung of both ladders (E1, E2, S1, S2, S3, W1)
//   2. Engine core — memo identity and deep freeze (synthetic 2-state engine)
//   3. Compose purity — no shared object identity with core (not.toBe)
//   4. Degradation — W1–W5, each produces a warning and a still-valid chart
//
// Quality bar observed:
//   • Input separability: each fixture is the only one that satisfies its condition.
//   • Non-vacuity: list/key assertions have bounds that fail on empty inputs.
//   • No numeric corpus or per-shape count literal in this tier.
//   • Compose purity proved by object identity (not.toBe), never deep equality.
//   • Degradation tests assert warning presence, still-valid chart, and no throw.
//   • Separability contrast tests confirm W1/W2/W3/W4/W5 each fire only on their
//     own condition.
//
// Task-039 appends the corpus tier below the END-OF-UNIT-TIER marker.
//
// Run: cd site && npx vitest run scripts/__tests__/flow-graph-doorways.test.mjs

import { describe, it, expect, beforeEach } from 'vitest';
import { readDoorwayBinding, composeDoorwayChart } from '../lib/flow-graph/compose.mjs';
import { getEngineCore } from '../lib/flow-graph/engine-core.mjs';
import {
  extractSiblingDoorway,
  parentChartCache,
} from '../lib/flow-graph/extract-sibling.mjs';
import { validateChart } from '../lib/flow-graph/validate.mjs';
import { makeNode, buildChart } from '../lib/flow-graph/model.mjs';

// ── Shared fixtures ────────────────────────────────────────────────────────────

/**
 * Build a minimal engine document: maintenance note, State Machine table,
 * and per-state sections.  When `note` is supplied it overrides the order in
 * the maintenance note, allowing controlled W5 divergence.  When omitted the
 * note matches the table exactly (no W5).
 *
 * @param {{ states: string[], note?: string }} opts
 * @returns {string}
 */
function engineDoc({ states, note }) {
  const order = note ?? states.join(' -> ');
  const rows = states.map((s, i) => {
    const advance = i === states.length - 1 ? 'HALT' : `CHAIN -> ${states[i + 1]}`;
    return `| ${s} | below | inline | ${advance} |`;
  });
  const sections = states.flatMap((s, i) => {
    const advance = i === states.length - 1 ? 'HALT' : `CHAIN -> ${states[i + 1]}`;
    return [`## State: ${s}`, '', `**Advance:** ${advance}`, ''];
  });
  return [
    '# shortcut-engine', '',
    `> **Maintenance note:** the states in order are ${order}.`, '',
    '## State Machine', '',
    '| State | Detail | Worker | Advance |',
    '|---|---|---|---|',
    ...rows, '',
    ...sections,
  ].join('\n');
}

// A gate document with no B1 triggers, so B1 from the engine can be isolated.
const INERT_GATE = [
  '# work-initiation-gate', '',
  '## State: INTAKE', '',
  'Nothing notable here.', '',
].join('\n');

// Two-state engine whose maintenance note AGREES with the table (no W5).
const MINIMAL_ENGINE = engineDoc({ states: ['INTAKE', 'GATE'] });

// Two-state engine whose maintenance note DISAGREES with the table (W5 fixture).
// Note says GATE -> INTAKE but table rows are INTAKE, GATE — intentional conflict.
const W5_ENGINE = engineDoc({ states: ['INTAKE', 'GATE'], note: 'GATE -> INTAKE' });

/**
 * Build a minimal valid FlowChart for pre-populating parentChartCache.
 * One HALT-terminal node, configurable confidence.
 *
 * @param {string} skillName
 * @param {'derived'|'approximate'} [confidence]
 * @returns {import('../lib/flow-graph/model.mjs').FlowChart}
 */
function makeMinimalParentChart(skillName, confidence = 'derived') {
  const prov = {
    file: `canonical/skills/${skillName}/SKILL.md`,
    startLine: 1,
    endLine: 1,
    sourceKind: 'skill',
    excerpt: '# Parent',
  };
  return buildChart({
    skill: skillName,
    shape: 'inline-states',
    extractor: 'extract-test',
    confidence,
    nodes: [
      makeNode({
        order: 1,
        name: 'DONE',
        label: 'Done',
        provenance: prov,
        terminal: { advanceType: 'HALT', handoff: null },
        detail: null,
      }),
    ],
    edges: [],
    sources: [`canonical/skills/${skillName}/SKILL.md`],
    warnings: [],
  });
}

/**
 * Build a synthetic SkillRecord for extractSiblingDoorway tests.
 * `delegatesTo` is set explicitly so no filesystem read is ever needed.
 *
 * @param {string} dirName
 * @param {string} body
 * @param {string|null} [delegatesTo]
 * @returns {object}
 */
function makeSyntheticRecord(dirName, body, delegatesTo = null) {
  return {
    dirName,
    sourcePath: `canonical/skills/${dirName}/SKILL.md`,
    body,
    bodyStartLine: 1,
    delegatesTo,
  };
}

/**
 * Build a minimal 2-node (c1, c2) deeply-frozen core for compose purity tests.
 * Mirrors the id convention (c1…cN) of the real EngineCore.
 *
 * @returns {{ nodes, edges, exits, sources, warnings }}
 */
function makeFrozenCore() {
  const prov = Object.freeze({
    file: 'canonical/aid/templates/shortcut-engine.md',
    startLine: 1,
    endLine: 1,
    sourceKind: 'engine',
    excerpt: '| X | below | inline | CHAIN -> Y |',
  });
  return Object.freeze({
    nodes: Object.freeze([
      Object.freeze({
        id: 'c1', order: 1, name: 'X', label: 'X',
        kind: 'step', terminal: null, provenance: prov, detail: null,
      }),
      Object.freeze({
        id: 'c2', order: 2, name: 'Y', label: 'Y',
        kind: 'exit',
        terminal: Object.freeze({ advanceType: 'HALT', handoff: null }),
        provenance: prov, detail: null,
      }),
    ]),
    edges: Object.freeze([
      Object.freeze({
        from: 'c1', to: 'c2', kind: 'sequence', condition: null,
        advanceType: 'CHAIN', provenance: prov,
      }),
    ]),
    exits: Object.freeze(['c2']),
    sources: Object.freeze(['canonical/aid/templates/shortcut-engine.md']),
    warnings: Object.freeze([]),
  });
}

// ── Per-test cache isolation ───────────────────────────────────────────────────
// Clear the parent-chart memo before every test to prevent inter-test pollution.
beforeEach(() => { parentChartCache.clear(); });


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 1 — Binding extraction: every rung of both ladders
// ══════════════════════════════════════════════════════════════════════════════

// ── E1 — engine ladder: Bind with backtick artifact ──────────────────────────

describe('E1 — engine ladder: Bind VERB=`create`, ARTIFACT=`api`', () => {
  const body = 'Bind **VERB=`create`**, **ARTIFACT=`api`**';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 5,
    sourcePath: 'canonical/skills/aid-create-api/SKILL.md',
  });

  it('kind is engine', () => {
    expect(b.kind).toBe('engine');
  });

  it('verb is create', () => {
    // Mutation-proof: altering engineMatch[1] capture breaks this.
    expect(b.verb).toBe('create');
  });

  it('artifact is api (backtick form preserved)', () => {
    // Mutation-proof: breaking the backtick branch makes artifact '' (E2 fallback).
    expect(b.artifact).toBe('api');
  });

  it('aliasOf is null (engine doorways carry no alias)', () => {
    expect(b.aliasOf).toBeNull();
  });

  it('no W1 warning emitted (E1 matched)', () => {
    // Separability: only the absence of all patterns reaches W1.
    expect(b.warnings).toEqual([]);
  });

  it('provenance.startLine is 5 (bodyStartLine + body-index 0)', () => {
    expect(b.provenance.startLine).toBe(5);
    expect(b.provenance.endLine).toBe(5);
  });

  it('provenance.excerpt is the Bind line verbatim (never just non-empty)', () => {
    // AC quality-bar rule 5: "never assert non-empty where the criterion says equals."
    expect(b.provenance.excerpt).toBe(body);
  });
});

// ── E2 — engine ladder: Bind with bare-verb form ──────────────────────────────

describe('E2 — engine ladder: Bind VERB=`fix`, ARTIFACT="" (bare verb)', () => {
  const body = 'Bind **VERB=`fix`**, **ARTIFACT="" (bare verb)**';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 7,
    sourcePath: 'canonical/skills/aid-fix/SKILL.md',
  });

  it('kind is engine', () => {
    expect(b.kind).toBe('engine');
  });

  it('verb is fix', () => {
    expect(b.verb).toBe('fix');
  });

  it('artifact is empty string (bare-verb form, not null)', () => {
    // Mutation-proof: dropping the bare-verb branch makes artifact undefined.
    expect(b.artifact).toBe('');
  });

  it('artifact is not null (distinguishes E2 from W1 no-match fallback)', () => {
    expect(b.artifact).not.toBeNull();
  });

  it('no W1 warning emitted (E2 matched)', () => {
    expect(b.warnings).toEqual([]);
  });

  it('provenance.startLine is 7', () => {
    expect(b.provenance.startLine).toBe(7);
  });

  it('provenance.excerpt is the Bind line verbatim', () => {
    expect(b.provenance.excerpt).toBe(body);
  });
});

// ── S1 — sibling ladder: braced group with non-empty artifact ─────────────────

describe('S1 — sibling ladder: {verb: test, artifact: quality}', () => {
  const body = '{verb: test, artifact: quality}';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 3,
    sourcePath: 'canonical/skills/aid-test-quality/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(b.kind).toBe('sibling');
  });

  it('verb is test', () => {
    expect(b.verb).toBe('test');
  });

  it('artifact is quality (non-empty artifact preserved)', () => {
    // Mutation-proof: removing the braced-group regex makes verb=null and W1 fires.
    expect(b.artifact).toBe('quality');
  });

  it('aliasOf is null (kind-sibling, not alias)', () => {
    expect(b.aliasOf).toBeNull();
  });

  it('no W1 warning emitted (S1 matched)', () => {
    expect(b.warnings).toEqual([]);
  });

  it('provenance.excerpt is the braced-group line verbatim', () => {
    expect(b.provenance.excerpt).toBe(body);
  });
});

// ── S2 — sibling ladder: braced group with empty artifact ─────────────────────

describe('S2 — sibling ladder: {verb: document, artifact: ""}', () => {
  const body = '{verb: document, artifact: ""}';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 3,
    sourcePath: 'canonical/skills/aid-document/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(b.kind).toBe('sibling');
  });

  it('verb is document', () => {
    expect(b.verb).toBe('document');
  });

  it('artifact is empty string (the "" token was converted)', () => {
    // Mutation-proof: dropping `if (artifact === '""') artifact = ''` leaves artifact as '""'.
    expect(b.artifact).toBe('');
  });

  it('artifact is not null (S2 is a matched rung, not a W1 fallback)', () => {
    expect(b.artifact).not.toBeNull();
  });

  it('no W1 warning emitted (S2 matched)', () => {
    expect(b.warnings).toEqual([]);
  });

  it('provenance.excerpt is the braced-group line verbatim', () => {
    expect(b.provenance.excerpt).toBe(body);
  });
});

// ── S3 — sibling ladder: alias_of form ────────────────────────────────────────

describe('S3 — sibling ladder: alias_of: aid-create', () => {
  const body = 'alias_of: aid-create';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 4,
    sourcePath: 'canonical/skills/aid-add/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(b.kind).toBe('sibling');
  });

  it('aliasOf is aid-create', () => {
    // Mutation-proof: removing the alias regex makes aliasOf null and W1 fires.
    expect(b.aliasOf).toBe('aid-create');
  });

  it('verb is null for a pure alias', () => {
    expect(b.verb).toBeNull();
  });

  it('artifact is null for a pure alias', () => {
    expect(b.artifact).toBeNull();
  });

  it('no W1 warning emitted (S3 matched)', () => {
    expect(b.warnings).toEqual([]);
  });

  it('provenance.excerpt is the alias_of line verbatim', () => {
    expect(b.provenance.excerpt).toBe(body);
  });
});

// ── W1 binding — no-binding fallback ─────────────────────────────────────────

describe('W1 binding — no pattern matches in body', () => {
  // Separability: none of E1/E2/S1/S2/S3 patterns appear; W1 is the only path.
  const body = '# Unrecognized\nThis skill has no binding form.';
  const b = readDoorwayBinding({
    body,
    bodyStartLine: 3,
    sourcePath: 'canonical/skills/aid-unknown/SKILL.md',
  });

  it('warnings is non-empty (W1 fired) — non-vacuity guard', () => {
    expect(b.warnings.length).toBeGreaterThan(0);
  });

  it('first warning contains W1', () => {
    // Mutation-proof: removing the W1 push makes warnings empty.
    expect(b.warnings[0]).toContain('W1');
  });

  it('W1 warning names the sourcePath (not a generic placeholder)', () => {
    expect(b.warnings[0]).toContain('canonical/skills/aid-unknown/SKILL.md');
  });

  it('verb is null in W1 fallback', () => {
    expect(b.verb).toBeNull();
  });

  it('artifact is null in W1 fallback', () => {
    expect(b.artifact).toBeNull();
  });

  it('aliasOf is null in W1 fallback', () => {
    expect(b.aliasOf).toBeNull();
  });

  it('kind is sibling in W1 fallback', () => {
    expect(b.kind).toBe('sibling');
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 2 — Engine core: memo identity and deep freeze
// ══════════════════════════════════════════════════════════════════════════════

describe('engine core — memo identity', () => {
  it('two calls with no argument return the same object reference', () => {
    // Mutation-proof: removing the `if (_memo !== null) return _memo` check makes a !== b.
    const a = getEngineCore();
    const b = getEngineCore();
    expect(a).toBe(b);
  });

  it('test-seam override returns a DIFFERENT reference from the memo', () => {
    // Separability: the override path deliberately bypasses the memo.
    const memo = getEngineCore();
    const override = getEngineCore({ engineText: MINIMAL_ENGINE, gateText: INERT_GATE });
    expect(override).not.toBe(memo);
  });

  it('test-seam override does not corrupt the memo (no cross-contamination)', () => {
    const before = getEngineCore();
    getEngineCore({ engineText: MINIMAL_ENGINE, gateText: INERT_GATE });
    // The memoized reference must still be the same object.
    expect(getEngineCore()).toBe(before);
  });
});

describe('engine core — deep freeze at every level', () => {
  // Use a synthetic 2-state override so assertions are independent of corpus structure.
  // The AC says "deeply frozen, including nested Provenance — assert a write throws
  // at each level, not just the top object".
  const synth = getEngineCore({ engineText: MINIMAL_ENGINE, gateText: INERT_GATE });

  it('write to nodes array throws (top-level freeze)', () => {
    expect(() => { 'use strict'; synth.nodes.push({}); }).toThrow(TypeError);
  });

  it('write to a node property throws (node-level freeze)', () => {
    expect(() => { 'use strict'; synth.nodes[0].name = 'TAMPERED'; }).toThrow(TypeError);
  });

  it('write to a node provenance.file throws (provenance-level freeze)', () => {
    expect(() => { 'use strict'; synth.nodes[0].provenance.file = 'tampered'; }).toThrow(TypeError);
  });

  it('write to a node provenance.excerpt throws (provenance-level freeze)', () => {
    expect(() => { 'use strict'; synth.nodes[0].provenance.excerpt = 'tampered'; }).toThrow(TypeError);
  });

  it('write to edges array throws', () => {
    expect(() => { 'use strict'; synth.edges.push({}); }).toThrow(TypeError);
  });

  it('write to an edge property throws (edge-level freeze)', () => {
    expect(() => { 'use strict'; synth.edges[0].condition = 'tampered'; }).toThrow(TypeError);
  });

  it('write to an edge provenance.file throws (edge provenance freeze)', () => {
    expect(() => { 'use strict'; synth.edges[0].provenance.file = 'tampered'; }).toThrow(TypeError);
  });

  it('write to exits array throws', () => {
    expect(() => { 'use strict'; synth.exits.push('cx'); }).toThrow(TypeError);
  });

  it('write to sources array throws', () => {
    expect(() => { 'use strict'; synth.sources.push('tampered'); }).toThrow(TypeError);
  });

  it('override result is also deeply frozen (not just the memo)', () => {
    // The test seam must freeze its output regardless of the memo path.
    expect(() => { 'use strict'; synth.nodes[0].kind = 'tampered'; }).toThrow(TypeError);
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 3 — Compose purity: no shared object identity with core
// ══════════════════════════════════════════════════════════════════════════════

describe('engine core — the nine-node spine, in order', () => {
  // task-038's AC places this in the UNIT tier alongside memo identity and the deep
  // freeze. It existed only in the corpus tier, asserted through a live `aid-fix` read,
  // which is a different claim: that one checks a composed doorway page, this one checks
  // the shared core itself. The gate flagged the gap and it is the right call — the core
  // is what every doorway page splices, so its spine deserves an assertion that does not
  // depend on any page.
  const core = getEngineCore();

  it('is the seven State Machine rows with each B1 node after its parent', () => {
    expect(core.nodes.map((n) => n.name)).toEqual([
      'INTAKE',
      'CONTINUATION',      // B1 under INTAKE
      'CAPTURE',
      'SPEC',
      'PLAN',
      'DETAIL',
      'GATE',
      'Circuit breaker',   // B1 under GATE
      'APPROVAL-HALT',
    ]);
  });

  it('each B1 node sits immediately after its parent, not merely somewhere later', () => {
    // Position, not membership: the list assertion above would still pass if the two B1
    // nodes were appended at the end, which is the mistake worth catching.
    const names = core.nodes.map((n) => n.name);
    expect(names.indexOf('CONTINUATION')).toBe(names.indexOf('INTAKE') + 1);
    expect(names.indexOf('Circuit breaker')).toBe(names.indexOf('GATE') + 1);
  });

  it('ids run c1…cN in that same order', () => {
    expect(core.nodes.map((n) => n.id)).toEqual(
      core.nodes.map((_, i) => `c${i + 1}`)
    );
  });
});

describe('compose purity — composed objects share no identity with core', () => {
  // Frozen 2-node (c1, c2) synthetic core — mirrors real EngineCore conventions.
  const frozenCore = makeFrozenCore();

  // Minimal prefix: one entry node + one hop edge to the core's first node.
  // After composeDoorwayChart applies offset=1, c1 becomes n2, c2 becomes n3.
  const prefixProv = {
    file: 'canonical/skills/purity-doorway/SKILL.md',
    startLine: 1,
    endLine: 1,
    sourceKind: 'skill',
    excerpt: 'Bind **VERB=`purity`**, **ARTIFACT=`test`**',
  };
  const prefixNode = {
    id: 'n1', order: 1, name: 'purity-doorway', label: 'Purity Doorway',
    kind: 'entry', terminal: null, provenance: prefixProv, detail: null,
  };
  const hopEdge = {
    from: 'n1', to: 'n2', kind: 'sequence', condition: null,
    advanceType: 'CHAIN', provenance: prefixProv,
  };

  const chart = composeDoorwayChart({
    skill: 'purity-doorway',
    prefixNodes: [prefixNode],
    prefixEdges: [hopEdge],
    core: frozenCore,
    confidence: 'derived',
  });

  it('non-vacuity: core has at least one node (guard for the identity loop)', () => {
    expect(frozenCore.nodes.length).toBeGreaterThan(0);
  });

  it('non-vacuity: core has at least one edge (guard for the identity loop)', () => {
    expect(frozenCore.edges.length).toBeGreaterThan(0);
  });

  it('no composed node is the same reference as any core node (not.toBe)', () => {
    // Deep equality would pass for a shared reference; only not.toBe catches the bug.
    for (const coreNode of frozenCore.nodes) {
      for (const composedNode of chart.nodes) {
        expect(composedNode).not.toBe(coreNode);
      }
    }
  });

  it('no composed edge is the same reference as any core edge (not.toBe)', () => {
    for (const coreEdge of frozenCore.edges) {
      for (const composedEdge of chart.edges) {
        expect(composedEdge).not.toBe(coreEdge);
      }
    }
  });

  it('composed nodes array itself is new — not the same reference as core.nodes', () => {
    expect(chart.nodes).not.toBe(frozenCore.nodes);
  });

  it('composed exits array is new — not the same reference as core.exits', () => {
    expect(chart.exits).not.toBe(frozenCore.exits);
  });

  it('composed warnings array is new — not the same reference as core.warnings', () => {
    expect(chart.warnings).not.toBe(frozenCore.warnings);
  });

  it('core is unmutated after composition — still frozen (write attempt throws)', () => {
    // Verifies purity: composition must read the core, not mutate it.
    expect(() => { 'use strict'; frozenCore.nodes[0].name = 'MUTATED'; }).toThrow(TypeError);
  });

  it('core c1 (name X, order 1) is remapped to id n2 in the composed chart', () => {
    // Non-vacuity: the remapping must actually produce a different id.
    const n2 = chart.nodes.find((n) => n.id === 'n2');
    expect(n2).toBeDefined();
    // Content is preserved — only id and order change.
    expect(n2.name).toBe('X');
  });

  it('core c2 (name Y, order 2) is remapped to id n3 in the composed chart', () => {
    const n3 = chart.nodes.find((n) => n.id === 'n3');
    expect(n3).toBeDefined();
    expect(n3.name).toBe('Y');
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 4 — Degradation: W1–W5 (warning + still-valid chart + no throw)
// ══════════════════════════════════════════════════════════════════════════════

// ── W1 degradation ────────────────────────────────────────────────────────────

describe('W1 degradation — no binding form matched; still-valid chart produced', () => {
  // Separability: body has none of E1/E2/S1/S2/S3 patterns → W1 is the only warning.
  // Parent is derived and in cache → W3/W4 cannot fire.
  // Body has no H2 sections → W2 cannot fire.
  const W1_BODY = '# No binding\nThis skill has no recognized binding form.';

  it('does not throw (W1 is degraded, never fatal)', () => {
    parentChartCache.set('w1-parent', makeMinimalParentChart('w1-parent'));
    expect(() => {
      extractSiblingDoorway(makeSyntheticRecord('w1-doorway', W1_BODY, 'w1-parent'));
    }).not.toThrow();
  });

  it('chart.warnings includes W1 (non-vacuity: at least one W1)', () => {
    parentChartCache.set('w1-parent', makeMinimalParentChart('w1-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w1-doorway', W1_BODY, 'w1-parent')
    );
    expect(chart.warnings.filter((w) => w.includes('W1')).length).toBeGreaterThan(0);
  });

  it('W1 warning names the skill source path (not a generic message)', () => {
    // Mutation-proof: removing the W1 push makes this fail.
    parentChartCache.set('w1-parent', makeMinimalParentChart('w1-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w1-doorway', W1_BODY, 'w1-parent')
    );
    const w1 = chart.warnings.find((w) => w.includes('W1'));
    expect(w1).toContain('canonical/skills/w1-doorway/SKILL.md');
  });

  it('validateChart returns ok: true (still-valid chart despite W1)', () => {
    parentChartCache.set('w1-parent', makeMinimalParentChart('w1-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w1-doorway', W1_BODY, 'w1-parent')
    );
    expect(validateChart(chart).ok).toBe(true);
  });

  it('W1 does NOT fire when a binding pattern is present (separability)', () => {
    // A body with an S1 pattern fires no W1 — absence of all patterns is the condition.
    parentChartCache.set('w1-parent', makeMinimalParentChart('w1-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w1-present', '{verb: test, artifact: present}', 'w1-parent')
    );
    expect(chart.warnings.filter((w) => w.includes('W1'))).toEqual([]);
  });
});

// ── W2 degradation ────────────────────────────────────────────────────────────

describe('W2 degradation — H2 sections in sibling body; still-valid chart produced', () => {
  // Separability: binding matches S1 (no W1), parent is derived (no W4), no cycle (no W3).
  // The H2 section is the only new condition that fires W2.
  const W2_BODY = '{verb: test, artifact: w2}\n\n## Approach\n\nSection content.';

  it('does not throw (W2 is degraded, never fatal)', () => {
    parentChartCache.set('w2-parent', makeMinimalParentChart('w2-parent'));
    expect(() => {
      extractSiblingDoorway(makeSyntheticRecord('w2-doorway', W2_BODY, 'w2-parent'));
    }).not.toThrow();
  });

  it('chart.warnings includes W2 (non-vacuity: at least one W2)', () => {
    parentChartCache.set('w2-parent', makeMinimalParentChart('w2-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w2-doorway', W2_BODY, 'w2-parent')
    );
    expect(chart.warnings.filter((w) => w.includes('W2')).length).toBeGreaterThan(0);
  });

  it('W2 warning names the undrawable H2 section title', () => {
    // 'Approach' is the specific title from the fixture — not a generic non-empty check.
    parentChartCache.set('w2-parent', makeMinimalParentChart('w2-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w2-doorway', W2_BODY, 'w2-parent')
    );
    const w2 = chart.warnings.find((w) => w.includes('W2'));
    expect(w2).toContain('Approach');
  });

  it('validateChart returns ok: true (still-valid chart despite W2)', () => {
    parentChartCache.set('w2-parent', makeMinimalParentChart('w2-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w2-doorway', W2_BODY, 'w2-parent')
    );
    expect(validateChart(chart).ok).toBe(true);
  });

  it('W2 does NOT fire when body has no H2 sections (separability)', () => {
    // Identical setup but no ## heading in body.
    parentChartCache.set('w2-parent', makeMinimalParentChart('w2-parent'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w2-no-h2', '{verb: test, artifact: noh2}', 'w2-parent')
    );
    expect(chart.warnings.filter((w) => w.includes('W2'))).toEqual([]);
  });
});

// ── W3 degradation ────────────────────────────────────────────────────────────

describe('W3 degradation — cycle detected; still-valid fallback chart produced', () => {
  // Cycle: delegatesTo === dirName (skill delegates to itself).
  // _resolveChain detects this at hop 0 in the visited-set check — before any
  // filesystem read — so this test requires no vi.mock.
  const W3_SKILL = 'w3-cycle';
  const W3_BODY = '{verb: cycle, artifact: test}';

  it('does not throw (W3 is degraded, never fatal)', () => {
    expect(() => {
      extractSiblingDoorway(makeSyntheticRecord(W3_SKILL, W3_BODY, W3_SKILL));
    }).not.toThrow();
  });

  it('chart.warnings includes W3 (non-vacuity: at least one W3)', () => {
    const chart = extractSiblingDoorway(
      makeSyntheticRecord(W3_SKILL, W3_BODY, W3_SKILL)
    );
    expect(chart.warnings.filter((w) => w.includes('W3')).length).toBeGreaterThan(0);
  });

  it('W3 warning text mentions cycle detection', () => {
    // 'cycle' is the discriminating word in the message — not just 'W3'.
    const chart = extractSiblingDoorway(
      makeSyntheticRecord(W3_SKILL, W3_BODY, W3_SKILL)
    );
    const w3 = chart.warnings.find((w) => w.includes('W3'));
    expect(w3).toContain('cycle');
  });

  it('validateChart returns ok: true (fallback chart is structurally valid)', () => {
    const chart = extractSiblingDoorway(
      makeSyntheticRecord(W3_SKILL, W3_BODY, W3_SKILL)
    );
    expect(validateChart(chart).ok).toBe(true);
  });

  it('W3 does NOT fire when parent is in cache (separability)', () => {
    parentChartCache.set('w3-ok', makeMinimalParentChart('w3-ok'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w3-ok-doorway', '{verb: test, artifact: ok}', 'w3-ok')
    );
    expect(chart.warnings.filter((w) => w.includes('W3'))).toEqual([]);
  });
});

// ── W4 degradation ────────────────────────────────────────────────────────────

describe('W4 degradation — approximate parent weakens confidence; still-valid chart produced', () => {
  // Separability: body matches S1 (no W1), parent is in cache (no W3), no H2 (no W2).
  // The sole condition under test is parent.confidence === 'approximate'.
  const W4_BODY = '{verb: test, artifact: w4}';

  it('does not throw (W4 is degraded, never fatal)', () => {
    parentChartCache.set('w4-parent', makeMinimalParentChart('w4-parent', 'approximate'));
    expect(() => {
      extractSiblingDoorway(makeSyntheticRecord('w4-doorway', W4_BODY, 'w4-parent'));
    }).not.toThrow();
  });

  it('chart.warnings includes W4 (non-vacuity: at least one W4)', () => {
    parentChartCache.set('w4-parent', makeMinimalParentChart('w4-parent', 'approximate'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w4-doorway', W4_BODY, 'w4-parent')
    );
    expect(chart.warnings.filter((w) => w.includes('W4')).length).toBeGreaterThan(0);
  });

  it('confidence is approximate when parent is approximate', () => {
    // Mutation-proof: removing the W4 confidence assignment leaves confidence 'derived'.
    parentChartCache.set('w4-parent', makeMinimalParentChart('w4-parent', 'approximate'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w4-doorway', W4_BODY, 'w4-parent')
    );
    expect(chart.confidence).toBe('approximate');
  });

  it('W4 warning names the approximate parent skill', () => {
    parentChartCache.set('w4-parent', makeMinimalParentChart('w4-parent', 'approximate'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w4-doorway', W4_BODY, 'w4-parent')
    );
    const w4 = chart.warnings.find((w) => w.includes('W4'));
    expect(w4).toContain('w4-parent');
  });

  it('validateChart returns ok: true (still-valid chart despite W4)', () => {
    parentChartCache.set('w4-parent', makeMinimalParentChart('w4-parent', 'approximate'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w4-doorway', W4_BODY, 'w4-parent')
    );
    expect(validateChart(chart).ok).toBe(true);
  });

  it('confidence is derived and no W4 when parent is derived (separability)', () => {
    // Same body, but parent.confidence === 'derived' — W4 must not fire.
    parentChartCache.set('w4-derived', makeMinimalParentChart('w4-derived', 'derived'));
    const chart = extractSiblingDoorway(
      makeSyntheticRecord('w4-derived-check', W4_BODY, 'w4-derived')
    );
    expect(chart.confidence).toBe('derived');
    expect(chart.warnings.filter((w) => w.includes('W4'))).toEqual([]);
  });
});

// ── W5 degradation ────────────────────────────────────────────────────────────

describe('W5 degradation — engine table order disagrees with Maintenance note', () => {
  // W5_ENGINE: note says 'GATE -> INTAKE' but table rows are INTAKE, GATE.
  // _checkMaintenanceNote detects the disagreement and emits W5 without throwing.

  it('getEngineCore does not throw even when note disagrees with table', () => {
    expect(() => {
      getEngineCore({ engineText: W5_ENGINE, gateText: INERT_GATE });
    }).not.toThrow();
  });

  it('core.warnings includes W5 (non-vacuity: at least one W5)', () => {
    const core = getEngineCore({ engineText: W5_ENGINE, gateText: INERT_GATE });
    expect(core.warnings.filter((w) => w.includes('W5')).length).toBeGreaterThan(0);
  });

  it('W5 warning names both the table and note orders', () => {
    // "never non-empty" — the criterion is that specific state names appear.
    const core = getEngineCore({ engineText: W5_ENGINE, gateText: INERT_GATE });
    const w5 = core.warnings.find((w) => w.includes('W5'));
    expect(w5).toContain('INTAKE');
    expect(w5).toContain('GATE');
  });

  it('core remains structurally usable despite W5 (non-vacuity: nodes and exits exist)', () => {
    // W5 must not destroy the derivation — the core must still have nodes and exits.
    const core = getEngineCore({ engineText: W5_ENGINE, gateText: INERT_GATE });
    expect(core.nodes.length).toBeGreaterThan(0);
    expect(core.exits.length).toBeGreaterThan(0);
  });

  it('a chart composed from the W5 core passes validateChart (still-valid chart)', () => {
    const core = getEngineCore({ engineText: W5_ENGINE, gateText: INERT_GATE });
    const prov = {
      file: 'canonical/skills/w5-doorway/SKILL.md',
      startLine: 1,
      endLine: 1,
      sourceKind: 'skill',
      excerpt: 'Bind **VERB=`w5`**, **ARTIFACT=`doorway`**',
    };
    const prefixNode = {
      id: 'n1', order: 1, name: 'w5-doorway', label: 'W5 Doorway',
      kind: 'entry', terminal: null, provenance: prov, detail: null,
    };
    // Hop targets the first core node (c1, order=1) which becomes n2 after offset=1.
    const hopEdge = {
      from: 'n1', to: 'n2', kind: 'sequence', condition: null,
      advanceType: 'CHAIN', provenance: prov,
    };
    const chart = composeDoorwayChart({
      skill: 'w5-doorway',
      prefixNodes: [prefixNode],
      prefixEdges: [hopEdge],
      core,
      confidence: 'derived',
    });
    expect(validateChart(chart).ok).toBe(true);
  });

  it('W5 does NOT fire when note agrees with table (separability)', () => {
    // MINIMAL_ENGINE has note 'INTAKE -> GATE' which matches the table rows INTAKE, GATE.
    const core = getEngineCore({ engineText: MINIMAL_ENGINE, gateText: INERT_GATE });
    expect(core.warnings.filter((w) => w.includes('W5'))).toEqual([]);
  });
});


// ── END OF UNIT TIER (task-038) ────────────────────────────────────────────────
// Task-039 appends the corpus tier below this line.

// ── Corpus tier imports ───────────────────────────────────────────────────────
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { buildFlowChart, renderMermaid, serializeChart } from '../lib/flow-graph/index.mjs';
import { sliceLines } from '../lib/flow-graph/source.mjs';
import { BODY_PROVIDERS } from '../skills/body.mjs';
import { REPO_ROOT, CANONICAL_SKILLS_DIR } from '../skills/paths.mjs';

// ── Corpus tier helpers ───────────────────────────────────────────────────────

/**
 * Build the live chart for a skill under the work-001 repo root.
 * All corpus-tier tests call this instead of importing REPO_ROOT directly
 * into each describe block.
 */
function liveChart(name) {
  return buildFlowChart({ name, dir: REPO_ROOT });
}

/**
 * Return all skill directory names under canonical/skills/ (the live listing).
 * Non-vacuity guards call this once and assert length > 0.
 */
function liveSkillNames() {
  return readdirSync(CANONICAL_SKILLS_DIR);
}

/**
 * For cross-page identity: remove the two per-page lines from a Mermaid output —
 * the n1 node declaration (which carries the per-skill name and binding label)
 * and the hop-edge line (n1 --> n2).  Everything else is shared engine segment.
 *
 * Filter is: skip any line matching /^\s+n1\(\[/ (the entry-node declaration)
 * and the literal hop-edge string '  n1 --> n2'.  These are the only lines that
 * differ between engine-doorway skills in the Mermaid output.
 *
 * @param {string} mermaid  Full renderMermaid output.
 * @returns {string}        Mermaid with per-page lines removed.
 */
function stripEnginePerPageLines(mermaid) {
  const ENTRY_DECL_RE = /^\s+n1\(\[/;
  return mermaid.split('\n')
    .filter((line) => !ENTRY_DECL_RE.test(line) && line !== '  n1 --> n2')
    .join('\n');
}

/**
 * For splice fidelity: apply the id/order offset of `offset` to an array of
 * parent nodes, producing the expected composed node ids and orders.
 *
 * @param {import('../lib/flow-graph/model.mjs').FlowNode[]} parentNodes
 * @param {number} offset
 * @returns {import('../lib/flow-graph/model.mjs').FlowNode[]}
 */
function applyNodeOffset(parentNodes, offset) {
  return parentNodes.map((n) => ({
    ...n,
    id: 'n' + (n.order + offset),
    order: n.order + offset,
  }));
}

/**
 * For splice fidelity: remap edge from/to ids by adding `offset` to the
 * numeric part of each id (e.g. 'n1' → 'n2' when offset=1).
 *
 * @param {import('../lib/flow-graph/model.mjs').FlowEdge[]} parentEdges
 * @param {number} offset
 * @returns {import('../lib/flow-graph/model.mjs').FlowEdge[]}
 */
function applyEdgeOffset(parentEdges, offset) {
  return parentEdges.map((e) => {
    const fromN = parseInt(e.from.slice(1), 10);
    const toN = parseInt(e.to.slice(1), 10);
    return { ...e, from: 'n' + (fromN + offset), to: 'n' + (toN + offset) };
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// GROUP 5 — AC-4 fixture 1: aid-create-api (engine-doorway to engine)
// ══════════════════════════════════════════════════════════════════════════════
//
// Quality bar observed:
//   • Input separability: shape/extractor/confidence assertions are specific
//     strings, not "non-empty".
//   • KNOWN-DEFECTIVE AC (accepted by orchestrator per task-035 IMPEDIMENT):
//     the AC requires terminal.handoff to mention '/aid-execute', but the live
//     handoff is "No branch is created; no ### Tasks lifecycle row advances past
//     Pending …" — /aid-execute appears only in APPROVAL-HALT's section prose,
//     not in its **Advance:** clause, which is the only text handoff derives from.
//     We assert terminal.advanceType === 'HALT' and the real handoff substring
//     instead, and note this deviation in the task report.

describe('AC-4 fixture 1 — aid-create-api: shape, extractor, confidence, entries', () => {
  // Build once for the describe block.
  const chart = liveChart('aid-create-api');

  it('shape is engine-doorway', () => {
    // Mutation-proof: changing 'engine-doorway' to any other value in the
    // call to composeDoorwayChart in extract-engine.mjs would fail this.
    expect(chart.shape).toBe('engine-doorway');
  });

  it('extractor is extract-engine', () => {
    expect(chart.extractor).toBe('extract-engine');
  });

  it('confidence is derived', () => {
    expect(chart.confidence).toBe('derived');
  });

  it('entries is exactly [nodes[0].id] — one entry, the doorway node', () => {
    // Non-vacuity: entries must have exactly one element.
    expect(chart.entries).toHaveLength(1);
    expect(chart.entries[0]).toBe(chart.nodes[0].id);
  });

  it('entry label contains VERB=create (verbatim match)', () => {
    // Mutation-proof: altering the verb capture in _ENGINE_BIND_RE would break this.
    expect(chart.nodes[0].label).toContain('VERB=create');
  });

  it('entry label contains ARTIFACT=api (verbatim match)', () => {
    // Mutation-proof: altering the artifact capture would break this.
    expect(chart.nodes[0].label).toContain('ARTIFACT=api');
  });
});

describe('AC-4 fixture 1 — aid-create-api: the loop (self-edge)', () => {
  const chart = liveChart('aid-create-api');
  const selfEdges = chart.edges.filter((e) => e.from === e.to);

  it('exactly one self-edge in the chart (non-vacuity bound)', () => {
    // Mutation-proof: adding or removing a self-edge in engine-core.mjs changes length.
    expect(selfEdges).toHaveLength(1);
  });

  it('self-edge from === to === GATE id (n8)', () => {
    const gateNode = chart.nodes.find((n) => n.name === 'GATE');
    expect(selfEdges[0].from).toBe(gateNode.id);
    expect(selfEdges[0].to).toBe(gateNode.id);
  });

  it('self-edge kind is loop-back', () => {
    // Mutation-proof: changing the loop kind in engine-core.mjs would fail this.
    expect(selfEdges[0].kind).toBe('loop-back');
  });

  it('self-edge provenance.file cites shortcut-engine.md', () => {
    // The loop-back edge is derived from the engine template, not the skill.
    expect(selfEdges[0].provenance.file).toBe(
      'canonical/aid/templates/shortcut-engine.md'
    );
  });
});

describe('AC-4 fixture 1 — aid-create-api: INTAKE branch (the decision node)', () => {
  const chart = liveChart('aid-create-api');
  const intakeNode = chart.nodes.find((n) => n.name === 'INTAKE');
  const intakeEdges = chart.edges.filter(
    (e) => e.from === intakeNode.id && e.kind === 'branch'
  );

  it('INTAKE node kind is decision', () => {
    // Mutation-proof: engine-core.mjs sets INTAKE as a decision node.
    expect(intakeNode.kind).toBe('decision');
  });

  it('exactly two branch edges leave INTAKE (non-vacuity bound)', () => {
    expect(intakeEdges).toHaveLength(2);
  });

  it('one INTAKE branch edge goes to CONTINUATION with condition On continuation (verbatim)', () => {
    const continuationNode = chart.nodes.find((n) => n.name === 'CONTINUATION');
    const edge = intakeEdges.find((e) => e.to === continuationNode.id);
    // Mutation-proof: changing the condition string in engine-core.mjs would break this.
    expect(edge).toBeDefined();
    expect(edge.condition).toBe('On continuation');
  });

  it('one INTAKE branch edge goes to CAPTURE with condition On new work (verbatim)', () => {
    const captureNode = chart.nodes.find((n) => n.name === 'CAPTURE');
    const edge = intakeEdges.find((e) => e.to === captureNode.id);
    expect(edge).toBeDefined();
    expect(edge.condition).toBe('On new work');
  });
});

describe('AC-4 fixture 1 — aid-create-api: GATE (3 outgoing edges)', () => {
  const chart = liveChart('aid-create-api');
  const gateNode = chart.nodes.find((n) => n.name === 'GATE');
  const gateEdges = chart.edges.filter((e) => e.from === gateNode.id);

  it('GATE node kind is decision', () => {
    expect(gateNode.kind).toBe('decision');
  });

  it('GATE has exactly 3 outgoing edges (2 branch + 1 loop-back)', () => {
    // Mutation-proof: removing any GATE edge in engine-core.mjs changes length.
    expect(gateEdges).toHaveLength(3);
  });

  it('GATE outgoing edges include exactly 2 branch kinds', () => {
    expect(gateEdges.filter((e) => e.kind === 'branch')).toHaveLength(2);
  });

  it('GATE outgoing edges include exactly 1 loop-back kind (the self-edge)', () => {
    expect(gateEdges.filter((e) => e.kind === 'loop-back')).toHaveLength(1);
  });

  it('GATE has a branch edge to APPROVAL-HALT (condition null)', () => {
    const ahNode = chart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    const edge = gateEdges.find(
      (e) => e.kind === 'branch' && e.to === ahNode.id && e.condition === null
    );
    expect(edge).toBeDefined();
  });

  it('GATE has a branch edge to Circuit breaker (non-null condition)', () => {
    const cbNode = chart.nodes.find((n) => n.name === 'Circuit breaker');
    const edge = gateEdges.find(
      (e) => e.kind === 'branch' && e.to === cbNode.id && e.condition !== null
    );
    expect(edge).toBeDefined();
  });
});

describe('AC-4 fixture 1 — aid-create-api: exits (APPROVAL-HALT, CONTINUATION, Circuit breaker)', () => {
  const chart = liveChart('aid-create-api');

  it('exits contains the id of APPROVAL-HALT', () => {
    const ahNode = chart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(chart.exits).toContain(ahNode.id);
  });

  it('exits contains the id of CONTINUATION', () => {
    const contNode = chart.nodes.find((n) => n.name === 'CONTINUATION');
    expect(chart.exits).toContain(contNode.id);
  });

  it('exits contains the id of Circuit breaker', () => {
    const cbNode = chart.nodes.find((n) => n.name === 'Circuit breaker');
    expect(chart.exits).toContain(cbNode.id);
  });

  it('APPROVAL-HALT terminal.advanceType is HALT', () => {
    const ahNode = chart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    // Mutation-proof: changing advanceType in engine-core.mjs would break this.
    expect(ahNode.terminal.advanceType).toBe('HALT');
  });

  it('APPROVAL-HALT terminal.handoff is a non-null string citing the halt behaviour', () => {
    // KNOWN-DEFECTIVE AC: the DETAIL says handoff must mention '/aid-execute'.
    // Measured: /aid-execute appears three times in APPROVAL-HALT's section PROSE
    // and zero times in its **Advance:** clause, which is the only text `handoff`
    // derives from.  task-035 filed an identical IMPEDIMENT; orchestrator accepted
    // it as a DETAIL defect.  We assert the real handoff substring instead.
    // Do NOT modify engine-core.mjs or shortcut-engine.md.
    const ahNode = chart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(ahNode.terminal.handoff).not.toBeNull();
    expect(ahNode.terminal.handoff).toContain('No branch is created');
  });
});

describe('AC-4 fixture 1 — aid-create-api: the spine (node order)', () => {
  const chart = liveChart('aid-create-api');
  const EXPECTED_SPINE = [
    'aid-create-api',
    'INTAKE',
    'CONTINUATION',
    'CAPTURE',
    'SPEC',
    'PLAN',
    'DETAIL',
    'GATE',
    'Circuit breaker',
    'APPROVAL-HALT',
  ];

  it('chart has exactly 10 nodes (1 doorway + 9 engine segment)', () => {
    // Mutation-proof: a change to the engine state machine changes this count.
    expect(chart.nodes).toHaveLength(EXPECTED_SPINE.length);
  });

  it('node names in ascending order equal the expected spine (verbatim)', () => {
    // Sorted by order ascending — same order chart.nodes is already stored in.
    const actual = [...chart.nodes]
      .sort((a, b) => a.order - b.order)
      .map((n) => n.name);
    // Must equal, not just contain — any extra or missing name fails.
    expect(actual).toEqual(EXPECTED_SPINE);
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 6 — AC-4 fixture 1 (lighter): aid-fix (bare-verb binding)
// ══════════════════════════════════════════════════════════════════════════════

describe('AC-4 fixture 1 (lighter) — aid-fix: bare-verb binding and engine spine', () => {
  const chart = liveChart('aid-fix');

  it('entry label contains ARTIFACT="" (bare verb) — bare-verb form carried verbatim', () => {
    // Mutation-proof: breaking the bare-verb detection in extract-engine.mjs would
    // change the label to 'ARTIFACT=undefined' or similar.
    expect(chart.nodes[0].label).toContain('ARTIFACT="" (bare verb)');
  });

  it('nine engine-segment node names match the expected engine spine', () => {
    // Non-vacuity: the slice must have 9 nodes.
    const ENGINE_SPINE = [
      'INTAKE', 'CONTINUATION', 'CAPTURE', 'SPEC', 'PLAN',
      'DETAIL', 'GATE', 'Circuit breaker', 'APPROVAL-HALT',
    ];
    const actual = chart.nodes.slice(1).map((n) => n.name);
    expect(actual).toHaveLength(ENGINE_SPINE.length);
    expect(actual).toEqual(ENGINE_SPINE);
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 7 — AC-4 fixture 2: aid-test-security (sibling-doorway to kind-sibling)
// ══════════════════════════════════════════════════════════════════════════════

describe('AC-4 fixture 2 — aid-test-security: shape, confidence, parent', () => {
  const chart = liveChart('aid-test-security');

  it('shape is sibling-doorway', () => {
    expect(chart.shape).toBe('sibling-doorway');
  });

  it('confidence is derived (parent aid-test is derived)', () => {
    expect(chart.confidence).toBe('derived');
  });
});

describe('AC-4 fixture 2 — aid-test-security: hop edge (the delegation)', () => {
  const chart = liveChart('aid-test-security');
  const entryNode = chart.nodes[0];
  const hopEdges = chart.edges.filter((e) => e.from === entryNode.id);

  it('non-vacuity: chart has at least two nodes (doorway + spliced parent)', () => {
    expect(chart.nodes.length).toBeGreaterThan(1);
  });

  it('exactly one hop edge leaves the entry node', () => {
    expect(hopEdges).toHaveLength(1);
  });

  it('hop edge kind is sequence', () => {
    expect(hopEdges[0].kind).toBe('sequence');
  });

  it('hop edge condition is kind bound to security (verbatim)', () => {
    // Mutation-proof: altering the _BOUND_RE capture in compose.mjs breaks this.
    expect(hopEdges[0].condition).toBe('kind bound to security');
  });

  it('hop edge provenance.sourceKind is sibling', () => {
    // Mutation-proof: the sibling extractor sets sourceKind: 'sibling' explicitly
    // in the hopProvenance override — changing that would fail this.
    expect(hopEdges[0].provenance.sourceKind).toBe('sibling');
  });

  it('hop edge targets the parent entry node (chart.nodes[1])', () => {
    // The parent chart's first node (order 1) becomes n2 after offset=1.
    expect(hopEdges[0].to).toBe(chart.nodes[1].id);
  });
});

describe('AC-4 fixture 2 — aid-test-security: spliced parent spine and provenance', () => {
  const chart = liveChart('aid-test-security');
  const PARENT_SKILL = 'aid-test';
  const PARENT_SKILL_MD = `canonical/skills/${PARENT_SKILL}/SKILL.md`;
  const EXPECTED_SPINE = ['INTAKE', 'RUN', 'VERIFY', 'PRESENT', 'HANDOFF', 'DONE'];

  it('exactly six nodes after the entry node (parent spine only)', () => {
    expect(chart.nodes.slice(1)).toHaveLength(EXPECTED_SPINE.length);
  });

  it('spliced node names are the aid-test six-state spine in order (verbatim)', () => {
    const actual = chart.nodes.slice(1).map((n) => n.name);
    expect(actual).toEqual(EXPECTED_SPINE);
  });

  it('every spliced node provenance.file points at aid-test SKILL.md (not the sibling)', () => {
    // Mutation-proof: if composeDoorwayChart does not copy provenance faithfully,
    // some nodes would cite the sibling's own SKILL.md.
    for (const node of chart.nodes.slice(1)) {
      expect(node.provenance.file).toBe(PARENT_SKILL_MD);
    }
  });
});

describe('AC-4 fixture 2 — aid-test-security: VERIFY→RUN loop-back', () => {
  const chart = liveChart('aid-test-security');
  const verifyNode = chart.nodes.find((n) => n.name === 'VERIFY');
  const runNode = chart.nodes.find((n) => n.name === 'RUN');

  it('VERIFY node exists in the chart', () => {
    expect(verifyNode).toBeDefined();
  });

  it('RUN node exists in the chart', () => {
    expect(runNode).toBeDefined();
  });

  it('a loop-back edge from VERIFY to RUN exists', () => {
    const loopEdge = chart.edges.find(
      (e) => e.from === verifyNode.id && e.to === runNode.id && e.kind === 'loop-back'
    );
    // Mutation-proof: removing the VERIFY→RUN loop-back in aid-test's SKILL.md
    // would remove this edge from the spliced segment.
    expect(loopEdge).toBeDefined();
  });
});

describe('AC-4 fixture 2 — aid-test-security: PRESENT decision branches', () => {
  const chart = liveChart('aid-test-security');
  const presentNode = chart.nodes.find((n) => n.name === 'PRESENT');
  const presentBranches = chart.edges.filter(
    (e) => e.from === presentNode.id && e.kind === 'branch'
  );

  it('PRESENT node kind is decision', () => {
    expect(presentNode.kind).toBe('decision');
  });

  it('PRESENT has exactly two branch edges', () => {
    expect(presentBranches).toHaveLength(2);
  });

  it('PRESENT has a branch edge to HANDOFF with condition optional (verbatim)', () => {
    const handoffNode = chart.nodes.find((n) => n.name === 'HANDOFF');
    const edge = presentBranches.find((e) => e.to === handoffNode.id);
    expect(edge).toBeDefined();
    expect(edge.condition).toBe('optional');
  });

  it('PRESENT has a branch edge to DONE with condition null', () => {
    const doneNode = chart.nodes.find((n) => n.name === 'DONE');
    const edge = presentBranches.find((e) => e.to === doneNode.id);
    expect(edge).toBeDefined();
    expect(edge.condition).toBeNull();
  });
});

describe('AC-4 fixture 2 — aid-test-security: DONE exit and terminal', () => {
  const chart = liveChart('aid-test-security');
  const doneNode = chart.nodes.find((n) => n.name === 'DONE');

  it('DONE is in exits', () => {
    expect(chart.exits).toContain(doneNode.id);
  });

  it('DONE terminal.advanceType is UNSPECIFIED', () => {
    // Mutation-proof: changing the terminal type in aid-test SKILL.md would fail.
    expect(doneNode.terminal.advanceType).toBe('UNSPECIFIED');
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 8 — Cross-page identity (AC-6)
// For every engine-doorway skill, renderMermaid output minus the two per-page
// lines is string-equal to the same slice of aid-create-api's.
// ══════════════════════════════════════════════════════════════════════════════

describe('AC-6 cross-page identity — all engine-doorway skills share the engine segment', () => {
  // Build the reference stripped output once.
  const REF_STRIPPED = stripEnginePerPageLines(
    renderMermaid(liveChart('aid-create-api'))
  );

  // Enumerate engine-doorway skills from the live listing.
  const allSkills = liveSkillNames();
  const engineDoorwaySkills = allSkills.filter((name) => {
    try {
      return liveChart(name).shape === 'engine-doorway';
    } catch {
      return false;
    }
  });

  it('non-vacuity: at least one engine-doorway skill exists in the corpus', () => {
    // Guard: an empty listing would make the loop below vacuously pass.
    expect(engineDoorwaySkills.length).toBeGreaterThan(0);
  });

  it('for every engine-doorway skill, stripped mermaid equals aid-create-api stripped', () => {
    // "Minus the entry-node declaration and hop-edge lines" is the per-page strip.
    // Mutation-proof: if any per-page datum leaks into the engine segment,
    // one skill's stripped output will differ from the reference, failing this.
    for (const name of engineDoorwaySkills) {
      const stripped = stripEnginePerPageLines(renderMermaid(liveChart(name)));
      expect(stripped).toBe(REF_STRIPPED);
    }
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 9 — Splice fidelity
// For every sibling-doorway skill, the spliced segment is deep-equal to the
// parent chart's nodes/edges under the id/order offset.
// ══════════════════════════════════════════════════════════════════════════════

describe('splice fidelity — sibling spliced segment equals parent chart under offset', () => {
  const allSkills = liveSkillNames();
  const siblingSkills = allSkills.filter((name) => {
    try {
      return liveChart(name).shape === 'sibling-doorway';
    } catch {
      return false;
    }
  });

  it('non-vacuity: at least one sibling-doorway skill exists in the corpus', () => {
    expect(siblingSkills.length).toBeGreaterThan(0);
  });

  it('for every sibling-doorway skill, spliced nodes equal parent nodes with offset', () => {
    // Extract parent name from the first spliced node's provenance file.
    // The provenance always points to the final authored-shape parent's SKILL.md.
    for (const name of siblingSkills) {
      const siblingChart = liveChart(name);
      const splicedNodes = siblingChart.nodes.slice(1);

      const m = splicedNodes[0].provenance.file.match(
        /canonical\/skills\/([^/]+)\/SKILL\.md/
      );
      // If provenance doesn't cite a skill, skip (engine-template node — shouldn't happen).
      if (!m) continue;
      const parentName = m[1];
      const parentChart = liveChart(parentName);

      // Mutation-proof: if compose.mjs corrupts the id or order during offset,
      // the expected ids won't match the actual ones.
      expect(splicedNodes).toEqual(applyNodeOffset(parentChart.nodes, 1));
    }
  });

  it('for every sibling-doorway skill, spliced edges equal parent edges with offset', () => {
    for (const name of siblingSkills) {
      const siblingChart = liveChart(name);
      // edges[0] is the hop edge from the doorway to the parent; edges[1..] are the
      // parent chart's edges with from/to remapped through the offset.
      const splicedEdges = siblingChart.edges.slice(1);

      const m = siblingChart.nodes[1]?.provenance?.file?.match(
        /canonical\/skills\/([^/]+)\/SKILL\.md/
      );
      if (!m) continue;
      const parentName = m[1];
      const parentChart = liveChart(parentName);

      expect(splicedEdges).toEqual(applyEdgeOffset(parentChart.edges, 1));
    }
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 10 — Validator conformance
// validateChart.ok === true for every doorway chart; plus structural invariants.
// ══════════════════════════════════════════════════════════════════════════════

describe('validator conformance — all doorway charts pass validateChart', () => {
  const allSkills = liveSkillNames();
  const doorwaySkills = allSkills.filter((name) => {
    try {
      const shape = liveChart(name).shape;
      return shape === 'engine-doorway' || shape === 'sibling-doorway';
    } catch {
      return false;
    }
  });

  it('non-vacuity: at least one doorway skill exists in the corpus', () => {
    expect(doorwaySkills.length).toBeGreaterThan(0);
  });

  it('for every doorway chart, validateChart.ok is true', () => {
    for (const name of doorwaySkills) {
      const chart = liveChart(name);
      const { ok, errors } = validateChart(chart);
      expect(ok, `${name}: ${errors?.[0] ?? ''}`).toBe(true);
    }
  });

  it('for every doorway chart, entries.length is exactly 1', () => {
    for (const name of doorwaySkills) {
      expect(liveChart(name).entries).toHaveLength(1);
    }
  });

  it('for every doorway chart, exits.length is at least 1', () => {
    for (const name of doorwaySkills) {
      expect(liveChart(name).exits.length).toBeGreaterThanOrEqual(1);
    }
  });

  it('for every doorway chart, every self-edge has from === to (both are known node ids)', () => {
    for (const name of doorwaySkills) {
      const chart = liveChart(name);
      const nodeIds = new Set(chart.nodes.map((n) => n.id));
      for (const edge of chart.edges.filter((e) => e.from === e.to)) {
        // V4 confirms the id is valid; this also directly asserts the structural
        // invariant from the AC.
        expect(nodeIds.has(edge.from)).toBe(true);
      }
    }
  });

  it('for every doorway chart, no (from, to, condition) triple repeats', () => {
    for (const name of doorwaySkills) {
      const chart = liveChart(name);
      const seen = new Set();
      for (const edge of chart.edges) {
        const key = `${edge.from}\0${edge.to}\0${edge.condition ?? ''}`;
        expect(seen.has(key), `${name}: duplicate triple ${key}`).toBe(false);
        seen.add(key);
      }
    }
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 11 — Provider partition
// For every directory under canonical/skills/, exactly one BODY_PROVIDERS
// entry's applies() returns true.
// ══════════════════════════════════════════════════════════════════════════════

describe('provider partition — exactly one BODY_PROVIDERS entry claims each skill', () => {
  // Load all skill bodies from disk to build minimal SkillRecord objects.
  const allSkills = liveSkillNames();

  function makeRecord(name) {
    const file = join(CANONICAL_SKILLS_DIR, name, 'SKILL.md');
    const text = readFileSync(file, 'utf8');
    const lines = text.split('\n');
    let fenceEnd = -1;
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trimEnd() === '---') { fenceEnd = i; break; }
    }
    const body = fenceEnd >= 0 ? lines.slice(fenceEnd + 1).join('\n') : '';
    return { dirName: name, body, fields: [] };
  }

  it('non-vacuity: BODY_PROVIDERS has at least two entries (both authored and doorway)', () => {
    expect(BODY_PROVIDERS.length).toBeGreaterThanOrEqual(2);
  });

  it('non-vacuity: at least one skill directory exists in canonical/skills/', () => {
    expect(allSkills.length).toBeGreaterThan(0);
  });

  it('for every skill directory, exactly one provider applies (not zero, not two)', () => {
    for (const name of allSkills) {
      const record = makeRecord(name);
      const matching = BODY_PROVIDERS.filter((p) => p.applies(record));
      // Mutation-proof: removing a shape from a provider's applies() set routes
      // that skill to the wrong provider, making matching.length !== 1.
      expect(matching, `${name}: expected 1 provider, got ${matching.length}`).toHaveLength(1);
    }
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 12 — Provenance equality
// Every node's provenance.excerpt equals the live slice of its cited file.
// Applies to nodes citing canonical/skills/, shortcut-engine.md, and
// work-initiation-gate.md — all three are verified here.
// ══════════════════════════════════════════════════════════════════════════════

describe('provenance equality — node excerpts match the live file slice', () => {
  const allSkills = liveSkillNames();
  const doorwaySkills = allSkills.filter((name) => {
    try {
      const shape = liveChart(name).shape;
      return shape === 'engine-doorway' || shape === 'sibling-doorway';
    } catch {
      return false;
    }
  });

  it('non-vacuity: at least one doorway skill exists for provenance checking', () => {
    expect(doorwaySkills.length).toBeGreaterThan(0);
  });

  it('for every doorway chart, every node excerpt equals the live file slice', () => {
    // Cache file lines to avoid re-reading the same file for every node.
    const fileCache = new Map();
    function getLines(relPath) {
      if (!fileCache.has(relPath)) {
        const text = readFileSync(join(REPO_ROOT, relPath), 'utf8');
        fileCache.set(relPath, text.split('\n').map((l) => l.replace(/\r$/, '')));
      }
      return fileCache.get(relPath);
    }

    for (const name of doorwaySkills) {
      const chart = liveChart(name);
      for (const node of chart.nodes) {
        const { file, startLine, endLine, excerpt } = node.provenance;
        const lines = getLines(file);
        const live = sliceLines(lines, startLine, endLine);
        // Mutation-proof: if engine-core.mjs records a wrong startLine, the live
        // slice will differ from the stored excerpt.
        expect(live, `${name}/${node.name}: provenance mismatch`).toBe(excerpt);
      }
    }
  });
});


// ══════════════════════════════════════════════════════════════════════════════
// GROUP 13 — Idempotence
// Two calls to buildFlowChart produce byte-equal serializeChart and
// renderMermaid output for both AC-4 fixtures.
// ══════════════════════════════════════════════════════════════════════════════

describe('idempotence — aid-create-api produces byte-equal output on two runs', () => {
  it('two serializeChart calls return the same string', () => {
    const c1 = serializeChart(liveChart('aid-create-api'));
    const c2 = serializeChart(liveChart('aid-create-api'));
    // Mutation-proof: introducing any non-determinism (clock, random, sort
    // instability) would make c1 !== c2.
    expect(c1).toBe(c2);
  });

  it('two renderMermaid calls return the same string', () => {
    const m1 = renderMermaid(liveChart('aid-create-api'));
    const m2 = renderMermaid(liveChart('aid-create-api'));
    expect(m1).toBe(m2);
  });
});

describe('idempotence — aid-test-security produces byte-equal output on two runs', () => {
  it('two serializeChart calls return the same string', () => {
    const c1 = serializeChart(liveChart('aid-test-security'));
    const c2 = serializeChart(liveChart('aid-test-security'));
    expect(c1).toBe(c2);
  });

  it('two renderMermaid calls return the same string', () => {
    const m1 = renderMermaid(liveChart('aid-test-security'));
    const m2 = renderMermaid(liveChart('aid-test-security'));
    expect(m1).toBe(m2);
  });
});
