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
const KB_DIR = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'knowledge-base');
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

// GitHub blob base for "Source" links.
const BLOB = 'https://github.com/AndreVianna/aid-methodology/blob/master';

// Per-skill group + pipeline phase (grounded in docs/aid-methodology.md §1 Skill
// Inventory + §4 The Phases). Order within each group is execution order.
const SKILL_GROUPS = [
  {
    group: 'Prepare',
    blurb: 'Set up the workspace and understand the system.',
    skills: [
      { name: 'aid-config', phase: 'bootstrap · run once' },
      { name: 'aid-discover', phase: 'Phase 1 · brownfield' },
      { name: 'aid-summarize', phase: 'optional viewer' },
    ],
  },
  {
    group: 'Define',
    blurb: 'Define the problem and how to solve it.',
    skills: [
      { name: 'aid-describe', phase: 'Phase 2a · TRIAGE → full or lite' },
      { name: 'aid-define', phase: 'Phase 2b · full path only · decompose features' },
      { name: 'aid-specify', phase: 'Phase 3 · full path only' },
    ],
  },
  {
    group: 'Map',
    blurb: 'Turn requirements into an executable task list.',
    skills: [
      { name: 'aid-plan', phase: 'Phase 4 · full path only' },
      { name: 'aid-detail', phase: 'Phase 5 · full path only' },
    ],
  },
  {
    group: 'Execute',
    blurb: 'Build, review, and test.',
    skills: [{ name: 'aid-execute', phase: 'Phase 6 · 8 task types · graded loop' }],
  },
  {
    group: 'Deliver (optional)',
    blurb: 'Optionally ship, monitor, and route what breaks back into the pipeline.',
    skills: [
      { name: 'aid-deploy', phase: 'optional · on demand' },
      { name: 'aid-monitor', phase: 'optional · on demand' },
    ],
  },
  {
    group: 'Off-pipeline',
    blurb: 'On-demand skills, outside the numbered phases.',
    skills: [
      { name: 'aid-housekeep', phase: 'on demand' },
      { name: 'aid-query-kb', phase: 'on demand · read-only Q&A' },
      { name: 'aid-update-kb', phase: 'on demand · targeted KB update' },
    ],
  },
];

function readSkillDescription(name) {
  const content = readFileSync(join(SKILLS_DIR, name, 'SKILL.md'), 'utf8');
  return parseFrontmatter(content).description || '';
}

// ── Skills page generator (grouped per-skill sections) ──────────────────────────

function generateSkillsPage() {
  // Confirm the canonical directory count matches the curated grouping (drift guard).
  const onDisk = readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
  const grouped = SKILL_GROUPS.flatMap((g) => g.skills.map((s) => s.name)).sort();
  if (onDisk.join(',') !== grouped.join(',')) {
    throw new Error(
      `[gen-reference] skills drift: canonical=${onDisk.join(',')} vs grouped=${grouped.join(',')}`
    );
  }

  const intro =
    'AID ships **14 user-facing skills** across five pipeline groups, plus three off-pipeline ' +
    'on-demand skills. The six numbered phases — Discover through Execute — form the mandatory ' +
    'sequential pipeline; every skill runs as a slash command (e.g. `/aid-config`) inside your AI ' +
    'host tool. Each entry below is generated from the skill\'s own definition in `canonical/skills/`.';

  const sections = SKILL_GROUPS.map((g) => {
    const items = g.skills
      .map((s) => {
        const desc = readSkillDescription(s.name);
        const src = `canonical/skills/${s.name}/SKILL.md`;
        return (
          `### \`${s.name}\`\n\n` +
          `**${s.phase}**\n\n` +
          `${desc}\n\n` +
          `[Definition: \`${src}\`](${BLOB}/${src})\n`
        );
      })
      .join('\n');
    return `## ${g.group}\n\n${g.blurb}\n\n${items}`;
  }).join('\n');

  const fm = serializeFrontmatter({
    title: 'Skills',
    description: 'All 14 AID pipeline skills — grouped by pipeline phase, with what each does and where its definition lives.',
    generatedFrom: 'canonical/skills/*/SKILL.md',
  });
  const note = `\n<!-- generated — do not edit; source: canonical/skills/*/SKILL.md -->\n\n`;
  return fm + note + intro + '\n\n' + sections;
}

// ── Agents page generator (grouped per-tier sections) ───────────────────────────

