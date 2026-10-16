# task-007: Work sources in the skills, and the ticket attachment part

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-29

**Depends on:** task-003

**Scope:**
- `canonical/aid/templates/connectors/consumption-protocol.md`: rewrite § Multi-level `ticket_ref`
  linkage for the one work-level `sources:` list, as REQUIREMENTS.md § 11 Feature 001
  `##### 4. External sources` says.
- Rewrite the other `ticket_ref` sites to write or read a `sources:` entry instead:
  - `canonical/aid/templates/shortcut-engine.md`;
  - `canonical/skills/aid-specify/references/state-initialize.md` Step 3b;
  - `canonical/skills/aid-plan/references/first-run-loop.md`;
  - `canonical/skills/aid-describe/references/state-first-run.md`.
- `canonical/skills/aid-update-ticket/SKILL.md`:
  - the closed part enum becomes `description | comment | status | attachment`, in the usage line, the
    `argument-hint` and `description:`;
  - `attachment` gets its LOAD-CONTEXT, preview and confirm for the files the user picks;
  - on a tool limit, it stops, tells the user and offers the workable options with a recommendation. It
    never picks a workaround itself.
- Suites to update in this same task:
  - `tests/canonical/test-connector-consumption-linkage.sh`;
  - `tests/canonical/test-ticket-retirement-structural.sh` T073, T091 and its skill-site assertions;
  - `tests/canonical/test-ticket-skills-structural.sh` (the part enum);
  - any suite the findings' S3 or S6 assigns here.
- **Site regeneration.** Run `(cd site && npm run gen:skills && npm run gen:reference)` and commit its
  output: the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md` and
  `scripts/.skills-manifest.json`. Never edit a generated site file by hand.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-007`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-007: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-007`.
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
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `git grep -n ticket_ref -- canonical/` finds nothing, which completes the gate's AC-29 template criterion with task-003. `git grep -l ticket_ref -- site/src/data/skill-flows/` finds nothing after regeneration.
- [ ] `aid-update-ticket`'s enum reads `description | comment | status | attachment` everywhere it appears. The attachment path names the picked files, previews, confirms, and on a tool limit stops and offers options with a recommendation (AC-29).
- [ ] The rewritten consumption-protocol section states the `sources:` entry fields `ref`, `kind`, `added`, `phase` and `effect`, and the top-level `write_backs:` entry fields `at`, `source`, `part` and `files`, matching Feature 001 `##### 4. External sources`.
- [ ] `test-connector-consumption-linkage.sh` and `test-ticket-skills-structural.sh` pass live, `test-ticket-retirement-structural.sh` passes in the scratch copy, and the site `npm test` passes.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
