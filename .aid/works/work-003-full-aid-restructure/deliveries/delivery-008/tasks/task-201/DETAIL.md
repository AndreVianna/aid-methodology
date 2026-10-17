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
  - **a nested work that also carries the flattened delivery keys (Q129): a copy of this work's real state** as
    it is when this task runs -- its `STATE.yml` byte for byte, with every top-level key (among them
    `pipeline.path` and `pipeline.initiator`, `tasks_lifecycle: {}`, `reviews`, `lifecycle_history`, `deploy: []`,
    `delivery_state`, `gate_*`, `delivery_lifecycle`, `delivery_gate`, `interview`, `features`, `review_history`,
    `qa`, `ticket_ref`), and its `deliveries/delivery-NNN/STATE.yml` and per-task `STATE.yml` files, with the
    delivery-008 file given a gate grade (as the resync will find it). A copy, committed as test data: the suite
    never reads the live work folder. Its expected result is written by hand from the spec: `tasks_lifecycle`
    filled once with every task's entry (never a second block); `deliveries` from the nested files, the delivery-008
    gate grade included; the flattened keys, `pipeline.path`, `interview`, `features` and `review_history` gone;
    every other key byte-identical; the per-task `dispatch_log` dropped, with a warning when it is not empty (Q138);
  - `ticket_ref` at each level; delivery `qa`; each legacy record row and the Q74 type rows; the named cases
    (an `aid-describe` work at `Detail`; `aid-design-api` and `aid-create-roadmap` works at `phase: Describe`;
    a halted `aid-refactor` work at `Detail`; `active_skill: aid-deploy` at `Execute`; a `--create`-made work at
    `Definition`); a duplicate task id; an unknown file;
  - every repository fixture starts at format 6 (PLAN.md Cross-Cutting Risks, row 5).
- Create `tests/canonical/lib/check-migrated-work.sh <work-dir> <pre-migration STATE.yml>`, which checks a migrated
  work against its own pre-migration file: no `deliveries/delivery-*/STATE.yml` and no per-task `STATE.yml` left;
  every task folder at `tasks/task-NNN/DETAIL.md` with exactly one `tasks_lifecycle` entry, and one
  `tasks_lifecycle` key in the file; one `deliveries` entry per delivery file, with its gate grade carried; none of
  the dropped keys; every other top-level key byte-identical to the pre-migration file. It exits 0, or 1 naming
  each difference. The resync session's dry run uses it (task-218's gate-session steps).
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
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
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
- [ ] The builder makes every case in a temporary folder and cleans up; each case has its expected tree on disk. The Q129 case's expected `STATE.yml` has exactly one `tasks_lifecycle` key holding every task, the delivery-008 gate grade in `deliveries.delivery-008`, none of the dropped keys, and every other top-level key byte-identical to the copied file.
- [ ] `check-migrated-work.sh` exits 0 on the Q129 case's expected tree against its copied file, and 1 naming the key on a scratch copy with `reviews` removed, with `tasks_lifecycle` duplicated, or with the gate grade dropped.
- [ ] The builder is deterministic (two runs build byte-identical fixtures) and needs no network.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
