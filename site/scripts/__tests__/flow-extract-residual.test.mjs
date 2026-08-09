// flow-extract-residual.test.mjs — Unit tests for extract-residual.mjs.
//
// Coverage:
//   parseAsciiStateMap — R1 token parser (exported for corroborating-spine use)
//   extractResidual    — all five rungs + confidence/shape invariants
//
// Discipline:
//   - Every assertion drives the real module; no logic is re-implemented here.
//   - Node and edge sets are asserted exactly (count + name + from/to), not loosely.
//   - Each heuristic rung has a firing case AND a near-miss that genuinely reaches it.
//   - Real SKILL.md files for the 13 corpus skills are loaded from disk; no inline
//     count is hard-coded (§8 / KI-005).
//   - Every test that fires a rung also asserts chart.confidence === 'approximate' and
//     validateChart(chart).ok === true (V1–V8 pass).

import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseAsciiStateMap, extractResidual } from '../lib/flow-graph/extract-residual.mjs';
import { splitFrontmatter } from '../lib/flow-graph/source.mjs';
import { validateChart } from '../lib/flow-graph/validate.mjs';
import { classifySkill } from '../lib/flow-graph/classify.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const CANONICAL_SKILLS = resolve(REPO_ROOT, 'canonical/skills');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Parse a SKILL.md text string and return the params extractResidual expects.
 * The `file` is set to `canonical/skills/test-fixture/SKILL.md` so V7 passes.
 *
 * @param {string} text        Full SKILL.md content (must start with ---\n).
 * @param {string} [skillName] Optional skill directory name (default: 'test-fixture').
 * @returns {object}  params object ready to pass to extractResidual.
 */
function parseSkill(text, skillName = 'test-fixture') {
  const file = `canonical/skills/${skillName}/SKILL.md`;
  const { allLines, bodyLines, bodyStartLine } = splitFrontmatter(text, file);
  // Parse frontmatter fields naively for test purposes.
  const fmLines = allLines.slice(0, bodyStartLine - 2); // exclude fences
  const frontmatter = {};
  for (const line of fmLines) {
    const m = line.match(/^(\w[\w-]*):\s*(.*)/);
    if (m) frontmatter[m[1]] = m[2];
  }
  return { skill: skillName, file, allLines, bodyLines, bodyStartLine, frontmatter };
}

/**
 * Load a real SKILL.md from canonical/skills/<name>/SKILL.md.
 *
 * @param {string} name
 * @returns {object}  params for extractResidual
 */
function loadSkill(name) {
  const file = `canonical/skills/${name}/SKILL.md`;
  const absPath = resolve(REPO_ROOT, file);
  const text = readFileSync(absPath, 'utf8');
  const { allLines, bodyLines, bodyStartLine } = splitFrontmatter(text, file);
  // Parse frontmatter for description field.
  const frontmatter = {};
  for (let i = 1; i < bodyStartLine - 1 && i < allLines.length; i++) {
    const m = allLines[i].match(/^(\w[\w-]*):\s*(.*)/);
    if (m) frontmatter[m[1]] = m[2];
  }
  return { skill: name, file, allLines, bodyLines, bodyStartLine, frontmatter };
}

// ── parseAsciiStateMap ────────────────────────────────────────────────────────

describe('parseAsciiStateMap — empty / trivial', () => {
  it('returns empty arrays for empty string', () => {
    const r = parseAsciiStateMap('');
    expect(r.names).toEqual([]);
    expect(r.conditions).toEqual([]);
  });

  it('returns empty arrays when no brackets are found', () => {
    const r = parseAsciiStateMap('no brackets here -> still nothing');
    expect(r.names).toEqual([]);
    expect(r.conditions).toEqual([]);
  });

  it('returns one token for a single bracketed name', () => {
    const r = parseAsciiStateMap('[ALPHA]');
    expect(r.names).toEqual(['ALPHA']);
    expect(r.conditions).toEqual([null]);
  });
});

describe('parseAsciiStateMap — sequence', () => {
  it('returns two tokens separated by ->', () => {
    const r = parseAsciiStateMap('[A] -> [B]');
    expect(r.names).toEqual(['A', 'B']);
    expect(r.conditions).toEqual([null, null]);
  });

  it('returns two tokens separated by unicode arrow →', () => {
    const r = parseAsciiStateMap('[A] \u2192 [B]');
    expect(r.names).toEqual(['A', 'B']);
    expect(r.conditions).toEqual([null, null]);
  });

  it('returns three tokens in order', () => {
    const r = parseAsciiStateMap('[PARSE] -> [COMPOSE] -> [SEND]');
    expect(r.names).toEqual(['PARSE', 'COMPOSE', 'SEND']);
    expect(r.conditions).toEqual([null, null, null]);
  });

  it('uppercases lowercase names', () => {
    const r = parseAsciiStateMap('[parse] -> [compose]');
    expect(r.names).toEqual(['PARSE', 'COMPOSE']);
  });
});

describe('parseAsciiStateMap — conditions', () => {
  it('extracts condition from parenthesised suffix inside brackets', () => {
    const r = parseAsciiStateMap('[A] -> [B(on success)]');
    expect(r.names).toEqual(['A', 'B']);
    expect(r.conditions).toEqual([null, 'on success']);
  });

  it('first token always has null condition even when suffix present in text', () => {
    // The parseAsciiStateMap contract: conditions[0] is always null.
    const r = parseAsciiStateMap('[A(init)] -> [B]');
    expect(r.conditions[0]).toBeNull();
    expect(r.names[0]).toBe('A');
  });

  it('middle-token condition does not affect the third token', () => {
    const r = parseAsciiStateMap('[A] -> [B(branch)] -> [C]');
    expect(r.names).toEqual(['A', 'B', 'C']);
    expect(r.conditions).toEqual([null, 'branch', null]);
  });
});

