// flow-classify.test.mjs — Unit tests for lib/flow-graph/classify.mjs (task-021).
//
// Covers every acceptance criterion for the body-inspection shape classifier:
//   AC-1  Never reads shortcut-catalog.yml or its `repurpose` flag (source grep).
//   AC-2  D1 requires EXACT heading text and a State+Advance table (not "contains Dispatch").
//   AC-3  aid-triage → dispatch-table despite having ## State Machine + ## State: headings.
//   AC-4  aid-review → inline-states; aid-test-security → sibling-doorway (both repurpose: true).
//   AC-5  Classification is total: every input returns one of the five shapes.
//   AC-6  delegatesTo is the parent dir for D3; null (never undefined) for all other shapes.
//   AC-7  evidence identifies the discriminator and the body construct that triggered it.
//   AC-8  No per-shape or corpus count literals in the module or its tests.
//
// Mutation-proving notes (§ Definition of done):
//   Each discriminator has a "fires" fixture AND a "near-miss" fixture that
//   differs by one edit.  Breaking the corresponding branch in classify.mjs makes
//   only the fires fixture fail; restoring it makes both pass.
//
// All assertions drive the REAL classifySkill — no re-implementation.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { classifySkill } from '../lib/flow-graph/classify.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const CLASSIFY_SRC = resolve(__dirname, '../lib/flow-graph/classify.mjs');

// ── Fixture helpers ───────────────────────────────────────────────────────────

/** Wrap a raw body string in a minimal skill object. */
function makeSkill(body, overrides = {}) {
  return { name: 'fixture', dir: 'fixture', frontmatter: {}, body, ...overrides };
}

/**
 * Read the body of a real skill from canonical/skills/<dir>/SKILL.md.
 * Mirrors the extraction logic in discover.mjs: text after the closing `---`.
 * @param {string} dir
 * @returns {string}
 */
function readRealBody(dir) {
  const skillPath = resolve(REPO_ROOT, 'canonical/skills', dir, 'SKILL.md');
  const text = readFileSync(skillPath, 'utf8').replace(/\r\n?/g, '\n');
  const lines = text.split('\n');
  let fenceEnd = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') { fenceEnd = i; break; }
  }
  return lines.slice(fenceEnd + 1).join('\n');
}

// ── AC-1: No catalog / repurpose reads ───────────────────────────────────────

describe('AC-1 — source never reads catalog or repurpose', () => {
  const src = readFileSync(CLASSIFY_SRC, 'utf8');

  it('source does not reference shortcut-catalog.yml', () => {
    expect(src).not.toMatch(/shortcut-catalog/);
  });

  it('source does not reference the repurpose field', () => {
    expect(src).not.toMatch(/\brepurpose\b/);
  });
});

// ── D1: dispatch-table ────────────────────────────────────────────────────────

// Minimal body: ## Dispatch followed by a table with both State and Advance columns.
const D1_DISPATCH_BODY = `
## Dispatch

| State | Worker | Advance |
|-------|--------|---------|
| INTAKE | inline | NEXT |
| DONE | inline | halt |
`;

// Minimal body: ## State Machine followed by a table with both State and Advance columns.
const D1_STATE_MACHINE_BODY = `
## State Machine

| State | Detail | Advance |
|-------|--------|---------|
| START | below | FINISH |
`;

// Near-miss: heading contains "Dispatch" but is not exactly "Dispatch".
const D1_NEAR_MISS_HEADING = `
## Dispatch Protocol

| State | Worker | Advance |
|-------|--------|---------|
| INTAKE | inline | NEXT |
`;

// Near-miss: exact heading but section has no table at all.
const D1_NEAR_MISS_NO_TABLE = `
## Dispatch

Route to the right state based on the input.

## Other

Some unrelated content.
`;

// Near-miss: exact heading, table present, but "Advance" column is missing.
const D1_NEAR_MISS_NO_ADVANCE = `
## Dispatch

| State | Worker | Next |
|-------|--------|------|
| INTAKE | inline | NEXT |
`;

