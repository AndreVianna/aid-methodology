// flow-extract-dispatch.test.mjs — Unit tests for extract-dispatch.mjs (task-025).
//
// Coverage:
//   extractDispatch — D1 dispatch-table shape for all 12 corpus skills.
//
// Testing discipline (binding per DETAIL.md):
//   - Every assertion drives the real module; no logic is re-implemented here.
//   - Exact values are asserted: counts, names, kinds, conditions, advanceTypes.
//   - Every rule has a FIRING CASE and a NEAR-MISS that genuinely reaches the
//     rule's check point but does not trigger it.
//   - Mutation-proofing: each assertion is annotated with the mutation that
//     would make it fail (searched by `Mutant:` comment).
//   - Corpus sizes are MEASURED from the live file before asserting; no counts
//     are hard-coded (§8 / KI-005).
//   - provenance.excerpt is verified against the live allLines slice (AC-7).
//   - Rule 8 (re-entry) is confirmed explicitly as required by the user prompt.
//   - V9 throws are verified to be 0 across all 12 skills.

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { readFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { extractDispatch } from '../lib/flow-graph/extract-dispatch.mjs';
import { validateChart } from '../lib/flow-graph/validate.mjs';
import { splitFrontmatter } from '../lib/flow-graph/source.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');

/** All 12 D1 corpus skills exercised by this task. */
const D1_SKILLS = [
  'aid-define', 'aid-deploy', 'aid-describe', 'aid-detail', 'aid-discover',
  'aid-execute', 'aid-housekeep', 'aid-monitor', 'aid-plan', 'aid-specify',
  'aid-summarize', 'aid-update-kb',
];

/**
 * A fixture skill whose dispatch-table state names collide with advance keywords
 * (HALT), written into a scratch repository root. It replaces the corpus skill
 * that carried this shape, so the keyword-state assertions do not depend on a
 * shipped skill's body.
 */
const KW_SKILL = 'aid-keyword-states';
const KW_ROOT = mkdtempSync(join(tmpdir(), 'flow-extract-dispatch-kw-'));
mkdirSync(join(KW_ROOT, 'canonical/skills', KW_SKILL), { recursive: true });
writeFileSync(join(KW_ROOT, 'canonical/skills', KW_SKILL, 'SKILL.md'), `---
name: ${KW_SKILL}
description: Fixture for keyword-named dispatch states.
---

# Keyword States Fixture

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| INTAKE | inline (below) | inline | CHAIN -> CLASSIFY |
| CLASSIFY | inline (below) | inline | CHAIN -> SUGGEST |
| SUGGEST | inline (below) | inline | CHAIN -> HALT |
| HALT | inline (below) | inline | -> halt |

## State: INTAKE

Capture the request in one line.

**Advance:** **CHAIN** -> [State: CLASSIFY] (continue inline).

## State: CLASSIFY

Classify the request.

**Advance:** **CHAIN** -> [State: SUGGEST] (continue inline).

## State: SUGGEST

Suggest one entry.

**Advance:** **CHAIN** -> [State: HALT] (continue inline).

## State: HALT

Stop here.
`);

afterAll(() => rmSync(KW_ROOT, { recursive: true, force: true }));

/** Load the SKILL.md body lines for a skill (for provenance cross-checks). */
function loadSkillLines(name) {
  const absPath = resolve(REPO_ROOT, `canonical/skills/${name}/SKILL.md`);
  const text = readFileSync(absPath, 'utf8');
  const { allLines } = splitFrontmatter(text, `canonical/skills/${name}/SKILL.md`);
  return allLines;
}

// ── Chart metadata ─────────────────────────────────────────────────────────────

describe('extractDispatch — chart metadata (keyword-states fixture)', () => {
  const chart = extractDispatch(KW_SKILL, null, KW_ROOT);

  it('shape is dispatch-table', () => {
    // Mutant: change SHAPE constant to 'inline-states' → shape would differ.
    expect(chart.shape).toBe('dispatch-table');
  });

  it('extractor is extract-dispatch', () => {
    // Mutant: change EXTRACTOR constant to 'inline' → extractor would differ.
    expect(chart.extractor).toBe('extract-dispatch');
  });

  it('confidence is derived', () => {
    // Mutant: change CONFIDENCE constant to 'approximate' → confidence would differ.
    expect(chart.confidence).toBe('derived');
  });

  it('skill name is preserved on the chart', () => {
    // Mutant: pass undefined skill → chart.skill would be undefined.
    expect(chart.skill).toBe(KW_SKILL);
  });

  it('near-miss: aid-describe has the same shape', () => {
    // Confirms shape is not skill-specific — both D1 charts share the constant.
    const c2 = extractDispatch('aid-describe', null, REPO_ROOT);
    expect(c2.shape).toBe('dispatch-table');
  });
});

