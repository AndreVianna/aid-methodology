// verify.mjs — Provenance verifier for flow-chart nodes.
//
// Exports `verifyProvenance(chart) -> void`.  Runs checks P0–P6 per node,
// throwing on the first violation.  Each cited file is read at most once per
// call via a per-run Map<file, {text, lines}> cache — material when a doorway
// corpus shares a single engine file across many nodes.
//
// Pure exported function — no import-time side effect.

import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { REPO_ROOT } from '../../skills/paths.mjs';

// ── Guard name constants ──────────────────────────────────────────────────────

/** @type {string} */
const GUARD_PATH    = 'provenance path';

/** @type {string} */
const GUARD_RANGE   = 'provenance range';

/** @type {string} */
const GUARD_EXCERPT = 'provenance excerpt';

// ── Internal helpers ──────────────────────────────────────────────────────────

/**
 * Build the `file#L...` location string for a provenance record.
 *
 * Single-line range:  `canonical/skills/foo/SKILL.md#L5`
 * Multi-line range:   `canonical/skills/foo/SKILL.md#L3-L7`
 *
 * @param {string} file
 * @param {number|unknown} startLine
 * @param {number|unknown} endLine
 * @returns {string}
 */
function fileLoc(file, startLine, endLine) {
  if (startLine === endLine) return file + '#L' + startLine;
  return file + '#L' + startLine + '-L' + endLine;
}

/**
 * Build the standard `[gen-skills] <guard>: skill=... node=... <loc>` prefix.
 *
 * @param {string} guard   One of the three GUARD_* constants
 * @param {string} skill   Chart skill directory name
 * @param {string} nodeId  Node id (e.g. 'n1')
 * @param {string} loc     The `file#L...` string
 * @returns {string}
 */
function msgBase(guard, skill, nodeId, loc) {
  return '[gen-skills] ' + guard + ': skill=' + skill + ' node=' + nodeId + ' ' + loc;
}

// ── Checks ────────────────────────────────────────────────────────────────────

/**
 * P1 — `file` is non-empty, POSIX (no backslashes), under `canonical/`, free
 * of `..` segments, and exists on disk.
 *
 * Both path-syntax violations and the missing-file case use GUARD_PATH so
 * a CI log can grep one stable name for all path errors.
 *
 * @param {string}       file
 * @param {string}       skill
 * @param {string}       nodeId
 * @param {number}       startLine
 * @param {number}       endLine
 * @param {string}       repoRoot  Absolute OS path to the repo root
 */
function checkP1(file, skill, nodeId, startLine, endLine, repoRoot) {
  const displayFile = file || '<empty>';
  const loc = fileLoc(displayFile, startLine, endLine);
  const base = msgBase(GUARD_PATH, skill, nodeId, loc);

  if (!file) {
    throw new Error(base + ' file is empty');
  }
  if (file.includes('\\')) {
    throw new Error(base + ' file is not POSIX (contains backslash)');
  }
  if (!file.startsWith('canonical/')) {
    throw new Error(base + ' file is not under canonical/');
  }
  if (file.split('/').some((seg) => seg === '..')) {
    throw new Error(base + ' file contains ".." segment');
  }

  const absPath = resolve(repoRoot, ...file.split('/'));
  if (!existsSync(absPath)) {
    throw new Error(base + ' file does not exist on disk');
  }
}

/**
 * P0 — The file's text contains no `\r` (CRLF guard).
 *
 * Called after P1 so the file is guaranteed to exist.  Uses the per-run cache
 * so P0 and P3/P4 share the same read.
 *
 * @param {string}                              file
 * @param {string}                              skill
 * @param {string}                              nodeId
 * @param {number}                              startLine
 * @param {number}                              endLine
 * @param {Map<string,{text:string,lines:string[]}>} cache
 * @param {string}                              repoRoot
 */
function checkP0(file, skill, nodeId, startLine, endLine, cache, repoRoot) {
  const { text } = readCached(file, cache, repoRoot);
  if (text.includes('\r')) {
    throw new Error(
      msgBase(GUARD_PATH, skill, nodeId, fileLoc(file, startLine, endLine)) +
      ' file contains CRLF (\\r)'
    );
  }
}

/**
 * P2 — `startLine` and `endLine` are integers with `1 <= startLine <= endLine`.
 *
 * @param {number} startLine
 * @param {number} endLine
 * @param {string} file
 * @param {string} skill
 * @param {string} nodeId
 */
function checkP2(startLine, endLine, file, skill, nodeId) {
  if (
    !Number.isInteger(startLine) ||
    !Number.isInteger(endLine) ||
    startLine < 1 ||
    startLine > endLine
  ) {
    throw new Error(
      msgBase(GUARD_RANGE, skill, nodeId, fileLoc(file, startLine, endLine)) +
      ' invalid range (startLine=' + startLine + ' endLine=' + endLine + ')'
    );
  }
}

/**
 * P3 — `endLine <= lineCount(file)`.
 *
 * Called after P2, so startLine and endLine are known valid integers.
 *
 * @param {number}                              endLine
 * @param {string}                              file
 * @param {number}                              startLine
 * @param {string}                              skill
 * @param {string}                              nodeId
 * @param {Map<string,{text:string,lines:string[]}>} cache
 * @param {string}                              repoRoot
 */
function checkP3(endLine, file, startLine, skill, nodeId, cache, repoRoot) {
  const { lines } = readCached(file, cache, repoRoot);
  if (endLine > lines.length) {
    throw new Error(
      msgBase(GUARD_RANGE, skill, nodeId, fileLoc(file, startLine, endLine)) +
      ' endLine=' + endLine + ' exceeds file length (' + lines.length + ')'
    );
  }
}

