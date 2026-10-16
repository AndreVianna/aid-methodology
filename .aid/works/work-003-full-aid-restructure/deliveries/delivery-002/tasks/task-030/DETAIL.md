# task-030: Work-initiation gate: --create in § 3a, the record in § 3b

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

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37

**Depends on:** task-023, task-025

**Scope:**
- Edit `canonical/aid/templates/work-initiation-gate.md` (REQUIREMENTS.md § 11 Feature 002 `##### 1. Files and layout` and
  `##### 2. Work state layout`, The work record):
  - § 3a NEW reads the type with `check-intent.md`, and runs `writeback-state.sh --create --work-dir ...
    --reading ... --request ... --skill ... --step ... [--phase] [--depth] [--path] [--minimum-grade]`
    before it hands the work back.
  - The hand-back carries the one line: "`STATE.yml` was created by the gate; skip any instruction to
    write `initiator`, `active_skill`, `lifecycle` or `phase` by hand; set other keys through the writer."
  - § 3b CONTINUATION gets the three-row resume table, `--check` with a confirmed `--repair`, and the
    legacy block between `<!-- legacy-phase-map: begin -->` and `<!-- legacy-phase-map: end -->`.
  - The same-invocation sentence goes.
- Suites to update in this same task: the existing `tests/canonical/test-work-initiation-gate.sh`
  assertions, and any suite the findings' P2, P3 or P8 assigns here. The per-row fixtures are task-047.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-030`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-030: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-030`.
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
- [ ] § 3a holds `writeback-state.sh --create` with `--reading`, `--skill` and `--step` (SS-14 (a)). § 3b's table has exactly the spec's three rows, first match wins.
- [ ] Old phase names appear in the file only between the legacy markers (SS-11 by hand), and SS-14 (d)'s pattern matches no line outside this file.
- [ ] `test-work-initiation-gate.sh` passes live.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
