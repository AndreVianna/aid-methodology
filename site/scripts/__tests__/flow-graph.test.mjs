// flow-graph.test.mjs — Unit tests for site/scripts/lib/flow-graph/model.mjs
//                        and site/scripts/lib/flow-graph/source.mjs.
//
// Coverage:
//   model.mjs:  truncate(), makeProvenance(), makeNode(), makeEdge(),
//               buildChart() — id assignment, entries/exits computation,
//               kind derivation, edge sort.
//               serializeChart() — key order, LF endings, determinism.
//   source.mjs: splitFrontmatter(), sliceLines(), buildProvenance(),
//               findStateSections() — heading detection, lead-paragraph
//               range, full-section range.
//
// Testing discipline:
//   - Every assertion drives the real module; no logic is re-implemented.
//   - Every guard and branch has a test that exercises it (mutation-proven).
//   - No hard-coded corpus counts (REQUIREMENTS §8 / KI-005).

import { describe, it, expect } from 'vitest';
import {
  truncate,
  makeProvenance,
  makeNode,
  makeEdge,
  buildChart,
  serializeChart,
} from '../lib/flow-graph/model.mjs';
import {
  splitFrontmatter,
  sliceLines,
  buildProvenance,
  findStateSections,
} from '../lib/flow-graph/source.mjs';
import { classifySkill } from '../lib/flow-graph/classify.mjs';
import { parseAdvanceBlock } from '../lib/flow-graph/advance.mjs';
import { validateChart } from '../lib/flow-graph/validate.mjs';

// No repo-root constant and no path resolution: this tier's fixtures are all inline in
// this file, so it reads nothing from `canonical/` or `.aid/works/` (task-031 AC-1).
// A REPO_ROOT was declared here and never used — removed rather than left as an
// invitation to reach outside the file.

// ── Shared fixtures ──────────────────────────────────────────────────────────

/** Minimal Provenance used wherever a real provenance is needed. */
const PROV = makeProvenance({
  file: 'canonical/skills/aid-test/SKILL.md',
  startLine: 1,
  endLine: 1,
  sourceKind: 'skill',
  excerpt: '| TEST | halt |',
});

/** Build a minimal node with sensible defaults. */
function node(order, name, terminal = null) {
  return makeNode({
    order,
    name,
    label: name,
    provenance: PROV,
    terminal,
  });
}

/** Build a minimal edge. */
function edge(from, to, kind = 'sequence') {
  return makeEdge({ from, to, kind, condition: null, advanceType: 'CHAIN', provenance: PROV });
}

/** Build a minimal exit terminal. */
function halt() {
  return { advanceType: 'HALT', handoff: null };
}

// ── truncate() ───────────────────────────────────────────────────────────────

describe('truncate — within limit', () => {
  it('returns text unchanged when equal to limit (no surrogates)', () => {
    const text = 'A'.repeat(60);
    expect(truncate(text, 60)).toBe(text);
  });

  it('returns text unchanged when shorter than limit', () => {
    expect(truncate('hello', 60)).toBe('hello');
  });

  it('returns text unchanged when exactly at limit=80', () => {
    const text = 'X'.repeat(80);
    expect(truncate(text, 80)).toBe(text);
  });
});

describe('truncate — word-boundary cut', () => {
  it('cuts at last whitespace and appends …', () => {
    // 61 code points: "abcde fghij" … must cut at the space before fghij
    const text = 'a'.repeat(55) + ' ' + 'b'.repeat(5); // 61 cp, space at 55
    const result = truncate(text, 60);
    expect(result.endsWith('\u2026')).toBe(true);
    expect(Array.from(result).length).toBeLessThanOrEqual(60);
  });

  it('strips trailing comma before appending …', () => {
    // "aaaa, bbbb" at 11 chars, but suppose we're over limit via a longer prefix
    const base = 'a'.repeat(55) + ', ' + 'b'.repeat(5); // 62 cp
    const result = truncate(base, 60);
    expect(result).not.toMatch(/,\u2026$/);
    expect(result.endsWith('\u2026')).toBe(true);
  });

  it('strips trailing semicolon before appending …', () => {
    const base = 'a'.repeat(55) + '; ' + 'b'.repeat(5);
    const result = truncate(base, 60);
    expect(result).not.toMatch(/;\u2026$/);
  });

  it('strips trailing colon before appending …', () => {
    const base = 'a'.repeat(55) + ': ' + 'b'.repeat(5);
    const result = truncate(base, 60);
    expect(result).not.toMatch(/:\u2026$/);
  });

  it('strips trailing em-dash (U+2014) before appending …', () => {
    const base = 'a'.repeat(53) + ' \u2014 ' + 'b'.repeat(5); // 62 cp
    const result = truncate(base, 60);
    expect(result).not.toMatch(/\u2014\u2026$/);
    expect(result.endsWith('\u2026')).toBe(true);
  });

  it('strips trailing hyphen before appending …', () => {
    const base = 'a'.repeat(55) + '- ' + 'b'.repeat(5);
    const result = truncate(base, 60);
    expect(result).not.toMatch(/-\u2026$/);
  });

  it('result is always ≤ limit code points (word-boundary path)', () => {
    const text = 'hello world '.repeat(6); // 72 cp, many spaces
    const result = truncate(text, 60);
    expect(Array.from(result).length).toBeLessThanOrEqual(60);
  });

  it('works correctly for limit=80', () => {
    const text = 'x'.repeat(70) + ' ' + 'y'.repeat(15); // 86 cp, space at 70
    const result = truncate(text, 80);
    expect(Array.from(result).length).toBeLessThanOrEqual(80);
    expect(result.endsWith('\u2026')).toBe(true);
  });
});

describe('truncate — no-whitespace-boundary hard cut', () => {
  it('hard-cuts at limit-1 code points when no whitespace exists', () => {
    const text = 'A'.repeat(65); // 65 code points, no spaces
    const result = truncate(text, 60);
    // Should be exactly 59 A's + '…' = 60 code points
    const cps = Array.from(result);
    expect(cps.length).toBe(60);
    expect(result.endsWith('\u2026')).toBe(true);
    expect(result.startsWith('A'.repeat(59))).toBe(true);
  });

  it('result is exactly limit code points (hard-cut path)', () => {
    const text = 'Z'.repeat(100);
    const result = truncate(text, 60);
    expect(Array.from(result).length).toBe(60);
  });

  it('hard-cut never exceeds limit even for surrogate-pair input', () => {
    // 𝟘 is U+1D7D8, a surrogate pair in JS (String.length=2, code points=1)
    // Build a string of 65 such characters (65 code points, String.length=130)
    const surrChar = '\uD835\uDFD8'; // 𝟘
    const text = surrChar.repeat(65); // 65 code points, no spaces
    const result = truncate(text, 60);
    const cps = Array.from(result);
    expect(cps.length).toBe(60);
    // The last code point must be '…' not a half-surrogate
    expect(cps[cps.length - 1]).toBe('\u2026');
    // The second-to-last must be a complete char (not a broken surrogate)
    expect(cps[cps.length - 2]).toBe(surrChar);
  });

  it('String.length is NOT used for measurement (surrogate pair keeps result ≤ limit)', () => {
    // If String.length were used, 65 chars × 2 = 130; limit=60 would incorrectly
    // trigger at index 59 of the String, which is mid-surrogate.
    const surrChar = '\uD835\uDFD8';
    const text = surrChar.repeat(65);
    const result = truncate(text, 60);
    // All non-ellipsis code points must be the original character (no half-surrogate)
    const cps = Array.from(result);
    const nonEllipsis = cps.filter((c) => c !== '\u2026');
    expect(nonEllipsis.every((c) => c === surrChar)).toBe(true);
  });
});

// ── makeProvenance() ─────────────────────────────────────────────────────────

describe('makeProvenance', () => {
  it('returns an object with all five fields', () => {
    const p = makeProvenance({
      file: 'canonical/skills/aid-foo/SKILL.md',
      startLine: 5,
      endLine: 10,
      sourceKind: 'skill',
      excerpt: 'line5\nline6',
    });
    expect(p.file).toBe('canonical/skills/aid-foo/SKILL.md');
    expect(p.startLine).toBe(5);
    expect(p.endLine).toBe(10);
    expect(p.sourceKind).toBe('skill');
    expect(p.excerpt).toBe('line5\nline6');
  });
});

// ── buildChart() — id assignment ─────────────────────────────────────────────

describe('buildChart — id assignment', () => {
  it('assigns n1 to the first node, n2 to the second, n3 to the third', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt()), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: [],
    });
    expect(chart.nodes[0].id).toBe('n1');
    expect(chart.nodes[1].id).toBe('n2');
    expect(chart.nodes[2].id).toBe('n3');
  });

  it('id matches ^[A-Za-z][A-Za-z0-9_]{0,31}$ for every node', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: Array.from({ length: 10 }, (_, i) => node(i + 1, 'S' + i, i === 9 ? halt() : null)),
      edges: Array.from({ length: 9 }, (_, i) => edge('n' + (i + 1), 'n' + (i + 2))),
      sources: [],
    });
    const idRe = /^[A-Za-z][A-Za-z0-9_]{0,31}$/;
    for (const n of chart.nodes) {
      expect(n.id).toMatch(idRe);
    }
  });
});

// ── buildChart() — entries computation ──────────────────────────────────────

