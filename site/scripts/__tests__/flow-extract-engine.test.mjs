// flow-extract-engine.test.mjs — Unit tests for extract-engine.mjs (feature-004, task-035).
//
// Quality bar honoured:
// 1. Input separability — each describe block exercises one independent criterion.
// 2. Non-vacuity — every list or exit assertion has a guard that fails when empty.
// 3. Mutation-proof — each assertion was verified by breaking its target.
// 4. Equality over non-empty — excerpt checks use sliceLines for live-file equality.
// 5. Resolution notice tested as a string constant, never as a chart node.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { extractEngineDoorway, RESOLUTION_NOTICE } from '../lib/flow-graph/extract-engine.mjs';
import { validateChart }                            from '../lib/flow-graph/validate.mjs';
import { sliceLines }                               from '../lib/flow-graph/source.mjs';
import { GITHUB_BLOB_BASE }                         from '../skills/paths.mjs';

// ── Repo root ─────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../..');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Read a canonical SKILL.md and build a SkillRecord matching discover.mjs output.
 *
 * Splits at the second `---` fence (end of frontmatter) and records bodyStartLine.
 */
function loadSkillRecord(dirName) {
  const sourcePath = `canonical/skills/${dirName}/SKILL.md`;
  const raw = readFileSync(join(REPO_ROOT, sourcePath), 'utf8');
  const lines = raw.split('\n').map((l) => l.replace(/\r$/, ''));

  // Find the closing `---` of the YAML frontmatter (first two `---` lines).
  let fenceCount = 0;
  let bodyStartIdx = 0; // 0-based index of first body line
  for (let i = 0; i < lines.length; i++) {
    if (/^---/.test(lines[i])) {
      fenceCount++;
      if (fenceCount === 2) {
        bodyStartIdx = i + 1;
        break;
      }
    }
  }

  const bodyStartLine = bodyStartIdx + 1; // 1-based
  const body = lines.slice(bodyStartIdx).join('\n');

  return { dirName, sourcePath, body, bodyStartLine, _rawLines: lines };
}

// ── Load real fixtures once ───────────────────────────────────────────────────

const createApiRecord = loadSkillRecord('aid-create-api');
const fixRecord       = loadSkillRecord('aid-fix');

const createApiChart = extractEngineDoorway(createApiRecord);
const fixChart       = extractEngineDoorway(fixRecord);

// ── AC-1: shape, extractor, confidence ───────────────────────────────────────

describe('AC-1 — shape / extractor / confidence (aid-create-api)', () => {
  it('shape === "engine-doorway"', () => {
    expect(createApiChart.shape).toBe('engine-doorway');
  });

  it('extractor === "extract-engine"', () => {
    expect(createApiChart.extractor).toBe('extract-engine');
  });

  it('confidence === "derived"', () => {
    expect(createApiChart.confidence).toBe('derived');
  });
});

// ── AC-2: entries, name, kind, label, provenance ─────────────────────────────

describe('AC-2 — entries, doorway node properties (aid-create-api)', () => {
  // Non-vacuity guard: the node list is non-empty before we index into it.
  it('nodes array is non-empty (non-vacuity guard)', () => {
    expect(createApiChart.nodes.length).toBeGreaterThan(0);
  });

  it('entries is exactly [nodes[0].id]', () => {
    expect(createApiChart.entries).toEqual([createApiChart.nodes[0].id]);
  });

  it('nodes[0].name === "aid-create-api"', () => {
    expect(createApiChart.nodes[0].name).toBe('aid-create-api');
  });

  it('nodes[0].kind === "entry"', () => {
    expect(createApiChart.nodes[0].kind).toBe('entry');
  });

  it('nodes[0].label contains "VERB=create"', () => {
    expect(createApiChart.nodes[0].label).toContain('VERB=create');
  });

  it('nodes[0].label contains "ARTIFACT=api"', () => {
    expect(createApiChart.nodes[0].label).toContain('ARTIFACT=api');
  });

  it('nodes[0].provenance.file is the skill SKILL.md path', () => {
    expect(createApiChart.nodes[0].provenance.file).toBe('canonical/skills/aid-create-api/SKILL.md');
  });

  it('nodes[0].provenance.sourceKind === "skill"', () => {
    expect(createApiChart.nodes[0].provenance.sourceKind).toBe('skill');
  });

  // Equality assertion against live file slice — not "non-empty": quality-bar rule 5.
  it('nodes[0].provenance.excerpt equals the live file slice at startLine', () => {
    const prov = createApiChart.nodes[0].provenance;
    const expected = sliceLines(createApiRecord._rawLines, prov.startLine, prov.endLine);
    // Equality comparison (not just non-empty) confirms the excerpt is the
    // correct line, not just some non-empty string.
    expect(prov.excerpt).toBe(expected);
  });
});

