// skills-groups.test.mjs — Unit tests for site/scripts/skills/groups.mjs
//
// Covers:
//  - Four guards: unassignable skill, curated skill missing,
//    duplicate assignment, full-path catalog row
//  - Family first-appearance ordering (catalog row order)
//  - Placement rules: aid-triage → Support and first;
//    five full-path skills open Definition in pipeline order;
//    aid-deploy / aid-monitor under deploy / monitor families (no special case)
//  - Real-corpus integration: every directory assigns cleanly,
//    no unassignable skill, whole GroupSection[] is well-formed

import { describe, it, expect, afterAll } from 'vitest';
import { readdirSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { CURATED_GROUPS, assignGroups, buildCuratedIndex } from '../skills/groups.mjs';
import { loadShortcutCatalog } from '../skills/catalog.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');

// ── Fixture helpers ───────────────────────────────────────────────────────────

/**
 * Build a minimal SkillRecord-like object for a given dirName.
 * The `field` accessor returns undefined for all keys (no frontmatter).
 * @param {string} dirName
 * @returns {{ dirName: string, route: string, field: (k: string) => undefined }}
 */
function rec(dirName) {
  return {
    dirName,
    route: '/skills/' + dirName + '/',
    field: () => undefined,
  };
}

/**
 * Build a minimal catalog object from a list of { name, verb } pairs.
 * @param {Array<{ name: string, verb: string }>} entries
 * @returns {{ rows: Array<{ name: string, verb: string }>, byName: Map<string, { name: string, verb: string }> }}
 */
function makeCatalog(entries) {
  const rows = entries.map((e) => ({ ...e }));
  const byName = new Map(rows.map((r) => [r.name, r]));
  return { rows, byName };
}

/**
 * Build a minimal records array covering every curated name plus any extras,
 * from the real CURATED_GROUPS constant.
 * @param {string[]} extras  Additional names to include beyond the curated set.
 * @param {string[]} omit    Curated names to omit (for curated-missing guard tests).
 * @returns {ReturnType<typeof rec>[]}
 */
function allCuratedRecs({ extras = [], omit = [] } = {}) {
  const names = new Set();
  for (const entry of CURATED_GROUPS) {
    for (const n of (entry.fullPath || [])) {
      if (!omit.includes(n)) names.add(n);
    }
    for (const n of entry.members) {
      if (!omit.includes(n)) names.add(n);
    }
  }
  for (const n of extras) names.add(n);
  return [...names].map(rec);
}

// ── Guard: unassignable skill ──────────────────────────────────────────────────

describe('guard: unassignable skill', () => {
  it('throws when a record is neither curated nor catalog-backed', () => {
    // Includes all curated names plus one extra that is in neither.
    const records = allCuratedRecs({ extras: ['aid-totally-unknown-xyz'] });
    // Catalog has no entry for aid-totally-unknown-xyz.
    const catalog = makeCatalog([]);

    expect(() => assignGroups(records, catalog)).toThrow('[gen-skills] unassignable skill:');
  });

  it('error message names the unassignable directory', () => {
    const records = allCuratedRecs({ extras: ['aid-mystery-skill'] });
    const catalog = makeCatalog([]);

    expect(() => assignGroups(records, catalog)).toThrow('"aid-mystery-skill"');
  });
});

// ── Guard: curated skill missing ──────────────────────────────────────────────

describe('guard: curated skill missing', () => {
  it('throws when a curated name has no record on disk', () => {
    // Omit one curated name so it is "missing".
    const records = allCuratedRecs({ omit: ['aid-triage'] });
    const catalog = makeCatalog([]);

    expect(() => assignGroups(records, catalog)).toThrow('[gen-skills] curated skill missing:');
  });

  it('error message names the missing curated skill', () => {
    const records = allCuratedRecs({ omit: ['aid-config'] });
    const catalog = makeCatalog([]);

    expect(() => assignGroups(records, catalog)).toThrow('"aid-config"');
  });
});

// ── Guard: duplicate assignment ───────────────────────────────────────────────
//
// The duplicate-assignment guard checks CURATED_GROUPS itself for duplicates.
// Since CURATED_GROUPS is a module-level constant that cannot be overridden in
// a test without module mocking, this suite verifies the guard's invariant:
// the constant currently contains no duplicate names, meaning the guard holds
// and would fire the moment a duplicate is introduced.