describe('buildChart — entries', () => {
  it('entries contains every in-degree-0 node', () => {
    // n1 → n2 → n3; n4 is isolated with no incoming edges
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C', halt()), node(4, 'D', halt())],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: [],
    });
    // n1 and n4 are in-degree-0
    expect(chart.entries).toContain('n1');
    expect(chart.entries).toContain('n4');
    expect(chart.entries).not.toContain('n2');
    expect(chart.entries).not.toContain('n3');
  });

  it('entries is non-empty for a pure cycle (no in-degree-0 node)', () => {
    // n1 → n2 → n3 → n1 (pure cycle)
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3'), edge('n3', 'n1')],
      sources: [],
    });
    expect(chart.entries.length).toBeGreaterThanOrEqual(1);
  });

  it('pure cycle uses the lowest-order node as synthetic entry', () => {
    // n2 → n3 → n2 (cycle); n1 has in-degree 0 in another component
    // Build two separate components: n1 (isolated) and n2↔n3 cycle
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt()), node(2, 'B'), node(3, 'C')],
      edges: [edge('n2', 'n3'), edge('n3', 'n2')],
      sources: [],
    });
    // n2 is lowest-order in the cycle component; n1 has in-degree 0
    expect(chart.entries).toContain('n1');
    expect(chart.entries).toContain('n2');
    expect(chart.entries).not.toContain('n3');
  });

  it('entries contains exactly the in-degree-0 node for a simple linear chain', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'START'), node(2, 'MID'), node(3, 'END', halt())],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: [],
    });
    expect(chart.entries).toEqual(['n1']);
  });

  it('entries ids are all valid node ids in the chart', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt()), node(2, 'B', halt())],
      edges: [],
      sources: [],
    });
    const nodeIds = new Set(chart.nodes.map((n) => n.id));
    for (const id of chart.entries) {
      expect(nodeIds.has(id)).toBe(true);
    }
  });
});

// ── buildChart() — exits computation ────────────────────────────────────────

describe('buildChart — exits', () => {
  it('exits contains every node with terminal !== null', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt()), node(3, 'C', halt())],
      edges: [edge('n1', 'n2'), edge('n1', 'n3')],
      sources: [],
    });
    expect(chart.exits).toContain('n2');
    expect(chart.exits).toContain('n3');
    expect(chart.exits).not.toContain('n1');
  });

  it('exits is non-empty even when no node has a terminal (fallback fires)', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3'), edge('n3', 'n1')],
      sources: [],
    });
    expect(chart.exits.length).toBeGreaterThanOrEqual(1);
  });

  it('fallback designates the highest-order node as exit', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: [],
    });
    // `toEqual`, not `toContain`. The DETAIL designates "the highest-`order` node"
    // — singular — and `toContain('n3')` is satisfied by any superset, so mutating
    // the fallback to designate EVERY node as an exit survived the whole suite.
    // An exact array is the only assertion that pins the count as well as the choice.
    expect(chart.exits).toEqual(['n3']);
  });

  it('fallback records a warning message', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B')],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    expect(chart.warnings.length).toBeGreaterThanOrEqual(1);
    expect(chart.warnings.some((w) => w.includes('[gen-skills]'))).toBe(true);
  });

  it('fallback does NOT fire when at least one terminal node exists', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    // No fallback warning
    expect(chart.warnings.every((w) => !w.includes('exits fallback'))).toBe(true);
    expect(chart.exits).toEqual(['n2']);
  });

  it('exits ids are all valid node ids in the chart', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt()), node(2, 'B', halt())],
      edges: [],
      sources: [],
    });
    const nodeIds = new Set(chart.nodes.map((n) => n.id));
    for (const id of chart.exits) {
      expect(nodeIds.has(id)).toBe(true);
    }
  });
});

// ── buildChart() — kind computation ─────────────────────────────────────────

describe('buildChart — kind precedence', () => {
  it("exit > entry: a node that is both in-degree-0 and terminal gets kind='exit'", () => {
    // Single node, in-degree-0 and has terminal
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'ONLY', halt())],
      edges: [],
      sources: [],
    });
    expect(chart.nodes[0].kind).toBe('exit');
  });

  it("entry: in-degree-0 non-exit node gets kind='entry'", () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'START'), node(2, 'END', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    expect(chart.nodes[0].kind).toBe('entry');
  });

  it("decision: node with 2+ outgoing branch edges gets kind='decision'", () => {
    // n2 must NOT be in-degree-0 (entry > decision in precedence), so give it
    // an incoming edge from n1 to make it a genuine mid-graph branching node.
    const branchEdge1 = makeEdge({ from: 'n2', to: 'n3', kind: 'branch', condition: 'if A', advanceType: 'CHAIN', provenance: PROV });
    const branchEdge2 = makeEdge({ from: 'n2', to: 'n4', kind: 'branch', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'START'), node(2, 'BRANCH'), node(3, 'A', halt()), node(4, 'B', halt())],
      edges: [edge('n1', 'n2'), branchEdge1, branchEdge2],
      sources: [],
    });
    // n2 has in-degree 1 so it's not in entries; it has 2 branch edges → decision
    expect(chart.nodes[1].kind).toBe('decision');
  });

  it("decision requires 2+ BRANCH edges: node with 1 branch + 1 sequence is 'step'", () => {
    // The near-miss node must have IN-DEGREE > 0. An earlier version of this test put
    // the single-branch node at order 1 with nothing pointing at it, so it landed in
    // `entries` and the precedence chain assigned `entry` BEFORE the decision check
    // ran. `not.toBe('decision')` then held whether the threshold was `>= 2` or
    // `>= 1`, so the criterion this test exists to guard was invisible to it — the
    // `>= 1` mutant survived the whole 80-test suite.
    //
    // Two changes make it bite: n2 is given an inbound edge so it actually reaches
    // the decision branch, and the assertion is the EXACT kind rather than a negation
    // — `not.toBe('decision')` is satisfied by four of the five kinds.
    const inbound = makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const oneBranch = makeEdge({ from: 'n2', to: 'n3', kind: 'branch', condition: 'if A', advanceType: 'CHAIN', provenance: PROV });
    const oneSequence = makeEdge({ from: 'n2', to: 'n4', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'START'), node(2, 'MAYBE'), node(3, 'A', halt()), node(4, 'B', halt())],
      edges: [inbound, oneBranch, oneSequence],
      sources: [],
    });
    const maybe = chart.nodes.find((n) => n.name === 'MAYBE');
    // Not an exit (no terminal), not an entry (in-degree 1), one branch edge only,
    // and sources no loop-back — so the chain must fall all the way through to 'step'.
    expect(maybe.kind).toBe('step');
  });

  it("loop-back: node that sources a loop-back edge (and is not exit/entry/decision) gets kind='loop-back'", () => {
    const loopEdge = makeEdge({ from: 'n2', to: 'n1', kind: 'loop-back', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const seqEdge = makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const exitEdge = makeEdge({ from: 'n2', to: 'n3', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'LOOPER'), node(3, 'C', halt())],
      edges: [seqEdge, loopEdge, exitEdge],
      sources: [],
    });
    expect(chart.nodes[1].kind).toBe('loop-back');
  });

  it("loop-back not assigned to node with only sequence self-edge (sequence != loop-back)", () => {
    // n2 has a sequence self-edge, but NO loop-back edge
    const selfSeq = makeEdge({ from: 'n2', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'SELF', halt())],
      edges: [edge('n1', 'n2'), selfSeq],
      sources: [],
    });
    // n2 is exit, not loop-back
    expect(chart.nodes[1].kind).toBe('exit');
  });

  it("step: default kind for a node with no special properties", () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'MIDDLE'), node(3, 'C', halt())],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: [],
    });
    expect(chart.nodes[1].kind).toBe('step');
  });

  it("a node with 1 sequence + 1 loop-back self-edge is loop-back, not decision", () => {
    // Mirrors aid-review's VERIFY: one sequence edge to PRESENT-FINDINGS,
    // one loop-back self-edge. kind should be 'loop-back', not 'decision',
    // because loop-back edges do not count toward the decision threshold.
    const seqEdge = makeEdge({ from: 'n2', to: 'n3', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const loopEdge = makeEdge({ from: 'n2', to: 'n1', kind: 'loop-back', condition: 'otherwise', advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'REVIEW'), node(2, 'VERIFY'), node(3, 'PRESENT', halt())],
      edges: [edge('n1', 'n2'), seqEdge, loopEdge],
      sources: [],
    });
    expect(chart.nodes[1].kind).toBe('loop-back');
  });
});

// ── buildChart() — edge ordering ─────────────────────────────────────────────

describe('buildChart — edge ordering', () => {
  it('edges are sorted by (from.order, to.order, condition)', () => {
    const e1 = makeEdge({ from: 'n2', to: 'n3', kind: 'branch', condition: 'z-condition', advanceType: 'CHAIN', provenance: PROV });
    const e2 = makeEdge({ from: 'n2', to: 'n3', kind: 'branch', condition: 'a-condition', advanceType: 'CHAIN', provenance: PROV });
    const e3 = makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C', halt())],
      edges: [e1, e2, e3],
      sources: [],
    });
    // Expected order: e3 (from n1), then e2 (from n2, cond a), then e1 (from n2, cond z)
    expect(chart.edges[0].from).toBe('n1');
    expect(chart.edges[1].condition).toBe('a-condition');
    expect(chart.edges[2].condition).toBe('z-condition');
  });

  it('null condition sorts before any string when from and to are identical', () => {
    // Two branch edges from n1 to n2 (same from, same to), different conditions.
    // null → '' which sorts before 'a' in the (from, to, condition) comparator.
    const e1 = makeEdge({ from: 'n1', to: 'n2', kind: 'branch', condition: 'a', advanceType: 'CHAIN', provenance: PROV });
    const e2 = makeEdge({ from: 'n1', to: 'n2', kind: 'branch', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [e1, e2],
      sources: [],
    });
    // null → '' < 'a', so e2 (null) should sort first
    expect(chart.edges[0].condition).toBeNull();
    expect(chart.edges[1].condition).toBe('a');
  });
});

