// skills-discover.test.mjs — unit tests for site/scripts/skills/discover.mjs
//
// Covers: all public functions (discoverSkills, buildRecord), each of the three
// per-skill guards, bodyStartLine/lineCount against a multi-line folded-scalar
// fixture, referencesDir presence/absence, and the real canonical/skills/ corpus.
//
// Drives the real module — no inline re-implementation.

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import {
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  rmSync,
  readdirSync,
  readFileSync,
  existsSync,
  statSync,
} from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { discoverSkills, buildRecord } from '../skills/discover.mjs';
import { CANONICAL_SKILLS_DIR } from '../skills/paths.mjs';

const DISCOVER_SRC = resolve(dirname(fileURLToPath(import.meta.url)), '../skills/discover.mjs');

// ── Temp-directory helpers ───────────────────────────────────────────────────

/** Temp dirs created during the run — cleaned up in afterAll. */
const _tempDirs = [];

afterAll(() => {
  for (const d of _tempDirs) {
    try { rmSync(d, { recursive: true, force: true }); } catch { /* ignore */ }
  }
});

/**
 * Create a temporary skills root containing the supplied skill descriptors.
 *
 * @param {Array<{dirName:string, content:string|null, refs?:boolean}>} skills
 *   content=null  → no SKILL.md (tests the missing-file guard)
 *   refs=true     → creates a references/ subdirectory
 * @returns {string}  Absolute OS path to the temporary root.
 */
function makeTempSkillsDir(skills) {
  const tmpDir = mkdtempSync(join(tmpdir(), 'skills-discover-'));
  _tempDirs.push(tmpDir);
  for (const { dirName, content, refs } of skills) {
    const skillDir = join(tmpDir, dirName);
    mkdirSync(skillDir, { recursive: true });
    if (content !== null && content !== undefined) {
      writeFileSync(join(skillDir, 'SKILL.md'), content, 'utf8');
    }
    if (refs) {
      mkdirSync(join(skillDir, 'references'), { recursive: true });
    }
  }
  return tmpDir;
}

/**
 * Build a minimal valid SKILL.md string for the given dirName.
 * Uses a plain scalar description so frontmatter is straightforward.
 *
 * @param {string} dirName
 * @param {string} [body]  Body text appended after the closing fence.
 * @returns {string}
 */
function minimalSkillMd(dirName, body = '# Body\n') {
  return `---\nname: ${dirName}\ndescription: A test skill.\n---\n\n${body}`;
}

// ── Guard: missing SKILL.md ──────────────────────────────────────────────────

describe('buildRecord — missing SKILL.md guard', () => {
  it('throws when SKILL.md is absent', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: null }]);
    expect(() => buildRecord('aid-test', dir)).toThrow(/missing SKILL\.md/);
  });

  it('error message names the offending directory', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-missing', content: null }]);
    expect(() => buildRecord('aid-missing', dir)).toThrow(/aid-missing/);
  });

  it('error message includes [gen-skills] prefix', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: null }]);
    expect(() => buildRecord('aid-test', dir)).toThrow(/\[gen-skills\]/);
  });
});

// ── Guard: invalid slug ──────────────────────────────────────────────────────

describe('buildRecord — invalid slug guard', () => {
  it('throws for a name with uppercase letters', () => {
    expect(() => buildRecord('AidFoo', tmpdir())).toThrow(/invalid slug/);
  });

  it('throws for a name starting with a hyphen', () => {
    expect(() => buildRecord('-bad', tmpdir())).toThrow(/invalid slug/);
  });

  it('throws for a name ending with a hyphen', () => {
    expect(() => buildRecord('aid-bad-', tmpdir())).toThrow(/invalid slug/);
  });

  it('throws for a name with consecutive hyphens', () => {
    expect(() => buildRecord('aid--double', tmpdir())).toThrow(/invalid slug/);
  });

  it('throws for a name containing an underscore', () => {
    expect(() => buildRecord('aid_bad', tmpdir())).toThrow(/invalid slug/);
  });

  it('error message names the offending directory', () => {
    expect(() => buildRecord('Aid_Bad', tmpdir())).toThrow(/Aid_Bad/);
  });

  it('error message includes [gen-skills] prefix', () => {
    expect(() => buildRecord('BadSlug', tmpdir())).toThrow(/\[gen-skills\]/);
  });
});

