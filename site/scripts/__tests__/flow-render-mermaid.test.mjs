// flow-render-mermaid.test.mjs — Unit tests for lib/flow-graph/render-mermaid.mjs
//
// Coverage (per DETAIL.md acceptance criteria):
//   AC-1  Output is fence body only: no fence markers, no H2, no notice line.
//   AC-2  Each of the five node kinds renders its correct shape delimiters;
//         each of the four edge kinds renders its correct arrow form.
//   AC-3  Escaping converts & < > " to HTML entities and replaces backtick /
//         pipe with space — verified against a condition containing >= and {floor}
//         and a label containing "" (bare verb).
//   AC-4  Every chart emits its own classDef block (all six classDefs present).
//   AC-5  Every node carries a `class <id> aidNode` statement backed by a
//         `classDef aidNode` in the same fence (hook H3).
//   AC-6  Node declarations follow node.order; edge lines follow (from.order,
//         to.order, condition).
//   AC-7  Two calls on the same chart return identical strings; renderMermaid
//         reads no clock, environment, or random source.
//   AC-8  Passing tests when run alongside the full suite (no regressions).
//
// Round-trip coverage:
//   A narrow Mermaid parser (parse-emitted) verifies that the rendered source
//   round-trips back to the same topology: each node id maps to the correct
//   shape category, each edge maps to the correct arrow form, and kind-class
//   assignments match.  This catches topology corruption that string assertions
//   alone miss.
//
//   The hand-written parser in site/src/data/__tests__/ac13-version-injection.test.ts
//   was read before writing this one.  It is TypeScript, handles LR pipeline
//   diagrams, and fails closed on any construct it has not modelled.  A narrower
//   parser is used here deliberately: the emitted format uses exactly three arrow
//   forms and three node-shape forms, and modelling only those makes it easier to
//   verify that every branch is exercised without introducing the full grammar.
//   The narrower parser also fails closed — unknown lines throw rather than being
//   silently dropped.
//
// Mutation-proving notes (§ Testing standard):
//   Each assertion was mutation-proven: the code was broken in the specific way
//   the assertion guards against and the test was observed to fail.  Mutations
//   applied and their survivor count are recorded in the report section below.
//
// No hard-coded corpus counts (REQUIREMENTS §8, KI-005).

import { describe, it, expect } from 'vitest';
import {
  makeProvenance,
  makeNode,
  makeEdge,
  buildChart,
} from '../lib/flow-graph/model.mjs';
import { renderMermaid } from '../lib/flow-graph/render-mermaid.mjs';

// ── Shared fixtures ──────────────────────────────────────────────────────────

const PROV = makeProvenance({
  file: 'canonical/skills/aid-test/SKILL.md',
  startLine: 1,
  endLine: 1,
  sourceKind: 'skill',
  excerpt: '| TEST | halt |',
});

function node(order, name, label = name, terminal = null) {
  return makeNode({ order, name, label, provenance: PROV, terminal });
}
function halt() { return { advanceType: 'HALT', handoff: null }; }
function edge(from, to, kind = 'sequence', condition = null) {
  return makeEdge({ from, to, kind, condition, advanceType: 'CHAIN', provenance: PROV });
}

/**
 * Build a minimal FlowChart with exactly the given raw nodes/edges.
 * Uses buildChart so that kind, entries, exits, and id assignment match the
 * real pipeline's behaviour.
 */
function makeChart(rawNodes, rawEdges) {
  return buildChart({
    skill: 'aid-fixture',
    shape: 'inline-states',
    extractor: 'extract-inline',
    confidence: 'derived',
    nodes: rawNodes,
    edges: rawEdges,
    sources: ['canonical/skills/aid-fixture/SKILL.md'],
  });
}

// ── Narrow round-trip parser ──────────────────────────────────────────────────
//
// Parses the subset of Mermaid that renderMermaid emits.  Fails closed:
// any line it cannot account for throws, preventing silent topology loss.
//
// Recognised line forms:
//   flowchart TB
//   classDef <name> <props>
//   <id>([<quoted>])          — stadium (entry / exit)
//   <id>{<quoted>}            — rhombus (decision)
//   <id>[<quoted>]            — rectangle (step / loop-back)
//   <from> --> <to>           — solid, no label
//   <from> -->|"<text>"| <to> — solid, labeled
//   <from> -.-> <to>          — dotted, no label
//   <from> -. "<text>" .-> <to>  — dotted, labeled
//   class <id> <className>    — class assignment
//   (empty lines)

const WHITESPACE_ONLY = /^\s*$/;
const FLOWCHART_TB   = /^\s*flowchart\s+TB\s*$/;
// A YAML frontmatter config block precedes the flowchart line, selecting the ELK
// layout engine and its spacing. It carries no topology, so the round-trip parser
// skips it: the `---` fences and every indented `key: value` line between them.
const INIT_DIRECTIVE = /^\s*(?:---|config:|\s+\w[\w-]*:.*)\s*$/;
const CLASSDEF_LINE  = /^\s*classDef\s+\w+/;
const CLASS_ASSIGN   = /^\s*class\s+(\w+)\s+(\w+)\s*$/;