// ── buildChart() — sources ────────────────────────────────────────────────────

describe('buildChart — sources', () => {
  it('sources are ASCII-sorted', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: ['canonical/skills/aid-test/references/z.md', 'canonical/skills/aid-test/SKILL.md'],
    });
    expect(chart.sources[0]).toBe('canonical/skills/aid-test/SKILL.md');
    expect(chart.sources[1]).toBe('canonical/skills/aid-test/references/z.md');
  });
});

// ── serializeChart() ─────────────────────────────────────────────────────────

describe('serializeChart — structure and format', () => {
  it('produces valid JSON parseable back to an equivalent object', () => {
    const chart = buildChart({
      skill: 'aid-example', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'START'), node(2, 'END', halt())],
      edges: [edge('n1', 'n2')],
      sources: ['canonical/skills/aid-example/SKILL.md'],
    });
    const json = serializeChart(chart);
    const parsed = JSON.parse(json);
    expect(parsed.skill).toBe('aid-example');
    expect(parsed.nodes).toHaveLength(2);
  });

  it('ends with exactly one trailing LF', () => {
    const chart = buildChart({
      skill: 'aid-example', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const json = serializeChart(chart);
    expect(json.endsWith('\n')).toBe(true);
    expect(json.endsWith('\n\n')).toBe(false);
  });

  it('uses LF line endings only (no CRLF)', () => {
    const chart = buildChart({
      skill: 'aid-example', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    expect(serializeChart(chart)).not.toContain('\r\n');
  });

  it('uses 2-space indentation', () => {
    const chart = buildChart({
      skill: 'aid-example', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const json = serializeChart(chart);
    // The "skill" key at the top level should be indented with exactly 2 spaces
    expect(json).toMatch(/^  "skill":/m);
  });

  it('two calls on the same chart produce identical output', () => {
    const chart = buildChart({
      skill: 'aid-example', shape: 'dispatch-table', extractor: 'extract-dispatch',
      confidence: 'derived',
      nodes: [node(1, 'START'), node(2, 'MIDDLE'), node(3, 'END', halt())],
      edges: [edge('n1', 'n2'), edge('n2', 'n3')],
      sources: ['canonical/skills/aid-example/SKILL.md'],
    });
    expect(serializeChart(chart)).toBe(serializeChart(chart));
  });

  it('top-level key order matches schema table order', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    const keys = Object.keys(parsed);
    const expected = ['skill', 'shape', 'extractor', 'confidence', 'title', 'nodes', 'edges', 'entries', 'exits', 'sources', 'warnings'];
    expect(keys).toEqual(expected);
  });

  it('node key order matches schema table order', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    const keys = Object.keys(parsed.nodes[0]);
    const expected = ['id', 'order', 'name', 'label', 'kind', 'terminal', 'provenance', 'detail'];
    expect(keys).toEqual(expected);
  });

  it('edge key order matches schema table order', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    const keys = Object.keys(parsed.edges[0]);
    const expected = ['from', 'to', 'kind', 'condition', 'advanceType', 'provenance'];
    expect(keys).toEqual(expected);
  });

  it('provenance key order matches schema', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    const keys = Object.keys(parsed.nodes[0].provenance);
    const expected = ['file', 'startLine', 'endLine', 'sourceKind', 'excerpt'];
    expect(keys).toEqual(expected);
  });

  it('terminal keys are normalized to schema order, whatever order the producer used', () => {
    // `terminal` was the one nested object passed through unnormalized, which left
    // AC-6 byte-identity resting on four independent producers — `advance.mjs` and
    // all three extractors — happening to write the literal in the same key order.
    // Building it BACKWARDS is the point of this fixture: it fails if the serializer
    // ever reverts to passing the caller's object straight through.
    const backwards = { handoff: 'Run /aid-define {work}', advanceType: 'PAUSE-FOR-USER-DECISION' };
    expect(Object.keys(backwards)).toEqual(['handoff', 'advanceType']); // fixture is genuinely reversed
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [makeNode({ order: 1, name: 'A', label: 'A', provenance: PROV, terminal: backwards })],
      edges: [],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    expect(Object.keys(parsed.nodes[0].terminal)).toEqual(['advanceType', 'handoff']);
    // …and the values survive the reordering.
    expect(parsed.nodes[0].terminal.advanceType).toBe('PAUSE-FOR-USER-DECISION');
    expect(parsed.nodes[0].terminal.handoff).toBe('Run /aid-define {work}');
  });

  it('a null terminal serializes as null, not as an empty object', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt()), makeNode({ order: 2, name: 'B', label: 'B', provenance: PROV })],
      edges: [makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV })],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    const b = parsed.nodes.find((n) => n.name === 'B');
    expect(b.terminal).toBeNull();
  });

  it('title field is "<skill> — state flow"', () => {
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    expect(parsed.title).toBe('aid-foo \u2014 state flow');
  });

  it('edges are sorted in the serialized output regardless of input order', () => {
    const e1 = makeEdge({ from: 'n2', to: 'n3', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const e2 = makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-foo', shape: 'residual', extractor: 'extract-residual',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C', halt())],
      edges: [e1, e2], // deliberately out of order
      sources: [],
    });
    const parsed = JSON.parse(serializeChart(chart));
    expect(parsed.edges[0].from).toBe('n1');
    expect(parsed.edges[1].from).toBe('n2');
  });
});

// ── splitFrontmatter() ───────────────────────────────────────────────────────

describe('splitFrontmatter', () => {
  it('splits at the closing --- fence', () => {
    const text = '---\nname: foo\ndesc: bar\n---\nBody text here.\n';
    const { fmLines, bodyLines, bodyStartLine } = splitFrontmatter(text, 'test.md');
    expect(fmLines).toHaveLength(4); // ---, name, desc, ---
    expect(bodyLines[0]).toBe('Body text here.');
    expect(bodyStartLine).toBe(5); // line 5 is 1-based
  });

  it('allLines contains every line of the file', () => {
    const text = '---\nname: foo\n---\nbody\n';
    const { allLines } = splitFrontmatter(text, 'test.md');
    expect(allLines).toHaveLength(5); // 4 lines + trailing empty from split
  });

  it('handles CRLF line endings transparently', () => {
    const text = '---\r\nname: foo\r\n---\r\nbody\r\n';
    const { bodyLines } = splitFrontmatter(text, 'test.md');
    expect(bodyLines[0]).toBe('body');
  });

  it('bodyStartLine is 1-based and correct', () => {
    // 3-line frontmatter: ---, name, --- → fence ends at index 2 (0-based)
    // body starts at index 3 (0-based) = line 4 (1-based)
    const text = '---\nname: foo\n---\nsome body\n';
    const { bodyStartLine } = splitFrontmatter(text, 'test.md');
    expect(bodyStartLine).toBe(4);
  });

  it('throws with [gen-skills] prefix and file:line on missing opening fence', () => {
    expect(() => splitFrontmatter('not a fence\n', 'canonical/skills/foo/SKILL.md'))
      .toThrow(/\[gen-skills\]/);
    expect(() => splitFrontmatter('not a fence\n', 'canonical/skills/foo/SKILL.md'))
      .toThrow(/canonical\/skills\/foo\/SKILL\.md:1/);
  });

  it('throws with [gen-skills] prefix and file:line on unterminated fence', () => {
    // The line-number half was missing here while its sibling above asserted it —
    // an asymmetry worth closing rather than tidying, because "the guard cites the
    // file but not the line" is the exact shape delivery-002 took two HIGH findings
    // for, in both cases with a test title that implied the line was checked.
    expect(() => splitFrontmatter('---\nname: foo\n', 'canonical/skills/foo/SKILL.md'))
      .toThrow(/\[gen-skills\]/);
    expect(() => splitFrontmatter('---\nname: foo\n', 'canonical/skills/foo/SKILL.md'))
      .toThrow(/canonical\/skills\/foo\/SKILL\.md:1/);
  });
});

// ── sliceLines() ─────────────────────────────────────────────────────────────

describe('sliceLines', () => {
  const lines = ['line1', 'line2', 'line3', 'line4', 'line5'];

  it('returns a single line when startLine === endLine', () => {
    expect(sliceLines(lines, 2, 2)).toBe('line2');
  });

  it('returns LF-joined content for a multi-line range', () => {
    expect(sliceLines(lines, 2, 4)).toBe('line2\nline3\nline4');
  });

  it('is 1-based (line 1 = index 0)', () => {
    expect(sliceLines(lines, 1, 1)).toBe('line1');
  });

  it('returns the last line correctly', () => {
    expect(sliceLines(lines, 5, 5)).toBe('line5');
  });
});

// ── buildProvenance() ────────────────────────────────────────────────────────

describe('buildProvenance', () => {
  it('excerpt equals the verbatim LF-joined slice of the named range', () => {
    const lines = ['---', 'name: foo', '---', '| A | B |', '| C | D |'];
    const p = buildProvenance('canonical/skills/aid-test/SKILL.md', lines, 4, 5, 'skill');
    expect(p.file).toBe('canonical/skills/aid-test/SKILL.md');
    expect(p.startLine).toBe(4);
    expect(p.endLine).toBe(5);
    expect(p.sourceKind).toBe('skill');
    expect(p.excerpt).toBe('| A | B |\n| C | D |');
  });

  it('excerpt satisfies the feature-005 equality check (excerpt === sliceLines(...))', () => {
    const lines = ['aaa', 'bbb', 'ccc'];
    const p = buildProvenance('canonical/skills/x/SKILL.md', lines, 2, 3, 'worker');
    expect(p.excerpt).toBe(sliceLines(lines, 2, 3));
  });
});

// ── findStateSections() ──────────────────────────────────────────────────────

