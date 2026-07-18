#!/usr/bin/env node
// gen-reference.mjs — Manifest-driven reference generator (feature-006).
//
// Generates four reference pages from canonical/ + .aid/settings.yml:
//   reference/skills.md    — 94 skill directories (16 classic + aid-triage + aid-ask +
//                            76 catalog-driven shortcuts), grouped + summarized
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
const SHORTCUT_CATALOG_FILE = join(REPO_ROOT, 'canonical', 'aid', 'templates', 'shortcut-catalog.yml');
const SHORTCUT_ENGINE_FILE = 'canonical/aid/templates/shortcut-engine.md';
const SHORTCUT_CATALOG_SRC = 'canonical/aid/templates/shortcut-catalog.yml';

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

// ── Shortcut catalog parser (minimal line-based YAML — no deps) ──────────────
//
// Mirrors the settings.yml line-by-line style below: `shortcuts:` holds a flat
// list of maps, one row per `  - name: <value>` opener followed by `    key:
// value` fields at the next indent level. Good enough for this catalog's fixed
// shape (see the field contract in shortcut-catalog.yml's header comment);
// not a general YAML parser.

function parseShortcutCatalog(text) {
  const lines = text.split('\n');
  const rows = [];
  let current = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const rowStart = line.match(/^  - name:\s*(.+)$/);
    if (rowStart) {
      if (current) rows.push(current);
      current = { name: stripYamlScalar(rowStart[1]) };
      continue;
    }

    if (!current) continue; // before the `shortcuts:` list (version:, header comments, ...)

    const field = line.match(/^    ([a-zA-Z_]+):\s*(.*)$/);
    if (field) {
      current[field[1]] = stripYamlScalar(field[2]);
    }
  }
  if (current) rows.push(current);
  return rows;
}

