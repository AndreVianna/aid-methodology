# task-185: Delivery-008 site search and reconciled edit list

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

**Type:** RESEARCH

**Source:** feature-006-planning -> delivery-008 -> AC-19

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 006 `##### 1. Files and layout` and `##### 8. Migration`):
  - **L1** `aid-detail`, over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`,
    `.github/` and `.aid/knowledge/`, checked against the spec's stated re-pointing sites;
  - **L2** the deleted templates and references by path: `delivery-state-template.yml`,
    `task-state-template.yml`, `delivery-plans/`, `aid-plan/references/first-run-loop.md` and
    `review-deliverables.md`, and every file of `aid-detail/`;
  - **L3** every PL-04 pattern: `deliveries/delivery-`, a per-task `STATE.yml`, `AID_TASK_STATE_FILE`,
    `AID_DELIVERY_STATE_FILE`, `pipeline.path`, `Pipeline Path`, `Spike Needed`, and in the dashboard files
    `work_path`;
  - **L4** every caller of `--create --path` and every allocation point (Feature 002's list), and the
    `delivery_lifecycle`, `tasks_lifecycle` and `--lifecycle Specified` writes in `shortcut-engine.md`;
  - **L5** every user of `derive-waves.sh`'s `<plan.md> --write|--check` table modes, of the `wave-map`
    block and of `parse_execution_graph`;
  - **L6** the dashboard's layout code: `_detect_hierarchy`, `_read_work_hierarchical`, `_detect_flat`,
    `_declared_work_path`, `parse_task_state_md`, the delivery-file parse and the delivery `qa` merge, with
    their Node twins, fixtures and tests;
  - **L7** the format-6 CONVERT-STATE step and `migrate-work-hierarchy.sh`/`.ps1` in `bin/aid`, `bin/aid.ps1`
    and `lib/`, and every suite or `Test-AidInstaller.ps1` case that runs `__migrate-repo` or `aid update` on
    a fixture holding a work;
  - **L8** the rows of `tests/conversation/deferred.tsv`, the SG-04 exempt list and
    `tests/canonical/skill-steps-exempt.tsv` that name `aid-plan`, `aid-detail` or `aid-deploy`, or a sample
    this delivery runs; and the Q106 suite map for every file on the edit list, including the dashboard
    tests and the site's skill lists.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
  `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
  renames it, which fixes the entry in the same task (AD14).
- **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
  skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
- Give each hit exactly one owner:
  - a task of delivery-008 (task-186 to task-218; see the task files under
    `.aid/works/work-003-full-aid-restructure/deliveries/delivery-008/tasks/`);
  - Feature 007 (delivery-009) for `aid-execute`'s own layout reads, exempt from PL-04 until then;
  - Feature 009 (delivery-012) for the shortcut engine's PLAN and DETAIL states;
  - "installed copy (resync)";
  - "history, left as is".
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-185: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-185`.
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
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] Each of L1-L8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step runs no suite (its work-folder-only rule).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