describe('parseAsciiStateMap — multi-line', () => {
  it('parses tokens spread across lines when joined with \\n', () => {
    const text = '[A] -> [B]\n[B] -> [C]';
    const r = parseAsciiStateMap(text);
    // A appears once before each ->, B appears twice (once as target, once as source)
    expect(r.names.length).toBeGreaterThanOrEqual(2);
    expect(r.names[0]).toBe('A');
  });
});

// ── R1 firing: fenced code block ──────────────────────────────────────────────

describe('R1 — fenced code block with arrows', () => {
  const R1_FENCED = `---
name: r1-fenced
description: R1 fixture
---

Some prose here.

\`\`\`
[ALPHA] -> [BETA] -> [GAMMA]
\`\`\`
`;

  it('R1 fires: 3 nodes extracted from the fenced block', () => {
    const params = parseSkill(R1_FENCED, 'r1-fenced');
    const chart = extractResidual(params);
    expect(chart.nodes.length).toBe(3);
    expect(chart.nodes.map((n) => n.name)).toEqual(['ALPHA', 'BETA', 'GAMMA']);
  });

  it('R1 fires: 2 sequence edges between consecutive tokens', () => {
    const params = parseSkill(R1_FENCED, 'r1-fenced');
    const chart = extractResidual(params);
    expect(chart.edges.length).toBe(2);
    expect(chart.edges[0].from).toBe('n1');
    expect(chart.edges[0].to).toBe('n2');
    expect(chart.edges[1].from).toBe('n2');
    expect(chart.edges[1].to).toBe('n3');
  });

  it('R1 fires: confidence is approximate', () => {
    const chart = extractResidual(parseSkill(R1_FENCED, 'r1-fenced'));
    expect(chart.confidence).toBe('approximate');
  });

  it('R1 fires: chart passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R1_FENCED, 'r1-fenced')));
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('R1 fires: last node is exit (has terminal)', () => {
    const chart = extractResidual(parseSkill(R1_FENCED, 'r1-fenced'));
    const last = chart.nodes[chart.nodes.length - 1];
    expect(last.terminal).not.toBeNull();
    expect(chart.exits).toContain(last.id);
  });
});

// ── R1 firing: State machine: line ────────────────────────────────────────────

describe('R1 — State machine: line', () => {
  const R1_SM = `---
name: r1-sm
description: State machine line fixture
---

State machine: [INIT] -> [RUN] -> [DONE]
`;

  it('R1 fires via State machine: line — 3 nodes', () => {
    const chart = extractResidual(parseSkill(R1_SM, 'r1-sm'));
    expect(chart.nodes.length).toBe(3);
    expect(chart.nodes[0].name).toBe('INIT');
    expect(chart.nodes[2].name).toBe('DONE');
  });

  it('R1 fires via State machine: line — edges connect consecutive tokens', () => {
    const chart = extractResidual(parseSkill(R1_SM, 'r1-sm'));
    expect(chart.edges.length).toBe(2);
    expect(chart.edges[0]).toMatchObject({ from: 'n1', to: 'n2' });
    expect(chart.edges[1]).toMatchObject({ from: 'n2', to: 'n3' });
  });

  it('R1 State machine: line — chart passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R1_SM, 'r1-sm')));
    expect(result.ok).toBe(true);
  });
});

// ── R1 near-miss: fenced block without arrows → falls to R2 ──────────────────

describe('R1 near-miss — fenced block has no arrows', () => {
  // The fenced block has no ->/→ separators, so R1 finds no tokens.
  // R2 heading is present so R2 fires instead.
  const R1_MISS = `---
name: r1-miss
description: R1 miss fixture
---

\`\`\`
just some code without arrows
\`\`\`

### State 1 — FIRST
### State 2 — SECOND
`;

  it('R1 near-miss: R2 fires instead (2 nodes with state names)', () => {
    const chart = extractResidual(parseSkill(R1_MISS, 'r1-miss'));
    expect(chart.nodes.map((n) => n.name)).toEqual(['FIRST', 'SECOND']);
  });

  it('R1 near-miss: extractor is still residual', () => {
    const chart = extractResidual(parseSkill(R1_MISS, 'r1-miss'));
    expect(chart.extractor).toBe('residual');
  });
});

// ── R1 near-miss: only 1 token → falls through ───────────────────────────────

describe('R1 near-miss — single token in fenced block', () => {
  const R1_ONE = `---
name: r1-one
description: one token
---

\`\`\`
[LONELY]
\`\`\`
### State 1 — ONLY
### State 2 — OTHER
`;

  it('R1 near-miss (1 token < 2): R2 fires with 2 state nodes', () => {
    const chart = extractResidual(parseSkill(R1_ONE, 'r1-one'));
    // R1 produces 1 node (fails ≥2 check), so R2 fires.
    expect(chart.nodes.map((n) => n.name)).toContain('ONLY');
    expect(chart.nodes.map((n) => n.name)).toContain('OTHER');
  });
});

// ── R2 firing: ### State N — NAME ────────────────────────────────────────────

