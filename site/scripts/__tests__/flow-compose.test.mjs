// flow-compose.test.mjs — Unit tests for compose.mjs (task-034).
//
// Adversarially structured per task-034 quality bar:
//   - Input separability: each test targets exactly the condition it names.
//   - Non-vacuity: assertions that would pass over empty/missing data are bounded.
//   - Mutation-proven: each assertion was confirmed to fail when its target code
//     was broken (see mutation log in the task report).
//   - Purity AC is load-bearing: no shared object identity with core is asserted
//     with toBe/===, not only deep equality.
//
// Run: cd site && npx vitest run scripts/__tests__/flow-compose.test.mjs

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { composeDoorwayChart, readDoorwayBinding } from '../lib/flow-graph/compose.mjs';
import { getEngineCore } from '../lib/flow-graph/engine-core.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Make a minimal frozen EngineCore-alike for isolated splice tests.
 * Uses 'cN' ids and integer orders matching the real core convention.
 *
 * @param {{ id: string, order: number }[]} nodeDefs
 * @param {{ from: string, to: string }[]} [edgeDefs]
 * @param {string[]} [exitIds]
 * @returns {{ nodes, edges, exits, sources, warnings }}
 */
function makeFakeCore(nodeDefs, edgeDefs = [], exitIds = []) {
  const prov = {
    file: 'canonical/aid/templates/shortcut-engine.md',
    startLine: 1, endLine: 1, sourceKind: 'engine', excerpt: 'x',
  };
  const nodes = nodeDefs.map((d) => Object.freeze({
    id: d.id, order: d.order, name: d.id, label: d.id,
    kind: 'step', terminal: null, provenance: prov, detail: null,
  }));
  const edges = edgeDefs.map((e) => Object.freeze({
    from: e.from, to: e.to, kind: 'sequence', condition: null,
    advanceType: 'CHAIN', provenance: prov,
  }));
  const exits = exitIds.length > 0 ? exitIds : [nodes[nodes.length - 1].id];
  return Object.freeze({
    nodes: Object.freeze(nodes),
    edges: Object.freeze(edges),
    exits: Object.freeze(exits),
    sources: Object.freeze(['canonical/aid/templates/shortcut-engine.md']),
    warnings: Object.freeze([]),
  });
}

/**
 * Build the minimal prefix node and hop edge for a doorway.
 *
 * @param {string} skill   Doorway skill name.
 * @param {string} coreEntryId  The core node the hop targets (after offset, this becomes the new id).
 * @param {number} coreEntryOrder  Original order of the core entry node.
 */
function makePrefix(skill, coreEntryId, coreEntryOrder) {
  const prov = {
    file: `canonical/skills/${skill}/SKILL.md`,
    startLine: 18, endLine: 18, sourceKind: 'skill', excerpt: 'Bind ...',
  };
  const node = {
    id: 'n1', order: 1, name: skill, label: skill,
    kind: 'entry', terminal: null, provenance: prov, detail: null,
  };
  // hop: n1 → new id of core entry node = 'n' + (coreEntryOrder + 1)
  const hopTarget = 'n' + (coreEntryOrder + 1);
  const edge = {
    from: 'n1', to: hopTarget,
    kind: 'sequence', condition: null,
    advanceType: 'CHAIN', provenance: prov,
  };
  return { prefixNodes: [node], prefixEdges: [edge] };
}

// ── Reference core (real engine) ─────────────────────────────────────────────

const realCore = getEngineCore();

// ── composeDoorwayChart: purity (no shared object identity with core) ─────────

