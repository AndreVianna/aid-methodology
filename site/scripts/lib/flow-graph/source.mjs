// source.mjs — Frontmatter split, line-addressed slicing, Provenance builder,
//              and the shared ## State: NAME section reader.
//
// Placed here because source.mjs already owns line-addressed slicing, and the
// section reader depends on that primitive. Extractor 1 needs it for inline
// Detail cells; extractor 2 needs it for every node; feature-004's engine
// derivation needs it for below-cells.
//
// Pure exports — no import-time side effect.

// ── Type import (for JSDoc only) ──────────────────────────────────────────────

/**
 * @typedef {import('./model.mjs').Provenance} Provenance
 */

// ── Frontmatter split ─────────────────────────────────────────────────────────

/**
 * Split a SKILL.md (or worker file) into its raw lines, tracking where the
 * body begins so callers can compute 1-based line numbers within the original
 * file.
 *
 * Normalises CRLF → LF before splitting. Lines are 0-indexed in the returned
 * arrays; callers convert to 1-based by adding 1.
 *
 * @param {string} text        Full file content.
 * @param {string} sourcePath  Repo-relative path, used in error messages only.
 * @returns {{ allLines: string[], fmLines: string[], bodyLines: string[], bodyStartLine: number }}
 *   allLines:      every line of the file (0-indexed, CRLF stripped).
 *   fmLines:       lines 0..fenceEnd inclusive (the --- fences + content).
 *   bodyLines:     lines after the closing ---  (may be empty).
 *   bodyStartLine: 1-based line number of bodyLines[0] within the original file.
 * @throws {Error}  On a missing opening --- fence or an unterminated fence.
 */
export function splitFrontmatter(text, sourcePath) {
  const allLines = text.split('\n').map((l) => l.replace(/\r$/, ''));

  if (allLines.length === 0 || allLines[0] !== '---') {
    const first = allLines.length > 0 ? allLines[0] : '';
    throw new Error(
      `[gen-skills] source: missing frontmatter fence` +
      ` (${sourcePath}:1: ${first})`
    );
  }

  let fenceEnd = -1;
  for (let i = 1; i < allLines.length; i++) {
    if (allLines[i] === '---') {
      fenceEnd = i;
      break;
    }
  }

  if (fenceEnd === -1) {
    throw new Error(
      `[gen-skills] source: unterminated frontmatter fence (${sourcePath}:1: ---)`
    );
  }

  return {
    allLines,
    fmLines: allLines.slice(0, fenceEnd + 1),
    bodyLines: allLines.slice(fenceEnd + 1),
    bodyStartLine: fenceEnd + 2, // 1-based
  };
}

// ── Line-addressed slicing ────────────────────────────────────────────────────

/**
 * Return the verbatim LF-joined text for a 1-based inclusive line range.
 *
 * @param {string[]} lines      0-indexed line array (CRLF already stripped).
 * @param {number}   startLine  1-based, inclusive.
 * @param {number}   endLine    1-based, inclusive.
 * @returns {string}
 */
export function sliceLines(lines, startLine, endLine) {
  return lines.slice(startLine - 1, endLine).join('\n');
}

// ── Provenance builder ────────────────────────────────────────────────────────

/**
 * Build a Provenance record for a line range within a file.
 *
 * The excerpt is the verbatim LF-joined content of [startLine, endLine],
 * matching the fast equality check feature-005 uses for line-range verification:
 *   excerpt === readFile(file).split('\n').slice(startLine-1, endLine).join('\n')
 *
 * @param {string}   file       Repo-root-relative POSIX path (under canonical/).
 * @param {string[]} lines      0-indexed line array for that file.
 * @param {number}   startLine  1-based, inclusive.
 * @param {number}   endLine    1-based, inclusive, >= startLine.
 * @param {string}   sourceKind 'skill' | 'worker' | 'engine' | 'sibling'
 * @returns {Provenance}
 */
export function buildProvenance(file, lines, startLine, endLine, sourceKind) {
  return {
    file,
    startLine,
    endLine,
    sourceKind,
    excerpt: sliceLines(lines, startLine, endLine),
  };
}

