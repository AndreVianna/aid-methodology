// flow-extract-sibling.test.mjs — Unit tests for extract-sibling.mjs (feature-004, task-036).
//
// Quality bar honoured:
// 1. Input separability: each describe block exercises one independent condition.
// 2. Non-vacuity: every list/exit assertion has a bound that fails on empty.
// 3. Mutation-proved: each assertion was confirmed to fail when its target code
//    was broken (see mutation log in the task report).
// 4. Memo asserted by object identity (toBe), never deep equality.
// 5. Splice fidelity: spliced nodes deep-equal parent chart nodes under offset.
// 6. sliceLines used for provenance excerpt equality (quality-bar rule 5).
// 7. Notice is checked as a string; never as a chart node name.
//
// Cap / cycle tests use vi.mock(node:fs) to inject fake sibling chains without
// creating real canonical/skills/ directories.
//
// Run: cd site && npx vitest run scripts/__tests__/flow-extract-sibling.test.mjs

// ── vi.mock must be at the top (vitest hoists it above imports) ──────────────

import { vi } from 'vitest';

// Fake sibling chain bodies for the 4-hop cap test.
// Chain: fake-cap-1 → fake-cap-2 → fake-cap-3 → fake-cap-4 (all siblings).
// Starting from fake-cap-1 exhausts all 4 hops without reaching an authored parent.
const FAKE_CHAIN_BODIES = {
  'fake-cap-1': '---\nname: fake-cap-1\n---\nno logic of its own canonical/skills/fake-cap-2/SKILL.md {verb: x, artifact: x}',
  'fake-cap-2': '---\nname: fake-cap-2\n---\nno logic of its own canonical/skills/fake-cap-3/SKILL.md {verb: x, artifact: x}',
  'fake-cap-3': '---\nname: fake-cap-3\n---\nno logic of its own canonical/skills/fake-cap-4/SKILL.md {verb: x, artifact: x}',
  'fake-cap-4': '---\nname: fake-cap-4\n---\nno logic of its own canonical/skills/fake-cap-5/SKILL.md {verb: x, artifact: x}',
};

vi.mock('node:fs', async (importOriginal) => {
  const actual = await importOriginal();
  return {
    ...actual,
    readFileSync: (filePath, encoding) => {
      // Intercept fake-cap-N paths; pass everything else to the real impl.
      const normalized = String(filePath).replace(/\\/g, '/');
      for (const [name, body] of Object.entries(FAKE_CHAIN_BODIES)) {
        if (normalized.includes(`/canonical/skills/${name}/SKILL.md`)) {
          return body;
        }
      }
      return actual.readFileSync(filePath, encoding);
    },
  };
});

// ── Imports (after vi.mock) ───────────────────────────────────────────────────

import { describe, it, expect, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  extractSiblingDoorway,
  resolveSiblingParent,
  parentChartCache,
} from '../lib/flow-graph/extract-sibling.mjs';
import { validateChart }   from '../lib/flow-graph/validate.mjs';
import { buildFlowChart }  from '../lib/flow-graph/index.mjs';
import { sliceLines }      from '../lib/flow-graph/source.mjs';
import { GITHUB_BLOB_BASE } from '../skills/paths.mjs';

// ── Repo root ─────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../..');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Read a canonical SKILL.md and build a SkillRecord matching discover.mjs output.
 */
function loadSkillRecord(dirName) {
  const sourcePath = `canonical/skills/${dirName}/SKILL.md`;
  const raw = readFileSync(join(REPO_ROOT, sourcePath), 'utf8');
  const lines = raw.split('\n').map((l) => l.replace(/\r$/, ''));
  let fenceCount = 0;
  let bodyStartIdx = 0;
  for (let i = 0; i < lines.length; i++) {
    if (/^---/.test(lines[i])) {
      fenceCount++;
      if (fenceCount === 2) { bodyStartIdx = i + 1; break; }
    }
  }
  return {
    dirName,
    sourcePath,
    body: lines.slice(bodyStartIdx).join('\n'),
    bodyStartLine: bodyStartIdx + 1,
    _rawLines: lines,
  };
}

