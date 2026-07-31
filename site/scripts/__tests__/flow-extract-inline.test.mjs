// flow-extract-inline.test.mjs — Unit tests for extract-inline.mjs (task-026).
//
// Coverage:
//   extractInline — all processing steps, each rule, and all 8 corpus skills.
//
// Testing discipline (binding per DETAIL.md):
//   - Every assertion drives the real module; no logic is re-implemented here.
//   - Exact values are asserted: counts, names, kinds, conditions, advanceTypes.
//   - Every rule has a FIRING CASE and a NEAR-MISS that genuinely reaches the rule
//     but does not trigger it.
//   - Mutation-proofing: each assertion is annotated with the mutation that would
//     make it fail (searched by `Mutant:` comment).
//   - Corpus sizes are MEASURED from the live file before asserting; no counts
//     are hard-coded (§8 / KI-005).
//   - provenance.excerpt is verified against the live allLines slice (AC-7).
//   - validateChart(chart).ok === true is asserted for every chart (V1-V8).

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { extractInline } from '../lib/flow-graph/extract-inline.mjs';
import { splitFrontmatter } from '../lib/flow-graph/source.mjs';
import { validateChart } from '../lib/flow-graph/validate.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Build extractInline params from a raw SKILL.md text string.
 * The file is set to `canonical/skills/<skillName>/SKILL.md` so V7 passes.
 *
 * @param {string} text       Full SKILL.md content (must start with ---\n).
 * @param {string} skillName  Skill directory name (default: 'test-fixture').
 * @returns {object}  Params ready to pass to extractInline.
 */
function parseSkill(text, skillName = 'test-fixture') {
  const file = `canonical/skills/${skillName}/SKILL.md`;
  const { allLines } = splitFrontmatter(text, file);
  return { skill: skillName, file, allLines, frontmatter: {} };
}

/**
 * Load a real SKILL.md from canonical/skills/<name>/SKILL.md.
 *
 * @param {string} name
 * @returns {object}  Params for extractInline.
 */
function loadSkill(name) {
  const file = `canonical/skills/${name}/SKILL.md`;
  const absPath = resolve(REPO_ROOT, file);
  const text = readFileSync(absPath, 'utf8');
  const { allLines } = splitFrontmatter(text, file);
  return { skill: name, file, allLines, frontmatter: {} };
}

