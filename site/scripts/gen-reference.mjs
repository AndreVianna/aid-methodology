#!/usr/bin/env node
// gen-reference.mjs — Manifest-driven reference generator (feature-006).
//
// Generates four reference pages from canonical/ + .aid/settings.yml:
//   reference/skills.md    — 11 skills table
//   reference/agents.md    — 9 agents table
//   reference/kb.md        — 14 KB doc-types table
//   reference/settings.md  — settings keys table
//
// Run: node scripts/gen-reference.mjs
// Wired as: gen:reference in package.json (chained in prebuild / predev)

import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { resolve, dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../');
const SITE_ROOT = join(__dirname, '..');
const CONTENT_DOCS_REF = join(SITE_ROOT, 'src', 'content', 'docs', 'reference');
const MANIFEST_PATH = join(__dirname, '.reference-manifest.json');

// ── Source paths ──────────────────────────────────────────────────────────────

const SKILLS_DIR = join(REPO_ROOT, 'canonical', 'skills');
const AGENTS_DIR = join(REPO_ROOT, 'canonical', 'agents');
const KB_DIR = join(REPO_ROOT, 'canonical', 'templates', 'knowledge-base');
const SETTINGS_FILE = join(REPO_ROOT, '.aid', 'settings.yml');

// ── YAML frontmatter parser (minimal — no deps) ───────────────────────────────

function parseFrontmatter(text) {
  const match = text.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const fm = {};
  const raw = match[1];

  // Handle multi-line folded block (>): `key: >\n  line1\n  line2`
  const lines = raw.split('\n');
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const m = line.match(/^([a-zA-Z_-]+):\s*(.*)/);
    if (!m) { i++; continue; }
    const key = m[1];
    const val = m[2].trim();

    if (val === '>') {
      // Collect indented continuation lines
      const parts = [];
      i++;
      while (i < lines.length && /^\s/.test(lines[i])) {
        parts.push(lines[i].trim());
        i++;
      }
      fm[key] = parts.join(' ').replace(/\s+/g, ' ').trim();
    } else {
      // Handle quoted or bare values
      fm[key] = val.replace(/^['"]|['"]$/g, '');
      i++;
    }
  }
  return fm;
}

// ── YAML frontmatter serializer ───────────────────────────────────────────────

function serializeFrontmatter(fm) {
  const lines = ['---'];
  for (const [key, val] of Object.entries(fm)) {
    const escaped = val.replace(/'/g, "''");
    lines.push(`${key}: '${escaped}'`);
  }
  lines.push('---');
  return lines.join('\n') + '\n';
}

// ── Skills table generator ────────────────────────────────────────────────────

function generateSkillsPage() {
  const skillDirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();

  const rows = skillDirs.map((dir) => {
    const skillPath = join(SKILLS_DIR, dir, 'SKILL.md');
    const content = readFileSync(skillPath, 'utf8');
    const fm = parseFrontmatter(content);
    const name = fm.name || dir;
    const description = fm.description || '';
    const srcPath = `canonical/skills/${dir}/SKILL.md`;
    return { name, description, srcPath };
  });

  const header = `| Skill | Description | Source |
|-------|-------------|--------|`;
  const tableRows = rows.map(
    (r) => `| \`${r.name}\` | ${r.description} | [\`${r.srcPath}\`](https://github.com/AndreVianna/aid-methodology/blob/master/${r.srcPath}) |`
  );
  const table = [header, ...tableRows].join('\n');

  const fm = serializeFrontmatter({
    title: 'Skills Reference',
    description: 'All 11 AID pipeline skills — what each skill does and where its definition lives.',
    generatedFrom: 'canonical/skills/*/SKILL.md',
  });

  const note = `\n<!-- generated — do not edit; source: canonical/skills/*/SKILL.md -->\n\n`;
  return fm + note + table + '\n';
}

// ── Agents table generator ────────────────────────────────────────────────────

function generateAgentsPage() {
  const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();

  const rows = agentDirs.map((dir) => {
    const agentPath = join(AGENTS_DIR, dir, 'AGENT.md');
    const content = readFileSync(agentPath, 'utf8');
    const fm = parseFrontmatter(content);
    const name = fm.name || dir;
    const description = fm.description || '';
    const tier = fm.tier || '';
    const tools = fm.tools || '';
    const srcPath = `canonical/agents/${dir}/AGENT.md`;
    return { name, description, tier, tools, srcPath };
  });

  const header = `| Agent | Description | Tier | Tools | Source |
|-------|-------------|------|-------|--------|`;
  const tableRows = rows.map(
    (r) =>
      `| \`${r.name}\` | ${r.description} | ${r.tier} | ${r.tools} | [\`${r.srcPath}\`](https://github.com/AndreVianna/aid-methodology/blob/master/${r.srcPath}) |`
  );
  const table = [header, ...tableRows].join('\n');

  const fm = serializeFrontmatter({
    title: 'Agents Reference',
    description: 'All 9 AID pipeline agents — role, tier, tools, and source definition.',
    generatedFrom: 'canonical/agents/*/AGENT.md',
  });

  const note = `\n<!-- generated — do not edit; source: canonical/agents/*/AGENT.md -->\n\n`;
  return fm + note + table + '\n';
}

// ── KB doc-types table generator ──────────────────────────────────────────────

function generateKbPage() {
  const files = readdirSync(KB_DIR)
    .filter((f) => f.endsWith('.md') && f !== 'README.md')
    .sort();

  const rows = files.map((file) => {
    const filePath = join(KB_DIR, file);
    const content = readFileSync(filePath, 'utf8');
    // Leading H1 (outside frontmatter) as the one-liner
    const afterFm = content.replace(/^---[\s\S]*?---\n/, '');
    const h1Match = afterFm.match(/^# (.+)/m);
    const title = h1Match ? h1Match[1].trim() : basename(file, '.md');
    const docType = basename(file, '.md');
    const srcPath = `canonical/templates/knowledge-base/${file}`;
    return { docType, title, srcPath };
  });

  const header = `| Doc Type | Title | Source |
|----------|-------|--------|`;
  const tableRows = rows.map(
    (r) =>
      `| \`${r.docType}\` | ${r.title} | [\`${r.srcPath}\`](https://github.com/AndreVianna/aid-methodology/blob/master/${r.srcPath}) |`
  );
  const table = [header, ...tableRows].join('\n');

  const fm = serializeFrontmatter({
    title: 'Knowledge Base Doc Types',
    description: 'All 14 standard AID Knowledge Base document types — what each captures and where its template lives.',
    generatedFrom: 'canonical/templates/knowledge-base/*.md',
  });

  const note = `\n<!-- generated — do not edit; source: canonical/templates/knowledge-base/*.md -->\n\n`;
  return fm + note + table + '\n';
}

// ── Settings table generator ──────────────────────────────────────────────────
//
// Parses .aid/settings.yml to extract key paths, values, and inline # comments.
// Uses a single-pass line-by-line state machine (no YAML library deps).

function generateSettingsPage() {
  const raw = readFileSync(SETTINGS_FILE, 'utf8');
  const lines = raw.split('\n');

  const rows = [];
  // Stack of { key, indent } for building dotted key paths
  const stack = [];
  // List accumulation state
  let listMode = false;
  let listPath = '';
  let listItems = [];
  let listIndent = -1;

  function flushList() {
    if (listMode && listItems.length > 0) {
      rows.push({ path: listPath, value: listItems.join(', '), description: 'Installed AI host tools' });
    }
    listMode = false;
    listPath = '';
    listItems = [];
    listIndent = -1;
  }

  for (const line of lines) {
    const trimmed = line.trim();
    // Skip blank lines and full-line comments
    if (!trimmed || trimmed.startsWith('#')) continue;

    const indent = line.match(/^(\s*)/)[1].length;

    // If we're in list mode, check if this line is a list item at the right depth
    if (listMode) {
      if (trimmed.startsWith('- ') && indent > listIndent) {
        const item = trimmed.slice(2).trim();
        listItems.push(item);
        continue;
      }
      // Not a list item — flush the list before processing this line
      flushList();
    }

    // Pop stack entries that are at a greater or equal indent
    while (stack.length > 0 && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }

    // Match: key: rest  (where rest may be empty, a value, or have inline comment)
    const kvMatch = line.match(/^(\s*)([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.*)/);
    if (!kvMatch) continue;

    const key = kvMatch[2];
    const rest = kvMatch[3];

    // Parse value and inline comment
    let value = rest.trim();
    let description = '';
    const inlineCommentMatch = rest.match(/^(.*?)\s{2,}#\s+(.*)$/) || rest.match(/^(.*?)\s+#\s+(.*)$/);
    if (inlineCommentMatch) {
      value = inlineCommentMatch[1].trim();
      description = inlineCommentMatch[2].trim();
    }

    const fullPath = [...stack.map((s) => s.key), key].join('.');

    if (value === '') {
      // This key has no inline value — it's either a container or a list parent.
      // Push to stack so child keys resolve the path correctly.
      stack.push({ key, indent });
      // Mark as potential list parent (next non-blank, non-comment line will tell us)
      listMode = true;
      listPath = fullPath;
      listItems = [];
      listIndent = indent;
    } else {
      // Leaf key with a scalar value
      rows.push({ path: fullPath, value, description });
    }
  }

  // Flush any trailing list
  flushList();

  const header = `| Key Path | Value | Description |
|----------|-------|-------------|`;
  const tableRows = rows.map(
    (r) => `| \`${r.path}\` | \`${r.value}\` | ${r.description} |`
  );
  const table = [header, ...tableRows].join('\n');

  const fm = serializeFrontmatter({
    title: 'Settings Keys',
    description: 'All .aid/settings.yml keys — path, default/current value, and description.',
    generatedFrom: '.aid/settings.yml',
  });

  const note = `\n<!-- generated — do not edit; source: .aid/settings.yml -->\n\n`;
  return fm + note + table + '\n';
}

// ── Main ──────────────────────────────────────────────────────────────────────

function main() {
  console.log('[gen-reference] Starting reference generation...');

  mkdirSync(CONTENT_DOCS_REF, { recursive: true });

  const pages = [
    { file: 'skills.md', generator: generateSkillsPage, src: 'canonical/skills/*/SKILL.md' },
    { file: 'agents.md', generator: generateAgentsPage, src: 'canonical/agents/*/AGENT.md' },
    { file: 'kb.md', generator: generateKbPage, src: 'canonical/templates/knowledge-base/*.md' },
    { file: 'settings.md', generator: generateSettingsPage, src: '.aid/settings.yml' },
  ];

  const generatedPaths = [];

  for (const page of pages) {
    const content = page.generator();
    const destPath = join(CONTENT_DOCS_REF, page.file);
    writeFileSync(destPath, content, 'utf8');
    console.log(`[gen-reference] Wrote: reference/${page.file}`);
    generatedPaths.push(`site/src/content/docs/reference/${page.file}`);
  }

  // Emit the manifest JSON (outside the collection root)
  const manifest = {
    generator: 'site/scripts/gen-reference.mjs',
    entries: pages.map((p) => ({
      src: p.src,
      dest: `site/src/content/docs/reference/${p.file}`,
    })),
    generatedPaths,
  };

  writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log('[gen-reference] Wrote: scripts/.reference-manifest.json');
  console.log('[gen-reference] Done.');
}

main();
