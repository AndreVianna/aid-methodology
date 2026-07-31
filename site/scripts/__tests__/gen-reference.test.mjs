// gen-reference.test.mjs — Unit and integration tests for feature-006 (task-018)
//
// Tests: generated reference pages present, roster counts match source,
// idempotency (drift-check), hand-authored pages exist, links resolve in content.

import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';
import { SKILL_GROUPS } from '../skills/curated-roster.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const REPO_ROOT = resolve(__dirname, '../../../');
const CONTENT_DOCS = join(SITE_ROOT, 'src', 'content', 'docs');
const MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.reference-manifest.json');

// Source directories
const SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const AGENTS_DIR = join(REPO_ROOT, 'canonical', 'agents');
const KB_DIR = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'knowledge-base');
const SHORTCUT_CATALOG_FILE = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'shortcut-catalog.yml');

// Local catalog reader mirroring gen-reference.mjs's row opener, field line and
// scalar strip. Re-implemented, NOT imported: gen-reference.mjs calls main() at
// module scope, so importing from it would regenerate that generator's pages.
function stripCatalogScalar(raw) {
  let val = raw.trim();
  const commentIdx = val.indexOf(' #');
  if (commentIdx !== -1) val = val.slice(0, commentIdx).trim();
  return val.replace(/^['"]|['"]$/g, '');
}

function parseCatalogRows(raw) {
  const rows = [];
  let current = null;
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const rowStart = line.match(/^ {2}- name:\s*(.+)$/);
    if (rowStart) {
      if (current) rows.push(current);
      current = { name: stripCatalogScalar(rowStart[1]) };
      continue;
    }
    if (!current) continue;
    const field = line.match(/^ {4}([a-zA-Z_]+):\s*(.*)$/);
    if (field) current[field[1]] = stripCatalogScalar(field[2]);
  }
  if (current) rows.push(current);
  return rows;
}

// Generated reference pages
const GENERATED_PAGES = [
  join(CONTENT_DOCS, 'reference', 'skills.md'),
  join(CONTENT_DOCS, 'reference', 'agents.md'),
  join(CONTENT_DOCS, 'reference', 'kb.md'),
  join(CONTENT_DOCS, 'reference', 'settings.md'),
];

// ── Setup ─────────────────────────────────────────────────────────────────────

beforeAll(() => {
  if (!GENERATED_PAGES.every((p) => existsSync(p))) {
    execSync('node scripts/gen-reference.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });
  }
});

// ── Existence: generated pages ────────────────────────────────────────────────

describe('gen-reference: generated pages exist', () => {
  it('reference/skills.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'skills.md'))).toBe(true);
  });
  it('reference/agents.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'agents.md'))).toBe(true);
  });
  it('reference/kb.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'kb.md'))).toBe(true);
  });
  it('reference/settings.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'settings.md'))).toBe(true);
  });
  it('.reference-manifest.json exists outside collection root', () => {
    expect(existsSync(MANIFEST_PATH)).toBe(true);
  });
});

// ── Existence: hand-authored pages ────────────────────────────────────────────

describe('gen-reference: hand-authored pages exist', () => {
  it('concepts/overview.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'concepts', 'overview.md'))).toBe(true);
  });
  it('reference/overview.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'overview.md'))).toBe(true);
  });
  it('reference/cli.mdx exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'cli.mdx'))).toBe(true);
  });
  it('reference/artifacts.md exists', () => {
    expect(existsSync(join(CONTENT_DOCS, 'reference', 'artifacts.md'))).toBe(true);
  });
});

// ── Frontmatter: generatedFrom field ─────────────────────────────────────────

describe('gen-reference: generatedFrom frontmatter', () => {
  it('skills.md has generatedFrom frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');
    expect(content).toContain(
      "generatedFrom: 'canonical/aid/templates/shortcut-catalog.yml, canonical/aid/templates/shortcut-engine.md'"
    );
  });
  it('agents.md has generatedFrom frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'agents.md'), 'utf8');
    expect(content).toContain("generatedFrom: 'canonical/agents/*/AGENT.md'");
  });
  it('kb.md has generatedFrom frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'kb.md'), 'utf8');
    expect(content).toContain('generatedFrom');
  });
  it('settings.md has generatedFrom frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'settings.md'), 'utf8');
    expect(content).toContain("generatedFrom: '.aid/settings.yml'");
  });
});

// ── Roster counts match source ────────────────────────────────────────────────

