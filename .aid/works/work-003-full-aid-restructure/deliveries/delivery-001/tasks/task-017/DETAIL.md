# task-017: Feature 001 samples 001-09 to 001-16: phases, sources and closing

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

**Type:** TEST

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-14, AC-29

**Depends on:** task-004, task-005, task-010

**Scope:**
- Create `001-09-bug-fix-phases.md`, `001-10-release-own-work.md`, `001-11-ticket-mid-work.md`,
  `001-12-write-back-limit.md`, `001-13-project-source-unattached.md`,
  `001-14-refactor-is-new-capability.md`, `001-15-no-kb-offers-preparation.md` and
  `001-16-work-closes-done.md` under `tests/conversation/samples/feature-001/`. Use the same shape as
  task-016: mechanical expectations as `## Checks` lines, and judgments as `## Expected outcome` or
  `## Must not` items.
- Create their fixtures under `tests/conversation/fixtures/`:
  - `001-15`: code, and no `.aid/knowledge/`;
  - `001-16`: a work whose tasks are all `Done`, in a project with no git remote;
  - `001-11` to `001-13`: the ticket is a file in the fixture, with `ref` a repo-relative path and
    `kind: ticket` (Q134, D9).
- Smoke run: each sample once, in a scratch copy, as in task-016.
- Suites to update in this same task: none.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-017`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-017: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-017`.
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
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] There are eight files with the spec's ids. `covers`: `001-09`, `001-10`, `001-15` and `001-16` AC-14; `001-11`, `001-12` and `001-13` AC-29; `001-14` AC-1.
- [ ] `001-11` has `contains` checks for the work's `sources:` entry and its closed `qa:` entries in the fixture's work `STATE.yml`. `001-15` has `## Expected outcome` items that Preparation is offered before any Specification question and that no KB file is written before the user agrees. `001-16` has a `contains` check for `lifecycle: Completed` and a `no-push` check.
- [ ] No `## Answer sheet` names a skill. `python3 tests/conversation/run.py --validate --feature 001` exits 0, and each sample has had one smoke run, with its result reported.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
