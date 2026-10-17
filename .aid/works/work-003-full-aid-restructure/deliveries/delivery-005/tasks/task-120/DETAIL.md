# task-120: Format 6: the KB conversion step, in bash and PowerShell

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

**Source:** feature-004-kb-management -> delivery-005 -> AC-25

**Depends on:** task-112

**Scope:**
- `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the KB step of
  REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`. It runs when `.aid/knowledge/STATE.md` exists and `STATE.yml` does not:
  - **Frontmatter:**
    - `kb_status` becomes `status`: `Approved` stays; anything else becomes `Building` with
      `active_skill: aid-kb-build` and `step: START`;
    - `kb_grade` becomes `grade`;
    - the approval line becomes `user_approved`.
  - **Sections:**
    - Domain, Triage and Elicitation become `domain`, `triage` and `elicitation`;
    - Documents Status rows become `documents`, and Review History rows become `reviews`;
    - each `### Q<N>` becomes a `qa` entry (`Required` becomes `High`).
  - An `Approved` KB gets `active_skill: none` and `step: --`.
  - The summary sections, spot-checks and calibration log are dropped.
  - `STATE.yml` is written and `STATE.md` deleted. A re-run changes nothing.
- The baselines and parent-branch steps are delivery-006's.
- Files: `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, whichever hold
  the step.
- `tests/windows/Test-AidInstaller.ps1` gains a KB-step case (Q126). Bash and PowerShell output are
  byte-identical, PowerShell 5.1-safe and ASCII.
- The unit suite is task-127.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md` assigns to `task-120`.
- **The KB README follows the conversion (G17 applied to the KB step).** `.aid/knowledge/README.md` cites
  `.aid/knowledge/STATE.md` in its `sources:` and `see_also:`. From this task on, the scratch copy's own migration
  converts the copy's `STATE.md`, so in this same task those two entries name `.aid/knowledge/STATE.yml`
  (`see_also: [INDEX.md, STATE.yml]`). Only the frontmatter changes here; the prose is task-137's. AD14 then holds
  wherever the test step runs `test-artifact-discipline.sh` (the scratch copy), and in the live tree after the
  delivery's resync. The KB lines are committed as the delivery commits KB paths (through `kb-commit.sh` once it
  exists).
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-120: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-120`.
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
- [ ] Converting a scratch copy of this repository's `.aid/knowledge/STATE.md` gives a `STATE.yml` that parses through both readers with no warning, and a second run changes nothing (`sha256sum` unchanged).
- [ ] Bash and PowerShell give byte-identical `STATE.yml` for the same fixture under `pwsh`, and `test-ps51-compat.sh` and `test-ascii-only.sh` pass.
- [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).
- [ ] `.aid/knowledge/README.md`'s `sources:` and `see_also:` name `STATE.yml` and not `STATE.md`, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