describe('R2 — ### State N — NAME headings', () => {
  const R2_TWO = `---
name: r2-two
description: R2 two states
---

### State 1 — ALPHA
Some content here.

### State 2 — BETA
More content.
`;

  it('R2 fires: 2 nodes with correct names', () => {
    const chart = extractResidual(parseSkill(R2_TWO, 'r2-two'));
    expect(chart.nodes.length).toBe(2);
    expect(chart.nodes[0].name).toBe('ALPHA');
    expect(chart.nodes[1].name).toBe('BETA');
  });

  it('R2 fires: 1 sequence edge ALPHA → BETA', () => {
    const chart = extractResidual(parseSkill(R2_TWO, 'r2-two'));
    expect(chart.edges.length).toBe(1);
    expect(chart.edges[0]).toMatchObject({ from: 'n1', to: 'n2', kind: 'sequence' });
  });

  it('R2 fires: entries = [n1], exits = [n2]', () => {
    const chart = extractResidual(parseSkill(R2_TWO, 'r2-two'));
    expect(chart.entries).toEqual(['n1']);
    expect(chart.exits).toEqual(['n2']);
  });

  it('R2 fires: confidence = approximate', () => {
    const chart = extractResidual(parseSkill(R2_TWO, 'r2-two'));
    expect(chart.confidence).toBe('approximate');
  });

  it('R2 fires: chart passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R2_TWO, 'r2-two')));
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('R2 — hyphen separator variant', () => {
  const R2_HYPHEN = `---
name: r2-hyph
description: R2 hyphen separator
---

### State 1 - FIRST
### State 2 - SECOND
`;

  it('R2 handles plain-hyphen separator', () => {
    const chart = extractResidual(parseSkill(R2_HYPHEN, 'r2-hyph'));
    expect(chart.nodes.map((n) => n.name)).toEqual(['FIRST', 'SECOND']);
  });
});

// ── R2 near-miss: only 1 heading → falls through to R3/R5 ────────────────────

describe('R2 near-miss — single ### State heading', () => {
  const R2_ONE = `---
name: r2-one
description: only one state
---

### State 1 — LONELY
`;

  it('R2 near-miss (1 node < 2): R5 fires with 3-node spine', () => {
    const chart = extractResidual(parseSkill(R2_ONE, 'r2-one'));
    // R2 produces 1 node, fails ≥2 check; R3/R4 also fail; R5 fires.
    expect(chart.nodes.length).toBe(3);
    expect(chart.nodes[0].name).toBe('ENTRY');
    expect(chart.nodes[1].name).toBe('RUN');
    expect(chart.nodes[2].name).toBe('EXIT');
  });
});

// ── R2 real skills ────────────────────────────────────────────────────────────

describe('R2 — aid-create-ticket (7 states)', () => {
  const params = loadSkill('aid-create-ticket');
  const chart = extractResidual(params);

  it('produces the correct number of nodes', () => {
    const stateCount = params.bodyLines.filter((l) => /^### State \d+/.test(l)).length;
    expect(chart.nodes.length).toBe(stateCount);
  });

  it('first node is PARSE-ARGS', () => {
    expect(chart.nodes[0].name).toBe('PARSE-ARGS');
  });

  it('last node is RETURN-REF (exit)', () => {
    const last = chart.nodes[chart.nodes.length - 1];
    expect(last.name).toBe('RETURN-REF');
    expect(chart.exits).toContain(last.id);
  });

  it('sequential edges: count = nodes - 1', () => {
    expect(chart.edges.length).toBe(chart.nodes.length - 1);
  });

  it('all edges are kind sequence', () => {
    expect(chart.edges.every((e) => e.kind === 'sequence')).toBe(true);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });

  it('confidence is approximate', () => {
    expect(chart.confidence).toBe('approximate');
  });
});

describe('R2 — aid-read-ticket (4 states)', () => {
  const params = loadSkill('aid-read-ticket');
  const chart = extractResidual(params);

  it('produces the correct number of nodes', () => {
    const stateCount = params.bodyLines.filter((l) => /^### State \d+/.test(l)).length;
    expect(chart.nodes.length).toBe(stateCount);
  });

  it('first node is PARSE-ARGS', () => {
    expect(chart.nodes[0].name).toBe('PARSE-ARGS');
  });

  it('last node is DISPLAY (exit)', () => {
    const last = chart.nodes[chart.nodes.length - 1];
    expect(last.name).toBe('DISPLAY');
    expect(chart.exits).toContain(last.id);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

describe('R2 — aid-update-ticket (6 states)', () => {
  const params = loadSkill('aid-update-ticket');
  const chart = extractResidual(params);

  it('produces the correct number of nodes', () => {
    const stateCount = params.bodyLines.filter((l) => /^### State \d+/.test(l)).length;
    expect(chart.nodes.length).toBe(stateCount);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });

  it('confidence is approximate', () => {
    expect(chart.confidence).toBe('approximate');
  });
});

// ── R3 firing: single-lane (no modes) ────────────────────────────────────────

describe('R3 — single-lane ### Step headings', () => {
  const R3_SINGLE = `---
name: r3-single
description: R3 single lane
---

### Step 1 — Do the first thing
Some content.

### Step 2 — Do the second thing
More content.
`;

  it('R3 fires: 2 nodes with step labels', () => {
    const chart = extractResidual(parseSkill(R3_SINGLE, 'r3-single'));
    expect(chart.nodes.length).toBe(2);
    expect(chart.nodes[0].label).toBe('Do the first thing');
    expect(chart.nodes[1].label).toBe('Do the second thing');
  });

  it('R3 fires: step names are STEP-1 and STEP-2', () => {
    const chart = extractResidual(parseSkill(R3_SINGLE, 'r3-single'));
    expect(chart.nodes[0].name).toBe('STEP-1');
    expect(chart.nodes[1].name).toBe('STEP-2');
  });

  it('R3 fires: 1 sequence edge', () => {
    const chart = extractResidual(parseSkill(R3_SINGLE, 'r3-single'));
    expect(chart.edges.length).toBe(1);
    expect(chart.edges[0]).toMatchObject({ from: 'n1', to: 'n2' });
  });

  it('R3 fires: entries=[n1], exits=[n2]', () => {
    const chart = extractResidual(parseSkill(R3_SINGLE, 'r3-single'));
    expect(chart.entries).toEqual(['n1']);
    expect(chart.exits).toEqual(['n2']);
  });

  it('R3 fires: passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R3_SINGLE, 'r3-single')));
    expect(result.ok).toBe(true);
  });
});

// ── R3 firing: multi-lane (## Mode N ancestor) ───────────────────────────────

describe('R3 — multi-lane with ## Mode N', () => {
  const R3_MULTI = `---
name: r3-multi
description: R3 multi-lane
---

## Mode 1 — Query

### Step 1: Read setting

### Step 2: Display result

## Mode 2 — Mutate

### Step 1: Validate key

### Step 2: Write value
`;

  it('R3 multi-lane: 6 nodes (2 mode entries + 2 + 2 steps)', () => {
    const chart = extractResidual(parseSkill(R3_MULTI, 'r3-multi'));
    expect(chart.nodes.length).toBe(6);
  });

  it('R3 multi-lane: 2 entries (one per mode)', () => {
    const chart = extractResidual(parseSkill(R3_MULTI, 'r3-multi'));
    expect(chart.entries.length).toBe(2);
    expect(chart.entries).toContain('n1');
    expect(chart.entries).toContain('n4');
  });

  it('R3 multi-lane: 2 exits (last step of each lane)', () => {
    const chart = extractResidual(parseSkill(R3_MULTI, 'r3-multi'));
    expect(chart.exits.length).toBe(2);
  });

  it('R3 multi-lane: edges connect within each lane only', () => {
    const chart = extractResidual(parseSkill(R3_MULTI, 'r3-multi'));
    // 4 edges: MODE-1→STEP-1, STEP-1→STEP-2, MODE-2→STEP-1, STEP-1→STEP-2
    expect(chart.edges.length).toBe(4);
    // No cross-lane edges
    const edgePairs = chart.edges.map((e) => `${e.from}->${e.to}`);
    expect(edgePairs).not.toContain('n3->n4'); // last Mode-1 step to Mode-2 entry
  });

  it('R3 multi-lane: passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R3_MULTI, 'r3-multi')));
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('R3 multi-lane: confidence is approximate', () => {
    const chart = extractResidual(parseSkill(R3_MULTI, 'r3-multi'));
    expect(chart.confidence).toBe('approximate');
  });
});

// ── R3 near-miss: only Step 0 → 1 node, falls to R4/R5 ──────────────────────

describe('R3 near-miss — single ### Step 0 only', () => {
  const R3_MISS = `---
name: r3-miss
description: only step zero
---

### Step 0: Validate arguments
`;

  it('R3 near-miss (1 node < 2): R5 fires with 3-node spine', () => {
    const chart = extractResidual(parseSkill(R3_MISS, 'r3-miss'));
    // R3 produces 1 node (Step 0 only), ≥2 check fails; R5 fires.
    expect(chart.nodes.length).toBe(3);
    expect(chart.nodes[0].name).toBe('ENTRY');
  });
});

// ── R3 real skills ────────────────────────────────────────────────────────────

describe('R3 — aid-config (2 modes, 3+7 steps)', () => {
  const params = loadSkill('aid-config');
  const chart = extractResidual(params);

  it('produces correct node count (2 mode entries + 3 Mode-1 steps + 7 Mode-2 steps)', () => {
    const modeCount = params.bodyLines.filter((l) => /^## Mode \d+/.test(l)).length;
    const stepCount = params.bodyLines.filter((l) => /^### Step /.test(l)).length;
    expect(chart.nodes.length).toBe(modeCount + stepCount);
  });

  it('has 2 entries (one per mode)', () => {
    expect(chart.entries.length).toBe(2);
  });

  it('has 2 exits (last step per mode)', () => {
    expect(chart.exits.length).toBe(2);
  });

  it('Mode-1 entry name is MODE-1', () => {
    expect(chart.nodes[0].name).toBe('MODE-1');
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });

  it('confidence is approximate', () => {
    expect(chart.confidence).toBe('approximate');
  });
});

// `aid-query-kb` was retired; `aid-ask` is its successor and carries the same
// authored step structure — R3 finds STEP-1, STEP-2A, STEP-2B, STEP-2C, STEP-3,
// STEP-4 on disk, so every assertion below holds unchanged at full strength.
describe('R3 — aid-ask (Steps 1, 2a, 2b, 2c, 3, 4)', () => {
  const params = loadSkill('aid-ask');
  const chart = extractResidual(params);

  it('produces correct node count (all ### Step headings)', () => {
    const stepCount = params.bodyLines.filter((l) => /^### Step /.test(l)).length;
    expect(chart.nodes.length).toBe(stepCount);
  });

  it('first node is STEP-1', () => {
    expect(chart.nodes[0].name).toBe('STEP-1');
  });

  it('second node name starts with STEP-2', () => {
    expect(chart.nodes[1].name).toMatch(/^STEP-2/);
  });

  it('last node is STEP-4 (exit)', () => {
    const last = chart.nodes[chart.nodes.length - 1];
    expect(last.name).toBe('STEP-4');
    expect(chart.exits).toContain(last.id);
  });

  it('single entry (no modes)', () => {
    expect(chart.entries.length).toBe(1);
    expect(chart.entries[0]).toBe('n1');
  });

  it('edges count = nodes - 1 (linear chain)', () => {
    expect(chart.edges.length).toBe(chart.nodes.length - 1);
  });

  it('passes V1-V8', () => {
    expect(validateChart(chart).ok).toBe(true);
  });
});

// ── R4 firing: ordered list with verb-starting items ─────────────────────────

describe('R4 — ordered list with verb-starting items', () => {
  const R4_LIST = `---
name: r4-list
description: R4 list fixture
---

1. Parse the incoming arguments carefully
2. Validate the parsed values against schema
3. Emit the result to stdout
`;

  it('R4 fires: 3 nodes derived from list items', () => {
    const chart = extractResidual(parseSkill(R4_LIST, 'r4-list'));
    expect(chart.nodes.length).toBe(3);
  });

  it('R4 fires: node labels are truncated item texts', () => {
    const chart = extractResidual(parseSkill(R4_LIST, 'r4-list'));
    expect(chart.nodes[0].label).toBe('Parse the incoming arguments carefully');
    expect(chart.nodes[1].label).toBe('Validate the parsed values against schema');
    expect(chart.nodes[2].label).toBe('Emit the result to stdout');
  });

  it('R4 fires: 2 sequence edges', () => {
    const chart = extractResidual(parseSkill(R4_LIST, 'r4-list'));
    expect(chart.edges.length).toBe(2);
  });

  it('R4 fires: passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R4_LIST, 'r4-list')));
    expect(result.ok).toBe(true);
  });

  it('R4 fires: confidence is approximate', () => {
    const chart = extractResidual(parseSkill(R4_LIST, 'r4-list'));
    expect(chart.confidence).toBe('approximate');
  });
});

// ── R4 near-miss: non-verb starters → falls to R5 ────────────────────────────

describe('R4 near-miss — list items start with articles/determiners', () => {
  const R4_MISS = `---
name: r4-miss
description: R4 non-verb list
---

1. The first item starts with an article
2. A second item also starts with an article
3. The third item is another non-verb
`;

  it('R4 near-miss: R5 fires with 3-node spine', () => {
    const chart = extractResidual(parseSkill(R4_MISS, 'r4-miss'));
    expect(chart.nodes.length).toBe(3);
    expect(chart.nodes[0].name).toBe('ENTRY');
  });
});

describe('R4 near-miss — only 1 verb item', () => {
  const R4_ONE = `---
name: r4-one
description: one verb item
---

1. Parse the input
2. The output is returned
`;

  it('R4 near-miss (only 1 verb item < 2): R5 fires', () => {
    // "Parse" is a verb, "The" is not — only 1 qualifying item.
    const chart = extractResidual(parseSkill(R4_ONE, 'r4-one'));
    expect(chart.nodes[0].name).toBe('ENTRY');
    expect(chart.nodes.length).toBe(3);
  });
});

// ── R5 — last resort, three-node spine ───────────────────────────────────────

describe('R5 — empty body falls to three-node spine', () => {
  const R5_EMPTY = `---
name: r5-empty
description: A skill with no body content at all.
---
`;

  it('R5 fires: exactly 3 nodes', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.nodes.length).toBe(3);
  });

  it('R5 fires: node names are ENTRY, RUN, EXIT', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.nodes[0].name).toBe('ENTRY');
    expect(chart.nodes[1].name).toBe('RUN');
    expect(chart.nodes[2].name).toBe('EXIT');
  });

  it('R5 fires: RUN label starts with "Run "', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.nodes[1].label).toMatch(/^Run /);
  });

  it('R5 fires: RUN label derived from description', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    // description is "A skill with no body content at all."
    expect(chart.nodes[1].label).toContain('A skill with');
  });

  it('R5 fires: 2 sequence edges ENTRY→RUN→EXIT', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.edges.length).toBe(2);
    expect(chart.edges[0]).toMatchObject({ from: 'n1', to: 'n2', kind: 'sequence' });
    expect(chart.edges[1]).toMatchObject({ from: 'n2', to: 'n3', kind: 'sequence' });
  });

  it('R5 fires: entry=[n1], exit=[n3]', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.entries).toEqual(['n1']);
    expect(chart.exits).toEqual(['n3']);
  });

  it('R5 fires: confidence is approximate', () => {
    const chart = extractResidual(parseSkill(R5_EMPTY, 'r5-empty'));
    expect(chart.confidence).toBe('approximate');
  });

  it('R5 fires: passes V1-V8', () => {
    const result = validateChart(extractResidual(parseSkill(R5_EMPTY, 'r5-empty')));
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });
});

describe('R5 — RUN label truncation', () => {
  const LONG_DESC = 'X'.repeat(100);
  const R5_LONG = `---
name: r5-long
description: ${LONG_DESC}
---
`;

  it('R5 fires: RUN label is at most 60 code points', () => {
    const chart = extractResidual(parseSkill(R5_LONG, 'r5-long'));
    expect(Array.from(chart.nodes[1].label).length).toBeLessThanOrEqual(60);
  });
});

// ── R5 real doorway skills ────────────────────────────────────────────────────

// `aid-set-connector` and `aid-unset-connector` were in this list and no longer
// belong: they DO have authored steps, and R3 now finds them. They were only
// falling to R5 because R3 matched `###` alone while both skills mix levels —
// `### Step 0` followed by `## Step 1` onward — so R3 saw one heading, failed its
// two-heading minimum, and gave up, discarding 7 and 4 steps.
//
// The list was re-pointed when the alias skills were retired. Two separate causes,
// both measured against the live tree rather than inferred from the names:
//
//   1. `aid-audit`, `aid-add-document`, `aid-investigate` and `aid-spike` no longer
//      exist on disk. `loadSkill` runs at describe-body scope, so the ENOENT threw
//      during collection and took the whole FILE down — every block in it collected
//      as zero, behind a failure count that named only the other two suites.
//   2. `aid-ask` and `aid-update-document` still exist but are no longer R5 cases:
//      each absorbed a retired skill's authored steps, so R3 now claims both.
//      Leaving them here would have turned a load failure into a wrong assertion,
//      which is worse, because it looks green.
//
// The replacements are real doorway skills, which is the property this rung needs
// and the same property the retired aliases supplied: a real SKILL.md that R1–R4
// all decline (no state map, no `## Mode`, no `### Step`, no verb-led ordered list).
// That population is exactly the doorway skills, engine and sibling alike; no
// residual, inline-states or dispatch-table skill is in it. The six below span both
// doorway kinds and both naming forms, so the cases are not near-duplicates of one
// generated template. Counts are deliberately absent: nothing guards a count stated
// in a comment under `site/scripts/` (check-skill-counts.mjs does not scan this tree
// and the site-side guard walks only `.md`/`.mdx`), so a number here would be
// unguarded drift.
describe.each([
  'aid-create',            // engine doorway, bare verb (the retired `aid-add`'s form)
  'aid-update-api',        // engine doorway, verb-noun
  'aid-deprecate',         // engine doorway, non-CRUD verb
  'aid-document',          // sibling doorway, bare
  'aid-document-runbook',  // sibling doorway, verb-noun
  'aid-test-security',     // sibling doorway, hand-authored rather than generated
])('R5 — %s falls to 3-node spine', (skillName) => {
  const params = loadSkill(skillName);
  const chart = extractResidual(params);

  it('produces exactly 3 nodes', () => {
    expect(chart.nodes.length).toBe(3);
  });

  it('node names are ENTRY, RUN, EXIT', () => {
    expect(chart.nodes[0].name).toBe('ENTRY');
    expect(chart.nodes[1].name).toBe('RUN');
    expect(chart.nodes[2].name).toBe('EXIT');
  });

  it('confidence is approximate', () => {
    expect(chart.confidence).toBe('approximate');
  });

  it('passes V1-V8', () => {
    const result = validateChart(chart);
    expect(result.ok).toBe(true);
  });
});

// ── R1 mechanics that mutation testing found unpinned ─────────────────────────
//
// Four survivors from the checkpoint review, all in R1. Each is a documented
// contract that no test in this 218-test suite exercised, so the source could be
// changed freely without a failure. They are grouped here because they share one
// cause: the suite tested which RUNG fires and how many nodes result, never what
// the resulting nodes and edges actually contain.

describe('R1 — a condition attaches to the edge INTO its token', () => {
  const COND_MAP = `---
name: r1-cond
description: Conditioned state map fixture
---

State machine: [ALPHA] -> [BETA (when ready)] -> [GAMMA (if approved)]
`;

  it('each condition lands on the edge whose TARGET carried it', () => {
    // The survivor: `conditions[i + 1]` -> `conditions[i]` — an off-by-one that
    // misattributes every condition to the previous edge — passed all 218 tests,
    // because nothing drove a conditioned map through `extractResidual` at all.
    const chart = extractResidual(parseSkill(COND_MAP, 'r1-cond'));
    const byId = new Map(chart.nodes.map((n) => [n.id, n.name]));
    const labelled = chart.edges.map((e) => `${byId.get(e.from)}->${byId.get(e.to)}:${e.condition}`);

    // Exact, and asserted as a whole so a shifted condition cannot hide.
    expect(labelled).toEqual([
      'ALPHA->BETA:when ready',
      'BETA->GAMMA:if approved',
    ]);
  });

  it('the bracketed condition is not left in the node name', () => {
    const chart = extractResidual(parseSkill(COND_MAP, 'r1-cond'));
    expect(chart.nodes.map((n) => n.name)).toEqual(['ALPHA', 'BETA', 'GAMMA']);
  });
});

describe('R1 — node labels are capped by the shared truncator', () => {
  it('an over-long token is truncated, not passed through', () => {
    // Unpinned survivor: dropping `truncate` here was invisible. It matters more
    // than a cosmetic cap — an over-long label fails V8, and the throwing façade
    // then loses the whole page, so this is the FR-2 boundary again.
    const long = 'A'.repeat(120);
    const chart = extractResidual(parseSkill(`---
name: r1-long
description: Long token fixture
---

State machine: [${long}] -> [DONE]
`, 'r1-long'));

    const node = chart.nodes[0];
    expect([...node.label].length).toBeLessThanOrEqual(60);
    // Non-vacuity: the fixture really is over the cap, so the assertion means
    // something.
    expect(long.length).toBeGreaterThan(60);
    expect(validateChart(chart).ok).toBe(true);
  });
});

describe('R1 — the ladder needs two nodes before a rung wins', () => {
  it('a single-token state map falls through to R5 rather than charting one node', () => {
    // Survivor: relaxing the gate from `>= 2` to `>= 1` produced a degenerate
    // one-node chart with no test objecting. The ladder contract is that a rung
    // must describe a FLOW, and one node is not a flow.
    const chart = extractResidual(parseSkill(`---
name: r1-single
description: Single token fixture
---

State machine: [ONLY]
`, 'r1-single'));

    // R5's signature shape, i.e. R1 declined.
    expect(chart.nodes.map((n) => n.name)).toEqual(['ENTRY', 'RUN', 'EXIT']);
  });
});

describe('R1 — repeated state names are disambiguated', () => {
  it('a second occurrence of a name is suffixed so the two nodes are distinguishable', () => {
    // Survivor: dropping the suffix produced two nodes a reader cannot tell apart,
    // silently. Asserted on the exact names so a different scheme still fails
    // rather than passing on a coincidence.
    const chart = extractResidual(parseSkill(`---
name: r1-dup
description: Duplicate name fixture
---

State machine: [CHECK] -> [WORK] -> [CHECK]
`, 'r1-dup'));

    const names = chart.nodes.map((n) => n.name);
    expect(names).toHaveLength(3);
    expect(new Set(names).size).toBe(3);
    expect(names[0]).toBe('CHECK');
    expect(names[2]).toMatch(/^CHECK-\d+$/);
  });
});

// ── FR-2: the safety net must never emit a malformed chart ────────────────────

describe('R1 — a bracket token with no NAME is skipped, not turned into a node', () => {
  // FR-2 draws the line at "a chart may be approximate, never malformed", and this
  // is the module that exists to honour it — R5 is the rung that always succeeds.
  // But R1 ran first and produced a node with an EMPTY LABEL, which fails V8, which
  // makes task-029's throwing façade lose the entire page. The safety net was the
  // thing tearing.
  //
  // Both inputs below are legitimate authoring: a placeholder box, and a bracket
  // carrying only a condition. Neither names a state, so neither is a node.
  const CASES = [
    ['an empty bracket', '[ ] -> [DONE]'],
    ['a condition-only bracket', '[(when ready)] -> [DONE]'],
  ];

  for (const [label, map] of CASES) {
    it(`${label} yields no empty-labelled node, and the chart validates`, () => {
      const body = `# T\n\nState machine:\n\n\`\`\`\n${map}\n\`\`\`\n`;
      const bodyLines = body.split('\n');
      const chart = extractResidual({
        skill: 'aid-fixture',
        file: 'canonical/skills/aid-fixture/SKILL.md',
        allLines: bodyLines,
        bodyLines,
        bodyStartLine: 1,
        frontmatter: 'name: aid-fixture\ndescription: A fixture.',
      });
      const empty = chart.nodes.filter((n) => !n.label || !String(n.label).trim());
      expect(empty).toEqual([]);
      // The real requirement: the façade must not throw on it.
      expect(validateChart(chart).ok).toBe(true);
      // Non-vacuity — a chart really was produced rather than the call bailing out.
      expect(chart.nodes.length).toBeGreaterThan(0);
    });
  }

  it('R2 — a `### State N —` heading with an empty name produces no node either', () => {
    // Row 16. The R1 guard has three tests; its R2 twin had none — and the R2 half is
    // exactly the half that was missed when this class was first "fixed", because my
    // probe fixture lacked the trailing space that makes the name empty. Leaving it
    // unpinned means the missed half can now be silently deleted.
    //
    // The trailing space after the em-dash is load-bearing: `R2_STATE_RE`'s `(.+)`
    // matches it, `.trim()` empties it, and the node used to ship with no label.
    const chart = extractResidual(parseSkill(`---
name: r2-empty
description: R2 empty-name fixture.
---

### State 1 — 

prose under the nameless heading

### State 2 — REAL

prose under the real one
`, 'r2-empty'));

    const empty = chart.nodes.filter((n) => !n.name || !String(n.label).trim());
    expect(empty).toEqual([]);
    expect(validateChart(chart).ok).toBe(true);
    // One valid R2 heading is not two, so the ladder declines and R5 answers.
    expect(chart.nodes.map((n) => n.name)).toEqual(['ENTRY', 'RUN', 'EXIT']);
  });

  it('parseAsciiStateMap drops the nameless token but keeps its neighbours', () => {
    // Pins the mechanism directly, so the behaviour survives a refactor of the
    // ladder above it.
    const { names } = parseAsciiStateMap('[ALPHA] -> [ ] -> [BETA]');
    expect(names).toEqual(['ALPHA', 'BETA']);
  });
});

// ── R3 across MIXED heading levels ────────────────────────────────────────────

describe('R3 — mixed `##` and `###` Step headings are one sequence', () => {
  // Both of these skills open with `### Step 0` and continue at `## Step 1`. R3
  // used to match `###` only, find a single heading, fail its two-heading minimum,
  // and fall to the R5 spine — so the chart lost every step. The counts below are
  // asserted as ">= 2 nodes beyond a spine" rather than an exact number, because the
  // exact count is a property of the skill's prose and would make this test a
  // tripwire for ordinary authoring edits.
  for (const [skill, minSteps] of [['aid-set-connector', 5], ['aid-unset-connector', 3]]) {
    it(`${skill} charts its steps instead of collapsing to a 3-node spine`, () => {
      const chart = extractResidual(loadSkill(skill));
      expect(chart.nodes.length).toBeGreaterThan(3);
      expect(chart.nodes.length).toBeGreaterThanOrEqual(minSteps);
      // Not the R5 shape: R5 emits exactly ENTRY / RUN / EXIT.
      expect(chart.nodes.map((n) => n.name)).not.toEqual(['ENTRY', 'RUN', 'EXIT']);
      expect(validateChart(chart).ok).toBe(true);
    });
  }

  it('a `## Mode N` heading with no steps beneath it produces NO node', () => {
    // It used to produce a node with no inbound and no outbound edge — a box
    // floating beside the chart. It passed validation only incidentally:
    // `buildChart` sees in-degree 0, lists it in `entries`, and V6 reachability is
    // then satisfied trivially. Valid, and still wrong to show, because it asserts
    // a lane with no content. A mode heading is a lane LABEL, not a state.
    const chart = extractResidual(parseSkill(`---
name: mode-empty
description: A mode with no steps.
---

## Mode 1

### Step 1: do a thing

## Mode 2
`, 'mode-empty'));

    expect(chart.nodes.map((n) => n.name)).toEqual(['MODE-1', 'STEP-1']);

    // The property that actually matters: nothing is stranded.
    for (const n of chart.nodes) {
      const degree = chart.edges.filter((e) => e.to === n.id || e.from === n.id).length;
      expect(degree, `${n.name} has no edges at all`).toBeGreaterThan(0);
    }
    expect(validateChart(chart).ok).toBe(true);
  });

  it('a `## Mode N` heading is not mistaken for a step', () => {
    // The reason widening to `#{2,3}` is safe: multi-lane detection keys on `Mode`,
    // which is lexically distinct from `Step`, so aid-config keeps its two lanes.
    const chart = extractResidual(loadSkill('aid-config'));
    const modeNodes = chart.nodes.filter((n) => /^MODE-/.test(n.name));
    expect(modeNodes.length).toBe(2);
    expect(chart.nodes.length).toBeGreaterThan(modeNodes.length);
  });
});

// ── Invariants across all 13 corpus skills ────────────────────────────────────

describe('every residual skill — invariants', () => {
  // DERIVED from the classifier, not a hand-written list. The literal roster of 13
  // names was a §8 violation (no hard-coded corpus counts — defect class KI-005),
  // and it fails in the way §8 exists to prevent: a skill that changes shape, or a
  // new residual skill, silently escapes these invariants while the suite stays
  // green. Asking the classifier means the set can only be wrong if the classifier is.
  const SKILLS = readdirSync(CANONICAL_SKILLS, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .filter((dir) => {
      const file = join(CANONICAL_SKILLS, dir, 'SKILL.md');
      if (!existsSync(file)) return false;
      const { fmLines, bodyLines } = splitFrontmatter(readFileSync(file, 'utf8'), `canonical/skills/${dir}/SKILL.md`);
      return classifySkill({
        name: dir, dir, frontmatter: fmLines.join('\n'), body: bodyLines.join('\n'),
      }).shape === 'residual';
    });

  it('the derived roster is non-empty — these invariants are not vacuous', () => {
    expect(SKILLS.length).toBeGreaterThan(1);
  });

  for (const skillName of SKILLS) {
    describe(skillName, () => {
      const params = loadSkill(skillName);
      const chart = extractResidual(params);

      it('chart is not null and has nodes', () => {
        expect(chart).not.toBeNull();
        expect(chart.nodes.length).toBeGreaterThanOrEqual(2);
      });

      it('confidence is approximate', () => {
        expect(chart.confidence).toBe('approximate');
      });

      it('shape is residual', () => {
        expect(chart.shape).toBe('residual');
      });

      it('extractor is residual', () => {
        expect(chart.extractor).toBe('residual');
      });

      it('passes V1-V8 (validateChart)', () => {
        const result = validateChart(chart);
        if (!result.ok) {
          // Print errors for diagnosis
          throw new Error(
            `${skillName} failed validation:\n${result.errors.join('\n')}`
          );
        }
        expect(result.ok).toBe(true);
      });

      it('has at least 1 entry and 1 exit', () => {
        expect(chart.entries.length).toBeGreaterThanOrEqual(1);
        expect(chart.exits.length).toBeGreaterThanOrEqual(1);
      });

      it('all edges reference valid node ids', () => {
        const nodeIds = new Set(chart.nodes.map((n) => n.id));
        for (const edge of chart.edges) {
          expect(nodeIds.has(edge.from)).toBe(true);
          expect(nodeIds.has(edge.to)).toBe(true);
        }
      });
    });
  }
});

// ── Provenance well-formedness (V7 spot-checks) ───────────────────────────────

describe('provenance integrity', () => {
  it('R2 nodes have provenance.file under canonical/', () => {
    const chart = extractResidual(loadSkill('aid-create-ticket'));
    for (const node of chart.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('R2 nodes have 1-line provenance excerpt matching actual file line', () => {
    const chart = extractResidual(loadSkill('aid-create-ticket'));
    for (const node of chart.nodes) {
      const p = node.provenance;
      const lineCount = p.excerpt.split('\n').length;
      expect(lineCount).toBe(p.endLine - p.startLine + 1);
    }
  });

  it('R3 (aid-config) nodes have provenance.file under canonical/', () => {
    const chart = extractResidual(loadSkill('aid-config'));
    for (const node of chart.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });

  it('R5 nodes have provenance.file under canonical/', () => {
    const chart = extractResidual(loadSkill('aid-ask'));
    for (const node of chart.nodes) {
      expect(node.provenance.file).toMatch(/^canonical\//);
    }
  });
});

// ── Shape and extractor field ─────────────────────────────────────────────────

describe('chart fields', () => {
  it('shape is always residual', () => {
    const chart = extractResidual(parseSkill(`---\nname: t\ndescription: T\n---\n`, 't'));
    expect(chart.shape).toBe('residual');
  });

  it('extractor is always residual', () => {
    const chart = extractResidual(parseSkill(`---\nname: t\ndescription: T\n---\n`, 't'));
    expect(chart.extractor).toBe('residual');
  });

  it('title is "<skill> — state flow"', () => {
    const chart = extractResidual(parseSkill(`---\nname: my-skill\ndescription: T\n---\n`, 'my-skill'));
    expect(chart.title).toBe('my-skill \u2014 state flow');
  });

  it('sources contains the SKILL.md file', () => {
    const params = loadSkill('aid-config');
    const chart = extractResidual(params);
    expect(chart.sources).toContain('canonical/skills/aid-config/SKILL.md');
  });
});

// ── parseAsciiStateMap is the single shared token parser ─────────────────────

describe('parseAsciiStateMap — export signature', () => {
  it('is exported as a named function', () => {
    expect(typeof parseAsciiStateMap).toBe('function');
  });

  it('accepts a string and returns { names, conditions }', () => {
    const r = parseAsciiStateMap('[A] -> [B]');
    expect(r).toHaveProperty('names');
    expect(r).toHaveProperty('conditions');
    expect(Array.isArray(r.names)).toBe(true);
    expect(Array.isArray(r.conditions)).toBe(true);
  });

  it('names and conditions arrays are same length', () => {
    const r = parseAsciiStateMap('[A] -> [B(cond)] -> [C]');
    expect(r.names.length).toBe(r.conditions.length);
  });
});
