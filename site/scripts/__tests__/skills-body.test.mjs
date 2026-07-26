// skills-body.test.mjs — Unit tests for body.mjs (task-010).
//
// Covers every acceptance criterion for body.mjs:
//   AC-1  BODY_PROVIDERS is a static empty array literal.
//   AC-2  BODY_APPENDERS is a static empty array literal.
//   AC-3  renderSkillBody returns '' when both registries are empty.
//   AC-4  No dynamic import(), no readdirSync/glob call (static literals only).
//   AC-5  No registration side effect at import time.
//   AC-6  renderSkillBody returns first-provider-then-appenders when populated
//         (contract test with in-test stubs — registries mutated then restored).
//
// The real body.mjs module is imported and driven directly.
// Fixtures are minimal SkillRecord-shaped objects sufficient for the tests.

import { describe, it, expect, afterEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BODY_PROVIDERS, BODY_APPENDERS, renderSkillBody } from '../skills/body.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BODY_SRC = resolve(__dirname, '../skills/body.mjs');

// ── Minimal fixture ───────────────────────────────────────────────────────────

const EMPTY_SKILL = { dirName: 'aid-fixture', fields: [], field: () => undefined };

// ── AC-1 / AC-2: Static array literals ───────────────────────────────────────

describe('BODY_PROVIDERS', () => {
  it('is an Array', () => {
    expect(Array.isArray(BODY_PROVIDERS)).toBe(true);
  });

  it('is empty on module load (no pre-registered providers)', () => {
    // Ensure no import-time side effect has pushed entries.
    expect(BODY_PROVIDERS).toHaveLength(0);
  });

  it('is declared as "export const BODY_PROVIDERS = []" in the source (static literal)', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).toMatch(/export const BODY_PROVIDERS\s*=\s*\[\]/);
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

// ── AC-3: renderSkillBody returns '' when both registries are empty ───────────

describe('renderSkillBody — empty registries (AC-3)', () => {
  it('returns empty string for any skill when both registries are empty', () => {
    expect(renderSkillBody(EMPTY_SKILL)).toBe('');
  });

  it('is deterministic — repeated calls return the same result', () => {
    expect(renderSkillBody(EMPTY_SKILL)).toBe(renderSkillBody(EMPTY_SKILL));
  });

  it('returns empty string for a skill with multiple fields', () => {
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
