# task-054: One shared skill-count derivation + its drift guard; correct KI-003's stale comments

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-054. It is the IMMUTABLE DEFINITION for this task.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.
Authored at execution time from `deliveries/delivery-006/BLUEPRINT.md`, per this delivery's
STATE.md Q1 — the same practice deliveries 001–005 used. No scope originates here that the
BLUEPRINT does not already carry.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-006

**Depends on:** —

**Scope:**
- Extract `SKILL_GROUPS` out of `site/scripts/gen-reference.mjs` into a new
  `site/scripts/skills/curated-roster.mjs`, **verbatim**, so the roster has one home. The
  extraction is what makes the roster readable by anything else: `gen-reference.mjs` calls
  `main()` at module scope, so importing it to ask "how many classic skills are there?" would
  regenerate all four reference pages as a side effect.
- Add `site/scripts/skills/skill-counts.mjs` exporting `deriveSkillCounts(repoRoot)` — the
  **single** derivation of the skill-count triple, computed from the same primitives the
  generator uses: the directories under `canonical/skills/`, the extracted curated roster, and
  the shortcut catalog. Pure: no import-time side effect, no writes.
- Add `site/scripts/__tests__/skill-counts.test.mjs` — the drift guard. It checks the
  derivation's internal consistency, checks it against the count the generated reference page
  renders, and checks every hand-authored page that states a roster claim against it. Floors
  and relations, not literals, except where a superseded value is named on purpose so a
  regression to it is obvious rather than merely "a number changed".
- Correct **KI-003**: the stale `94 / 16 classic / 76` triple in `gen-reference.mjs`'s comments
  (lines 5–6, 147, 390). State no count in that file's comments at all — the authority moves to
  `skill-counts.mjs`. Where a superseded number must be quoted to explain what went wrong, mark
  the line `KI-003` so the guard's exemption is keyed on the marker rather than on a line range
  that could silently widen.
- Update `known-issues.md` KI-003's Description to record what was actually measured: the
  generated page was always correct, only the comments drifted, so the issue had no
  reader-visible symptom.

**Acceptance Criteria:**
- [ ] `deriveSkillCounts` returns the measured triple — 111 directories, 19 classic, 64 emitting
      shortcuts — with `curated === classic + 2` (`/aid-triage` and `/aid-ask` counted separately,
      matching the README/methodology framing) and `shortcuts + repurposed === catalogRows`.
- [ ] `skill-counts.mjs` does **not** import `gen-reference.mjs`, and importing it regenerates
      nothing.
- [ ] The curated roster is declared in exactly one place: `curated-roster.mjs` exports it,
      `gen-reference.mjs` imports it, and no second `const SKILL_GROUPS = [` declaration survives
      anywhere. Asserted by the guard, not by inspection.
- [ ] `gen-reference.mjs` states no skill count in its comments, except on lines marked `KI-003`,
      and the guard proves that exemption is non-vacuous.
- [ ] Every curated name and every emitting shortcut name resolves to a real directory under
      `canonical/skills/`, checked non-vacuously.
- [ ] `skill-counts.test.mjs` passes, and `gen-reference.test.mjs` still passes unchanged.
- [ ] `gen-reference.mjs` remains idempotent, and `reference/skills.md`, `agents.md`, `kb.md`
      and `settings.md` are **byte-unchanged** by this task — the extraction moves code, not
      output.
- [ ] The 111 generated skill detail pages and their sidecars are byte-unchanged.
- [ ] `known-issues.md` KI-003 records the narrowed finding (comments-only, no reader-visible
      symptom) rather than leaving a future reader hunting a rendering bug.
- [ ] All section-6 quality gates pass.
