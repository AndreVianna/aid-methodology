# task-295: aid-fix and aid-refactor hand-authored with the findings reference, and their catalog rows gone

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 295 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-14, AC-20, AC-30

**Depends on:** task-294

**Scope:**
- Rewrite `canonical/skills/aid-fix/SKILL.md` and `canonical/skills/aid-refactor/SKILL.md` by hand, each at most 80
  lines (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 2. Flow`): the `GENERATED` marker goes; step START only;
  the same citations as task-294; the spec's `description:`; `argument-hint: "[<kind>] <what is wrong>"` and
  `"<what to restructure>"`. `/aid-refactor` takes no kind.
- Create `canonical/skills/aid-fix/references/findings.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`, `/aid-fix`):
  run inside START, after step 5; the ledgers in the **main folder's** `.aid/.temp/review-pending/`
  (`<work>-review.md`, `<work>-test.md`), the main folder resolved as `worktree-lifecycle.sh` does, from any
  worktree; the chosen ledger as a `sources:` entry (`kind: file`, its main-folder path); one `Findings` question
  when several rows are open, recommending every `[CRITICAL]` and `[HIGH]` row; the kind from the findings or the
  symptoms.
- **Rows leave the shortcut catalog in this same task (Q121; PLAN.md delivery-011 Notes).**
  - Remove the `aid-fix` and `aid-refactor` rows from `canonical/aid/templates/shortcut-catalog.yml`. No other row changes.
  - `python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` passes with the rows gone, and
    the builder writes no file for the two skills any more.
  - The suites that count catalog rows or doorways take the new counts here, as the findings' Z3 lists them:
    `test-deploy-monitor-repurpose.sh` DMR30-DMR35 (and DMR33's `repurpose` count where the rows carried no
    `repurpose` key), `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`,
    `test-doc-counts.sh`, and the site's `skill-counts.test.mjs`, `skills-catalog.test.mjs` and
    `skills-groups.test.mjs`.
  - The site roster: the two skills are no longer catalog rows, so `site/scripts/skills/curated-roster.mjs` and
    `groups.mjs` name them in their group (`groups.mjs` stops with "unassignable skill" otherwise); then
    the site regeneration below.
  - Any count of catalog rows that `.claude/skills/generate-profile/SKILL.md` states and a suite asserts follows.
- **SS-09:** as task-294, with `skill:aid-fix` and `skill:aid-refactor` rows when needed.
- `canonical/aid/templates/connectors/consumption-protocol.md`: the wired-seam table drops `aid-fix`'s ingest step,
  which the hand-authored `aid-fix` no longer runs (a tracker item now enters through Feature 001's
  `external-sources.md` and `/aid-specify` START); the shortcut engine's own seam stays until delivery-012.
- Suites to update in this same task: `test-fix-family-scaffold.sh` and `test-change-refactor-family-scaffold.sh`
  where they assert the two doorways (FFS14, CRF13e and the like; the suites themselves retire with the
  scaffolding in delivery-012); `test-connector-consumption-linkage.sh`'s `aid-fix` seam, following the edited table;
  the site tests that use `aid-fix`'s body as a doorway fixture (`flow-extract-engine.test.mjs`'s
  `loadSkillRecord('aid-fix')`, `flow-graph-doorways.test.mjs`'s `aid-fix` fixture), re-pointed to a bare-verb
  doorway that stays until delivery-012 (`aid-remove` or `aid-migrate`); any suite the findings' Z1 or Z5 assigns
  here.
- **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
  asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
  synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
  for the final pass (AC-45).
- **Site regeneration (G1, G5).** When this task adds, deletes, renames or edits anything under
  `canonical/skills/`, `canonical/agents/` or `canonical/aid/templates/`, it runs
  `(cd site && npm run gen:skills && npm run gen:reference)` in this same task and commits the output:
  the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md`,
  `reference/agents.md` and `scripts/.skills-manifest.json`.
  - It also updates any hard-coded count or name list in a site generator, for example the agent count
    in `site/scripts/gen-reference.mjs`, so the generators' drift checks pass at this task's end.
  - A generated site page is never edited by hand.
- **Later checks on this task's files (G3).** Before `Done`, run by hand, over the files this task
  writes, every static-check pattern that this delivery's own suites or an earlier delivery's suites apply
  to those files, and fix every hit here. Repo-wide criteria in this file are scoped to what this task
  owns.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-295`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-295.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-295`.
       That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
     - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
     - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
     - Run `rm -rf "$S"` before step 4.
     - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
  4. **Live half.**
     - When `LIVE` is every suite outside `COPY`, run `HOME="$(mktemp -d)" bash tests/run-all.sh` and
       drop the `COPY` suites' results by name.
     - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
  5. **Outside `run-all.sh`.**
     - Run `(cd site && npm test)` when this task changes anything under `canonical/skills/`,
       `canonical/agents/` or `canonical/aid/templates/`, or under `docs/` or `site/` (G5). Run `npm ci`
       there first if `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] Neither `SKILL.md` carries the `GENERATED` marker; each is at most 80 lines; `findings.md` exists, at most 120 lines, and names the main folder and `.aid/.temp/review-pending/` (AS-06's findings half).
- [ ] `build-shortcut-skills.py --check` passes with the two rows gone; `grep -lr GENERATED canonical/skills/aid-{create,update,fix,refactor}/SKILL.md` prints nothing.
- [ ] The counting suites pass where the test step puts them, and the site `npm test` passes after `sync:docs` and regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
