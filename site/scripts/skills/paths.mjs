// paths.mjs — Repo-root resolution, POSIX path builders, and shared constants.
//
// Repo-relative POSIX path strings are built by string concatenation so they
// stay platform-independent (forward slashes only) and make the
// .skills-manifest.json byte-identical on any OS (AC-6).
// Absolute OS paths for file I/O are built with resolve() from node:path.
//
// Pure exports — no import-time side effect.

import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// ── Shared constants ───────────────────────────────────────────────────────

/**
 * GitHub blob base URL, mirroring the literal used by the existing reference
 * generator. Redeclared here — that generator runs main() at module scope, so
 * importing anything from it would regenerate the four reference pages.
 */
export const GITHUB_BLOB_BASE =
  'https://github.com/AndreVianna/aid-methodology/blob/master';

// ── Root resolution ────────────────────────────────────────────────────────

const _dir = dirname(fileURLToPath(import.meta.url));

/**
 * Absolute OS path to the repository root (three levels up from
 * site/scripts/skills/).  Computed once at module load.
 */
export const REPO_ROOT = resolve(_dir, '../../../');

/**
 * Absolute OS path to the site/ directory.
 */
export const SITE_ROOT = resolve(_dir, '../../');

// ── Absolute OS path helpers (for file I/O) ───────────────────────────────

/**
 * Absolute OS path to canonical/skills/.
 */
export const CANONICAL_SKILLS_DIR = resolve(REPO_ROOT, 'canonical', 'skills');

/**
 * Absolute OS path to site/src/content/docs/skills/ (output directory).
 */
export const SITE_SKILLS_DIR = resolve(SITE_ROOT, 'src', 'content', 'docs', 'skills');

/**
 * Absolute OS path to site/scripts/.skills-manifest.json.
 */
export const SKILLS_MANIFEST_ABS = resolve(SITE_ROOT, 'scripts', '.skills-manifest.json');

// ── POSIX repo-relative string builders ───────────────────────────────────
// Return values are POSIX strings built by string concatenation (forward
// slashes only).  They are the exact strings written to .skills-manifest.json.

/**
 * Repo-relative POSIX source path for a skill's SKILL.md.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}        e.g. 'canonical/skills/aid-create-api/SKILL.md'
 */
export function skillSourcePath(dirName) {
  return 'canonical/skills/' + dirName + '/SKILL.md';
}

/**
 * Repo-relative POSIX destination path for a skill's generated page.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}        e.g. 'site/src/content/docs/skills/aid-create-api.md'
 */
export function skillDestPath(dirName) {
  return 'site/src/content/docs/skills/' + dirName + '.md';
}

/**
 * Full GitHub blob URL for a skill's SKILL.md source file.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}
 */
export function skillGithubUrl(dirName) {
  return GITHUB_BLOB_BASE + '/canonical/skills/' + dirName + '/SKILL.md';
}

/**
 * Absolute OS path to a specific skill directory.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}
 */
export function skillDirAbs(dirName) {
  return resolve(CANONICAL_SKILLS_DIR, dirName);
}

/**
 * Absolute OS path to a skill's SKILL.md file.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}
 */
export function skillFileAbs(dirName) {
  return resolve(CANONICAL_SKILLS_DIR, dirName, 'SKILL.md');
}

/**
 * Absolute OS path to a skill's generated destination page.
 * @param {string} dirName  e.g. 'aid-create-api'
 * @returns {string}
 */
export function skillDestAbs(dirName) {
  return resolve(SITE_SKILLS_DIR, dirName + '.md');
}