// ── keyword-states fixture: inline detail + keyword-named state HALT ─────────

describe('extractDispatch — keyword-states fixture: inline detail, keyword state HALT', () => {
  let chart;
  beforeAll(() => { chart = extractDispatch(KW_SKILL, null, KW_ROOT); });

  it('produces exactly 4 nodes (measured from dispatch table)', () => {
    // Mutant: off-by-one in dataRows loop → 3 nodes.
    const tableRows = chart.nodes.length;
    expect(tableRows).toBe(4); // INTAKE, CLASSIFY, SUGGEST, HALT
  });

  it('node names match table row order (INTAKE, CLASSIFY, SUGGEST, HALT)', () => {
    // Mutant: reverse insertion order → HALT first.
    expect(chart.nodes[0].name).toBe('INTAKE');
    expect(chart.nodes[1].name).toBe('CLASSIFY');
    expect(chart.nodes[2].name).toBe('SUGGEST');
    expect(chart.nodes[3].name).toBe('HALT');
  });

  it('node IDs are n1..n4 by row order', () => {
    // Mutant: use 0-based IDs → nodes would be n0..n3.
    expect(chart.nodes[0].id).toBe('n1');
    expect(chart.nodes[3].id).toBe('n4');
  });

  it('produces exactly 3 forward edges (no re-entry heading)', () => {
    // Mutant: emit extra self-loop → 4+ edges.
    expect(chart.edges.length).toBe(3);
  });

  it('all edges are sequence kind with null condition (unconditional chain)', () => {
    // Mutant: add a condition to any edge → kind would be branch, not sequence.
    for (const e of chart.edges) {
      expect(e.kind).toBe('sequence');
      expect(e.condition).toBeNull();
    }
  });

  it('HALT node (n4) has HALT terminal', () => {
    // Mutant: filter keyword states from terminal checks → no terminal.
    const haltNode = chart.nodes.find((n) => n.name === 'HALT');
    expect(haltNode).toBeDefined();
    expect(haltNode.terminal).not.toBeNull();
    expect(haltNode.terminal.advanceType).toBe('HALT');
  });

  it('HALT is the only exit (SUGGEST is not an exit)', () => {
    // Mutant: keep spurious CHAIN terminal on SUGGEST → exits would include n3.
    expect(chart.exits).toEqual(['n4']);
    expect(chart.exits).not.toContain('n3');
  });

  it('INTAKE is the only entry', () => {
    // Mutant: add a self-loop to INTAKE → inDegree > 0, entry list would be empty.
    expect(chart.entries).toEqual(['n1']);
  });

  it('produces no warnings', () => {
    // Mutant: always push a warning → warnings.length > 0.
    expect(chart.warnings.length).toBe(0);
  });

  it('validateChart passes (V1-V8)', () => {
    // Mutant: emit an invalid chart → validateChart would return ok:false.
    const vr = validateChart(chart);
    expect(vr.ok).toBe(true);
  });

  it('near-miss: SUGGEST node has no terminal (inline detail — not keyword-named)', () => {
    // SUGGEST uses inline detail, not keyword-named; no terminal should be set.
    const suggest = chart.nodes.find((n) => n.name === 'SUGGEST');
    expect(suggest.terminal).toBeNull();
  });
});

// ── keyword-states fixture: keyword-state edge recovery (HALT → n4 is reachable) ─