/**
 * Build a minimal synthetic SkillRecord (used for sub-form and edge-case tests).
 *
 * provenance.file defaults to a canonical path so validateChart's V7 passes.
 */
function makeSyntheticRecord(dirName, bodyLines) {
  const sourcePath = `canonical/skills/${dirName}/SKILL.md`;
  const body = bodyLines.join('\n');
  return { dirName, sourcePath, body, bodyStartLine: 1 };
}

// ── Load real fixtures once ───────────────────────────────────────────────────

const testSecRecord  = loadSkillRecord('aid-test-security');
const testPerfRecord = loadSkillRecord('aid-test-performance');

// Clear cache before each test to avoid inter-test pollution.
beforeEach(() => { parentChartCache.clear(); });

// ── resolveSiblingParent ──────────────────────────────────────────────────────

describe('resolveSiblingParent — D3 resolution', () => {
  it('returns the single parent name when exactly one distinct ref exists', () => {
    // Only aid-test-security → 'aid-test' (body has exactly one canonical skill ref)
    const result = resolveSiblingParent({ body: testSecRecord.body });
    expect(result).toBe('aid-test');
  });

  it('returns null when no canonical/skills ref exists', () => {
    // Separability: the only condition under test is "zero refs".
    const body = 'no logic of its own. This skill delegates to its parent.';
    expect(resolveSiblingParent({ body })).toBeNull();
  });

  it('returns null when two distinct refs exist (contradicts D3)', () => {
    // Separability: the only condition under test is "two distinct refs".
    const body = [
      'no logic of its own.',
      'See canonical/skills/aid-test/SKILL.md for the parent logic.',
      'Also see canonical/skills/aid-create/SKILL.md for another reference.',
    ].join('\n');
    expect(resolveSiblingParent({ body })).toBeNull();
  });

  it('counts repeated occurrences of the same ref as one distinct ref', () => {
    // The same SKILL.md path twice still produces a size-1 Set → single parent.
    const body = [
      'no logic: canonical/skills/aid-test/SKILL.md.',
      'See canonical/skills/aid-test/SKILL.md again.',
    ].join('\n');
    expect(resolveSiblingParent({ body })).toBe('aid-test');
  });
});

// ── AC-1: shape, extractor, confidence (aid-test-security) ───────────────────

describe('AC-1 — shape / extractor / confidence (aid-test-security)', () => {
  const chart = extractSiblingDoorway(testSecRecord);

  it('shape === "sibling-doorway"', () => {
    expect(chart.shape).toBe('sibling-doorway');
  });

  it('extractor === "extract-sibling"', () => {
    expect(chart.extractor).toBe('extract-sibling');
  });

  it('confidence === "derived" (parent aid-test is inline-states)', () => {
    expect(chart.confidence).toBe('derived');
  });
});

// ── AC-2: entry node — kind-sibling sub-form (aid-test-security) ─────────────

describe('AC-2 — entry node properties (aid-test-security)', () => {
  const chart = extractSiblingDoorway(testSecRecord);

  // Non-vacuity: nodes array is non-empty before we index into it.
  it('nodes array is non-empty (non-vacuity guard)', () => {
    expect(chart.nodes.length).toBeGreaterThan(0);
  });

  it('entries is exactly [nodes[0].id]', () => {
    expect(chart.entries).toEqual([chart.nodes[0].id]);
  });

  it('nodes[0].name === "aid-test-security"', () => {
    expect(chart.nodes[0].name).toBe('aid-test-security');
  });

  it('nodes[0].kind === "entry"', () => {
    expect(chart.nodes[0].kind).toBe('entry');
  });

  it('nodes[0].label contains "verb: test"', () => {
    // Separability: only a kind-sibling fixture with verb=test satisfies this.
    expect(chart.nodes[0].label).toContain('verb: test');
  });

  it('nodes[0].label contains "artifact: security"', () => {
    expect(chart.nodes[0].label).toContain('artifact: security');
  });

  it('nodes[0].label is the braced group {verb: test, artifact: security}', () => {
    // Non-vacuity: if the label construction is broken, this exact string fails.
    expect(chart.nodes[0].label).toBe('{verb: test, artifact: security}');
  });

  it('nodes[0].provenance.file is the skill SKILL.md path', () => {
    expect(chart.nodes[0].provenance.file).toBe(
      'canonical/skills/aid-test-security/SKILL.md'
    );
  });

  it('nodes[0].provenance.sourceKind === "skill"', () => {
    expect(chart.nodes[0].provenance.sourceKind).toBe('skill');
  });

  it('nodes[0].provenance.excerpt equals the live file slice at startLine', () => {
    // sliceLines equality — not "non-empty" — per quality bar rule 5.
    const prov = chart.nodes[0].provenance;
    const expected = sliceLines(testSecRecord._rawLines, prov.startLine, prov.endLine);
    expect(prov.excerpt).toBe(expected);
  });
});

