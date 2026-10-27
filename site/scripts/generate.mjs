#!/usr/bin/env node
// Build-time generator. Runs before `astro build` and `astro dev`.
//
// The site never keeps a second copy of anything the repository already says:
//   docs/*.md             -> concepts/ and reference/ pages (links and callouts rewritten)
//   canonical/skills/*    -> one page per skill + the skills index
//   canonical/agents/*    -> the agents page
//   VERSION               -> src/generated/site.json
// Hand-written plain-language data lives in src/data/{skills,agents}.json; the live
// SKILL.md / AGENT.md frontmatter supplies descriptions, argument hints and tiers.
// Everything written here is git-ignored (see site/.gitignore).

import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { GROUPS } from '../src/data/groups.mjs';

const SITE = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ROOT = resolve(SITE, '..');
const DOCS = join(SITE, 'src/content/docs');
const REPO = 'https://github.com/AndreVianna/aid-methodology';

// ── Pure helpers (exported for tests) ──────────────────────────────────────

/** Minimal frontmatter reader: `key: value`, quoted values, and folded (`>`) blocks. */
export function readFrontmatter(text) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text);
  if (!m) return {};
  const out = {};
  const lines = m[1].split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const kv = /^([A-Za-z][\w-]*):\s*(.*)$/.exec(lines[i]);
    if (!kv) continue;
    let [, key, val] = kv;
    if (/^[>|][+-]?$/.test(val)) {
      const parts = [];
      while (i + 1 < lines.length && /^\s+\S/.test(lines[i + 1])) parts.push(lines[++i].trim());
      val = parts.join(' ');
    } else if (/^(["']).*\1$/.test(val)) {
      val = val.slice(1, -1);
    }
    out[key] = val.trim();
  }
  return out;
}

