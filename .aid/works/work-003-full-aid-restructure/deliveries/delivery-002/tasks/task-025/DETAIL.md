# task-025: Writer: new phase names, record modes and the fork

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

**Type:** IMPLEMENT

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37, AC-41

**Depends on:** task-021

**Scope:**
- Edit `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 002 `##### 2. Work state layout` and
  `##### 4. Steps and hand-offs`, Writer modes):
  - every write is atomic: a temporary copy is renamed into place under the lock, so a failed write
    leaves the file byte-for-byte unchanged;
  - the header documents exits 7, 8 and 9;
  - the header's "you are here (edit this)" becomes "this is the source (edit this)";
  - the `--pipeline` Phase check accepts only `Definition`, `Specification`, `Planning`, `Building` and
    `CI`, with the error text to match;
  - setting `lifecycle` to `Completed` or `Canceled` also sets `active_skill: none` and clears `step`
    and `step_detail`, in the same locked write;
  - new modes: `--create` (with `--path` and `--minimum-grade`), `--step`, `--reroute`, `--check` and
    `--repair`, as the spec's mode table says.
- Edit `dashboard/scripts/writeback-state.sh` (the fork): the new phase names plus `Deploy`, in its three
  places.
- Suites to update in this same task:
  - `tests/canonical/test-writeback-state.sh`;
  - `test-pipeline-status-walkthrough.sh` A1, its writer-fed values only. Its B1 "M4 phase emits" assertions
    on the skills' phase-write lines change with task-039 and task-040, which rewrite those lines (Q106);
  - `test-lite-work-end-to-end.sh`;
  - `test-producer-completeness.sh`;
  - `test-disjoint-merge.sh`;
  - the dashboard tests that feed an old phase name to a writer;
  - any suite the findings' P8 or P9 assigns here.
- Only existing assertions change here. The new-mode unit cases are task-046 and task-052 (Q135, R3).
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-025`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-025: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-025`.
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
- [ ] On a fixture work, `writeback-state.sh --pipeline --field Phase --value Execute` exits 4 and `--value Building` succeeds. The fork accepts the five names and `Deploy`, and nothing else.
- [ ] A scratch `--create` on an empty folder writes `intent.reading`, `intent.request`, `active_skill`, `step`, `pipeline.initiator`, `phase`, `lifecycle: Running`, `started` and `updated`. A second `--create` exits 8, and a missing `--skill` exits 5.
- [ ] `--check` exits 9 on a work with no `intent.reading`, and 0 on the work `--create` wrote. A forced failure (an unwritable target) leaves the file's `sha256sum` unchanged.
- [ ] `test-writeback-state.sh` and `test-pipeline-status-walkthrough.sh` pass live. The SS-11 forms, run by hand over both writers, find no old phase name (G3).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
