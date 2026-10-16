# task-253: KB test landscape for the building suites, the regenerated index and the view

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

**Type:** DOCUMENT

**Source:** feature-007-building -> delivery-009 -> AC-25, AC-26

**Depends on:** task-241, task-243, task-244, task-245, task-249, task-250, task-251, task-252

**Scope:**
- `.aid/knowledge/test-landscape.md`: `test-execute.sh` and `test-simplify-guard.sh` and their lane; the new
  cases of `test-writeback-state.sh`, `test-derive-waves.sh`, `test-complexity-score.sh`,
  `test-compute-block-radius.sh` and `test-work-state-migration.sh`; the retired `test-delivery-gate-aggregate.sh`
  and `test-disjoint-merge.sh` go.
- Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync
  migrates this work's state, not the KB.
- Name no work and no work folder.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-253`.
- **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
  them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
  except the resync itself.
  1. **Resync session:** the resync (`delivery-009: resync`), committed alone: it installs the new `/aid-execute`,
     the Feature 007 writer and `simplify-guard.sh`, and runs format 6's building part on this work (every delivery's
     gate grade into its `verify`). Then the session ends.
  2. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
     `--plan` when it reports stale; then `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated page (`reference/settings.md`
    from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB is not changed by this resync.
  3. **The gate:** the stanza's criteria, the samples, G0 with the baselines, and the tracking proof for task-219
     to task-253 (the work `STATE.yml`'s state-only commits and its `reviews`). A fix after this resync records its
     grade with `--delivery-id 009 --field Verify`; no lifecycle is written.
     The gate's pre-switch checks leave out the stanza's "After the switch, four things hold" criterion; step 5
     checks it.
  4. **The switch** (Q123, Q124): `--check`, then `--repair --skill aid-execute --name START --reading change`;
     `Verify` and `Commit` for deliveries 001-009 with `--delivery-id NNN --field`; then the one approval through
     `--ask` and `--answer`, `covers: delivery delivery-001; ...; delivery delivery-009; confirmation before
     building`, `commit` the head.
  5. **Post-switch check** (the stanza's "After the switch, four things hold", run after step 4): the installed
     `writeback-state.sh --check` exits 0 on this work; its `STATE.yml` reads `intent.reading: change`,
     `active_skill: aid-execute` and `step: START`; `qa` holds one `Approval` entry answered yes, with a `commit`,
     whose `covers` names `delivery delivery-001` to `delivery delivery-009` and `confirmation before building`.
     A failure here is fixed and the check re-run before delivery-010's START.
  6. **Research for delivery-010 (Q139)**, after the post-switch check (step 5). `aid-researcher` writes
     `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` from the brief below, in a clean
     context. `aid-reviewer` grades it in a clean context with `grade.sh` against `minimum_grade`, against the brief's
     criteria; fix rounds follow as for a task, and the same failure after three rounds goes to the maintainer. The
     file is then committed alone (a work-folder file, not resync-relevant). Delivery-010's run starts only after
     that commit.
     **Brief:**
     - Create `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md`. The step touches nothing else.
     - Re-run these searches at the head the gate session leaves, and record that commit in the file
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
     - **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
       `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
       renames it, which fixes the entry in the same task (AD14).
     - **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
       skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
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
     **Criteria:**
     - [ ] Each of Y1-Y8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
     - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
     - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-253: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-253`.
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
- [ ] `test-landscape.md` names both new suites and their lane, and neither retired suite.
- [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
