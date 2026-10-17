# task-238: Format 6: the building part of the work-state step, in bash and PowerShell

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

**Source:** feature-007-building -> delivery-009 -> AC-25, AC-33

**Depends on:** task-220

**Scope:**
- The format-6 work-state step (Feature 006's) gains its building part, bash first and then its PowerShell twin,
  in this same task, byte-identical and idempotent (REQUIREMENTS.md § 11 Feature 007 `##### 7. Migration`, Format 6):
  - `tasks_lifecycle.*.review` -> `verify`; `quick_check` -> appended to `notes`; `gate_tier` -> `tier`,
    `gate_grade` -> `verify`; `gate_timestamp` goes; delivery `Executing` -> `Building`, `Gated` -> `Verifying`;
  - each `delivery-NNN-issues.md` appended to that delivery's `issue_list`, then deleted;
  - each `IMPEDIMENT-task-NNN.md` or `IMPEDIMENT-delivery-NNN.md` -> one `qa` entry (`category: Blocker`,
    `state: Pending`, `context` its description, `suggested` its recommendation), then deleted;
    `block_artifact` goes; a task's `Failed` state stays;
  - it runs on a repository already stamped format 6 (PLAN.md Cross-Cutting Risks, row 5);
  - **the building blocks a work lacks are added at their template defaults** (settled by rule, F007 § 7 is
    silent): `wave_stops` (`choice: --`, `planned: --`), `full_suite` (`command`, `baseline`, `baseline_commit`,
    `result`, `commit`, each `--`) and `feedback: []`, each only when absent, so a second run changes nothing and a
    block already present is kept as it is. A reader meeting a work without one of these blocks treats it as that
    template default: `/aid-execute` START (task-226) asks the wave question and records `baseline:
    not taken` for an old work, and the dashboard readers (task-239) pass the defaults.
- **This work's own state is a case to get right**: this delivery's resync runs the step on it, carrying every
  delivery's gate grade into its `verify` (PLAN.md Toolchain and Branching, step 3).
- `tests/windows/Test-AidInstaller.ps1` gains a building-step case (Q126).
- Files: as delivery-008's task-202. PowerShell 5.1-safe and ASCII.
- The unit cases are task-244.
- Suites to update in this same task: any migration suite or case the findings' X8 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-238`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-238: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-238`.
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
- [ ] On a scratch repository at format 6 holding a single-layout work with `review`, `quick_check`, `gate_grade`, an issues file and an impediment file, the step gives the expected `STATE.yml`, deletes both files, and a second run changes nothing.
- [ ] Under `pwsh`, the twin gives byte-identical files; `test-ps51-compat.sh` and `test-ascii-only.sh` pass live, and `test-aid-cli-parity.sh` passes in the scratch copy.
- [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).
- [ ] On a scratch single-layout work with no `wave_stops`, `full_suite` or `feedback` block (this work's shape after delivery-008's migration), the step adds the three blocks at their template defaults (`wave_stops.choice: --`, every `full_suite` field `--`, `feedback: []`); on a work that already holds them, with values, it leaves them byte-identical; a second run changes nothing.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
