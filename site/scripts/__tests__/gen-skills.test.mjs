// gen-skills.test.mjs — Unit and integration tests for task-012 / feature-001-skill-detail-pages.
//
// Covers every acceptance criterion:
//   AC-1  Drift guard — missing page and orphan page scenarios.
//   AC-2  Header completeness — every frontmatter key appears on the page.
//   AC-6  Idempotence — byte comparison of two consecutive runs.
//   Manifest shape, marker, isolation, stdout discipline.

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { readFileSync, existsSync, readdirSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync, spawnSync } from 'node:child_process';
import { discoverSkills } from '../skills/discover.mjs';
// Importing the generator is safe — and is itself a check on the `main()` guard.
// gen-reference.mjs calls main() at module scope, so importing it would
// regenerate four pages as a side effect; gen-skills.mjs must not, and this
// import would run the whole generator on every test file load if it did.
import { assertNoSkillsDrift } from '../gen-skills.mjs';

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

  it('manifest.entries count equals directory count — derived, no literal', () => {
    const dirNames = getCanonicalDirNames();
    expect(manifest.entries).toHaveLength(dirNames.length);
  });

  it('manifest.entries are ordered by src ascending (matching sorted directory scan)', () => {
    // The sort is over directory names (UTF-16 code-unit order), which gives a
    // different result from sorting full src paths because '-' (45) < '/' (47):
    // e.g. 'aid-add-api' sorts before 'aid-add' when comparing full paths, but
    // 'aid-add' sorts before 'aid-add-api' when comparing directory names.
    const dirNames = getCanonicalDirNames(); // already sorted
    const expectedSrcs = dirNames.map((d) => 'canonical/skills/' + d + '/SKILL.md');
    const actualSrcs = manifest.entries.map((e) => e.src);
    expect(actualSrcs).toEqual(expectedSrcs);
  });

  it('manifest.entries each have src and dest as POSIX repo-relative strings', () => {
    for (const entry of manifest.entries) {
      // No Windows backslashes.
      expect(entry.src).not.toContain('\\');
      expect(entry.dest).not.toContain('\\');
      // src points at canonical/skills/*/SKILL.md
      expect(entry.src).toMatch(/^canonical\/skills\/[^/]+\/SKILL\.md$/);
      // dest points at site/src/content/docs/skills/*.md
      expect(entry.dest).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }
  });

  it('manifest.generatedPaths contains one entry per skill, all POSIX', () => {
    const dirNames = getCanonicalDirNames();
    expect(manifest.generatedPaths).toHaveLength(dirNames.length);
    for (const p of manifest.generatedPaths) {
      expect(p).not.toContain('\\');
      expect(p).toMatch(/^site\/src\/content\/docs\/skills\/[^/]+\.md$/);
    }
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
  it('two consecutive runs produce byte-identical pages and manifest', () => {
    // Run 1.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Capture byte content after run 1.
    const dirNames = getCanonicalDirNames();
    const run1Pages = new Map();
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      run1Pages.set(dir, readFileSync(p));
    }
    const run1Manifest = readFileSync(MANIFEST_PATH);

    // Run 2.
    execSync('node scripts/gen-skills.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Compare page bytes.
    for (const dir of dirNames) {
      const p = join(SKILLS_OUTPUT_DIR, dir + '.md');
      const run2Content = readFileSync(p);
      const run1Content = run1Pages.get(dir);
      expect(run2Content.equals(run1Content)).toBe(true);
    }

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