const TIER_ORDER = ['large', 'medium', 'small'];
const TIER_BLURB = {
  large: 'Highest-stakes work — requirements, architecture, brownfield discovery, and adversarial review.',
  medium: 'The production workhorses — implementation, delivery, coordination, and documentation.',
  small: 'Deterministic, mechanical operations — extract, format, enumerate.',
};

function generateAgentsPage() {
  const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();

  const agents = agentDirs.map((dir) => {
    const fm = parseFrontmatter(readFileSync(join(AGENTS_DIR, dir, 'AGENT.md'), 'utf8'));
    return {
      name: fm.name || dir,
      description: fm.description || '',
      tier: (fm.tier || '').toLowerCase(),
      tools: fm.tools || '',
      srcPath: `canonical/agents/${dir}/AGENT.md`,
    };
  });

  const intro =
    'AID runs **9 specialized agents** across three model tiers. The separation is structural: ' +
    'the reviewer\'s tier is always **≥** the executor\'s, and the agent that writes code never ' +
    'grades its own work. Each profile maps these tiers to concrete models (see ' +
    '[the Agent Model](/concepts/methodology/#5-the-agent-model)). Generated from `canonical/agents/`.';

  const sections = TIER_ORDER.map((tier) => {
    const inTier = agents.filter((a) => a.tier === tier);
    if (inTier.length === 0) return '';
    const items = inTier
      .map(
        (a) =>
          `### \`${a.name}\`\n\n` +
          `**Tools:** ${a.tools}\n\n` +
          `${a.description}\n\n` +
          `[Definition: \`${a.srcPath}\`](${BLOB}/${a.srcPath})\n`
      )
      .join('\n');
    const label = tier.charAt(0).toUpperCase() + tier.slice(1);
    return `## ${label} tier\n\n${TIER_BLURB[tier]}\n\n${items}`;
  })
    .filter(Boolean)
    .join('\n');

  const fm = serializeFrontmatter({
    title: 'Agents',
    description: 'All 9 AID pipeline agents — grouped by model tier, with role, tools, and source definition.',
    generatedFrom: 'canonical/agents/*/AGENT.md',
  });
  const note = `\n<!-- generated — do not edit; source: canonical/agents/*/AGENT.md -->\n\n`;
  return fm + note + intro + '\n\n' + sections;
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
    const srcPath = `canonical/aid/templates/knowledge-base/${file}`;
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
    generatedFrom: 'canonical/aid/templates/knowledge-base/*.md',
  });

  const intro =
    'The Knowledge Base is the gravitational center of AID — every phase reads it, any phase can ' +
    'revise it. `aid-discover` populates these **14 standard documents** under `.aid/knowledge/` ' +
    '(plus three meta-documents: `INDEX.md`, `README.md`, and `STATE.md`). The set is the default ' +
    'seed and is configurable per project via `discovery.doc_set` in `.aid/settings.yml`. Each row ' +
    'links to the template the document is generated from.';

  const note = `\n<!-- generated — do not edit; source: canonical/aid/templates/knowledge-base/*.md -->\n\n`;
  return fm + note + intro + '\n\n' + table + '\n';
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

  const intro =
    '`.aid/settings.yml` is the single source of truth for AID pipeline configuration — quality ' +
    'bar, parallelism, project identity, and more. Manage it with the `/aid-config` skill: a bare ' +
    '`/aid-config` prints every value; `/aid-config <dotted.key>` views and updates one key ' +
    'interactively. The keys below reflect this project\'s current `settings.yml`. Every skill with ' +
    'a review state reads `review.minimum_grade` and only exits when its grade clears that floor ' +
    '(per-skill overrides are allowed).';

  const note = `\n<!-- generated — do not edit; source: .aid/settings.yml -->\n\n`;
  return fm + note + intro + '\n\n' + table + '\n';
}

// ── Main ──────────────────────────────────────────────────────────────────────

function main() {
  console.log('[gen-reference] Starting reference generation...');

  mkdirSync(CONTENT_DOCS_REF, { recursive: true });

  const pages = [
    { file: 'skills.md', generator: generateSkillsPage, src: 'canonical/skills/*/SKILL.md' },
    { file: 'agents.md', generator: generateAgentsPage, src: 'canonical/agents/*/AGENT.md' },
    { file: 'kb.md', generator: generateKbPage, src: 'canonical/aid/templates/knowledge-base/*.md' },
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