// ── Guard: name mismatch ─────────────────────────────────────────────────────

describe('buildRecord — name mismatch guard', () => {
  it('throws when frontmatter name differs from directory name', () => {
    const content = '---\nname: wrong-name\ndescription: test\n---\n\nBody.\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    expect(() => buildRecord('aid-test', dir)).toThrow(/name mismatch/);
  });

  it('error message names the offending directory', () => {
    const content = '---\nname: wrong-name\ndescription: test\n---\n\nBody.\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-mismatch', content }]);
    expect(() => buildRecord('aid-mismatch', dir)).toThrow(/aid-mismatch/);
  });

  it('error message includes [gen-skills] prefix', () => {
    const content = '---\nname: other\ndescription: test\n---\n\nBody.\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    expect(() => buildRecord('aid-test', dir)).toThrow(/\[gen-skills\]/);
  });
});

// ── buildRecord — record shape ───────────────────────────────────────────────

describe('buildRecord — record shape', () => {
  it('builds a record with all required fields', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);

    expect(rec.dirName).toBe('aid-test');
    expect(rec.sourcePath).toBe('canonical/skills/aid-test/SKILL.md');
    expect(rec.route).toBe('/skills/aid-test/');
    expect(rec.destPath).toBe('site/src/content/docs/skills/aid-test.md');
    expect(Array.isArray(rec.fields)).toBe(true);
    expect(typeof rec.field).toBe('function');
    expect(typeof rec.body).toBe('string');
    expect(typeof rec.bodyStartLine).toBe('number');
    expect(typeof rec.lineCount).toBe('number');
    expect(rec.referencesDir === null || typeof rec.referencesDir === 'string').toBe(true);
  });

  it('record has no shape key', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    expect('shape' in rec).toBe(false);
  });

  it('record has no count key other than lineCount', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    const countKeys = Object.keys(rec).filter((k) => /count/i.test(k) && k !== 'lineCount');
    expect(countKeys).toEqual([]);
  });

  it('route is /skills/<dirName>/', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-foo-bar', content: minimalSkillMd('aid-foo-bar') }]);
    expect(buildRecord('aid-foo-bar', dir).route).toBe('/skills/aid-foo-bar/');
  });

  it('destPath is site/src/content/docs/skills/<dirName>.md', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-foo-bar', content: minimalSkillMd('aid-foo-bar') }]);
    expect(buildRecord('aid-foo-bar', dir).destPath).toBe('site/src/content/docs/skills/aid-foo-bar.md');
  });

  it('sourcePath is canonical/skills/<dirName>/SKILL.md', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-foo-bar', content: minimalSkillMd('aid-foo-bar') }]);
    expect(buildRecord('aid-foo-bar', dir).sourcePath).toBe('canonical/skills/aid-foo-bar/SKILL.md');
  });

  it('paths contain only forward slashes', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.sourcePath.includes('\\')).toBe(false);
    expect(rec.route.includes('\\')).toBe(false);
    expect(rec.destPath.includes('\\')).toBe(false);
  });

  it('field() returns the named field', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    const f = rec.field('name');
    expect(f).toBeDefined();
    expect(f.value).toBe('aid-test');
  });

  it('field() returns undefined for a missing key', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    expect(buildRecord('aid-test', dir).field('nonexistent')).toBeUndefined();
  });

  it('fields preserves source order', () => {
    const content = '---\nname: aid-test\ndescription: desc\nallowed-tools: Read\n---\n\nBody.\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.fields.map((f) => f.key)).toEqual(['name', 'description', 'allowed-tools']);
  });
});