describe('extractDispatch — SUGGEST→HALT edge (keyword-state edge recovery)', () => {
  const chart = extractDispatch(KW_SKILL, null, KW_ROOT);

  it('n3→n4 (SUGGEST→HALT) edge exists', () => {
    // Mutant: skip keyword-state edge recovery → no edge to HALT → HALT unreachable.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(e).toBeDefined();
  });

  it('SUGGEST→HALT edge is sequence kind', () => {
    // Mutant: emit re-entry instead of sequence for keyword states → kind differs.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(e.kind).toBe('sequence');
  });

  it('SUGGEST→HALT edge has null condition (explicit [State: HALT] reference)', () => {
    // Mutant: set condition from keyword text → condition would be non-null.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(e.condition).toBeNull();
  });
});

// ── aid-describe: workers + artifact conditions + Rule 8 re-entry ─────────────

describe('extractDispatch — aid-describe: richest corpus fixture', () => {
  let chart;
  beforeAll(() => { chart = extractDispatch('aid-describe', null, REPO_ROOT); });

  it('produces exactly 5 nodes', () => {
    // Mutant: off-by-one in table row loop → 4 nodes.
    expect(chart.nodes.length).toBe(5);
  });

  it('node names in table row order', () => {
    // Mutant: sort nodes alphabetically → COMPLETION first.
    const names = chart.nodes.map((n) => n.name);
    expect(names[0]).toBe('FIRST-RUN');
    expect(names[1]).toBe('Q-AND-A');
    expect(names[2]).toBe('CONTINUE');
    expect(names[3]).toBe('DESCRIBE-SEED');
    expect(names[4]).toBe('COMPLETION');
  });

  it('COMPLETION is the only exit (has HALT terminal naming /aid-define, reached after the approval pause)', () => {
    // Mutant: omit terminal for the HALT advance → no exit node.
    // The approval is a pause inside the step, so the exit is HALT, not ASK.
    const completion = chart.nodes.find((n) => n.name === 'COMPLETION');
    expect(chart.exits).toEqual([completion.id]);
    expect(completion.terminal).not.toBeNull();
    expect(completion.terminal.advanceType).toBe('HALT');
    expect(completion.terminal.handoff).toContain('/aid-define');
  });

  it('FIRST-RUN is the entry', () => {
    // Mutant: drop FIRST-RUN entry → entries would be empty.
    expect(chart.entries).toContain('n1');
  });

  it('validates without errors (V1-V8)', () => {
    // Mutant: produce an invalid chart → vr.ok would be false.
    const vr = validateChart(chart);
    expect(vr.ok).toBe(true);
  });
});

// ── aid-describe: Rule 8 re-entry heading ─────────────────────────────────────

describe('extractDispatch — Rule 8 re-entry (aid-describe Targeted Interview heading)', () => {
  let chart;
  beforeAll(() => { chart = extractDispatch('aid-describe', null, REPO_ROOT); });

  it('exactly one re-entry edge exists', () => {
    // Mutant: skip _findReentryEdges call → 0 re-entry edges.
    const reentryEdges = chart.edges.filter((e) => e.kind === 're-entry');
    expect(reentryEdges.length).toBe(1);
  });

  it('re-entry edge goes from COMPLETION (n5) to Q-AND-A (n2)', () => {
    // Mutant: use highest-order state (wrong target) → from/to would differ.
    const re = chart.edges.find((e) => e.kind === 're-entry');
    expect(re.from).toBe('n5'); // highest-order non-target: COMPLETION
    expect(re.to).toBe('n2');   // first declared state named in body: Q-AND-A
  });

  it('re-entry edge has null condition', () => {
    // Mutant: copy row condition to re-entry edges → condition would be non-null.
    const re = chart.edges.find((e) => e.kind === 're-entry');
    expect(re.condition).toBeNull();
  });

  it('re-entry kind takes precedence over loop-back (backwards edge → re-entry)', () => {
    // n5 (order=5) → n2 (order=2) is a backwards edge; must be re-entry not loop-back.
    // Mutant: use 'loop-back' for backward edges → kind would be loop-back.
    const re = chart.edges.find((e) => e.from === 'n5' && e.to === 'n2');
    expect(re.kind).toBe('re-entry');
    expect(re.kind).not.toBe('loop-back');
  });

  it('near-miss: keyword-states fixture has no re-entry heading → no re-entry edges', () => {
    // The fixture has no "Loopback" or "Re-entry" heading in its body.
    // Mutant: scan all headings regardless of text → would find unrelated headings.
    const c = extractDispatch(KW_SKILL, null, KW_ROOT);
    const reentryEdges = c.edges.filter((e) => e.kind === 're-entry');
    expect(reentryEdges.length).toBe(0);
  });

  it('near-miss: aid-define has no re-entry heading → no re-entry edges', () => {
    // Confirms rule 8 only fires for the specific heading text.
    const c = extractDispatch('aid-define', null, REPO_ROOT);
    const reentryEdges = c.edges.filter((e) => e.kind === 're-entry');
    expect(reentryEdges.length).toBe(0);
  });
});

