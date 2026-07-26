/**
 * summary.mjs — First-sentence skill summary rule.
 *
 * Purpose:   skillSummary(record) -> string — the canonical one-line intent for
 *            a skill card or page description. Single authority for this rule;
 *            render-page.mjs (task-010) and render-index.mjs (task-014) both
 *            import from here and neither reimplements it.
 * Usage:     import { skillSummary } from './skills/summary.mjs';
 * Wired as:  imported by render-page.mjs and render-index.mjs.
 */

const SUMMARY_CAP = 157;

/**
 * Returns a one-line intent string for the skill represented by `record`:
 *
 * 1. Takes the first sentence of the frontmatter `description` — the text up to
 *    and including the first `. ` (period followed by a space).
 * 2. When no `. ` is present, uses the whole description value.
 * 3. Hard-cuts at the last word boundary at or below 157 characters, appending
 *    a trailing `…` (U+2026) if the value exceeded the cap. The cut never lands
 *    mid-word.
 * 4. Falls back to a fixed sentinel when the record carries no `description`
 *    field: `AID skill <dir> — declared frontmatter contract, generated from
 *    canonical/.` (em-dash U+2014, trailing period).
 *
 * Pure function: no clock, no environment read, no randomness. Output is
 * identical across repeated calls for the same input.
 *
 * @param {{ dirName: string, field: (k: string) => { value: string } | undefined }} record
 * @returns {string}
 */
export function skillSummary(record) {
  const descField = record.field('description');
  if (!descField) {
    return `AID skill ${record.dirName} \u2014 declared frontmatter contract, generated from canonical/.`;
  }

  const description = String(descField.value);

  // First sentence: text up to and including the first '. ' (period-space).
  // When no '. ' is present the whole value is the sentence.
  const dotSpaceIdx = description.indexOf('. ');
  const sentence = dotSpaceIdx === -1
    ? description
    : description.slice(0, dotSpaceIdx + 1);

  if (sentence.length <= SUMMARY_CAP) {
    return sentence;
  }

  // Cut at the last word boundary at or below SUMMARY_CAP characters.
  // Searching one position beyond SUMMARY_CAP catches the case where the
  // character at exactly SUMMARY_CAP is a space — that makes cutting at
  // SUMMARY_CAP valid (the prefix is a complete word ending).
  const searchRegion = sentence.slice(0, SUMMARY_CAP + 1);
  const lastSpace = searchRegion.lastIndexOf(' ');
  const cut = lastSpace > 0 ? sentence.slice(0, lastSpace) : sentence.slice(0, SUMMARY_CAP);
  return cut + '\u2026';
}