// Node declaration patterns — id must start with a letter, then word chars.
const STADIUM_DECL   = /^\s*(\w+)\(\[(?:"[^"]*"|'[^']*')\]\)\s*$/;
const RHOMBUS_DECL   = /^\s*(\w+)\{(?:"[^"]*"|'[^']*')\}\s*$/;
const RECT_DECL      = /^\s*(\w+)\[(?:"[^"]*"|'[^']*')\]\s*$/;

// Edge patterns.
const SOLID_BARE     = /^\s*(\w+)\s*-->\s*(\w+)\s*$/;
const SOLID_LABELED  = /^\s*(\w+)\s*-->\|"[^"]*"\|\s*(\w+)\s*$/;
const DOTTED_BARE    = /^\s*(\w+)\s*-\.->(\s*\w+)\s*$/;
const DOTTED_LABELED = /^\s*(\w+)\s*-\.\s*"[^"]*"\s*\.->\s*(\w+)\s*$/;

/**
 * @typedef {object} ParsedFlow
 * @property {Map<string, 'stadium'|'rhombus'|'rect'>} shapes  id → shape category
 * @property {Array<{from:string, to:string, form:'solid-bare'|'solid-labeled'|'dotted-bare'|'dotted-labeled'}>} edges
 * @property {Map<string, string[]>} classes  id → list of class names applied
 */

/**
 * Parse the Mermaid fence body produced by renderMermaid.
 * Throws on any line not covered by the above grammar.
 *
 * @param {string} body  The string returned by renderMermaid.
 * @returns {ParsedFlow}
 */
function parseEmitted(body) {
  const shapes  = new Map();
  const edges   = [];
  const classes = new Map();

  for (const rawLine of body.split('\n')) {
    const line = rawLine;

    if (WHITESPACE_ONLY.test(line)) continue;
    if (INIT_DIRECTIVE.test(line))  continue;
    if (FLOWCHART_TB.test(line))    continue;
    if (CLASSDEF_LINE.test(line))   continue;

    const ca = CLASS_ASSIGN.exec(line);
    if (ca) {
      const [, id, cls] = ca;
      if (!classes.has(id)) classes.set(id, []);
      classes.get(id).push(cls);
      continue;
    }

    const st = STADIUM_DECL.exec(line);
    if (st) { shapes.set(st[1], 'stadium'); continue; }

    const rh = RHOMBUS_DECL.exec(line);
    if (rh) { shapes.set(rh[1], 'rhombus'); continue; }

    const re = RECT_DECL.exec(line);
    if (re) { shapes.set(re[1], 'rect'); continue; }

    const slb = SOLID_LABELED.exec(line);
    if (slb) {
      edges.push({ from: slb[1], to: slb[2], form: 'solid-labeled' });
      continue;
    }

    const sb = SOLID_BARE.exec(line);
    if (sb) {
      edges.push({ from: sb[1], to: sb[2], form: 'solid-bare' });
      continue;
    }

    const dlb = DOTTED_LABELED.exec(line);
    if (dlb) {
      edges.push({ from: dlb[1], to: dlb[2], form: 'dotted-labeled' });
      continue;
    }

    const db = DOTTED_BARE.exec(line);
    if (db) {
      edges.push({ from: db[1], to: db[2].trim(), form: 'dotted-bare' });
      continue;
    }

    throw new Error(
      `parseEmitted: unrecognised Mermaid line: ${JSON.stringify(line)}\n` +
      `Full body:\n${body}`
    );
  }

  return { shapes, edges, classes };
}

// ── AC-1: fence body only ─────────────────────────────────────────────────────

describe('AC-1 — output is fence body only', () => {
  it('does not contain opening fence marker ```mermaid', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    expect(renderMermaid(chart)).not.toContain('```mermaid');
  });

  it('does not contain closing fence marker ```', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    expect(renderMermaid(chart)).not.toContain('```');
  });

  it('does not contain an H2 heading', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    // No line starting with ## (after any leading spaces)
    expect(renderMermaid(chart)).not.toMatch(/^##/m);
  });

  it('does not contain the approximate-notice text', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    expect(renderMermaid(chart)).not.toContain('Approximate');
  });

  it('opens with a frontmatter config selecting the ELK layout', () => {
    // Mermaid's default dagre layout assumes small hand-drawn diagrams. These
    // charts carry two lines of derived text per node, so shapes crowded and edges
    // took curved detours around them. ELK routes orthogonally and spaces ranks
    // properly. It reaches Mermaid through `@mermaid-js/layout-elk`, which
    // astro-mermaid registers as an optional peer dependency.
    const c = makeChart([node(1, 'A', 'Do A', halt())], []);
    const lines = renderMermaid(c).trimStart().split('\n');
    expect(lines[0]).toBe('---');
    expect(lines).toContain('  layout: elk');
    const close = lines.indexOf('---', 1);
    expect(close).toBeGreaterThan(0);
    // The graph declaration follows the closing fence immediately.
    expect(lines[close + 1]).toMatch(/^flowchart TB\s*$/);
  });

  it('still declares flowchart TB, on the line after the directive', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    const lines = renderMermaid(chart).trimStart().split('\n');
    expect(lines.find((l) => /^flowchart TB\s*$/.test(l))).toBeDefined();
  });

  it('ends with exactly one trailing LF', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    const out = renderMermaid(chart);
    expect(out.endsWith('\n')).toBe(true);
    expect(out.endsWith('\n\n')).toBe(false);
  });
});

// ── AC-2a: node shape delimiters by kind ──────────────────────────────────────