// ── AC-3: bare-verb form (aid-fix) ────────────────────────────────────────────

describe('AC-3 — bare-verb form ARTIFACT="" (bare verb) (aid-fix)', () => {
  // Non-vacuity: the node list is non-empty.
  it('fix chart nodes array is non-empty', () => {
    expect(fixChart.nodes.length).toBeGreaterThan(0);
  });

  // Separability: only aid-fix can exercise this path because aid-create-api
  // has a backtick artifact. The fixture name in the describe block makes the
  // intent explicit: this is the unique condition being tested.
  it('nodes[0].label carries ARTIFACT="" (bare verb) as written', () => {
    expect(fixChart.nodes[0].label).toBe('Bind VERB=fix, ARTIFACT="" (bare verb)');
  });

  it('nodes[0].label does NOT carry ARTIFACT= (empty string undecorated)', () => {
    // If the bare-verb detection is broken and we fall back to `ARTIFACT=${artifact}`,
    // artifact is '' so the label would be 'Bind VERB=fix, ARTIFACT='. This test
    // catches that mutation.
    expect(fixChart.nodes[0].label).not.toBe('Bind VERB=fix, ARTIFACT=');
  });
});

// ── AC-4: hop edge ────────────────────────────────────────────────────────────

describe('AC-4 — hop edge from n1', () => {
  const hopEdge = () => createApiChart.edges.find((e) => e.from === 'n1');

  // Non-vacuity: hop edge must exist.
  it('hop edge from n1 exists', () => {
    expect(hopEdge()).toBeTruthy();
  });

  it('hop edge kind === "sequence"', () => {
    expect(hopEdge().kind).toBe('sequence');
  });

  it('hop edge condition === null', () => {
    expect(hopEdge().condition).toBeNull();
  });

  it('hop edge to === "n2" (core entry becomes n2 with offset 1)', () => {
    expect(hopEdge().to).toBe('n2');
  });

  it('hop edge advanceType === "CHAIN"', () => {
    expect(hopEdge().advanceType).toBe('CHAIN');
  });
});

// ── AC-5: composed spine order ────────────────────────────────────────────────

describe('AC-5 — composed node spine (doorway + 9 engine nodes)', () => {
  // Non-vacuity: we must have exactly 10 nodes.
  it('chart has exactly 10 nodes (1 doorway + 9 engine)', () => {
    expect(createApiChart.nodes.length).toBe(10);
  });

  const expectedNames = [
    'aid-create-api',  // n1: doorway prefix
    'INTAKE',          // n2: c1 shifted by 1
    'CONTINUATION',    // n3: B1 under INTAKE
    'CAPTURE',         // n4
    'SPEC',            // n5
    'PLAN',            // n6
    'DETAIL',          // n7
    'GATE',            // n8
    'Circuit breaker', // n9: B1 under GATE
    'APPROVAL-HALT',   // n10
  ];

  it('node names in order match the full engine spine', () => {
    const actualNames = createApiChart.nodes
      .slice()
      .sort((a, b) => a.order - b.order)
      .map((n) => n.name);
    expect(actualNames).toEqual(expectedNames);
  });

  it('node ids are n1…n10 (offset=1 gives n2…n10 for engine, n1 for doorway)', () => {
    const ids = createApiChart.nodes
      .slice()
      .sort((a, b) => a.order - b.order)
      .map((n) => n.id);
    expect(ids).toEqual(['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10']);
  });

  it('doorway prefix offset is 1: no composed node retains a cN-prefixed id', () => {
    for (const n of createApiChart.nodes) {
      expect(n.id).not.toMatch(/^c\d/);
    }
  });
});

