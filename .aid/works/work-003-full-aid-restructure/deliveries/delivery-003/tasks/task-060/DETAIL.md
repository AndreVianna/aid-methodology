# task-060: Sweep: the design family

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

**Source:** feature-002-step-by-step-decisions -> delivery-003 -> AC-8, AC-37

**Depends on:** task-058

**Scope:**
- Apply the delivery-003 sweep conversions to this task's group only. The groups of task-060 to
  task-069 are disjoint.
  - **(a) Banners.** Remove every SS-01 form: `[State: X] -- ...` entry lines, "you are here" maps,
    "-> Advancing to [State: X]", "[State N] Dispatching ...", "[Resolved: ...]" and "Re-run `/aid-...`
    to continue" messages. `[State: X]` stays only as a target inside `**Advance:**` lines. Where a step
    starts long work, at most one plain progress line remains, with no step name (REQUIREMENTS.md § 11 Feature 002 `##### 4. Steps
    and hand-offs`, What the user sees).
  - **(b) Chaining citations.** Every citation of `state-machine-chaining.md` becomes
    `.aid/runtime/templates/skill-steps.md`.
  - **(c) Protocol line.** Every asking `SKILL.md` carries the line "Talking with the user: follow
    `.aid/runtime/templates/question-protocol.md`." Every `AskUserQuestion` leaves `allowed-tools` and
    the body; its question is asked in plain text by the protocol.
  - **(d) Question records.** Every question-record site writes through `writeback-state.sh --ask` /
    `--answer` to the work's `qa`, or with `--project` for setup skills. None names
    `## Cross-phase Q&A`, and none writes a delivery-level `qa` (KI-003, SS-06).
  - **(e) Interviewer.** Every interviewer mention is re-pointed: the main conversation asks the
    questions, through the protocol.
  - **(f) Review focus.** Every `references/reviewer-brief.md` in the group gains `### What to report`,
    with the spec's rule: only issues that affect the work; exact counts, word-for-word comparisons and
    cosmetic points are not findings (REQUIREMENTS.md § 11 Feature 002 `##### 4. Steps and hand-offs`, Review focus).
- Suites to update in this same task: every suite the findings' Q8 assigns to this group's files,
  including `tests/canonical/test-describe-full-only.sh` where it applies, and the site tests that read
  these skill bodies.
- **Group:** `canonical/aid/templates/design-lifecycle.md`, `canonical/skills/aid-design/`,
  `canonical/skills/aid-brainstorm/`, and the 21 `canonical/skills/aid-design-*/` skills.
- **Specific sites:** banners and the protocol line only.
- **Site regeneration.** Run `(cd site && npm run gen:skills && npm run gen:reference)` and commit its
  output: the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md` and
  `scripts/.skills-manifest.json`. Never edit a generated site file by hand.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites.md` assigns to `task-060`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-060: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-060`.
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
- [ ] Over this group's files, these each find nothing: the SS-01 banner forms, `state-machine-chaining`, `AskUserQuestion`, `## Cross-phase Q&A`, and `interviewer` (any case). The exception is a chaining citation the findings assign to task-074.
- [ ] Every asking `SKILL.md` in the group carries the protocol line (SS-04 by hand).
- [ ] (a) and (c) hold in all 24 files of the group.
- [ ] This group's suites pass where the test step puts them, and the site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
