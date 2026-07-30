// render-index.mjs — Assembles site/src/content/docs/skills/index.md.
//
// Pure exported function; no import-time side effect.

import { skillSummary } from './summary.mjs';
import { renderFrontmatterValue } from './render-value.mjs';
import { SKILL_GROUPS } from './curated-roster.mjs';

// ── Constants ─────────────────────────────────────────────────────────────────

/**
 * Two-source generatedFrom string — byte-identical to the string
 * gen-reference.mjs already writes for its own two-input page, including
 * source order.  One string, three places (marker, frontmatter, manifest),
 * no third spelling to drift.
 */
const GENERATED_FROM =
  'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml';

/**
 * Fixed page description (verbatim from the SPEC § Page structure).
 * Contains em-dashes (U+2014), not hyphens.
 */
const PAGE_DESCRIPTION =
  'Every AID skill, one card each, grouped by skill group and \u2014' +
  ' inside Definition \u2014 by verb family.';

// ── Frontmatter serializer ─────────────────────────────────────────────────────
//
// Mirrors the single-quoted style used by render-page.mjs, sync-docs.mjs, and
// gen-reference.mjs:72-80.  That serializer emits flat scalar pairs only, so
// the nested sidebar: key is appended here as a literal two-line block after
// the scalar pairs rather than passed through it.

/**
 * Serialize an object\u2019s string fields to a YAML frontmatter block,
 * single-quoted style, with sidebar: hidden: true appended.
 *
 * @param {Record<string, string>} fm  Key-value pairs, emitted in insertion order.
 * @returns {string}  Opening ---, fields, sidebar block, closing ---, trailing newline.
 */