// The curated (non-shortcut) skill roster — the skills gen-reference.mjs's
// SKILL_GROUPS USED to render as individual `### \`aid-...\`` sections, until
// task-057 hollowed that page out; the roster now renders only at /skills/.
// Which skills are curated is a curatorial choice living in SKILL_GROUPS, not a
// filesystem fact, so this list stays hand-maintained rather than derived —
// deriving it would only make the test tautological with the generator. It is
// kept honest by the clamp assertion below, which fails BY NAME for any on-disk
// skill directory that is neither a catalog row nor listed here.
// (Until task-057 this comment ended by saying the other directories were
// "summarized by family in the Direct-entry shortcuts table". That table is gone --
// the roster moved to /skills/ and this page kept only the engine narrative.)
const CURATED_SKILL_NAMES = [
  'aid-config', 'aid-discover', 'aid-summarize',
  'aid-triage',
  'aid-describe', 'aid-define', 'aid-specify',
  'aid-plan', 'aid-detail',
  'aid-execute',
  // work-003 extracts review into two chainable skills. Added here as well as in
  // curated-roster.mjs and skills/groups.mjs -- this list is deliberately independent (see the
  // note below), so its agreement with the roster is the assertion, and that agreement is what
  // broke at the work-003/master merge.
  'aid-light-review', 'aid-deep-review',
  'aid-deploy', 'aid-monitor',
  'aid-housekeep', 'aid-query-kb', 'aid-ask', 'aid-update-kb',
  'aid-set-connector', 'aid-unset-connector',
  'aid-read-ticket', 'aid-create-ticket', 'aid-update-ticket',
].sort();

// The list above is deliberately NOT derived — deriving it from the roster would make the
// clamp below tautological with the generator it is checking. But left unchecked it is a
// SECOND hand-maintained roster that can drift from the first, which is the KI-005 class
// wearing a different hat. So the list stays independent and its AGREEMENT with the roster
// is the assertion. (This became possible only when task-054 extracted SKILL_GROUPS into
// curated-roster.mjs; while it lived inside gen-reference.mjs, importing it here would have
// run main() and regenerated four pages as a side effect of a test.)
describe('the two curated rosters agree', () => {
  it('CURATED_SKILL_NAMES equals curated-roster.mjs SKILL_GROUPS membership', () => {
    const fromRoster = [...new Set(SKILL_GROUPS.flatMap((g) => g.skills.map((s) => s.name)))].sort();
    expect(CURATED_SKILL_NAMES).toEqual(fromRoster);
  });
});

const catalogRows = parseCatalogRows(readFileSync(SHORTCUT_CATALOG_FILE, 'utf8'));
const catalogNames = catalogRows.map((r) => r.name);
const emittingNames = catalogRows.filter((r) => r.repurpose !== 'true').map((r) => r.name);