describe('composeDoorwayChart — purity: no shared object identity with core', () => {
  const core = makeFakeCore(
    [{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }],
    [{ from: 'c1', to: 'c2' }],
    ['c2'],
  );
  const { prefixNodes, prefixEdges } = makePrefix('aid-test-skill', 'c1', 1);
  const chart = composeDoorwayChart({
    skill: 'aid-test-skill', prefixNodes, prefixEdges, core, confidence: 'derived',
  });

  it('composed node objects are not the same reference as any core node', () => {
    // Non-vacuity: core has at least one node (guard first).
    expect(core.nodes.length).toBeGreaterThan(0);
    for (const coreNode of core.nodes) {
      for (const composedNode of chart.nodes) {
        // Reference comparison — not deep equality — is the load-bearing assertion.
        // Deep equality would pass even for a shared reference; toBe fails on it.
        expect(composedNode).not.toBe(coreNode);
      }
    }
  });

  it('composed edge objects are not the same reference as any core edge', () => {
    expect(core.edges.length).toBeGreaterThan(0);
    for (const coreEdge of core.edges) {
      for (const composedEdge of chart.edges) {
        expect(composedEdge).not.toBe(coreEdge);
      }
    }
  });

  it('composed nodes array itself is a new array, not the core.nodes reference', () => {
    expect(chart.nodes).not.toBe(core.nodes);
  });

  it('composed exits array is new (not the same reference as core.exits)', () => {
    expect(chart.exits).not.toBe(core.exits);
  });
});

// ── composeDoorwayChart: id and order shifting ────────────────────────────────

describe('composeDoorwayChart — id/order shift by prefix length (offset = 1)', () => {
  // Three-node core: c1, c2, c3 in orders 1, 2, 3.
  const core = makeFakeCore(
    [{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }, { id: 'c3', order: 3 }],
    [{ from: 'c1', to: 'c2' }, { from: 'c2', to: 'c3' }],
    ['c3'],
  );
  const { prefixNodes, prefixEdges } = makePrefix('my-skill', 'c1', 1);
  const chart = composeDoorwayChart({
    skill: 'my-skill', prefixNodes, prefixEdges, core, confidence: 'derived',
  });

  it('prefix node retains id n1 and order 1', () => {
    const n1 = chart.nodes.find((n) => n.id === 'n1');
    expect(n1).toBeTruthy();
    expect(n1.order).toBe(1);
  });

  it('core c1 (order 1) becomes n2 (order 2)', () => {
    const n2 = chart.nodes.find((n) => n.id === 'n2');
    expect(n2).toBeTruthy();
    expect(n2.order).toBe(2);
    // name was 'c1' in the fake core
    expect(n2.name).toBe('c1');
  });

  it('core c2 (order 2) becomes n3 (order 3)', () => {
    const n3 = chart.nodes.find((n) => n.id === 'n3');
    expect(n3).toBeTruthy();
    expect(n3.order).toBe(3);
  });

  it('core c3 (order 3) becomes n4 (order 4)', () => {
    const n4 = chart.nodes.find((n) => n.id === 'n4');
    expect(n4).toBeTruthy();
    expect(n4.order).toBe(4);
  });

  it('core edge c1→c2 is remapped to n2→n3', () => {
    const edge = chart.edges.find((e) => e.from === 'n2' && e.to === 'n3');
    expect(edge).toBeTruthy();
  });

  it('core edge c2→c3 is remapped to n3→n4', () => {
    const edge = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(edge).toBeTruthy();
  });

  it('no composed node retains a cN-prefixed id', () => {
    for (const n of chart.nodes) {
      expect(n.id).not.toMatch(/^c/);
    }
  });

  it('no composed edge from/to retains a cN-prefixed id', () => {
    for (const e of chart.edges) {
      expect(e.from).not.toMatch(/^c/);
      expect(e.to).not.toMatch(/^c/);
    }
  });
});

// ── composeDoorwayChart: entries, exits, sources, warnings ────────────────────