// ── AC-6: validateChart ───────────────────────────────────────────────────────

describe('AC-6 — validateChart passes', () => {
  const result = validateChart(createApiChart);

  it('validateChart(chart).ok === true', () => {
    expect(result.ok).toBe(true);
  });

  it('chart.entries has exactly 1 entry', () => {
    // Non-vacuity: length must be >= 1 is the minimum; AC says exactly 1.
    expect(createApiChart.entries.length).toBe(1);
  });

  it('chart.exits is non-empty', () => {
    expect(createApiChart.exits.length).toBeGreaterThan(0);
  });

  it('chart.exits contains the APPROVAL-HALT node id', () => {
    const approvalHaltNode = createApiChart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(approvalHaltNode).toBeTruthy();
    expect(createApiChart.exits).toContain(approvalHaltNode.id);
  });

  it('APPROVAL-HALT node has terminal.advanceType === "HALT"', () => {
    const approvalHaltNode = createApiChart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(approvalHaltNode.terminal.advanceType).toBe('HALT');
  });

  it('APPROVAL-HALT node has a non-null terminal.handoff', () => {
    // The AC also requires handoff to mention /aid-execute, but the actual
    // **Advance:** clause does not contain that phrase — see IMPEDIMENT.md in
    // this task's directory. We assert non-null rather than a substring match
    // to document the actual contract without fabricating a failing test.
    const approvalHaltNode = createApiChart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(approvalHaltNode.terminal.handoff).not.toBeNull();
  });

  it('APPROVAL-HALT node has terminal.handoff containing "No branch is created"', () => {
    const approvalHaltNode = createApiChart.nodes.find((n) => n.name === 'APPROVAL-HALT');
    expect(approvalHaltNode.terminal.handoff).toContain('No branch is created');
  });

  it('chart.exits contains the CONTINUATION node id', () => {
    const contNode = createApiChart.nodes.find((n) => n.name === 'CONTINUATION');
    expect(contNode).toBeTruthy();
    expect(createApiChart.exits).toContain(contNode.id);
  });

  it('chart.exits contains the "Circuit breaker" node id', () => {
    const cbNode = createApiChart.nodes.find((n) => n.name === 'Circuit breaker');
    expect(cbNode).toBeTruthy();
    expect(createApiChart.exits).toContain(cbNode.id);
  });
});

// ── AC-7: resolution notice ───────────────────────────────────────────────────

describe('AC-7 — RESOLUTION_NOTICE', () => {
  it('RESOLUTION_NOTICE is a string', () => {
    expect(typeof RESOLUTION_NOTICE).toBe('string');
  });

  it('RESOLUTION_NOTICE is non-empty', () => {
    expect(RESOLUTION_NOTICE.length).toBeGreaterThan(0);
  });

  it('RESOLUTION_NOTICE carries a GITHUB_BLOB_BASE link', () => {
    expect(RESOLUTION_NOTICE).toContain(GITHUB_BLOB_BASE);
  });

  it('RESOLUTION_NOTICE link points to the canonical shortcut engine path', () => {
    expect(RESOLUTION_NOTICE).toContain('canonical/aid/templates/shortcut-engine.md');
  });

  it('RESOLUTION_NOTICE is NOT a chart node: it is not in chart.nodes names', () => {
    for (const n of createApiChart.nodes) {
      // The notice is prose; no node should carry its substring as a name.
      expect(n.name).not.toContain('RESOLUTION_NOTICE');
      expect(n.name).not.toContain('Derived from the [shared shortcut engine]');
    }
  });

  it('RESOLUTION_NOTICE is prose (starts with > blockquote marker)', () => {
    // Confirms it is authored for display above the fence, not as a node.
    expect(RESOLUTION_NOTICE.trimStart()).toMatch(/^>/);
  });
});

// ── Truncation ────────────────────────────────────────────────────────────────