/** Escape text for MDX prose, leaving `code spans` alone. */
export function mdx(text) {
  return String(text)
    .split(/(`[^`]*`)/)
    .map((part, i) => (i % 2 ? part : part.replace(/\{/g, '\\{').replace(/\}/g, '\\}').replace(/</g, '&lt;')))
    .join('');
}

const yamlString = (s) => JSON.stringify(String(s));

const DOC_LINKS = {
  'aid-methodology.md': '/concepts/methodology/',
  'faq.md': '/concepts/faq/',
  'glossary.md': '/reference/glossary/',
  'repository-structure.md': '/reference/repository-structure/',
  'install.md': '/get-started/install/',
  'chat-wake-install.md': '/guides/agent-chat/',
};

// docs/install.md is replaced on the site by the Get started install page, whose headings differ.
const INSTALL_ANCHORS = {
  'update-check': 'update',
  'root-agent-files-and-the-aid-region': 'the-aid-block-in-your-root-files',
};

/** Where a relative link found in docs/*.md should point on the website. */
export function rewriteTarget(target) {
  if (/^([a-z][a-z0-9+.-]*:|#|\/)/i.test(target)) return target;
  const [path, hash = ''] = target.split('#');
  const clean = path.replace(/^\.\//, '');
  const suffix = hash ? `#${clean === 'install.md' ? INSTALL_ANCHORS[hash] ?? hash : hash}` : '';
  if (DOC_LINKS[clean]) return DOC_LINKS[clean] + suffix;
  if (clean.startsWith('images/')) return `/${clean}${suffix}`;
  const abs = resolve('/docs', clean).slice(1); // path relative to the repo root
  const kind = /\.[a-z0-9]+$/i.test(abs) ? 'blob' : 'tree';
  return `${REPO}/${kind}/master/${abs}${suffix}`;
}

/** Turn one docs/*.md file into a Starlight page body (no frontmatter). */
export function transformDoc(markdown) {
  const out = [];
  let fence = null; // the marker that opened the current fenced block
  let skipping = null; // 'mermaid' | 'toc' | null
  let sawH1 = false;
  const lines = markdown.replace(/\r\n/g, '\n').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const fenceMatch = /^(\s*)(`{3,}|~{3,})(.*)$/.exec(line);
    if (skipping === 'mermaid') {
      if (fenceMatch && fence && line.trim().startsWith(fence)) { skipping = null; fence = null; }
      continue;
    }
    if (fenceMatch) {
      if (!fence) {
        fence = fenceMatch[2];
        if (/^\s*mermaid\b/.test(fenceMatch[3])) { skipping = 'mermaid'; continue; }
      } else if (line.trim().startsWith(fence)) {
        fence = null;
      }
      out.push(line);
      continue;
    }
    if (fence) { out.push(line); continue; }

    if (!sawH1 && /^# /.test(line)) { sawH1 = true; continue; }
    if (/^##\s+(Table of Contents|Contents)\s*$/i.test(line)) { skipping = 'toc'; continue; }
    if (skipping === 'toc') {
      if (/^#{1,2}\s/.test(line)) skipping = null;
      else continue;
    }
    // GitHub alert -> Starlight aside
    const alert = /^>\s*\[!(NOTE|TIP|WARNING|CAUTION|IMPORTANT)\]\s*$/i.exec(line);
    if (alert) {
      const type = { note: 'note', tip: 'tip', important: 'note', warning: 'caution', caution: 'danger' }[alert[1].toLowerCase()];
      const body = [];
      while (i + 1 < lines.length && /^>/.test(lines[i + 1])) body.push(lines[++i].replace(/^>\s?/, ''));
      out.push(`:::${type}`, ...body, ':::');
      continue;
    }
    out.push(line.replace(/\]\(([^)\s]+)((?:\s+"[^"]*")?)\)/g, (_, t, title) => `](${rewriteTarget(t)}${title})`));
  }
  return out.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n';
}

// ── Generation ─────────────────────────────────────────────────────────────

const read = (p) => readFileSync(p, 'utf8');
const readJson = (p) => JSON.parse(read(p));
function write(path, text) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
}

const IMPORT_FLOW = "import Flow from '~/components/Flow.astro';";
const frontmatter = (fields) => `---\n${Object.entries(fields).map(([k, v]) => `${k}: ${v}`).join('\n')}\n---\n`;

const DOC_PAGES = [
  { src: 'aid-methodology.md', dest: 'concepts/methodology.md', title: 'The AID methodology', description: 'The whole method in one document: pipeline, philosophy, Knowledge Base, phases, agents, feedback loops and adoption.', order: 2 },
  { src: 'faq.md', dest: 'concepts/faq.md', title: 'FAQ', description: 'Short answers to common questions about adopting and running AID.', order: 3 },
  { src: 'glossary.md', dest: 'reference/glossary.md', title: 'Glossary', description: 'What each AID term means, in plain words.', order: 9 },
  { src: 'repository-structure.md', dest: 'reference/repository-structure.md', title: 'Repository structure', description: 'How the AID repository is laid out and where things live.', order: 8 },
];

function syncDocs() {
  for (const p of DOC_PAGES) {
    const body = transformDoc(read(join(ROOT, 'docs', p.src)));
    write(join(DOCS, p.dest), frontmatter({
      title: yamlString(p.title),
      description: yamlString(p.description),
      editUrl: yamlString(`${REPO}/edit/master/docs/${p.src}`),
      sidebar: `\n  order: ${p.order}`,
    }) + `\n<!-- Generated by site/scripts/generate.mjs from docs/${p.src}. Edit that file, not this one. -->\n\n${body}`);
  }
  if (existsSync(join(ROOT, 'docs/images'))) {
    rmSync(join(SITE, 'public/images'), { recursive: true, force: true });
    cpSync(join(ROOT, 'docs/images'), join(SITE, 'public/images'), { recursive: true });
  }
}

export function loadSkills() {
  const curated = readJson(join(SITE, 'src/data/skills.json'));
  const dir = join(ROOT, 'canonical/skills');
  const names = readdirSync(dir, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name).sort();
  return names.map((name) => {
    const fm = readFrontmatter(read(join(dir, name, 'SKILL.md')));
    const c = curated[name];
    if (!c) throw new Error(`canonical/skills/${name} has no entry in site/src/data/skills.json`);
    return { name, ...c, description: fm.description ?? '', hint: fm['argument-hint'] ?? '', tools: (fm['allowed-tools'] ?? '').split(/\s+/).filter(Boolean) };
  });
}

const byGroup = (skills, id) => skills.filter((s) => s.group === id).sort((a, b) => a.order - b.order);

function skillPage(s, all) {
  const known = new Set(all.map((x) => x.name));
  const link = (n) => (known.has(n) ? `[\`/${n}\`](/reference/skills/${n}/)` : `\`/${n}\``);
  const group = GROUPS.find((g) => g.id === s.group);
  const L = [];
  L.push(frontmatter({
    title: yamlString(`/${s.name}`),
    description: yamlString(s.summary),
    editUrl: yamlString(`${REPO}/edit/master/canonical/skills/${s.name}/SKILL.md`),
    sidebar: `\n  label: ${yamlString(s.name)}\n  order: ${s.order}`,
  }));
  L.push(`{/* Generated by site/scripts/generate.mjs from canonical/skills/${s.name}/SKILL.md and src/data/skills.json. */}`, IMPORT_FLOW, '');
  L.push(mdx(s.summary), '', `Group: ${group.title}.`, '');
  L.push('## When to use it', '', mdx(s.when), '');
  L.push('## Try it', '', '```text', s.example, '```', '');
  if (s.hint) L.push('How the tool describes its arguments:', '', '```text', s.hint, '```', '');
  if (s.kinds?.length) {
    L.push('## Kinds', '', `Put one of these words first to say what you mean. For example: \`/${s.name} ${s.kinds[0]}\`.`, '');
    L.push(s.kinds.map((k) => `\`${k}\``).join(', '), '');
  }
  L.push('## What happens', '');
  L.push(`<Flow label="${s.name}: the stages, in order" columns={1} steps={${JSON.stringify(s.steps.map((x) => ({ title: x.title, text: x.text })))}} />`, '');
  L.push('## What it writes', '', ...s.writes.map((w) => `- ${mdx(w)}`), '');
  if (s.gate) L.push('## What you decide', '', mdx(s.gate), '');
  if (s.next?.length) L.push('## What comes next', '', ...s.next.map((n) => `- ${link(n)}`), '');
  if (s.notes?.length) L.push('## Good to know', '', ...s.notes.map((n) => `- ${mdx(n)}`), '');
  L.push('## Details', '');
  if (s.tools.length) L.push(`Tools this skill may use: ${s.tools.map((t) => `\`${t}\``).join(', ')}.`, '');
  L.push(`Definition: [\`canonical/skills/${s.name}/SKILL.md\`](${REPO}/blob/master/canonical/skills/${s.name}/SKILL.md) in the repository.`, '');
  return L.join('\n');
}

