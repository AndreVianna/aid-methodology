// render-index.mjs — Assembles site/src/content/docs/skills/index.md.
//
// Pure exported function; no import-time side effect.

import { skillSummary } from './summary.mjs';
import { renderFrontmatterValue } from './render-value.mjs';

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

/**
 * The three skills reference/skills.md groups differently.
 * This is a curatorial statement tied to FR-5 \u2014 not derived from
 * gen-reference.mjs\u2019s frozen SKILL_GROUPS.
 */
const DIVERGENT_SKILLS = ['aid-triage', 'aid-deploy', 'aid-monitor'];

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

  // ── 4. Divergence note ─────────────────────────────────────────────────────
  // Sits immediately below the intro and above the first ## heading,
  // so it is visible to a reader but does not appear in the table of contents.
  // The three skill names are a curatorial statement tied to FR-5 \u2014
  // not derived, because deriving them would mean importing the frozen
  // generator\u2019s SKILL_GROUPS (gen-reference.mjs:707 calls main() at module scope).
  const d = DIVERGENT_SKILLS;
  const divergenceNote =
    `> **Note:** [Reference \u2192 Skills](/reference/skills/) is a terse family ` +
    `**summary**, generated separately. It groups \`${d[0]}\`, \`${d[1]}\`, and ` +
    `\`${d[2]}\` under *Definition*, while this page files them per FR-5\u2019s ` +
    `Placement rules. Where the two pages disagree about grouping, ` +
    `**this page is authoritative**. The difference exists because the older ` +
    `generator is frozen, not because either page is stale-by-accident.`;

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
    '\n' + divergenceNote + '\n' +
    '\n' + groupLines.join('\n') + '\n'
  );
}