describe('composeDoorwayChart — entries, exits, sources, warnings', () => {
  const core = makeFakeCore(
    [{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }],
    [{ from: 'c1', to: 'c2' }],
    ['c2'],
  );
  const { prefixNodes, prefixEdges } = makePrefix('door-skill', 'c1', 1);
  // Add a source in the prefix node's provenance (already set to skill SKILL.md by makePrefix).
  const chart = composeDoorwayChart({
    skill: 'door-skill', prefixNodes, prefixEdges, core, confidence: 'derived',
  });

  it('entries is exactly [n1]', () => {
    // Non-vacuity: entries must not be empty.
    expect(chart.entries.length).toBeGreaterThan(0);
    expect(chart.entries).toEqual(['n1']);
  });

  it('entries is RECOMPUTED — a core carrying its own entries key is ignored', () => {
    // The assertion above cannot tell "recomputed" from "copied": EngineCore has no
    // `entries` key at all (task-033 AC), so a `core.entries ?? [n1]` fallback would
    // yield the same answer. Verified by mutation — that change survived until this
    // test existed.
    //
    // This fixture hands composition a core with a DECOY entries key. Only genuine
    // recomputation ignores it, so the presence of the key is the sole thing deciding
    // the outcome.
    const base = makeFakeCore([{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }], [{ from: 'c1', to: 'c2' }], ['c2']);
    const decoyCore = Object.freeze({ ...base, entries: Object.freeze(['c1']) });
    const { prefixNodes, prefixEdges } = makePrefix('decoy-skill', 'c1', 1);

    const composed = composeDoorwayChart({
      skill: 'decoy-skill', prefixNodes, prefixEdges, core: decoyCore, confidence: 'derived',
    });

    expect(composed.entries).toEqual(['n1']);
    // And specifically not the core's value, offset or otherwise.
    expect(composed.entries).not.toContain('c1');
    expect(composed.entries).not.toContain('n2');
  });

  it('exits contains the offset version of the core exit (c2 → n3)', () => {
    // Non-vacuity: exits must not be empty.
    expect(chart.exits.length).toBeGreaterThan(0);
    expect(chart.exits).toContain('n3');
  });

  it('exits does NOT contain the old core exit id c2', () => {
    expect(chart.exits).not.toContain('c2');
  });

  it('sources includes the prefix node SKILL.md', () => {
    expect(chart.sources).toContain('canonical/skills/door-skill/SKILL.md');
  });

  it('sources includes the core source file', () => {
    expect(chart.sources).toContain('canonical/aid/templates/shortcut-engine.md');
  });

  it('sources is ASCII-sorted, proven against an input whose insertion order is NOT', () => {
    // The previous form compared `sources` to `sources.slice().sort()` — a value against
    // a sorted copy of itself, which passes whenever the input already happens to be
    // sorted. It was: this fixture's two files arrive in ascending order anyway, so
    // deleting the `.sort()` changed nothing and the mutant survived. Same anti-pattern
    // this work fixed once before in skills-discover.test.mjs.
    //
    // A Set preserves insertion order, so the fixture below is built so that insertion
    // order and sorted order differ: the core contributes a 'z…' file first, and the
    // prefix contributes an 'a…' file second.
    const base = makeFakeCore([{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }], [{ from: 'c1', to: 'c2' }], ['c2']);
    const unsortedCore = Object.freeze({
      ...base,
      sources: Object.freeze([
        'canonical/aid/templates/zzz-last.md',
        'canonical/aid/templates/shortcut-engine.md',
      ]),
    });
    const { prefixNodes, prefixEdges } = makePrefix('aaa-first', 'c1', 1);

    const composed = composeDoorwayChart({
      skill: 'aaa-first', prefixNodes, prefixEdges, core: unsortedCore, confidence: 'derived',
    });

    // Explicit expected order, not a re-sort of the output.
    expect(composed.sources).toEqual([
      'canonical/aid/templates/shortcut-engine.md',
      'canonical/aid/templates/zzz-last.md',
      'canonical/skills/aaa-first/SKILL.md',
    ]);
    // Guard the fixture itself: if insertion order were already sorted, this test could
    // not distinguish a sort from a no-op.
    expect(unsortedCore.sources[0] > unsortedCore.sources[1]).toBe(true);
  });

  it('warnings is a new array (not the core.warnings reference)', () => {
    expect(chart.warnings).not.toBe(core.warnings);
  });
});

// ── composeDoorwayChart: core unmutated after composing two doorways ──────────

