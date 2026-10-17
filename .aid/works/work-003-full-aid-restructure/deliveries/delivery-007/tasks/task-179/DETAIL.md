# task-179: Samples 005-06 to 005-10 (run at this gate), and the deferred rows that now run

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

**Source:** feature-005-specification -> delivery-007 -> AC-9, AC-10, AC-15, AC-37, AC-44

**Depends on:** task-169, task-172, task-174, task-178

**Scope:**
- Create under `tests/conversation/samples/feature-005/`, with frontmatter `skills: aid-specify`, their
  fixtures and the checks of REQUIREMENTS.md § 11 Feature 005 `##### 8. Testing`: `005-06-full-two-checkpoints`,
  `005-07-lite-ticket-no-stop`, `005-08-decision-to-kb` (both runs), `005-09-change-requirement-later` (both
  runs) and `005-10-old-define-work`.
- Update `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Lists other features own):
  - the `skill:aid-specify` row goes, since `005-01` and `005-04` cover it;
  - the rows of `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09` and `004-10` go: they run at this
    gate;
  - `002-07` waits only for Feature 007, and `002-08` and `002-09` for Features 006 and 007.
- Smoke run (Q134 D8): each new sample once, and each sample whose row goes once, in a scratch copy.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-007-sites.md` assigns to `task-179`.
- **Checks and judgments (task-004's grammar).** A `## Checks` line is a file check on the fixture (`exists`,
  `absent`, `contains`, `no-new-dir`, `no-push`) or a transcript check (`tool-called`, `tool-not-called`). How the
  conversation went -- the order and count of questions, what the agent says, that nothing is written before a
  yes -- is an `## Expected outcome` or `## Must not` item, which the judge rules on. This task does not extend
  `run.py`.
- **Re-run samples of this gate.** `001-08` and `001-09` pass again at this gate (PLAN.md delivery-007 Gate
  Criteria). Each is read against the flow this delivery changes -- its answer sheet, `## Expected outcome`,
  `## Must not` and `## Checks` -- and brought in line in this same task where the flow moved; then each gets one
  smoke run with the others.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-179: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-179`.
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
- [ ] There are five new files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill.
- [ ] DT-01 and SS-09 pass, with no `skill:aid-specify` row and none of the seven rows left.
- [ ] Each smoke run has its result reported.
- [ ] The re-run samples `001-08` and `001-09` have had one smoke run each, with the result reported, and `run.py --validate` exits 0 for feature 001.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