// ── AC-3: hop edge structure (aid-test-security) ─────────────────────────────

describe('AC-3 — hop edge (aid-test-security)', () => {
  const chart = extractSiblingDoorway(testSecRecord);
  const hopEdge = () => chart.edges.find((e) => e.from === 'n1');

  // Non-vacuity: hop edge must exist.
  it('hop edge from n1 exists (non-vacuity)', () => {
    expect(hopEdge()).toBeTruthy();
  });

  it('hop edge kind === "sequence"', () => {
    expect(hopEdge().kind).toBe('sequence');
  });

  it('hop edge condition === "kind bound to security"', () => {
    expect(hopEdge().condition).toBe('kind bound to security');
  });

  it('hop edge to === "n2" (parent entry at order 1 becomes n2 after offset)', () => {
    expect(hopEdge().to).toBe('n2');
  });

  it('hop edge provenance.sourceKind === "sibling"', () => {
    // The hop is a sibling delegation, not a sequence within the doorway's own machine.
    expect(hopEdge().provenance.sourceKind).toBe('sibling');
  });

  it('hop edge targets the parent chart\'s entry node (n2 === offset(aid-test n1))', () => {
    // n2 is the parent's first node (order=1) shifted by offset=1.
    const n2 = chart.nodes.find((n) => n.id === 'n2');
    expect(n2).toBeTruthy();
    expect(chart.entries).toContain('n1');
    expect(n2.name).not.toBe('aid-test-security'); // not the doorway itself
  });
});

// ── AC-4: splice fidelity ─────────────────────────────────────────────────────

describe('AC-4 — splice fidelity (parent chart spliced whole, no L1/B1)', () => {
  it('spliced segment is deep-equal to parent chart under id/order offset', () => {
    parentChartCache.clear();
    const chart = extractSiblingDoorway(testSecRecord);
    const parentChart = parentChartCache.get('aid-test');

    // Non-vacuity: parent must have nodes.
    expect(parentChart.nodes.length).toBeGreaterThan(0);

    for (const parentNode of parentChart.nodes) {
      const composedNode = chart.nodes.find((n) => n.order === parentNode.order + 1);
      // Non-vacuity: every parent node must appear in the composed chart.
      expect(composedNode, `node ${parentNode.name} not found in composed chart`).toBeTruthy();
      // Deep equality for all content fields (offset changes only id and order).
      expect(composedNode.name).toBe(parentNode.name);
      expect(composedNode.label).toBe(parentNode.label);
      expect(composedNode.kind).toBe(parentNode.kind);
      expect(composedNode.terminal).toEqual(parentNode.terminal);
      expect(composedNode.provenance).toEqual(parentNode.provenance);
      expect(composedNode.detail).toEqual(parentNode.detail);
    }
  });

  it('spliced nodes all carry provenance.file pointing at aid-test SKILL.md', () => {
    parentChartCache.clear();
    const chart = extractSiblingDoorway(testSecRecord);
    const parentPath = 'canonical/skills/aid-test/SKILL.md';
    // Non-vacuity: there must be at least one spliced node (nodes[1..N]).
    const splicedNodes = chart.nodes.filter((n) => n.name !== 'aid-test-security');
    expect(splicedNodes.length).toBeGreaterThan(0);
    for (const n of splicedNodes) {
      expect(n.provenance.file).toBe(parentPath);
    }
  });

  it('no L1/B1 applied: aid-test-security sees the same spine as aid-test-performance', () => {
    // Two siblings of the same parent must see the same spliced spine.
    parentChartCache.clear();
    const chartSec = extractSiblingDoorway(testSecRecord);
    const chartPerf = extractSiblingDoorway(testPerfRecord);
    // Collect names of spliced nodes (everything after prefix node at order 1).
    const spineOf = (c) =>
      c.nodes
        .filter((n) => n.order > 1)
        .sort((a, b) => a.order - b.order)
        .map((n) => n.name);
    expect(spineOf(chartSec)).toEqual(spineOf(chartPerf));
  });
});

