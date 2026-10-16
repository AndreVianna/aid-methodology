# task-233: aid-execute SKILL.md rewritten, and its seven old references deleted

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

**Source:** feature-007-building -> delivery-009 -> AC-26, AC-32, AC-33, AC-34

**Depends on:** task-220, task-226, task-227, task-228, task-229, task-230

**Scope:**
- Rewrite `canonical/skills/aid-execute/SKILL.md`, at most 120 lines (REQUIREMENTS.md § 11 Feature 007 `##### 1. Files and layout` and
  `##### 2. Flow`): the step table START, BUILD, TEST, VERIFY, SIMPLIFY, REVERIFY, NEXT, DELIVERY, FINAL,
  MILESTONE and FINISH pointing at the new references; `skill-steps.md` and `question-protocol.md` cited; the
  spec's `description:` and `argument-hint`; the plan-mode check as one line; the control signals. Gone: Check 1's
  work listing and worktree entry, the layout detection and full/flat branches, Check 5's per-delivery branches,
  the state map and banners, `## Delivery Lifecycle` with "merge to main", the pool, `## Impediments`,
  `## Ticket Suggestion`, the quality checklist.
- Delete `references/state-execute.md`, `state-execute-drilldown.md`, `state-review.md`, `state-fix.md`,
  `state-re-run.md`, `state-delivery-gate.md` and `reviewer-guide.md`.
- **Lists and counts**: the `/aid-execute` line of the skill guide with the spec's text; `aid-execute`'s SG-04
  row, if any; the `aid-execute` row (`PL-04`, owner Feature 007) of `tests/canonical/skill-steps-exempt.tsv`; the
  site skill lists and flows and their `__tests__`.
- Suites to update in this same task (the spec's hit list, `##### 7. Migration`, Suites):
  `test-pipeline-status-walkthrough.sh` (A1 to `references/start.md`, phase `Building`; A3's impediment fixture
  a `Blocker` question; M4's `aid-execute` row and its B1 check, B2's delivery-gate checks, B4e and B4f retired;
  B3 rewritten over `blocker.md`; B4a and B4b's emit-file list), `test-ticket-retirement-structural.sh`
  (`STATE_EXECUTE` becomes `references/build.md`; T037-T039 hold there; T040 asserts `build.md`'s `In Progress`
  write), `test-compute-block-radius.sh` (T17 retired), `test-task-state-transitions.sh` (its header and mandate
  name `build.md`), `test-scoped-review-cycles.sh` (the SW01-SW04 comment names `fix.md`), PL-04 of `test-plan.sh`
  (the exempt row gone), `test-downstream-worktree-entry.sh` (its `aid-execute` assertions -- G0-G4 and Group 7 --
  go with the worktree entry this rewrite removes, G11), and any suite the findings' X1 or X8 assigns here.
- **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
  build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
  list does not come from the findings' map alone. Every suite it finds is updated in this same task
  (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
  criterion is scoped so it holds without the row.
- **KB `sources:` citations (G17).** Every `.aid/knowledge/` document whose frontmatter `sources:` cites a file or
  folder this task deletes, moves or renames is fixed in this same task (`git grep -n -e '<path>' -e '<folder>/' --
  .aid/knowledge/` at this task's base): the entry follows a moved file, and goes when the file is gone. Only the
  `sources:` entries change here; the prose stays for the delivery's DOCUMENT task. So `test-artifact-discipline.sh`
  AD14 (every `sources:` citation resolves) holds at this task's end. The KB lines are committed as the delivery
  commits KB paths (through `kb-commit.sh` once it exists, as Feature 007's BUILD requires).
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-233`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-233: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-233`.
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
- [ ] `SKILL.md` is at most 120 lines with the eleven steps, FINISH advancing by `PASS`; none of the seven old references exists, and the thirteen new ones and the brief do (EX-01's reference clauses, EX-02's table clause).
- [ ] Over `canonical/skills/aid-execute/`, `git grep -nE 'worktree add|checkout -b|switch -c|run_in_background|max_parallel_tasks|merge to main'` finds nothing, and a delivery *branch* is named only in `old-work.md` (EX-03): `git grep -nE 'aid/[^ ]*-delivery-|(checkout -b|switch -c|branch) [^ ]*-delivery-'` over the skill finds hits only in `old-work.md`. The writer's `--delivery-id` and the delivery ledger name `<work>-delivery-NNN.md` are not branch names and stay allowed.
- [ ] `skill-steps-exempt.tsv` has no `aid-execute` row and PL-04 passes; SG-02, SG-04 and the listed suites pass where the test step puts them, and the site `npm test` passes after regeneration.
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
