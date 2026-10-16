# task-166: aid-specify references: START, the effort check, REQUIREMENTS and FEATURES

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

**Source:** feature-005-specification -> delivery-007 -> AC-12, AC-16, AC-28

**Depends on:** task-162, task-163, task-164

**Scope:**
- Create in `canonical/skills/aid-specify/references/`, each at most 120 lines (REQUIREMENTS.md § 11 Feature 005 `##### 3. Flow`, steps 1-3, and `##### 5. Components`,
  Effort check):
  - `start.md`: what START reads (the record, the idea draft and `draft` sources through
    `idea-drafts.sh path`, the draft's open questions and `## Kind` with its `shape` points, `sources:`, the
    open `qa` first, the KB through `INDEX.md`); the effort check while `effort_check` is `--`; the tracker
    read seam moved from `state-initialize.md` Step 3b with its wording ("Skip silently when no such ticket
    applies or no matching connector is catalogued"); what is already on disk is kept; `REQUIREMENTS.md`
    created from `requirements.md` when absent; a change after Specification goes straight to REVISE;
  - `effort-check.md`: one row per tool, filled from task-162's findings; the high-or-above, below-high and
    "cannot be read" paths with the spec's wording; `effort_check` written before any question it asks; the
    agent only reads, never writes a tool setting;
  - `requirements.md`: the business part, drafted by `aid-architect` in a clean context and never asking the
    user; the open points asked by subject under the question protocol; "ask only what blocks" (Q65); every
    criterion names an observable; the one-line reading when Specification is the first phase;
  - `features.md`: the split rule; no split asks nothing; a split is one question, and in `lite` first
    re-routes to `full` with `--reroute`; the business checkpoint in `full`, recorded `covers: requirements
    business part`; in a fix, only the split question.
- `SKILL.md` and the old references stay until task-170 points the step table at these files.
- Suites to update in this same task: any suite the findings' P8 assigns to these new files.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-007-sites.md` assigns to `task-166`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-166: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-166`.
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
- [ ] The four files exist, each at most 120 lines. `start.md` cites `effort-check.md` and holds the read seam's silent-skip sentence verbatim.
- [ ] `effort-check.md` has a row for each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI and states the "cannot be read" path; `git grep -n effort-check -- canonical/skills/aid-kb-build` finds nothing (SP-04).
- [ ] `features.md` names `--reroute` and `covers: requirements business part`. The site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
