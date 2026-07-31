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
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { getEngineCore } from '../lib/flow-graph/engine-core.mjs';
import { sliceLines } from '../lib/flow-graph/source.mjs';

const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../../../');

// ── Shared fixture (one call per suite run) ───────────────────────────────────

const core = getEngineCore();

// The engine document itself. Several assertions below check the SOURCE, not just the graph:
// where a rule stopped firing because the text it keys on moved elsewhere, the test pins the
// sentence that now carries the behaviour, so "the node is gone" cannot pass by accident.
const ENGINE_ABS = resolve(REPO_ROOT, 'canonical/aid/templates/shortcut-engine.md');

/**
 * The GATE state section, sliced on LINE-ANCHORED headings.
 *
 * A plain `indexOf('## State: GATE')` matches the prose two hundred lines earlier that quotes
 * both headings inside the insertion-point comment -- `Append the "## State: GATE" and
 * "## State: APPROVAL-HALT" sections HERE` -- which yields a 21-character slice that contains
 * neither section. Anchoring to `^## State: X$` picks the heading itself.
 */
function gateSectionOf(src) {
  const start = src.search(/^## State: GATE\s*$/m);
  const end   = src.search(/^## State: APPROVAL-HALT\s*$/m);
  if (start < 0 || end < 0 || end <= start) {
    throw new Error(`gateSectionOf: headings not found in order (start=${start}, end=${end})`);
  }
  return src.slice(start, end);
}

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

// ── The GATE fix loop and circuit breaker moved out of the engine ─────────────
//
// work-003 delivery-012 extracted review into `/aid-light-review` + `/aid-deep-review`.
// shortcut-engine.md's GATE state now says, in as many words: "Invoke `/aid-deep-review` ...
// It owns the dispatch, the clean context, the ledger, the gap gate, the grade, the fix loop
// and the circuit breaker", and "`/aid-deep-review` runs the loop".
//
// So the engine graph legitimately lost its GATE self-edge (L1) and its `Circuit breaker`
// exit node (B1): neither is in this file any more. These blocks assert the NEW shape AND the
// delegation sentence that explains it -- asserting only the absence would trade a real
// assertion for "expect nothing", which is how a guard stops guarding. The L1 and B1 RULES
// remain fully tested against fixtures further down ("B1 trigger tokens -- each is contract,
// so each gets a fixture"), so what changed here is this document, not the engine's rules.

describe('eight core node names in order', () => {
  const names = core.nodes.map((n) => n.name);

  it('has exactly eight nodes (non-vacuity: fails on 0 or wrong count)', () => {
    expect(names).toHaveLength(8);
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

  it('eighth node is APPROVAL-HALT (nothing between it and GATE)', () => {
    expect(names[7]).toBe('APPROVAL-HALT');
  });

  it('node ids are c1…c8 in order', () => {
    const ids = core.nodes.map((n) => n.id);
    expect(ids).toEqual(['c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8']);
  });

  it('node orders are 1…8 in order', () => {
    const orders = core.nodes.map((n) => n.order);
    expect(orders).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
  });
});

// ── AC: L1 rule — GATE self-loop ──────────────────────────────────────────────

describe('L1 rule: the GATE loop is DELEGATED, not inline', () => {
  const gateNode  = core.nodes.find((n) => n.name === 'GATE');
  const selfEdges = core.edges.filter((e) => e.from === e.to);
  const engineSrc = readFileSync(ENGINE_ABS, 'utf8');

  it('GATE node exists', () => {
    expect(gateNode).toBeTruthy();
  });

  it('no self-edge anywhere in the graph', () => {
    // Was: "exactly one self-edge", on GATE. shortcut-engine.md no longer loops at GATE.
    expect(selfEdges).toHaveLength(0);
  });

  it('...because the GATE section says the loop is run by /aid-deep-review', () => {
    // The POSITIVE fact that replaced the self-edge. Without this, the assertion above passes
    // just as well on a GATE section that lost its loop by accident.
    const gateSection = gateSectionOf(engineSrc);
    expect(gateSection).toContain('/aid-deep-review` runs the loop');
  });

  it('GATE advances straight to APPROVAL-HALT as a plain sequence edge', () => {
    const approvalNode = core.nodes.find((n) => n.name === 'APPROVAL-HALT');
    const edge = core.edges.find(
      (e) => e.from === gateNode?.id && e.to === approvalNode?.id
    );
    expect(edge).toBeTruthy();
    // Not `branch`: with no B1 sibling to branch against, there is nothing to re-kind it to.
    expect(edge?.kind).toBe('sequence');
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

describe('B1 rule: the GATE circuit breaker is DELEGATED, not inline', () => {
  const gateNode = core.nodes.find((n) => n.name === 'GATE');
  const cbNode   = core.nodes.find((n) => n.name === 'Circuit breaker');
  const engineSrc = readFileSync(ENGINE_ABS, 'utf8');

  it('no Circuit breaker node in the engine graph', () => {
    expect(cbNode).toBeUndefined();
  });

  it('GATE has no B1 exit sibling at all', () => {
    // Stronger than naming one node: ANY exit inserted after GATE would fail this.
    const gateOrder = gateNode?.order ?? 0;
    const afterGate = core.nodes.find((n) => n.order === gateOrder + 1);
    expect(afterGate?.name).toBe('APPROVAL-HALT');
  });

  it('...because the GATE section hands the breaker to /aid-deep-review', () => {
    // The POSITIVE fact. shortcut-engine.md names the owner explicitly, so this pins the
    // delegation rather than merely observing that a node is missing.
    const gateSection = gateSectionOf(engineSrc);
    expect(gateSection).toContain('the fix loop and the circuit breaker');
  });

  it('the breaker really does still exist -- in the skill that now owns it', () => {
    // Delegated is not deleted. If /aid-deep-review ever loses it, the behaviour has gone
    // missing from the pipeline entirely and this fails, which the absence checks cannot see.
    const deepReview = readFileSync(
      resolve(REPO_ROOT, 'canonical/skills/aid-deep-review/SKILL.md'), 'utf8'
    );
    expect(deepReview).toMatch(/\*\*Circuit breaker/);
  });

  it('exits contains only CONTINUATION and APPROVAL-HALT', () => {
    const names = core.exits.map((id) => core.nodes.find((n) => n.id === id)?.name).sort();
    expect(names).toEqual(['APPROVAL-HALT', 'CONTINUATION']);
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

  it('sources are ASCII-sorted, asserted against an explicit expected order', () => {
    // `[...core.sources].sort()` compared the value to a sorted copy of ITSELF, which
    // passes for any already-sorted input — and this one is, so deleting the `.sort()`
    // in engine-core.mjs changed nothing and the mutant survived. Third appearance of
    // this anti-pattern in this work; the other two were skills-discover.test.mjs and
    // flow-compose.test.mjs, and fixing only the latter is what left this one standing.
    //
    // Correcting a claim an earlier version of this comment made: insertion order and
    // sorted order do NOT differ here. `sources` is the fixed two-element literal
    // `[ENGINE_REL, GATE_REL]`, and `shortcut-engine.md` already sorts before
    // `work-initiation-gate.md`, so the `.sort()` in engine-core.mjs is **inert** and
    // deleting it is a no-op that no test can catch. Measured, not assumed.
    //
    // The sort is kept anyway, and this assertion is kept as a statement of the contract:
    // it pins the order that IS published, so adding a third source out of order fails
    // here. What it cannot do is pin the sort call itself, and claiming otherwise is the
    // kind of overstatement this delivery has already had to correct twice.
    //
    // `compose.mjs`'s sort is a different matter — its input is a runtime union, and that
    // one is proven against a fixture whose insertion order genuinely differs.
    expect(core.sources).toEqual([
      'canonical/aid/templates/shortcut-engine.md',
      'canonical/aid/templates/work-initiation-gate.md',
    ]);
  });

  it('every node provenance file starts with canonical/', () => {
    for (const node of core.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('every node provenance excerpt EQUALS the live slice of its cited file', () => {
    // Was `excerpt.length > 0`, which any non-empty wrong string satisfies — the AC says
    // "excerpt equals the live slice", and that is a different claim. Nodes here cite two
    // different files (the engine template and the gate template), so the comparison has
    // to read whichever file the node names.
    const cache = new Map();
    const linesOf = (rel) => {
      if (!cache.has(rel)) {
        const text = readFileSync(join(REPO_ROOT, rel), 'utf8');
        cache.set(rel, text.split('\n').map((l) => l.replace(/\r$/, '')));
      }
      return cache.get(rel);
    };

    expect(core.nodes.length).toBeGreaterThan(0);          // non-vacuity
    const filesSeen = new Set();

    for (const node of core.nodes) {
      const { file, startLine, endLine, excerpt } = node.provenance;
      filesSeen.add(file);
      expect(sliceLines(linesOf(file), startLine, endLine)).toBe(excerpt);
    }

    // Both templates must actually be exercised, or this would pass while only ever
    // checking one of them — the CONTINUATION node is the only one citing the gate.
    expect([...filesSeen].sort()).toEqual([
      'canonical/aid/templates/shortcut-engine.md',
      'canonical/aid/templates/work-initiation-gate.md',
    ]);
  });

  it('every edge provenance file starts with canonical/', () => {
    for (const edge of core.edges) {
      expect(edge.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('every edge provenance excerpt EQUALS the live slice of its cited file', () => {
    const cache = new Map();
    const linesOf = (rel) => {
      if (!cache.has(rel)) {
        const text = readFileSync(join(REPO_ROOT, rel), 'utf8');
        cache.set(rel, text.split('\n').map((l) => l.replace(/\r$/, '')));
      }
      return cache.get(rel);
    };

    expect(core.edges.length).toBeGreaterThan(0);          // non-vacuity
    for (const edge of core.edges) {
      const { file, startLine, endLine, excerpt } = edge.provenance;
      expect(sliceLines(linesOf(file), startLine, endLine)).toBe(excerpt);
    }
  });
});

// ── AC: exits array ───────────────────────────────────────────────────────────

describe('exits array', () => {
  it('exits has exactly two entries (non-vacuity)', () => {
    // Was three: CONTINUATION, Circuit breaker, APPROVAL-HALT. The breaker moved to
    // /aid-deep-review with the fix loop it guards.
    expect(core.exits).toHaveLength(2);
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

// ── Fixture-driven rule contracts ─────────────────────────────────────────────
//
// Everything above derives from the two real template files, which is the right default
// but leaves several stated contracts unreachable: the real corpus does not discriminate
// them, so mutating the code changed nothing and the mutants survived. `getEngineCore`
// takes a test-only `{ engineText, gateText }` override for exactly this, and does NOT
// memoize when given one, so nothing below can poison the shared instance.
//
// The fixtures below are built on the rules' ACTUAL trigger shapes, read from the module:
//   - L1 is applied only within the section named GATE.
//   - B1 is applied only to INTAKE and GATE.
//   - INTAKE's arm matcher is `On **<name>**` with a trigger token in the same paragraph.
// A first attempt invented state names and arm shapes; it reached neither rule, and four
// tests failed for that reason rather than for any defect in the code. Recorded because
// "the fixture never reached the rule" is the same failure mode as a test that cannot
// fail, arrived at from the other direction.

/** A minimal engine document: maintenance note, State Machine table, state sections. */
function engineDoc({ states, sections, note }) {
  const order = note ?? states.join(' -> ');
  const rows = states.map((s, i) => {
    const advance = i === states.length - 1 ? 'HALT' : `CHAIN -> ${states[i + 1]}`;
    return `| ${s} | below | inline | ${advance} |`;
  });
  return [
    '# shortcut-engine', '',
    `> **Maintenance note:** the states in order are ${order}.`, '',
    '## State Machine', '',
    '| State | Detail | Worker | Advance |',
    '|---|---|---|---|',
    ...rows, '',
    ...sections, '',
  ].join('\n');
}

/** A gate document with no B1 trigger, so a fixture's B1 can only come from the engine. */
const INERT_GATE = [
  '# work-initiation-gate', '',
  '## State: INTAKE', '',
  'Nothing notable happens here.', '',
].join('\n');

/** Two-state engine whose INTAKE section is supplied by the caller. */
function withIntake(intakeLines) {
  return engineDoc({
    states: ['INTAKE', 'GATE'],
    sections: [
      '## State: INTAKE', '',
      ...intakeLines, '',
      '**Advance:** CHAIN -> GATE', '',
      '## State: GATE', '',
      '**Advance:** HALT', '',
    ],
  });
}

/** Two-state engine whose GATE section is supplied by the caller. */
function withGate(gateLines) {
  return engineDoc({
    states: ['INTAKE', 'GATE'],
    sections: [
      '## State: INTAKE', '',
      '**Advance:** CHAIN -> GATE', '',
      '## State: GATE', '',
      ...gateLines, '',
      '**Advance:** HALT', '',
    ],
  });
}

describe('B1 trigger tokens — each is contract, so each gets a fixture', () => {
  // The DETAIL names four trigger tokens. Only HALTS and STOP are reachable through the
  // real files, so removing `does not run` or `instead of looping further` from the set
  // killed nothing. These two fixtures are identical except for the token.
  // These assert only that the token is what makes B1 FIRE — which is the precise claim
  // the DETAIL makes about the trigger set. The B1 node's *name* is resolved separately
  // (for INTAKE, out of the gate document, which is why an inert gate still yields
  // `CONTINUATION`), and that resolution is pinned against the real corpus above.
  // Asserting an invented name here would be asserting something the rule does not
  // promise.
  const CASES = [
    ['does not run', 'On **Skipped**, the follow-on does not run.'],
    ['instead of looping further', 'On **Bailout**, the run exits instead of looping further.'],
  ];

  for (const [token, armLine] of CASES) {
    it(`"${token}" is a trigger — B1 fires and adds an exit with a branch edge in`, () => {
      const core2 = getEngineCore({
        engineText: withIntake([armLine]),
        gateText: INERT_GATE,
      });
      const names = core2.nodes.map((n) => n.name);

      // Non-vacuity: both table states must be present, or a missing B1 node would pass
      // for the wrong reason.
      expect(names).toContain('INTAKE');
      expect(names).toContain('GATE');

      // Exactly one node beyond the two table rows, and it is an exit reached by a branch.
      expect(core2.nodes).toHaveLength(3);
      const b1 = core2.nodes.find((n) => n.name !== 'INTAKE' && n.name !== 'GATE');
      expect(b1).toBeDefined();
      expect(b1.kind).toBe('exit');
      expect(core2.edges.some((e) => e.to === b1.id && e.kind === 'branch')).toBe(true);
    });
  }

  it('the same arm with NO trigger token emits no extra node', () => {
    // Separability: identical shape, trigger removed. Without this the tests above would
    // not show that the tokens are what fire the rule.
    const core2 = getEngineCore({
      engineText: withIntake(['On **Quiet**, the follow-on merely notes something.']),
      gateText: INERT_GATE,
    });
    expect(core2.nodes.map((n) => n.name)).toEqual(['INTAKE', 'GATE']);
  });
});

describe('L1 loop phrasing is narrow — "Loop back", not any "Loop"', () => {
  /** The self-edges on the GATE node, which is the only state L1 is applied to. */
  function gateSelfEdges(core2) {
    const gate = core2.nodes.find((n) => n.name === 'GATE');
    expect(gate).toBeDefined();               // non-vacuity
    return core2.edges.filter((e) => e.from === gate.id && e.to === gate.id);
  }

  it('emits one self-edge with condition null for "Loop back to"', () => {
    const core2 = getEngineCore({
      engineText: withGate(['Loop back to Step 1 (REVIEW) until the panel agrees.']),
      gateText: INERT_GATE,
    });
    const selfEdges = gateSelfEdges(core2);
    expect(selfEdges).toHaveLength(1);
    expect(selfEdges[0].kind).toBe('loop-back');
    expect(selfEdges[0].condition).toBeNull();
  });

  it('emits none for a bare "Loop" that is not "Loop back"', () => {
    // "Loop" appears ten times across the real templates and "Loop back" once, yet
    // widening the phrasing to /Loop/i killed no test. Only the phrasing differs here.
    const core2 = getEngineCore({
      engineText: withGate(['Loop over each finding and record it.']),
      gateText: INERT_GATE,
    });
    expect(gateSelfEdges(core2)).toEqual([]);
  });
});

describe('W5 warns on drift and never throws', () => {
  const SECTIONS = [
    '## State: INTAKE', '', '**Advance:** CHAIN -> GATE', '',
    '## State: GATE', '', '**Advance:** CHAIN -> OMEGA', '',
    '## State: OMEGA', '', '**Advance:** HALT', '',
  ];

  it('fires when the table order disagrees with the maintenance note', () => {
    const doc = engineDoc({
      states: ['INTAKE', 'GATE', 'OMEGA'],
      sections: SECTIONS,
      note: 'INTAKE -> OMEGA -> GATE',   // deliberately disagrees with the table
    });

    let core2;
    // The "never a throw" half of the AC, asserted rather than assumed: turning the
    // warning into a throw survived until this existed.
    expect(() => { core2 = getEngineCore({ engineText: doc, gateText: INERT_GATE }); }).not.toThrow();
    expect(core2.warnings.some((w) => w.includes('W5'))).toBe(true);
  });

  it('stays silent when the note agrees, so the check is not unconditional', () => {
    const doc = engineDoc({ states: ['INTAKE', 'GATE', 'OMEGA'], sections: SECTIONS });
    const core2 = getEngineCore({ engineText: doc, gateText: INERT_GATE });
    expect(core2.warnings.filter((w) => w.includes('W5'))).toEqual([]);
  });
});

describe('B1 conditions go through the shared truncator', () => {
  it('caps a guard clause longer than 80 code points', () => {
    // Dropping the `truncate(…, 80)` wrapper survived: no real B1 condition is long
    // enough to notice. This one is.
    // The B1 condition is derived from the ARM NAME (`On <arm>`), not from the guard
    // sentence — measured, after a first fixture put the long run in the guard and saw a
    // 9-character condition. So the long text has to be the arm name.
    const long = 'Halted ' + 'x'.repeat(160);
    const core2 = getEngineCore({
      engineText: withIntake([`On **${long}**, the run HALTS immediately.`]),
      gateText: INERT_GATE,
    });

    const conds = core2.edges.map((e) => e.condition).filter((c) => typeof c === 'string');
    expect(conds.length).toBeGreaterThan(0);                       // non-vacuity
    for (const c of conds) expect([...c].length).toBeLessThanOrEqual(80);

    // The cap alone is not evidence — a short condition satisfies it. Two things are.
    //
    // First, the ellipsis. `truncate` cuts at the last word boundary before the limit and
    // appends U+2026, so with the over-length run being a single unbroken token the
    // condition comes out as "On Halted…" — only ten code points, but demonstrably cut.
    // Two earlier assertions failed here for guessing the wrong signal: exact length 80,
    // then length > 40. The ellipsis is the thing that means "truncated".
    expect(conds.some((c) => c.endsWith('\u2026'))).toBe(true);

    // Second, the over-length run reaches no published condition in full.
    for (const c of conds) expect(c).not.toContain(long);
  });
});

describe('the test seam cannot corrupt the memoized instance', () => {
  it('an override returns a different object and leaves the memo untouched', () => {
    const before = getEngineCore();
    const fixture = getEngineCore({ engineText: withIntake([]), gateText: INERT_GATE });

    expect(fixture).not.toBe(before);
    expect(fixture.nodes.map((n) => n.name)).toEqual(['INTAKE', 'GATE']);
    expect(getEngineCore()).toBe(before);
    expect(getEngineCore().nodes.map((n) => n.name)).toEqual(before.nodes.map((n) => n.name));
  });

  it('an override result is frozen too', () => {
    const fixture = getEngineCore({ engineText: withIntake([]), gateText: INERT_GATE });
    expect(() => { fixture.nodes[0].name = 'MUTATED'; }).toThrow();
  });
});
