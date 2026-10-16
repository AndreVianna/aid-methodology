# task-201: Format 6 work-state step: fixtures and expected results, written first

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

**Source:** feature-006-planning -> delivery-008 -> AC-19, AC-25

**Depends on:** task-187

**Scope:**
- Create `tests/canonical/lib/work-state-migration-fixtures.sh` (sourced, not run by `run-all.sh`), which builds
  each case of REQUIREMENTS.md § 11 Feature 006 `##### 9. Testing` (`test-work-state-migration.sh`) in a temporary main folder with a
  registered worktree, and the expected file and tree for each, under `tests/canonical/fixtures/work-state-migration/`:
  - a nested work; an old lite work; a single-layout work;
  - **a nested work that also carries the flattened delivery keys (Q129)**, shaped like this work's own
    `STATE.yml`: `pipeline.path: full`, the top-level `delivery_state`, `gate_*`, `delivery_lifecycle` and
    `delivery_gate`, `interview`, `features` and `review_history`, a top-level `qa`, `ticket_ref: --` at every
    level, phase `Execute` and `active_skill: aid-execute`, and per-task `STATE.yml` files with `quick_check`
    and `dispatch_log` (its expected result follows proposal F-1);
  - `ticket_ref` at each level; delivery `qa`; each legacy record row and the Q74 type rows; the named cases
    (an `aid-describe` work at `Detail`; `aid-design-api` and `aid-create-roadmap` works at `phase: Describe`;
    a halted `aid-refactor` work at `Detail`; `active_skill: aid-deploy` at `Execute`; a `--create`-made work at
    `Definition`); a duplicate task id; an unknown file;
  - every repository fixture starts at format 6 (PLAN.md Cross-Cutting Risks, row 5).
- The suite that runs them is task-210.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md` assigns to `task-201`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-201: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-201`.
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
- [ ] The builder makes every case in a temporary folder and cleans up; each case has its expected tree on disk, and the Q129 case's expected `STATE.yml` keeps the nested delivery data and has none of the flattened keys.
- [ ] The builder is deterministic (two runs build byte-identical fixtures) and needs no network.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
