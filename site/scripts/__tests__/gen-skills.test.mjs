// gen-skills.test.mjs — Unit and integration tests for feature-001-skill-detail-pages
//                        and feature-002-grouped-skill-index (task-012 / task-015).
//
// Covers every acceptance criterion:
//   AC-1  Drift guard — missing page and orphan page scenarios.
//   AC-2  Header completeness — every frontmatter key appears on the page.
//   AC-6  Idempotence — byte comparison of two consecutive runs.
//   Manifest shape, marker, isolation, stdout discipline.
//   feature-002: catalog load (3a), group assignment (4a), index write (5a),
//                dead card guard (7a), assertNoDeadCards all branches.

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { readFileSync, existsSync, readdirSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync, spawnSync } from 'node:child_process';
import { discoverSkills } from '../skills/discover.mjs';
import { loadShortcutCatalog } from '../skills/catalog.mjs';
import { assignGroups } from '../skills/groups.mjs';
// Importing the generator is safe — and is itself a check on the `main()` guard.
// gen-reference.mjs calls main() at module scope, so importing it would
// regenerate four pages as a side effect; gen-skills.mjs must not, and this
// import would run the whole generator on every test file load if it did.
import { assertNoSkillsDrift, assertNoDeadCards } from '../gen-skills.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const REPO_ROOT = resolve(__dirname, '../../../');
const SKILLS_OUTPUT_DIR = join(SITE_ROOT, 'src', 'content', 'docs', 'skills');
const MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.skills-manifest.json');
const REFERENCE_MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.reference-manifest.json');
const CANONICAL_SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const GEN_SKILLS_SCRIPT = join(SITE_ROOT, 'scripts', 'gen-skills.mjs');
const GEN_REFERENCE_SCRIPT = join(SITE_ROOT, 'scripts', 'gen-reference.mjs');

// ── Setup: ensure gen-skills has run at least once ────────────────────────────