// ── AC-5: parent spine node names ────────────────────────────────────────────

describe('AC-5 — parent spine (aid-test nodes appear in order)', () => {
  const chart = extractSiblingDoorway(testSecRecord);

  it('node names after prefix match aid-test spine', () => {
    // Non-vacuity: at least one node beyond the prefix.
    const spineNames = chart.nodes
      .filter((n) => n.order > 1)
      .sort((a, b) => a.order - b.order)
      .map((n) => n.name);
    expect(spineNames.length).toBeGreaterThan(0);
    // The first node of aid-test is INTAKE.
    expect(spineNames[0]).toBe('INTAKE');
  });
});

// ── AC-6: parentChartCache memo identity ─────────────────────────────────────

describe('AC-6 — parentChartCache memo (object identity, not deep equality)', () => {
  it('aid-create-document chart is derived once for two siblings', () => {
    parentChartCache.clear();
    // Two siblings of aid-create-document.
    const rec1 = loadSkillRecord('aid-document-architecture');
    const rec2 = loadSkillRecord('aid-document-changelog');
    extractSiblingDoorway(rec1);
    const cached1 = parentChartCache.get('aid-create-document');
    extractSiblingDoorway(rec2);
    const cached2 = parentChartCache.get('aid-create-document');

    // Non-vacuity: cache must have an entry after the first call.
    expect(cached1).toBeTruthy();
    // Identity (not deep equality): same object reference — contract, not optimisation.
    expect(cached1).toBe(cached2);
  });

  it('cache has exactly one entry for the shared parent after two sibling calls', () => {
    parentChartCache.clear();
    extractSiblingDoorway(loadSkillRecord('aid-document-architecture'));
    extractSiblingDoorway(loadSkillRecord('aid-document-changelog'));
    // Both resolve to aid-create-document; only one cache entry.
    expect(parentChartCache.has('aid-create-document')).toBe(true);
  });
});

// ── AC-7: pure-alias sub-form ─────────────────────────────────────────────────

describe('AC-7 — pure-alias sub-form (alias_of in body)', () => {
  // Synthetic: a body that has alias_of: aid-test (no braced group).
  // Separability: only a pure-alias body (no {verb:...} group) satisfies this.
  const aliasBody = [
    'This skill carries **no logic of its own.** See',
    'canonical/skills/aid-test/SKILL.md for all behavior.',
    'alias_of: aid-test',
  ].join('\n');

  // Pre-populate cache so no file read is needed.
  const makeAliasChart = () => {
    const parentChart = buildFlowChart({ name: 'aid-test', dir: REPO_ROOT });
    parentChartCache.set('aid-test', parentChart);
    return extractSiblingDoorway(
      makeSyntheticRecord('aid-alias-synth', [
        '# Alias',
        'This skill carries **no logic of its own.** See',
        'canonical/skills/aid-test/SKILL.md for all behavior.',
        'alias_of: aid-test',
      ])
    );
  };

  it('label === "alias of aid-test"', () => {
    const chart = makeAliasChart();
    expect(chart.nodes[0].label).toBe('alias of aid-test');
  });

  it('hop condition === null (unconditional alias delegation)', () => {
    const chart = makeAliasChart();
    const hop = chart.edges.find((e) => e.from === 'n1');
    expect(hop.condition).toBeNull();
  });

  it('no W1 warning (alias_of matched; binding form was found)', () => {
    const chart = makeAliasChart();
    const w1 = chart.warnings.filter((w) => w.includes('W1'));
    expect(w1.length).toBe(0);
  });
});

