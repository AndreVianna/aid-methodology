// FR-8 group (c): the facts script must detect drift, and must not crash silently.
import { spawnSync } from 'node:child_process';
import { appendFileSync, cpSync, mkdirSync, mkdtempSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterAll, describe, expect, it } from 'vitest';
import { REPO, SITE } from './dist.mjs';

const DOCS = join(SITE, 'src/content/docs');
const temps = [];

function tempDir() {
  const dir = mkdtempSync(join(tmpdir(), 'aid-facts-test-'));
  temps.push(dir);
  return dir;
}

function run(...args) {
  return spawnSync(process.execPath, [join(SITE, 'scripts/gen-facts.mjs'), ...args], {
    cwd: SITE,
    encoding: 'utf8',
  });
}

/** Copy the committed generated pages into a fresh temp folder and return it. */
function copyPages() {
  const dir = tempDir();
  for (const rel of ['skills', 'reference/agents.md', 'reference/settings.md']) {
    mkdirSync(dirname(join(dir, rel)), { recursive: true });
    cpSync(join(DOCS, rel), join(dir, rel), { recursive: true });
  }
  return dir;
}

afterAll(() => {
  for (const dir of temps) rmSync(dir, { recursive: true, force: true });
});

describe('gen-facts --check', () => {
  it('C1 committed pages are current', () => {
    const r = run('--check');
    expect(r.status).toBe(0);
    expect(r.stdout + r.stderr).toMatch(/pages up to date/);
  });

  it('C2 a stale page is caught', () => {
    const tmp = copyPages();
    appendFileSync(join(tmp, 'skills/aid-fix.md'), 'drift\n');
    const r = run('--check', '--out', tmp);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain('stale: skills/aid-fix.md');
  });

  it('C3 an extra page is caught', () => {
    const tmp = copyPages();
    writeFileSync(join(tmp, 'skills/aid-gone.md'), 'extra\n');
    const r = run('--check', '--out', tmp);
    expect(r.status).toBe(1);
    expect(r.stderr).toContain('extra: skills/aid-gone.md');
  });

  it('C4 an ungrouped skill fails', () => {
    const tmp = tempDir();
    const src = join(REPO, 'canonical');
    cpSync(join(src, 'skills'), join(tmp, 'skills'), { recursive: true });
    cpSync(join(src, 'agents'), join(tmp, 'agents'), { recursive: true });
    mkdirSync(join(tmp, 'aid/templates'), { recursive: true });
    for (const f of ['shortcut-catalog.yml', 'settings.yml']) {
      cpSync(join(src, 'aid/templates', f), join(tmp, 'aid/templates', f));
    }
    mkdirSync(join(tmp, 'skills/aid-orphan'), { recursive: true });
    writeFileSync(
      join(tmp, 'skills/aid-orphan/SKILL.md'),
      '---\nname: aid-orphan\ndescription: An orphan skill used only by the test.\n---\n\nBody.\n',
    );
    const r = run('--check', '--canonical', tmp);
    expect(r.status).toBe(2);
    expect(r.stderr).toContain('aid-orphan has no group');
  });

  it('C5 write mode reproduces the committed bytes', () => {
    const tmp = tempDir();
    const expected = readdirSync(join(REPO, 'canonical/skills')).length + 3;
    const first = run('--out', tmp);
    expect(first.status).toBe(0);
    expect(first.stdout + first.stderr).toContain(`wrote ${expected}`);
    const second = run('--check', '--out', tmp);
    expect(second.status).toBe(0);
  });
});
