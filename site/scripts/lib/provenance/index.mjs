// index.mjs — Source-fragments body appender (feature-005 / task-043).
//
// Exports `provenanceAppender = { id: 'source-fragments', render(skill) }`.
//
// render(skill) runs four steps in this fixed order:
//   1. buildFlowChart({ name: dirName, dir }) — memoised per dirName for the run
//   2. verifyProvenance(chart)
//   3. buildEntries(chart)
//   4. renderFragmentList(entries)
//
// Verification runs before any markdown is produced for that skill.  An uncaught
// throw from verifyProvenance propagates to the caller, exits the process
// non-zero, and fails prebuild / npm run build — the same blast radius
// feature-001 specifies for its own guards.
//
// The section is emitted unconditionally for every skill: there is no flag,
// config, or environment value that can suppress it.
//
// The appender logs nothing.  stdout is unchanged by this module.
//
// Module-level state: _runMemo starts empty and is populated only by render().
// resetProvenanceMemo() drops all entries.  Tests inject _memo and _buildFlowChart
// via the opts seam to isolate runs and count calls; production always uses the
// module-level defaults, which start fresh per process.
//
// Pure exported values — no import-time side effect.

import { REPO_ROOT } from '../../skills/paths.mjs';
import { buildFlowChart } from '../flow-graph/index.mjs';
import { verifyProvenance } from './verify.mjs';
import { buildEntries, renderFragmentList } from './render-list.mjs';

// ── Run-level memo ────────────────────────────────────────────────────────────

/**
 * Memoised FlowChart objects, keyed by skill dirName, for the current run.
 *
 * Keyed by dirName because that is buildFlowChart's identity key.  A single
 * gen-skills run calls render() once per skill during RENDER; the memo collapses
 * any duplicate calls within that pass to exactly one buildFlowChart invocation
 * per dirName.
 *
 * @type {Map<string, import('../flow-graph/model.mjs').FlowChart>}
 */
const _runMemo = new Map();

/**
 * Drop all memoised charts.
 *
 * Analogous to resetFlowWarnings() in flow-graph/index.mjs.  Tests inject a
 * fresh Map via opts._memo instead of calling this; gen-skills.mjs may call
 * this at the top of main() alongside resetFlowWarnings() so that a second
 * in-process run starts clean.
 *
 * @returns {void}
 */
export function resetProvenanceMemo() {
  _runMemo.clear();
}

// ── Appender ──────────────────────────────────────────────────────────────────

/**
 * Body appender that appends the `## Source fragments` section to every skill page.
 *
 * Registered in skills/body.mjs as the sole entry in BODY_APPENDERS.
 * Emitted unconditionally — there is no code path that skips it.
 *
 * Uses exactly two fields from the SkillRecord: `dirName` and `sourcePath`.
 * The per-skill line range fields added by feature-001 are deliberately not
 * accessed — a node's provenance may cite any canonical/ file, not only the
 * skill's own SKILL.md, so verification reads whichever file is cited rather
 * than trusting the skill-level range.
 *
 * @type {{ id: string, render(skill: object, opts?: object): string }}
 */
export const provenanceAppender = {
  id: 'source-fragments',

  /**
   * Render the `## Source fragments` section for a skill page.
   *
   * Runs four steps in fixed order: buildFlowChart (memoised), verifyProvenance,
   * buildEntries, renderFragmentList.  Verification runs before any markdown is
   * produced; an uncaught throw propagates to the caller.
   *
   * @param {object}   skill                      SkillRecord (dirName and sourcePath used).
   * @param {string}   skill.dirName              Skill directory name (memo key and chart name).
   * @param {string}   skill.sourcePath           Repo-relative path to this skill's SKILL.md.
   * @param {object}   [opts]                     Testing seam — never passed in production.
   * @param {Map}      [opts._memo]               Override the run-level memo (inject per-test map).
   * @param {Function} [opts._buildFlowChart]     Override buildFlowChart (inject call counter).
   * @param {Function} [opts._renderFragmentList] Override renderFragmentList (inject spy).
   * @returns {string}  LF-terminated markdown containing `## Source fragments`.
   */
  render(skill, opts = {}) {
    const { dirName, sourcePath } = skill;
    const memo     = opts._memo               ?? _runMemo;
    const buildFn  = opts._buildFlowChart      ?? buildFlowChart;
    const renderFn = opts._renderFragmentList  ?? renderFragmentList;
    const dir      = REPO_ROOT;

    // Step 1 — build chart, memoised by dirName.
    // sourcePath ('canonical/skills/<dirName>/SKILL.md') is read alongside
    // dirName to satisfy the two-field contract; buildFlowChart constructs
    // the full path internally from name and dir.
    let chart = memo.get(dirName);
    if (chart === undefined) {
      chart = buildFn({ name: dirName, dir });
      memo.set(dirName, chart);
    }

    // Steps 2–4 — verify → entries → render.
    // verifyProvenance throws on the first violation; renderFn is never called
    // and no markdown is produced for this skill.
    verifyProvenance(chart);
    const entries = buildEntries(chart);
    return renderFn(entries);
  },
};
