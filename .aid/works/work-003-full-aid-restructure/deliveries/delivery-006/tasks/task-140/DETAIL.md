# task-140: Delivery-006 site search and reconciled edit list

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

**Source:** feature-004-kb-management -> delivery-006 -> AC-15, AC-18, AC-25, AC-39

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-006-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout` and `##### 7. Migration`):
  - **R1** the 14 KB `create`/`update` skills (`aid-create-*` and `aid-update-*` for `architecture`,
    `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog` and `mvp`) and `design-lifecycle.md`, over
    every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`, `.github/` and
    `.aid/knowledge/`;
  - **R2** the rows and comments of `shortcut-catalog.yml` that name those skills, and every suite or site
    test that counts catalog rows, `repurpose: true` rows, doorways or skills
    (`test-deploy-monitor-repurpose.sh` DMR33, `test-catalog-dirs-parity.sh`, `test-shortcut-builder-invariants.sh`
    SBI05, `test-doc-counts.sh`, the site's skill-count tests);
  - **R3** the rows of `tests/canonical/skill-steps-exempt.tsv` whose owner is Feature 004, the SG-04
    exempt rows of `test-skill-guide.sh`, and the rows of `tests/conversation/deferred.tsv` that name a
    retiring skill, `003-11` or a Feature 004 sample;
  - **R4** the Q60 sites: `master` and `--base` in `worktree-lifecycle.sh`, `worktree-lifecycle.md` and
    `work-initiation-gate.md` § 3a; every caller of `worktree-lifecycle.sh create`; every reader of
    `pipeline.parent_branch`;
  - **R5** the new-project sites: `type: greenfield`, the callers of `recon-classify.sh`, the `Growing`
    case of `aid-kb-show`, the rows of `size-and-route.md`, and the modes `kb-commit.sh` has;
  - **R6** the drift and baseline sites: the callers of `kb-freshness-check.sh`, the writers of
    `approved_at_commit:` (`migrate-kb-frontmatter.sh` among them), and the CONVERT-STATE step's KB step
    in `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1`;
  - **R7** the shapes the two new templates carry over: `aid-create-roadmap`'s document, `aid-create-mvp`'s
    `## MVP` section shape and anchor position, and `aid-create-backlog`'s document; the readers of
    `backlog.md` and `roadmap.md` under `canonical/`; and every consumer of
    `canonical/aid/templates/knowledge-base/` (`synth_default_seed`, `domain-doc-matrix.md`, the site
    reference manifest, `test-kb-template-authoring-standard.sh` AS06);
  - **R8** the Q106 suite map for every file on the edit list, including the dashboard tests and the
    site's skill lists.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- Give each hit exactly one owner:
  - a task of delivery-006 (task-141 to task-160; see
    `.aid/works/work-003-full-aid-restructure/analysis/detail-proposal-delivery-006.md`);
  - "Feature 009 (delivery-012)" for the dashboard readers' legacy skill maps, which Feature 009 puts
    inside `legacy-skill-names` markers;
  - "installed copy (resync)";
  - "history, left as is";
  - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html` and `.aid/knowledge/INDEX.md`,
    which the resync's baselines step changes (G8, proposal S7).
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-140: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-140`.
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
- [ ] Each of R1-R8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
