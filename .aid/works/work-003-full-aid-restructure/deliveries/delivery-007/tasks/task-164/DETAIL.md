# task-164: Work-state keys reviews and effort_check, and the writer's --review and Effort Check

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

**Source:** feature-005-specification -> delivery-007 -> AC-12, AC-44

**Depends on:** task-161

**Scope:**
- `canonical/aid/templates/work-state-template.yml` (REQUIREMENTS.md § 11 Feature 005 `##### 4. Work state`): `interview` (with its ten
  `sections`), `features` and `review_history` go, with their comments; `reviews: []` and
  `effort_check: --` come, each with its `[W]` comment, in block style.
- `canonical/aid/scripts/execute/writeback-state.sh`:
  - `--review --grade G --notes T` without `--kb` appends an entry (`at`, `grade`, `by` = the saved
    `active_skill`, `notes`) to the work's `STATE.yml` `reviews`, resolved like every work write;
  - when the work file has no `reviews` key, the same write adds it, block style, at the top level (Q130);
  - same grade validation (exit 4), lock and atomic rename; `--kb --review` is unchanged;
  - `--pipeline --field "Effort Check"` writes `effort_check`, accepting `--`, `unknown` or a level name of
    lowercase letters; anything else exits 4.
- Both dashboard readers parse the template with no warning (SS-08). They ignore keys they do not show.
- The unit cases are task-175.
- Suites to update in this same task: `test-work-state-template.sh` (WS21 and WS22 go; one assertion each
  for `reviews: []` and `effort_check: --` with their `[W]` comments), the existing `test-writeback-state.sh`
  assertions, `test-skill-steps.sh` SS-08 where it reads the template, and any suite the findings' P3 or P8
  assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-007-sites.md` assigns to `task-164`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-164: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-164`.
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
- [ ] The template has no `interview:`, `features:` or `review_history:` key, and has `reviews: []` and `effort_check: --`, each with its `[W]` comment (SP-06's template clause).
- [ ] On a scratch work file with no `reviews` key, `--review --grade A --notes x` adds the key with one entry whose `by` is the saved skill; `--grade Z` exits 4 with the file byte-identical; `--pipeline --field "Effort Check" --value High` exits 4.
- [ ] `test-work-state-template.sh` and `test-writeback-state.sh` pass where the test step puts them, and `test-skill-steps.sh` SS-08 passes in the scratch copy.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