// ── ## State: NAME section reader ─────────────────────────────────────────────

/**
 * @typedef {object} StateSectionRange
 * @property {string} name          State name (trailing parenthetical stripped).
 * @property {number} headingLine   1-based line number of the '## State: NAME' heading.
 * @property {number} leadEndLine   1-based last line of the heading+lead-paragraph
 *                                  (the provenance range for extractor 2).
 * @property {number} sectionEndLine 1-based last line of the full section (the detail
 *                                   range: heading to the line before the next '## '
 *                                   heading or '---' rule, or end of file).
 */

/**
 * Find all '## State: NAME' sections in a file's lines, returning ranges for
 * both the compact provenance (heading through lead paragraph) and the full
 * section (heading through line before next '##' heading or '---' rule).
 *
 * Extractor 1 uses the compact range for inline Detail cells. Extractor 2 uses
 * both ranges for every node. Feature-004's engine derivation uses both for
 * below-cells. All three consume this function unchanged.
 *
 * @param {string[]} lines  0-indexed line array (CRLF already stripped).
 * @param {string}   file   Repo-root-relative POSIX path (used in error messages).
 * @returns {StateSectionRange[]}
 */
export function findStateSections(lines, file) {
  // Pattern: ## State: NAME  (optional trailing parenthetical is stripped from name)
  const HEADING_RE = /^##\s+State:\s+(\S.*)/;
  const result = [];

  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(HEADING_RE);
    if (!m) continue;

    const headingLine = i + 1; // 1-based

    // Strip trailing parenthetical from name:
    //   "## State: VERIFY  (who reviews the reviewer)" → "VERIFY"
    const rawName = m[1].trim();
    const name = rawName.replace(/\s*\(.*\)\s*$/, '').trim();

    // ── Lead paragraph ───────────────────────────────────────────────────────
    // The lead paragraph is the first contiguous block of non-blank, non-heading
    // text immediately after the heading (possibly separated from it by blank lines).
    // If no such block exists before the next heading/rule/EOF, leadEndLine =
    // headingLine (just the heading itself).
    let leadEnd = headingLine;

    // Skip blank lines between heading and first content.
    let j = i + 1;
    while (j < lines.length && lines[j].trim() === '') j++;

    // If the first non-blank line is not a heading or rule, start the lead para.
    if (j < lines.length && !_isBoundary(lines[j])) {
      leadEnd = j + 1; // 1-based
      j++;
      while (j < lines.length && lines[j].trim() !== '' && !_isBoundary(lines[j])) {
        leadEnd = j + 1; // 1-based, extend to current line
        j++;
      }
    }

    // ── Full section ─────────────────────────────────────────────────────────
    // Section ends at the line before the next '## ' heading or '---' rule.
    // If neither is found, the section extends to the last line of the file.
    let sectionEnd = lines.length; // default: past last line (corrected below)

    for (let k = i + 1; k < lines.length; k++) {
      if (_isSectionBoundary(lines[k])) {
        // Next section starts at 0-indexed k → last included line is k-1 (0-indexed)
        // = k (1-based).
        sectionEnd = k;
        break;
      }
    }
        // Trim trailing blank lines from section end (they belong to the gap, not the section).
    while (sectionEnd > headingLine && lines[sectionEnd - 1].trim() === '') {
      sectionEnd--;
    }

        result.push({ name, headingLine, leadEndLine: leadEnd, sectionEndLine: sectionEnd });
  }

  return result;
}

// ── Internal helpers ───────────────────────────────────────────────────────────

/**
 * True when a line is a heading of any level or a '---' horizontal rule.
 * Used to detect the end of a lead paragraph.
 *
 * @param {string} line
 * @returns {boolean}
 */
function _isBoundary(line) {
  return /^#{1,6}\s/.test(line) || line === '---';
}

/**
 * True when a line starts a new section — specifically a level-2 heading or a
 * '---' horizontal rule. Level-3+ headings are sub-sections of the current
 * State section and do NOT end it.
 *
 * @param {string} line
 * @returns {boolean}
 */
function _isSectionBoundary(line) {
  return /^##\s/.test(line) || line === '---';
}
