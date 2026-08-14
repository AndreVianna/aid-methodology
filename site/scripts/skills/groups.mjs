// groups.mjs — Curated taxonomy and group assignment for the /skills/ index.
//
// Exports:
//   CURATED_GROUPS  — the corrected taxonomy table (FR-5, owner-corrected Q1).
//                     Deliberately NOT named SKILL_GROUPS — the identically-named
//                     constant at gen-reference.mjs:150-199 holds the stale taxonomy
//                     FR-5 overrides; a distinct name stops a future reader assuming
//                     the two tables agree.
//   assignGroups(records, catalog) → GroupSection[]
//                     Four guards (all throw), then a fully-assigned group tree.
//
// No import-time side effect; all work happens inside the exported function.

import { skillSummary } from './summary.mjs';


// ── Types (JSDoc only — no runtime shape) ────────────────────────────────────

/**
 * @typedef {{ name: string, route: string, intent: string }} SkillCard
 * @typedef {{ verb: string, cards: SkillCard[] }} FamilySection
 * @typedef {{ group: string, blurb: string, cards: SkillCard[], families: FamilySection[] }} GroupSection
 */

// ── Curated taxonomy ─────────────────────────────────────────────────────────
//
// Which skills sit in each curated group, and in what order, is a curatorial
// choice — not a filesystem fact or a catalog derivation. Deriving it would
// make the assignment tautological with itself. The unassignable-skill guard
// makes this table self-policing rather than trusted.
//
// Group order: Support → Knowledge Base Maintenance → Definition → Execution.
// This matches FR-5's own enumeration and gen-reference.mjs:150-199's order.
//
// Key design decisions recorded in REQUIREMENTS.md §5 FR-5 (Placement rules):
//   - aid-triage is Support (first in group), NOT Definition.
//   - Definition opens with exactly five full-path skills, un-subdivided,
//     in pipeline order. They have no catalog row; no family is invented.
//   - The two skills that used to be curated as full-path but are now ordinary
//     shortcuts carry catalog rows (verb: deploy / verb: monitor) and land
//     under those families by the ordinary rule, with no special case here.
//
// The `fullPath` array is the five un-subdivided skills, in pipeline order.
// The `members` array is the curated skills that do NOT belong to fullPath.

/**
 * @typedef {{ group: string, blurb: string, members: string[], fullPath?: string[] }} CuratedGroupEntry
 */

/**
 * The corrected taxonomy implementing FR-5 Placement rules (Q1, 2026-07-25).
 *
 * Every entry in `members` and `fullPath` must have a directory under
 * `canonical/skills/`; a missing directory fails the `curated skill missing`
 * guard. No name may appear more than once across all entries; a duplicate
 * fails the `duplicate assignment` guard. None of the `fullPath` names may
 * have a catalog row; a row fails the `full-path catalog row` guard. Any
 * on-disk skill directory not named here and not in the catalog fails the
 * `unassignable skill` guard.
 *
 * @type {CuratedGroupEntry[]}
 */
export const CURATED_GROUPS = [
  {
    group: 'Support',
    blurb: "Skills for configuring AID and managing tickets and connectors. Start here if you're not sure which skill to use.",
    members: [
      'aid-triage',
      'aid-config',
      'aid-set-connector',
      'aid-unset-connector',
      'aid-read-ticket',
      'aid-create-ticket',
      'aid-update-ticket',
    ],
  },
  {
    group: 'Knowledge Base Maintenance',
    blurb: 'Skills for discovering, querying, summarising, mapping, and maintaining the project Knowledge Base.',
    members: [
      'aid-discover',
      'aid-summarize',
      'aid-housekeep',
      'aid-update-kb',
      'aid-ask',
    ],
  },
  {
    group: 'Definition',
    blurb: 'The full AID pipeline plus every shortcut skill, grouped by verb family.',
    members: [],
    fullPath: [
      'aid-describe',
      'aid-define',
      'aid-specify',
      'aid-plan',
      'aid-detail',
    ],
  },
  {
    group: 'Execution',
    // Deliberately does NOT mention deploying or monitoring. Per FR-5's
    // owner-corrected Placement rules, `aid-deploy` and `aid-monitor` are
    // ordinary shortcut skills filed under their own `deploy` / `monitor` verb
    // families inside Definition — not members of this group. A blurb promising
    // them here contradicts the very taxonomy the page exists to present.
    blurb: 'Skills for executing detailed tasks, each through a graded adversarial review loop.',
    members: ['aid-execute'],
  },
];