// ── buildRecord — bodyStartLine and lineCount ────────────────────────────────

describe('buildRecord — bodyStartLine and lineCount', () => {
  it('bodyStartLine is the 1-based line of the first body character (plain scalar)', () => {
    // Line 1: ---
    // Line 2: name: aid-test
    // Line 3: description: plain
    // Line 4: ---                ← closing fence, fenceEnd=3 (0-based)
    // Line 5: (empty)            ← body[0] is here
    // Line 6: # Body
    const content = '---\nname: aid-test\ndescription: plain\n---\n\n# Body\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.bodyStartLine).toBe(5);
    expect(rec.lineCount).toBe(6);
  });

  it('bodyStartLine correct with multi-line folded scalar in frontmatter', () => {
    // Line 1: ---
    // Line 2: name: aid-test
    // Line 3: description: >
    // Line 4:   Line one of description.
    // Line 5:   Line two of description.
    // Line 6:   Line three.
    // Line 7: ---                ← fenceEnd=6 (0-based), closing fence
    // Line 8: (empty)            ← body[0] is here → bodyStartLine=8
    // Line 9: # Body title
    const content =
      '---\n' +
      'name: aid-test\n' +
      'description: >\n' +
      '  Line one of description.\n' +
      '  Line two of description.\n' +
      '  Line three.\n' +
      '---\n' +
      '\n' +
      '# Body title\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    const rec = buildRecord('aid-test', dir);
    // Closing fence at line 7 (1-based) = index 6 (0-based). bodyStartLine = 6+2 = 8.
    expect(rec.bodyStartLine).toBe(8);
    expect(rec.lineCount).toBe(9);
  });

  it('lineCount matches the total line count of the file (wc-l compatible)', () => {
    // 9-line file ending with \n → lineCount = 9
    const content =
      '---\n' +
      'name: aid-test\n' +
      'description: >\n' +
      '  Line one.\n' +
      '  Line two.\n' +
      '  Line three.\n' +
      '---\n' +
      '\n' +
      '# Body title\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.lineCount).toBe(9);
  });

  it('body contains the content after the closing fence', () => {
    const content =
      '---\n' +
      'name: aid-test\n' +
      'description: >\n' +
      '  Line one.\n' +
      '  Line two.\n' +
      '---\n' +
      '\n' +
      '# Body title\n';
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.body).toBe('\n# Body title\n');
  });

  it('bodyStartLine <= lineCount + 1', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.bodyStartLine).toBeLessThanOrEqual(rec.lineCount + 1);
  });

  it('bodyStartLine is greater than 1 (fence is at least on line 1)', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test') }]);
    const rec = buildRecord('aid-test', dir);
    expect(rec.bodyStartLine).toBeGreaterThan(1);
  });
});

// ── buildRecord — referencesDir ──────────────────────────────────────────────

describe('buildRecord — referencesDir', () => {
  it('is null when no references/ subdirectory exists', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test'), refs: false }]);
    expect(buildRecord('aid-test', dir).referencesDir).toBeNull();
  });

  it('is non-null when references/ subdirectory exists', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test'), refs: true }]);
    expect(buildRecord('aid-test', dir).referencesDir).not.toBeNull();
  });

  it('is the POSIX repo-relative path (no trailing slash)', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test'), refs: true }]);
    expect(buildRecord('aid-test', dir).referencesDir).toBe('canonical/skills/aid-test/references');
  });

  it('contains only forward slashes', () => {
    const dir = makeTempSkillsDir([{ dirName: 'aid-test', content: minimalSkillMd('aid-test'), refs: true }]);
    const referencesDir = buildRecord('aid-test', dir).referencesDir;
    expect(referencesDir.includes('\\')).toBe(false);
  });
});

// ── discoverSkills ────────────────────────────────────────────────────────────