describe('guard: duplicate assignment (invariant hold)', () => {
  it('CURATED_GROUPS contains no duplicate names across all entries', () => {
    const allNames = CURATED_GROUPS.flatMap((e) => [
      ...(e.fullPath || []),
      ...e.members,
    ]);
    const nameSet = new Set(allNames);
    // If this fails, the duplicate-assignment guard would throw at runtime.
    expect(nameSet.size).toBe(allNames.length);
  });

  it('assignGroups succeeds with a complete valid corpus (no duplicate guard fires)', () => {
    // A successful run is the positive proof that no duplicate currently exists.
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    expect(() => assignGroups(records, catalog)).not.toThrow();
  });
});

// ── Guard: full-path catalog row ──────────────────────────────────────────────

describe('guard: full-path catalog row', () => {
  it('throws when a full-path skill unexpectedly has a catalog row', () => {
    // aid-describe is a full-path skill. Injecting it into the catalog triggers the guard.
    const records = allCuratedRecs();
    const catalog = makeCatalog([{ name: 'aid-describe', verb: 'describe' }]);

    expect(() => assignGroups(records, catalog)).toThrow('[gen-skills] full-path catalog row:');
  });

  it('error message names the offending full-path skill', () => {
    const records = allCuratedRecs();
    const catalog = makeCatalog([{ name: 'aid-plan', verb: 'plan' }]);

    expect(() => assignGroups(records, catalog)).toThrow('"aid-plan"');
  });
});

// ── Placement rule: aid-triage is Support and first ──────────────────────────

describe('placement: aid-triage in Support, first', () => {
  it('aid-triage is in the Support group', () => {
    const supportEntry = CURATED_GROUPS.find((e) => e.group === 'Support');
    expect(supportEntry).toBeDefined();
    const allMembers = [...(supportEntry.fullPath || []), ...supportEntry.members];
    expect(allMembers).toContain('aid-triage');
  });

  it('aid-triage is the first member of Support', () => {
    const supportEntry = CURATED_GROUPS.find((e) => e.group === 'Support');
    const allMembers = [...(supportEntry.fullPath || []), ...supportEntry.members];
    expect(allMembers[0]).toBe('aid-triage');
  });

  it('assignGroups places aid-triage card first in the Support section', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const supportSection = sections.find((s) => s.group === 'Support');
    expect(supportSection).toBeDefined();
    expect(supportSection.cards.length).toBeGreaterThan(0);
    expect(supportSection.cards[0].name).toBe('aid-triage');
  });
});

// ── Placement rule: five full-path skills open Definition in pipeline order ───

const FULL_PATH_SKILLS = ['aid-describe', 'aid-define', 'aid-specify', 'aid-plan', 'aid-detail'];

describe('placement: five full-path skills open Definition', () => {
  it('Definition entry has fullPath = the five skills in pipeline order', () => {
    const defEntry = CURATED_GROUPS.find((e) => e.group === 'Definition');
    expect(defEntry).toBeDefined();
    expect(defEntry.fullPath).toEqual(FULL_PATH_SKILLS);
  });

  it('none of the five full-path skills appears in any curated members list', () => {
    for (const entry of CURATED_GROUPS) {
      for (const name of entry.members) {
        expect(FULL_PATH_SKILLS).not.toContain(name);
      }
    }
  });

  it('five full-path skills have no catalog row (verified by the real catalog)', () => {
    const { byName } = loadShortcutCatalog(REPO_ROOT);
    for (const name of FULL_PATH_SKILLS) {
      expect(byName.has(name)).toBe(false);
    }
  });

  it('assignGroups places the five skills as the Definition section cards, in pipeline order', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');
    expect(defSection).toBeDefined();

    // cards holds the full-path block (the un-subdivided opening block).
    expect(defSection.cards.map((c) => c.name)).toEqual(FULL_PATH_SKILLS);
  });

  it('none of the five full-path skills appears under any family section', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');
    const familyCardNames = defSection.families.flatMap((f) => f.cards.map((c) => c.name));
    for (const name of FULL_PATH_SKILLS) {
      expect(familyCardNames).not.toContain(name);
    }
  });
});

// ── Placement rule: aid-deploy and aid-monitor under their own families ────────