describe('findStateSections — detection', () => {
  it('finds a single ## State: section', () => {
    const lines = [
      '---',
      'name: foo',
      '---',
      '',
      '## State: INTAKE',
      'Purpose: resolve the target.',
      '',
      '### Step 1',
      'Some text.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections).toHaveLength(1);
    expect(sections[0].name).toBe('INTAKE');
  });

  it('finds multiple ## State: sections in document order', () => {
    const lines = [
      '---', 'name: foo', '---',
      '## State: ALPHA',
      'First paragraph.',
      '',
      '## State: BETA',
      'Second paragraph.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections).toHaveLength(2);
    expect(sections[0].name).toBe('ALPHA');
    expect(sections[1].name).toBe('BETA');
  });

  it('strips trailing parenthetical from name', () => {
    const lines = [
      '---', 'name: foo', '---',
      '## State: VERIFY  (who reviews the reviewer)',
      'Some text.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].name).toBe('VERIFY');
  });

  it('does not match headings that are not ## State:', () => {
    const lines = [
      '---', 'name: foo', '---',
      '## Dispatch',
      '## State of the Union',
      '## State: VALID',
      '### State: NOT-LEVEL-2',
    ];
    const sections = findStateSections(lines, 'test.md');
    // Only '## State: VALID' matches (level 2, exactly State:)
    expect(sections).toHaveLength(1);
    expect(sections[0].name).toBe('VALID');
  });

  it('returns empty array when no ## State: sections exist', () => {
    const lines = ['---', 'name: foo', '---', '# Title', '## Dispatch', 'body'];
    expect(findStateSections(lines, 'test.md')).toHaveLength(0);
  });
});

describe('findStateSections — line ranges', () => {
  it('headingLine is the 1-based line of the ## State: heading', () => {
    // Lines: 0=---, 1=name:foo, 2=---, 3=empty, 4=## State: INTAKE (index 4 → 1-based 5)
    const lines = [
      '---',            // idx 0 → line 1
      'name: foo',      // idx 1 → line 2
      '---',            // idx 2 → line 3
      '',               // idx 3 → line 4
      '## State: INTAKE', // idx 4 → line 5
      'Some text.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].headingLine).toBe(5);
  });

  it('leadEndLine covers the heading + first paragraph block', () => {
    const lines = [
      '## State: A',   // idx 0 → line 1
      '',              // blank after heading (skip)
      'Lead line 1.',  // idx 2 → line 3
      'Lead line 2.',  // idx 3 → line 4
      '',              // blank (end of lead para)
      '### Step 1',
      'Details here.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].headingLine).toBe(1);
    expect(sections[0].leadEndLine).toBe(4); // heading + lead para 2 lines
  });

  it('leadEndLine = headingLine when no lead paragraph follows', () => {
    const lines = [
      '## State: EMPTY',
      '',
      '## State: NEXT',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].leadEndLine).toBe(1); // just the heading
  });

  it('sectionEndLine is the line before the next ## heading', () => {
    const lines = [
      '## State: A',   // idx 0 → line 1
      'Content A.',    // idx 1 → line 2
      '### Sub',       // idx 2 → line 3 — sub-heading, NOT a boundary
      'More A.',       // idx 3 → line 4
      '## State: B',   // idx 4 → line 5 — boundary; section A ends at line 4
      'Content B.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].sectionEndLine).toBe(4);
    expect(sections[0].name).toBe('A');
  });

  it('sectionEndLine excludes trailing blank lines before the next boundary', () => {
    // The trim loop in source.mjs had no fixture: every other sectionEndLine case
    // puts the boundary immediately after content, so deleting the loop left all 82
    // tests green. Blank lines before a heading are near-universal in real markdown,
    // so the untested path was the COMMON one — a state section ending with a blank
    // line would have reported that blank as its last line, and the provenance
    // excerpt would carry it.
    const lines = [
      '## State: A',   // line 1
      'Content A.',    // line 2 — the true last line of the section
      '',              // line 3 — belongs to the gap
      '   ',           // line 4 — whitespace-only also counts as blank
      '## State: B',   // line 5
      'Content B.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].sectionEndLine).toBe(2);
  });

  it('a section of nothing but blank lines collapses back to its heading line', () => {
    // Honest scope note, twice corrected, because the precise statement is subtle.
    //
    // This pins the BEHAVIOUR — an all-blank section reports its heading as its last
    // line — and here that behaviour comes from the trim loop's
    // `sectionEnd > headingLine` bound: sectionEnd walks 4 → 3 → 2 and stops because
    // `2 > 2` is false, without the inner blank-check ever looking at the heading.
    //
    // But the bound is not DISTINGUISHING, and no test can make it so. Mutate it to
    // `sectionEnd > 0` and all 84 tests still pass, because the heading matched
    // `## State:` to get here, so it is never blank and `.trim() === ''` would halt
    // the loop on it anyway. Both halves of the condition independently produce the
    // same answer for every input the function can receive.
    //
    // So the guard is kept and documented rather than deleted — it carries the intent
    // (never trim into the heading) at zero cost, and removing it would need a
    // `sectionEnd = 0` safety path that nothing exercises. What is deliberately NOT
    // done is writing a test that claims to cover it: that test could not fail, which
    // is the defect this suite has now been corrected for three times.
    const lines = [
      'intro',         // line 1
      '## State: EMPTY', // line 2
      '',              // line 3
      '',              // line 4
      '## State: NEXT',  // line 5
      'body',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].name).toBe('EMPTY');
    expect(sections[0].sectionEndLine).toBe(2);
  });

  it('sectionEndLine extends to end of file when no next ## heading or ---', () => {
    const lines = [
      '## State: LAST',
      'Content here.',
      'More content.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].sectionEndLine).toBe(3);
  });

  it('sectionEndLine respects --- as a boundary', () => {
    const lines = [
      '## State: A',
      'Body.',
      '---',
      'After rule.',
    ];
    const sections = findStateSections(lines, 'test.md');
    expect(sections[0].sectionEndLine).toBe(2); // before ---
  });

  it('sub-headings (###) do NOT end the section', () => {
    const lines = [
      '## State: A',
      'Top content.',
      '### Step 1',
      'Step content.',
      '#### Sub',
      'Sub content.',
      '## State: B',
      'B content.',
    ];
    const sections = findStateSections(lines, 'test.md');
    // Section A should extend through all sub-headings until ## State: B
    expect(sections[0].sectionEndLine).toBe(6);
  });
});

describe('findStateSections — excerpt via buildProvenance', () => {
  it('compact provenance excerpt matches the verbatim heading+lead range', () => {
    const lines = [
      '---',                    // 0
      'name: aid-review',       // 1
      '---',                    // 2
      '',                       // 3
      '## State: INTAKE',       // 4 → line 5
      '',                       // 5
      'Purpose: resolve.',      // 6 → line 7
      'More detail.',           // 7 → line 8
      '',                       // 8
      '### Step 1',             // 9
    ];
    const sections = findStateSections(lines, 'canonical/skills/aid-review/SKILL.md');
    const s = sections[0];
    // leadEndLine should be 8 (Purpose: resolve. + More detail.)
    const p = buildProvenance(
      'canonical/skills/aid-review/SKILL.md',
      lines,
      s.headingLine,
      s.leadEndLine,
      'skill'
    );
    // The excerpt should contain the heading and the lead paragraph
    expect(p.excerpt).toContain('## State: INTAKE');
    expect(p.excerpt).toContain('Purpose: resolve.');
    expect(p.excerpt).toContain('More detail.');
  });
});

// ── AC validation: every constructible chart has non-empty entries and exits ──

describe('AC-3 by construction', () => {
  it('entries is non-empty for a simple linear chart', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    expect(chart.entries.length).toBeGreaterThan(0);
  });

  it('exits is non-empty for a simple linear chart', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    expect(chart.exits.length).toBeGreaterThan(0);
  });

  it('entries is non-empty for a pure cycle (AC-3 by construction)', () => {
    // n1 → n2 → n3 → n1, no exits (fallback fires)
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3'), edge('n3', 'n1')],
      sources: [],
    });
    expect(chart.entries.length).toBeGreaterThan(0);
  });

  it('exits fallback records a [gen-skills] warning', () => {
    const chart = buildChart({
      skill: 'aid-no-exit', shape: 'residual', extractor: 'test',
      confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B'), node(3, 'C')],
      edges: [edge('n1', 'n2'), edge('n2', 'n3'), edge('n3', 'n1')],
      sources: [],
    });
    expect(chart.warnings.some((w) => w.startsWith('[gen-skills]'))).toBe(true);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// CONTRACT TIER — classify.mjs · advance.mjs · validate.mjs
// All fixtures are inline; no canonical/ file is read.
// ═══════════════════════════════════════════════════════════════════════════════

// ── truncate — 59-cp boundary (contract supplement) ──────────────────────────
// 60 cp (line 74) and 61 cp word-boundary (line 92) are already covered.
// This pins the specific off-by-one on the lower side.

describe('truncate — 59-cp boundary', () => {
  it('59 code points is within the 60-cp cap and returned unchanged', () => {
    const text = 'A'.repeat(59);
    // Non-vacuity: confirm the fixture is actually 59 cp.
    expect(Array.from(text).length).toBe(59);
    expect(truncate(text, 60)).toBe(text);
  });
});

// ── classifySkill — discriminator group ──────────────────────────────────────

/** Wrap a body string into the minimal skill object classifySkill expects. */
function skillBody(body) {
  return { name: 'aid-test', dir: 'canonical/skills/aid-test', frontmatter: {}, body };
}

describe('classifySkill — D1 dispatch-table', () => {
  it('classifies as dispatch-table when ## Dispatch heading has State+Advance table', () => {
    const body = [
      '## Dispatch',
      '',
      '| State | Advance |',
      '|-------|---------|',
      '| ALPHA | HALT |',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('dispatch-table');
    expect(result.evidence.some((e) => e.includes('D1'))).toBe(true);
    expect(result.delegatesTo).toBeNull();
  });

  it('classifies as dispatch-table when ## State Machine heading has State+Advance table', () => {
    const body = [
      '## State Machine',
      '',
      '| State | Advance |',
      '|-------|---------|',
      '| ALPHA | HALT |',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('dispatch-table');
    expect(result.evidence.some((e) => e.includes('State Machine'))).toBe(true);
  });

  it('does NOT classify as D1 when Dispatch heading table lacks the Advance column', () => {
    // Without an "Advance" column the table does not satisfy the D1 probe.
    const body = [
      '## Dispatch',
      '',
      '| State | Notes |',
      '|-------|-------|',
      '| ALPHA | some notes |',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).not.toBe('dispatch-table');
  });

  it('does NOT classify as D1 when heading text is a superset of "Dispatch"', () => {
    // D1_HEADING_RE requires the text is EXACTLY "Dispatch" or "State Machine".
    const body = [
      '## Dispatch Protocol',
      '',
      '| State | Advance |',
      '|-------|---------|',
      '| ALPHA | HALT |',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).not.toBe('dispatch-table');
  });
});

describe('classifySkill — D2 inline-states', () => {
  it('classifies as inline-states when two or more ## State: headings exist', () => {
    const body = [
      '## State: ALPHA',
      'First state content.',
      '',
      '## State: BETA',
      'Second state content.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('inline-states');
    expect(result.evidence.some((e) => e.includes('D2'))).toBe(true);
  });

  it('does NOT classify as D2 with only one ## State: heading (threshold is 2)', () => {
    // One heading is below the threshold; falls through to D5 residual.
    const body = '## State: ALPHA\nOnly one state, no second heading.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).not.toBe('inline-states');
  });
});

describe('classifySkill — D3 sibling-doorway', () => {
  it('classifies as sibling-doorway: "no logic of its own" + exactly one SKILL.md ref', () => {
    const body = [
      'This skill has no logic of its own.',
      'See canonical/skills/aid-base/SKILL.md for the full implementation.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('sibling-doorway');
    expect(result.delegatesTo).toBe('aid-base');
    expect(result.evidence.some((e) => e.includes('D3'))).toBe(true);
  });

  it('does NOT classify as D3 when two distinct SKILL.md targets are referenced', () => {
    // names.size === 2 → probe returns null.
    const body = [
      'This skill has no logic of its own.',
      'See canonical/skills/aid-alpha/SKILL.md and canonical/skills/aid-beta/SKILL.md.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).not.toBe('sibling-doorway');
  });

  it('does NOT classify as D3 when "no logic of its own" phrase is absent', () => {
    // The SKILL.md reference exists but the required phrase is missing.
    const body = 'See canonical/skills/aid-base/SKILL.md for details.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).not.toBe('sibling-doorway');
  });

  it('the SAME target referenced twice is ONE distinct reference — still D3', () => {
    // "exactly one reference" means one distinct *target*, not one occurrence — the
    // owner decision recorded for D3. The probe deduplicates through a Set, and nothing
    // exercised that: swapping the Set for an array left every other case green while
    // silently making a repeated target fail to classify.
    //
    // Separable from the two-distinct-targets case above: here the count of occurrences
    // is 2 and the count of distinct names is 1, so only deduplication can decide it.
    const body = [
      'This skill has no logic of its own.',
      'See canonical/skills/aid-base/SKILL.md for the full implementation.',
      'All behaviour is defined in canonical/skills/aid-base/SKILL.md.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('sibling-doorway');
    expect(result.delegatesTo).toBe('aid-base');
  });
});

describe('classifySkill — D4 engine-doorway', () => {
  it('classifies as engine-doorway via GENERATED-by-build-shortcut-skills.py comment', () => {
    const body = '<!-- GENERATED by build-shortcut-skills.py -->\nSome content.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('engine-doorway');
    expect(result.evidence.some((e) => e.includes('D4'))).toBe(true);
    expect(result.delegatesTo).toBeNull();
  });

  it('classifies as engine-doorway via shortcut-engine.md reference', () => {
    const body = 'Uses canonical/aid/templates/shortcut-engine.md as its template.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('engine-doorway');
    expect(result.evidence.some((e) => e.includes('D4'))).toBe(true);
  });
});

describe('classifySkill — D5 residual', () => {
  it('classifies as residual when no D1–D4 discriminator matches', () => {
    const body = 'This skill has plain prose content with no special markers.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('residual');
    expect(result.delegatesTo).toBeNull();
    expect(result.evidence.some((e) => e.includes('D5'))).toBe(true);
  });
});

describe('classifySkill — precedence D1 > D2 > D3 > D4 > D5', () => {
  it('D1 beats D2: aid-triage-shaped fixture carries ## State Machine + ## State: headings', () => {
    // The body simultaneously satisfies D1 (## State Machine with State+Advance table)
    // AND D2 (two ## State: headings). D1 must win because it fires first in the chain.
    // This is the "aid-triage-shaped fixture" required by the AC: a body that carries
    // a Dispatch table heading, a qualifying table, AND inline ## State: sections.
    const body = [
      '## State Machine',
      '',
      '| State | Advance |',
      '|-------|---------|',
      '| INTAKE | PROCESS HALT |',
      '| PROCESS | HALT |',
      '',
      '## State: INTAKE',
      'Intake state content.',
      '',
      '## State: PROCESS',
      'Process state content.',
    ].join('\n');
    // D1 fires: ## State Machine + State+Advance table.
    // D2 would also fire: two ## State: headings present.
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('dispatch-table');
  });

  it('D2 beats D3: two ## State: headings win over "no logic of its own" + SKILL.md ref', () => {
    const body = [
      'This skill has no logic of its own.',
      'See canonical/skills/aid-base/SKILL.md.',
      '',
      '## State: ALPHA',
      'State A.',
      '',
      '## State: BETA',
      'State B.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('inline-states');
  });

  it('D3 beats D4: sibling-doorway wins over shortcut-engine.md reference', () => {
    const body = [
      'This skill has no logic of its own.',
      'See canonical/skills/aid-base/SKILL.md.',
      'Uses canonical/aid/templates/shortcut-engine.md.',
    ].join('\n');
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('sibling-doorway');
  });

  it('D4 beats D5: engine-doorway beats residual when GENERATED comment is present', () => {
    const body = '<!-- GENERATED by build-shortcut-skills.py -->\nJust plain text.';
    const result = classifySkill(skillBody(body));
    expect(result.shape).toBe('engine-doorway');
  });
});

// ── parseAdvanceBlock — separator group ──────────────────────────────────────

/** States shared by all advance-parser fixtures. Uppercase names are exact-case
 *  tokens — the parser is case-sensitive for declared state matching. */
const ADV_STATES = [
  { name: 'ALPHA', order: 1, id: 'n1' },
  { name: 'BETA',  order: 2, id: 'n2' },
  { name: 'GAMMA', order: 3, id: 'n3' },
];

/** Call parseAdvanceBlock with fixture defaults. `fromNodeId` defaults to 'n0'
 *  (not in ADV_STATES) so rule-7 back-reference does not fire by default. */
function adv(block, states = ADV_STATES, fromNodeId = 'n0') {
  return parseAdvanceBlock({
    block,
    fromNodeId,
    fromNodeName: 'START',
    declaredStates: states,
    file: 'canonical/skills/aid-test/SKILL.md',
    blockStartLine: 1,
    sourceKind: 'skill',
  });
}

describe('parseAdvanceBlock — separators', () => {
  it('semicolon ";" splits one block into two edges', () => {
    const { edges } = adv('**Advance:** ALPHA; BETA');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('spaced slash " / " splits into two edges', () => {
    const { edges } = adv('**Advance:** ALPHA / BETA');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('unspaced slash "A/B" between declared state tokens splits into two edges', () => {
    // Both sides must be declared states; otherwise phase 2 rejects the cut.
    const { edges } = adv('**Advance:** ALPHA/BETA');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('" or " separator splits into two edges', () => {
    const { edges } = adv('**Advance:** ALPHA or BETA');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('"(or X)" parenthetical alternative produces two edges', () => {
    const { edges } = adv('**Advance:** ALPHA (or BETA)');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('sentence ". " boundary splits into two edges', () => {
    const { edges } = adv('**Advance:** ALPHA. BETA');
    expect(edges).toHaveLength(2);
    expect(edges.some((e) => e.to === 'n1')).toBe(true);
    expect(edges.some((e) => e.to === 'n2')).toBe(true);
  });

  it('" then " (lowercase) is recognised as a separator (one edge after rule 6 removes Y)', () => {
    // The lowercase " then " separator is detected in phase 1. After phase 2 splits
    // the block, rule 6 (unmarked arm) removes the Y clause edge, leaving one edge.
    // This pins that " then " IS in the separator set; the rule 6 tests in their own
    // group separately pin what each arm does.
    const { edges } = adv('**Advance:** ALPHA then BETA');
    expect(edges).toHaveLength(1);
    expect(edges[0].to).toBe('n1'); // ALPHA is kept; BETA edge removed by rule 6
  });
});

describe('parseAdvanceBlock — rule 4: terminal handling', () => {
  it('HALT keyword with no declared-state target → HALT terminal, zero edges', () => {
    const { edges, terminal } = adv('**Advance:** HALT', []);
    expect(edges).toHaveLength(0);
    expect(terminal).not.toBeNull();
    expect(terminal.advanceType).toBe('HALT');
  });

  it('lowercase "halt" also produces a HALT terminal', () => {
    const { edges, terminal } = adv('**Advance:** halt', []);
    expect(edges).toHaveLength(0);
    expect(terminal.advanceType).toBe('HALT');
  });

  it('"Stop here" produces a PAUSE-FOR-USER-ACTION terminal', () => {
    const { edges, terminal } = adv('**Advance:** Stop here', []);
    expect(edges).toHaveLength(0);
    expect(terminal.advanceType).toBe('PAUSE-FOR-USER-ACTION');
  });
});

describe('parseAdvanceBlock — rule 5: single conditional edge → self-loop', () => {
  it('one conditional branch edge triggers a loop-back self-edge with condition "otherwise"', () => {
    // "if approved BETA": single clause → edge to n2 (branch, condition='if approved').
    // Rule 5: edges.length===1, condition!==null, to!=='n0' → self-loop added.
    const { edges } = adv('**Advance:** if approved BETA');
    expect(edges).toHaveLength(2);
    const selfLoop = edges.find((e) => e.to === 'n0');
    expect(selfLoop).toBeDefined();
    expect(selfLoop.kind).toBe('loop-back');
    expect(selfLoop.condition).toBe('otherwise');
  });

  it('rule 5 does NOT fire when there are two or more edges', () => {
    // Two unconditional edges → rule 5 guard (edges.length===1) fails.
    const { edges } = adv('**Advance:** ALPHA; BETA');
    expect(edges.every((e) => e.to !== 'n0')).toBe(true);
    expect(edges).toHaveLength(2);
  });

  it('rule 5 does NOT fire when the single edge is unconditional', () => {
    // One clause, no condition → `condition !== null` is false → no self-loop.
    const { edges } = adv('**Advance:** ALPHA');
    expect(edges).toHaveLength(1);
    expect(edges[0].condition).toBeNull();
  });
});

describe('parseAdvanceBlock — rule 6: " then " separator, marked and unmarked arms', () => {
  it('unmarked "then": keeps X as sequence edge, removes Y, emits W-1 warning', () => {
    // No optionality marker on ALPHA → unmarked arm:
    //   - ALPHA edge kept (sequence)
    //   - BETA edge removed; BETA exempt from V9
    //   - W-1 warning pushed
    const { edges, warnings } = adv('**Advance:** ALPHA then BETA');
    expect(edges).toHaveLength(1);
    expect(edges[0].to).toBe('n1');
    expect(edges[0].kind).toBe('sequence');
    expect(warnings.length).toBeGreaterThan(0);
    expect(warnings.some((w) => w.includes('then'))).toBe(true);
  });

  it('marked "then" with (optional): X becomes branch(condition=marker), Y becomes branch(null)', () => {
    // "ALPHA (optional) then BETA": optionality marker detected on X.
    // Marked arm: X → branch('optional'), Y → branch(null).
    const { edges } = adv('**Advance:** ALPHA (optional) then BETA');
    expect(edges).toHaveLength(2);
    const xEdge = edges.find((e) => e.to === 'n1');
    const yEdge = edges.find((e) => e.to === 'n2');
    expect(xEdge).toBeDefined();
    expect(xEdge.kind).toBe('branch');
    expect(xEdge.condition).toBe('optional');
    expect(yEdge).toBeDefined();
    expect(yEdge.kind).toBe('branch');
    expect(yEdge.condition).toBeNull();
  });
});

describe('parseAdvanceBlock — rule 7: back-reference → loop-back kind', () => {
  it('an edge targeting a lower-order declared state is assigned kind "loop-back"', () => {
    // FROM: BETA (order=2, id=n2). TARGET: ALPHA (order=1 < 2) → rule 7 assigns loop-back.
    const { edges } = adv('**Advance:** ALPHA', ADV_STATES, 'n2');
    expect(edges).toHaveLength(1);
    expect(edges[0].to).toBe('n1');
    expect(edges[0].kind).toBe('loop-back');
  });

  it('an edge targeting a higher-order state is NOT assigned loop-back', () => {
    // FROM: ALPHA (order=1, id=n1). TARGET: BETA (order=2 > 1) → sequence unchanged.
    const { edges } = adv('**Advance:** BETA', ADV_STATES, 'n1');
    expect(edges).toHaveLength(1);
    expect(edges[0].to).toBe('n2');
    expect(edges[0].kind).toBe('sequence');
  });
});

describe('parseAdvanceBlock — rule 9: pause-resume edge → terminal', () => {
  it('PAUSE-FOR-USER-DECISION targeting a declared state → terminal, zero edges', () => {
    // Edge to ALPHA is emitted by rules 2-4, then consumed by rule 9.
    const { edges, terminal } = adv('**Advance:** PAUSE-FOR-USER-DECISION ALPHA');
    expect(edges).toHaveLength(0);
    expect(terminal).not.toBeNull();
    expect(terminal.advanceType).toBe('PAUSE-FOR-USER-DECISION');
    expect(terminal.handoff).toBe('ALPHA');
  });

  it('PAUSE-FOR-USER-ACTION targeting a declared state → terminal with that state as handoff', () => {
    const { edges, terminal } = adv('**Advance:** PAUSE-FOR-USER-ACTION BETA');
    expect(edges).toHaveLength(0);
    expect(terminal.advanceType).toBe('PAUSE-FOR-USER-ACTION');
    expect(terminal.handoff).toBe('BETA');
  });
});

// ── V9 — enforced in advance.mjs at edge-emission time, not in validateChart ─

describe('parseAdvanceBlock — rule 10: W-1 residual warning (warn, never throw)', () => {
  // Rule 10 has two halves against the same residue: W-1 warns, V9 throws. The V9 half
  // is below. This half was recorded as possibly-unreachable and left OPEN in the
  // delivery STATE — six candidate inputs were measured and none produced a residual
  // W-1, because for a single-clause block the clause IS the whole content, so residue
  // is necessarily empty.
  //
  // The reachable shape turned out to be a MULTI-outcome block in which one outcome is
  // dropped: the dropped span is not covered by any accepted clause, so it becomes
  // residue. `aid-update-kb`'s REVIEW row is the live instance. That closes the open
  // question with an input rather than with a declaration of unreachability.
  const STATES = [
    { name: 'APPLY', order: 1, id: 'n1' },
    { name: 'APPROVAL', order: 2, id: 'n2' },
  ];

  it('a dropped outcome leaves residue and emits a W-1 naming it — without throwing', () => {
    const r = adv(
      '**Advance:** incomplete APPLY -> CHAIN -> APPLY; ' +
      'grade below gate -> CHAIN -> UNDECLARED; READY -> CHAIN -> APPROVAL',
      STATES
    );

    // Warns, never throws — that is rule 10's W-1 half, and FR-2's boundary.
    const w1 = r.warnings.filter((w) => /W-1/.test(w));
    expect(w1).toHaveLength(1);
    // Content, not just presence: the tag, the source node, file:line, and the residue.
    expect(w1[0]).toContain('W-1');
    expect(w1[0]).toContain("'START'");
    expect(w1[0]).toContain('canonical/skills/aid-test/SKILL.md:1');
    expect(w1[0]).toContain('grade below gate');

    // The surviving outcomes are unaffected, which is what makes the residue a residue
    // rather than a parse failure.
    expect(r.edges.map((e) => e.to).sort()).toEqual(['n1', 'n2']);
  });

  it('no residue means no W-1 — the warning is not emitted unconditionally', () => {
    // Separability for the residue condition: same two-clause shape, both outcomes
    // resolvable, so nothing is dropped and nothing is left over.
    const r = adv('**Advance:** incomplete APPLY -> CHAIN -> APPLY; READY -> CHAIN -> APPROVAL', STATES);
    expect(r.warnings.filter((w) => /W-1/.test(w))).toEqual([]);
    expect(r.edges).toHaveLength(2);
  });

  // Rule 8 is deliberately NOT tested here. Its guard
  // (`if (edge.kind === 're-entry') continue;` inside rule 7) is structurally dead in
  // this module: `advance.mjs` never assigns kind 're-entry', so no input to
  // parseAdvanceBlock can reach it. Rule 8 emits re-entry edges from a *heading*, which
  // is an extractor's job, so the criterion is discharged in
  // `flow-extract-dispatch.test.mjs` — see its "re-entry kind takes precedence over
  // loop-back" case. Writing a rule-8 test here would be a test that cannot fail, which
  // is the defect this delivery keeps producing. Recorded in the delivery STATE.
});

describe('V9 (advance.mjs): throw on unconsumed declared state', () => {
  it('throws carrying "V9" when a declared state appears in advance text but is not an edge target', () => {
    // KI-008 scenario: THEN (uppercase) is not the " then " separator.
    // Phase 1 finds no separator. Clause "DELIVER THEN DONE" resolves to DELIVER.
    // DONE is declared, case-exact in the text, not an edge target → V9 throws.
    const states = [
      { name: 'DELIVER', order: 1, id: 'n1' },
      { name: 'DONE',    order: 2, id: 'n2' },
    ];
    expect(() =>
      parseAdvanceBlock({
        block: '**Advance:** DELIVER THEN DONE',
        fromNodeId: 'n0',
        fromNodeName: 'START',
        declaredStates: states,
        file: 'canonical/skills/aid-test/SKILL.md',
        blockStartLine: 1,
      })
    ).toThrow(/V9/);
  });

  it('V9 throw message cites the unconsumed state by name (KI-008 fingerprint)', () => {
    const states = [
      { name: 'DELIVER', order: 1, id: 'n1' },
      { name: 'DONE',    order: 2, id: 'n2' },
    ];
    expect(() =>
      parseAdvanceBlock({
        block: '**Advance:** DELIVER THEN DONE',
        fromNodeId: 'n0',
        fromNodeName: 'START',
        declaredStates: states,
        file: 'canonical/skills/aid-test/SKILL.md',
        blockStartLine: 1,
      })
    ).toThrow(/DONE/);
  });

  it('V9 does NOT throw when all declared state references are emitted as edge targets', () => {
    // Both ALPHA and BETA are consumed by edges; V9 scan finds nothing unaccounted for.
    const states = [
      { name: 'ALPHA', order: 1, id: 'n1' },
      { name: 'BETA',  order: 2, id: 'n2' },
    ];
    expect(() =>
      parseAdvanceBlock({
        block: '**Advance:** ALPHA; BETA',
        fromNodeId: 'n0',
        fromNodeName: 'START',
        declaredStates: states,
        file: 'canonical/skills/aid-test/SKILL.md',
        blockStartLine: 1,
      })
    ).not.toThrow();
  });

  it('V9 does NOT throw when the state appears only as the pause-resume handoff', () => {
    // ALPHA is consumed into terminal.handoff, not edgeTargetIds.
    // V9 skips it via the handoffName comparison.
    const states = [{ name: 'ALPHA', order: 1, id: 'n1' }];
    expect(() =>
      parseAdvanceBlock({
        block: '**Advance:** PAUSE-FOR-USER-DECISION ALPHA',
        fromNodeId: 'n0',
        fromNodeName: 'START',
        declaredStates: states,
        file: 'canonical/skills/aid-test/SKILL.md',
        blockStartLine: 1,
      })
    ).not.toThrow();
  });

  it('V9 does NOT throw when the tail of an unmarked " then " clause is exempt', () => {
    // "ALPHA then BETA" unmarked → rule 6 removes the BETA edge AND adds n2 to v9Exempt.
    // V9 then skips BETA; no throw.
    const states = [
      { name: 'ALPHA', order: 1, id: 'n1' },
      { name: 'BETA',  order: 2, id: 'n2' },
    ];
    expect(() =>
      parseAdvanceBlock({
        block: '**Advance:** ALPHA then BETA',
        fromNodeId: 'n0',
        fromNodeName: 'START',
        declaredStates: states,
        file: 'canonical/skills/aid-test/SKILL.md',
        blockStartLine: 1,
      })
    ).not.toThrow();
  });
});

// ── validateChart — V1–V8 isolation ──────────────────────────────────────────
// Each test fails exactly ONE V-rule.  Confirmed by: (a) asserting that rule's
// error string appears in `errors`, and (b) asserting ALL errors mention only
// that rule — a test that also catches a second rule firing.

describe('validateChart — V1: nodes non-empty; ids unique and charset-valid', () => {
  it('V1 fires (only) for a node id that violates the charset (starts with digit)', () => {
    // '1invalid' starts with a digit → fails ^[A-Za-z][A-Za-z0-9_]{0,31}$.
    // entries/exits use that same id → nodeIds contains it → V2, V3 pass.
    // V6: '1invalid' is in entries; adj walk → it is reachable. Passes.
    // V7: PROV is valid. V8: label 'A' ≤ 60 cp. ONLY V1 fires.
    const rawChart = {
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate', title: 'aid-test \u2014 state flow',
      nodes: [{
        id: '1invalid', order: 1, name: 'A', label: 'A',
        kind: 'exit', terminal: halt(), provenance: PROV, detail: null,
      }],
      edges: [],
      entries: ['1invalid'],
      exits: ['1invalid'],
      sources: [], warnings: [],
    };
    const { ok, errors } = validateChart(rawChart);
    expect(ok).toBe(false);
    expect(errors.some((e) => /V1/.test(e))).toBe(true);
    expect(errors.every((e) => /V1/.test(e))).toBe(true);
  });

  it('V1 fires for duplicate node ids', () => {
    // Two nodes share id 'n1'. entries/exits both point to 'n1' → present in nodeIds → V2/V3 pass.
    // V6: n1 in entries → reachable. V7, V8 pass. Only V1 fires.
    const rawChart = {
      skill: 'aid-test', shape: 'residual', extractor: 'test',
      confidence: 'approximate', title: 'aid-test \u2014 state flow',
      nodes: [
        { id: 'n1', order: 1, name: 'A', label: 'A', kind: 'entry', terminal: null,  provenance: PROV, detail: null },
        { id: 'n1', order: 2, name: 'B', label: 'B', kind: 'exit',  terminal: halt(), provenance: PROV, detail: null },
      ],
      edges: [], entries: ['n1'], exits: ['n1'], sources: [], warnings: [],
    };
    const { errors } = validateChart(rawChart);
    expect(errors.some((e) => /V1/.test(e) && /duplicate/.test(e))).toBe(true);
  });
});

describe('validateChart — V1: nodes non-empty (the condition before the id checks)', () => {
  it('V1 fires when nodes is EMPTY, with only the structurally forced companions', () => {
    // V1's id-uniqueness and charset checks live in its `else` branch, so no test that
    // reaches them can also reach this one. Like V2's empty case, an empty chart cannot
    // fail V1 alone: with no nodes there is no valid entry or exit id and nothing is
    // reachable, so V2, V3 and V6 are forced companions. Pinned rather than skipped.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const { errors } = validateChart({ ...chart, nodes: [] });
    expect(errors.some((e) => /V1: nodes is empty/.test(e))).toBe(true);
    expect(errors.every((e) => /V1|V2|V3|V6/.test(e))).toBe(true);
  });
});

describe('validateChart — V2: entries non-empty; every entry id is a node id', () => {
  it('V2 fires (only) when entries contains an id not present in nodes', () => {
    // entries=['n1','ghost']: 'n1' is valid (V2 passes for it), 'ghost' is not (V2 fires).
    // V6: queue starts with n1 (ghost filtered by nodeIds); n2 reachable via edge. Passes.
    // V3: exits=['n2'] → valid. ONLY V2 fires.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const { errors } = validateChart({ ...chart, entries: ['n1', 'ghost'] });
    expect(errors.some((e) => /V2/.test(e))).toBe(true);
    expect(errors.every((e) => /V2/.test(e))).toBe(true);
  });

  it('V2 also fires when entries is EMPTY — its other half', () => {
    // V2 has two independent conditions and the case above only reaches the second.
    // Neutralising the emptiness check killed nothing until this test existed.
    //
    // Empty entries cannot fail V2 *alone*: with no entry, V6 finds no node reachable,
    // so it necessarily co-fires. That is a structural fact about the rule set, not a
    // reason to leave the condition unpinned — so this asserts V2 fires, names V6 as the
    // expected companion, and pins that nothing else joins them.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const { errors } = validateChart({ ...chart, entries: [] });
    expect(errors.some((e) => /V2: entries is empty/.test(e))).toBe(true);
    expect(errors.every((e) => /V2|V6/.test(e))).toBe(true);
  });
});

describe('validateChart — V3: exits non-empty; every exit id is a node id', () => {
  it('V3 fires (only) when exits contains an id not present in nodes', () => {
    // exits=['n2','ghost']: 'n2' valid, 'ghost' is not → V3 fires.
    // V2: entries=['n1'] valid. V6: reachable. ONLY V3 fires.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const { errors } = validateChart({ ...chart, exits: ['n2', 'ghost'] });
    expect(errors.some((e) => /V3/.test(e))).toBe(true);
    expect(errors.every((e) => /V3/.test(e))).toBe(true);
  });

  it('V3 also fires when exits is EMPTY — its other half, and alone', () => {
    // As with V2, the case above only reaches the second condition. Unlike V2's empty
    // case, this one genuinely fails V3 alone: no other rule reads `exits`.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const { errors } = validateChart({ ...chart, exits: [] });
    expect(errors.some((e) => /V3: exits is empty/.test(e))).toBe(true);
    expect(errors.every((e) => /V3/.test(e))).toBe(true);
  });
});

describe('validateChart — V4: no dangling edges', () => {
  it('V4 fires (only) when an edge.to is not a node id', () => {
    // n1 is the only node (entry + exit via terminal). Edge n1→'ghost' is dangling.
    // V5: one edge, no duplicate. V6: V4-invalid edges are skipped in adj construction;
    //     n1 reachable from its own entry. ONLY V4 fires.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const danglingEdge = makeEdge({
      from: 'n1', to: 'ghost', kind: 'sequence',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const { errors } = validateChart({ ...chart, edges: [danglingEdge] });
    // Names the offending endpoint, not merely the rule — a bare /V4/ would also match
    // the `from` half's message, so it could not tell the two halves apart.
    expect(errors.some((e) => /V4: edge\.to 'ghost'/.test(e))).toBe(true);
    expect(errors.every((e) => /V4/.test(e))).toBe(true);
  });

  it('V4 also fires when an edge.FROM is not a node id — its other half', () => {
    // V4 checks both endpoints independently, and the case above only reaches `to`.
    // Disabling the `from` half killed nothing until this test existed.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const danglingFrom = makeEdge({
      from: 'ghost', to: 'n1', kind: 'sequence',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const { errors } = validateChart({ ...chart, edges: [danglingFrom] });
    expect(errors.some((e) => /V4: edge\.from 'ghost'/.test(e))).toBe(true);
    expect(errors.every((e) => /V4/.test(e))).toBe(true);
  });
});

describe('validateChart — V5: no duplicate (from, to, condition) triple', () => {
  it('V5 fires (only) when two edges share the same (from, to, condition) triple', () => {
    // Two identical n1→n2 sequence edges with condition=null.
    // V4: both endpoints are valid node ids. V6: n2 reachable via (either) edge. ONLY V5.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [edge('n1', 'n2')],
      sources: [],
    });
    const dup = makeEdge({ from: 'n1', to: 'n2', kind: 'sequence', condition: null, advanceType: 'CHAIN', provenance: PROV });
    const { errors } = validateChart({ ...chart, edges: [chart.edges[0], dup] });
    expect(errors.some((e) => /V5/.test(e))).toBe(true);
    expect(errors.every((e) => /V5/.test(e))).toBe(true);
  });

  it('two edges with the same (from, to) but different conditions do NOT trigger V5', () => {
    // Different condition strings → different keys in tripleSeen → no duplicate.
    const e1 = makeEdge({ from: 'n1', to: 'n2', kind: 'branch', condition: 'if A', advanceType: 'CHAIN', provenance: PROV });
    const e2 = makeEdge({ from: 'n1', to: 'n2', kind: 'branch', condition: 'if B', advanceType: 'CHAIN', provenance: PROV });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt())],
      edges: [e1, e2],
      sources: [],
    });
    const { errors } = validateChart(chart);
    expect(errors.some((e) => /V5/.test(e))).toBe(false);
  });
});

describe('validateChart — V6: every node reachable from entries', () => {
  it('V6 fires (only) for a node that is not reachable from any entry', () => {
    // Strategy: build the chart normally, then override `entries` in the raw object
    // passed to validateChart so n3 is not an entry.
    //
    // buildChart computes a synthetic entry for n3 (its own self-loop makes it a
    // cycle component with no real in-degree-0 node), keeping V6 from firing on the
    // built chart. By overriding to entries=['n1'] we give validateChart a structurally
    // coherent chart where n3 is genuinely unreachable from the declared entry set —
    // the scenario V6 exists to detect.
    //
    // V4: both n3→n3 and n1→n2 have valid node endpoints. Passes.
    // V5: no duplicate triples. Passes.
    // V7: all nodes use PROV (valid canonical/ file, line range, excerpt). Passes.
    // V8: all labels short. Passes.
    // V2: 'n1' in nodeIds. Passes. V3: exits=['n2']. Passes. ONLY V6 fires.
    const selfLoopEdge = makeEdge({
      from: 'n3', to: 'n3', kind: 'loop-back',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A'), node(2, 'B', halt()), node(3, 'C')],
      edges: [edge('n1', 'n2'), selfLoopEdge],
      sources: [],
    });
    // Override entries: remove the synthetic n3 entry so validateChart sees n3 as unreachable.
    const { errors } = validateChart({ ...chart, entries: ['n1'] });
    expect(errors.some((e) => /V6/.test(e))).toBe(true);
    expect(errors.every((e) => /V6/.test(e))).toBe(true);
  });
});

describe('validateChart — V7: provenance well-formed', () => {
  it('V7 fires (only) when provenance.file is not under canonical/', () => {
    // Local path fails the startsWith('canonical/') guard.
    // startLine=1, endLine=1, excerpt='| test |' (1 line → span matches) → no range error.
    // V8: label 'A' ≤ 60 cp. ONLY V7 fires.
    const badProv = makeProvenance({
      file: 'local/skills/aid-test/SKILL.md',
      startLine: 1, endLine: 1, sourceKind: 'skill', excerpt: '| test |',
    });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [makeNode({ order: 1, name: 'A', label: 'A', provenance: badProv, terminal: halt() })],
      edges: [],
      sources: [],
    });
    const { errors } = validateChart(chart);
    expect(errors.some((e) => /V7/.test(e))).toBe(true);
    expect(errors.every((e) => /V7/.test(e))).toBe(true);
  });

  it('V7 also fires on an out-of-range line pair the excerpt check cannot catch', () => {
    // V7's numeric guards (`Number.isFinite`, `startLine < 1`, `endLine < startLine`) are
    // separate from its excerpt-span check, and disabling all four killed nothing:
    // startLine=0/endLine=0 with a one-line excerpt has span 1 and passes the span
    // check, so only the range guard can reject it. Built by hand because the provenance
    // has to reach the validator with that pair intact — makeProvenance does not validate,
    // so this is about controlling the value, not about evading a rejection.
    //
    // Note the guard's other three arms are *subsumed* by the span check and cannot be
    // isolated: a NaN line number makes the expected span NaN, and `endLine < startLine`
    // makes it zero or negative, so in both cases the span mismatch fires first. Only the
    // `startLine < 1` arm has an input that reaches it alone, and this is that input.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const badRange = {
      ...chart.nodes[0].provenance,
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: 0,
      endLine: 0,
      excerpt: 'X',
    };
    const { errors } = validateChart({
      ...chart,
      nodes: [{ ...chart.nodes[0], provenance: badRange }],
    });
    expect(errors.some((e) => /V7: .*invalid line range startLine=0/.test(e))).toBe(true);
    expect(errors.every((e) => /V7/.test(e))).toBe(true);
  });

  it('V7 also fires when a node has NO provenance at all — its first condition', () => {
    // The two cases below reach V7's file and span checks; neither reaches the guard
    // that runs before them, and disabling that guard killed nothing until now.
    // Built by hand rather than through makeNode, which requires a provenance — the
    // point is a chart that reached the validator without one.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const stripped = { ...chart, nodes: [{ ...chart.nodes[0], provenance: null }] };
    const { errors } = validateChart(stripped);
    expect(errors.some((e) => /V7: node 'n1' \('A'\) has no provenance/.test(e))).toBe(true);
    expect(errors.every((e) => /V7/.test(e))).toBe(true);
  });

  it('V7 fires (only) when excerpt line count mismatches the startLine–endLine span', () => {
    // startLine=1, endLine=3 → expects 3 lines. 'single line only' has 1 → V7 fires.
    // file is under canonical/ → file check passes. ONLY V7 fires.
    const mismatchProv = makeProvenance({
      file: 'canonical/skills/aid-test/SKILL.md',
      startLine: 1, endLine: 3, sourceKind: 'skill', excerpt: 'single line only',
    });
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [makeNode({ order: 1, name: 'A', label: 'A', provenance: mismatchProv, terminal: halt() })],
      edges: [],
      sources: [],
    });
    const { errors } = validateChart(chart);
    expect(errors.some((e) => /V7/.test(e))).toBe(true);
    expect(errors.every((e) => /V7/.test(e))).toBe(true);
  });
});

describe('validateChart — V8: label ≤ 60 Unicode code points', () => {
  it('V8 fires (only) for a label that is 61 code points (one over the cap)', () => {
    // 61 ASCII chars → 61 code points. Limit is 60. V8 fires.
    // PROV is valid → V7 passes. id 'n1' valid → V1 passes. ONLY V8 fires.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [makeNode({ order: 1, name: 'A', label: 'A'.repeat(61), provenance: PROV, terminal: halt() })],
      edges: [],
      sources: [],
    });
    const { ok, errors } = validateChart(chart);
    expect(ok).toBe(false);
    expect(errors.some((e) => /V8/.test(e))).toBe(true);
    expect(errors.every((e) => /V8/.test(e))).toBe(true);
  });

  it('V8 passes for a label of exactly 60 code points (at the cap)', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [makeNode({ order: 1, name: 'A', label: 'A'.repeat(60), provenance: PROV, terminal: halt() })],
      edges: [],
      sources: [],
    });
    const { ok } = validateChart(chart);
    expect(ok).toBe(true);
  });

  it('V8 also fires for an EMPTY label — the non-empty half of the same rule', () => {
    // V8 is "non-empty AND ≤ 60 code points". The over-cap case above reaches only the
    // length half, so removing `|| label === ''` left a validator that silently accepted
    // an empty label — and an empty label is what killed pages earlier in this delivery
    // (extract-residual's nameless-token defect), so the branch is not academic.
    //
    // Built by hand rather than through makeNode — not because makeNode rejects an empty
    // label (it does not validate at all), but because the label has to survive into the
    // chart unchanged, and going through buildChart first then overriding is the shortest
    // way to get an otherwise-valid chart carrying one.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const { errors } = validateChart({
      ...chart,
      nodes: [{ ...chart.nodes[0], label: '' }],
    });
    expect(errors.some((e) => /V8: node 'n1' \('A'\) has empty label/.test(e))).toBe(true);
    expect(errors.every((e) => /V8/.test(e))).toBe(true);
  });

  it('V8 fires for a non-string label too — the same guard, other arm', () => {
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'A', halt())],
      edges: [],
      sources: [],
    });
    const { errors } = validateChart({
      ...chart,
      nodes: [{ ...chart.nodes[0], label: null }],
    });
    expect(errors.some((e) => /V8: .*has empty label/.test(e))).toBe(true);
    // Isolation, as in the empty-string case: nothing else may fire, or a future rule
    // that starts rejecting a null label would be indistinguishable from this one.
    expect(errors.every((e) => /V8/.test(e))).toBe(true);
  });
});

// ── validateChart — exactly V1–V8; V9 is NOT implemented here ────────────────

describe('validateChart — boundary: V1–V8 only; V9 lives in advance.mjs', () => {
  it('a chart structurally valid under V1-V8 passes cleanly even for a V9 scenario', () => {
    // Two isolated terminal nodes (both entries, both exits, no edges).
    // This represents the chart that could result from a parse where DONE appeared
    // in DELIVER's advance text but was not emitted as an edge — exactly the KI-008
    // scenario. validateChart cannot see the advance text, so it passes V1-V8 cleanly.
    // V9 would have fired at parse time in advance.mjs. This test is the positive
    // statement that the V1-V8 boundary is where the rule is intentionally drawn.
    const chart = buildChart({
      skill: 'aid-test', shape: 'residual', extractor: 'test', confidence: 'approximate',
      nodes: [node(1, 'DELIVER', halt()), node(2, 'DONE', halt())],
      edges: [],
      sources: [],
    });
    const { ok, errors } = validateChart(chart);
    expect(ok).toBe(true);
    expect(errors).toHaveLength(0);
  });
});