/**
 * P4 — `excerpt === lines.slice(startLine-1, endLine).join('\n')`.
 *
 * Safe as a byte comparison because P0 already ruled out `\r`.
 * The error message names the first differing line (1-based absolute file line).
 *
 * @param {string}                              excerpt
 * @param {number}                              startLine
 * @param {number}                              endLine
 * @param {string}                              file
 * @param {string}                              skill
 * @param {string}                              nodeId
 * @param {Map<string,{text:string,lines:string[]}>} cache
 * @param {string}                              repoRoot
 */
function checkP4(excerpt, startLine, endLine, file, skill, nodeId, cache, repoRoot) {
  const { lines } = readCached(file, cache, repoRoot);
  const expected = lines.slice(startLine - 1, endLine).join('\n');
  if (excerpt === expected) return;

  const excerptLines = excerpt.split('\n');
  const expectedLines = expected.split('\n');
  let firstDiff = startLine;
  for (let i = 0; i < Math.max(excerptLines.length, expectedLines.length); i++) {
    if (excerptLines[i] !== expectedLines[i]) {
      firstDiff = startLine + i;
      break;
    }
  }

  throw new Error(
    msgBase(GUARD_EXCERPT, skill, nodeId, fileLoc(file, startLine, endLine)) +
    ' excerpt mismatch first-differing-line=' + firstDiff
  );
}

/**
 * P5 — The excerpt contains at least one non-whitespace character.
 *
 * A range citing only blank lines passes P4 (the file really contains blanks)
 * but renders an empty box, silently failing AC-5's "verbatim prompt fragment
 * is exposed" requirement.
 *
 * @param {string} excerpt
 * @param {number} startLine
 * @param {number} endLine
 * @param {string} file
 * @param {string} skill
 * @param {string} nodeId
 */
function checkP5(excerpt, startLine, endLine, file, skill, nodeId) {
  if (!/\S/.test(excerpt)) {
    throw new Error(
      msgBase(GUARD_EXCERPT, skill, nodeId, fileLoc(file, startLine, endLine)) +
      ' excerpt is all whitespace'
    );
  }
}

// ── File cache ────────────────────────────────────────────────────────────────

/**
 * Return `{text, lines}` for a repo-relative file, reading from disk only on
 * first access within a single `verifyProvenance` call.
 *
 * Callers must have already run P1 so the path is known valid and the file
 * is known to exist.
 *
 * @param {string}                              file      Repo-root-relative POSIX path
 * @param {Map<string,{text:string,lines:string[]}>} cache Per-run cache
 * @param {string}                              repoRoot  Absolute OS path to repo root
 * @returns {{ text: string, lines: string[] }}
 */
function readCached(file, cache, repoRoot) {
  if (cache.has(file)) return cache.get(file);
  const absPath = resolve(repoRoot, ...file.split('/'));
  const text = readFileSync(absPath, 'utf8');
  const lines = text.split('\n');
  const entry = { text, lines };
  cache.set(file, entry);
  return entry;
}

// ── Composite check runners ───────────────────────────────────────────────────

/**
 * Run P1, P0, P2, P3, P4, P5 on a Provenance record (for `node.provenance`).
 *
 * @param {object} prov
 * @param {string} skill
 * @param {string} nodeId
 * @param {Map}    cache
 * @param {string} repoRoot
 */
function checkFullProvenance(prov, skill, nodeId, cache, repoRoot) {
  const { file, startLine, endLine, excerpt } = prov;
  checkP1(file, skill, nodeId, startLine, endLine, repoRoot);
  checkP0(file, skill, nodeId, startLine, endLine, cache, repoRoot);
  checkP2(startLine, endLine, file, skill, nodeId);
  checkP3(endLine, file, startLine, skill, nodeId, cache, repoRoot);
  checkP4(excerpt, startLine, endLine, file, skill, nodeId, cache, repoRoot);
  checkP5(excerpt, startLine, endLine, file, skill, nodeId);
}

/**
 * Run P1, P2, P3 on a `detail` Provenance record (P6 — no excerpt checks).
 *
 * `detail` carries no excerpt by contract, so P4 and P5 are never run on it.
 *
 * @param {object} detail
 * @param {string} skill
 * @param {string} nodeId
 * @param {Map}    cache
 * @param {string} repoRoot
 */
function checkDetailProvenance(detail, skill, nodeId, cache, repoRoot) {
  const { file, startLine, endLine } = detail;
  checkP1(file, skill, nodeId, startLine, endLine, repoRoot);
  checkP2(startLine, endLine, file, skill, nodeId);
  checkP3(endLine, file, startLine, skill, nodeId, cache, repoRoot);
}

// ── Main export ───────────────────────────────────────────────────────────────

/**
 * Verify all provenance records in a FlowChart.
 *
 * Runs checks P0–P6 per node (P1–P3 only on `detail`).  Throws on the first
 * violation.  Each cited file is read at most once per call.
 *
 * @param {import('../flow-graph/model.mjs').FlowChart} chart
 * @param {object}  [opts]
 * @param {string}  [opts._repoRoot]  Override repo root (testing seam only).
 * @param {Map}     [opts._cache]     Inject external cache (testing seam only).
 * @throws {Error}  On the first violated provenance check
 */
export function verifyProvenance(chart, opts = {}) {
  const repoRoot = opts._repoRoot ?? REPO_ROOT;
  const cache = opts._cache ?? new Map();
  const { skill, nodes } = chart;

  for (const node of nodes) {
    checkFullProvenance(node.provenance, skill, node.id, cache, repoRoot);
    if (node.detail != null) {
      checkDetailProvenance(node.detail, skill, node.id, cache, repoRoot);
    }
  }
}