describe('placement: aid-deploy and aid-monitor as ordinary shortcut families', () => {
  it('aid-deploy is NOT in CURATED_GROUPS', () => {
    const allCurated = CURATED_GROUPS.flatMap((e) => [
      ...(e.fullPath || []),
      ...e.members,
    ]);
    expect(allCurated).not.toContain('aid-deploy');
  });

  it('aid-monitor is NOT in CURATED_GROUPS', () => {
    const allCurated = CURATED_GROUPS.flatMap((e) => [
      ...(e.fullPath || []),
      ...e.members,
    ]);
    expect(allCurated).not.toContain('aid-monitor');
  });

  it('aid-deploy lands under a "deploy" family in the Definition section', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');
    const deployFamily = defSection.families.find((f) => f.verb === 'deploy');
    expect(deployFamily).toBeDefined();
    const deployNames = deployFamily.cards.map((c) => c.name);
    expect(deployNames).toContain('aid-deploy');
  });

  it('aid-monitor lands under a "monitor" family in the Definition section', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');
    const monitorFamily = defSection.families.find((f) => f.verb === 'monitor');
    expect(monitorFamily).toBeDefined();
    const monitorNames = monitorFamily.cards.map((c) => c.name);
    expect(monitorNames).toContain('aid-monitor');
  });

  it('aid-deploy catalog row has verb "deploy"', () => {
    const { byName } = loadShortcutCatalog(REPO_ROOT);
    expect(byName.has('aid-deploy')).toBe(true);
    expect(byName.get('aid-deploy').verb).toBe('deploy');
  });

  it('aid-monitor catalog row has verb "monitor"', () => {
    const { byName } = loadShortcutCatalog(REPO_ROOT);
    expect(byName.has('aid-monitor')).toBe(true);
    expect(byName.get('aid-monitor').verb).toBe('monitor');
  });
});

// ── Family first-appearance ordering ─────────────────────────────────────────

describe('family ordering', () => {
  it('family verb order matches catalog first-appearance order for non-curated skills', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');

    // Build the expected verb order by walking catalog.rows in file order,
    // skipping curated names — the same algorithm groups.mjs uses.
    const allCurated = new Set(
      CURATED_GROUPS.flatMap((e) => [...(e.fullPath || []), ...e.members])
    );
    const expectedVerbOrder = [];
    const seenVerbs = new Set();
    for (const row of catalog.rows) {
      if (allCurated.has(row.name)) continue;
      if (!seenVerbs.has(row.verb)) {
        seenVerbs.add(row.verb);
        expectedVerbOrder.push(row.verb);
      }
    }

    const actualVerbOrder = defSection.families.map((f) => f.verb);
    expect(actualVerbOrder).toEqual(expectedVerbOrder);
  });

  it('card order within a family matches catalog row order', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');

    const allCurated = new Set(
      CURATED_GROUPS.flatMap((e) => [...(e.fullPath || []), ...e.members])
    );

    // For each family, build expected card order from catalog rows in file order.
    for (const family of defSection.families) {
      const expectedNames = catalog.rows
        .filter((r) => !allCurated.has(r.name) && r.verb === family.verb)
        .map((r) => r.name);
      const actualNames = family.cards.map((c) => c.name);
      expect(actualNames).toEqual(expectedNames);
    }
  });

  it('a verb whose every member is curated produces no family section', () => {
    // Every `query` catalog row is curated -- they render inside Knowledge Base
    // Maintenance -- so the verb must produce no family section of its own. The rows
    // are re-derived from the catalog below rather than named here, and the assertion
    // is skipped if that premise ever stops holding, so this cannot go stale as rows
    // are added to or removed from the verb.
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    // Only run this test if 'query' rows are actually all curated.
    const queryRows = catalog.rows.filter((r) => r.verb === 'query');
    const allCurated = new Set(
      CURATED_GROUPS.flatMap((e) => [...(e.fullPath || []), ...e.members])
    );
    const allQueryCurated = queryRows.every((r) => allCurated.has(r.name));

    if (allQueryCurated && queryRows.length > 0) {
      const sections = assignGroups(records, catalog);
      const defSection = sections.find((s) => s.group === 'Definition');
      const queryFamily = defSection.families.find((f) => f.verb === 'query');
      expect(queryFamily).toBeUndefined();
    } else {
      // query rows are not all curated — the family should appear (not a defect).
      // This branch just keeps the test passing without asserting the wrong thing.
    }
  });
});

// ── Real-corpus integration ───────────────────────────────────────────────────

