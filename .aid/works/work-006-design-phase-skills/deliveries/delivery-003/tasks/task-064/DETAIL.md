# task-064: The site's generated skill surface regenerated -- twenty-two design cards and one brainstorm

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-064/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-063

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §5 and its §10 row *Site families*,
  with the card count fixed by REQUIREMENTS FR-11 **CC-7** and cited from there rather than re-derived.
  It closes BLUEPRINT criterion **8**.
- **"The site needs no code change" is true and is not the whole obligation.**
  `site/scripts/skills/groups.mjs` `assignGroups()` derives verb families by walking `catalog.rows` in
  file order, skipping curated names and appending each newly-seen verb, then pushing one card per
  surviving row -- so `design` gains cards and `brainstorm` appears as a new single-card section with
  no edit to that file. What **does** move is the generated content the site commits: the per-skill
  reference pages, the published index, the per-skill flow sidecars and the three generator manifests
  are all tracked files derived from the roster, and today they hold 76 skills.
- **The generated, tracked surface, resolved against disk rather than assumed.**
  `site/scripts/skills/paths.mjs` defines `SITE_SKILLS_DIR` as
  `site/src/content/docs/skills` (`:48`), `SKILLS_MANIFEST_ABS` as
  `site/scripts/.skills-manifest.json` (`:53`) and `SITE_SKILL_FLOWS_DIR` as
  `site/src/data/skill-flows` (`:65`). `git ls-files` counts 77 pages (76 plus `index.md`) and 76 flow
  sidecars today. `site/scripts/gen-reference.mjs` additionally writes
  `site/src/content/docs/reference/skills.md` and `site/scripts/.reference-manifest.json`. All of them
  are regenerated here by running the site's own generators -- `node site/scripts/gen-reference.mjs`
  then `node site/scripts/gen-skills.mjs`, which is the order `site/package.json`'s `prebuild` uses.
- **Every skill page embeds its skill's full description verbatim**, twice -- once truncated into the
  page's own frontmatter `description:` and once as a body bullet. So the AC-12 sweep changes all 112,
  and this task is what makes that visible on the published site. This is also why it is a descendant
  of every slice rather than a sibling.
- **Relocating a state-machine line into a body changes that skill's flow sidecar, and that is
  expected here.** `site/scripts/lib/flow-graph/extract-residual.mjs` rung R1 (`:222-234`) scans the
  **body** for a `^State machine:` line and builds the chart from it when found. task-052, task-053 and
  task-055 relocate five such lines out of frontmatter and into bodies, so R1 newly fires for those
  skills and their `<name>.flow.json` changes shape. A sidecar diff on exactly those skills is the
  expected result, not a defect -- and a sidecar diff on a skill whose description carried no such line
  is the finding.
- **The card counts are the teeth; the four guards are a no-regression clause.** §5 records that only
  `unassignable skill` (`groups.mjs:216`) can fire from this work -- it throws for any on-disk directory
  that is neither curated nor catalog-backed. The other three (`:161`, `:196`, `:206`) fire only on a
  malformed or colliding `CURATED_GROUPS` or a deleted curated directory, and `CURATED_GROUPS` is
  **not** edited. The clamp explicitly does not guard the other direction (`:265-268`), so a row whose
  directory was never created throws nothing and shows up only as one card fewer -- which is what
  `design == 22` catches.
- **One taxonomy warning, because three different "families" are in play and only one of them is 22.**
  22 is the **verb** family in the published index. The catalog's `group:` field is a second axis, on
  which G3 becomes 25 (`design` 22 + `prototype` 2 + `brainstorm` 1). The methodology Skill Inventory
  table is a third, hand-curated axis whose *Prototype + Design* row takes **25**, not 22, and that row
  is task-068's. A figure of 22 in a `group`-shaped context, or 25 in a card-count context, is wrong in
  both directions.
- Out of scope: editing `site/scripts/skills/groups.mjs` or `CURATED_GROUPS`; the four hand-maintained
  site content pages and the four `sync-docs.mjs` targets, all of which are task-068's; any write under
  `site/scripts/__tests__/`, barred by feature-001 AC-3; and the count-bearing prose in
  `site/src/content/docs/index.mdx`, which is task-068's.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 8, first half -- `assignGroups` throws none of its four guards.** The
      generators run to completion and the record names all four guards with the reason each could not
      fire, distinguishing the one that **can** (`unassignable skill`) from the three that cannot
- [ ] **BLUEPRINT criterion 8, second half -- the published index holds exactly 22 design cards and 1
      brainstorm.** In `site/src/content/docs/skills/index.md`, the `### \`design\`` section holds
      **22** card bullets and a `### \`brainstorm\`` section exists holding **1**, both counted from
      the regenerated file. The figure is CC-7's and is cited, not re-derived here
- [ ] **The generated page set grew to the full roster.** `git ls-files site/src/content/docs/skills/`
      captured to a variable -> `113` (112 skill pages plus `index.md`), and
      `git ls-files site/src/data/skill-flows/` -> `112`
- [ ] **Every one of the 112 pages carries its post-sweep description.**
      `grep -rc 'Direct-entry Lite-path shortcut' site/src/content/docs/skills/` captured to a variable
      -> `0`, and a witness page from each of the three strata is recorded with its description quoted
      and matched against the corresponding `canonical/skills/<name>/SKILL.md`
- [ ] **The flow-sidecar diff is exactly the relocation set.** `git diff --name-only HEAD --
      site/src/data/skill-flows/` is partitioned in the record into (a) the 36 newly added sidecars,
      (b) the sidecars of the skills whose `State machine:` line was relocated by task-052, task-053
      or task-055, and (c) any residue -- and (c) is empty, or each member is explained
- [ ] **The three manifests moved and are internally consistent**: `site/scripts/.skills-manifest.json`
      and `site/scripts/.reference-manifest.json` are regenerated, and re-running both generators
      produces byte-identical output (idempotence, evidenced by a `sha256sum` capture before and after
      rather than by `git status`)
- [ ] **The site suite is green with no edit to it.** `cd site && npm test` passes and
      `git diff --exit-code -- site/scripts/__tests__/` is clean. `site/scripts/__tests__/skill-counts.test.mjs`
      derives its current figures rather than pinning them, so it is expected to pass unmodified at
      112 / 94 / 60; if it does not, that is a finding to report, **not** to fix by editing the suite,
      because feature-001 AC-3 bars a write there
- [ ] **`groups.mjs` and `CURATED_GROUPS` are untouched.**
      `git diff --exit-code -- site/scripts/skills/` is clean
- [ ] **The taxonomy warning is honoured in this task's own record**: it reports 22 as the verb-family
      card count and states that G3 is 25 and the methodology table's *Prototype + Design* row is 25,
      naming task-068 as their owner, so no downstream reader carries 22 into a `group`-shaped context
- [ ] **Configuration is idempotent** and **no plaintext secrets** are introduced: nothing under
      `.aid/connectors/.secrets/` is created, modified or deleted
- [ ] `git diff --exit-code -- canonical/ tests/ profiles/ .claude/ .cursor/ docs/ .aid/knowledge/` is
      clean, and `git diff --name-only HEAD -- site/` lists only the generated paths named in Scope
- [ ] All section-6 quality gates pass