// ── Assignment ────────────────────────────────────────────────────────────────

/**
 * Assign every on-disk skill record to a group (and, inside Definition, a verb
 * family), returning a GroupSection[] ready for the index renderer.
 *
 * Four guards run before any assignment; each throws with a stable name and an
 * actionable detail:
 *
 *   `unassignable skill`   — a directory that is neither curated nor catalog-backed.
 *   `curated skill missing` — a curated name with no directory on disk.
 *   `duplicate assignment`  — a name appearing in two curated entries.
 *   `full-path catalog row` — a full-path skill that unexpectedly has a catalog row.
 *
 * Returns only after all four pass, so no downstream renderer needs a defensive branch.
 *
 * Family order = catalog first-appearance order, derived by walking catalog.rows
 * in file order, skipping curated names, and appending each newly-seen verb to an
 * ordered array. A verb whose every member is curated produces no section at all.
 *
 * Card order within a family = catalog row order (canonical before aliases).
 *
 * @param {Array<{ dirName: string, route: string, field: (k: string) => { value: string } | undefined }>} records
 * @param {{ rows: import('./catalog.mjs').CatalogRow[], byName: Map<string, import('./catalog.mjs').CatalogRow> }} catalog
 * @returns {GroupSection[]}
 */
/**
 * Index a curated-groups table by name, enforcing the `duplicate assignment`
 * guard as it goes.
 *
 * Exported, and taking the table as a parameter, purely so that guard is
 * reachable. It fires only on a malformed `CURATED_GROUPS` — a hand-maintained
 * table — so with the constant read directly there is no input any test could
 * supply to trigger it, and an untested guard is indistinguishable from an
 * absent one. `assignGroups` passes the real constant; tests pass a deliberately
 * duplicated table.
 *
 * @param {typeof CURATED_GROUPS} groups
 * @returns {{ curatedGroup: Map<string, string>, fullPathSet: Set<string> }}
 */
export function buildCuratedIndex(groups) {
  /** @type {Map<string, string>} name → group label */
  const curatedGroup = new Map();
  /** @type {Set<string>} */
  const fullPathSet = new Set();

  const claim = (name, group) => {
    if (curatedGroup.has(name)) {
      throw new Error(
        '[gen-skills] duplicate assignment: "' + name + '" appears in more than one curated entry'
      );
    }
    curatedGroup.set(name, group);
  };

  for (const entry of groups) {
    for (const name of entry.fullPath || []) {
      claim(name, entry.group);
      fullPathSet.add(name);
    }
    for (const name of entry.members) {
      claim(name, entry.group);
    }
  }

  return { curatedGroup, fullPathSet };
}

