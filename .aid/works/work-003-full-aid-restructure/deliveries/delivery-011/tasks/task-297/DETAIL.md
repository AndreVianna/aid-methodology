# task-297: aid-test rewritten as an investigation, with its references

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 297 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-14, AC-30, AC-36

**Depends on:** task-293

**Scope:**
- Rewrite `canonical/skills/aid-test/SKILL.md`, at most 100 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`, `/aid-test`): the step table
  START, RUN, CHECK, PRESENT, FINISH with the spec's references, workers and advance words; the citations of
  task-294; the spec's `description:`; `argument-hint: "[<kind>] <what to check>"`; read-only on the project.
- Create `canonical/skills/aid-test/references/run.md`, `check.md`, `present.md`, `finish.md` and `reviewer-brief.md`,
  each at most 120 lines: RUN (what the kind names, never changing the project; the tool and command from the KB;
  raw output to `.aid/.temp/test/<work>/`; an experiment needing new code is a `/aid-create` work first); CHECK (one
  clean-context `aid-reviewer` pass, the ledger `.aid/.temp/review-pending/<work>-test.md`, the kind's `checks`, no
  grade, RUN again once for a finding with no evidence); PRESENT (chunks, the final-result approval, the `Findings`
  question); FINISH (`--handoff --to aid-monitor-pipeline --step START --returns no --phase CI --why 'test done'`,
  close mode `nothing`); the brief with `### What to report` (SS-13).
- Suites to update in this same task (Q106): `test-work-initiation-gate.sh` Group G drops `aid-test` (with its
  `STARTER_ALLOC_ANCHOR` and `STARTER_COVERAGE_ID` entries) and gains the check that `aid-test/SKILL.md` cites
  `action-start.md` and names no `worktree-lifecycle.sh create` of its own; `test-test-experiment-family-scaffold.sh`
  where it asserts `aid-test`'s body; `test-state-review-surface.sh`, whose glob finds the new brief; any suite the
  findings' Z1, Z5 or Z6 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-297`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-297.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-297`.
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
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] `SKILL.md` is at most 100 lines with the five steps; the five references exist, each at most 120 lines; `finish.md` names `aid-monitor-pipeline` and `--phase CI` (AS-05's `aid-test` clause); the brief has `### What to report`.
- [ ] Over `canonical/skills/aid-test/`, `git grep -nE 'git (commit|push|add)|worktree-lifecycle.sh create'` finds nothing.
- [ ] `test-work-initiation-gate.sh` and `test-state-review-surface.sh` pass where the test step puts them, and the site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
