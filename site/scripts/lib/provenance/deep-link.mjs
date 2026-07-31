// deep-link.mjs — GitHub blob deep-link builder.
//
// Exports `lineAnchor` and `blobUrl`.  Pure functions; no file reads, no
// clock, no environment access, no import-time side effect.

import { GITHUB_BLOB_BASE } from '../../skills/paths.mjs';

// ── Path-charset guard ────────────────────────────────────────────────────────

const SAFE_PATH_RE = /^[A-Za-z0-9._/-]+$/;

/**
 * Throw if `file` is unsafe to embed in a GitHub blob URL without encoding.
 *
 * Three distinct rejections:
 *   1. Any character outside [A-Za-z0-9._/-]
 *   2. A `..` path segment
 *   3. A leading `/`
 *
 * @param {string} file
 */
function guardPath(file) {
  if (!SAFE_PATH_RE.test(file)) {
    throw new Error(
      'blobUrl: file contains a character outside [A-Za-z0-9._/-]: ' + file
    );
  }
  if (file.split('/').some(seg => seg === '..')) {
    throw new Error('blobUrl: file contains a ".." segment: ' + file);
  }
  if (file.startsWith('/')) {
    throw new Error('blobUrl: file has a leading "/": ' + file);
  }
}

// ── Exported functions ────────────────────────────────────────────────────────

/**
 * GitHub line-range anchor fragment.
 *
 * Returns `#L<n>` when `startLine === endLine`, else `#L<start>-L<end>`.
 *
 * @param {number} startLine  1-based start line
 * @param {number} endLine    1-based end line (>= startLine)
 * @returns {string}
 */
export function lineAnchor(startLine, endLine) {
  if (startLine === endLine) {
    return '#L' + startLine;
  }
  return '#L' + startLine + '-L' + endLine;
}

/**
 * Full GitHub blob URL pointing at the given line range in `file`.
 *
 * Throws via `guardPath` if `file` is unsafe (see that function's docs).
 *
 * @param {string} file       Repo-relative POSIX path, e.g. `canonical/skills/aid-foo/SKILL.md`
 * @param {number} startLine  1-based start line
 * @param {number} endLine    1-based end line
 * @returns {string}
 */
export function blobUrl(file, startLine, endLine) {
  guardPath(file);
  return GITHUB_BLOB_BASE + '/' + file + lineAnchor(startLine, endLine);
}