beforeAll(() => {
  // Run the generator if no pages exist yet.
  const anyPage = existsSync(SKILLS_OUTPUT_DIR) &&
    readdirSync(SKILLS_OUTPUT_DIR).some((f) => f.endsWith('.md') && f !== 'index.md');
  if (!anyPage) {
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Returns sorted array of skill directory names from canonical/skills/. */
function getCanonicalDirNames() {
  return readdirSync(CANONICAL_SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();
}

/** Returns sorted array of on-disk page basenames (without .md), excluding index.md. */
function getOnDiskPageNames() {
  if (!existsSync(SKILLS_OUTPUT_DIR)) return [];
  return readdirSync(SKILLS_OUTPUT_DIR)
    .filter((f) => f.endsWith('.md') && f !== 'index.md')
    .map((f) => f.slice(0, -3))
    .sort();
}

// ── AC-1 / Corpus coverage: one page per skill directory ─────────────────────

describe('gen-skills: AC-1 corpus coverage', () => {
  it('every canonical/skills/ directory has a generated page', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    const missing = dirNames.filter((d) => !pageNames.includes(d));
    expect(missing).toEqual([]);
  });

  it('no generated page exists without a canonical/skills/ directory', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    const orphans = pageNames.filter((p) => !dirNames.includes(p));
    expect(orphans).toEqual([]);
  });

  it('index.md is excluded from the on-disk comparison', () => {
    const pageNames = getOnDiskPageNames();
    expect(pageNames).not.toContain('index');
  });

  it('page count matches directory count — derived, no literal', () => {
    const dirNames = getCanonicalDirNames();
    const pageNames = getOnDiskPageNames();
    expect(pageNames).toHaveLength(dirNames.length);
  });
});

// Note on "missing page" guard direction:
// The generator's drift guard runs AFTER the write pass. Since the write pass
// writes all expected pages unconditionally, the "missing pages" branch of the
// on-disk guard is architecturally unreachable in a successfully-executing
// generator (a deleted file is always regenerated before the guard checks).
// The write pass self-healing behaviour is implicitly covered by the corpus
// coverage tests above (which verify all pages exist after a run) and by the
// AC-6 idempotence test (which runs twice and compares bytes).
// The orphan page test below covers the reachable "orphan pages:" guard branch.

// ── AC-1 / Drift guard: orphan page scenario ─────────────────────────────────

describe('gen-skills: drift guard — orphan page', () => {
  const ORPHAN_NAME = '__test-orphan-skill__';
  const ORPHAN_PATH = join(SKILLS_OUTPUT_DIR, ORPHAN_NAME + '.md');

  it('throws when a synthetic orphan page is on disk, names it, gives git rm remedy, does not delete it', () => {
    // Create a synthetic orphan page (no corresponding canonical/skills/ directory).
    writeFileSync(ORPHAN_PATH, '---\ntitle: orphan\n---\n', 'utf8');
    expect(existsSync(ORPHAN_PATH)).toBe(true);

    // Run the generator — it writes all real pages, then the drift guard runs.
    const result = spawnSync('node', ['scripts/gen-skills.mjs'], {
      cwd: SITE_ROOT,
      encoding: 'utf8',
    });

    // Generator should exit 1.
    expect(result.status).toBe(1);

    // The error message should name the orphan.
    const errMsg = result.stderr || '';
    expect(errMsg).toContain(ORPHAN_NAME);

    // The error message should include "orphan pages:".
    expect(errMsg).toContain('orphan pages:');

    // The error message should include the git rm remedy.
    expect(errMsg).toContain('git rm');

    // The orphan page must NOT have been deleted — auto-pruning is forbidden.
    expect(existsSync(ORPHAN_PATH)).toBe(true);
  });

  afterAll(() => {
    // Clean up the synthetic orphan page.
    if (existsSync(ORPHAN_PATH)) {
      rmSync(ORPHAN_PATH);
    }
  });
});

// ── AC-2 / Header completeness: every frontmatter key appears on each page ───

describe('gen-skills: AC-2 header completeness', () => {
  it('every SKILL.md frontmatter key appears in the rendered Frontmatter section', () => {
    const skills = discoverSkills();
    for (const skill of skills) {
      const pagePath = join(SKILLS_OUTPUT_DIR, skill.dirName + '.md');
      const pageContent = readFileSync(pagePath, 'utf8');
      for (const field of skill.fields) {
        expect(pageContent).toContain(`**\`${field.key}\`**`);
      }
    }
  });
});

// ── Marker: "generated — do not edit" on every page ─────────────────────────

describe('gen-skills: generated marker', () => {
  it('every page contains "generated \u2014 do not edit" (em-dash)', () => {
    const dirNames = getCanonicalDirNames();
    for (const dir of dirNames) {
      const content = readFileSync(join(SKILLS_OUTPUT_DIR, dir + '.md'), 'utf8');
      expect(content).toContain('generated \u2014 do not edit');
    }
  });
});

// ── Manifest shape ────────────────────────────────────────────────────────────

describe('gen-skills: .skills-manifest.json shape', () => {
  let manifest;

  beforeAll(() => {
    manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
  });

  it('manifest has generator, entries, generatedPaths fields', () => {
    expect(manifest).toHaveProperty('generator');
    expect(manifest).toHaveProperty('entries');
    expect(manifest).toHaveProperty('generatedPaths');
  });

  it('manifest.generator identifies gen-skills.mjs', () => {
    expect(manifest.generator).toContain('gen-skills.mjs');
  });

  it('manifest has no generatedAt field (determinism: no wall-clock timestamps)', () => {
    expect(manifest).not.toHaveProperty('generatedAt');
    // Also check the raw JSON string has no timestamp-like field.
    const raw = readFileSync(MANIFEST_PATH, 'utf8');
    expect(raw).not.toContain('generatedAt');
  });

  it('manifest.entries count is directory count + 1 (skill pages + index row) — derived, no literal', () => {
    const dirNames = getCanonicalDirNames();
    // +1 for the index entry (src: canonical/skills/*/SKILL.md, ...)
    expect(manifest.entries).toHaveLength(dirNames.length + 1);
  });

  it('manifest.entries are ordered by src ascending (literal string comparison, no localeCompare)', () => {
    // Task-015: entries are sorted by full src string (pure string comparison).
    // '*' (code point 42) < 'a' (97), so the index row lands first.
    // This differs from directory-name sort for pairs where one name is a prefix
    // of another (e.g. 'aid-add-api/SKILL.md' < 'aid-add/SKILL.md' because
    // '-' (45) < '/' (47) at the divergence point).
    const entries = manifest.entries;
    expect(entries.length).toBeGreaterThan(1);

    // The index row must be first.
    expect(entries[0].src).toBe(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
    expect(entries[0].dest).toBe('site/src/content/docs/skills/index.md');

    // All consecutive pairs must satisfy strict ascending literal order.
    for (let i = 1; i < entries.length; i++) {
      expect(entries[i - 1].src < entries[i].src).toBe(true);
    }

    // Skill entries (all but the first) must cover exactly the canonical dirs.
    const dirNames = getCanonicalDirNames(); // directory-name sort order
    const skillSrcs = entries.slice(1).map((e) => e.src);
    // Same set, regardless of which sort order they arrived in.
    const expectedSkillSrcs = dirNames.map((d) => 'canonical/skills/' + d + '/SKILL.md').sort();
    expect(skillSrcs.slice().sort()).toEqual(expectedSkillSrcs);
  });

  it('manifest.entries each have src and dest as POSIX repo-relative strings', () => {
    for (const entry of manifest.entries) {
      // No Windows backslashes anywhere.
      expect(entry.src).not.toContain('\\');
      expect(entry.dest).not.toContain('\\');
      // dest always points at site/src/content/docs/skills/*.md
      expect(entry.dest).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }

    // Skill entries (all but index row) must match the single-source pattern.
    for (const entry of manifest.entries.slice(1)) {
      expect(entry.src).toMatch(/^canonical\/skills\/[^/]+\/SKILL\.md$/);
    }

    // The index entry (first) has the two-source src.
    const indexEntry = manifest.entries[0];
    expect(indexEntry.src).toBe(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
    expect(indexEntry.dest).toBe('site/src/content/docs/skills/index.md');
  });

  it('manifest.generatedPaths has directory count + 1 entries, all POSIX, includes index.md', () => {
    const dirNames = getCanonicalDirNames();
    // +1 for index.md
    expect(manifest.generatedPaths).toHaveLength(dirNames.length + 1);
    for (const p of manifest.generatedPaths) {
      expect(p).not.toContain('\\');
      expect(p).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }
    expect(manifest.generatedPaths).toContain('site/src/content/docs/skills/index.md');
  });

  it('manifest JSON ends with exactly one trailing newline and is two-space indented', () => {
    const raw = readFileSync(MANIFEST_PATH, 'utf8');
    expect(raw.endsWith('\n')).toBe(true);
    expect(raw.endsWith('\n\n')).toBe(false);
    // Two-space indented: second line starts with two spaces.
    const lines = raw.split('\n');
    const firstIndented = lines.find((l) => l.startsWith('  ') && !l.startsWith('   '));
    expect(firstIndented).toBeDefined();
  });
});

// ── AC-6 / Idempotence: byte comparison of two consecutive runs ───────────────

describe('gen-skills: AC-6 idempotence by byte comparison', () => {
  it('two consecutive runs produce byte-identical skill pages, index.md, and manifest', () => {
    // Run 1.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Capture byte content after run 1.
    const dirNames = getCanonicalDirNames();
    const run1Pages = new Map();
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      run1Pages.set(dir, readFileSync(p));
    }
    const run1Index = readFileSync(join(SKILLS_OUTPUT_DIR, 'index.md'));
    const run1Manifest = readFileSync(MANIFEST_PATH);

    // Run 2.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Compare skill page bytes.
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      const run2Content = readFileSync(p);
      const run1Content = run1Pages.get(dir);
      expect(run2Content.equals(run1Content)).toBe(true);
    }

    // Compare index.md bytes (AC-6 for the index page).
    const run2Index = readFileSync(join(SKILLS_OUTPUT_DIR, 'index.md'));
    expect(run2Index.equals(run1Index)).toBe(true);

    // Compare manifest bytes.
    const run2Manifest = readFileSync(MANIFEST_PATH);
    expect(run2Manifest.equals(run1Manifest)).toBe(true);
  });
});

// ── Stdout discipline: exactly four lines on success ─────────────────────────

describe('gen-skills: stdout discipline', () => {
  it('successful run emits exactly four [gen-skills]-prefixed stdout lines and nothing on stderr', () => {
    const result = spawnSync('node', ['scripts/gen-skills.mjs'], {
      cwd: SITE_ROOT,
      encoding: 'utf8',
    });

    expect(result.status).toBe(0);

    // stderr must be empty on success.
    expect(result.stderr || '').toBe('');

    // stdout: exactly four non-empty lines, each starting with [gen-skills].
    const lines = (result.stdout || '').split('\n').filter((l) => l.trim() !== '');
    expect(lines).toHaveLength(4);
    for (const line of lines) {
      expect(line).toMatch(/^\[gen-skills\] /);
    }

    // Line 1: start message.
    expect(lines[0]).toContain('[gen-skills] generating');

    // Line 2: parsed N skills — count derived, not literal.
    expect(lines[1]).toMatch(/^\[gen-skills\] parsed \d+ skills$/);

    // Line 3: wrote N pages.
    expect(lines[2]).toMatch(/^\[gen-skills\] wrote \d+ pages -> src\/content\/docs\/skills\/$/);

    // Line 4: manifest.
    expect(lines[3]).toBe('[gen-skills] wrote scripts/.skills-manifest.json');

    // The counts in lines 2 and 3 must match the actual directory count.
    const dirCount = getCanonicalDirNames().length;
    expect(lines[1]).toBe(`[gen-skills] parsed ${dirCount} skills`);
    expect(lines[2]).toBe(`[gen-skills] wrote ${dirCount} pages -> src/content/docs/skills/`);
  });
});

// ── Isolation: gen-reference.mjs is byte-unmodified and not imported ──────────

describe('gen-skills: isolation from gen-reference', () => {
  it('gen-reference.mjs is byte-unmodified after gen-skills run', () => {
    // Read gen-reference.mjs bytes before a gen-skills run.
    const before = readFileSync(GEN_REFERENCE_SCRIPT);

    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Read after.
    const after = readFileSync(GEN_REFERENCE_SCRIPT);
    expect(after.equals(before)).toBe(true);
  });

  it('.reference-manifest.json is unchanged after gen-skills run', () => {
    const before = readFileSync(REFERENCE_MANIFEST_PATH);
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
    const after = readFileSync(REFERENCE_MANIFEST_PATH);
    expect(after.equals(before)).toBe(true);
  });

  it('the four reference pages are unchanged after gen-skills run', () => {
    const refPages = [
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'skills.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'agents.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'kb.md'),
      join(SITE_ROOT, 'src', 'content', 'docs', 'reference', 'settings.md'),
    ];

    const before = refPages.map((p) => readFileSync(p));
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
    const after = refPages.map((p) => readFileSync(p));

    for (let i = 0; i < refPages.length; i++) {
      expect(after[i].equals(before[i])).toBe(true);
    }
  });
});

// ── AC-1 drift guard, every branch ───────────────────────────────────────────
//
// Called from main() the guard runs after the write pass, so two of its four
// branches cannot fire there — a page has just been written for every discovered
// skill. Driving the exported function directly is what makes them reachable;
// left untested they would be indistinguishable from branches that do not work.
// The orphan-on-disk path is additionally proven end-to-end, against the real
// generator in a subprocess, in the suite above.

describe('assertNoSkillsDrift — all four branches', () => {
  const ok = { expected: ['a', 'b'], written: ['a', 'b'], onDisk: ['a', 'b'] };

  it('passes when all three sets agree', () => {
    expect(() => assertNoSkillsDrift(ok)).not.toThrow();
  });

  it('throws when the write pass missed a discovered skill', () => {
    expect(() => assertNoSkillsDrift({ ...ok, written: ['a'] })).toThrow(
      /skills drift: write pass diverged from discovery\. missing pages: b/
    );
  });

  it('throws when the write pass produced a page for an undiscovered skill', () => {
    expect(() => assertNoSkillsDrift({ ...ok, written: ['a', 'b', 'zz'] })).toThrow(
      /write pass diverged from discovery\. orphan pages: zz/
    );
  });

  it('throws when a discovered skill has no page on disk', () => {
    expect(() => assertNoSkillsDrift({ ...ok, onDisk: ['a'] })).toThrow(
      /\[gen-skills\] skills drift: missing pages: b/
    );
  });

  it('throws when a page on disk has no skill, naming it with the git rm remedy', () => {
    let err;
    try {
      assertNoSkillsDrift({ ...ok, onDisk: ['a', 'b', 'aid-deleted'] });
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('orphan pages: aid-deleted');
    expect(err.message).toContain('git rm site/src/content/docs/skills/aid-deleted.md');
  });

  it('reports both deltas at once, each under its own label', () => {
    let err;
    try {
      assertNoSkillsDrift({ expected: ['a', 'b'], written: ['a', 'b'], onDisk: ['a', 'zz'] });
    } catch (e) {
      err = e;
    }
    expect(err.message).toContain('missing pages: b');
    expect(err.message).toContain('orphan pages: zz');
  });

  it('reports each delta sorted', () => {
    let err;
    try {
      assertNoSkillsDrift({
        expected: ['a'],
        written: ['a'],
        onDisk: ['a', 'zz', 'mm', 'bb'].sort(),
      });
    } catch (e) {
      err = e;
    }
    expect(err.message).toContain('orphan pages: bb, mm, zz');
  });
});

// ── feature-002: step 3a CATALOG load ─────────────────────────────────────────

describe('gen-skills: step 3a catalog load', () => {
  it('loadShortcutCatalog returns rows in file order and a byName Map', () => {
    const catalog = loadShortcutCatalog(REPO_ROOT);
    // rows is a non-empty array in file order.
    expect(Array.isArray(catalog.rows)).toBe(true);
    expect(catalog.rows.length).toBeGreaterThan(0);
    // byName is a Map covering the same names.
    expect(catalog.byName).toBeInstanceOf(Map);
    expect(catalog.byName.size).toBe(catalog.rows.length);
    // Every row has a name and a verb.
    for (const row of catalog.rows) {
      expect(typeof row.name).toBe('string');
      expect(typeof row.verb).toBe('string');
    }
  });

  it('the real catalog loads, and every row it yields is well-formed', () => {
    // Deliberately NOT "catalog row count matches manifest skill count" — it never
    // checked that and the counts are not equal by design: catalog rows cover
    // classic and shortcut skills, curated and not, while the manifest has one
    // row per skill directory plus the index. What matters here is that the real
    // file was loaded rather than a stub, so downstream assertions are not
    // vacuously true over an empty array.
    const catalog = loadShortcutCatalog(REPO_ROOT);

    // Row count derived from the file itself, never a literal (§8; the defect
    // class that produced KI-005).
    const raw = readFileSync(join(REPO_ROOT, 'canonical/aid/templates/shortcut-catalog.yml'), 'utf8');
    const declared = (raw.match(/^ {2}- name:/gm) || []).length;
    expect(declared).toBeGreaterThan(0);
    expect(catalog.rows).toHaveLength(declared);

    for (const row of catalog.rows) {
      expect(row.name, 'every catalog row has a name').toBeTruthy();
      expect(row.verb, `${row.name} has a verb`).toBeTruthy();
      expect(catalog.byName.get(row.name)).toBe(row);
    }
  });
});

// ── feature-002: step 4a ASSIGN ────────────────────────────────────────────────

describe('gen-skills: step 4a group assignment', () => {
  it('assignGroups returns four sections: Support, Knowledge Base Maintenance, Definition, Execution', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    expect(sections).toHaveLength(4);
    expect(sections.map((s) => s.group)).toEqual([
      'Support',
      'Knowledge Base Maintenance',
      'Definition',
      'Execution',
    ]);
  });

  it('every skill has exactly one card across all sections — derived count, no literal', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);

    // Collect all card names from all sections and families.
    const cardNames = [];
    for (const section of sections) {
      for (const card of section.cards) cardNames.push(card.name);
      for (const family of section.families) {
        for (const card of family.cards) cardNames.push(card.name);
      }
    }

    // Each skill must appear exactly once.
    const skillDirNames = skills.map((s) => s.dirName);
    expect(cardNames.sort()).toEqual(skillDirNames.sort());
  });

  it('Definition section has families (verb subdivisions)', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    const definition = sections.find((s) => s.group === 'Definition');
    expect(definition).toBeDefined();
    expect(definition.families.length).toBeGreaterThan(0);
  });

  it('non-Definition sections have no families', () => {
    const skills = discoverSkills();
    const catalog = loadShortcutCatalog(REPO_ROOT);
    const sections = assignGroups(skills, catalog);
    for (const section of sections) {
      if (section.group !== 'Definition') {
        expect(section.families).toHaveLength(0);
      }
    }
  });
});

