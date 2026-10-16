# task-202: Format 6 work-state step, part 1: the layout conversion, in bash and PowerShell

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

**Source:** feature-006-planning -> delivery-008 -> AC-19, AC-25

**Depends on:** task-188, task-201

**Scope:**
- `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the work-state step's layout part, run
  after `migrate-work-hierarchy.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 8. Migration`, Format 6), over every work `STATE.yml` in the
  main folder and in each worktree `git worktree list` registers:
  - **nested works**: each `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` moves to `tasks/task-NNN/DETAIL.md`
    (a task id found twice stops the step for that work, with a warning and nothing changed); task cells become
    `tasks_lifecycle.task-NNN` (with `quick_check` as one text value); delivery cells become
    `deliveries.delivery-NNN` (`Pending-Spec` and `Specified` -> `Pending`; `delivery_gate.issue_list` -> one
    text value); a per-task `dispatch_log`, which the spec's `tasks_lifecycle` shape does not carry, is dropped,
    with a warning when it is not empty (proposal F-1, pending the maintainer's confirmation); each delivery's `qa` is appended to the work's `qa` under the next free ids, its `context`
    opening with the old place; the per-unit state files are deleted, then the folders left empty; an unknown
    file is kept, with a warning;
  - **old lite works**: the flattened keys become `deliveries.delivery-001`;
  - **a nested work that also carries the flattened keys** (Q129): the nested data wins; the flattened keys are
    dropped and never mapped.
  - Bash first, then its PowerShell twin, in this same task: the twins are never split across tasks
    (delivery-005 S3), so parity holds at this task's end.
- `tests/windows/Test-AidInstaller.ps1` gains a case for this part (Q126).
- Files: `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, whichever hold the step.
  Byte-identical, PowerShell 5.1-safe and ASCII.
- Suites to update in this same task: `test-aid-migrate.sh`, `test-migrate-hierarchy.sh` and any suite or case
  the findings' L7 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md` assigns to `task-202`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-202: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-202`.
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
- [ ] On task-201's nested, old lite and Q129 fixtures, the bash step's tree equals the expected tree, and a second run changes nothing (`sha256sum` of every file unchanged).
- [ ] Under `pwsh`, the PowerShell twin gives byte-identical trees for the same fixtures; `test-ps51-compat.sh` and `test-ascii-only.sh` pass live, and `test-aid-cli-parity.sh` passes in the scratch copy.
- [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).
- [ ] On the Q129 fixture (this work's real state), `check-migrated-work.sh` exits 0 on the migrated tree: `tasks_lifecycle` filled once, every key outside the drop list byte-identical, the delivery-008 gate grade carried.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