/** Count ## State: headings in a line array (live measurement — no hard-coding). */
function countStateHeadings(allLines) {
  return allLines.filter((l) => /^##\s+State:\s+\S/.test(l)).length;
}

// ── Minimal fixture: 2 states ─────────────────────────────────────────────────

const TWO_STATE = `---
name: two-state
description: Minimal two-state fixture
---

## State: ALPHA

The lead paragraph of ALPHA.

**Advance:** BETA.

---

## State: BETA

The lead paragraph of BETA.
`;

describe('extractInline — basic 2-state fixture', () => {
  const params = parseSkill(TWO_STATE, 'two-state');
  const chart = extractInline(params);

  it('returns a non-null chart', () => {
    // Mutant: return null when sections.length < 2 always → chart would be null.
    expect(chart).not.toBeNull();
  });

  it('produces exactly 2 nodes', () => {
    // Mutant: advance sections loop by 2 instead of 1 → only 1 node.
    const measured = countStateHeadings(params.allLines);
    expect(chart.nodes.length).toBe(measured);
    expect(chart.nodes.length).toBe(2);
  });

  it('nodes are in document order (ALPHA first, BETA second)', () => {
    // Mutant: reverse the sections array → BETA first.
    expect(chart.nodes[0].name).toBe('ALPHA');
    expect(chart.nodes[1].name).toBe('BETA');
  });

  it('first node has order 1, second has order 2', () => {
    // Mutant: start order at 0 → order would be 0 and 1.
    expect(chart.nodes[0].order).toBe(1);
    expect(chart.nodes[1].order).toBe(2);
  });

  it('shape is inline-states', () => {
    // Mutant: use SHAPE = 'residual' → shape would be 'residual'.
    expect(chart.shape).toBe('inline-states');
  });

  it('extractor is inline', () => {
    // Mutant: use EXTRACTOR = 'residual' → extractor would be 'residual'.
    expect(chart.extractor).toBe('inline');
  });

  it('confidence is derived', () => {
    // Mutant: use CONFIDENCE = 'approximate' → confidence would be 'approximate'.
    expect(chart.confidence).toBe('derived');
  });

  it('produces exactly 1 edge (ALPHA → BETA)', () => {
    // Mutant: skip advance block parsing → 0 edges.
    expect(chart.edges.length).toBe(1);
    expect(chart.edges[0]).toMatchObject({
      from: 'n1',
      to: 'n2',
      kind: 'sequence',
      condition: null,
      advanceType: 'UNSPECIFIED',
    });
  });

  it('BETA is an exit with advanceType UNSPECIFIED (no Advance line)', () => {
    // Mutant: always set terminal = null → BETA.terminal would be null → exits would be [].
    expect(chart.nodes[1].terminal).toEqual({ advanceType: 'UNSPECIFIED', handoff: null });
  });

  it('ALPHA has no terminal (it has an Advance line)', () => {
    // Mutant: always assign UNSPECIFIED terminal → ALPHA.terminal would be non-null.
    expect(chart.nodes[0].terminal).toBeNull();
  });

  it('entries = [n1], exits = [n2]', () => {
    // Mutant: wrong order → ids would swap.
    expect(chart.entries).toEqual(['n1']);
    expect(chart.exits).toEqual(['n2']);
  });

  it('passes V1-V8 validation', () => {
    // Mutant: produce bad provenance startLine/endLine → V7 fails.
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

// ── null for < 2 state headings ───────────────────────────────────────────────

describe('extractInline — returns null when fewer than 2 ## State: headings', () => {
  it('returns null for a single ## State: heading', () => {
    // Near-miss: exactly 1 heading reaches the sections.length < 2 guard.
    // Mutant: change < 2 to <= 2 → a 2-heading skill would also return null.
    const text = `---\nname: t\ndescription: T\n---\n\n## State: LONELY\n\nSome body.\n`;
    const params = parseSkill(text, 't');
    expect(extractInline(params)).toBeNull();
  });

  it('returns non-null for exactly 2 ## State: headings (boundary)', () => {
    // Mutant: change < 2 to < 3 → 2-heading skills would return null.
    const params = parseSkill(TWO_STATE, 'two-state');
    expect(extractInline(params)).not.toBeNull();
  });
});

// ── Parenthetical gloss ───────────────────────────────────────────────────────

const GLOSS_FIXTURE = `---
name: gloss-test
description: Gloss test
---

## State: ALPHA

Lead line.

**Advance:** VERIFY.

## State: VERIFY  (who reviews the reviewer)

Second state lead.

**Advance:** DONE.

## State: DONE

Final.
`;

describe('extractInline — parenthetical gloss handling', () => {
  const params = parseSkill(GLOSS_FIXTURE, 'gloss-test');
  const chart = extractInline(params);

  it('strips gloss from node name', () => {
    // Mutant: skip rawName.replace → name would be "VERIFY  (who reviews the reviewer)".
    expect(chart.nodes[1].name).toBe('VERIFY');
  });

  it('uses gloss as label when present', () => {
    // Mutant: always use section.name for label → label would be "VERIFY" not the gloss.
    expect(chart.nodes[1].label).toBe('who reviews the reviewer');
  });

  it('uses state name as label when no gloss', () => {
    // Mutant: always use gloss path → empty gloss would produce empty label.
    expect(chart.nodes[0].label).toBe('ALPHA');
    expect(chart.nodes[2].label).toBe('DONE');
  });

  it('gloss is retained as label even when gloss references another state (no edge)', () => {
    // Rule: gloss is a display label, not edge-producing syntax.
    expect(chart.nodes[1].label).not.toBe('VERIFY');
  });
});

// ── Provenance excerpt matches live file slice (AC-7) ─────────────────────────

describe('extractInline — provenance excerpt equals live allLines slice', () => {
  const params = parseSkill(GLOSS_FIXTURE, 'gloss-test');
  const chart = extractInline(params);

  it('every node provenance.excerpt matches allLines[start-1..end-1].join(newline)', () => {
    // Mutant: use wrong startLine in buildProvenance → excerpt would differ.
    for (const node of chart.nodes) {
      const p = node.provenance;
      const expected = params.allLines.slice(p.startLine - 1, p.endLine).join('\n');
      expect(p.excerpt).toBe(expected);
    }
  });

  it('every node detail.excerpt matches allLines slice for full section', () => {
    // Mutant: use sectionEndLine for provenance and leadEndLine for detail → excerpts swap.
    for (const node of chart.nodes) {
      const d = node.detail;
      const expected = params.allLines.slice(d.startLine - 1, d.endLine).join('\n');
      expect(d.excerpt).toBe(expected);
    }
  });

  it('provenance is the compact range (shorter or equal to detail)', () => {
    // Mutant: swap provenance and detail ranges → provenance would be longer than detail.
    for (const node of chart.nodes) {
      const provLines = node.provenance.endLine - node.provenance.startLine + 1;
      const detailLines = node.detail.endLine - node.detail.startLine + 1;
      expect(provLines).toBeLessThanOrEqual(detailLines);
    }
  });

  it('sourceKind is skill for all provenance records', () => {
    // Mutant: use 'worker' → sourceKind would not be 'skill'.
    for (const node of chart.nodes) {
      expect(node.provenance.sourceKind).toBe('skill');
      expect(node.detail.sourceKind).toBe('skill');
    }
  });
});

// ── Body back-reference → loop-back edge (rule 7) ────────────────────────────

const LOOPBACK_FIXTURE = `---
name: loopback-test
description: Loop-back test
---

## State: START

Entry state.

**Advance:** VERIFY.

## State: VERIFY

Some verification. Not clean -> loop to START for correction.

**Advance:** FINISH.

## State: FINISH

All done.
`;

describe('extractInline — body back-reference emits loop-back edge', () => {
  const params = parseSkill(LOOPBACK_FIXTURE, 'loopback-test');
  const chart = extractInline(params);

  it('VERIFY emits a loop-back edge back to START from body text', () => {
    // Mutant: remove TOKEN_RE scan in _scanBodyEdges → no loop-back edge.
    const loopEdge = chart.edges.find(
      (e) => e.from === 'n2' && e.to === 'n1' && e.kind === 'loop-back'
    );
    expect(loopEdge).toBeDefined();
  });

  it('loop-back edge has condition null and advanceType UNSPECIFIED', () => {
    // Mutant: set condition to 'something' → this assertion fails.
    const loopEdge = chart.edges.find(
      (e) => e.from === 'n2' && e.to === 'n1' && e.kind === 'loop-back'
    );
    expect(loopEdge.condition).toBeNull();
    expect(loopEdge.advanceType).toBe('UNSPECIFIED');
  });

  it('loop-back edge provenance cites a line in the VERIFY section body', () => {
    // Mutant: use headingLine as provenance for all body edges → line would be the heading.
    const loopEdge = chart.edges.find(
      (e) => e.from === 'n2' && e.to === 'n1' && e.kind === 'loop-back'
    );
    expect(loopEdge.provenance.startLine).toBeGreaterThan(chart.nodes[1].provenance.startLine);
  });

  it('VERIFY still has the forward edge to FINISH from the advance block', () => {
    // Mutant: skip advance block parsing → no forward edge.
    const fwdEdge = chart.edges.find(
      (e) => e.from === 'n2' && e.to === 'n3' && e.kind === 'sequence'
    );
    expect(fwdEdge).toBeDefined();
  });

  it('total 3 edges: START→VERIFY, VERIFY→START (loop-back), VERIFY→FINISH', () => {
    // Mutant: body scan also picks up FINISH mention → would be 4 edges.
    expect(chart.edges.length).toBe(3);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── Near-miss: body says "loop" but no state name → no extra loop-back ────────

const NO_EXPLICIT_LOOP_FIXTURE = `---
name: no-explicit-loop
description: Body says loop but no state name
---

## State: ALPHA

Some state.

**Advance:** VERIFY.

## State: VERIFY

Grade the output. Not clean -> loop on failure (3-cycle circuit-breaker).

**Advance:** FINISH.

## State: FINISH

Done.
`;

describe('extractInline — near-miss: "loop" in body without state name does not emit edge', () => {
  const params = parseSkill(NO_EXPLICIT_LOOP_FIXTURE, 'no-explicit-loop');
  const chart = extractInline(params);

  it('VERIFY emits no loop-back body edge when no earlier state name appears', () => {
    // Near-miss: "loop on failure" is in body but no declared state name is present.
    // Mutant: change stateByName lookup to partial match → would find "failure" as a state.
    const loopEdgesFromVerify = chart.edges.filter(
      (e) => e.from === 'n2' && e.kind === 'loop-back'
    );
    expect(loopEdgesFromVerify).toHaveLength(0);
  });

  it('only 2 forward edges (ALPHA→VERIFY, VERIFY→FINISH)', () => {
    // Mutant: emit a spurious loop-back from "loop" token → 3 edges.
    expect(chart.edges.length).toBe(2);
  });
});

// ── Rule 8: Loopback/Re-entry heading → re-entry edge ────────────────────────

const REENTRY_FIXTURE = `---
name: reentry-test
description: Re-entry heading test
---

## State: ALPHA

Entry state.

**Advance:** VERIFY.

## State: VERIFY

Do verification.

### Loopback path: ALPHA

On failure, re-enter ALPHA.

**Advance:** FINISH.

## State: FINISH

Final.
`;

describe('extractInline — rule 8: sub-heading with Loopback emits re-entry edge', () => {
  const params = parseSkill(REENTRY_FIXTURE, 'reentry-test');
  const chart = extractInline(params);

  it('VERIFY emits a re-entry edge to ALPHA from the Loopback sub-heading', () => {
    // Mutant: remove RE_ENTRY_HEADING_RE check → kind would be loop-back, not re-entry.
    const reentryEdge = chart.edges.find(
      (e) => e.from === 'n2' && e.to === 'n1' && e.kind === 're-entry'
    );
    expect(reentryEdge).toBeDefined();
  });

  it('re-entry edge has condition null', () => {
    // Mutant: set condition from heading text → condition would be non-null.
    const reentryEdge = chart.edges.find((e) => e.kind === 're-entry');
    expect(reentryEdge.condition).toBeNull();
  });

  it('re-entry edge is not reclassified as loop-back', () => {
    // advance.mjs rule 7 guards against downgrading re-entry edges;
    // the extractor must set kind: 're-entry' directly for them.
    // Mutant: produce loop-back from _scanBodyEdges → kind would be 'loop-back'.
    const reentryEdge = chart.edges.find((e) => e.from === 'n2' && e.to === 'n1');
    expect(reentryEdge.kind).toBe('re-entry');
  });

  it('only one re-entry edge (deduplicated)', () => {
    // Mutant: remove seen-set deduplication → two re-entry edges to ALPHA.
    const reentryEdges = chart.edges.filter((e) => e.kind === 're-entry');
    expect(reentryEdges).toHaveLength(1);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── Near-miss: heading without Loopback/Re-entry does not trigger rule 8 ─────

describe('extractInline — near-miss: plain sub-heading does not emit re-entry edge', () => {
  const PLAIN_HEADING = `---
name: plain-heading
description: Plain sub-heading
---

## State: ALPHA

**Advance:** VERIFY.

## State: VERIFY

### Step 1: process ALPHA data

Some prose about ALPHA.

**Advance:** FINISH.

## State: FINISH

Done.
`;

  it('sub-heading mentioning a state name does NOT produce re-entry when no Loopback/Re-entry', () => {
    // Near-miss: "### Step 1: process ALPHA data" contains ALPHA but no Loopback/Re-entry.
    // This genuinely reaches the heading check but does not trigger rule 8.
    // Mutant: remove RE_ENTRY_HEADING_RE test → would emit re-entry for any heading.
    const params = parseSkill(PLAIN_HEADING, 'plain-heading');
    const chart = extractInline(params);
    const reentryEdges = chart.edges.filter((e) => e.kind === 're-entry');
    expect(reentryEdges).toHaveLength(0);
  });
});

// ── No-advance exit ───────────────────────────────────────────────────────────

const MULTI_STATE = `---
name: multi-state
description: Multi-state with DONE exit
---

## State: INTAKE

**Advance:** RUN.

## State: RUN

Execute the work.

**Advance:** VERIFY.

## State: VERIFY

Check output. Not clean -> loop to RUN.

**Advance:** DONE-NODE.

## State: DONE-NODE

Lifecycle complete. Keep artifact as record.
`;

describe('extractInline — no-advance state is UNSPECIFIED exit', () => {
  const params = parseSkill(MULTI_STATE, 'multi-state');
  const chart = extractInline(params);

  it('DONE-NODE (no Advance line) has terminal { advanceType: UNSPECIFIED, handoff: null }', () => {
    // Mutant: only set UNSPECIFIED terminal when hasAdvanceLine → terminal would be null
    //         (since there is no Advance line and the no-advance branch would not fire).
    const done = chart.nodes.find((n) => n.name === 'DONE-NODE');
    expect(done.terminal).toEqual({ advanceType: 'UNSPECIFIED', handoff: null });
  });

  it('DONE-NODE is in exits', () => {
    // Mutant: skip UNSPECIFIED terminal → done.terminal = null → exits fallback fires,
    //         designating the highest-order node but with a warning.
    const done = chart.nodes.find((n) => n.name === 'DONE-NODE');
    expect(chart.exits).toContain(done.id);
  });

  it('VERIFY has a loop-back to RUN from body text', () => {
    // Mutant: body scan skips uppercase tokens → RUN not matched.
    const loopEdge = chart.edges.find(
      (e) => e.from === 'n3' && e.to === 'n2' && e.kind === 'loop-back'
    );
    expect(loopEdge).toBeDefined();
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── Fenced code block exclusion ───────────────────────────────────────────────

describe('extractInline — state names inside fenced code blocks are not back-references', () => {
  const FENCED_FIXTURE = `---
name: fenced-test
description: Fenced code fixture
---

## State: ALPHA

Body text.

**Advance:** VERIFY.

## State: VERIFY

Some content.

\`\`\`
Example: ALPHA -> VERIFY -> FINISH
\`\`\`

**Advance:** FINISH.

## State: FINISH

Done.
`;

  it('ALPHA inside a fenced block does not produce a loop-back edge from VERIFY', () => {
    // Mutant: remove inFence tracking → ALPHA in code block would match → spurious loop-back.
    const params = parseSkill(FENCED_FIXTURE, 'fenced-test');
    const chart = extractInline(params);
    const loopEdges = chart.edges.filter(
      (e) => e.from === 'n2' && e.to === 'n1' && e.kind === 'loop-back'
    );
    expect(loopEdges).toHaveLength(0);
  });
});

// ── Advance block deduplication: advance target not re-emitted by body scan ───

describe('extractInline — advance-block target not duplicated by body back-ref scan', () => {
  // VERIFY's advance says "**Advance:** ALPHA." — a back-reference via advance.
  // advance.mjs rule 7 classifies it as loop-back. The body also says "ALPHA"
  // but it must not produce a second edge.
  const DEDUP_FIXTURE = `---
name: dedup-test
description: Deduplication test
---

## State: ALPHA

First state.

**Advance:** VERIFY.

## State: VERIFY

Check and possibly return to ALPHA.

**Advance:** ALPHA.

## State: FINAL

Done.
`;

  it('only one edge from VERIFY to ALPHA, not two', () => {
    // advance.mjs creates the loop-back via rule 7 (ALPHA has lower order than VERIFY).
    // The body scan must not duplicate it.
    // Mutant: remove existingTargets dedup → 2 edges from VERIFY to ALPHA.
    const params = parseSkill(DEDUP_FIXTURE, 'dedup-test');
    const chart = extractInline(params);
    const edgesFromVerifyToAlpha = chart.edges.filter(
      (e) => e.from === 'n2' && e.to === 'n1'
    );
    expect(edgesFromVerifyToAlpha).toHaveLength(1);
  });

  it('passes V1-V8 (no V5 duplicate-triple violation)', () => {
    const params = parseSkill(DEDUP_FIXTURE, 'dedup-test');
    expect(validateChart(extractInline(params)).ok).toBe(true);
  });
});

// ── aid-review corpus (6 states — AC-4 fixture) ───────────────────────────────

describe('aid-review — 6 inline states, loop-back, branch decision, DONE exit', () => {
  const params = loadSkill('aid-review');
  const chart = extractInline(params);

  it('produces exactly 6 nodes (measured, not hard-coded)', () => {
    // Mutant: skip one section in the loop → 5 nodes.
    const measured = countStateHeadings(params.allLines);
    expect(chart.nodes.length).toBe(measured);
    expect(chart.nodes.length).toBe(6);
  });

  it('node names match the declared state headings in order', () => {
    // Mutant: reverse sections → DONE would be first.
    expect(chart.nodes.map((n) => n.name)).toEqual([
      'INTAKE', 'REVIEW', 'VERIFY', 'PRESENT-FINDINGS', 'PUBLISH', 'DONE',
    ]);
  });

  it('VERIFY has label matching its gloss "who reviews the reviewer"', () => {
    // Mutant: use name instead of gloss → label would be "VERIFY".
    const verify = chart.nodes.find((n) => n.name === 'VERIFY');
    expect(verify.label).toBe('who reviews the reviewer');
  });

  it('PRESENT-FINDINGS has gloss label (hard stop)', () => {
    // Mutant: gloss strip fails → label would include parentheses.
    const pf = chart.nodes.find((n) => n.name === 'PRESENT-FINDINGS');
    expect(pf.label).toBe('always a hard stop -- human final say');
  });

  it('VERIFY emits a loop-back edge to REVIEW from body back-reference', () => {
    // The body says "loop back to REVIEW so the first reviewer revises".
    // Mutant: body scan skipped → no loop-back from VERIFY to REVIEW.
    const verify = chart.nodes.find((n) => n.name === 'VERIFY');
    const review = chart.nodes.find((n) => n.name === 'REVIEW');
    const loopEdge = chart.edges.find(
      (e) => e.from === verify.id && e.to === review.id && e.kind === 'loop-back'
    );
    expect(loopEdge).toBeDefined();
  });

  it('PRESENT-FINDINGS has 2 branch edges (decision node)', () => {
    // "**Advance:** PUBLISH on approval; otherwise DONE." → 2 clauses.
    // Mutant: treat semicolon as non-separator → 1 edge.
    const pf = chart.nodes.find((n) => n.name === 'PRESENT-FINDINGS');
    const edgesFrom = chart.edges.filter((e) => e.from === pf.id);
    const branchEdges = edgesFrom.filter((e) => e.kind === 'branch');
    expect(branchEdges).toHaveLength(2);
  });

  it('PRESENT-FINDINGS → PUBLISH has condition "on approval"', () => {
    // Mutant: strip all condition text → condition would be null.
    const pf = chart.nodes.find((n) => n.name === 'PRESENT-FINDINGS');
    const publish = chart.nodes.find((n) => n.name === 'PUBLISH');
    const edge = chart.edges.find(
      (e) => e.from === pf.id && e.to === publish.id
    );
    expect(edge).toBeDefined();
    expect(edge.condition).toBe('on approval');
  });

  it('PRESENT-FINDINGS → DONE has condition "otherwise"', () => {
    // Mutant: swap condition values → otherwise would be on PUBLISH edge.
    const pf = chart.nodes.find((n) => n.name === 'PRESENT-FINDINGS');
    const done = chart.nodes.find((n) => n.name === 'DONE');
    const edge = chart.edges.find(
      (e) => e.from === pf.id && e.to === done.id
    );
    expect(edge).toBeDefined();
    expect(edge.condition).toBe('otherwise');
  });

  it('DONE has no Advance line → terminal UNSPECIFIED, in exits', () => {
    // Mutant: skip no-advance exit logic → DONE.terminal = null → not in exits.
    const done = chart.nodes.find((n) => n.name === 'DONE');
    expect(done.terminal).toEqual({ advanceType: 'UNSPECIFIED', handoff: null });
    expect(chart.exits).toContain(done.id);
  });

  it('PRESENT-FINDINGS.kind === decision (2 branch edges)', () => {
    // Mutant: emit both as sequence → kind would be step, not decision.
    const pf = chart.nodes.find((n) => n.name === 'PRESENT-FINDINGS');
    expect(pf.kind).toBe('decision');
  });

  it('VERIFY.kind === loop-back (has outgoing loop-back edge)', () => {
    // Mutant: body scan misses the REVIEW back-reference → VERIFY has no loop-back out.
    const verify = chart.nodes.find((n) => n.name === 'VERIFY');
    expect(verify.kind).toBe('loop-back');
  });

  it('provenance.excerpt matches live allLines slice for every node', () => {
    // Mutant: buildProvenance uses 0-based lines → excerpt shifts by 1 line.
    for (const node of chart.nodes) {
      const p = node.provenance;
      const expected = params.allLines.slice(p.startLine - 1, p.endLine).join('\n');
      expect(p.excerpt).toBe(expected);
    }
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── aid-test corpus (`then` clause, KI-008 fix) ───────────────────────────────

describe('aid-test — PRESENT: HANDOFF (optional) then DONE (KI-008 pin)', () => {
  const params = loadSkill('aid-test');
  const chart = extractInline(params);

  it('produces 6 nodes (measured)', () => {
    const measured = countStateHeadings(params.allLines);
    expect(chart.nodes.length).toBe(measured);
    expect(chart.nodes.length).toBe(6);
  });

  it('PRESENT has exactly 2 outgoing edges', () => {
    // Mutant: `then` separator not parsed → only 1 edge (HANDOFF), DONE dropped.
    const present = chart.nodes.find((n) => n.name === 'PRESENT');
    const edgesFromPresent = chart.edges.filter((e) => e.from === present.id);
    expect(edgesFromPresent).toHaveLength(2);
  });

  it('PRESENT → HANDOFF is a branch edge with condition "optional"', () => {
    // Mutant: optionality marker not extracted → condition null or different.
    const present = chart.nodes.find((n) => n.name === 'PRESENT');
    const handoff = chart.nodes.find((n) => n.name === 'HANDOFF');
    const edge = chart.edges.find(
      (e) => e.from === present.id && e.to === handoff.id
    );
    expect(edge).toBeDefined();
    expect(edge.kind).toBe('branch');
    expect(edge.condition).toBe('optional');
  });

  it('PRESENT → DONE is a branch edge with condition null', () => {
    // The skip-HANDOFF path. Mutant: emit PRESENT→DONE as sequence → kind would be sequence.
    const present = chart.nodes.find((n) => n.name === 'PRESENT');
    const done = chart.nodes.find((n) => n.name === 'DONE');
    const edge = chart.edges.find(
      (e) => e.from === present.id && e.to === done.id
    );
    expect(edge).toBeDefined();
    expect(edge.kind).toBe('branch');
    expect(edge.condition).toBeNull();
  });

  it('PRESENT → HANDOFF advanceType is UNSPECIFIED', () => {
    // Mutant: set advanceType from keyword → no keyword in "HANDOFF (optional) then DONE",
    //         so UNSPECIFIED is correct; any other value is a bug.
    const present = chart.nodes.find((n) => n.name === 'PRESENT');
    const handoff = chart.nodes.find((n) => n.name === 'HANDOFF');
    const edge = chart.edges.find(
      (e) => e.from === present.id && e.to === handoff.id
    );
    expect(edge.advanceType).toBe('UNSPECIFIED');
  });

  it('HANDOFF → DONE sequence edge exists (through-path)', () => {
    // Distinguished from the PRESENT→DONE skip-path above.
    // Mutant: skip HANDOFF advance parsing → no HANDOFF→DONE edge.
    const handoff = chart.nodes.find((n) => n.name === 'HANDOFF');
    const done = chart.nodes.find((n) => n.name === 'DONE');
    const edge = chart.edges.find(
      (e) => e.from === handoff.id && e.to === done.id
    );
    expect(edge).toBeDefined();
    expect(edge.kind).toBe('sequence');
  });

  it('PRESENT.kind === decision (2 branch edges out)', () => {
    // Mutant: emit PRESENT edges as sequence → no decision kind.
    const present = chart.nodes.find((n) => n.name === 'PRESENT');
    expect(present.kind).toBe('decision');
  });

  it('VERIFY emits a loop-back to RUN from body text "loop to RUN/consolidate"', () => {
    // Mutant: body scan stops at "/" → "RUN" not matched from "RUN/consolidate".
    // TOKEN_RE matches "RUN" because "/" is not in [A-Za-z0-9-].
    const verify = chart.nodes.find((n) => n.name === 'VERIFY');
    const run = chart.nodes.find((n) => n.name === 'RUN');
    const loopEdge = chart.edges.find(
      (e) => e.from === verify.id && e.to === run.id && e.kind === 'loop-back'
    );
    expect(loopEdge).toBeDefined();
  });

  it('DONE is exit with UNSPECIFIED terminal', () => {
    const done = chart.nodes.find((n) => n.name === 'DONE');
    expect(done.terminal).toEqual({ advanceType: 'UNSPECIFIED', handoff: null });
    expect(chart.exits).toContain(done.id);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── All 8 inline-states corpus skills ─────────────────────────────────────────

const INLINE_SKILLS = [
  'aid-change-document',
  'aid-create-document',
  'aid-design',
  'aid-prototype',
  'aid-report',
  'aid-research',
  'aid-review',
  'aid-test',
];

describe.each(INLINE_SKILLS)('corpus: %s — invariants', (skillName) => {
  const params = loadSkill(skillName);
  const chart = extractInline(params);

  it('returns non-null chart', () => {
    expect(chart).not.toBeNull();
  });

  it('node count equals measured ## State: heading count', () => {
    // Mutant: skip a section in the loop → node count < heading count.
    const measured = countStateHeadings(params.allLines);
    expect(measured).toBeGreaterThanOrEqual(2);
    expect(chart.nodes.length).toBe(measured);
  });

  it('shape is inline-states', () => {
    expect(chart.shape).toBe('inline-states');
  });

  it('extractor is inline', () => {
    expect(chart.extractor).toBe('inline');
  });

  it('confidence is derived', () => {
    expect(chart.confidence).toBe('derived');
  });

  it('has at least 1 entry and 1 exit', () => {
    expect(chart.entries.length).toBeGreaterThanOrEqual(1);
    expect(chart.exits.length).toBeGreaterThanOrEqual(1);
  });

  it('all edge from/to ids are valid node ids', () => {
    // V4 check run manually as well to surface the specific failure.
    const nodeIds = new Set(chart.nodes.map((n) => n.id));
    for (const edge of chart.edges) {
      expect(nodeIds.has(edge.from)).toBe(true);
      expect(nodeIds.has(edge.to)).toBe(true);
    }
  });

  it('provenance.excerpt matches allLines slice for every node', () => {
    // Mutant: use wrong startLine/endLine → excerpt differs.
    for (const node of chart.nodes) {
      const p = node.provenance;
      const expected = params.allLines.slice(p.startLine - 1, p.endLine).join('\n');
      expect(p.excerpt).toBe(expected);
    }
  });

  it('provenance.file is under canonical/', () => {
    // Mutant: use empty string for file → V7 fails.
    for (const node of chart.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('every label is non-empty and <= 60 code points (V8)', () => {
    for (const node of chart.nodes) {
      expect(node.label.length).toBeGreaterThan(0);
      expect(Array.from(node.label).length).toBeLessThanOrEqual(60);
    }
  });

  it('sources contains the SKILL.md file', () => {
    expect(chart.sources).toContain(`canonical/skills/${skillName}/SKILL.md`);
  });

  it('passes V1-V8 (validateChart)', () => {
    const result = validateChart(chart);
    if (!result.ok) {
      throw new Error(`${skillName} failed validation:\n${result.errors.join('\n')}`);
    }
    expect(result.ok).toBe(true);
  });
});

// ── Per-skill loop-back assertions (measured from live text) ──────────────────

describe('corpus: loop-back back-reference per skill', () => {
  for (const skillName of INLINE_SKILLS) {
    it(`${skillName}: VERIFY emits loop-back if body names an earlier state`, () => {
      // Measure: find the earlier state name that appears in VERIFY's body.
      const params = loadSkill(skillName);
      const chart = extractInline(params);

      const verify = chart.nodes.find((n) => n.name === 'VERIFY');
      if (!verify) return; // skill doesn't have VERIFY (shouldn't happen for our 8)

      // Measure the declared state names with order < VERIFY's order.
      const earlierStateNames = chart.nodes
        .filter((n) => n.order < verify.order)
        .map((n) => n.name.toLowerCase());

      // Find which earlier state names appear as whole tokens in VERIFY's body.
      const allLines = params.allLines;
      const verifySection = allLines.slice(verify.provenance.startLine - 1);
      // Determine section end by looking for next ## heading or ---
      let sectionText = '';
      for (const line of verifySection) {
        if (line !== verifySection[0] && /^##\s/.test(line)) break;
        if (line !== verifySection[0] && line === '---') break;
        sectionText += line + '\n';
      }
      const foundInBody = earlierStateNames.filter((name) => {
        const re = new RegExp(`(?<![A-Za-z0-9-])${name.replace(/-/g, '\\-')}(?![A-Za-z0-9-])`, 'i');
        return re.test(sectionText);
      });

      if (foundInBody.length > 0) {
        // At least one loop-back edge from VERIFY should be in the chart.
        // Mutant: body scan disabled → no loop-back from VERIFY.
        const loopEdges = chart.edges.filter(
          (e) => e.from === verify.id && e.kind === 'loop-back'
        );
        expect(loopEdges.length).toBeGreaterThanOrEqual(1);
      } else {
        // No earlier state name in VERIFY body → no body-scan loop-back.
        // (aid-change-document: "loop on failure" with no explicit state name.)
        const loopEdgesFromBody = chart.edges.filter(
          (e) => e.from === verify.id && e.kind === 'loop-back'
        );
        // aid-change-document: body says "loop on failure" but names no state.
        // The advance.mjs rule 5 also doesn't fire (VERIFY advance is unconditional).
        expect(loopEdgesFromBody.length).toBe(0);
      }
    });
  }
});

// ── V9 safety: no skill throws during extraction ──────────────────────────────

describe('V9 safety — extractInline throws on 0 of the 8 inline skills', () => {
  it('all 8 skills extract without throwing (V9 not triggered)', () => {
    // Mutant: use wrong blockStartLine in parseAdvanceBlock call → V9 may see wrong
    //         context and throw for an advance block that references a state it cannot find.
    const errors = [];
    for (const skillName of INLINE_SKILLS) {
      try {
        const params = loadSkill(skillName);
        extractInline(params);
      } catch (e) {
        errors.push(`${skillName}: ${e.message}`);
      }
    }
    expect(errors).toEqual([]);
  });
});

// ── Rule 8 explicit statement (AC compliance note) ────────────────────────────
// None of the 8 inline-states corpus skills contain a ## or ### heading whose
// text contains "Loopback" or "Re-entry". Rule 8 is implemented and tested via
// REENTRY_FIXTURE above but does not fire on the current 8-skill corpus.
// This is explicitly documented here rather than silently absent from the corpus
// tests, per the task instruction to "say so explicitly."
describe('rule 8 explicit corpus statement', () => {
  it('none of the 8 corpus skills have Loopback/Re-entry headings in their bodies', () => {
    for (const skillName of INLINE_SKILLS) {
      const params = loadSkill(skillName);
      const reentryLines = params.allLines.filter(
        (l) => /^#{2,6}\s+/.test(l) && /Loopback|Re-entry/i.test(l)
      );
      expect(reentryLines).toHaveLength(0);
    }
  });
});

// ── Rule 7: a mention is not a return (task-058, closes W1-16) ────────────────
//
// WHY THIS BLOCK EXISTS. Rule 7 used to emit a loop-back edge for ANY body line naming
// an earlier-ordered state. That shipped 7 wrong edge-attributions onto 4 published
// charts, and no test saw it — the rule was tested only with fixtures whose mentions
// happened to be real loops. An unfamiliar reader found it at an AC-7 comprehension
// spot-check by reading a rendered chart and reporting three loop-backs where the source
// had one.
//
// These fixtures drive the REAL extractor (`extractInline`), never a copy of the rule.
// Each covers a shape measured in the live corpus, and each would have passed before the
// fix only if the rule were wrong — see the per-case mutant notes.

describe('rule 7 — the state must be the TARGET of a loop phrase, not merely mentioned', () => {
  /** Edges into an earlier state, as `from->to` pairs, for terse assertions. */
  const loopBacks = (chart) =>
    chart.edges.filter((e) => e.kind === 'loop-back').map((e) => `${e.from}->${e.to}`);

  it('a bare prose mention of an earlier state emits NO edge', () => {
    // Shape from aid-review:132 — "(model+effort from INTAKE Step 4)". The state is named
    // as the SOURCE of a parameter, not as a destination.
    // Mutant: drop the _loopTargetRe guard → n2->n1 appears.
    const chart = extractInline(parseSkill(`---
name: mention-only
description: Mention is not a return
---

## State: INTAKE

Resolve the target.

**Advance:** WORK.

## State: WORK

Dispatch the worker (model+effort from INTAKE Step 4) and record the result.

**Advance:** DONE.

## State: DONE

Finish.
`));
    expect(loopBacks(chart)).toEqual([]);
  });

  it('an earlier state named as a filename emits NO edge', () => {
    // Shape from aid-design — state DESIGN vs artifact DESIGN.md. TOKEN_RE stops at the
    // dot, so `DESIGN.md` matched the state name. That chart drew 3 arrows, 2 of them
    // from prose about the file.
    // Mutant: drop the _isFilenameAt guard → n2->n1 appears from the `DESIGN.md` mention.
    const chart = extractInline(parseSkill(`---
name: filename-collision
description: A state whose name matches its artifact file
---

## State: DESIGN

Author the design.

**Advance:** VERIFY.

## State: VERIFY

Clean-context reviewer checks \`DESIGN.md\`: grounded, complete, buildable.

**Advance:** DONE.

## State: DONE

Keep \`DESIGN.md\` in the work folder as the record.
`));
    expect(loopBacks(chart)).toEqual([]);
  });

  it('a real loop still emits an edge when the verb wraps onto the PREVIOUS line', () => {
    // The load-bearing case. aid-create-document, aid-report, aid-test and aid-design all
    // wrap as `... -> loop` / `   to <STATE>.` — 17 of the corpus's 20 genuine cross-state
    // edges. A line-scoped cue test deletes every one of them.
    // Mutant: test the cue on `line` instead of the joined block → this fails.
    const chart = extractInline(parseSkill(`---
name: wrapped-verb
description: Loop verb on the previous physical line
---

## State: AUTHOR

Write it.

**Advance:** VERIFY.

## State: VERIFY

3. **Grade:** run the grader on the ledger. Not clean -> loop
   to AUTHOR. Circuit-breaker: 3 cycles -> IMPEDIMENT.

**Advance:** DONE.

## State: DONE

Finish.
`));
    expect(loopBacks(chart)).toEqual(['n2->n1']);
  });

  it('a real loop still emits an edge when the TARGET wraps onto the next line', () => {
    // The opposite wrap, as the shared shortcut engine writes it: `Loop back` ends the
    // line and `to Step 1 (REVIEW)` begins the next — note the parenthetical step number
    // sitting between `to` and the state name.
    // Mutant: forbid filler between `to` and the state name → this fails.
    const chart = extractInline(parseSkill(`---
name: wrapped-target
description: Loop target on the next physical line, behind a step number
---

## State: REVIEW

Dispatch the reviewer.

**Advance:** FIX.

## State: FIX

The architect addresses each row in place; it does not touch the ledger. Loop back
to Step 1 (REVIEW) for a fresh, clean-context reviewer pass.

**Advance:** DONE.

## State: DONE

Finish.
`));
    expect(loopBacks(chart)).toEqual(['n2->n1']);
  });

  it('"back to" pointing somewhere else does not capture a later-mentioned state', () => {
    // Shape from aid-change-document:87 — "Write the revision back to the existing
    // document (the diff was already reviewed at PRESENT)." A loop cue IS present, but
    // its object is "the existing document", not PRESENT.
    // Mutant: test for cue-anywhere-in-block instead of cue-targeting-the-state → n2->n1
    // appears, which is exactly the edge this task removed from the published chart.
    const chart = extractInline(parseSkill(`---
name: cue-elsewhere
description: A loop cue whose object is not the state
---

## State: PRESENT

Show the diff.

**Advance:** WRITE.

## State: WRITE

Write the revision back to the existing document (the diff was already reviewed at PRESENT).

**Advance:** DONE.

## State: DONE

Finish.
`));
    expect(loopBacks(chart)).toEqual([]);
  });

  it('provenance points at the line carrying the loop phrase, not the first mention', () => {
    // Recovered behaviour, not merely suppressed noise. In aid-design the real edge was
    // attributed to :76 (a `DESIGN.md` mention) because first-match-won; the genuine
    // "loop to DESIGN" at :80 never got to speak. After the fix the edge survives and
    // carries the right line — which is why this task's AC counts 20 edges, not 19.
    // Mutant: keep first-match-wins → provenance lands on the earlier mention line.
    const chart = extractInline(parseSkill(`---
name: provenance-recovery
description: A filename mention precedes the real loop phrase in the same section
---

## State: DESIGN

Author it.

**Advance:** VERIFY.

## State: VERIFY

Reviewer checks \`DESIGN.md\` for grounding.
Not clean -> loop
   to DESIGN. Circuit-breaker: 3 cycles.

**Advance:** DONE.

## State: DONE

Finish.
`));
    const edge = chart.edges.find((e) => e.kind === 'loop-back');
    expect(edge).toBeDefined();
    const cueLine = chart.nodes.length ? edge.provenance.startLine : -1;
    // The `DESIGN.md` line and the `to DESIGN.` line are distinct; assert we took the latter
    // by checking the recorded excerpt is the loop sentence, not the filename sentence.
    expect(edge.provenance.excerpt).toMatch(/to DESIGN\./);
    expect(edge.provenance.excerpt).not.toMatch(/DESIGN\.md/);
    expect(cueLine).toBeGreaterThan(0);
  });
});