// ── feature-002: step 5a INDEX write ──────────────────────────────────────────

describe('gen-skills: step 5a index page', () => {
  const INDEX_PATH = join(SKILLS_OUTPUT_DIR, 'index.md');

  it('index.md exists after a gen-skills run', () => {
    expect(existsSync(INDEX_PATH)).toBe(true);
  });

  it('index.md has a generatedFrom frontmatter field with the two-source string', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    // The two-source string must appear exactly in the frontmatter.
    expect(content).toContain(
      'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
    );
  });

  it('index.md generatedFrom matches the manifest index entry src — one string, three places', () => {
    // Three places: gen-reference.mjs:447 generatedFrom, manifest index entry src,
    // and index.md frontmatter generatedFrom. All three must be byte-identical.
    const manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
    const indexEntry = manifest.entries.find((e) => e.dest === 'site/src/content/docs/skills/index.md');
    expect(indexEntry).toBeDefined();

    const content = readFileSync(INDEX_PATH, 'utf8');
    // The manifest src string must appear verbatim in the page.
    expect(content).toContain(indexEntry.src);
  });

  it('index.md has the "generated — do not edit" marker (em-dash)', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('generated \u2014 do not edit');
  });

  it('index.md has sidebar: hidden: true in frontmatter', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('sidebar:');
    expect(content).toContain('hidden: true');
  });

  it('index.md contains one ## heading per group (Support, Knowledge Base Maintenance, Definition, Execution)', () => {
    const content = readFileSync(INDEX_PATH, 'utf8');
    expect(content).toContain('## Support');
    expect(content).toContain('## Knowledge Base Maintenance');
    expect(content).toContain('## Definition');
    expect(content).toContain('## Execution');
  });

  it('index.md has LF line endings, no CRLF', () => {
    const raw = readFileSync(INDEX_PATH, 'utf8');
    expect(raw).not.toContain('\r');
  });

  it('index.md ends with a trailing newline', () => {
    const raw = readFileSync(INDEX_PATH, 'utf8');
    expect(raw.endsWith('\n')).toBe(true);
  });
});