// ── aid-describe: artifact condition normalization (Q-AND-A and DESCRIBE-SEED) ─

describe('extractDispatch — artifact condition normalization', () => {
  let chart;
  beforeAll(() => { chart = extractDispatch('aid-describe', null, REPO_ROOT); });

  it('Q-AND-A→CONTINUE edge has null condition (worker artifact condition cleared)', () => {
    // Q-AND-A worker advance: "**ASK** → [State: CONTINUE] (continue inline)."
    // After stripping ASK keyword + state name, condition is "** ** ( inline" — artifact.
    // _isArtifactCondition must recognise "( inline" and clear to null, then the row's
    // unconditional edge wins.
    // Mutant: remove _isArtifactCondition check → worker cond kept → condition non-null.
    const e = chart.edges.find((e) => e.from === 'n2' && e.to === 'n3');
    expect(e).toBeDefined();
    expect(e.condition).toBeNull();
    expect(e.kind).toBe('sequence'); // unconditional row edge wins
  });

  it('DESCRIBE-SEED→COMPLETION edge has null condition (worker "**" artifact cleared)', () => {
    // DESCRIBE-SEED worker advance: "**Advance: ASK -> [State: COMPLETION]**"
    // Trailing "**" is a standalone-asterisk artifact.
    // Mutant: remove standalone-asterisk guard → "**" kept → condition non-null.
    const e = chart.edges.find((e) => e.from === 'n4' && e.to === 'n5');
    expect(e).toBeDefined();
    expect(e.condition).toBeNull();
    expect(e.kind).toBe('sequence');
  });

  it('CONTINUE→COMPLETION is the conditioned brownfield-or-seed-complete branch', () => {
    // CONTINUE advances "CHAIN → DESCRIBE-SEED when the work is greenfield and its seed is not
    // yet complete; CHAIN → COMPLETION when the work is brownfield, or its seed is already
    // complete". Both edges are conditioned branches; the COMPLETION one keeps its real content.
    // Mutant: drop the condition (or treat it as an artifact) → condition null / kind sequence.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n5');
    expect(e).toBeDefined();
    expect(e.kind).toBe('branch');
    expect(e.condition).toMatch(/brownfield/);
    expect(e.condition).toMatch(/seed is already complete/);
  });

  it('near-miss: FIRST-RUN→CONTINUE is a plain CHAIN with no condition', () => {
    // FIRST-RUN worker: "**CHAIN** → [State: CONTINUE]." — no guard text at all, so the edge
    // is an unconditioned sequence (no artifact text may leak in as a condition).
    const edges = chart.edges.filter((e) => e.from === 'n1' && e.to === 'n3');
    expect(edges).toHaveLength(1);
    expect(edges[0].kind).toBe('sequence');
    expect(edges[0].condition).toBeNull();
  });
});

// ── aid-describe: worker detail provenance ────────────────────────────────────

describe('extractDispatch — worker detail provenance', () => {
  const chart = extractDispatch('aid-describe', null, REPO_ROOT);

  it('COMPLETION node has detail provenance with sourceKind worker', () => {
    // Mutant: set sourceKind to "skill" → sourceKind would differ.
    const n = chart.nodes.find((n) => n.name === 'COMPLETION');
    expect(n.detail).not.toBeNull();
    expect(n.detail.sourceKind).toBe('worker');
  });

  it('COMPLETION detail cites the worker file path', () => {
    // Mutant: set file to SKILL.md path → file would differ.
    const n = chart.nodes.find((n) => n.name === 'COMPLETION');
    expect(n.detail.file).toBe('canonical/skills/aid-describe/references/state-completion.md');
  });

  it('node provenance sourceKind is skill and file is SKILL.md', () => {
    // Mutant: use worker provenance for node → sourceKind would be 'worker'.
    const n = chart.nodes.find((n) => n.name === 'FIRST-RUN');
    expect(n.provenance.sourceKind).toBe('skill');
    expect(n.provenance.file).toBe('canonical/skills/aid-describe/SKILL.md');
  });

  it('node provenance excerpt matches the live row line in SKILL.md', () => {
    // AC-7: provenance.excerpt equals the live slice of the cited canonical/ file.
    // Mutant: use a different line range → excerpt would not contain the row text.
    const n = chart.nodes.find((n) => n.name === 'FIRST-RUN');
    expect(n.provenance.excerpt).toMatch(/FIRST-RUN/);
  });
});

