// skill-counts.mjs — the single derivation of AID's skill-count triple.
//
// Every reader-facing claim about how many skills AID ships must be checked
// against this, and nothing may hand-count. That is the KI-005 lesson: the same
// three numbers were written by hand into a generator's comments, two content
// pages and a test's fixtures, and drifted independently in all four places until
// KI-003 — the home page promised 92 skills while the site shipped 111 cards.
//
// This module deliberately does NOT import gen-reference.mjs, which calls main()
// at module scope — importing it would regenerate all four reference pages as a
// side effect of asking a question. It derives from the same primitives that
// generator uses: the canonical skill directories, feature-002's curated roster,
// and the shortcut catalog.
//
// Pure: no import-time side effect, no writes.

import { readdirSync } from 'node:fs';
import { join } from 'node:path';
import { CANONICAL_SKILLS_DIR } from './paths.mjs';
import { SKILL_GROUPS } from './curated-roster.mjs';
import { loadShortcutCatalog } from './catalog.mjs';

/**
 * Skills that are curated but are NOT counted as "classic pipeline skills".
 *
 * `/aid-triage` is the suggest-only router and `/aid-ask` is a Q&A alias of
 * `/aid-query-kb`; both render inside a group but are counted separately, matching
 * the README and methodology framing of "N classic + /aid-triage + /aid-ask".
 * gen-reference.mjs USED to exclude exactly these two when it computed its own classic count;
 * task-057 deleted that computation along with the roster it rendered, so this module is now
 * the only place the distinction is made. `classic` itself is no longer stated on any page --
 * `curatedOnly` is, because that is the figure a decomposition can sum with. Kept because the
 * README and methodology still use the "N classic" framing in prose.
 */
const NON_CLASSIC_CURATED = ['aid-triage', 'aid-ask'];

/**
 * @typedef {object} SkillCounts
 * @property {number}   directories  Directories under `canonical/skills/`.
 * @property {number}   curated      Curated skills — classic plus the two above.
 * @property {number}   classic      Curated minus `/aid-triage` and `/aid-ask`.
 * @property {number}   shortcuts    Catalog rows that emit a shortcut skill.
 * @property {number}   catalogRows  All catalog rows, emitting or `repurpose`.
 * @property {number}   repurposed   Rows that re-register a hand-authored skill.
 * @property {number}   classicRepurposed  Repurpose rows naming a curated skill.
 * @property {number}   curatedOnly  Curated skills that are NOT catalog rows — the
 *                                   figure that makes a decomposition of the corpus
 *                                   SUM, because it does not double-count.
 * @property {number}   catalogCanonical  Catalog rows that are canonical names.
 * @property {number}   catalogAliases    Catalog rows that are aliases.
 * @property {string[]} directoryNames  Sorted directory names.
 * @property {string[]} curatedNames    Sorted curated skill names.
 * @property {string[]} shortcutNames   Sorted emitting shortcut names.
 */

/**
 * Derive the skill-count triple and its supporting sets.
 *
 * @param {string} repoRoot  Absolute path to the repository root.
 * @returns {SkillCounts}
 */
export function deriveSkillCounts(repoRoot) {
  // Honour `repoRoot` for BOTH reads. It used to be passed to loadShortcutCatalog while the
  // directory scan used the module-level constant, so a caller passing a different root got a
  // catalog from there and directories from here -- two halves of one answer, from two trees.
  const skillsDir = repoRoot ? join(repoRoot, 'canonical', 'skills') : CANONICAL_SKILLS_DIR;
  const directoryNames = readdirSync(skillsDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  // From gen-reference's roster, not feature-002's CURATED_GROUPS. The two are
  // different sets on purpose and both are correct: CURATED_GROUPS holds its members plus a
  // separate `fullPath` list, deliberately excluding `aid-deploy` and `aid-monitor`
  // because the owner's Q1 decision made the full path exactly five skills and those
  // two ordinary shortcuts. They are still hand-authored `repurpose: true` skills, so
  // they ARE classic in the reference framing — which is what a reader-facing "N
  // classic skills" claim means. Deriving from CURATED_GROUPS would silently produce the
  // NON-catalog figure instead, which is a different quantity with a different meaning.
  //
  // Deduped: a curated skill appears in exactly one group today, but the set
  // operation is what the count means, so a future duplicate must not inflate it.
  const curatedNames = [
    ...new Set(SKILL_GROUPS.flatMap((g) => g.skills.map((s) => s.name))),
  ].sort();

  const { rows } = loadShortcutCatalog(repoRoot);
  // `repurpose: true` rows re-register a pre-existing hand-authored skill rather
  // than generating a doorway, so they are catalog rows that emit nothing.
  const emitting = rows.filter((r) => r.repurpose !== 'true');
  const shortcutNames = emitting.map((r) => r.name).sort();

  const classicNames = curatedNames.filter((n) => !NON_CLASSIC_CURATED.includes(n));

  // Repurpose rows that re-register a skill the curated roster already carries, as
  // opposed to the work-005 single-shot "collapse" skills. The reference page states
  // this number in prose, so it is derived here rather than counted there.
  const curatedSet = new Set(curatedNames);
  const classicRepurposed = rows.filter(
    (r) => r.repurpose === 'true' && curatedSet.has(r.name),
  ).length;

  // The figure a reader-facing decomposition must use.
  //
  // `curated` counts four skills that are ALSO catalog rows -- aid-deploy, aid-monitor,
  // aid-query-kb and the aid-ask alias -- so pairing it with the catalog-row count
  // double-counts those four, and the sentence "classic + triage + ask + shortcuts"
  // double-counts three of them AND omits the work-005 collapse skills entirely. Excluding
  // the overlap gives the figure that SUMS with the catalog rows to the corpus total, which
  // is the decomposition every page on the site states.
  //
  // No figures are written above on purpose: this file is the one place the numbers are
  // derived, so stating them in its own commentary is the defect it exists to prevent --
  // and stating them here is exactly what the guard caught twice. The identity is asserted
  // in skill-counts.test.mjs, so a future roster change cannot quietly break it.
  const catalogNameSet = new Set(rows.map((r) => r.name));
  const curatedOnlyNames = curatedNames.filter((n) => !catalogNameSet.has(n));

  // Pages state the catalog's split as "N canonical names + N aliases", so both halves are
  // derived here too rather than being two more numbers nobody checks.
  const catalogCanonical = rows.filter((r) => r.alias_of === 'null').length;

  return {
    curatedOnly: curatedOnlyNames.length,
    curatedOnlyNames,
    catalogCanonical,
    catalogAliases: rows.length - catalogCanonical,
    directories: directoryNames.length,
    curated: curatedNames.length,
    classic: classicNames.length,
    shortcuts: shortcutNames.length,
    catalogRows: rows.length,
    repurposed: rows.length - emitting.length,
    classicRepurposed,
    directoryNames,
    curatedNames,
    shortcutNames,
  };
}
