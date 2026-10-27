// Guards the generator and the hand-written data against drifting from the repository.
// Fast and offline: `npm test`.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { GROUPS } from '../src/data/groups.mjs';
import { loadAgentTiers, loadSkills, mdx, readFrontmatter, rewriteTarget, transformDoc } from '../scripts/generate.mjs';

const SITE = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ROOT = resolve(SITE, '..');
const json = (p) => JSON.parse(readFileSync(join(SITE, p), 'utf8'));

test('every canonical skill has plain-language data, and nothing else does', () => {
  const onDisk = readdirSync(join(ROOT, 'canonical/skills'), { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name);
  assert.deepEqual(Object.keys(json('src/data/skills.json')).sort(), onDisk.sort());
});

test('skill data is complete and well-formed', () => {
  const skills = loadSkills();
  const names = new Set(skills.map((s) => s.name));
  const groups = new Set(GROUPS.map((g) => g.id));
  for (const s of skills) {
    const at = `skills.json › ${s.name}`;
    assert.ok(groups.has(s.group), `${at}: unknown group "${s.group}"`);
    assert.ok(Number.isInteger(s.order), `${at}: order must be an integer`);
    assert.ok(s.summary && s.summary.length <= 140, `${at}: summary missing or over 140 characters`);
    assert.ok(s.when && s.example?.startsWith(`/${s.name}`), `${at}: needs "when" and an example that starts with /${s.name}`);
    assert.ok(s.steps?.length >= 2 && s.steps.every((x) => x.title && x.text), `${at}: steps need a title and text`);
    assert.ok(s.writes?.length, `${at}: writes must not be empty`);
    for (const n of s.next ?? []) assert.ok(names.has(n), `${at}: next names unknown skill ${n}`);
    assert.ok(s.description, `${at}: SKILL.md has no description`);
  }
  for (const g of GROUPS) assert.ok(skills.some((s) => s.group === g.id), `group "${g.id}" has no skills`);
});

test('agent data matches the canonical agents and their tiers', () => {
  const tiers = loadAgentTiers();
  const data = json('src/data/agents.json');
  assert.deepEqual(data.agents.map((a) => a.name).sort(), Object.keys(tiers).sort());
  for (const a of data.agents) assert.equal(a.tier, tiers[a.name], `${a.name}: tier differs from AGENT.md`);
});

test('readFrontmatter reads folded and quoted values', () => {
  const fm = readFrontmatter('---\nname: aid-x\ndescription: >\n  One line\n  two lines.\nargument-hint: "[a]  -- b"\n---\nbody');
  assert.deepEqual(fm, { name: 'aid-x', description: 'One line two lines.', 'argument-hint': '[a]  -- b' });
});

test('mdx escapes braces and angle brackets but not code spans', () => {
  assert.equal(mdx('a {b} <c> `{d}`'), 'a \\{b\\} &lt;c> `{d}`');
});

test('rewriteTarget sends doc links to site pages and everything else to GitHub', () => {
  assert.equal(rewriteTarget('install.md#x'), '/get-started/install/#x');
  assert.equal(rewriteTarget('./faq.md'), '/concepts/faq/');
  assert.equal(rewriteTarget('images/a.png'), '/images/a.png');
  assert.equal(rewriteTarget('#local'), '#local');
  assert.equal(rewriteTarget('https://x.dev/a'), 'https://x.dev/a');
  assert.match(rewriteTarget('../README.md'), /\/blob\/master\/README\.md$/);
  assert.match(rewriteTarget('../examples/'), /\/tree\/master\/examples$/);
});

test('transformDoc drops the H1, contents list and mermaid, and converts alerts', () => {
  const out = transformDoc([
    '# Title', '', 'Intro [faq](faq.md).', '', '## Contents', '', '- [a](#a)', '', '---', '', '## A', '',
    '```mermaid', 'flowchart TD', '```', '', '> [!NOTE]', '> Be careful.', '', '```bash', '# not a heading', '```', '',
  ].join('\n'));
  assert.ok(!out.includes('# Title') && !out.includes('mermaid') && !out.includes('Contents'));
  assert.ok(out.includes('[faq](/concepts/faq/)'));
  assert.ok(out.includes(':::note\nBe careful.\n:::'));
  assert.ok(out.includes('# not a heading'), 'text inside code fences is left alone');
});

test('relative links in the imported docs point at files that exist', () => {
  for (const f of ['aid-methodology.md', 'faq.md', 'glossary.md', 'repository-structure.md']) {
    const text = readFileSync(join(ROOT, 'docs', f), 'utf8').replace(/```[\s\S]*?```/g, '');
    for (const [, target] of text.matchAll(/\]\(([^)\s]+)/g)) {
      if (/^([a-z][a-z0-9+.-]*:|#|\/)/i.test(target)) continue;
      const file = target.split('#')[0];
      assert.ok(existsSync(resolve(ROOT, 'docs', file)), `docs/${f} links to missing ${target}`);
    }
  }
});
