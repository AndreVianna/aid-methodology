// discover.mjs — Enumerate canonical/skills/ and build SkillRecord[].
//
// Sole consumer of the skills directory. Exported functions accept an optional
// skillsDir parameter (defaults to CANONICAL_SKILLS_DIR) so tests can pass a
// temporary fixture directory without touching the real corpus.
//
// Pure exports — no import-time side effect.

import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import { parseSkillFrontmatter } from './frontmatter.mjs';
import { CANONICAL_SKILLS_DIR } from './paths.mjs';

/**
 * @typedef {import('./frontmatter.mjs').Field} Field
 */

/**
 * @typedef {object} SkillRecord
 * @property {string}   dirName        'aid-create-api' — also the slug
 * @property {string}   sourcePath     'canonical/skills/aid-create-api/SKILL.md'  (POSIX, repo-relative)
 * @property {string}   route          '/skills/aid-create-api/'
 * @property {string}   destPath       'site/src/content/docs/skills/aid-create-api.md' (POSIX, repo-relative)
 * @property {Field[]}  fields         frontmatter, source order
 * @property {(k:string)=>Field|undefined} field   convenience lookup
 * @property {string}   body           SKILL.md text after the closing fence
 * @property {number}   bodyStartLine  1-based line of body[0] within SKILL.md
 * @property {number}   lineCount      total lines in SKILL.md
 * @property {string|null} referencesDir  'canonical/skills/aid-describe/references' | null
 */

/** Slug pattern every canonical/skills/ directory must satisfy. */
const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/;

// ── Public API ────────────────────────────────────────────────────────────

/**
 * Enumerate canonical/skills/ and build SkillRecord[].
 *
 * Directories are enumerated with readdirSync(...).sort() — UTF-16 code-unit
 * order, locale-independent — matching gen-reference.mjs and ensuring AC-6
 * idempotence.
 *
 * @param {string} [skillsDir]  Absolute OS path to the skills root.
 *                              Defaults to CANONICAL_SKILLS_DIR.
 * @returns {SkillRecord[]}
 * @throws {Error}  On any per-skill guard failure (propagated from buildRecord).
 */
export function discoverSkills(skillsDir = CANONICAL_SKILLS_DIR) {
  const dirNames = readdirSync(skillsDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  return dirNames.map((dirName) => buildRecord(dirName, skillsDir));
}

/**
 * Build a single SkillRecord for one skill directory.
 *
 * @param {string} dirName        Directory name, e.g. 'aid-create-api'.
 * @param {string} [skillsDir]    Absolute OS path to the skills root.
 *                                Defaults to CANONICAL_SKILLS_DIR.
 * @returns {SkillRecord}
 * @throws {Error}  On: invalid slug; missing SKILL.md; name mismatch; any
 *                  frontmatter parse error.
 */
export function buildRecord(dirName, skillsDir = CANONICAL_SKILLS_DIR) {
  // Guard: directory name must match the slug pattern.
  if (!SLUG_RE.test(dirName)) {
    throw new Error(
      `[gen-skills] invalid slug: directory name '${dirName}' ` +
      `does not match ^[a-z0-9]+(-[a-z0-9]+)*$`
    );
  }

  // Guard: SKILL.md must exist.
  const absFile = resolve(skillsDir, dirName, 'SKILL.md');
  if (!existsSync(absFile)) {
    throw new Error(
      `[gen-skills] missing SKILL.md: no SKILL.md in canonical/skills/${dirName}/`
    );
  }

  const rawText = readFileSync(absFile, 'utf8');

  // Normalise line endings so \r\n and \r are treated as \n throughout.
  const normalizedText = rawText.replace(/\r\n?/g, '\n');
  const lines = normalizedText.split('\n');

  // lineCount: wc-l-compatible total. A properly \n-terminated file produces
  // one extra '' element at the end of split(); subtract it.
  const lineCount = lines[lines.length - 1] === '' ? lines.length - 1 : lines.length;

  // Find closing fence (0-based index). parseSkillFrontmatter will throw if
  // the fence is missing or unterminated, so fenceEnd is always found when
  // we reach the bodyStartLine computation below.
  let fenceEnd = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') {
      fenceEnd = i;
      break;
    }
  }

  // Parse frontmatter — the only YAML reader in the cluster; throws on any
  // parse error including missing/unterminated fence and duplicate keys.
  const sourcePath = 'canonical/skills/' + dirName + '/SKILL.md';
  const fields = parseSkillFrontmatter(normalizedText, sourcePath);

  // Guard: frontmatter 'name' must equal directory name (identity derivation).
  const nameField = fields.find((f) => f.key === 'name');
  const nameVal = nameField ? String(nameField.value) : '(missing)';
  if (!nameField || nameField.value !== dirName) {
    // Cites file and 1-based line like the three frontmatter guards do, so a
    // maintainer is pointed at the offending line rather than just the directory.
    // When `name` is absent entirely there is no line to cite, so the location
    // clause is suppressed rather than inventing one.
    const where = nameField ? `${sourcePath}:${nameField.line}` : sourcePath;
    throw new Error(
      `[gen-skills] name mismatch: directory '${dirName}' has frontmatter name ` +
        `'${nameVal}' (${where})`
    );
  }

  // bodyStartLine: 1-based line of the first character after the closing fence.
  // The closing fence sits at 0-based index fenceEnd (= 1-based line fenceEnd+1).
  // The first body character is at 0-based index fenceEnd+1 (= 1-based fenceEnd+2).
  const bodyStartLine = fenceEnd + 2;

  // body: raw normalised text of SKILL.md starting immediately after the
  // closing fence line, including the leading blank separator line when present.
  const body = lines.slice(fenceEnd + 1).join('\n');

  // referencesDir: non-null iff canonical/skills/<dir>/references/ exists.
  const refsAbsPath = resolve(skillsDir, dirName, 'references');
  const referencesDir = _isDirectory(refsAbsPath)
    ? 'canonical/skills/' + dirName + '/references'
    : null;

  return {
    dirName,
    sourcePath,
    route: '/skills/' + dirName + '/',
    destPath: 'site/src/content/docs/skills/' + dirName + '.md',
    fields,
    field(k) {
      return fields.find((f) => f.key === k);
    },
    body,
    bodyStartLine,
    lineCount,
    referencesDir,
  };
}

// ── Internal helpers ──────────────────────────────────────────────────────

/**
 * Return true if absPath exists and is a directory; false otherwise.
 * Swallows OS-level errors (e.g. permission denied).
 *
 * @param {string} absPath
 * @returns {boolean}
 */
function _isDirectory(absPath) {
  try {
    return existsSync(absPath) && statSync(absPath).isDirectory();
  } catch {
    return false;
  }
}