describe('composeDoorwayChart — core unmutated after composing two different doorways', () => {
  const core = realCore;

  // Snapshot of core before any composition.
  const beforeNodeCount  = core.nodes.length;
  const beforeEdgeCount  = core.edges.length;
  const beforeFirstId    = core.nodes[0].id;
  const beforeFirstOrder = core.nodes[0].order;

  // Compose doorway A.
  const provA = {
    file: 'canonical/skills/aid-fix/SKILL.md',
    startLine: 18, endLine: 18, sourceKind: 'skill', excerpt: 'Bind ...',
  };
  const nodeA = { id: 'n1', order: 1, name: 'aid-fix', label: 'Fix', kind: 'entry',
                  terminal: null, provenance: provA, detail: null };
  const hopTargetA = 'n' + (core.nodes[0].order + 1);
  const edgeA = { from: 'n1', to: hopTargetA, kind: 'sequence', condition: null,
                  advanceType: 'CHAIN', provenance: provA };
  composeDoorwayChart({
    skill: 'aid-fix', prefixNodes: [nodeA], prefixEdges: [edgeA],
    core, confidence: 'derived',
  });

  // Compose doorway B.
  const provB = {
    file: 'canonical/skills/aid-create-api/SKILL.md',
    startLine: 18, endLine: 18, sourceKind: 'skill', excerpt: 'Bind ...',
  };
  const nodeB = { id: 'n1', order: 1, name: 'aid-create-api', label: 'Create Api', kind: 'entry',
                  terminal: null, provenance: provB, detail: null };
  const hopTargetB = 'n' + (core.nodes[0].order + 1);
  const edgeB = { from: 'n1', to: hopTargetB, kind: 'sequence', condition: null,
                  advanceType: 'CHAIN', provenance: provB };
  composeDoorwayChart({
    skill: 'aid-create-api', prefixNodes: [nodeB], prefixEdges: [edgeB],
    core, confidence: 'derived',
  });

  it('core node count is unchanged after two compositions', () => {
    expect(core.nodes.length).toBe(beforeNodeCount);
  });

  it('core edge count is unchanged after two compositions', () => {
    expect(core.edges.length).toBe(beforeEdgeCount);
  });

  it('core first node id is unchanged after two compositions', () => {
    expect(core.nodes[0].id).toBe(beforeFirstId);
  });

  it('core first node order is unchanged after two compositions', () => {
    expect(core.nodes[0].order).toBe(beforeFirstOrder);
  });

  it('core is still deeply frozen (write attempt throws) after composition', () => {
    expect(() => {
      'use strict';
      core.nodes[0].name = 'MUTATED';
    }).toThrow(TypeError);
  });
});

// ── readDoorwayBinding: engine ladder — backtick artifact ─────────────────────

describe('readDoorwayBinding — engine ladder: Bind VERB=`create`, ARTIFACT=`api`', () => {
  const body = [
    '',
    '# Shortcut: create api',
    '',
    'Bind **VERB=`create`**, **ARTIFACT=`api`**, then run the shared engine.',
  ].join('\n');
  const binding = readDoorwayBinding({ body, bodyStartLine: 13, sourcePath: 'canonical/skills/aid-create-api/SKILL.md' });

  it('kind is engine', () => {
    expect(binding.kind).toBe('engine');
  });

  it('verb is create', () => {
    expect(binding.verb).toBe('create');
  });

  it('artifact is api', () => {
    expect(binding.artifact).toBe('api');
  });

  it('aliasOf is null (engine doorways are not aliases)', () => {
    expect(binding.aliasOf).toBeNull();
  });

  it('provenance points to the Bind line (file line 16 = bodyStart 13 + body-index 3)', () => {
    expect(binding.provenance.startLine).toBe(16);
    expect(binding.provenance.endLine).toBe(16);
    expect(binding.provenance.sourceKind).toBe('skill');
  });

  it('no W1 warning emitted for matched binding', () => {
    expect(binding.warnings).toHaveLength(0);
  });
});

// ── readDoorwayBinding: engine ladder — bare verb form ────────────────────────

