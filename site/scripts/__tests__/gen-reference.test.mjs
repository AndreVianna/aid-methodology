// gen-reference.test.mjs — Unit and integration tests for feature-006 (task-018)
//
// Tests: generated reference pages present, roster counts match source,
// idempotency (drift-check), hand-authored pages exist, links resolve in content.

import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, '../../');
const REPO_ROOT = resolve(__dirname, '../../../');
const CONTENT_DOCS = join(SITE_ROOT, 'src', 'content', 'docs');
const MANIFEST_PATH = join(SITE_ROOT, 'scripts', '.reference-manifest.json');

// Source directories
const SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const AGENTS_DIR = join(REPO_ROOT, 'canonical', 'agents');
const KB_DIR = join(REPO_ROOT, 'canonical', 'templates', 'knowledge-base');

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
    expect(content).toContain("generatedFrom: 'canonical/skills/*/SKILL.md'");
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

describe('gen-reference: roster counts', () => {
  it('skills.md: exactly 11 skill rows matching canonical/skills/', () => {
    const skillDirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name);
    expect(skillDirs).toHaveLength(11);

    const skillsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');
    // Count data rows in the table (lines starting with | `aid-)
    const rows = skillsContent.split('\n').filter((l) => l.startsWith('| `aid-'));
    expect(rows).toHaveLength(11);
  });

  it('agents.md: exactly 9 agent rows matching canonical/agents/', () => {
    const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name);
    expect(agentDirs).toHaveLength(9);

    const agentsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'agents.md'), 'utf8');
    const rows = agentsContent.split('\n').filter((l) => l.startsWith('| `aid-'));
    expect(rows).toHaveLength(9);
  });

  it('kb.md: exactly 14 KB doc-type rows matching canonical/templates/knowledge-base/', () => {
    const kbFiles = readdirSync(KB_DIR)
      .filter((f) => f.endsWith('.md') && f !== 'README.md');
    expect(kbFiles).toHaveLength(14);

    const kbContent = readFileSync(join(CONTENT_DOCS, 'reference', 'kb.md'), 'utf8');
    // Count data rows (lines starting with | `)
    const rows = kbContent.split('\n').filter((l) => /^\| `[a-z]/.test(l));
    expect(rows).toHaveLength(14);
  });

  it('skills.md: all canonical skill names are present', () => {
    const skillDirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name)
      .sort();

    const skillsContent = readFileSync(join(CONTENT_DOCS, 'reference', 'skills.md'), 'utf8');
    for (const dir of skillDirs) {
      expect(skillsContent).toContain(`\`${dir}\``);
    }
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