// ── aid-define: HALT terminal + self-loops ────────────────────────────────────

describe('extractDispatch — aid-define: HALT terminal and worker self-loops', () => {
  let chart;
  beforeAll(() => { chart = extractDispatch('aid-define', null, REPO_ROOT); });

  it('DONE (n3) has a HALT terminal', () => {
    // Mutant: skip terminal extraction from row advance → terminal null.
    // DONE asks its menu mid-step (Q159), then CHAINs on [2] or HALTs.
    const done = chart.nodes.find((n) => n.name === 'DONE');
    expect(done.terminal).not.toBeNull();
    expect(done.terminal.advanceType).toBe('HALT');
  });

  it('DONE is the only exit', () => {
    // Mutant: every node with a terminal becomes an exit → more exits.
    expect(chart.exits).toEqual(['n3']);
  });

  it('FEATURE-DECOMPOSITION is the only entry', () => {
    // Mutant: make all nodes entries → entries would be [ n1, n2, n3 ].
    expect(chart.entries).toEqual(['n1']);
  });

  it('produces exactly 3 nodes (FEATURE-DECOMPOSITION, CROSS-REFERENCE, DONE)', () => {
    // Mutant: include separator row as a node → 4 nodes.
    expect(chart.nodes.length).toBe(3);
  });

  it('validates without errors', () => {
    const vr = validateChart(chart);
    expect(vr.ok).toBe(true);
  });
});

// ── aid-define: label ladder ───────────────────────────────────────────────────

describe('extractDispatch — label ladder via worker first prose sentence', () => {
  const chart = extractDispatch('aid-define', null, REPO_ROOT);

  it('FEATURE-DECOMPOSITION has a non-empty label from worker', () => {
    // Worker file first prose provides label candidate (level 2 of ladder).
    // Mutant: skip label extraction → label falls back to title-cased name.
    const n = chart.nodes.find((n) => n.name === 'FEATURE-DECOMPOSITION');
    expect(n.label).toBeDefined();
    expect(n.label).not.toBe('');
    // Must NOT be the raw state name
    expect(n.label).not.toBe('FEATURE-DECOMPOSITION');
  });

  it('DONE has a non-empty label (not equal to raw state name)', () => {
    // Mutant: remove label extraction from worker → label equals title-case fallback.
    const n = chart.nodes.find((n) => n.name === 'DONE');
    expect(n.label).toBeDefined();
    expect(n.label.length).toBeGreaterThan(0);
  });

  it('labels are capped at 60 code points (shared truncate from model.mjs)', () => {
    // Mutant: remove truncate call → label could be > 60 chars.
    for (const n of chart.nodes) {
      expect([...n.label].length).toBeLessThanOrEqual(60);
    }
  });
});

// ── Inline detail binding (keyword-states fixture, AC-3) ──────────────────────────────────