describe('readDoorwayBinding — engine ladder: Bind VERB=`fix`, ARTIFACT="" (bare verb)', () => {
  const body = [
    '',
    '# Shortcut: fix',
    '',
    'Bind **VERB=`fix`**, **ARTIFACT="" (bare verb)**, then run the shared engine.',
  ].join('\n');
  const binding = readDoorwayBinding({ body, bodyStartLine: 13, sourcePath: 'canonical/skills/aid-fix/SKILL.md' });

  it('kind is engine', () => {
    expect(binding.kind).toBe('engine');
  });

  it('verb is fix', () => {
    expect(binding.verb).toBe('fix');
  });

  it('artifact is empty string (bare verb, not null)', () => {
    expect(binding.artifact).toBe('');
  });

  it('artifact is exactly empty string, not null or undefined', () => {
    // This assertion fails if artifact=null (the bare-verb rung missed).
    expect(binding.artifact).not.toBeNull();
    expect(binding.artifact).not.toBeUndefined();
  });

  it('no W1 warning emitted', () => {
    expect(binding.warnings).toHaveLength(0);
  });
});

// ── readDoorwayBinding: sibling ladder — braced group with non-empty artifact ─

describe('readDoorwayBinding — sibling braced group: {verb: test, artifact: security}', () => {
  // Mirrors aid-test-security body line 17 structure.
  const body = [
    '',
    '# Test Security',
    '',
    '`/aid-test-security` is a thin kind-sibling of ...',
    '(`canonical/skills/aid-test/SKILL.md`) ...',
    '(`alias_of: null`, `{verb: test, artifact: security}`), `repurpose: true`.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-test-security/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(binding.kind).toBe('sibling');
  });

  it('verb is test', () => {
    expect(binding.verb).toBe('test');
  });

  it('artifact is security', () => {
    expect(binding.artifact).toBe('security');
  });

  it('aliasOf is null (kind-siblings are not aliases)', () => {
    expect(binding.aliasOf).toBeNull();
  });

  it('provenance startLine is 17 (bodyStartLine 12 + body-index 5)', () => {
    expect(binding.provenance.startLine).toBe(17);
  });

  it('no W1 warning emitted', () => {
    expect(binding.warnings).toHaveLength(0);
  });
});

// ── readDoorwayBinding: sibling ladder — braced group with empty artifact ──────

describe('readDoorwayBinding — sibling braced group: {verb: document, artifact: ""}', () => {
  const body = [
    '',
    '# Document',
    '',
    '(`alias_of: null`, its own `{verb: document, artifact: ""}`), `repurpose: true`.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-document/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(binding.kind).toBe('sibling');
  });

  it('verb is document', () => {
    expect(binding.verb).toBe('document');
  });

  it('artifact is empty string (not null — this rung carried the value)', () => {
    expect(binding.artifact).toBe('');
    expect(binding.artifact).not.toBeNull();
  });

  it('no W1 warning emitted', () => {
    expect(binding.warnings).toHaveLength(0);
  });
});

// ── readDoorwayBinding: sibling ladder — alias_of ────────────────────────────

describe('readDoorwayBinding — sibling alias_of: aid-create-document', () => {
  const body = [
    '',
    '# Create Document (alias)',
    '',
    'Registered `alias_of: aid-create-document`, `repurpose: true`.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-add-document/SKILL.md',
  });

  it('kind is sibling', () => {
    expect(binding.kind).toBe('sibling');
  });

  it('aliasOf is aid-create-document', () => {
    expect(binding.aliasOf).toBe('aid-create-document');
  });

  it('verb is null for a pure alias', () => {
    expect(binding.verb).toBeNull();
  });

  it('artifact is null for a pure alias', () => {
    expect(binding.artifact).toBeNull();
  });

  it('no W1 warning emitted', () => {
    expect(binding.warnings).toHaveLength(0);
  });
});

// ── readDoorwayBinding: alias_of null does NOT match alias rung ───────────────

