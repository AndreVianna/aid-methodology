// skills-body.test.mjs — Unit tests for body.mjs (task-010 / task-029).
//
// Covers every acceptance criterion for body.mjs:
//   AC-1  BODY_PROVIDERS is a static array literal with the flow-chart-authored entry (task-029).
//   AC-2  BODY_APPENDERS is a static empty array literal.
//   AC-3  renderSkillBody returns '' for unclaimed skills; non-empty for claimed skills.
//   AC-4  No dynamic import(), no readdirSync/glob call (static literals only).
//   AC-5  No registration side effect at import time.
//   AC-6  renderSkillBody returns first-provider-then-appenders when populated
//         (contract test with in-test stubs — registries mutated then restored).
//
// The real body.mjs module is imported and driven directly.
// Fixtures are minimal SkillRecord-shaped objects sufficient for the tests.
// All assertions are mutation-proved (break source → that specific test fails).

import { describe, it, expect, afterEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BODY_PROVIDERS, BODY_APPENDERS, renderSkillBody } from '../skills/body.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BODY_SRC = resolve(__dirname, '../skills/body.mjs');

// ── Fixtures ──────────────────────────────────────────────────────────────────

/** A skill with no body — not claimed by any provider. */
const EMPTY_SKILL = { dirName: 'aid-fixture', fields: [], field: () => undefined };

/**
 * A skill whose body classifies as inline-states → claimed by flow-chart-authored.
 * The body is the minimum needed for applies() to classify it; render() reads
 * the real SKILL.md from disk using dirName.
 */
const INLINE_BODY =
  '## State: ELICIT\n\nContent.\n\n**Advance:** → PRESENT\n\n## State: PRESENT\n\nContent.\n\n**Advance:** HALT\n';

const AID_REVIEW_SKILL = { dirName: 'aid-review', body: INLINE_BODY };

// ── AC-1 / AC-2: Static array literals ───────────────────────────────────────

describe('BODY_PROVIDERS', () => {
  it('is an Array', () => {
    expect(Array.isArray(BODY_PROVIDERS)).toBe(true);
  });

  it('has exactly one registered provider (flow-chart-authored, added by task-029)', () => {
    // Mutation probe: remove the flow-chart-authored entry → toHaveLength(1) fails.
    expect(BODY_PROVIDERS).toHaveLength(1);
    expect(BODY_PROVIDERS[0].id).toBe('flow-chart-authored');
  });

  it('is declared as a static array literal containing the flow-chart-authored entry in the source', () => {
    // Mutation probe: change id to 'flow-chart-wrong' → toContain fails.
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).toMatch(/export const BODY_PROVIDERS\s*=\s*\[/);
    expect(src).toContain("id: 'flow-chart-authored'");
  });
});

describe('BODY_APPENDERS', () => {
  it('is an Array', () => {
    expect(Array.isArray(BODY_APPENDERS)).toBe(true);
  });

  it('is empty on module load (no pre-registered appenders)', () => {
    expect(BODY_APPENDERS).toHaveLength(0);
  });

  it('is declared as "export const BODY_APPENDERS = []" in the source (static literal)', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).toMatch(/export const BODY_APPENDERS\s*=\s*\[\]/);
  });
});

// ── AC-4: No dynamic imports, no filesystem access ───────────────────────────

describe('static array literal safety (AC-4)', () => {
  it('source contains no dynamic import() call', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).not.toMatch(/\bimport\s*\(/);
  });

  it('source contains no readdirSync call', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).not.toMatch(/\breaddirSync\b/);
  });

  it('source contains no glob call', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).not.toMatch(/\bglob\s*\(/);
  });

  it('source contains no globSync call', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).not.toMatch(/\bglobSync\b/);
  });
});

// ── AC-3: renderSkillBody — claimed vs unclaimed skill ────────────────────────