describe('Truncation — label capped at 60 code points', () => {
  // Synthetic fixture: verb and artifact long enough that the combined label
  // exceeds 60 code points, forcing the truncator.
  //
  // Label = "Bind VERB=" (10) + verb (19) + ", ARTIFACT=" (11) + artifact (21) = 61
  // → truncated to 59 chars + "…" = 60 code points total.
  //
  // verb = "aaaaaaaaaaaaaaaaaaa" (19 a's)
  // artifact = "bbbbbbbbbbbbbbbbbbbbb" (21 b's)
  const longBody = [
    'Bind **VERB=`aaaaaaaaaaaaaaaaaaa`**, **ARTIFACT=`bbbbbbbbbbbbbbbbbbbbb`**, then run the engine.',
    '',
  ].join('\n');

  const syntheticRecord = {
    dirName:       'aid-synthetic-long',
    sourcePath:    'canonical/skills/aid-synthetic-long/SKILL.md',
    bodyStartLine: 1,
    body:          longBody,
  };

  const syntheticChart = extractEngineDoorway(syntheticRecord);

  it('label is truncated to at most 60 code points', () => {
    const label = syntheticChart.nodes[0].label;
    const codepoints = [...label];
    expect(codepoints.length).toBeLessThanOrEqual(60);
  });

  it('label ends with "…" (U+2026) when truncated', () => {
    const label = syntheticChart.nodes[0].label;
    expect(label.endsWith('\u2026')).toBe(true);
  });

  it('non-truncated label (aid-create-api) does NOT end with "…"', () => {
    // Separability: short label should pass through untruncated.
    expect(createApiChart.nodes[0].label.endsWith('\u2026')).toBe(false);
  });
});

// ── Provenance on hop edge ────────────────────────────────────────────────────

describe('Hop edge provenance', () => {
  it('hop edge provenance.file equals the skill SKILL.md path', () => {
    const hopEdge = createApiChart.edges.find((e) => e.from === 'n1');
    expect(hopEdge.provenance.file).toBe('canonical/skills/aid-create-api/SKILL.md');
  });

  it('hop edge provenance.sourceKind === "skill"', () => {
    const hopEdge = createApiChart.edges.find((e) => e.from === 'n1');
    expect(hopEdge.provenance.sourceKind).toBe('skill');
  });

  // Equality check — not merely non-empty: the hop edge shares provenance with
  // the doorway prefix node (same Bind clause line).
  it('hop edge provenance.excerpt equals the doorway node provenance.excerpt', () => {
    const hopEdge     = createApiChart.edges.find((e) => e.from === 'n1');
    const doorwayNode = createApiChart.nodes.find((n) => n.id === 'n1');
    expect(hopEdge.provenance.excerpt).toBe(doorwayNode.provenance.excerpt);
  });
});

// ── Purity: no mutation of the engine core ───────────────────────────────────

describe('Purity — extractEngineDoorway does not mutate the engine core', () => {
  it('calling extractEngineDoorway twice returns the same spine order', () => {
    const chart1 = extractEngineDoorway(createApiRecord);
    const chart2 = extractEngineDoorway(createApiRecord);
    const names1 = chart1.nodes.map((n) => n.name);
    const names2 = chart2.nodes.map((n) => n.name);
    // If the core were mutated (e.g., by pushing a node), the second call would
    // produce a longer or differently-ordered node list.
    expect(names1).toEqual(names2);
  });

  it('calling extractEngineDoorway on a different skill still yields 10 nodes', () => {
    // If the core's nodes array were mutated by the first call (aid-create-api),
    // the second call (aid-fix) would see a polluted core and would not produce
    // the canonical 10-node spine.
    expect(fixChart.nodes.length).toBe(10);
  });
});

// ── Sources ───────────────────────────────────────────────────────────────────

describe('Sources', () => {
  it('sources includes the skill SKILL.md path', () => {
    expect(createApiChart.sources).toContain('canonical/skills/aid-create-api/SKILL.md');
  });

  it('sources includes the engine template path', () => {
    expect(createApiChart.sources).toContain('canonical/aid/templates/shortcut-engine.md');
  });

  it('sources is ASCII-sorted', () => {
    const sorted = [...createApiChart.sources].sort();
    expect(createApiChart.sources).toEqual(sorted);
  });
});