describe('gen-reference: roster counts', () => {
  it('skills.md: on-disk skill dirs reconcile with the catalog and the curated roster', () => {
    const skillDirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name);

    // Every catalog row has a directory on disk.
    expect(catalogNames.filter((n) => !skillDirs.includes(n))).toEqual([]);

    // The clamp: no on-disk skill exists that the roster does not know about.
    // Adding a hand-authored skill without listing it here fails HERE, by name.
    // Ordered ahead of the set-equality check below deliberately: both catch an
    // unknown directory, but the clamp names it, where set equality reports a
    // whole-corpus array diff.
    expect(
      skillDirs.filter((d) => !catalogNames.includes(d) && !CURATED_SKILL_NAMES.includes(d))
    ).toEqual([]);

    // Non-curated directories and non-curated catalog names are the same set,
    // in both directions — no count.
    const shortcutDirs = skillDirs.filter((d) => !CURATED_SKILL_NAMES.includes(d));
    expect(shortcutDirs.slice().sort()).toEqual(
      catalogNames.filter((n) => !CURATED_SKILL_NAMES.includes(n)).slice().sort()
    );

    // No curated name has lost its directory.
    expect(CURATED_SKILL_NAMES.filter((n) => !skillDirs.includes(n))).toEqual([]);

    // NOTE: this test used to end by counting per-skill sections on
    // reference/skills.md, one per curated skill. delivery-006 task-057 hollowed that
    // page out -- the roster it duplicated now lives only at /skills/ -- so that
    // assertion's subject is gone by design (work-level Q4). Everything above is
    // retained and unweakened: it reconciles the on-disk corpus against the catalog and
    // the curated roster, which is delivery-001's actual guarantee and has nothing to do
    // with what any page renders. Page-shape assertions for the new page are below.
  });

  it('skills.md: keeps the shortcut-engine narrative and sheds the roster table', () => {
    const skillsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');

    // The narrative is the REASON this page was hollowed out rather than deleted: it is
    // the only place on the site that explains the engine. Asserted by content, per the
    // delivery's gate criterion -- not by the file merely existing.
    expect(skillsContent).toContain('## Direct-entry shortcuts');
    expect(skillsContent).toContain('INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT');
    expect(skillsContent).toContain('shortcut engine');
    expect(skillsContent).toContain('APPROVAL-HALT. GATE grades every generated document');

    // The family table is gone -- and with it KI-009. Both broken renderings ("= 0" and
    // "-1 typed forms") came from per-family detail templates interpolating against an
    // empty row set for the two `repurpose` families, so deleting the table IS the close;
    // repairing the arithmetic and keeping a duplicate roster would have been the wrong one.
    expect(skillsContent).not.toContain('**Total**');
    expect(skillsContent).not.toContain('| Family | Count | Forms |');
    expect(skillsContent).not.toMatch(/=\s*0\b/);
    expect(skillsContent).not.toContain('typed forms');
    // Non-vacuity: emittingNames is a real, non-empty set, so a table WOULD have had rows.
    expect(emittingNames.length).toBeGreaterThan(20);

    // The shortcut count itself is still stated, and still derived.
    expect(skillsContent).toContain(
      '**' + emittingNames.length + ' engine-driven verb-first shortcut skills**'
    );
  });

  it('skills.md: points a reader at the roster instead of repeating it', () => {
    const skillsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');
    // Inbound links and bookmarks predating delivery-006 land here expecting the roster.
    expect(skillsContent).toContain('/skills/');
    expect(skillsContent).toMatch(/Looking for the list of skills/);
  });

  it('agents.md: exactly 9 agent sections matching canonical/agents/', () => {
    const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name);
    expect(agentDirs).toHaveLength(10);

    const agentsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'agents.md'), 'utf8');
    const sections = agentsContent.split('\n').filter((l) => /^### `aid-/.test(l));
    expect(sections).toHaveLength(10);
  });

  it('kb.md: exactly 14 KB doc-type rows matching canonical/aid/templates/knowledge-base/', () => {
    const kbFiles = readdirSync(KB_DIR)
      .filter((f) => f.endsWith('.md') && f !== 'README.md');
    expect(kbFiles).toHaveLength(14);

    const kbContent = readFileSync(join(CONTENT_DOCS, 'reference', 'kb.md'), 'utf8');
    // Count data rows (lines starting with | `)
    const rows = kbContent.split('\n').filter((l) => /^\| `[a-z]/.test(l));
    expect(rows).toHaveLength(14);
  });

  it('skills.md no longer lists the curated skills, and /skills/ does', () => {
    // The inverse of the assertion this replaces. Duplicating the roster across two pages
    // is what delivery-006 exists to end, so "every curated name appears HERE" became the
    // wrong contract -- while "every curated name appears somewhere a reader can find it"
    // is still guaranteed, just on the derived page.
    const skillsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');
    const perSkillSections = skillsContent.split('\n').filter((l) => /^### `aid-/.test(l));
    expect(perSkillSections).toEqual([]);

    const rosterPage = readFileSync(join(CONTENT_DOCS, 'skills', 'index.md'), 'utf8');
    const missing = CURATED_SKILL_NAMES.filter((n) => !rosterPage.includes('`' + n + '`'));
    expect(missing, 'curated skills absent from the roster page').toEqual([]);
    // Non-vacuity: the curated set is real, so the filter had something to check.
    expect(CURATED_SKILL_NAMES.length).toBeGreaterThan(10);
  });

  it('agents.md: all canonical agent names are present', () => {
    const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name)
      .sort();

    const agentsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'agents.md'), 'utf8');
    for (const dir of agentDirs) {
      expect(agentsContent).toContain(`\`${dir}\``);
    }
  });
});

// ── "Do not edit" notice ──────────────────────────────────────────────────────

describe('gen-reference: generated marker', () => {
  for (const page of GENERATED_PAGES) {
    const name = basename(page);
    it(`${name}: contains "generated — do not edit" comment`, () => {
      const content = readFileSync(page, 'utf8');
      expect(content).toContain('generated — do not edit');
    });
  }
});

// ── Hand-authored pages: valid frontmatter ───────────────────────────────────