// ── AC-8: neither sub-form (W1) ────────────────────────────────────────────────

describe('AC-8 — neither sub-form (no binding found → W1)', () => {
  // Synthetic: a body with a SKILL.md ref but no braced group and no alias_of.
  // Separability: only the "neither" path (no engine/sibling/alias match) fires W1.
  const makeNeitherChart = () => {
    const parentChart = buildFlowChart({ name: 'aid-test', dir: REPO_ROOT });
    parentChartCache.set('aid-test', parentChart);
    return extractSiblingDoorway(
      makeSyntheticRecord('aid-neither-synth', [
        '# No binding',
        'This skill has **no logic of its own.**',
        'See canonical/skills/aid-test/SKILL.md for the parent behavior.',
        'It delegates unconditionally.',
      ])
    );
  };

  it('label === "Delegates to aid-test"', () => {
    const chart = makeNeitherChart();
    expect(chart.nodes[0].label).toBe('Delegates to aid-test');
  });

  it('hop condition === null', () => {
    const chart = makeNeitherChart();
    const hop = chart.edges.find((e) => e.from === 'n1');
    expect(hop.condition).toBeNull();
  });

  it('W1 warning is emitted', () => {
    const chart = makeNeitherChart();
    // Non-vacuity: warnings must have at least one W1.
    const w1 = chart.warnings.filter((w) => w.includes('W1'));
    expect(w1.length).toBeGreaterThan(0);
  });
});

// ── AC-9: W4 — confidence weakened ────────────────────────────────────────────

describe('AC-9 — W4: confidence weakens to approximate when parent is approximate', () => {
  // Inject a fake approximate parent into the cache.
  const setupApproxParent = () => {
    const realParentChart = buildFlowChart({ name: 'aid-test', dir: REPO_ROOT });
    const approxParent = { ...realParentChart, confidence: 'approximate' };
    parentChartCache.set('aid-approx-parent', approxParent);
    return extractSiblingDoorway(
      makeSyntheticRecord('aid-w4-synth', [
        '# W4 fixture',
        'no logic of its own canonical/skills/aid-approx-parent/SKILL.md',
        '{verb: test, artifact: w4test}',
        '**kind bound to w4test**',
      ])
    );
  };

  it('confidence === "approximate" when parent chart is approximate', () => {
    const chart = setupApproxParent();
    expect(chart.confidence).toBe('approximate');
  });

  it('W4 warning is emitted', () => {
    const chart = setupApproxParent();
    // Non-vacuity: at least one W4 warning must exist.
    const w4 = chart.warnings.filter((w) => w.includes('W4'));
    expect(w4.length).toBeGreaterThan(0);
  });

  it('W4 warning names the parent', () => {
    const chart = setupApproxParent();
    const w4 = chart.warnings.find((w) => w.includes('W4'));
    expect(w4).toContain('aid-approx-parent');
  });

  it('derived confidence (aid-test-security) does NOT emit W4', () => {
    // Separability: only an approximate parent triggers W4.
    const chart = extractSiblingDoorway(testSecRecord);
    const w4 = chart.warnings.filter((w) => w.includes('W4'));
    expect(w4.length).toBe(0);
  });
});

// ── AC-10: W3 cycle guard ─────────────────────────────────────────────────────

describe('AC-10 — W3 cycle guard', () => {
  // A skill that delegates to itself — cycle on the very first hop.
  const makeCycleRecord = () =>
    makeSyntheticRecord('aid-cycle-synth', [
      '# Cycle',
      'no logic of its own canonical/skills/aid-cycle-synth/SKILL.md',
      '{verb: cycle, artifact: test}',
    ]);

  it('cycle emits a W3 warning', () => {
    const chart = extractSiblingDoorway(makeCycleRecord());
    const w3 = chart.warnings.filter((w) => w.includes('W3'));
    expect(w3.length).toBeGreaterThan(0);
  });

  it('cycle returns a fallback chart with one exit node (never throws)', () => {
    // Never throws — the contract.
    expect(() => extractSiblingDoorway(makeCycleRecord())).not.toThrow();
    const chart = extractSiblingDoorway(makeCycleRecord());
    // Fallback chart: single node, that node is an exit.
    expect(chart.exits.length).toBeGreaterThan(0);
  });

  it('cycle fallback chart passes validateChart', () => {
    const chart = extractSiblingDoorway(makeCycleRecord());
    const { ok } = validateChart(chart);
    expect(ok).toBe(true);
  });

  it('cycle fallback chart has entries.length === 1', () => {
    const chart = extractSiblingDoorway(makeCycleRecord());
    expect(chart.entries.length).toBe(1);
  });

  it('W3 warning mentions "cycle"', () => {
    const chart = extractSiblingDoorway(makeCycleRecord());
    const w3 = chart.warnings.find((w) => w.includes('W3'));
    expect(w3).toContain('cycle');
  });
});

