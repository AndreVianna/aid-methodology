# task-167: aid-specify references: DESIGN, CHECK and the reviewer brief

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

**Source:** feature-005-specification -> delivery-007 -> AC-16, AC-44

**Depends on:** task-163, task-164

**Scope:**
- Create in `canonical/skills/aid-specify/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 3. Flow`, steps 4-5, and the Fix route):
  - `design.md`: the technical part drafted once for the work, or feature by feature in id order; research
    fanned out to `aid-researcher`; a `WAIT` for an investigation only the user can make (today's SPIKE) and
    an open question for a pending answer (today's BLOCKED); real forks asked in plain words, the rest
    recorded `Assumed`; `known-issues-scope.md`'s filter moved here unchanged; the optional-section list as
    prompts, not headings; a KB conflict raised with the user; a kind's `shape` points settled in Data and
    interfaces;
  - `check.md`: one graded `aid-reviewer` pass over the whole document, ledger
    `.aid/.temp/review-pending/<work>-specify.md`; what it reports; the cross-document contradiction pass
    (Guard 2) on cycle 1, once per work; `grade.sh` and `--review`; the Fix route; after three rounds below
    the bar, one question per open row -- fix, accept (ledger status `Accepted`, the choice in Evidence), or
    keep reviewing (Q69); nothing goes on to APPROVE unless the grade passes or every open row is accepted.
- Rewrite `references/reviewer-brief.md` for the whole-document pass, with `### What to report` (FR-21,
  SS-13).
- The Guard 2 site table in `reviewer-dispatch.md` is task-171's.
- Suites to update in this same task: `test-scoped-review-cycles.sh`, because `check.md` is the first
  `aid-specify` reference to name Guard 2 and today's SC11 fails on that. SC10's three sites become
  `aid-specify/references/check.md`, `aid-plan/references/review-deliverables.md` and
  `aid-detail/references/review.md`; SC11 now asserts that `aid-specify` invokes the pass in `check.md` and in
  no other reference (REQUIREMENTS.md § 11 Feature 005 `##### 7. Migration`, Suites). Also any suite the findings' P5 or P8 assigns to
  these files.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-007-sites.md` assigns to `task-167`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-167: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-167`.
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
- [ ] `design.md` and `check.md` exist, each at most 120 lines. `check.md` names fix, accept and keep reviewing, the status `Accepted`, `<work>-specify.md` and Guard 2 (SP-03's `check.md` clause).
- [ ] `reviewer-brief.md` has `### What to report`, SS-13 passes where the test step puts it, and `test-scoped-review-cycles.sh` passes live with SC10 and SC11 as the spec states them.
- [ ] The site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