// Near-miss: exact heading, table present, but "State" column is missing.
const D1_NEAR_MISS_NO_STATE = `
## Dispatch

| Input | Worker | Advance |
|-------|--------|---------|
| foo | inline | NEXT |
`;

describe('D1 dispatch-table', () => {
  it('fires when ## Dispatch heading is followed by a State+Advance table', () => {
    const result = classifySkill(makeSkill(D1_DISPATCH_BODY));
    expect(result.shape).toBe('dispatch-table');
  });

  it('fires when ## State Machine heading is followed by a State+Advance table', () => {
    const result = classifySkill(makeSkill(D1_STATE_MACHINE_BODY));
    expect(result.shape).toBe('dispatch-table');
  });

  it('returns delegatesTo null for D1 matches', () => {
    const result = classifySkill(makeSkill(D1_DISPATCH_BODY));
    expect(result.delegatesTo).toBeNull();
  });

  it('evidence mentions D1 and the heading text', () => {
    const result = classifySkill(makeSkill(D1_DISPATCH_BODY));
    const joined = result.evidence.join(' ');
    expect(joined).toMatch(/D1/);
    expect(joined).toMatch(/dispatch-table/);
    expect(joined).toMatch(/Dispatch/);
  });

  // ── Near-miss boundary cases ─────────────────────────────────────────────

  it('near-miss: ## Dispatch Protocol does NOT fire D1 (heading not exact)', () => {
    const result = classifySkill(makeSkill(D1_NEAR_MISS_HEADING));
    expect(result.shape).not.toBe('dispatch-table');
  });

  it('near-miss: ## Dispatch with no table does NOT fire D1', () => {
    const result = classifySkill(makeSkill(D1_NEAR_MISS_NO_TABLE));
    expect(result.shape).not.toBe('dispatch-table');
  });

  it('near-miss: ## Dispatch table missing Advance column does NOT fire D1', () => {
    const result = classifySkill(makeSkill(D1_NEAR_MISS_NO_ADVANCE));
    expect(result.shape).not.toBe('dispatch-table');
  });

  it('near-miss: ## Dispatch table missing State column does NOT fire D1', () => {
    const result = classifySkill(makeSkill(D1_NEAR_MISS_NO_STATE));
    expect(result.shape).not.toBe('dispatch-table');
  });

  // ── AC-3: aid-triage precedence test ────────────────────────────────────

  it('AC-3: aid-triage classifies as dispatch-table (## State Machine + ## State: headings present)', () => {
    const body = readRealBody('aid-triage');
    // Verify the fixture actually contains the competing headings, so this
    // test exercises precedence rather than a trivial single-discriminator case.
    expect(body).toMatch(/^## State Machine\s*$/m);
    expect(body).toMatch(/^## State:\s+\S/m);
    const result = classifySkill(makeSkill(body));
    expect(result.shape).toBe('dispatch-table');
  });
});

// ── D2: inline-states ─────────────────────────────────────────────────────────

const D2_TWO_STATES_BODY = `
# Some Skill

## State: INTAKE

Capture input here.

## State: DONE

Print result and halt.
`;

const D2_THREE_STATES_BODY = `
## State: A

Step A.

## State: B

Step B.

## State: C

Step C.
`;

// Near-miss: only one ## State: heading.
const D2_NEAR_MISS_ONE_STATE = `
# Some Skill

## State: INTAKE

Capture input here.

## Other

Unrelated section.
`;

// Near-miss: ## State: with only trailing whitespace (no non-whitespace after).
const D2_NEAR_MISS_EMPTY_STATE = `
# Some Skill

## State: 

Some content here.

## State: 

More content.
`;

describe('D2 inline-states', () => {
  it('fires when two ## State: headings are present', () => {
    const result = classifySkill(makeSkill(D2_TWO_STATES_BODY));
    expect(result.shape).toBe('inline-states');
  });

  it('fires when three or more ## State: headings are present', () => {
    const result = classifySkill(makeSkill(D2_THREE_STATES_BODY));
    expect(result.shape).toBe('inline-states');
  });

  it('returns delegatesTo null for D2 matches', () => {
    const result = classifySkill(makeSkill(D2_TWO_STATES_BODY));
    expect(result.delegatesTo).toBeNull();
  });

  it('evidence mentions D2 and the heading count', () => {
    const result = classifySkill(makeSkill(D2_TWO_STATES_BODY));
    const joined = result.evidence.join(' ');
    expect(joined).toMatch(/D2/);
    expect(joined).toMatch(/inline-states/);
  });

  // ── Near-miss boundary cases ─────────────────────────────────────────────

  it('near-miss: exactly one ## State: heading does NOT fire D2', () => {
    const result = classifySkill(makeSkill(D2_NEAR_MISS_ONE_STATE));
    expect(result.shape).not.toBe('inline-states');
  });

  it('near-miss: ## State: with no following non-whitespace does NOT fire D2', () => {
    const result = classifySkill(makeSkill(D2_NEAR_MISS_EMPTY_STATE));
    expect(result.shape).not.toBe('inline-states');
  });

  // ── AC-4: aid-review real-file test ─────────────────────────────────────

  it('AC-4: aid-review classifies as inline-states (repurpose: true)', () => {
    const body = readRealBody('aid-review');
    // Verify fixture has 2+ ## State: headings so the test exercises the real discriminator.
    const count = (body.match(/^## State:\s+\S/gm) || []).length;
    expect(count).toBeGreaterThanOrEqual(2);
    const result = classifySkill(makeSkill(body));
    expect(result.shape).toBe('inline-states');
  });

  it('AC-4: aid-review delegatesTo is null', () => {
    const body = readRealBody('aid-review');
    const result = classifySkill(makeSkill(body));
    expect(result.delegatesTo).toBeNull();
  });
});

// ── D3: sibling-doorway ───────────────────────────────────────────────────────

const D3_BODY = `
# Test (kind-sibling of /aid-test)

This skill carries no logic of its own.

Execute \`canonical/skills/aid-test/SKILL.md\` exactly as written.
`;

// D3 with two occurrences of the SAME target (should still be D3 — one distinct name).
const D3_SAME_REF_TWICE_BODY = `
# Kind-Sibling

This skill carries no logic of its own — its behavior is defined by
canonical/skills/aid-parent/SKILL.md.

Execute canonical/skills/aid-parent/SKILL.md exactly as written.
`;

// Near-miss: "no logic of its own" but zero SKILL.md references.
const D3_NEAR_MISS_NO_REF = `
# Some Skill

This skill carries no logic of its own.

Route to the common implementation (path not given here).
`;

// Near-miss: exactly one SKILL.md reference but no "no logic of its own" phrase.
const D3_NEAR_MISS_NO_PHRASE = `
# Some Skill

Execute \`canonical/skills/aid-parent/SKILL.md\` exactly as written.
`;

// Near-miss: "no logic of its own" but TWO DISTINCT SKILL.md references.
const D3_NEAR_MISS_TWO_REFS = `
# Dual Delegator

This skill carries no logic of its own.

See canonical/skills/aid-first/SKILL.md and canonical/skills/aid-second/SKILL.md.
`;

describe('D3 sibling-doorway', () => {
  it('fires when "no logic of its own" and exactly one distinct SKILL.md reference', () => {
    const result = classifySkill(makeSkill(D3_BODY));
    expect(result.shape).toBe('sibling-doorway');
  });

  it('delegatesTo is the referenced skill directory name', () => {
    const result = classifySkill(makeSkill(D3_BODY));
    expect(result.delegatesTo).toBe('aid-test');
  });

  it('two occurrences of the same target still fires D3 (one distinct name)', () => {
    const result = classifySkill(makeSkill(D3_SAME_REF_TWICE_BODY));
    expect(result.shape).toBe('sibling-doorway');
    expect(result.delegatesTo).toBe('aid-parent');
  });

  it('evidence mentions D3, the phrase, and the delegated skill', () => {
    const result = classifySkill(makeSkill(D3_BODY));
    const joined = result.evidence.join(' ');
    expect(joined).toMatch(/D3/);
    expect(joined).toMatch(/sibling-doorway/);
    expect(joined).toMatch(/aid-test/);
  });

  // ── Near-miss boundary cases ─────────────────────────────────────────────

  it('near-miss: "no logic of its own" but no SKILL.md reference does NOT fire D3', () => {
    const result = classifySkill(makeSkill(D3_NEAR_MISS_NO_REF));
    expect(result.shape).not.toBe('sibling-doorway');
  });

  it('near-miss: one SKILL.md reference but no "no logic of its own" does NOT fire D3', () => {
    const result = classifySkill(makeSkill(D3_NEAR_MISS_NO_PHRASE));
    expect(result.shape).not.toBe('sibling-doorway');
  });

  it('near-miss: two distinct SKILL.md references does NOT fire D3', () => {
    const result = classifySkill(makeSkill(D3_NEAR_MISS_TWO_REFS));
    expect(result.shape).not.toBe('sibling-doorway');
  });

  // ── AC-4: aid-test-security real-file test ───────────────────────────────

  it('AC-4: aid-test-security classifies as sibling-doorway (repurpose: true)', () => {
    const body = readRealBody('aid-test-security');
    // Verify the fixture has the discriminating phrase so this test is non-trivial.
    expect(body).toMatch(/no logic of its own/i);
    const result = classifySkill(makeSkill(body));
    expect(result.shape).toBe('sibling-doorway');
  });

  it('AC-4: aid-test-security delegatesTo is "aid-test"', () => {
    const body = readRealBody('aid-test-security');
    const result = classifySkill(makeSkill(body));
    expect(result.delegatesTo).toBe('aid-test');
  });
});

// ── D4: engine-doorway ────────────────────────────────────────────────────────

const D4_GENERATED_BODY = `
# Shortcut

<!-- GENERATED by .claude/skills/generate-profile/scripts/build-shortcut-skills.py from catalog -->

This is a generated shortcut skill.
`;

const D4_ENGINE_REF_BODY = `
# Shortcut

Bind VERB and run \`canonical/aid/templates/shortcut-engine.md\`.
`;

// Near-miss: neither GENERATED comment nor engine ref.
const D4_NEAR_MISS = `
# Some Skill

This is plain prose with no special markers.
`;

describe('D4 engine-doorway', () => {
  it('fires on GENERATED-by-build-shortcut-skills.py HTML comment', () => {
    const result = classifySkill(makeSkill(D4_GENERATED_BODY));
    expect(result.shape).toBe('engine-doorway');
  });

  it('fires on reference to canonical/aid/templates/shortcut-engine.md', () => {
    const result = classifySkill(makeSkill(D4_ENGINE_REF_BODY));
    expect(result.shape).toBe('engine-doorway');
  });

  it('returns delegatesTo null for D4 matches', () => {
    expect(classifySkill(makeSkill(D4_GENERATED_BODY)).delegatesTo).toBeNull();
    expect(classifySkill(makeSkill(D4_ENGINE_REF_BODY)).delegatesTo).toBeNull();
  });

  it('evidence mentions D4 and engine-doorway', () => {
    const joined = classifySkill(makeSkill(D4_GENERATED_BODY)).evidence.join(' ');
    expect(joined).toMatch(/D4/);
    expect(joined).toMatch(/engine-doorway/);
  });

  it('near-miss: no GENERATED comment and no engine ref does NOT fire D4', () => {
    const result = classifySkill(makeSkill(D4_NEAR_MISS));
    expect(result.shape).not.toBe('engine-doorway');
  });

  // ── Real engine-doorway skill ────────────────────────────────────────────

  it('real aid-add body classifies as engine-doorway', () => {
    const body = readRealBody('aid-add');
    const result = classifySkill(makeSkill(body));
    expect(result.shape).toBe('engine-doorway');
    expect(result.delegatesTo).toBeNull();
  });
});

// ── D5: residual ─────────────────────────────────────────────────────────────

const D5_EMPTY_BODY = '';
const D5_PROSE_BODY = `
# Plain Skill

This skill just has prose. No state machine, no dispatch table, nothing special.
`;

describe('D5 residual', () => {
  it('fires when no other discriminator matches (empty body)', () => {
    const result = classifySkill(makeSkill(D5_EMPTY_BODY));
    expect(result.shape).toBe('residual');
  });

  it('fires when no other discriminator matches (plain prose body)', () => {
    const result = classifySkill(makeSkill(D5_PROSE_BODY));
    expect(result.shape).toBe('residual');
  });

  it('returns delegatesTo null for D5 residual', () => {
    expect(classifySkill(makeSkill(D5_EMPTY_BODY)).delegatesTo).toBeNull();
    expect(classifySkill(makeSkill(D5_PROSE_BODY)).delegatesTo).toBeNull();
  });

  it('evidence mentions D5 and residual', () => {
    const joined = classifySkill(makeSkill(D5_EMPTY_BODY)).evidence.join(' ');
    expect(joined).toMatch(/D5/);
    expect(joined).toMatch(/residual/);
  });
});

// ── AC-5: classification is total ────────────────────────────────────────────

describe('AC-5 — classification is total (no shape can be missing)', () => {
  const cases = [
    ['dispatch-table body', D1_DISPATCH_BODY],
    ['inline-states body', D2_TWO_STATES_BODY],
    ['sibling-doorway body', D3_BODY],
    ['engine-doorway body', D4_GENERATED_BODY],
    ['residual body', D5_PROSE_BODY],
    ['empty body', D5_EMPTY_BODY],
  ];

  const VALID_SHAPES = new Set([
    'dispatch-table',
    'inline-states',
    'sibling-doorway',
    'engine-doorway',
    'residual',
  ]);

  for (const [label, body] of cases) {
    it(`${label} returns a valid shape`, () => {
      const { shape } = classifySkill(makeSkill(body));
      expect(VALID_SHAPES.has(shape)).toBe(true);
    });
  }
});

// ── AC-6: delegatesTo is exactly null (not undefined) for non-D3 shapes ───────

describe('AC-6 — delegatesTo is null for non-D3 shapes', () => {
  it('D1 result has delegatesTo strictly equal to null', () => {
    expect(classifySkill(makeSkill(D1_DISPATCH_BODY)).delegatesTo).toBeNull();
  });

  it('D2 result has delegatesTo strictly equal to null', () => {
    expect(classifySkill(makeSkill(D2_TWO_STATES_BODY)).delegatesTo).toBeNull();
  });

  it('D4 result has delegatesTo strictly equal to null', () => {
    expect(classifySkill(makeSkill(D4_GENERATED_BODY)).delegatesTo).toBeNull();
  });

  it('D5 result has delegatesTo strictly equal to null', () => {
    expect(classifySkill(makeSkill(D5_PROSE_BODY)).delegatesTo).toBeNull();
  });

  it('delegatesTo is present as a property key (not absent) for all shapes', () => {
    for (const body of [
      D1_DISPATCH_BODY, D2_TWO_STATES_BODY, D3_BODY,
      D4_GENERATED_BODY, D5_PROSE_BODY,
    ]) {
      const result = classifySkill(makeSkill(body));
      expect(Object.prototype.hasOwnProperty.call(result, 'delegatesTo')).toBe(true);
    }
  });
});

// ── Precedence order: D1 beats D2, D2 beats D3, D3 beats D4 ─────────────────

// Body qualifying for BOTH D1 and D2.
const PRECEDENCE_D1_D2_BODY = `
## Dispatch

| State | Worker | Advance |
|-------|--------|---------|
| INTAKE | inline | DONE |

## State: INTAKE

Step one.

## State: DONE

Step two.
`;

// Body qualifying for BOTH D2 and D3.
const PRECEDENCE_D2_D3_BODY = `
## State: INTAKE

Capture input.

## State: DONE

This skill carries no logic of its own.

Execute canonical/skills/aid-parent/SKILL.md exactly.
`;

// Body qualifying for BOTH D3 and D4.
const PRECEDENCE_D3_D4_BODY = `
# Kind-Sibling

This skill carries no logic of its own.

Execute canonical/skills/aid-parent/SKILL.md exactly as written.

Bind VERB and run canonical/aid/templates/shortcut-engine.md.
`;

// Body qualifying for BOTH D2 and D4.
const PRECEDENCE_D2_D4_BODY = `
## State: INTAKE

Step one.

## State: DONE

Step two.

Bind VERB and run canonical/aid/templates/shortcut-engine.md.
`;

describe('Discriminator precedence (D1 > D2 > D3 > D4 > D5)', () => {
  it('D1 beats D2: dispatch-table even when ## State: headings are also present', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D1_D2_BODY));
    expect(result.shape).toBe('dispatch-table');
  });

  it('D2 beats D3: inline-states even when sibling-doorway markers are also present', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D2_D3_BODY));
    expect(result.shape).toBe('inline-states');
  });

  it('D3 beats D4: sibling-doorway even when engine ref is also present', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D3_D4_BODY));
    expect(result.shape).toBe('sibling-doorway');
  });

  it('D2 beats D4: inline-states even when engine ref is also present', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D2_D4_BODY));
    expect(result.shape).toBe('inline-states');
  });

  it('D2 beats D3 — delegatesTo is null (not the sibling name)', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D2_D3_BODY));
    expect(result.delegatesTo).toBeNull();
  });

  it('D3 beats D4 — delegatesTo is the parent skill name', () => {
    const result = classifySkill(makeSkill(PRECEDENCE_D3_D4_BODY));
    expect(result.delegatesTo).toBe('aid-parent');
  });
});