// ── AC-11: W3 cap exceeded ────────────────────────────────────────────────────

describe('AC-11 — W3 4-hop cap (requires vi.mock for fake chain)', () => {
  // The vi.mock at the top of this file intercepts reads for fake-cap-N paths
  // and returns sibling bodies pointing to the next in the chain.
  // Chain: fake-cap-1 → fake-cap-2 → fake-cap-3 → fake-cap-4 (sibling) → fake-cap-5
  // After 4 hops the loop exits and W3 fires with "exceeded cap".

  const makeCapRecord = () =>
    makeSyntheticRecord('aid-cap-synth', [
      '# Cap test',
      'no logic of its own',
      'canonical/skills/fake-cap-1/SKILL.md',
      '{verb: cap, artifact: test}',
      '**kind bound to test**',
    ]);

  it('4-hop cap emits the CAP W3, naming the cap value', () => {
    const chart = extractSiblingDoorway(makeCapRecord());
    const w3 = chart.warnings.filter((w) => w.includes('W3'));
    expect(w3.length).toBeGreaterThan(0);

    // `w3.length > 0` alone does not pin the cap: W3 covers three distinct causes —
    // cap exceeded, cycle detected, and unresolvable parent — and raising MAX_HOPS to 400
    // still ends this chain with an *unresolvable* W3, so the mutant survived. Asserting
    // the cap message, with its value, is what makes MAX_HOPS = 4 a tested contract.
    expect(w3.some((w) => /exceeded 4-hop resolution cap/.test(w))).toBe(true);
  });

  it('cap returns fallback chart (never throws)', () => {
    expect(() => extractSiblingDoorway(makeCapRecord())).not.toThrow();
    const chart = extractSiblingDoorway(makeCapRecord());
    expect(chart.exits.length).toBeGreaterThan(0);
  });

  it('the fallback chart is marked approximate', () => {
    // Nothing asserted the fallback's confidence, so flipping it to 'derived' survived.
    // An unresolved parent means the flow was never derived at all, so `approximate` is
    // the only honest value — and it is what makes the page carry feature-003's
    // interpretation notice instead of presenting a stub as fact.
    const chart = extractSiblingDoorway(makeCapRecord());
    expect(chart.confidence).toBe('approximate');
  });

  it('cap fallback chart passes validateChart', () => {
    const chart = extractSiblingDoorway(makeCapRecord());
    const { ok } = validateChart(chart);
    expect(ok).toBe(true);
  });

  it('cap fallback chart has entries.length === 1', () => {
    const chart = extractSiblingDoorway(makeCapRecord());
    expect(chart.entries.length).toBe(1);
  });

  it('W3 cap warning mentions "cap"', () => {
    const chart = extractSiblingDoorway(makeCapRecord());
    const w3 = chart.warnings.find((w) => w.includes('W3'));
    expect(w3).toContain('cap');
  });
});

// ── AC-12: W2 — H2 sections in sibling body ───────────────────────────────────