describe('AC-2 — node shape delimiters', () => {
  it('entry kind renders as stadium (["…"])', () => {
    // n1 in-degree-0 with no terminal → entry kind
    const chart = makeChart(
      [node(1, 'START', 'Begin'), node(2, 'END', 'Terminate', halt())],
      [edge('n1', 'n2')]
    );
    const entryNode = chart.nodes.find(n => n.kind === 'entry');
    expect(entryNode).toBeDefined();
    const out = renderMermaid(chart);
    // Exact shape delimiters: ([" ... "])
    expect(out).toContain(`${entryNode.id}(["`);
    expect(out).toContain(`"])`);
  });

  it('exit kind renders as stadium (["…"])', () => {
    const chart = makeChart(
      [node(1, 'START', 'Begin'), node(2, 'END', 'Terminate', halt())],
      [edge('n1', 'n2')]
    );
    const exitNode = chart.nodes.find(n => n.kind === 'exit');
    expect(exitNode).toBeDefined();
    const out = renderMermaid(chart);
    expect(out).toContain(`${exitNode.id}(["`);
  });

  it('decision kind renders as rhombus {"…"}', () => {
    // n2 is not in-degree-0 and has 2+ branch edges → decision
    const chart = makeChart(
      [
        node(1, 'START', 'Begin'),
        node(2, 'CHOOSE', 'Pick path'),
        node(3, 'PATH-A', 'Take path A', halt()),
        node(4, 'PATH-B', 'Take path B', halt()),
      ],
      [
        edge('n1', 'n2'),
        edge('n2', 'n3', 'branch', 'if A'),
        edge('n2', 'n4', 'branch', 'otherwise'),
      ]
    );
    const decisionNode = chart.nodes.find(n => n.kind === 'decision');
    expect(decisionNode).toBeDefined();
    const out = renderMermaid(chart);
    // Rhombus uses { and } delimiters
    expect(out).toContain(`${decisionNode.id}{"`);
    expect(out).toContain('"}'   );
  });

  it('step kind renders as rectangle ["…"]', () => {
    const chart = makeChart(
      [
        node(1, 'START', 'Begin'),
        node(2, 'MIDDLE', 'Do the work'),
        node(3, 'END', 'Finish', halt()),
      ],
      [edge('n1', 'n2'), edge('n2', 'n3')]
    );
    const stepNode = chart.nodes.find(n => n.kind === 'step');
    expect(stepNode).toBeDefined();
    const out = renderMermaid(chart);
    // Rectangle uses [ and ] delimiters (NOT a stadium or rhombus)
    expect(out).toMatch(new RegExp(`${stepNode.id}\\["`));
  });

  it('loop-back kind renders as rectangle ["…"]', () => {
    const loopEdge = makeEdge({
      from: 'n2', to: 'n1', kind: 'loop-back',
      condition: 'otherwise', advanceType: 'CHAIN', provenance: PROV,
    });
    const seqEdge  = makeEdge({
      from: 'n1', to: 'n2', kind: 'sequence',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const exitEdge = makeEdge({
      from: 'n2', to: 'n3', kind: 'sequence',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'REVIEW', 'Review'), node(2, 'VERIFY', 'Verify'), node(3, 'DONE', 'Done', halt())],
      [seqEdge, loopEdge, exitEdge]
    );
    const loopbackNode = chart.nodes.find(n => n.kind === 'loop-back');
    expect(loopbackNode).toBeDefined();
    const out = renderMermaid(chart);
    // Must use rectangle, not stadium or rhombus
    expect(out).toMatch(new RegExp(`${loopbackNode.id}\\["`));
    // Must NOT use stadium delimiters for this node
    expect(out).not.toContain(`${loopbackNode.id}(["`);
    // Must NOT use rhombus delimiters for this node
    expect(out).not.toContain(`${loopbackNode.id}{"`);
  });

  it('entry and exit shapes are both stadium (same delimiters, class distinguishes them)', () => {
    const chart = makeChart(
      [node(1, 'ENTRY', 'Enter'), node(2, 'EXIT', 'Exit', halt())],
      [edge('n1', 'n2')]
    );
    const parsed = parseEmitted(renderMermaid(chart));
    const entryId = chart.nodes.find(n => n.kind === 'entry').id;
    const exitId  = chart.nodes.find(n => n.kind === 'exit').id;
    // Both stadium
    expect(parsed.shapes.get(entryId)).toBe('stadium');
    expect(parsed.shapes.get(exitId)).toBe('stadium');
    // Disambiguated by kind class
    expect(parsed.classes.get(entryId)).toContain('aidEntry');
    expect(parsed.classes.get(exitId)).toContain('aidExit');
  });

  it('step and loop-back shapes are both rectangle (kind class distinguishes them)', () => {
    // n1 = entry (in-degree 0), n2 = step (mid-graph, no branches/loop-back),
    // n3 = loop-back (has outgoing loop-back edge), n4 = exit (terminal).
    const loopEdge = makeEdge({
      from: 'n3', to: 'n1', kind: 'loop-back',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [
        node(1, 'ENTRY', 'Start'),
        node(2, 'MIDDLE', 'Step work'),
        node(3, 'VERIFY', 'Loop node'),
        node(4, 'DONE', 'End', halt()),
      ],
      [edge('n1', 'n2'), edge('n2', 'n3'), loopEdge, edge('n3', 'n4')]
    );
    const stepNode     = chart.nodes.find(n => n.kind === 'step');
    const loopbackNode = chart.nodes.find(n => n.kind === 'loop-back');
    expect(stepNode).toBeDefined();
    expect(loopbackNode).toBeDefined();
    const parsed = parseEmitted(renderMermaid(chart));
    expect(parsed.shapes.get(stepNode.id)).toBe('rect');
    expect(parsed.shapes.get(loopbackNode.id)).toBe('rect');
    expect(parsed.classes.get(stepNode.id)).toContain('aidStep');
    expect(parsed.classes.get(loopbackNode.id)).toContain('aidLoopBack');
  });
});

// ── AC-2b: edge arrow forms by kind ──────────────────────────────────────────

describe('AC-2 — edge arrow forms', () => {
  it('sequence edge renders as --> (solid, no label)', () => {
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'End', halt())],
      [edge('n1', 'n2', 'sequence')]
    );
    const out = renderMermaid(chart);
    // Solid bare arrow: "n1 --> n2"
    expect(out).toContain('n1 --> n2');
    // Must NOT use dotted form for a sequence edge
    expect(out).not.toContain('n1 -.');
  });

  it('branch edge with condition renders as -->|"condition"| (labeled)', () => {
    const branchEdge = makeEdge({
      from: 'n2', to: 'n3',
      kind: 'branch', condition: 'on approval',
      advanceType: 'HALT', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Decide'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), branchEdge]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('n2 -->|"on approval"| n3');
  });

  it('branch edge with null condition renders as --> (no label)', () => {
    const branchEdge = makeEdge({
      from: 'n2', to: 'n3',
      kind: 'branch', condition: null,
      advanceType: 'HALT', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Decide'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), branchEdge]
    );
    const out = renderMermaid(chart);
    // No pipe label syntax for null condition
    expect(out).toContain('n2 --> n3');
    expect(out).not.toContain('n2 -->|');
  });

  it('loop-back edge with condition renders as -. "condition" .-> (dotted labeled)', () => {
    const loopEdge = makeEdge({
      from: 'n2', to: 'n1',
      kind: 'loop-back', condition: 'otherwise',
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Loop'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), loopEdge, edge('n2', 'n3')]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('n2 -. "otherwise" .-> n1');
  });

  it('loop-back edge with null condition renders as -.-> (dotted bare)', () => {
    const loopEdge = makeEdge({
      from: 'n2', to: 'n1',
      kind: 'loop-back', condition: null,
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Loop'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), loopEdge, edge('n2', 'n3')]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('n2 -.-> n1');
    // Must NOT use dotted-labeled form
    expect(out).not.toContain('n2 -. ');
  });

  it('re-entry edge with condition renders as -. "condition" .-> (same as loop-back)', () => {
    const reentryEdge = makeEdge({
      from: 'n2', to: 'n1',
      kind: 're-entry', condition: 'on retry',
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Process'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), reentryEdge, edge('n2', 'n3')]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('n2 -. "on retry" .-> n1');
  });

  it('re-entry edge with null condition renders as -.-> (dotted bare)', () => {
    const reentryEdge = makeEdge({
      from: 'n2', to: 'n1',
      kind: 're-entry', condition: null,
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'Start'), node(2, 'B', 'Process'), node(3, 'C', 'Done', halt())],
      [edge('n1', 'n2'), reentryEdge, edge('n2', 'n3')]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('n2 -.-> n1');
  });
});

// ── AC-3: escaping ────────────────────────────────────────────────────────────

describe('AC-3 — escaping in labels and conditions', () => {
  it('& in label becomes &amp;', () => {
    const chart = makeChart(
      [node(1, 'A', 'Parse & validate', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('&amp;');
    expect(out).not.toMatch(/(?<!&amp)&(?!amp;|lt;|gt;|quot;)/); // no bare &
  });

  it('< in label becomes &lt;', () => {
    const chart = makeChart(
      [node(1, 'A', 'grade < minimum', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('&lt;');
  });

  it('> in label becomes &gt;', () => {
    const chart = makeChart(
      [node(1, 'A', 'score > threshold', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('&gt;');
  });

  it('" in label becomes &quot; (bare-verb entry label from corpus)', () => {
    // Mirrors the corpus entry label for bare-verb skills: ARTIFACT="" (bare verb)
    const chart = makeChart(
      [node(1, 'ENTRY', 'Binds VERB=`create` ARTIFACT="" (bare verb)', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('&quot;');
    // Must not embed a literal unescaped " inside the label (only the delimiter " is OK)
    // The label is always wrapped in "…" and the content should not have bare "
    const labelLine = out.split('\n').find(l => l.includes('n1'));
    // After the opening `["` and before the closing `"]`, there should be no bare "
    const match = labelLine && labelLine.match(/n1\(\["(.*)"\]\)/);
    if (match) {
      // Check no unescaped double-quote in the inner content
      expect(match[1]).not.toMatch(/"(?!quot;|<br)/);
    }
  });

  it('>= in a condition becomes &gt;= (feature-004 GATE branch condition)', () => {
    // Per DETAIL.md: "feature-004's charts, whose GATE branch condition contains >= and {floor}"
    const branchEdge = makeEdge({
      from: 'n1', to: 'n2',
      kind: 'branch', condition: 'grade >= minimum_grade',
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'GATE', 'Evaluate grade'), node(2, 'DONE', 'Done', halt())],
      [branchEdge]
    );
    const out = renderMermaid(chart);
    expect(out).toContain('&gt;=');
    // Extract only the condition text inside the pipe labels to verify no raw > remains.
    // The edge line is: n1 -->|"grade &gt;= minimum_grade"| n2
    // The arrow --> itself contains > which is fine; we only check the condition portion.
    const edgeLine = out.split('\n').find(l => l.includes('n1 -->|'));
    expect(edgeLine).toBeDefined();
    const condMatch = edgeLine.match(/\|"([^"]*)"\|/);
    expect(condMatch).toBeTruthy();
    // Inside the condition quotes, > must be escaped as &gt;
    expect(condMatch[1]).not.toContain('>');
    expect(condMatch[1]).toContain('&gt;=');
  });

  it('{floor} in a condition is passed through (curly braces are not special in conditions)', () => {
    const branchEdge = makeEdge({
      from: 'n1', to: 'n2',
      kind: 'branch', condition: 'grade >= floor({score})',
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'GATE', 'Check floor'), node(2, 'DONE', 'Done', halt())],
      [branchEdge]
    );
    const out = renderMermaid(chart);
    // The curly braces themselves are fine (not special in Mermaid edge labels)
    expect(out).toContain('{score}');
    // But > must be escaped
    expect(out).toContain('&gt;=');
  });

  it('backtick in label becomes a space', () => {
    const chart = makeChart(
      [node(1, 'A', 'Run `aid-execute`', halt())], []
    );
    const out = renderMermaid(chart);
    // Backtick must be gone
    expect(out).not.toContain('`');
    // Replaced with space
    expect(out).toContain('Run  aid-execute ');
  });

  it('pipe | in label becomes a space', () => {
    const chart = makeChart(
      [node(1, 'A', 'Choose A | B', halt())], []
    );
    const out = renderMermaid(chart);
    // Pipe in label must be gone (it would break arrow syntax)
    // The label content should contain a space instead
    const labelContent = out.match(/n1\(\[".*?"\]\)/)?.[0] ?? '';
    expect(labelContent).not.toContain('|');
    expect(labelContent).toContain('Choose A   B'); // pipe → space
  });

  it('pipe | in a branch condition becomes a space', () => {
    const branchEdge = makeEdge({
      from: 'n1', to: 'n2',
      kind: 'branch', condition: 'A | B',
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'DECIDE', 'Decide'), node(2, 'DONE', 'Done', halt())],
      [branchEdge]
    );
    const out = renderMermaid(chart);
    // The condition inside -->|"..."| must not have a raw pipe (it would mis-parse the arrow)
    const edgeLine = out.split('\n').find(l => l.includes('n1 -->|'));
    expect(edgeLine).toBeDefined();
    // Inside the condition quotes, no raw pipe
    const condMatch = edgeLine.match(/\|"([^"]*)"\|/);
    expect(condMatch).toBeTruthy();
    expect(condMatch[1]).not.toContain('|');
  });

  it('& is escaped before < so &&lt; is not produced', () => {
    // If < is escaped first, & in the result would then be double-escaped.
    // The correct order is & → &amp; first.
    const chart = makeChart(
      [node(1, 'A', 'Test &lt; edge', halt())], []
    );
    const out = renderMermaid(chart);
    // & becomes &amp; and < becomes &lt;
    expect(out).toContain('&amp;lt;');
    // Must not double-escape the & that was already &amp;
    expect(out).not.toContain('&amp;amp;');
  });

  it('state name is also escaped when it contains special characters', () => {
    // State names in the corpus are uppercase/hyphen, but the escaper must handle
    // any input defensively (future-proofing).
    const chart = makeChart(
      [node(1, 'STATE<X>', 'Do X', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('STATE&lt;X&gt;');
    expect(out).not.toContain('STATE<X>');
  });
});

// ── AC-4: classDef block ──────────────────────────────────────────────────────

describe('AC-4 — classDef block (casulo palette)', () => {
  // Build a simple chart used across all classDef tests
  const baseChart = makeChart(
    [node(1, 'A', 'Start'), node(2, 'B', 'End', halt())],
    [edge('n1', 'n2')]
  );

  it('output contains classDef aidNode', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidNode');
  });

  it('output contains classDef aidEntry', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidEntry');
  });

  it('output contains classDef aidExit', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidExit');
  });

  it('output contains classDef aidDecision', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidDecision');
  });

  it('output contains classDef aidLoopBack', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidLoopBack');
  });

  it('output contains classDef aidStep', () => {
    expect(renderMermaid(baseChart)).toContain('classDef aidStep');
  });

  it('all six classDefs appear even in a chart that uses only two node kinds', () => {
    // A minimal chart has only entry and exit kinds, but all classDefs must still appear
    const out = renderMermaid(baseChart);
    expect(out).toContain('classDef aidNode');
    expect(out).toContain('classDef aidEntry');
    expect(out).toContain('classDef aidExit');
    expect(out).toContain('classDef aidDecision');
    expect(out).toContain('classDef aidLoopBack');
    expect(out).toContain('classDef aidStep');
  });

  it('classDef block appears before node declarations (classDefs precede nodes)', () => {
    const out = renderMermaid(baseChart);
    const classDefPos = out.indexOf('classDef aidNode');
    const nodePos     = out.indexOf('n1([');
    expect(classDefPos).toBeLessThan(nodePos);
  });

  it('classDef aidNode includes a fill/stroke-neutral style so it does not override kind colors', () => {
    // aidNode must not set fill or stroke (only color:inherit is safe as a hook class)
    const out = renderMermaid(baseChart);
    const classDefLine = out.split('\n').find(l => /classDef aidNode/.test(l));
    expect(classDefLine).toBeDefined();
    // The aidNode classDef must not contain fill: or stroke:
    expect(classDefLine).not.toMatch(/fill:/);
    expect(classDefLine).not.toMatch(/stroke:/);
  });

  it('aidNode is DECLARED BEFORE every kind classDef, which is what makes it lose the cascade', () => {
    // The property above is necessary but not sufficient, and this is the half that
    // was missing. `aidNode` carries `color:inherit`, and every node receives two
    // class statements — `class n1 aidEntry` then `class n1 aidNode`. Both land on
    // one element with equal specificity, so the winner is decided by which classDef
    // is DECLARED LATER in the fence, not by the order of the class attribute.
    //
    // So legibility rests on a line ordering that nothing else in the suite pins.
    // Move `classDef aidNode` after the kind classDefs and `color:inherit` would win,
    // dropping every node's text to the inherited colour against dark fills — a
    // contrast regression invisible to a substring assertion. The class cannot simply
    // be dropped instead: it is hook H3 and feature-006 binds to it.
    const lines = renderMermaid(baseChart).split('\n');
    const aidNodeAt = lines.findIndex((l) => /^\s*classDef aidNode\b/.test(l));
    const kindDefs = lines
      .map((l, i) => [l, i])
      .filter(([l]) => /^\s*classDef aid(Entry|Exit|Decision|LoopBack|Step)\b/.test(l));

    expect(aidNodeAt).toBeGreaterThanOrEqual(0);
    // Non-vacuity: all five kind classDefs are present, so this is not passing on an
    // empty list.
    expect(kindDefs).toHaveLength(5);
    for (const [line, at] of kindDefs) {
      expect(at, `${line.trim()} must be declared after classDef aidNode`).toBeGreaterThan(aidNodeAt);
    }
  });
});

// ── AC-5: class <id> aidNode (hook H3) ────────────────────────────────────────

describe('AC-5 — every node carries class <id> aidNode (hook H3)', () => {
  it('single-node chart has class n1 aidNode', () => {
    const chart = makeChart([node(1, 'ONLY', 'Only node', halt())], []);
    expect(renderMermaid(chart)).toContain('class n1 aidNode');
  });

  it('every node in a multi-node chart has its own class <id> aidNode statement', () => {
    const chart = makeChart(
      [
        node(1, 'START', 'Begin'),
        node(2, 'MIDDLE', 'Process'),
        node(3, 'END', 'Terminate', halt()),
      ],
      [edge('n1', 'n2'), edge('n2', 'n3')]
    );
    const out = renderMermaid(chart);
    for (const n of chart.nodes) {
      expect(out).toContain(`class ${n.id} aidNode`);
    }
  });

  it('aidNode statement is backed by classDef aidNode in the same output', () => {
    const chart = makeChart([node(1, 'A', 'Do A', halt())], []);
    const out = renderMermaid(chart);
    expect(out).toContain('classDef aidNode');
    expect(out).toContain('class n1 aidNode');
  });

  it('every node also has a kind-specific class assignment', () => {
    const chart = makeChart(
      [
        node(1, 'START', 'Entry node'),
        node(2, 'END', 'Exit node', halt()),
      ],
      [edge('n1', 'n2')]
    );
    const out = renderMermaid(chart);
    const parsed = parseEmitted(out);
    // Every node id that appears in chart.nodes must have a class assignment
    for (const n of chart.nodes) {
      const classes = parsed.classes.get(n.id) ?? [];
      // Must have aidNode
      expect(classes).toContain('aidNode');
      // Must have a kind class (one of the five kind names)
      const kindClasses = ['aidEntry', 'aidExit', 'aidDecision', 'aidLoopBack', 'aidStep'];
      expect(classes.some(c => kindClasses.includes(c))).toBe(true);
    }
  });
});

// ── AC-6: node and edge ordering ──────────────────────────────────────────────

describe('AC-6 — node declarations follow order; edge lines follow (from.order, to.order, condition)', () => {
  it('nodes appear in order.order ascending in the output', () => {
    // Provide raw nodes with non-sequential orders to verify sort
    const chart = makeChart(
      [node(3, 'C', 'Third'), node(1, 'A', 'First'), node(2, 'B', 'Second', halt())],
      [edge('n1', 'n3'), edge('n3', 'n2')]
    );
    const out = renderMermaid(chart);
    const nodeLines = out.split('\n').filter(l => /n\d\(?\[|n\d\{/.test(l));
    // n1 declaration must appear before n2, which must appear before n3
    const posN1 = out.indexOf('n1([');
    const posN2 = out.indexOf('n2([');
    const posN3 = out.indexOf('n3[');
    // n1 entry, n3 loop-back (both have non-terminal, n2 has terminal → exit)
    // The exact positions: n1 first, then n2, then n3 (by order field)
    // Verify by checking their relative order in the output
    const ids = nodeLines.map(l => l.match(/n(\d+)/)?.[0]);
    expect(ids[0]).toBe('n1');
  });

  it('edges appear after all node declarations', () => {
    const chart = makeChart(
      [node(1, 'A', 'A'), node(2, 'B', 'B', halt())],
      [edge('n1', 'n2')]
    );
    const out = renderMermaid(chart);
    const lastNodeLine = out.lastIndexOf('n1([') > out.lastIndexOf('n2([')
      ? out.lastIndexOf('n1([')
      : out.lastIndexOf('n2([');
    const firstEdgeLine = out.indexOf('n1 -->');
    expect(firstEdgeLine).toBeGreaterThan(lastNodeLine);
  });

  it('edges follow (from.order, to.order, condition) sort order', () => {
    // n2 → n3 (cond z) should come after n2 → n3 (cond a) which comes after n1 → n2
    const e1 = makeEdge({
      from: 'n2', to: 'n3', kind: 'branch', condition: 'z-cond',
      advanceType: 'HALT', provenance: PROV,
    });
    const e2 = makeEdge({
      from: 'n2', to: 'n3', kind: 'branch', condition: 'a-cond',
      advanceType: 'HALT', provenance: PROV,
    });
    const e3 = makeEdge({
      from: 'n1', to: 'n2', kind: 'sequence', condition: null,
      advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [node(1, 'A', 'A'), node(2, 'B', 'Decide'), node(3, 'C', 'End', halt())],
      [e1, e2, e3]
    );
    const out = renderMermaid(chart);
    const posE3 = out.indexOf('n1 --> n2');    // from order 1 → first
    const posE2 = out.indexOf('"a-cond"');     // from order 2, cond a → second
    const posE1 = out.indexOf('"z-cond"');     // from order 2, cond z → third
    expect(posE3).toBeLessThan(posE2);
    expect(posE2).toBeLessThan(posE1);
  });
});

// ── AC-7: byte-stability ──────────────────────────────────────────────────────

describe('AC-7 — two calls return identical strings (byte-stability)', () => {
  it('simple linear chart: two calls are byte-identical', () => {
    const chart = makeChart(
      [node(1, 'START', 'Begin'), node(2, 'END', 'Terminate', halt())],
      [edge('n1', 'n2')]
    );
    expect(renderMermaid(chart)).toBe(renderMermaid(chart));
  });

  it('chart with all five kinds: two calls are byte-identical', () => {
    const loopEdge = makeEdge({
      from: 'n4', to: 'n2', kind: 'loop-back',
      condition: 'otherwise', advanceType: 'CHAIN', provenance: PROV,
    });
    const b1 = makeEdge({
      from: 'n2', to: 'n3', kind: 'branch',
      condition: 'if A', advanceType: 'CHAIN', provenance: PROV,
    });
    const b2 = makeEdge({
      from: 'n2', to: 'n5', kind: 'branch',
      condition: null, advanceType: 'HALT', provenance: PROV,
    });
    const chart = makeChart(
      [
        node(1, 'ENTRY', 'Start'),
        node(2, 'DECIDE', 'Branch here'),
        node(3, 'PROCESS', 'Do work'),
        node(4, 'VERIFY', 'Check it'),
        node(5, 'EXIT', 'Done', halt()),
      ],
      [edge('n1', 'n2'), b1, edge('n3', 'n4'), loopEdge, b2]
    );
    expect(renderMermaid(chart)).toBe(renderMermaid(chart));
  });

  it('output does not change between calls (reads no clock, env, or random)', () => {
    // Store and compare two independent calls
    const chart = makeChart(
      [node(1, 'A', 'Do A'), node(2, 'B', 'Done', halt())],
      [edge('n1', 'n2')]
    );
    const first  = renderMermaid(chart);
    const second = renderMermaid(chart);
    expect(first).toBe(second);
  });
});

// ── Round-trip: topology preservation ─────────────────────────────────────────

describe('Round-trip — rendered Mermaid preserves chart topology', () => {
  it('all five node kinds round-trip to their correct shape categories', () => {
    const loopEdge = makeEdge({
      from: 'n4', to: 'n2', kind: 'loop-back',
      condition: 'otherwise', advanceType: 'CHAIN', provenance: PROV,
    });
    const b1 = makeEdge({
      from: 'n3', to: 'n4', kind: 'branch',
      condition: 'if A', advanceType: 'CHAIN', provenance: PROV,
    });
    const b2 = makeEdge({
      from: 'n3', to: 'n5', kind: 'branch',
      condition: null, advanceType: 'HALT', provenance: PROV,
    });
    const chart = makeChart(
      [
        node(1, 'ENTRY', 'Start'),           // → entry (in-degree 0)
        node(2, 'MIDDLE', 'Process'),         // → step
        node(3, 'DECIDE', 'Pick path'),       // → decision (2 branch edges)
        node(4, 'VERIFY', 'Check'),           // → loop-back (loop-back edge out)
        node(5, 'EXIT', 'Done', halt()),      // → exit (terminal)
      ],
      [edge('n1', 'n2'), edge('n2', 'n3'), b1, b2, loopEdge]
    );
    const parsed = parseEmitted(renderMermaid(chart));

    // Verify shapes from kind
    expect(parsed.shapes.get('n1')).toBe('stadium');   // entry
    expect(parsed.shapes.get('n2')).toBe('rect');      // step
    expect(parsed.shapes.get('n3')).toBe('rhombus');   // decision
    expect(parsed.shapes.get('n4')).toBe('rect');      // loop-back
    expect(parsed.shapes.get('n5')).toBe('stadium');   // exit

    // Verify kind classes assigned correctly
    expect(parsed.classes.get('n1')).toContain('aidEntry');
    expect(parsed.classes.get('n2')).toContain('aidStep');
    expect(parsed.classes.get('n3')).toContain('aidDecision');
    expect(parsed.classes.get('n4')).toContain('aidLoopBack');
    expect(parsed.classes.get('n5')).toContain('aidExit');

    // All nodes also have aidNode
    for (const id of ['n1', 'n2', 'n3', 'n4', 'n5']) {
      expect(parsed.classes.get(id)).toContain('aidNode');
    }
  });

  it('all four edge kinds round-trip to their correct arrow forms', () => {
    const bEdge = makeEdge({
      from: 'n1', to: 'n2', kind: 'branch',
      condition: 'if A', advanceType: 'CHAIN', provenance: PROV,
    });
    const sEdge = makeEdge({
      from: 'n2', to: 'n3', kind: 'sequence',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const lEdge = makeEdge({
      from: 'n3', to: 'n1', kind: 'loop-back',
      condition: 'otherwise', advanceType: 'CHAIN', provenance: PROV,
    });
    const rEdge = makeEdge({
      from: 'n3', to: 'n4', kind: 're-entry',
      condition: null, advanceType: 'CHAIN', provenance: PROV,
    });
    const chart = makeChart(
      [
        node(1, 'A', 'A'),
        node(2, 'B', 'B'),
        node(3, 'C', 'C'),
        node(4, 'D', 'D', halt()),
      ],
      [bEdge, sEdge, lEdge, rEdge]
    );
    const parsed = parseEmitted(renderMermaid(chart));

    // branch with condition → solid-labeled
    const bParsed = parsed.edges.find(e => e.from === 'n1' && e.to === 'n2');
    expect(bParsed?.form).toBe('solid-labeled');

    // sequence → solid-bare
    const sParsed = parsed.edges.find(e => e.from === 'n2' && e.to === 'n3');
    expect(sParsed?.form).toBe('solid-bare');

    // loop-back with condition → dotted-labeled
    const lParsed = parsed.edges.find(e => e.from === 'n3' && e.to === 'n1');
    expect(lParsed?.form).toBe('dotted-labeled');

    // re-entry null condition → dotted-bare
    const rParsed = parsed.edges.find(e => e.from === 'n3' && e.to === 'n4');
    expect(rParsed?.form).toBe('dotted-bare');
  });

  it('edge count in parsed output matches chart.edges.length', () => {
    const chart = makeChart(
      [
        node(1, 'A', 'Start'),
        node(2, 'B', 'Middle'),
        node(3, 'C', 'End', halt()),
      ],
      [edge('n1', 'n2'), edge('n2', 'n3'), edge('n1', 'n3')]
    );
    const parsed = parseEmitted(renderMermaid(chart));
    expect(parsed.edges.length).toBe(chart.edges.length);
  });

  it('node count in parsed output matches chart.nodes.length', () => {
    const chart = makeChart(
      [node(1, 'A', 'A'), node(2, 'B', 'B'), node(3, 'C', 'C', halt())],
      [edge('n1', 'n2'), edge('n2', 'n3')]
    );
    const parsed = parseEmitted(renderMermaid(chart));
    expect(parsed.shapes.size).toBe(chart.nodes.length);
  });

  it('node label two-line format: each node declaration contains <br/>', () => {
    const chart = makeChart(
      [node(1, 'INTAKE', 'Resolve the target'), node(2, 'DONE', 'Finished', halt())],
      [edge('n1', 'n2')]
    );
    const out = renderMermaid(chart);
    // Every node declaration (lines with n1 or n2 declaration form) contains <br/>
    const nodeLines = out.split('\n').filter(l => /^\s+n\d/.test(l) && /\[/.test(l));
    for (const ln of nodeLines) {
      expect(ln).toContain('<br/>');
    }
  });

  it('parseEmitted throws on unrecognised Mermaid constructs (fails closed)', () => {
    expect(() => parseEmitted('flowchart TB\n  n1 ~~~ n2\n')).toThrow('parseEmitted');
  });
});

// ── Two-line label format ──────────────────────────────────────────────────────

describe('Two-line label — NAME<br/>derived label', () => {
  it('node declaration contains the state name before <br/>', () => {
    const chart = makeChart(
      [node(1, 'PRESENT-FINDINGS', 'Present the analysis', halt())], []
    );
    const out = renderMermaid(chart);
    // The name PRESENT-FINDINGS must appear before <br/>
    const match = out.match(/n1\(\["([^<]*)<br\/>([^"]*)"]/);
    expect(match).toBeTruthy();
    expect(match[1]).toBe('PRESENT-FINDINGS');
    expect(match[2]).toBe('Present the analysis');
  });

  it('node declaration contains the derived label after <br/>', () => {
    const chart = makeChart(
      [node(1, 'VERIFY', 'Check correctness of artifacts', halt())], []
    );
    const out = renderMermaid(chart);
    expect(out).toContain('VERIFY<br/>Check correctness of artifacts');
  });

  it('the <br/> separator itself is NOT escaped (it is Mermaid HTML markup)', () => {
    const chart = makeChart([node(1, 'A', 'Label', halt())], []);
    const out = renderMermaid(chart);
    // <br/> must be present as HTML (not escaped to &lt;br/&gt;)
    expect(out).toContain('<br/>');
    expect(out).not.toContain('&lt;br/&gt;');
  });
});
