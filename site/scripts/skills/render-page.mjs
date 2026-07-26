// render-page.mjs — Assembles one skill detail page.
//
// Pure exported function; no import-time side effect.

import { skillSummary } from './summary.mjs';
import { renderFrontmatterValue } from './render-value.mjs';
import { skillSourcePath, skillGithubUrl } from './paths.mjs';
import { renderSkillBody } from './body.mjs';

// ── Frontmatter serializer ────────────────────────────────────────────────────
//
// Re-implemented here rather than imported from gen-reference.mjs: that module
// calls main() at module scope, so importing anything from it would run the
// reference generator as a side effect. This is accepted duplication, recorded
// in the SPEC's Migration Plan.
//
// Serializes in the single-quoted style used by gen-reference.mjs and
// sync-docs.mjs: each value is wrapped in single quotes with ' → '' escaping.

/**
 * Serialize an object's string fields to a YAML frontmatter block.
 *
 * @param {Record<string, string>} fm  Key-value pairs, emitted in insertion order.
 * @returns {string}  Opening ---, fields, closing ---, trailing newline.
 */
function serializeFrontmatter(fm) {
  const lines = ['---'];
  for (const [key, val] of Object.entries(fm)) {
    const escaped = val.replace(/'/g, "''");
    lines.push(`${key}: '${escaped}'`);
  }
  lines.push('---');
  return lines.join('\n') + '\n';
}

// ── Page renderer ─────────────────────────────────────────────────────────────

/**
 * Assembles one skill detail page in feature-001's fixed order:
 *
 *   1. Page frontmatter  (title, description, generatedFrom)
 *   2. Generated marker  (byte-for-byte the sentence the four existing generated
 *                         pages carry, em-dash U+2014 included)
 *   3. ## Frontmatter    bullet list — every field rendered through
 *                         renderFrontmatterValue; no key dropped (AC-2)
 *   4. [Definition: …]  source link using GITHUB_BLOB_BASE from paths.mjs
 *   5. Body slot         renderSkillBody output, or the
 *                         <!-- body slot: … --> comment when empty (never an
 *                         empty heading — AC-7)
 *
 * No sidebar key is emitted (reserved slot for feature-002).
 *
 * @param {object} skill  SkillRecord as built by skills/discover.mjs.
 * @returns {string}  Complete page content, LF line endings, trailing newline.
 */
export function renderSkillPage(skill) {
  const sourcePath = skillSourcePath(skill.dirName);

  // ── 1. Page frontmatter ───────────────────────────────────────────────────
  // title   = the directory name (identity derivation — no slugification).
  // description = skillSummary(skill): the single authority for the first-sentence
  //              rule (cap defined in summary.mjs — not copied here).
  //              This keeps card text and page <meta name="description"> in sync.
  // generatedFrom = repo-relative POSIX source path.
  const pageFm = serializeFrontmatter({
    title: skill.dirName,
    description: skillSummary(skill),
    generatedFrom: sourcePath,
  });

  // ── 2. Generated marker ───────────────────────────────────────────────────
  // \u2014 = em-dash (U+2014), byte-for-byte matching the four existing pages.
  const marker =
    `<!-- generated \u2014 do not edit; source: ${sourcePath} -->`;

  // ── 3. ## Frontmatter bullet list ─────────────────────────────────────────
  // Every field from the record appears; no key is dropped.
  // Bullet format: - **`key`** — rendered-value
  // A bullet list is used (not a table) so none of the values containing `|`
  // needs a second escaping layer.
  const bullets = skill.fields
    .map((f) => `- **\`${f.key}\`** \u2014 ${renderFrontmatterValue(f)}`)
    .join('\n');

  // ── 4. [Definition: …] source link ────────────────────────────────────────
  const definitionLink =
    `[Definition: \`${sourcePath}\`](${skillGithubUrl(skill.dirName)})`;

  // ── 5. Body slot ──────────────────────────────────────────────────────────
  // renderSkillBody returns '' when both registries are empty (this feature).
  // Emit the slot comment rather than an empty heading so the page reads as
  // "unfilled slot" rather than "broken page".
  const body = renderSkillBody(skill);
  const bodyText = body !== ''
    ? body
    : `<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->\n`;

  // Assemble all sections, separated by blank lines.
  // pageFm already ends with '\n' (the closing '---\n').
  return (
    pageFm +
    '\n' + marker + '\n' +
    '\n' + '## Frontmatter' + '\n' +
    '\n' + bullets + '\n' +
    '\n' + definitionLink + '\n' +
    '\n' + bodyText
  );
}
