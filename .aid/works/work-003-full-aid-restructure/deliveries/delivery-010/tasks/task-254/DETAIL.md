# task-254: Delivery-010 site search and reconciled edit list

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 254 --field State.

**Type:** RESEARCH

**Source:** feature-008-cicd-integration-monitoring -> delivery-010 -> AC-11, AC-35, AC-36

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 008 `##### 1. Files and layout` and `##### 7. Migration`):
  - **Y1** `housekeep/cleanup-classify.sh`, the `aid-housekeep` teardown, and `origin/master` as a merge target,
    over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/` and `.github/`;
  - **Y2** the interim close: `/aid-orchestrate`'s close minimum, and every line that marks a work `Completed`
    by hand (`aid-research`, `aid-review`, `aid-report`, `aid-deploy`, `aid-orchestrate`, `aid-kb-update`,
    `aid-execute`);
  - **Y3** every executed or written `git push`, `git merge`, `git pull`, `gh pr create`, `glab mr create`,
    `git branch -D` and `git worktree remove --force` under `canonical/` and `dashboard/scripts/` (NM-01, NM-03,
    NM-05, NM-06), each with the task that removes it or the exception that keeps it;
  - **Y4** the readers of `pull_request`, `work_folders`, `feedback` and the dashboard's CI card lines;
  - **Y5** the consumer rows of `worktree-lifecycle.md` § Step 3, `consumption-protocol.md`'s wired-seam
    table, and the gate's § 3b row 1;
  - **Y6** this repository's own `.gitignore` entries for `.aid/works/` (the ignored-folder question at the
    first push of this work, Risks);
  - **Y7** the rows of `tests/conversation/deferred.tsv` and the SG-04 exempt list that name a sample or skill
    this delivery runs or adds;
  - **Y8** the Q106 suite map for every file on the edit list, including the site's skill lists.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- Give each hit exactly one owner:
  - a task of delivery-010 (task-255 to task-287; see the task files under
    `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
  - Feature 009 (delivery-012) for the skills it rebuilds that finish a work (`create`, `update`, `document`,
    `test`, `prototype`);
  - "installed copy (resync)";
  - "history, left as is".
- **Content owner of the moved file (G7):** `cleanup-classify.sh` moves to `canonical/aid/scripts/pipeline/`, and
  task-257 owns both the move and its content.
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-254.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-254`.
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
- [ ] Each of Y1-Y8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
