# task-058: Delivery-003 site search and reconciled edit list

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

**Source:** feature-002-step-by-step-decisions -> delivery-003 -> AC-8, AC-28, AC-37, AC-40, AC-46

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file. The scopes
  are those of REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing`, group S.
  - **Q1** The SS-01 banner forms: `[State: X]` entry lines, "you are here" maps, "Advancing to
    [State", "[State N] Dispatching", "[Resolved:", and "Re-run `/aid-".
  - **Q2** The interviewer sites: `interviewer` in any case, over SS-05's scope (`canonical/agents/`,
    `canonical/skills/`, `canonical/aid/templates/`, `docs/`, `examples/`, `site/src/content/`), plus
    `tests/` and `.aid/knowledge/`.
  - **Q3** The question-record sites: `## Cross-phase Q&A`, and every write to a delivery-level `qa`.
  - **Q4** `AskUserQuestion`. This includes `canonical/aid/scripts/connectors/write-connector.sh`; decide
    whether it is a picker use or text.
  - **Q5** The `reviewer-brief.md` files, `reviewer-dispatch.md` and the reviewer agent.
  - **Q6** Every citation of `state-machine-chaining.md`.
  - **Q7** The asking skills against the spec's AC-28 coverage table, each with its sample id or the
    `skill:` row it needs.
  - **Q8** The Q106 suite map for every file on the delivery's edit list.
  - **Q9** Today's counts for each AD13 class in `tests/canonical/test-artifact-discipline.sh`.
- Give each hit exactly one owner:
  - a task of delivery-003 (task-059 to task-081; see
    `.aid/works/work-003-full-aid-restructure/analysis/detail-proposal-delivery-003.md`);
  - "installed copy (resync)";
  - "history, left as is", for `release-tracking.md`, `kb.html`, `coverage-accepted-removals.tsv` and
    `validate-diagram-content.mjs`.
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-058: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-058`.
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
     - Run `(cd site && npm test)` when this task changes `canonical/skills/`,
       `canonical/aid/templates/shortcut-catalog.yml`, `docs/` or `site/`. Run `npm ci` there first if
       `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] Each of Q1-Q9 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
- [ ] Q7 lists every asking skill with its sample id or the `skill:` row task-078 adds. RESEARCH defaults are overridden as in task-001, and the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