export function assignGroups(records, catalog) {
  // ── Build helper sets ───────────────────────────────────────────────────

  // Collect every on-disk directory name from records.
  /** @type {Set<string>} */
  const onDiskNames = new Set(records.map((r) => r.dirName));

  // Build the complete curated set (members + fullPath). This is also where the
  // `duplicate assignment` guard fires — see buildCuratedIndex.
  const { curatedGroup, fullPathSet } = buildCuratedIndex(CURATED_GROUPS);

  // ── Guard: full-path catalog row ────────────────────────────────────────
  // None of the five full-path skills may have a catalog row.
  for (const name of fullPathSet) {
    if (catalog.byName.has(name)) {
      throw new Error(
        '[gen-skills] full-path catalog row: "' + name + '" is a full-path skill but has a catalog row'
      );
    }
  }

  // ── Guard: curated skill missing ─────────────────────────────────────────
  // Every curated name must have a directory on disk.
  for (const name of curatedGroup.keys()) {
    if (!onDiskNames.has(name)) {
      throw new Error(
        '[gen-skills] curated skill missing: "' + name + '" is in CURATED_GROUPS but has no directory on disk'
      );
    }
  }

  // ── Guard: unassignable skill (the clamp) ────────────────────────────────
  // Every on-disk directory must be either curated or catalog-backed.
  for (const name of onDiskNames) {
    if (!curatedGroup.has(name) && !catalog.byName.has(name)) {
      throw new Error(
        '[gen-skills] unassignable skill: "' + name + '" is neither in CURATED_GROUPS nor in the shortcut catalog'
      );
    }
  }

  // ── Build a record lookup by dirName ─────────────────────────────────────
  /** @type {Map<string, typeof records[0]>} */
  const recordByName = new Map();
  for (const r of records) {
    recordByName.set(r.dirName, r);
  }

  // ── Helper: build a SkillCard from a record ───────────────────────────────
  /** @param {typeof records[0]} r @returns {SkillCard} */
  function toCard(r) {
    // `skillSummary` is the SINGLE authority for this rule — imported, never
    // reimplemented, and the cap literal deliberately does not appear here.
    // An earlier version of this function used the raw `description` value with
    // `dirName` as its fallback, which silently broke three contracts at once:
    // it lost the first-sentence extraction and the length cap, it carried the
    // folded block's trailing newline into a card, and its fallback was the one
    // feature-002's SPEC states and delivery-002 Q3 rejected (feature-001's
    // sentinel is authoritative). feature-002 requires a card's text to EQUAL
    // its page's meta description, which only holds if both call this.
    return { name: r.dirName, route: r.route, intent: skillSummary(r) };
  }

  // ── Build family order by walking catalog.rows in file order ──────────────
  // Skipping curated names; appending each newly-seen verb to an ordered array.
  // A verb whose every member is curated therefore produces no empty section.
  /** @type {string[]} — ordered array of verbs, first-appearance order */
  const verbOrder = [];
  /** @type {Set<string>} */
  const seenVerbs = new Set();
  /** @type {Map<string, SkillCard[]>} verb → cards in catalog row order */
  const familyCards = new Map();

  for (const row of catalog.rows) {
    if (curatedGroup.has(row.name)) continue; // skip curated skills

    const verb = row.verb;

    if (!seenVerbs.has(verb)) {
      seenVerbs.add(verb);
      verbOrder.push(verb);
      familyCards.set(verb, []);
    }

    // Only add a card if this skill has a record (it should — the clamp
    // ensures every catalog-backed on-disk skill is accounted for, but a
    // catalog row might reference a non-existent directory if the corpus
    // changes; the clamp only guards the other direction).
    const rec = recordByName.get(row.name);
    if (rec) {
      familyCards.get(verb).push(toCard(rec));
    }
  }

  // ── Assemble GroupSection[] ────────────────────────────────────────────────

  /** @type {GroupSection[]} */
  const sections = [];

  for (const entry of CURATED_GROUPS) {
    // Cards for the group's hand-maintained member list (in entry order).
    /** @type {SkillCard[]} */
    const groupCards = [];
    for (const name of entry.members) {
      const rec = recordByName.get(name);
      if (rec) groupCards.push(toCard(rec));
    }

    // Full-path cards (Definition only).
    /** @type {SkillCard[]} */
    const fullPathCards = [];
    for (const name of entry.fullPath || []) {
      const rec = recordByName.get(name);
      if (rec) fullPathCards.push(toCard(rec));
    }

    // Family sections (Definition only — where fullPath exists).
    /** @type {FamilySection[]} */
    const families = [];
    if (entry.fullPath) {
      for (const verb of verbOrder) {
        const cards = familyCards.get(verb) || [];
        if (cards.length) {
          families.push({ verb, cards });
        }
      }
    }

    // Merge fullPathCards into the group's card list for the un-subdivided block.
    // The renderer uses GroupSection.cards for the full-path block when families exist.
    const allCards = entry.fullPath
      ? fullPathCards.concat(groupCards)
      : groupCards;

    sections.push({
      group: entry.group,
      blurb: entry.blurb,
      cards: allCards,
      families,
    });
  }

  return sections;
}