// ── feature-002: step 7a assertNoDeadCards — all branches ────────────────────
//
// Called from main() after both writes, the guard is architecturally unreachable
// in a correctly-executing generator — assignGroups() only produces cards from
// SkillRecords that were just written. Driving the exported function directly is
// what makes every branch testable; left untested they would be indistinguishable
// from absent code.

describe('assertNoDeadCards — all branches', () => {
  // Minimal section shape: two sections, one with families.
  const makeSection = (groupCards, familyCards = []) => ({
    group: 'Test',
    blurb: '',
    cards: groupCards,
    families: familyCards.length
      ? [{ verb: 'test-verb', cards: familyCards }]
      : [],
  });

  it('passes when all cards are in the written set', () => {
    const sections = [
      makeSection([{ name: 'a', route: '/skills/a/' }]),
      makeSection([], [{ name: 'b', route: '/skills/b/' }]),
    ];
    expect(() => assertNoDeadCards(sections, ['a', 'b'])).not.toThrow();
  });

  it('passes when written set has more entries than cards (extra pages are fine)', () => {
    const sections = [makeSection([{ name: 'a', route: '/skills/a/' }])];
    expect(() => assertNoDeadCards(sections, ['a', 'b', 'c'])).not.toThrow();
  });

  it('throws [gen-skills] dead card when a section card is missing from written', () => {
    const sections = [
      makeSection([
        { name: 'a', route: '/skills/a/' },
        { name: 'missing-skill', route: '/skills/missing-skill/' },
      ]),
    ];
    expect(() => assertNoDeadCards(sections, ['a'])).toThrow(
      /\[gen-skills\] dead card:.*missing-skill/
    );
  });

  it('throws [gen-skills] dead card when a family card is missing from written', () => {
    const sections = [
      makeSection(
        [{ name: 'a', route: '/skills/a/' }],
        [{ name: 'ghost-skill', route: '/skills/ghost-skill/' }]
      ),
    ];
    expect(() => assertNoDeadCards(sections, ['a'])).toThrow(
      /\[gen-skills\] dead card:.*ghost-skill/
    );
  });

  it('names the specific offending card in the error message', () => {
    const sections = [
      makeSection([{ name: 'xyz-offender', route: '/skills/xyz-offender/' }]),
    ];
    let err;
    try {
      assertNoDeadCards(sections, []);
    } catch (e) {
      err = e;
    }
    expect(err).toBeDefined();
    expect(err.message).toContain('[gen-skills] dead card:');
    expect(err.message).toContain('xyz-offender');
  });

  it('passes with empty sections', () => {
    expect(() => assertNoDeadCards([], [])).not.toThrow();
    expect(() => assertNoDeadCards([], ['a', 'b'])).not.toThrow();
  });

  it('passes with sections that have no cards or families', () => {
    const sections = [makeSection([]), makeSection([], [])];
    expect(() => assertNoDeadCards(sections, [])).not.toThrow();
  });
});