describe('renderSkillBody — unclaimed skill (AC-3)', () => {
  // All three tests below use a skill no provider claims (no body field).
  // They stay green even if the provider's applies() is broken (always false).
  // The mutation-proof companion tests below use a CLAIMED skill.

  it('returns empty string for a skill with no body (no provider claims it)', () => {
    // Mutation probe: if provider.applies() returned true here → render() would try
    // buildFlowChart('aid-fixture') → throws (file not found) → test errors, not green.
    expect(renderSkillBody(EMPTY_SKILL)).toBe('');
  });

  it('is deterministic — repeated calls return the same result', () => {
    expect(renderSkillBody(EMPTY_SKILL)).toBe(renderSkillBody(EMPTY_SKILL));
  });

  it('returns empty string for a skill with multiple fields but no body', () => {
    const skill = {
      dirName: 'aid-multi',
      fields: [
        { key: 'name', kind: 'scalar', value: 'aid-multi', line: 1 },
        { key: 'description', kind: 'scalar', value: 'A skill with fields.', line: 2 },
      ],
      field: (k) => undefined,
    };
    expect(renderSkillBody(skill)).toBe('');
  });

  it('returns a non-empty string beginning with ## Flow for a claimed skill (aid-review)', () => {
    // Mutation probe: break applies() to always return false → output is '' → fails.
    // Mutation probe: break render() to return '' → toMatch fails.
    const output = renderSkillBody(AID_REVIEW_SKILL);
    expect(output).toMatch(/^## Flow\n/);
  });
});

// ── AC-6: renderSkillBody contract with populated registries ─────────────────
//
// These tests mutate the exported arrays in-place to verify the contract,
// then restore them. This is the only correct way to test a seam whose sole
// extension mechanism is array mutation (no registration function exists by
// design, to keep the seam static).

describe('renderSkillBody — contract with populated registries (AC-6)', () => {
  afterEach(() => {
    // Restore both registries to empty after each test.
    BODY_PROVIDERS.length = 0;
    BODY_APPENDERS.length = 0;
  });

  it('returns the first matching provider output when a provider applies', () => {
    BODY_PROVIDERS.push({
      id: 'test-provider',
      applies: () => true,
      render: () => '## Body\n\nProvider content.\n',
    });
    expect(renderSkillBody(EMPTY_SKILL)).toBe('## Body\n\nProvider content.\n');
  });

  it('returns empty string when the provider does not apply', () => {
    BODY_PROVIDERS.push({
      id: 'non-matching',
      applies: () => false,
      render: () => '## Body\n\nNot rendered.\n',
    });
    expect(renderSkillBody(EMPTY_SKILL)).toBe('');
  });

  it('first-match-wins: only the first matching provider is called', () => {
    let firstCalled = false;
    let secondCalled = false;
    BODY_PROVIDERS.push(
      { id: 'first', applies: () => true, render: () => { firstCalled = true; return 'first\n'; } },
      { id: 'second', applies: () => true, render: () => { secondCalled = true; return 'second\n'; } }
    );
    const result = renderSkillBody(EMPTY_SKILL);
    expect(result).toBe('first\n');
    expect(firstCalled).toBe(true);
    expect(secondCalled).toBe(false);
  });

  it('all appenders run and their output is concatenated after the provider', () => {
    BODY_PROVIDERS.push({
      id: 'base-provider',
      applies: () => true,
      render: () => '## Flow\n\nBody.\n',
    });
    BODY_APPENDERS.push(
      { id: 'a1', render: () => '\n## Appendix A\n\nA.\n' },
      { id: 'a2', render: () => '\n## Appendix B\n\nB.\n' }
    );
    const result = renderSkillBody(EMPTY_SKILL);
    expect(result).toBe('## Flow\n\nBody.\n\n## Appendix A\n\nA.\n\n## Appendix B\n\nB.\n');
  });

  it('appenders still run when no provider matches', () => {
    BODY_PROVIDERS.push({ id: 'skipped', applies: () => false, render: () => 'x' });
    BODY_APPENDERS.push({ id: 'a1', render: () => '## Appendix\n\nContent.\n' });
    const result = renderSkillBody(EMPTY_SKILL);
    expect(result).toBe('## Appendix\n\nContent.\n');
  });

  it('appenders receive the skill record and can use it', () => {
    const captured = [];
    BODY_APPENDERS.push({ id: 'capture', render: (s) => { captured.push(s.dirName); return ''; } });
    renderSkillBody(EMPTY_SKILL);
    expect(captured).toEqual(['aid-fixture']);
  });
});