describe('gen-reference: hand-authored page frontmatter', () => {
  it('concepts/overview.md: has title frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'concepts', 'overview.md'), 'utf8');
    expect(content).toMatch(/^---\n/);
    expect(content).toContain('title:');
  });

  it('reference/overview.md: has title frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'overview.md'), 'utf8');
    expect(content).toMatch(/^---\n/);
    expect(content).toContain('title:');
  });

  it('reference/cli.mdx: has title frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'cli.mdx'), 'utf8');
    expect(content).toMatch(/^---\n/);
    expect(content).toContain('title:');
  });

  it('reference/artifacts.md: has title frontmatter', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'artifacts.md'), 'utf8');
    expect(content).toMatch(/^---\n/);
    expect(content).toContain('title:');
  });
});

// ── Hand-authored pages: no sourceDoc/generatedFrom ─────────────────────────

describe('gen-reference: authored pages have no generator provenance', () => {
  it('concepts/overview.md has no sourceDoc or generatedFrom', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'concepts', 'overview.md'), 'utf8');
    const fm = content.match(/^---\n([\s\S]*?)\n---/)?.[1] ?? '';
    expect(fm).not.toContain('sourceDoc:');
    expect(fm).not.toContain('generatedFrom:');
  });

  it('reference/cli.mdx links to guides/installation for long-form prose', () => {
    const content = readFileSync(join(CONTENT_DOCS, 'reference', 'cli.mdx'), 'utf8');
    expect(content).toContain('/guides/installation/');
  });
});

// ── Manifest checks ───────────────────────────────────────────────────────────

describe('gen-reference: .reference-manifest.json', () => {
  let manifest;

  beforeAll(() => {
    manifest = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
  });

  it('manifest has 4 entries (skills, agents, kb, settings)', () => {
    expect(manifest.entries).toHaveLength(4);
  });

  it('manifest.generator identifies gen-reference.mjs', () => {
    expect(manifest.generator).toContain('gen-reference.mjs');
  });

  it('manifest entries cover all 4 generated reference files', () => {
    const dests = manifest.entries.map((e) => e.dest);
    expect(dests.some((d) => d.includes('skills.md'))).toBe(true);
    expect(dests.some((d) => d.includes('agents.md'))).toBe(true);
    expect(dests.some((d) => d.includes('kb.md'))).toBe(true);
    expect(dests.some((d) => d.includes('settings.md'))).toBe(true);
  });

  it('manifest has no generatedAt field (determinism: no wall-clock timestamps)', () => {
    expect(manifest).not.toHaveProperty('generatedAt');
  });
});

// ── Idempotency / drift-check ─────────────────────────────────────────────────

describe('gen-reference: idempotency (drift-check)', () => {
  it('running gen:reference again produces no diff on the owned files', () => {
    // Re-run the generator
    execSync('node scripts/gen-reference.mjs', { cwd: SITE_ROOT, stdio: 'pipe' });

    // Check git diff scoped to the four generated reference pages + manifest
    const scopedPaths = [
      'site/src/content/docs/reference/skills.md',
      'site/src/content/docs/reference/agents.md',
      'site/src/content/docs/reference/kb.md',
      'site/src/content/docs/reference/settings.md',
      'site/scripts/.reference-manifest.json',
    ];

    let diffOutput = '';
    try {
      diffOutput = execSync(
        `git diff --exit-code -- ${scopedPaths.join(' ')}`,
        { cwd: REPO_ROOT, encoding: 'utf8' }
      );
    } catch (err) {
      diffOutput = err.stdout || '';
      throw new Error(
        `Drift detected after re-running gen:reference. Diff output:\n${diffOutput}`
      );
    }

    expect(diffOutput).toBe('');
  });
});

// ── Package.json: single prebuild chain ──────────────────────────────────────

describe('package.json: prebuild chain', () => {
  it('prebuild is a single chained line with sync:docs && gen:reference', () => {
    const pkg = JSON.parse(readFileSync(join(SITE_ROOT, 'package.json'), 'utf8'));
    const prebuild = pkg.scripts?.prebuild ?? '';
    expect(prebuild).toContain('sync:docs');
    expect(prebuild).toContain('gen:reference');
    expect(prebuild).toContain('&&');
  });

  it('package.json has exactly one "prebuild" key', () => {
    const raw = readFileSync(join(SITE_ROOT, 'package.json'), 'utf8');
    const prebuildCount = (raw.match(/"prebuild"/g) || []).length;
    expect(prebuildCount).toBe(1);
  });
});