function skillsIndex(skills) {
  const L = [frontmatter({
    title: yamlString('Skills'),
    description: yamlString(`All ${skills.length} AID skills, grouped by what they are for. Each is a slash command in your AI coding tool.`),
    sidebar: '\n  order: 2',
  })];
  L.push('{/* Generated by site/scripts/generate.mjs. */}', '');
  L.push(`AID ships ${skills.length} skills. A skill is a slash command, such as \`/aid-fix\`, that you type in your AI coding tool. Skills that take a *kind* accept a word after the name: \`/aid-create api\`.`, '');
  L.push('Not sure where to start? Read [Choose your entry](/guides/choose-your-entry/) or run `/aid-triage`.', '');
  for (const g of GROUPS) {
    const list = byGroup(skills, g.id);
    if (!list.length) continue;
    L.push(`## ${g.title}`, '', g.blurb, '', '| Skill | What it does | Example |', '| --- | --- | --- |');
    for (const s of list) L.push(`| [\`/${s.name}\`](/reference/skills/${s.name}/) | ${mdx(s.summary).replace(/\|/g, '\\|')} | \`${s.example.replace(/\|/g, '\\|')}\` |`);
    L.push('');
  }
  return L.join('\n');
}

function agentsPage(agents) {
  const L = [frontmatter({
    title: yamlString('Agents'),
    description: yamlString(`The ${agents.agents.length} specialist agents AID hands work to, what each may do, and which model tier each uses.`),
    sidebar: '\n  order: 3',
  })];
  L.push('{/* Generated by site/scripts/generate.mjs from each canonical agent definition and src/data/agents.json. */}', '');
  L.push('An agent is a focused helper that a skill starts for one job, with its own clean context. You never call an agent directly; skills do it for you.', '');
  if (agents.rules?.length) L.push(...agents.rules.map((r) => `- ${mdx(r)}`), '');
  L.push('## Tiers', '', '| Tier | Meaning |', '| --- | --- |', ...agents.tiers.map((t) => `| ${t.name} | ${mdx(t.meaning)} |`), '');
  if (agents.tools?.length) {
    const tiers = agents.tiers.map((t) => t.name);
    L.push('## Which model each tool uses', '', `| Tool | ${tiers.join(' | ')} |`, `| --- | ${tiers.map(() => '---').join(' | ')} |`);
    for (const t of agents.tools) L.push(`| ${t.name} | ${tiers.map((n) => mdx(t.tierModels?.[n.toLowerCase()] ?? t.tierModels?.[n] ?? '')).join(' | ')} |`);
    L.push('');
  }
  L.push('## The agents', '');
  for (const a of agents.agents) {
    L.push(`### ${a.role}`, '', `\`${a.name}\` · ${a.tier} tier`, '', mdx(a.summary), '');
    if (a.does?.length) L.push('It does:', '', ...a.does.map((x) => `- ${mdx(x)}`), '');
    if (a.doesNot?.length) L.push('It does not:', '', ...a.doesNot.map((x) => `- ${mdx(x)}`), '');
    if (a.usedBy?.length) L.push(`Used by: ${a.usedBy.map((u) => (u.startsWith('aid-') ? `[\`/${u}\`](/reference/skills/${u}/)` : mdx(u))).join(', ')}.`, '');
  }
  L.push('## Source', '', `Each agent is defined in \`canonical/agents/<name>/AGENT.md\` ([browse on GitHub](${REPO}/tree/master/canonical/agents)).`, '');
  return L.join('\n');
}

export function loadAgentTiers() {
  const dir = join(ROOT, 'canonical/agents');
  return Object.fromEntries(readdirSync(dir, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => [d.name, readFrontmatter(read(join(dir, d.name, 'AGENT.md'))).tier]));
}

function generate() {
  mkdirSync(join(SITE, 'src/generated'), { recursive: true });
  write(join(SITE, 'src/generated/site.json'), JSON.stringify({ version: read(join(ROOT, 'VERSION')).trim(), repo: REPO }, null, 2) + '\n');
  syncDocs();

  const skills = loadSkills();
  rmSync(join(DOCS, 'reference/skills'), { recursive: true, force: true });
  write(join(DOCS, 'reference/skills/index.mdx'), skillsIndex(skills));
  for (const s of skills) write(join(DOCS, `reference/skills/${s.name}.mdx`), skillPage(s, skills));

  const agents = readJson(join(SITE, 'src/data/agents.json'));
  write(join(DOCS, 'reference/agents.mdx'), agentsPage(agents));
  console.log(`generate: ${skills.length} skills, ${agents.agents.length} agents, ${DOC_PAGES.length} synced docs`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) generate();