describe('discoverSkills', () => {
  it('returns an array of SkillRecords', () => {
    const dir = makeTempSkillsDir([
      { dirName: 'aid-alpha', content: minimalSkillMd('aid-alpha') },
      { dirName: 'aid-beta', content: minimalSkillMd('aid-beta') },
    ]);
    const records = discoverSkills(dir);
    expect(Array.isArray(records)).toBe(true);
    expect(records).toHaveLength(2);
  });

  it('records are in .sort() order (UTF-16 code-unit, deterministic)', () => {
    // The fixture is created OUT of sorted order deliberately. The expectation is
    // written out explicitly rather than as `names.slice().sort()` — comparing an
    // array to a sorted copy of itself is a tautology that holds even with the
    // `.sort()` deleted from `discoverSkills`, which is how that state shipped.
    //
    // This matters beyond hygiene. `readdirSync` order is filesystem-dependent:
    // NTFS returns entries already ordered, so the defect is invisible on a
    // Windows dev machine, while CI builds on ubuntu-24.04/ext4, which gives no
    // ordering guarantee. AC-6 byte-identical idempotence depends on this sort,
    // so an unsorted read there would produce a differently-ordered manifest on
    // every run.
    const dir = makeTempSkillsDir([
      { dirName: 'aid-z', content: minimalSkillMd('aid-z') },
      { dirName: 'aid-a', content: minimalSkillMd('aid-a') },
      { dirName: 'aid-m', content: minimalSkillMd('aid-m') },
    ]);
    const records = discoverSkills(dir);
    expect(records.map((r) => r.dirName)).toEqual(['aid-a', 'aid-m', 'aid-z']);
  });

  // The behavioural assertion above is correct but cannot carry this contract on
  // its own, and it is worth being explicit about why. `readdirSync` order is
  // filesystem-dependent: NTFS returns entries already sorted, so deleting the
  // `.sort()` leaves the behavioural test green on a Windows dev machine —
  // verified by mutation. It would fail on CI's ubuntu-24.04/ext4, but a defect
  // that only surfaces in CI is one that ships from a developer's laptop.
  //
  // So the sort is also pinned at the source, using the same idiom the SPEC's
  // `localeCompare` ban already relies on. This kills the mutant on every
  // platform.
  it('the directory scan applies .sort() and never localeCompare', () => {
    const src = readFileSync(DISCOVER_SRC, 'utf8');
    const enumeration = src.slice(src.indexOf('export function discoverSkills'));
    const body = enumeration.slice(0, enumeration.indexOf('\n}'));

    expect(body, 'discoverSkills must sort the directory listing').toMatch(/\.sort\(\)/);
    // A locale-aware comparator would make output host-dependent and break AC-6.
    expect(src).not.toMatch(/localeCompare/);
    // …and the sort must be the bare default comparator, not a custom one.
    expect(body).not.toMatch(/\.sort\(\s*\(/);
  });

  it('orders `-` before digits and letters, per the default comparator', () => {
    // Pins default-comparator semantics: `-` (45) sorts before any digit (48+) and
    // any letter (97+).
    //
    // The title deliberately does NOT claim this discriminates the default sort
    // from `localeCompare`. I searched for an input within the slug charset
    // `^[a-z0-9]+(-[a-z0-9]+)*$` where the two disagree and found none on this ICU
    // build — they order every candidate identically, including this one. A test
    // titled "not by locale" would therefore be claiming a check it cannot make,
    // which is the exact failure mode this delivery kept producing. The
    // `localeCompare` ban is enforced at the source instead, in the test above.
    const dir = makeTempSkillsDir([
      { dirName: 'aid-a1', content: minimalSkillMd('aid-a1') },
      { dirName: 'aid-a-b', content: minimalSkillMd('aid-a-b') },
      { dirName: 'aid-ab', content: minimalSkillMd('aid-ab') },
    ]);
    const records = discoverSkills(dir);
    expect(records.map((r) => r.dirName)).toEqual(['aid-a-b', 'aid-a1', 'aid-ab']);
  });

  it('propagates a guard error from buildRecord (missing SKILL.md)', () => {
    const dir = makeTempSkillsDir([
      { dirName: 'aid-good', content: minimalSkillMd('aid-good') },
      { dirName: 'aid-bad', content: null },
    ]);
    expect(() => discoverSkills(dir)).toThrow(/missing SKILL\.md/);
  });

  it('propagates a guard error from buildRecord (name mismatch)', () => {
    const dir = makeTempSkillsDir([
      { dirName: 'aid-test', content: '---\nname: wrong\ndescription: d\n---\n\nBody.\n' },
    ]);
    expect(() => discoverSkills(dir)).toThrow(/name mismatch/);
  });
});

// ── Real corpus tests ─────────────────────────────────────────────────────────
// Proves discoverSkills against the actual canonical/skills/ tree.
// No literal count is asserted (§8); every expectation is derived.

describe('discoverSkills — real canonical/skills/ corpus', () => {
  let records;

  beforeAll(() => {
    records = discoverSkills();
  });

  it('does not throw on the real corpus', () => {
    expect(Array.isArray(records)).toBe(true);
  });

  it('corpus is non-empty', () => {
    expect(records.length).toBeGreaterThan(0);
  });

  it('record count matches the directory count', () => {
    const dirCount = readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .length;
    expect(records.length).toBe(dirCount);
  });

  it('every record route round-trips from dirName', () => {
    for (const rec of records) {
      expect(rec.route).toBe('/skills/' + rec.dirName + '/');
    }
  });

  it('every record destPath round-trips from dirName', () => {
    for (const rec of records) {
      expect(rec.destPath).toBe('site/src/content/docs/skills/' + rec.dirName + '.md');
    }
  });

  it('every record sourcePath round-trips from dirName', () => {
    for (const rec of records) {
      expect(rec.sourcePath).toBe('canonical/skills/' + rec.dirName + '/SKILL.md');
    }
  });

  it('referencesDir is non-null exactly for directories with a references/ subtree', () => {
    // Independently compute the set — never hard-coded.
    const dirsWithRefs = new Set(
      readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
        .filter((name) => {
          try {
            const p = resolve(CANONICAL_SKILLS_DIR, name, 'references');
            return existsSync(p) && statSync(p).isDirectory();
          } catch {
            return false;
          }
        })
    );

    for (const rec of records) {
      if (dirsWithRefs.has(rec.dirName)) {
        expect(rec.referencesDir).not.toBeNull();
        expect(rec.referencesDir).toBe('canonical/skills/' + rec.dirName + '/references');
      } else {
        expect(rec.referencesDir).toBeNull();
      }
    }
  });

  it('no record has a shape key', () => {
    for (const rec of records) {
      expect('shape' in rec).toBe(false);
    }
  });

  it('no record has a count key other than lineCount', () => {
    for (const rec of records) {
      const extraCountKeys = Object.keys(rec).filter((k) => /count/i.test(k) && k !== 'lineCount');
      expect(extraCountKeys).toEqual([]);
    }
  });

  it('every record has a positive bodyStartLine', () => {
    for (const rec of records) {
      expect(rec.bodyStartLine).toBeGreaterThan(0);
    }
  });

  it('every record has a positive lineCount', () => {
    for (const rec of records) {
      expect(rec.lineCount).toBeGreaterThan(0);
    }
  });

  it('bodyStartLine <= lineCount + 1 for every record', () => {
    for (const rec of records) {
      expect(rec.bodyStartLine).toBeLessThanOrEqual(rec.lineCount + 1);
    }
  });

  it('every record dirName matches the slug pattern', () => {
    const slugRe = /^[a-z0-9]+(-[a-z0-9]+)*$/;
    for (const rec of records) {
      expect(slugRe.test(rec.dirName)).toBe(true);
    }
  });
});
