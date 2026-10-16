# task-036: The KB-writing aid-create-* and aid-update-* family on the step rules

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

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37

**Depends on:** task-023, task-025, task-030

**Scope:**
- Apply the stanza-wave-4 sweep conversions to this task's group only. The groups of task-034 to
  task-044 are disjoint.
  - **(a) Citation.** Every `SKILL.md` with a Dispatch table or a `## State:` section cites
    `.aid/runtime/templates/skill-steps.md` (SS-02).
  - **(b) Advance words.** Every `**Advance:**` word is translated one for one:
    - `PAUSE-FOR-USER-DECISION` becomes `ASK` and keeps its step ("Re-run `/aid-<skill>` to continue to
      [State: X]" becomes `ASK` -> [State: X]);
    - `PAUSE-FOR-USER-ACTION` becomes `WAIT`;
    - a pause that points at another skill becomes `ASK` then `HALT`, naming that skill in one line.
    There are no new `PASS` or `CALL` edges (SS-03).
  - **(c) State Detection.** Every § State Detection, or its equivalent, carries `skill-steps.md`'s
    standard rule: it shapes the entry step of a fresh start, validates a saved step on resume, and never
    routes.
  - **(d) Group-specific sites,** listed below.
  - **Out of scope here:** banners, the chaining file, the protocol line, question-record sites and the
    interviewer. Those are delivery-003's.
- Suites to update in this same task: every suite the findings' P8 or P9 assigns to this group's files,
  including the site tests that read these skill bodies.
- **Group:** `canonical/skills/aid-create-*/` and `aid-update-*/` for `architecture`, `backlog`, `cicd`,
  `mvp`, `roadmap`, `stack` and `testing-strategy`.
- **(d):** none. Their binding lines and finishes stay (exempt; Feature 004).
- **Site regeneration.** Run `(cd site && npm run gen:skills && npm run gen:reference)` and commit its
  output: the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md` and
  `scripts/.skills-manifest.json`. Never edit a generated site file by hand.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-036`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-036: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-036`.
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
     - Run `(cd site && npm test)` when this task changes `canonical/skills/`,
       `canonical/aid/templates/shortcut-catalog.yml`, `docs/` or `site/`. Run `npm ci` there first if
       `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] Over this group's files, `grep -c 'PAUSE-FOR-USER'` prints 0, and every `**Advance:**` word is one of `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL` or `HALT` (SS-03 by hand).
- [ ] Every `SKILL.md` in the group with a Dispatch table or a `## State:` section names `skill-steps.md` (SS-02 by hand).
- [ ] The SS-11, SS-12 and SS-14 (b)/(d) patterns, run by hand over the group's files, match only lines inside legacy markers or in files on the shared exempt list.
- [ ] (a) to (c) hold in all 14 skills.
- [ ] This group's suites pass where the test step puts them, and the site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
