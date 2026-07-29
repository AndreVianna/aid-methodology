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

import { describe, it, expect, afterEach, beforeEach } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BODY_PROVIDERS, BODY_APPENDERS, renderSkillBody } from '../skills/body.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BODY_SRC = resolve(__dirname, '../skills/body.mjs');
const REPO_ROOT = resolve(__dirname, '../../../');

// Snapshot the shipped registries at import, before any test mutates them, so the
// afterEach below can put them back exactly as the module declared them.
const REAL_PROVIDERS = [...BODY_PROVIDERS];
const REAL_APPENDERS = [...BODY_APPENDERS];

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

  it('has exactly two registered providers, in declaration order', () => {
    // Was one (flow-chart-authored, task-029); task-037 adds flow-chart-doorway, and
    // feature-004's is the last provider this work registers. Ids are asserted rather
    // than only the count, so swapping one for a wrong entry fails too.
    expect(BODY_PROVIDERS.map((p) => p.id)).toEqual([
      'flow-chart-authored',
      'flow-chart-doorway',
    ]);
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

  it('has exactly one appender on module load (provenanceAppender)', () => {
    expect(BODY_APPENDERS).toHaveLength(1);
    expect(BODY_APPENDERS[0].id).toBe('source-fragments');
  });

  it('is declared as "export const BODY_APPENDERS = [provenanceAppender]" in the source (static literal)', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    expect(src).toMatch(/export const BODY_APPENDERS\s*=\s*\[provenanceAppender\]/);
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
  //
  // BODY_APPENDERS is cleared for this block so the provenanceAppender does not
  // throw when it tries to read a non-existent fixture skill from disk.
  // The appender's own behaviour is tested in provenance-appender.test.mjs.
  beforeEach(() => { BODY_APPENDERS.length = 0; });
  afterEach(() => { BODY_APPENDERS.length = 0; BODY_APPENDERS.push(...REAL_APPENDERS); });

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
  // Clear both registries before each test so the real provenanceAppender
  // does not run against EMPTY_SKILL (fixture, no real file on disk).
  // The afterEach below restores both from the module-load snapshots.
  beforeEach(() => {
    BODY_PROVIDERS.length = 0;
    BODY_APPENDERS.length = 0;
  });

  afterEach(() => {
    // RESTORE the real registries, rather than leaving them empty.
    //
    // This previously emptied both and stopped there, which silently broke every test
    // defined after this block: they saw a registry with no providers, so "no provider
    // claims this skill" was vacuously true. It went unnoticed because nothing later in
    // the file needed the real entries until task-037's partition guard, which then
    // reported all 111 skills unclaimed while the generator was charting all 111 happily.
    BODY_PROVIDERS.length = 0;
    BODY_PROVIDERS.push(...REAL_PROVIDERS);
    BODY_APPENDERS.length = 0;
    BODY_APPENDERS.push(...REAL_APPENDERS);
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

// ── task-037: the provider partition ──────────────────────────────────────────
//
// The DETAIL makes a point of this being a TEST, not a comment: array order must not be
// load-bearing. `classifySkill` returns one value from a five-member enum; the authored
// provider claims three shapes and the doorway provider claims two, and the two sets
// partition the enum. So at most one predicate can ever fire, and the day a sixth shape
// is added it goes unclaimed and these tests fail loudly — rather than being routed
// silently to whichever provider happens to be listed first.

describe('task-037 — exactly one provider claims each skill', () => {
  const dirNames = readdirSync(join(REPO_ROOT, 'canonical', 'skills'), { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();

  /** A SkillRecord shaped like discover.mjs output, read from the live file. */
  function recordFor(dirName) {
    const raw = readFileSync(join(REPO_ROOT, 'canonical', 'skills', dirName, 'SKILL.md'), 'utf8');
    const lines = raw.split('\n').map((l) => l.replace(/\r$/, ''));
    let fences = 0;
    let start = 0;
    for (let i = 0; i < lines.length; i++) {
      if (/^---\s*$/.test(lines[i])) {
        fences++;
        if (fences === 2) { start = i + 1; break; }
      }
    }
    return { dirName, body: lines.slice(start).join('\n'), fields: [] };
  }

  it('every directory under canonical/skills/ is claimed by exactly one provider', () => {
    // Non-vacuity: an empty listing would make the loop below prove nothing.
    expect(dirNames.length).toBeGreaterThan(50);

    const unclaimed = [];
    const contested = [];
    for (const dirName of dirNames) {
      const skill = recordFor(dirName);
      const hits = BODY_PROVIDERS.filter((p) => p.applies(skill)).map((p) => p.id);
      if (hits.length === 0) unclaimed.push(dirName);
      if (hits.length > 1) contested.push(`${dirName}: ${hits.join(' + ')}`);
    }

    // Named, not counted — a bare count would not say which skill regressed.
    expect(unclaimed).toEqual([]);
    expect(contested).toEqual([]);
  });

  it('the two providers partition the five-shape enum — no overlap, no gap', () => {
    const src = readFileSync(BODY_SRC, 'utf8');
    const authored = ['dispatch-table', 'inline-states', 'residual'];
    const doorway = ['engine-doorway', 'sibling-doorway'];

    // Both sets are declared in the module, and they are disjoint and complete.
    for (const s of [...authored, ...doorway]) expect(src).toContain(`'${s}'`);
    expect(authored.filter((s) => doorway.includes(s))).toEqual([]);
    expect([...authored, ...doorway].sort()).toEqual([
      'dispatch-table', 'engine-doorway', 'inline-states', 'residual', 'sibling-doorway',
    ].sort());
  });

  it('both providers emit the identical ## Flow heading, compared not inspected', () => {
    // The AC asks for this to be established by comparing rendered outputs. Two real
    // skills, one of each family.
    const authoredOut = BODY_PROVIDERS
      .find((p) => p.id === 'flow-chart-authored')
      .render(recordFor('aid-review'));
    const doorwayOut = BODY_PROVIDERS
      .find((p) => p.id === 'flow-chart-doorway')
      .render(recordFor('aid-create-api'));

    const headingOf = (s) => s.split('\n')[0];
    expect(headingOf(authoredOut)).toBe('## Flow');
    expect(headingOf(doorwayOut)).toBe(headingOf(authoredOut));
  });

  it('order is not load-bearing: reversing the providers changes nothing', () => {
    // The partition claim, exercised rather than asserted. If the two predicate sets
    // ever overlapped, first-match-wins would make this fail.
    const reversed = [...BODY_PROVIDERS].reverse();
    for (const dirName of dirNames) {
      const skill = recordFor(dirName);
      const forward = BODY_PROVIDERS.find((p) => p.applies(skill));
      const backward = reversed.find((p) => p.applies(skill));
      expect(backward.id).toBe(forward.id);
    }
  });
});