// ── AC-7: evidence format ─────────────────────────────────────────────────────

describe('AC-7 — evidence identifies discriminator and triggering construct', () => {
  it('D1 evidence names the heading text', () => {
    const result = classifySkill(makeSkill(D1_DISPATCH_BODY));
    expect(result.evidence.some((e) => /Dispatch/.test(e))).toBe(true);
  });

  it('D1 evidence names the table header row', () => {
    const result = classifySkill(makeSkill(D1_DISPATCH_BODY));
    expect(result.evidence.some((e) => /State.*Advance|Advance.*State/.test(e))).toBe(true);
  });

  it('D2 evidence names the ## State: headings', () => {
    const result = classifySkill(makeSkill(D2_TWO_STATES_BODY));
    expect(result.evidence.some((e) => /## State:/.test(e))).toBe(true);
  });

  it('D3 evidence names the no-logic phrase and the delegated skill', () => {
    const result = classifySkill(makeSkill(D3_BODY));
    const joined = result.evidence.join(' ');
    expect(joined).toMatch(/no logic of its own/i);
    expect(joined).toMatch(/aid-test/);
  });

  it('D4 evidence names the triggering construct (GENERATED or engine ref)', () => {
    const r1 = classifySkill(makeSkill(D4_GENERATED_BODY));
    expect(r1.evidence.some((e) => /GENERATED/i.test(e))).toBe(true);

    const r2 = classifySkill(makeSkill(D4_ENGINE_REF_BODY));
    expect(r2.evidence.some((e) => /shortcut-engine/.test(e))).toBe(true);
  });

  it('evidence is a non-empty array for every shape', () => {
    for (const body of [
      D1_DISPATCH_BODY, D2_TWO_STATES_BODY, D3_BODY,
      D4_GENERATED_BODY, D5_PROSE_BODY,
    ]) {
      const { evidence } = classifySkill(makeSkill(body));
      expect(Array.isArray(evidence)).toBe(true);
      expect(evidence.length).toBeGreaterThan(0);
    }
  });
});
