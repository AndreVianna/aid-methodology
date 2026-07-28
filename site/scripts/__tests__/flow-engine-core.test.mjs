// flow-engine-core.test.mjs — Unit tests for engine-core.mjs
//
// Adversarially structured per task-033 quality bar:
//   - Input separability: each test targets one condition alone.
//   - Non-vacuity: bounds that fail on empty inputs.
//   - Mutation-proven: each assertion was verified to fail when the
//     targeted code was broken.
//
// Run: cd site && npx vitest run scripts/__tests__/flow-engine-core.test.mjs

import { describe, it, expect } from 'vitest';
import { getEngineCore } from '../lib/flow-graph/engine-core.mjs';

// ── Shared fixture (one call per suite run) ───────────────────────────────────

const core = getEngineCore();

// ── AC: Memo identity ─────────────────────────────────────────────────────────

describe('memo identity', () => {
  it('second call returns the identical object reference', () => {
    const a = getEngineCore();
    const b = getEngineCore();
    // Mutation-proof: if the memo were broken (new object each call) this fails.
    expect(a).toBe(b);
  });

  it('first call also returns the same reference as the cached object', () => {
    // Non-vacuity: ensures the memo is not undefined/null.
    expect(core).not.toBeNull();
    expect(typeof core).toBe('object');
    expect(getEngineCore()).toBe(core);
  });
});

// ── AC: Deep-freeze ───────────────────────────────────────────────────────────