describe('real-corpus integration', () => {
  it('assignGroups does not throw for the real catalog and real skill directory set', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    expect(() => assignGroups(records, catalog)).not.toThrow();
  });

  it('every on-disk skill directory is assigned exactly once across all sections', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);

    // Collect all names from all sections (cards + family cards).
    const assignedNames = [];
    for (const section of sections) {
      for (const card of section.cards) {
        assignedNames.push(card.name);
      }
      for (const family of section.families) {
        for (const card of family.cards) {
          assignedNames.push(card.name);
        }
      }
    }

    // Each on-disk name appears exactly once.
    const assignedSet = new Set(assignedNames);
    expect(assignedSet.size).toBe(assignedNames.length); // no duplicates
    for (const dir of skillDirs) {
      expect(assignedSet.has(dir)).toBe(true);
    }
  });

  it('group order is exactly Support → Knowledge Base Maintenance → Definition → Execution', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    expect(sections.map((s) => s.group)).toEqual([
      'Support',
      'Knowledge Base Maintenance',
      'Definition',
      'Execution',
    ]);
  });

  it('every curated skill from CURATED_GROUPS appears in its declared group', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);

    for (const entry of CURATED_GROUPS) {
      const section = sections.find((s) => s.group === entry.group);
      const sectionCardNames = section.cards.map((c) => c.name);
      for (const name of entry.members) {
        expect(sectionCardNames).toContain(name);
      }
    }
  });

  it('Definition section has no family-less non-full-path skills (all extras land in families)', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const skillDirs = readdirSync(resolve(REPO_ROOT, 'canonical', 'skills'));
    const records = skillDirs.map(rec);

    const sections = assignGroups(records, catalog);
    const defSection = sections.find((s) => s.group === 'Definition');

    // defSection.cards = the full-path block only.
    // Every non-full-path, non-curated skill must be in a family.
    const allCurated = new Set(
      CURATED_GROUPS.flatMap((e) => [...(e.fullPath || []), ...e.members])
    );
    const fullPathSet = new Set(FULL_PATH_SKILLS);
    const familyCardNames = new Set(
      defSection.families.flatMap((f) => f.cards.map((c) => c.name))
    );

    for (const dir of skillDirs) {
      if (allCurated.has(dir)) continue; // handled by its own group section
      if (fullPathSet.has(dir)) continue; // handled by the full-path block
      expect(familyCardNames.has(dir)).toBe(true);
    }
  });
});

// ── Guard: duplicate assignment ───────────────────────────────────────────────
//
// This guard fires only on a malformed CURATED_GROUPS, which is a hand-maintained
// table. With the constant read directly there is no input a test could supply to
// reach it, so `buildCuratedIndex` takes the table as a parameter and these cases
// drive it with deliberately duplicated ones. An untested guard is
// indistinguishable from an absent guard.

describe('groups: duplicate assignment guard', () => {
  it('the real CURATED_GROUPS is free of duplicates', () => {
    expect(() => buildCuratedIndex(CURATED_GROUPS)).not.toThrow();
  });

  it('throws when a name appears in two different groups', () => {
    const table = [
      { group: 'Support', blurb: '', members: ['aid-config'] },
      { group: 'Execution', blurb: '', members: ['aid-config'] },
    ];
    expect(() => buildCuratedIndex(table)).toThrow('[gen-skills] duplicate assignment:');
    expect(() => buildCuratedIndex(table)).toThrow('"aid-config"');
  });

  it('throws when a name appears twice within one members list', () => {
    const table = [{ group: 'Support', blurb: '', members: ['aid-config', 'aid-config'] }];
    expect(() => buildCuratedIndex(table)).toThrow('"aid-config"');
  });

  it('throws when a name is both a fullPath entry and a member', () => {
    const table = [
      { group: 'Definition', blurb: '', fullPath: ['aid-plan'], members: ['aid-plan'] },
    ];
    expect(() => buildCuratedIndex(table)).toThrow('[gen-skills] duplicate assignment:');
    expect(() => buildCuratedIndex(table)).toThrow('"aid-plan"');
  });

  it('throws when a fullPath name is duplicated across two groups', () => {
    const table = [
      { group: 'Definition', blurb: '', fullPath: ['aid-plan'], members: [] },
      { group: 'Execution', blurb: '', fullPath: ['aid-plan'], members: [] },
    ];
    expect(() => buildCuratedIndex(table)).toThrow('"aid-plan"');
  });

  it('indexes fullPath and members into the same group, tracking fullPath separately', () => {
    const { curatedGroup, fullPathSet } = buildCuratedIndex([
      { group: 'Definition', blurb: '', fullPath: ['aid-plan'], members: ['aid-deploy'] },
    ]);
    expect(curatedGroup.get('aid-plan')).toBe('Definition');
    expect(curatedGroup.get('aid-deploy')).toBe('Definition');
    expect(fullPathSet.has('aid-plan')).toBe(true);
    expect(fullPathSet.has('aid-deploy')).toBe(false);
  });
});
