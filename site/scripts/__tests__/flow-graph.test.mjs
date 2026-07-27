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
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
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

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');

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
