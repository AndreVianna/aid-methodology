# task-022: Question protocol question-protocol.md

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

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-8, AC-9, AC-28, AC-40

**Depends on:** task-020

**Scope:**
- Create `canonical/aid/templates/question-protocol.md`, of type `template-own`. It holds
  REQUIREMENTS.md § 11 Feature 002 `##### 3. Question protocol`:
  - one question in plain text, with **Why I ask**, **My recommendation**, options, and the free answer;
  - importance labels;
  - groups of 3 to 5 questions, breaks, follow-ups, and `Assumed` for questions already answered;
  - reviews in chunks, and small decisions confirmed in one batch;
  - the question record shape, and its four states;
  - `--ask` before a question is shown, and `--answer` after it;
  - the intake-question exception;
  - where each record lives: the work, `.aid/STATE.yml`, or the KB file;
  - main conversation only: sub-agents record their questions and never ask them.
- Suites to update in this same task: none exist.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-022`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-022: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-022`.
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
- [ ] The file holds the spec's example question block, and states FR-17 rules 1-10, each under a greppable heading or bullet (AC-8, AC-28).
- [ ] The record shape lists `id`, `category`, `impact` (`High`, `Medium` or `Low`), `state` (`Pending`, `Answered`, `Skipped` or `Assumed`), `asked_by`, `step`, `context`, `suggested`, `answer`, `answered_by` and `applied_to`, plus `covers` and `commit` for approvals.
- [ ] It names the intake exception, `--ask`, `--answer` and `--project`. `grep -c AskUserQuestion` on it prints 0, and every `.aid/runtime/` pointer resolves under `canonical/aid/` (SR-01).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