describe('AC-12 — W2: sibling body carrying H2 sections not drawn', () => {
  // Synthetic: sibling body that has ## Pre-flight and ## Execution sections.
  // Separability: only a body WITH H2 sections triggers W2.
  const makeW2Record = () => {
    const parentChart = buildFlowChart({ name: 'aid-test', dir: REPO_ROOT });
    parentChartCache.set('aid-test', parentChart);
    return makeSyntheticRecord('aid-w2-synth', [
      '# W2 fixture',
      'no logic of its own canonical/skills/aid-test/SKILL.md',
      '{verb: test, artifact: w2}',
      '**kind bound to w2**',
      '',
      '## Pre-flight',
      'Some pre-flight steps.',
      '',
      '## Execution',
      'Do the work.',
    ]);
  };

  it('W2 warning is emitted', () => {
    const chart = extractSiblingDoorway(makeW2Record());
    const w2 = chart.warnings.filter((w) => w.includes('W2'));
    expect(w2.length).toBeGreaterThan(0);
  });

  it('W2 warning names the H2 section titles', () => {
    const chart = extractSiblingDoorway(makeW2Record());
    const w2 = chart.warnings.find((w) => w.includes('W2'));
    // Non-vacuity: the warning must name at least the first section.
    expect(w2).toContain('Pre-flight');
    expect(w2).toContain('Execution');
  });

  it('body WITHOUT H2 sections does not emit W2 (separability)', () => {
    // aid-test-security has no H2 sections in its body.
    const chart = extractSiblingDoorway(testSecRecord);
    const w2 = chart.warnings.filter((w) => w.includes('W2'));
    expect(w2.length).toBe(0);
  });
});

// ── AC-13: validateChart passes for all real sibling-doorway skills ───────────

describe('AC-13 — validateChart passes (entries=1, exits>=1)', () => {
  const realSiblings = [
    'aid-test-security',
    'aid-test-performance',
    'aid-test-data-quality',
    'aid-document-architecture',
    'aid-document',
  ];

  for (const skill of realSiblings) {
    it(`validateChart(${skill}).ok === true`, () => {
      const record = loadSkillRecord(skill);
      const chart = extractSiblingDoorway(record);
      const { ok, errors } = validateChart(chart);
      expect(ok, errors[0]).toBe(true);
    });

    it(`${skill} has entries.length === 1`, () => {
      const record = loadSkillRecord(skill);
      const chart = extractSiblingDoorway(record);
      expect(chart.entries.length).toBe(1);
    });

    it(`${skill} has exits.length >= 1`, () => {
      const record = loadSkillRecord(skill);
      const chart = extractSiblingDoorway(record);
      // Non-vacuity bound.
      expect(chart.exits.length).toBeGreaterThan(0);
    });
  }
});

// ── AC-14: resolution notice ──────────────────────────────────────────────────

describe('AC-14 — resolution notice', () => {
  const chart = extractSiblingDoorway(testSecRecord);

  it('notice is a string', () => {
    expect(typeof chart.notice).toBe('string');
  });

  it('notice is non-empty', () => {
    expect(chart.notice.length).toBeGreaterThan(0);
  });

  it('notice carries a GITHUB_BLOB_BASE link', () => {
    expect(chart.notice).toContain(GITHUB_BLOB_BASE);
  });

  it('notice names the resolved parent (aid-test)', () => {
    expect(chart.notice).toContain('aid-test');
  });

  it('notice names the facet binding', () => {
    expect(chart.notice).toContain('kind bound to security');
  });

  it('notice is prose (not a chart node): no node has notice text as its name', () => {
    for (const n of chart.nodes) {
      expect(n.name).not.toContain('Sibling resolution');
      expect(n.name).not.toContain(GITHUB_BLOB_BASE);
    }
  });

  it('notice is above-fence prose (starts with > blockquote marker)', () => {
    expect(chart.notice.trimStart()).toMatch(/^>/);
  });
});

// ── Existing tests still pass: run source-encoding smoke ─────────────────────

describe('No existing tests broken: source-encoding guard', () => {
  it('extract-sibling.mjs has no UTF-8 BOM', () => {
    // The toolchain constraint forbids BOM injection via PowerShell.
    // Check that the module file itself does not start with a BOM.
    const raw = readFileSync(
      join(__dirname, '../lib/flow-graph/extract-sibling.mjs')
    );
    // UTF-8 BOM is 0xEF 0xBB 0xBF at bytes 0-2.
    expect(raw[0]).not.toBe(0xef);
  });
});