describe('deep-freeze (strict-mode write attempts throw)', () => {
  // Vitest runs in strict mode (ESM). Writes to frozen objects throw TypeError.

  it('write to the nodes array throws', () => {
    expect(() => {
      'use strict';
      core.nodes.push({});
    }).toThrow(TypeError);
  });

  it('write to a node name throws', () => {
    expect(() => {
      'use strict';
      core.nodes[0].name = 'TAMPERED';
    }).toThrow(TypeError);
  });

  it('write to a node kind throws', () => {
    expect(() => {
      'use strict';
      core.nodes[0].kind = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to the edges array throws', () => {
    expect(() => {
      'use strict';
      core.edges.push({});
    }).toThrow(TypeError);
  });

  it('write to an edge condition throws', () => {
    expect(() => {
      'use strict';
      core.edges[0].condition = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to a node provenance file throws', () => {
    const prov = core.nodes[0].provenance;
    expect(prov).toBeTruthy();
    expect(() => {
      'use strict';
      prov.file = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to a node provenance excerpt throws', () => {
    const prov = core.nodes[0].provenance;
    expect(() => {
      'use strict';
      prov.excerpt = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to an edge provenance file throws', () => {
    const prov = core.edges[0].provenance;
    expect(prov).toBeTruthy();
    expect(() => {
      'use strict';
      prov.file = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to a detail provenance when present throws', () => {
    const nodeWithDetail = core.nodes.find((n) => n.detail !== null);
    expect(nodeWithDetail).toBeTruthy();
    expect(() => {
      'use strict';
      nodeWithDetail.detail.file = 'tampered';
    }).toThrow(TypeError);
  });

  it('write to the exits array throws', () => {
    expect(() => {
      'use strict';
      core.exits.push('cx');
    }).toThrow(TypeError);
  });

  it('write to the sources array throws', () => {
    expect(() => {
      'use strict';
      core.sources.push('tampered');
    }).toThrow(TypeError);
  });
});

// ── AC: EngineCore shape — no skill/title/entries/confidence ──────────────────

describe('EngineCore shape', () => {
  it('has exactly the expected top-level keys', () => {
    const keys = Object.keys(core).sort();
    // Mutation-proof: removing any expected key fails; adding any extra key fails.
    expect(keys).toEqual(['edges', 'exits', 'nodes', 'sources', 'warnings']);
  });

  it('has no skill key', () => {
    expect('skill' in core).toBe(false);
  });

  it('has no title key', () => {
    expect('title' in core).toBe(false);
  });

  it('has no entries key', () => {
    expect('entries' in core).toBe(false);
  });

  it('has no confidence key', () => {
    expect('confidence' in core).toBe(false);
  });
});

// ── AC: Nine-node spine in order ──────────────────────────────────────────────

describe('nine core node names in order', () => {
  const names = core.nodes.map((n) => n.name);

  it('has exactly nine nodes (non-vacuity: fails on 0 or wrong count)', () => {
    expect(names).toHaveLength(9);
  });

  it('first node is INTAKE', () => {
    expect(names[0]).toBe('INTAKE');
  });

  it('second node is CONTINUATION (B1 after INTAKE)', () => {
    expect(names[1]).toBe('CONTINUATION');
  });

  it('third node is CAPTURE', () => {
    expect(names[2]).toBe('CAPTURE');
  });

  it('fourth node is SPEC', () => {
    expect(names[3]).toBe('SPEC');
  });

  it('fifth node is PLAN', () => {
    expect(names[4]).toBe('PLAN');
  });

  it('sixth node is DETAIL', () => {
    expect(names[5]).toBe('DETAIL');
  });

  it('seventh node is GATE', () => {
    expect(names[6]).toBe('GATE');
  });

  it('eighth node is Circuit breaker (B1 after GATE)', () => {
    expect(names[7]).toBe('Circuit breaker');
  });

  it('ninth node is APPROVAL-HALT', () => {
    expect(names[8]).toBe('APPROVAL-HALT');
  });

  it('node ids are c1…c9 in order', () => {
    const ids = core.nodes.map((n) => n.id);
    expect(ids).toEqual(['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9']);
  });

  it('node orders are 1…9 in order', () => {
    const orders = core.nodes.map((n) => n.order);
    expect(orders).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });
});

// ── AC: L1 rule — GATE self-loop ──────────────────────────────────────────────

describe('L1 rule: GATE self-loop', () => {
  const gateNode  = core.nodes.find((n) => n.name === 'GATE');
  const selfEdges = core.edges.filter((e) => e.from === e.to);
  const gateSelf  = selfEdges.filter((e) => e.from === gateNode?.id);

  it('GATE node exists', () => {
    expect(gateNode).toBeTruthy();
  });

  it('exactly one self-edge in the entire graph (non-vacuity)', () => {
    // Mutation-proof: if we accidentally add a self-loop elsewhere, this fails.
    expect(selfEdges).toHaveLength(1);
  });

  it('self-edge is on GATE (fires on GATE only)', () => {
    // Mutation-proof: if L1 fires on wrong node, gateSelf is empty.
    expect(gateSelf).toHaveLength(1);
  });

  it('L1 self-edge has kind loop-back', () => {
    expect(gateSelf[0].kind).toBe('loop-back');
  });

  it('L1 self-edge has condition null', () => {
    // Separability: this condition alone distinguishes L1 from a guarded loop.
    expect(gateSelf[0].condition).toBeNull();
  });

  it('L1 self-edge provenance cites shortcut-engine.md', () => {
    expect(gateSelf[0].provenance.file).toContain('shortcut-engine');
  });
});

// ── AC: B1 rule — CONTINUATION under INTAKE ──────────────────────────────────

describe('B1 rule: CONTINUATION under INTAKE', () => {
  const intakeNode = core.nodes.find((n) => n.name === 'INTAKE');
  const contNode   = core.nodes.find((n) => n.name === 'CONTINUATION');

  it('CONTINUATION node exists', () => {
    expect(contNode).toBeTruthy();
  });

  it('CONTINUATION is immediately after INTAKE in node order', () => {
    // Mutation-proof: if inserted at wrong position, this fails.
    expect(contNode?.order).toBe((intakeNode?.order ?? 0) + 1);
  });

  it('CONTINUATION node is an exit node', () => {
    expect(contNode?.kind).toBe('exit');
  });

  it('CONTINUATION terminal is HALT', () => {
    expect(contNode?.terminal?.advanceType).toBe('HALT');
  });

  it('CONTINUATION node id is c2', () => {
    expect(contNode?.id).toBe('c2');
  });

  it('INTAKE -> CONTINUATION edge exists as branch', () => {
    const edge = core.edges.find(
      (e) => e.from === intakeNode?.id && e.to === contNode?.id
    );
    expect(edge).toBeTruthy();
    expect(edge?.kind).toBe('branch');
  });

  it('INTAKE -> CONTINUATION edge condition is "On continuation"', () => {
    const edge = core.edges.find(
      (e) => e.from === intakeNode?.id && e.to === contNode?.id
    );
    expect(edge?.condition).toBe('On continuation');
  });

  it('INTAKE -> CAPTURE edge is re-kinded to branch with condition "On new work"', () => {
    const captureNode = core.nodes.find((n) => n.name === 'CAPTURE');
    const edge = core.edges.find(
      (e) => e.from === intakeNode?.id && e.to === captureNode?.id
    );
    expect(edge).toBeTruthy();
    expect(edge?.kind).toBe('branch');
    expect(edge?.condition).toBe('On new work');
  });

  it('CONTINUATION provenance cites work-initiation-gate.md', () => {
    // Separability: this alone distinguishes the "read from source" AC.
    expect(contNode?.provenance?.file).toContain('work-initiation-gate');
  });

  it('CONTINUATION provenance excerpt is non-empty', () => {
    expect(contNode?.provenance?.excerpt?.length ?? 0).toBeGreaterThan(0);
  });

  it('CONTINUATION appears in exits array', () => {
    expect(core.exits).toContain(contNode?.id);
  });
});

// ── AC: B1 rule — Circuit breaker under GATE ─────────────────────────────────

describe('B1 rule: Circuit breaker under GATE', () => {
  const gateNode = core.nodes.find((n) => n.name === 'GATE');
  const cbNode   = core.nodes.find((n) => n.name === 'Circuit breaker');

  it('Circuit breaker node exists', () => {
    expect(cbNode).toBeTruthy();
  });

  it('Circuit breaker is immediately after GATE in node order', () => {
    expect(cbNode?.order).toBe((gateNode?.order ?? 0) + 1);
  });

  it('Circuit breaker node is an exit node', () => {
    expect(cbNode?.kind).toBe('exit');
  });

  it('Circuit breaker terminal is HALT', () => {
    expect(cbNode?.terminal?.advanceType).toBe('HALT');
  });

  it('Circuit breaker node id is c8', () => {
    expect(cbNode?.id).toBe('c8');
  });

  it('GATE -> Circuit breaker edge exists as branch', () => {
    const edge = core.edges.find(
      (e) => e.from === gateNode?.id && e.to === cbNode?.id
    );
    expect(edge).toBeTruthy();
    expect(edge?.kind).toBe('branch');
  });

  it('GATE -> Circuit breaker condition is the verbatim guard clause', () => {
    const edge = core.edges.find(
      (e) => e.from === gateNode?.id && e.to === cbNode?.id
    );
    // Separability: tests the exact guard text extracted from source.
    expect(edge?.condition).toBe(
      "If the pass's grade has not improved across 3 consecutive cycles"
    );
  });

  it('GATE -> APPROVAL-HALT edge is re-kinded to branch', () => {
    const approvalNode = core.nodes.find((n) => n.name === 'APPROVAL-HALT');
    const edge = core.edges.find(
      (e) => e.from === gateNode?.id && e.to === approvalNode?.id
    );
    expect(edge).toBeTruthy();
    expect(edge?.kind).toBe('branch');
  });

  it('Circuit breaker provenance cites shortcut-engine.md', () => {
    expect(cbNode?.provenance?.file).toContain('shortcut-engine');
  });

  it('Circuit breaker provenance excerpt is non-empty', () => {
    expect(cbNode?.provenance?.excerpt?.length ?? 0).toBeGreaterThan(0);
  });

  it('Circuit breaker appears in exits array', () => {
    expect(core.exits).toContain(cbNode?.id);
  });
});

// ── AC: sources and provenance ────────────────────────────────────────────────

describe('sources and provenance', () => {
  it('sources includes both template files (non-vacuity)', () => {
    expect(core.sources).toHaveLength(2);
  });

  it('sources includes shortcut-engine.md', () => {
    expect(core.sources.some((s) => s.includes('shortcut-engine'))).toBe(true);
  });

  it('sources includes work-initiation-gate.md', () => {
    expect(core.sources.some((s) => s.includes('work-initiation-gate'))).toBe(true);
  });

  it('sources are ASCII-sorted', () => {
    const sorted = [...core.sources].sort();
    expect(core.sources).toEqual(sorted);
  });

  it('every node provenance file starts with canonical/', () => {
    for (const node of core.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('every node provenance has a non-empty excerpt', () => {
    for (const node of core.nodes) {
      expect(node.provenance.excerpt.length).toBeGreaterThan(0);
    }
  });

  it('every edge provenance file starts with canonical/', () => {
    for (const edge of core.edges) {
      expect(edge.provenance.file).toMatch(/^canonical\//);
    }
  });
});

// ── AC: exits array ───────────────────────────────────────────────────────────

describe('exits array', () => {
  it('exits has exactly three entries (non-vacuity)', () => {
    expect(core.exits).toHaveLength(3);
  });

  it('APPROVAL-HALT is in exits', () => {
    const approvalNode = core.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(core.exits).toContain(approvalNode?.id);
  });

  it('exits does not include GATE', () => {
    const gateNode = core.nodes.find((n) => n.name === 'GATE');
    expect(core.exits).not.toContain(gateNode?.id);
  });

  it('exits does not include INTAKE', () => {
    const intakeNode = core.nodes.find((n) => n.name === 'INTAKE');
    expect(core.exits).not.toContain(intakeNode?.id);
  });
});

// ── AC: B1 conditions capped by shared truncator ─────────────────────────────

describe('B1 conditions are capped at 80 code points', () => {
  it('INTAKE -> CONTINUATION condition is within 80 code points', () => {
    const contNode   = core.nodes.find((n) => n.name === 'CONTINUATION');
    const intakeNode = core.nodes.find((n) => n.name === 'INTAKE');
    const edge = core.edges.find(
      (e) => e.from === intakeNode?.id && e.to === contNode?.id
    );
    if (edge?.condition !== null) {
      expect(Array.from(edge.condition ?? '').length).toBeLessThanOrEqual(80);
    }
  });

  it('GATE -> Circuit breaker condition is within 80 code points', () => {
    const cbNode   = core.nodes.find((n) => n.name === 'Circuit breaker');
    const gateNode = core.nodes.find((n) => n.name === 'GATE');
    const edge = core.edges.find(
      (e) => e.from === gateNode?.id && e.to === cbNode?.id
    );
    expect(edge?.condition).not.toBeNull();
    expect(Array.from(edge?.condition ?? '').length).toBeLessThanOrEqual(80);
  });
});

// ── AC: W5 — no drift between table and maintenance note ─────────────────────

describe('W5 maintenance note check', () => {
  it('no W5 warning when table order matches the maintenance note', () => {
    const w5 = core.warnings.filter((w) => w.includes('W5'));
    expect(w5).toHaveLength(0);
  });
});