function serializeFrontmatter(fm) {
  const lines = ['---'];
  for (const [key, val] of Object.entries(fm)) {
    const escaped = val.replace(/'/g, "''");
    lines.push(`${key}: '${escaped}'`);
  }
  // Nested sidebar key appended as a literal two-line block \u2014 the flat
  // serializer cannot represent nested YAML, so this must be appended manually.
  lines.push('sidebar:');
  lines.push('  hidden: true');
  lines.push('---');
  return lines.join('\n') + '\n';
}

// ── Card renderer ─────────────────────────────────────────────────────────────

/**
 * Render one SkillCard as a markdown list item:
 *   - [`name`](<route>) \u2014 <escaped-intent>
 *
 * Intent is escaped by the same code-span-aware rule as the detail header
 * (renderFrontmatterValue over a synthetic scalar field) \u2014 never re-implemented.
 *
 * @param {{ name: string, route: string, intent: string }} card
 * @returns {string}
 */
function renderCard(card) {
  // card.intent comes from skillSummary (via groups.mjs\u2019s toCard).
  // Apply the code-span-aware escaping rule by wrapping in a synthetic scalar
  // field \u2014 the same technique the detail header uses for frontmatter values.
  const escapedIntent = renderFrontmatterValue({
    key: 'description',
    kind: 'scalar',
    value: card.intent,
    line: 0,
  });
  return `- [\`${card.name}\`](${card.route}) \u2014 ${escapedIntent}`;
}

// ── Index renderer ─────────────────────────────────────────────────────────────

/**
 * Assembles the complete content of site/src/content/docs/skills/index.md.
 *
 * Page structure (in order):
 *   1. Frontmatter  (title, description, generatedFrom, sidebar: hidden: true)
 *   2. Generated marker  (byte-identical to the existing generated pages\u2019 sentence)
 *   3. Intro paragraph   (counts interpolated from records.length and sections)
 *   4. Divergence note   (above the first ## heading \u2014 not a TOC entry)
 *   5. Group sections    (H2 per group; H3 per verb family inside Definition)
 *
 * No count literal appears in this module or in any string it builds.  Every
 * count that reaches the page is interpolated from records.length or the
 * catalog-derived sections (REQUIREMENTS \u00a78, KI-005).
 *
 * @param {Array<{ dirName: string, route: string, field: (k: string) => { value: string } | undefined }>} records
 *   Every on-disk SkillRecord, as produced by discoverSkills().
 * @param {import('./groups.mjs').GroupSection[]} sections
 *   Fully-assigned group tree, as produced by assignGroups().
 * @returns {string}  Complete page content, LF line endings, trailing newline.
 */
/**
 * Which skills the two groupings disagree about.
 *
 * EXPORTED so the AC-7 test can assert against this function rather than re-implementing
 * the same walk. It was re-implemented inline first, against this file's own rule that
 * consumers "never reimplement their rules inline" -- and with nothing asserting the two
 * copies agreed, a traversal bug would simply have been reproduced in both. That is the
 * defect the two-curated-rosters row records, one directory over.
 *
 * @param {import('./groups.mjs').GroupSection[]} sections
 * @returns {Array<{name: string, here: string, there: string}>} sorted by name
 */
export function findGroupingDivergence(sections) {
  const rosterGroupOf = new Map();
  for (const g of SKILL_GROUPS) {
    for (const sk of g.skills) rosterGroupOf.set(sk.name, g.group);
  }
  const divergent = [];
  for (const section of sections) {
    // Both the group's own cards AND its verb-family cards. `aid-deploy` and `aid-monitor`
    // live under `### deploy` / `### monitor` families rather than in `section.cards`, so
    // walking cards alone would silently never compare them.
    for (const card of [...section.cards, ...section.families.flatMap((f) => f.cards)]) {
      const rosterGroup = rosterGroupOf.get(card.name);
      if (rosterGroup && rosterGroup !== section.group) {
        divergent.push({ name: card.name, here: section.group, there: rosterGroup });
      }
    }
  }
  return divergent.sort((x, y) => x.name.localeCompare(y.name));
}

export function renderSkillIndex(records, sections) {
  // ── 1. Frontmatter ─────────────────────────────────────────────────────────
  const fm = serializeFrontmatter({
    title: 'All Skills',
    description: PAGE_DESCRIPTION,
    generatedFrom: GENERATED_FROM,
  });

  // ── 2. Generated marker ─────────────────────────────────────────────────────
  // \u2014 = em-dash (U+2014), byte-identical to the existing generated pages.
  const marker =
    `<!-- generated \u2014 do not edit; source: ${GENERATED_FROM} -->`;

  // ── 3. Intro paragraph ─────────────────────────────────────────────────────
  // All counts are interpolated from the live data \u2014 no literals.
  const skillCount = records.length;
  const familyCount = sections.reduce((n, s) => n + s.families.length, 0);
  const intro =
    `AID ships **${skillCount} skill directories** across four skill groups ` +
    `(Support, Knowledge Base Maintenance, Definition, Execution), ` +
    `with the Definition group subdivided into **${familyCount} verb ` +
    `${familyCount === 1 ? 'family' : 'families'}** derived from the shortcut catalog. ` +
    `Each card below links to that skill\u2019s detail page.`;

  // ── 4. Grouping-divergence + cross-reference note ──────────────────────
  // Sits immediately below the intro and above the first ## heading, so it is
  // visible to a reader but does not appear in the table of contents.
  //
  // HISTORY, because this note has now been wrong twice in opposite directions.
  // Originally it hard-coded three skill names as grouped differently by
  // /reference/skills/, and explained the difference as "because the older generator
  // is frozen". delivery-006 task-057 hollowed that page out and replaced the whole
  // note with a plain cross-reference, on the reasoning that a hollowed page has no
  // roster left to diverge from. That reasoning was WRONG: the competing grouping was
  // never the reference PAGE, it is the curated roster itself -- which still exists,
  // still groups `aid-triage` under Definition, and is still what docs/aid-methodology.md
  // publishes in its inventory table, while this page files it under Support per FR-5.
  // Deleting the disclosure removed a true statement a reader needs.
  //
  // So it is DERIVED now, not curated. task-054 extracted SKILL_GROUPS into
  // curated-roster.mjs precisely so it could be read without importing a generator that
  // calls main() at module scope -- which is what made the old hard-coded list necessary.
  // Whatever the two groupings actually disagree about is what the note names, and if
  // they stop disagreeing the note disappears on its own.
  const divergent = findGroupingDivergence(sections);

  const crossRefNote = divergent.length === 0
    ? `> **Note:** This page is the roster. How the verb-first shortcut skills actually ` +
      `work — the shared shortcut engine they delegate to, and its ` +
      `INTAKE → APPROVAL-HALT sequence — is documented at ` +
      `[Reference → Shortcut engine](/reference/skills/).`
    : `> **Note:** This page is the roster, and it files skills per FR-5’s Placement ` +
      `rules. ${divergent.map((d) => `\`${d.name}\` is **${d.here}** here and ` +
      `**${d.there}** in the curated roster that ` +
      `[the methodology's skill inventory](/concepts/methodology/) ` +
      `publishes`).join('; ')}. Where they disagree about grouping, **this page is ` +
      `authoritative**. How the shortcut skills themselves work — the shared engine ` +
      `and its INTAKE → APPROVAL-HALT sequence — is at ` +
      `[Reference → Shortcut engine](/reference/skills/).`;

  // ── 5. Group and family sections ───────────────────────────────────────────
  const groupLines = [];

  for (const section of sections) {
    // H2 group heading
    groupLines.push(`## ${section.group}`);
    groupLines.push('');
    // Group blurb
    groupLines.push(section.blurb);
    groupLines.push('');

    if (section.families.length > 0) {
      // Definition group: full-path block first (bold lead-in, no heading,
      // so it does not enter the TOC), then verb-family subsections (H3).
      // section.cards holds the five full-path SkillCards (groups.mjs merges
      // fullPathCards + groupCards; Definition\u2019s members array is empty so
      // cards == fullPathCards).
      groupLines.push('**The full path** \u2014 the five phases, in order:');
      groupLines.push('');
      for (const card of section.cards) {
        groupLines.push(renderCard(card));
      }
      groupLines.push('');

      for (const family of section.families) {
        // H3 family heading \u2014 bare code span only.
        // The heading text is the raw verb, so the heading IS the catalog key.
        // Nothing else in this heading (no blurb, no count, no annotation)
        // so the family regex matches exactly and nothing extraneous matches it.
        groupLines.push(`### \`${family.verb}\``);
        groupLines.push('');
        for (const card of family.cards) {
          groupLines.push(renderCard(card));
        }
        groupLines.push('');
      }
    } else {
      // Non-Definition groups: flat card list, no sub-headings.
      for (const card of section.cards) {
        groupLines.push(renderCard(card));
      }
      groupLines.push('');
    }
  }

  // Trim the trailing blank line that the last group\u2019s loop appended.
  while (groupLines.length > 0 && groupLines[groupLines.length - 1] === '') {
    groupLines.pop();
  }

  // ── Assemble ─────────────────────────────────────────────────────────────
  // fm already ends with '\n' (the closing ---\n).
  // Each subsequent block is separated by a blank line.
  return (
    fm +
    '\n' + marker + '\n' +
    '\n' + intro + '\n' +
    '\n' + crossRefNote + '\n' +
    '\n' + groupLines.join('\n') + '\n'
  );
}