function stripYamlScalar(raw) {
  let val = raw.trim();
  const commentIdx = val.indexOf(' #');
  if (commentIdx !== -1) val = val.slice(0, commentIdx).trim();
  return val.replace(/^['"]|['"]$/g, '');
}

// Rows that emit a `canonical/skills/<name>/SKILL.md` directory: every row
// EXCEPT `repurpose: true` ones (those re-register a pre-existing hand-authored
// skill — `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask` — for
// /aid-triage's benefit; the maintainer build helper skips generating a
// directory for them).
function emittingShortcutRows(rows) {
  return rows.filter((r) => r.repurpose !== 'true');
}

function loadShortcutCatalog() {
  const raw = readFileSync(SHORTCUT_CATALOG_FILE, 'utf8');
  const rows = parseShortcutCatalog(raw);
  return { rows, emitting: emittingShortcutRows(rows) };
}

// Per-skill group + pipeline phase (grounded in docs/aid-methodology.md §1 Skill
// Inventory + §4 The Phases). Groups are the four non-sequential AID skill
// groups — Support, Knowledge Base Maintenance, Definition, Execution — always
// presented in that order; they are NOT the numbered pipeline phases (shown per
// skill via `phase`). Order within each group is execution order. These are the
// 16 classic skills — the shortcut skills are summarized separately, data-driven
// from the shortcut catalog (see generateShortcutFamiliesSection), and rendered
// nested inside the Definition group (see `shortcutsAfter` below).
const SKILL_GROUPS = [
  {
    group: 'Support',
    blurb: 'Set up the workspace and manage connectors.',
    skills: [
      { name: 'aid-config', phase: 'bootstrap · run once' },
      { name: 'aid-set-connector', phase: 'on demand · upsert a connector into the catalog' },
      { name: 'aid-unset-connector', phase: 'on demand · remove a connector from the catalog' },
    ],
  },
  {
    group: 'Knowledge Base Maintenance',
    blurb: "Build and keep current the team's understanding of the existing system.",
    skills: [
      { name: 'aid-discover', phase: 'Phase 1 · brownfield' },
      { name: 'aid-summarize', phase: 'optional viewer' },
      { name: 'aid-housekeep', phase: 'on demand' },
      { name: 'aid-update-kb', phase: 'on demand · targeted KB update' },
      { name: 'aid-query-kb', phase: 'on demand · read-only Q&A' },
      { name: 'aid-ask', phase: 'on demand · friendly alias of aid-query-kb' },
    ],
  },
  {
    group: 'Definition',
    blurb: 'Route, gather requirements, decide how to solve it, sequence the roadmap, and break it into tasks — the full path, or a shortcut.',
    skills: [
      { name: 'aid-triage', phase: 'router · suggest-only' },
      { name: 'aid-describe', phase: 'Phase 2a · full path only' },
      { name: 'aid-define', phase: 'Phase 2b · full path only · decompose features' },
      { name: 'aid-specify', phase: 'Phase 3 · full path only' },
      { name: 'aid-plan', phase: 'Phase 4 · full path only' },
      { name: 'aid-detail', phase: 'Phase 5 · full path only' },
      { name: 'aid-deploy', phase: 'optional shortcut path · on demand' },
      { name: 'aid-monitor', phase: 'optional shortcut path · on demand' },
    ],
    // The 64 direct-entry shortcuts (and the shared shortcut engine they delegate
    // to) are also Definition-group members — render the family summary nested
    // here, right after the full-path skills and before the Deploy/Monitor
    // shortcut paths.
    shortcutsAfter: 'aid-detail',
  },
  {
    group: 'Execution',
    blurb: 'Build, review, and test.',
    skills: [{ name: 'aid-execute', phase: 'Phase 6 · 8 task types · graded loop' }],
  },
];

function readSkillDescription(name) {
  const content = readFileSync(join(SKILLS_DIR, name, 'SKILL.md'), 'utf8');
  return parseFrontmatter(content).description || '';
}

// ── Direct-entry shortcuts section (data-driven from the catalog) ────────────
//
// The fact-sheet families reproduce cleanly by grouping the catalog's emitting
// rows by `verb` (create/change further split by `alias_of` into canonical vs
// alias forms). This is the ONLY place shortcut names are summarized on the
// page — individually they'd be 67 near-identical H3 blocks of pure noise.
const SHORTCUT_FAMILIES = [
  {
    label: 'Create (+ `add` alias)',
    match: (r) => r.verb === 'create',
    detail: (rows) => {
      const canonical = rows.filter((r) => r.alias_of === 'null');
      const aliases = rows.filter((r) => r.alias_of !== 'null');
      return `${canonical.length} canonical \`aid-create*\` forms + ${aliases.length} \`aid-add*\` aliases`;
    },
  },
  {
    label: 'Change (+ `update` alias)',
    match: (r) => r.verb === 'change',
    detail: (rows) => {
      const canonical = rows.filter((r) => r.alias_of === 'null');
      const aliases = rows.filter((r) => r.alias_of !== 'null');
      return `${canonical.length} canonical \`aid-change*\` forms + ${aliases.length} \`aid-update*\` aliases`;
    },
  },
  {
    label: 'Fix',
    match: (r) => r.verb === 'fix',
    detail: () => '`aid-fix` — diagnose and correct a defect, regression, incident, or vulnerability; no alias',
  },
  {
    label: 'Refactor',
    match: (r) => r.verb === 'refactor',
    detail: () => '`aid-refactor` — restructure or optimize without changing behavior; no alias',
  },
  {
    label: 'Test + Experiment',
    match: (r) => r.verb === 'test' || r.verb === 'experiment',
    detail: (rows) =>
      `\`aid-test\` + 3 typed forms (security, performance, data-quality) = ${rows.filter((r) => r.verb === 'test').length}, plus \`aid-experiment\`; no alias`,
  },
  {
    label: 'Prototype',
    match: (r) => r.verb === 'prototype',
    detail: () => '`aid-prototype`, `aid-prototype-ui`; no alias',
  },
  {
    label: 'Document',
    match: (r) => r.verb === 'document',
    detail: (rows) => `\`aid-document\` + ${rows.length - 1} typed forms (decision, architecture, guideline, standard, runbook, tutorial, changelog); no alias`,
  },
  {
    label: 'Report',
    match: (r) => r.verb === 'report',
    detail: () => '`aid-report` — analyze data or usage and communicate insight; no alias',
  },
  {
    label: 'Show dashboard',
    match: (r) => r.verb === 'show-dashboard',
    detail: () => '`aid-show-dashboard` — build a durable dashboard or BI view; no alias',
  },
  {
    label: 'Remove (+ `delete` alias)',
    match: (r) => r.verb === 'remove',
    detail: (rows) => {
      const canonical = rows.filter((r) => r.alias_of === 'null');
      const aliases = rows.filter((r) => r.alias_of !== 'null');
      return `${canonical.length} canonical \`aid-remove\` form + ${aliases.length} \`aid-delete\` alias`;
    },
  },
  {
    label: 'Deprecate',
    match: (r) => r.verb === 'deprecate',
    detail: () => '`aid-deprecate` — mark an artifact/API deprecated, add warnings and a migration path, without deleting yet; no alias',
  },
  {
    label: 'Migrate',
    match: (r) => r.verb === 'migrate',
    detail: () => '`aid-migrate` — migrate data, a dependency, framework, or platform, with a rollback plan; no alias',
  },
  {
    label: 'Review (+ `audit` alias)',
    match: (r) => r.verb === 'review',
    detail: (rows) => {
      const canonical = rows.filter((r) => r.alias_of === 'null');
      const aliases = rows.filter((r) => r.alias_of !== 'null');
      return `${canonical.length} canonical \`aid-review\` form + ${aliases.length} \`aid-audit\` alias`;
    },
  },
  {
    label: 'Research (+ `investigate`/`spike` aliases)',
    match: (r) => r.verb === 'research',
    detail: (rows) => {
      const canonical = rows.filter((r) => r.alias_of === 'null');
      const aliases = rows.filter((r) => r.alias_of !== 'null');
      return `${canonical.length} canonical \`aid-research\` form + ${aliases.length} \`aid-investigate\`/\`aid-spike\` aliases`;
    },
  },
];

function generateShortcutFamiliesSection(catalog, headingLevel = 2) {
  const { rows, emitting } = catalog;
  const heading = '#'.repeat(headingLevel);

  const familyRows = SHORTCUT_FAMILIES.map((f) => {
    const matched = emitting.filter(f.match);
    return { label: f.label, count: matched.length, detail: f.detail(matched) };
  });

  // Every emitting row must land in exactly one family — if the catalog grows
  // a new verb, this throws instead of silently under-reporting the count.
  const accountedFor = familyRows.reduce((sum, f) => sum + f.count, 0);
  if (accountedFor !== emitting.length) {
    throw new Error(
      `[gen-reference] shortcut family drift: families account for ${accountedFor} of ` +
        `${emitting.length} catalog rows that emit a skill directory — a verb is unmapped`
    );
  }

  const header = `| Family | Count | Forms |
|--------|-------|-------|`;
  const tableRows = familyRows.map((f) => `| ${f.label} | ${f.count} | ${f.detail} |`);
  const table = [header, ...tableRows, `| **Total** | **${accountedFor}** | |`].join('\n');

  const repurposedRows = rows.filter((r) => r.repurpose === 'true');
  const repurposed = repurposedRows.length;
  const repurposedNames = repurposedRows.map((r) => `\`${r.name}\``).join(' / ');

  return (
    `${heading} Direct-entry shortcuts\n\n` +
    `**${emitting.length} engine-driven verb-first shortcut skills** — a fast, mostly-autonomous ` +
    `alternative to the full Describe→Detail path for a single, well-scoped change. Each is a thin doorway ` +
    `generated from one non-\`repurpose\` row of [\`${SHORTCUT_CATALOG_SRC}\`](${BLOB}/${SHORTCUT_CATALOG_SRC}) ` +
    `(${rows.length} rows total; the other ${repurposed} are \`repurpose: true\` — the 4 classic re-registered ` +
    `skills (\`aid-deploy\`/\`aid-monitor\`/\`aid-query-kb\`/\`aid-ask\`) plus the work-005 hand-authored ` +
    `single-shot "collapse" skills, all hand-authored with their own directory).\n\n` +
    `Every engine-driven shortcut delegates to the shared **shortcut engine** — ` +
    `[\`${SHORTCUT_ENGINE_FILE}\`](${BLOB}/${SHORTCUT_ENGINE_FILE}) — which collapses the five definition ` +
    `phases (Describe → Detail) into one mostly-autonomous run:\n\n` +
    '```\nINTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT\n```\n\n' +
    `CAPTURE/SPEC/PLAN/DETAIL run without a per-phase human checkpoint (unlike the full path's ` +
    `Propose→Discuss→Write→Review loops); the only interactive moments are a rare CAPTURE gap-question ` +
    `and the terminal APPROVAL-HALT. GATE grades every generated document mechanically against the ` +
    `project's minimum grade before halting. The engine never executes — \`/aid-execute\` is a separate, ` +
    `user-initiated run after approval. Not sure which shortcut fits your change? \`/aid-triage\` reads ` +
    `this same catalog and suggests exactly one.\n\n` +
    `${table}\n`
  );
}

// ── Skills page generator (grouped per-skill sections + shortcut summary) ────

function generateSkillsPage() {
  const catalog = loadShortcutCatalog();
  const shortcutNames = catalog.emitting.map((r) => r.name);

  // Expected skill-directory set = the curated classic skills (which already
  // include `aid-triage` in the Definition group + the 4 classic repurpose
  // skills deploy/monitor/query-kb/ask) ∪ EVERY catalog row name. work-005
  // turned many `repurpose` rows into hand-authored single-shot "collapse"
  // skills that DO have their own directory (unlike the 4 classic repurpose
  // rows curated above), so the guard now expects every catalog row's
  // directory — not just the engine-driven (non-`repurpose`) emitting ones.
  // Compare against on-disk `canonical/skills/`.
  const curatedNames = SKILL_GROUPS.flatMap((g) => g.skills.map((s) => s.name));
  const allCatalogNames = catalog.rows.map((r) => r.name);
  const expected = [...new Set([...curatedNames, ...allCatalogNames])].sort();
  const onDisk = readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
  if (onDisk.join(',') !== expected.join(',')) {
    throw new Error(
      `[gen-reference] skills drift: canonical=${onDisk.join(',')} vs expected=${expected.join(',')}`
    );
  }

  const canonicalCatalogNames = catalog.rows.filter((r) => r.alias_of === 'null').length;
  const aliasCatalogNames = catalog.rows.filter((r) => r.alias_of !== 'null').length;
  const repurposedRowsForIntro = catalog.rows.filter((r) => r.repurpose === 'true');
  const repurposedCanonicalForIntro = repurposedRowsForIntro.filter((r) => r.alias_of === 'null').length;
  const repurposedAliasForIntro = repurposedRowsForIntro.filter((r) => r.alias_of !== 'null').length;
  // aid-ask is an ALIAS of the classic aid-query-kb (a repurpose row), not a distinct
  // capability — it renders in the Knowledge Base Maintenance group but is NOT counted
  // among the classic skills (matching the README/methodology "16 classic + /aid-triage +
  // /aid-ask" framing). aid-triage (the suggest-only router) is likewise counted separately.
  const classicSkillCount = SKILL_GROUPS.reduce(
    (sum, g) => sum + g.skills.filter((s) => s.name !== 'aid-ask' && s.name !== 'aid-triage').length,
    0
  );

  const intro =
    `AID ships **${onDisk.length} skill directories** under \`canonical/skills/\`: **${classicSkillCount} classic ` +
    'pipeline skills** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), the ' +
    `suggest-only router **\`/aid-triage\`**, the friendly **\`/aid-ask\`** Q&A alias (of \`/aid-query-kb\`), and **${shortcutNames.length} engine-driven direct-entry shortcut ` +
    `skills** generated from a ${catalog.rows.length}-row catalog (${canonicalCatalogNames} canonical ` +
    `names + ${aliasCatalogNames} aliases); ${repurposedRowsForIntro.length} of the rows (` +
    `${repurposedCanonicalForIntro} canonical + ${repurposedAliasForIntro} alias) are \`repurpose: true\` — the 4 classic ` +
    're-registered skills plus the work-005 hand-authored single-shot "collapse" skills, all hand-authored with their own directories). The six numbered phases — Discover through Execute — ' +
    'form the mandatory sequential full path; every skill runs as a slash command (e.g. `/aid-config`) ' +
    "inside your AI host tool. Classic and router skills below are generated from each skill's own " +
    'definition in `canonical/skills/`; shortcuts are summarized by family from the catalog (see ' +
    '"Direct-entry shortcuts" below, nested inside the Definition group).';

  // The 64 direct-entry shortcuts are rendered as an H3 family-summary table
  // nested inside the Definition group's H2 (see SKILL_GROUPS' `shortcutsAfter`)
  // rather than as their own top-level H2 — Groups are exactly four (Support,
  // Knowledge Base Maintenance, Definition, Execution).
  const shortcutsSectionH3 = generateShortcutFamiliesSection(catalog, 3);

  const sections = SKILL_GROUPS.map((g) => {
    const blocks = g.skills.map((s) => {
      const desc = readSkillDescription(s.name);
      const src = `canonical/skills/${s.name}/SKILL.md`;
      return {
        name: s.name,
        text:
          `### \`${s.name}\`\n\n` +
          `**${s.phase}**\n\n` +
          `${desc}\n\n` +
          `[Definition: \`${src}\`](${BLOB}/${src})\n`,
      };
    });
    let itemTexts = blocks.map((b) => b.text);
    if (g.shortcutsAfter) {
      const idx = blocks.findIndex((b) => b.name === g.shortcutsAfter);
      itemTexts = [
        ...itemTexts.slice(0, idx + 1),
        shortcutsSectionH3,
        ...itemTexts.slice(idx + 1),
      ];
    }
    return `## ${g.group}\n\n${g.blurb}\n\n${itemTexts.join('\n')}`;
  }).join('\n');

  const fm = serializeFrontmatter({
    title: 'Skills',
    description:
      `All AID skills — ${classicSkillCount} classic pipeline skills, the aid-triage router, the aid-ask Q&A alias, and the ` +
      'catalog-driven direct-entry shortcuts — grouped by skill group/family, with what each does and ' +
      'where it comes from.',
    generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml',
  });
  const note = `\n<!-- generated — do not edit; source: canonical/skills/*/SKILL.md -->\n\n`;
  return fm + note + intro + '\n\n' + sections + '\n';
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