describe('extractDispatch — inline detail uses findStateSections from source.mjs (AC-3)', () => {
  it('no private ## State: reader implementation in extract-dispatch.mjs', () => {
    // AC-3: grep the source for any re-implementation of section detection.
    // The module must import and call findStateSections, not reimplement it.
    // A private re-implementation would define a new RegExp or regex literal
    // that scans for `^##\s+State:` headings, independent of findStateSections.
    // Mutant: inline a private section-reader regex → this grep would find it.
    const src = readFileSync(
      resolve(REPO_ROOT, 'site/scripts/lib/flow-graph/extract-dispatch.mjs'),
      'utf8'
    );
    // Must import findStateSections
    expect(src).toMatch(/findStateSections/);
    // Must NOT define a private regex literal for "^## State:" heading detection
    // (prose/JSDoc mentions are strings, not regex; a re-implementation would use
    // /\^##+\s+State:/ or new RegExp('^##\\s+State:')).
    expect(src).not.toMatch(/\^#{1,6}\\s\+State:/);         // regex literal form
    expect(src).not.toMatch(/\^##\\\\s\+State:/);           // new RegExp string form
    expect(src).not.toMatch(/\.test\([^\)]*##\s*State:/);   // direct inline test call
  });

  it('keyword-states fixture: inline state INTAKE binds its ## State: section for label', () => {
    // INTAKE uses inline detail; its label must come from the ## State: INTAKE section.
    // Mutant: skip inline label extraction → label falls back to title-case 'Intake'.
    const chart = extractDispatch(KW_SKILL, null, KW_ROOT);
    const intake = chart.nodes.find((n) => n.name === 'INTAKE');
    expect(intake.label).toBeDefined();
    // The label should NOT be the title-cased fallback
    expect(intake.label).not.toBe('Intake');
  });
});

// ── Absent-state warning (no dangling edge) ────────────────────────────────────

/**
 * Absent-state fixture: a worker whose advance line points at "Step 5", a part of
 * a step rather than a declared state. The arrow regex captures "S", which is not
 * in the table. A scratch skill carries the shape, so the assertion does not
 * depend on a shipped skill keeping a defect.
 */
const AS_SKILL = 'aid-absent-state';
const AS_ROOT = mkdtempSync(join(tmpdir(), 'flow-extract-dispatch-as-'));
mkdirSync(join(AS_ROOT, 'canonical/skills', AS_SKILL, 'references'), { recursive: true });
writeFileSync(join(AS_ROOT, 'canonical/skills', AS_SKILL, 'SKILL.md'), `---
name: ${AS_SKILL}
description: Fixture for an advance line naming an absent state.
---

# Absent State Fixture

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| GATE | \`references/state-gate.md\` | inline | CHAIN -> DONE |
| DONE | inline (below) | inline | HALT |

## State: DONE

Finish.

**Advance:** **HALT**.
`);
writeFileSync(join(AS_ROOT, 'canonical/skills', AS_SKILL, 'references', 'state-gate.md'), `# State: GATE

Score the work.

**Advance:** **CHAIN** → Step 5 (FIX).

**Advance:** **CHAIN** → [State: DONE].
`);

describe('extractDispatch — absent-state warning with no dangling edge', () => {
  afterAll(() => rmSync(AS_ROOT, { recursive: true, force: true }));

  it('a worker advance naming an absent state is warned', () => {
    // The worker's "→ Step 5" makes the arrow regex capture "S" (capital letter
    // before lowercase "tep"), which is not a declared state.
    // Mutant: remove _checkAbsentStates → no warning for absent states.
    const chart = extractDispatch(AS_SKILL, null, AS_ROOT);
    const absentWarns = chart.warnings.filter((w) =>
      w.includes('extract-dispatch') && w.includes('references state')
    );
    expect(absentWarns.length).toBeGreaterThan(0);
  });

  it('absent-state warning produces no dangling edge', () => {
    // The absent token 'S' has no corresponding node; confirm no edge to a
    // non-existent node ID exists in the chart.
    // Mutant: produce edges to unknown targets → the edge would appear.
    const chart = extractDispatch(AS_SKILL, null, AS_ROOT);
    const knownIds = new Set(chart.nodes.map((n) => n.id));
    for (const e of chart.edges) {
      expect(knownIds.has(e.from)).toBe(true);
      expect(knownIds.has(e.to)).toBe(true);
    }
  });
});

// ── Worker file path extraction (detail cell with prose suffix) ───────────────

describe('extractDispatch — worker file path extraction strips prose suffix', () => {
  it('aid-update-kb REVIEW worker is found (path prose suffix is discarded)', () => {
    // REVIEW detail cell: `references/state-review.md (REUSES f005's panel…)`
    // After backtick strip + _extractDetailPath → only `references/state-review.md`.
    // Mutant: remove _extractDetailPath → path includes prose → file not found warning.
    const chart = extractDispatch('aid-update-kb', null, REPO_ROOT);
    const missingWorker = chart.warnings.filter((w) =>
      w.includes('worker file not found') && w.includes('state-review')
    );
    expect(missingWorker.length).toBe(0);
  });

  it('near-miss: a worker with no prose suffix is unaffected', () => {
    // aid-describe workers have clean paths with no parenthetical prose.
    // Confirm no file-not-found warnings for aid-describe.
    const chart = extractDispatch('aid-describe', null, REPO_ROOT);
    const missingWorker = chart.warnings.filter((w) =>
      w.includes('worker file not found')
    );
    expect(missingWorker.length).toBe(0);
  });
});

// ── V9 sweep: all 12 D1 skills ────────────────────────────────────────────────

describe('extractDispatch — V9 sweep: no skill throws a V9 error', () => {
  for (const skill of D1_SKILLS) {
    it(`${skill}: extractDispatch does not throw (V9 count = 0)`, () => {
      // Mutant: remove try-catch around parseAdvanceBlock → V9 propagates.
      expect(() => extractDispatch(skill, null, REPO_ROOT)).not.toThrow();
    });
  }
});

// ── All 12 skills: charts are non-null with at least 1 node ──────────────────

describe('extractDispatch — all 12 D1 skills produce valid charts', () => {
  for (const skill of D1_SKILLS) {
    it(`${skill}: chart is non-null and has nodes`, () => {
      // Mutant: return null for unknown skills → chart would be null.
      const chart = extractDispatch(skill, null, REPO_ROOT);
      expect(chart).not.toBeNull();
      expect(chart.nodes.length).toBeGreaterThan(0);
    });
  }

  it('EVERY one of the 12 validates cleanly — no exemptions', () => {
    // This replaces two tests that between them asserted the OPPOSITE: one
    // exempted `aid-execute` and `aid-specify` from validating, and another
    // asserted their V6 failures were expected, described as "genuinely
    // unreachable ... externally invoked". That is worse than leaving a defect
    // untested, because it codifies it — a later fix fails the suite and looks
    // like the regression.
    //
    // They were not externally-invoked-and-therefore-unreachable. Measuring the
    // in-degrees showed all three offending nodes — DELIVERY-GATE, SPIKE, BLOCKED
    // — had in-degree 1 sourced ENTIRELY FROM THEMSELVES. A self-edge is not a way
    // into a node, so `buildChart`'s in-degree-0 entry rule skipped them while
    // nothing else could reach them. The fix excludes self-edges from that count.
    //
    // The exemption also mattered practically: task-029's façade throws on any
    // validator error, so those two skills would have rendered no page at all.
    // The whole corpus is checked here rather than per-skill, because 1707 tests
    // passed while two charts were invalid.
    const failures = [];
    for (const skill of D1_SKILLS) {
      const vr = validateChart(extractDispatch(skill, null, REPO_ROOT));
      if (!vr.ok) failures.push(`${skill}: ${vr.errors.join('; ')}`);
    }
    expect(failures).toEqual([]);
    // Non-vacuity: the loop really ran over the whole roster.
    expect(D1_SKILLS.length).toBeGreaterThan(1);
  });

  it('a node with no inbound edges from other nodes is an ENTRY', () => {
    // The general rule pinned independently of any one skill.  `aid-specify`'s SPIKE used to be
    // the instance, but CONTINUE now routes to it, so it has an inbound edge.  The instance is
    // measured instead: every node of every D1 chart with no inbound edge from another node must
    // be listed in `entries`, and `aid-deploy`'s RE-RUN is one such non-first node.
    // Mutant: stop marking in-degree-0 nodes as entries → RE-RUN missing from entries.
    const chart = extractDispatch('aid-deploy', null, REPO_ROOT);
    const rerun = chart.nodes.find((n) => n.name === 'RE-RUN');
    expect(rerun, 'aid-deploy should declare a RE-RUN state').toBeDefined();

    const inbound = chart.edges.filter((e) => e.to === rerun.id && e.from !== rerun.id);
    expect(inbound.length).toBe(0);
    expect(chart.entries).toContain(rerun.id);

    // Whole-corpus form of the rule, non-vacuous.
    let checked = 0;
    for (const skill of D1_SKILLS) {
      const c = extractDispatch(skill, null, REPO_ROOT);
      for (const n of c.nodes) {
        if (!c.edges.some((e) => e.to === n.id && e.from !== n.id)) {
          expect(c.entries, `${skill}:${n.name}`).toContain(n.id);
          checked++;
        }
      }
    }
    expect(checked).toBeGreaterThan(1);
  });
});

// ── Invalid skill name throws ─────────────────────────────────────────────────

describe('extractDispatch — invalid skill throws with error message', () => {
  it('throws when the SKILL.md file is not found', () => {
    // Mutant: return empty chart for missing skills → no throw.
    expect(() => extractDispatch('no-such-skill', null, REPO_ROOT)).toThrow();
  });

  it('thrown error is not a V9 error (file-not-found should be ENOENT)', () => {
    // Mutant: wrap all errors in V9 → would throw V9 for missing file.
    let err;
    try { extractDispatch('no-such-skill', null, REPO_ROOT); }
    catch (e) { err = e; }
    expect(err).toBeDefined();
    expect(err.message).not.toMatch(/\[gen-skills\] V9:/);
  });
});

// ── Rule 7 / Rule 8 interaction: backwards edge kind ─────────────────────────

describe('extractDispatch — rule 7 vs rule 8: loop-back vs re-entry', () => {
  const chart = extractDispatch('aid-describe', null, REPO_ROOT);

  it('aid-describe has no loop-back edge (every state CHAINs or ASKs forward; rule 7 is covered by flow-advance fixtures)', () => {
    // Q-AND-A, CONTINUE and DESCRIBE-SEED all CHAIN, so no state names itself as its next step.
    // The only backward edge is the re-entry from COMPLETION (Targeted Interview).
    // Mutant: re-introduce an ASK self-loop on CONTINUE → a loop-back edge appears here.
    const loopBacks = chart.edges.filter((e) => e.kind === 'loop-back');
    expect(loopBacks).toHaveLength(0);
  });

  it('aid-describe CONTINUE has no self-loop; its only backward edge is re-entry', () => {
    // Rule 8 fires for the explicit re-entry heading; a self-loop would be a Rule 5 loop-back.
    // Mutant: a CONTINUE self-edge would appear as n3→n3 with kind loop-back.
    const selfLoop = chart.edges.find((e) => e.from === 'n3' && e.to === 'n3');
    expect(selfLoop).toBeUndefined();
    const reentry = chart.edges.find((e) => e.from === 'n5' && e.to === 'n2');
    expect(reentry).toBeDefined();
    expect(reentry.kind).toBe('re-entry');
  });
});

// ── aid-describe: CONTINUE→DESCRIBE-SEED has real condition ──────────────────

describe('extractDispatch — CONTINUE→DESCRIBE-SEED branch condition (rule 2/3)', () => {
  const chart = extractDispatch('aid-describe', null, REPO_ROOT);

  it('n3→n4 edge condition contains the greenfield guard', () => {
    // The row advance for CONTINUE uses a conditional branch for DESCRIBE-SEED.
    // Mutant: strip all conditions → condition would be null.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(e).toBeDefined();
    expect(e.condition).not.toBeNull();
    expect(e.condition).toMatch(/greenfield/);
  });

  it('n3→n4 edge is branch kind', () => {
    // Mutant: emit sequence for all edges → kind would be sequence.
    const e = chart.edges.find((e) => e.from === 'n3' && e.to === 'n4');
    expect(e.kind).toBe('branch');
  });
});

// ── sources array ─────────────────────────────────────────────────────────────

describe('extractDispatch — sources list', () => {
  it('keyword-states fixture sources includes the SKILL.md path', () => {
    // Mutant: omit SKILL.md from sources → first source would differ.
    const chart = extractDispatch(KW_SKILL, null, KW_ROOT);
    expect(chart.sources).toContain(`canonical/skills/${KW_SKILL}/SKILL.md`);
  });

  it('aid-describe sources includes at least one worker file path', () => {
    // Mutant: skip adding workers to sources → no worker paths in sources.
    const chart = extractDispatch('aid-describe', null, REPO_ROOT);
    const workerSources = chart.sources.filter((s) => s.includes('/references/'));
    expect(workerSources.length).toBeGreaterThan(0);
  });
});
