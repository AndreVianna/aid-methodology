# task-023: Step rules skill-steps.md

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

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-10, AC-11, AC-37, AC-38

**Depends on:** task-020, task-022

**Scope:**
- Create `canonical/aid/templates/skill-steps.md`, of type `template-own` (REQUIREMENTS.md § 11 Feature 002 `##### 4. Steps and
  hand-offs`, `##### 2. Work state layout` and `##### 5. Approvals and the merge boundary`). It holds:
  - the step-table shape;
  - the advance words `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL` and `HALT`;
  - the six-part step procedure;
  - **§ The work record**: when it is written, fail-closed, starting versus resuming, detection's two
    uses, and recovery;
  - the one standard **State Detection rule** that every skill's section cites: detection shapes the
    entry step and validates a saved step, and never routes;
  - **§ When approvals happen**: the table, coinciding approvals, approval records, and "before the push
    it controls";
  - the never-merges rule;
  - what the user sees: no banners, and one progress line.
- It cites `question-protocol.md` for `ASK`. task-022 is a dependency.
- Suites to update in this same task: none exist.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-023`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-023: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-023`.
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
- [ ] The six advance words appear with their meanings in one table. The step-entry rule says `--step` is written before any work in the step, which is SS-02's clause (AC-37).
- [ ] § The work record states fail-closed, the two detection uses, and recovery: one confirmation question, then `--repair`, which needs `--reading` when the record has none (AC-37). `PASS`, `CALL` and `HALT` with nested calls match the spec's step procedure, steps 4-6 (AC-38).
- [ ] § When approvals happen holds the nine-row `full`/`lite` table and the M11 and Q36 rules (AC-10). The file says AID never merges, naming Feature 008's conflict-merge exception (AC-11).
- [ ] Every pointer resolves under `canonical/aid/` (SR-01).
- [ ] `grep -nE '^(active_skill|step|step_detail|phase):' canonical/aid/templates/skill-steps.md` finds nothing: every record example is indented or inline (SS-14 (b)). The SS-11 forms find no old phase name in the file (G3).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