describe('readDoorwayBinding — alias_of: null does not trigger alias rung', () => {
  // A kind-sibling body has "alias_of: null" on the same line as {verb, artifact}.
  // The braced group must fire, not the alias rung.
  const body = [
    '',
    '(`alias_of: null`, `{verb: test, artifact: performance}`), `repurpose: true`.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-test-performance/SKILL.md',
  });

  it('kind is sibling (braced group fired, not alias)', () => {
    expect(binding.kind).toBe('sibling');
  });

  it('aliasOf is null (null was not matched)', () => {
    expect(binding.aliasOf).toBeNull();
  });

  it('verb is test (braced group was matched)', () => {
    expect(binding.verb).toBe('test');
  });

  it('artifact is performance', () => {
    expect(binding.artifact).toBe('performance');
  });
});

// ── readDoorwayBinding: W1 no-binding fallback ────────────────────────────────

describe('readDoorwayBinding — W1 fallback: no binding form matched', () => {
  // A body with none of the recognisable patterns.
  const body = [
    '',
    '# Unknown Skill',
    '',
    'This skill has no recognisable binding clause.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-unknown/SKILL.md',
  });

  it('warnings is non-empty (W1 fired)', () => {
    // Non-vacuity: must have at least one warning.
    expect(binding.warnings.length).toBeGreaterThan(0);
  });

  it('W1 warning message mentions W1', () => {
    expect(binding.warnings[0]).toMatch(/W1/);
  });

  it('verb is null in the W1 fallback', () => {
    expect(binding.verb).toBeNull();
  });

  it('artifact is null in the W1 fallback', () => {
    expect(binding.artifact).toBeNull();
  });

  it('aliasOf is null in the W1 fallback', () => {
    expect(binding.aliasOf).toBeNull();
  });
});

// ── readDoorwayBinding: bound detection ──────────────────────────────────────

describe('readDoorwayBinding — bound detection: **kind bound to security**', () => {
  const body = [
    '',
    '`{verb: test, artifact: security}`',
    '',
    'Execute exactly as written, with the **kind bound to security** (SAST/DAST).',
  ].join('\n');
  const binding = readDoorwayBinding({
    body,
    bodyStartLine: 12,
    sourcePath: 'canonical/skills/aid-test-security/SKILL.md',
  });

  it('bound is kind bound to security', () => {
    expect(binding.bound).toBe('kind bound to security');
  });
});

describe('readDoorwayBinding — bound is null when no facet binding in body', () => {
  const body = [
    '',
    'Bind **VERB=`create`**, **ARTIFACT=`api`**, then run the shared engine.',
  ].join('\n');
  const binding = readDoorwayBinding({
    body, bodyStartLine: 13,
    sourcePath: 'canonical/skills/aid-create-api/SKILL.md',
  });

  it('bound is null (engine doorways have no facet binding)', () => {
    expect(binding.bound).toBeNull();
  });
});

// ── readDoorwayBinding: provenance fields ─────────────────────────────────────

describe('readDoorwayBinding — provenance fields', () => {
  const body = 'Bind **VERB=`create`**, **ARTIFACT=`api`**, then run engine.';
  const binding = readDoorwayBinding({
    body, bodyStartLine: 18,
    sourcePath: 'canonical/skills/aid-create-api/SKILL.md',
  });

  it('provenance.file is the sourcePath', () => {
    expect(binding.provenance.file).toBe('canonical/skills/aid-create-api/SKILL.md');
  });

  it('provenance.sourceKind is skill', () => {
    expect(binding.provenance.sourceKind).toBe('skill');
  });

  it('provenance.startLine equals endLine (single-line)', () => {
    expect(binding.provenance.startLine).toBe(binding.provenance.endLine);
  });

  it('provenance.excerpt matches the binding line verbatim', () => {
    expect(binding.provenance.excerpt).toBe(body);
  });
});

// ── readDoorwayBinding: module-level purity guard ─────────────────────────────

