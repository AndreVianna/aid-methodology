# task-016: Feature 001 samples 001-01 to 001-08: reading and matching a request

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-21

**Depends on:** task-004, task-005, task-010

**Scope:**
- Create `tests/conversation/samples/feature-001/` with `001-01-one-match.md`, `001-02-several-decide.md`,
  `001-03-several-ask.md`, `001-04-no-match.md`, `001-05-project-question.md`, `001-06-kb-conflict.md`,
  `001-07-rich-ticket.md` and `001-08-bare-idea.md`, plus any extra fixture under
  `tests/conversation/fixtures/` they need.
  - Each has frontmatter `id`, `covers` and `fixture`.
  - Each has the sections `## User`, `## Answer sheet`, `## Expected outcome`, `## Must not` and
    `## Checks`, in `run.py`'s check grammar.
- Smoke run (Q134, D8): run each sample once with `python3 tests/conversation/run.py --feature 001
  --sample <id> --runs 1`, inside a scratch copy made as the test step says, after its generator.
  - Fix any failure caused by the sample.
  - Report any failure caused by the product; do not hide it.
  - The 3-of-3 runs belong to the gate.
- Suites to update in this same task: none.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-016`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-016: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-016`.
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
- [ ] There are eight files with the spec's ids. Each `covers` equals REQUIREMENTS.md § 11 Feature 001 Criteria traceability: `001-01` AC-1; `001-02` and `001-03` AC-2; `001-04` AC-3; `001-05` AC-4; `001-06` AC-5; `001-07` AC-7 and AC-21; `001-08` AC-7.
- [ ] `001-05`'s checks assert that no new `.aid/works/` folder exists and that the answer cites sources. `001-07`'s checks assert a `Skill` call the agent made itself and one approval before building.
- [ ] No `## Answer sheet` names a skill, and no sample needs a network or a live tracker. Each sample's checks give the same verdict on a re-run of the same transcript.
- [ ] Each sample has had one smoke run, and the report lists each sample's result and the cause of any failure.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