describe('readDoorwayBinding — the module cannot read the catalogue, or anything else', () => {
  // AC: "readDoorwayBinding never reads shortcut-catalog.yml, verified by grep".
  //
  // A bare substring check over the whole file is satisfiable by editing a COMMENT,
  // which is exactly what happened once: the doc comment explaining *why* the body is
  // read instead of the catalogue was reworded to make this pass, losing the reasoning
  // to satisfy a string match. So the check now strips comments first — the same
  // treatment the count-literal guards in gen-skills.test.mjs use — and the prose is
  // free to name the file it is explaining.
  //
  // The substring check is also weak on its own: `'shortcut' + '-catalog.yml'` would
  // slip past it. The second test below is the real guarantee.

  /** compose.mjs with block and line comments removed. */
  function codeOnly() {
    const src = readFileSync(join(__dirname, '../lib/flow-graph/compose.mjs'), 'utf8');
    return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
  }

  it('does not name the catalogue anywhere in CODE (comments may explain it)', () => {
    const code = codeOnly();
    // Non-vacuity: comment stripping must not have emptied the file.
    expect(code).toContain('export function readDoorwayBinding');
    expect(code).not.toContain('shortcut-catalog');
  });

  it('imports no file I/O at all, so it cannot read any file however named', () => {
    // This is the property the AC is reaching for, and it cannot be satisfied by
    // renaming a string. compose.mjs is handed everything it needs.
    const code = codeOnly();
    expect(code).not.toMatch(/from\s+['"]node:fs['"]/);
    expect(code).not.toMatch(/from\s+['"]node:path['"]/);
    expect(code).not.toMatch(/require\s*\(/);
    expect(code).not.toMatch(/\bimport\s*\(/);
    // Belt and braces: no import statement of any kind reaches outside this module.
    expect(code).not.toMatch(/^\s*import\s/m);
  });
});

// ── readDoorwayBinding: resolveSiblingParent is NOT in compose.mjs ────────────

describe('readDoorwayBinding — resolveSiblingParent is absent from this module', () => {
  it('compose.mjs exports do not include resolveSiblingParent', async () => {
    const mod = await import('../lib/flow-graph/compose.mjs');
    expect(mod.resolveSiblingParent).toBeUndefined();
  });

  it('compose.mjs source does not define resolveSiblingParent', () => {
    // Comments stripped for the same reason as the catalogue guard above: the DETAIL's
    // rationale for placing the resolver in task-036 is worth writing down here, and a
    // whole-file substring check would forbid saying its name while explaining it.
    const src = readFileSync(join(__dirname, '../lib/flow-graph/compose.mjs'), 'utf8');
    const code = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    expect(code).toContain('export function composeDoorwayChart');   // non-vacuity
    expect(code).not.toContain('resolveSiblingParent');
  });
});

// ── composeDoorwayChart: title format ─────────────────────────────────────────

describe('composeDoorwayChart — title is skill + em-dash + state flow', () => {
  const core = makeFakeCore([{ id: 'c1', order: 1 }], [], ['c1']);
  const { prefixNodes, prefixEdges } = makePrefix('aid-create-api', 'c1', 1);
  const chart = composeDoorwayChart({
    skill: 'aid-create-api', prefixNodes, prefixEdges, core, confidence: 'derived',
  });

  it('title contains the skill name', () => {
    expect(chart.title).toContain('aid-create-api');
  });

  it('title contains an em-dash (U+2014)', () => {
    expect(chart.title).toContain('\u2014');
  });
});

// ── composeDoorwayChart: nodes sorted by order ────────────────────────────────

describe('composeDoorwayChart — nodes are sorted by order ascending', () => {
  const core = makeFakeCore(
    [{ id: 'c1', order: 1 }, { id: 'c2', order: 2 }, { id: 'c3', order: 3 }],
    [],
    ['c3'],
  );
  const { prefixNodes, prefixEdges } = makePrefix('my-skill', 'c1', 1);
  const chart = composeDoorwayChart({
    skill: 'my-skill', prefixNodes, prefixEdges, core, confidence: 'derived',
  });

  it('nodes are in ascending order', () => {
    for (let i = 1; i < chart.nodes.length; i++) {
      expect(chart.nodes[i].order).toBeGreaterThan(chart.nodes[i - 1].order);
    }
  });

  it('total node count is prefix + core count', () => {
    // Non-vacuity: chart must have more than just the prefix.
    expect(chart.nodes.length).toBe(1 + core.nodes.length);
  });
});
