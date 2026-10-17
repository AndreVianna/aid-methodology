# task-020: Delivery-002 site search and reconciled edit list

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

**Type:** RESEARCH

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-11, AC-37, AC-41

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md`. Touch nothing else.
- Re-run the searches of PLAN.md's delivery-002 stanza, wave 1, at this task's base commit, and record
  the base commit in the file. The scope is REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing`.
  - **P1** SS-11's forms over SS-11's scope. The spec says 55 lines today.
  - **P2** SS-14 (b): `initiator:`, copying the template, hand-written record blocks.
  - **P3** SS-14 (d): continuation lines.
  - **P4** SS-12: a hand-written `lifecycle: Completed` / `Canceled`.
  - **P5** SS-03: every `PAUSE-FOR-USER` line and every `**Advance:**` word.
  - **P6** SS-02: every `SKILL.md` with a Dispatch table or a `## State:` section.
  - **P7** NM-01 to NM-04 over NM's include and exclude globs.
  - **P8** The Q106 map. For every file on the delivery's edit list, list the suites that read it by
    path or assert its text, in `tests/`, `site/scripts/__tests__/`, `dashboard/reader/tests/` and
    `dashboard/server/tests/`.
  - **P9** The suites and tests that feed an old phase name to a writer, or assert a reader's phase
    output. This follows REQUIREMENTS.md § 11 Feature 002 `##### 2. Work state layout`, the Tests rule.
  - **P10** Whether today's writes in `canonical/aid/scripts/execute/writeback-state.sh` are already
    atomic (a temporary copy renamed under the lock).
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
  `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
  renames it, which fixes the entry in the same task (AD14).
- **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
  skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
- Give each hit exactly one owner: a task of delivery-002 (task-021 to task-057; see
  each task's `DETAIL.md` under `.aid/works/work-003-full-aid-restructure/deliveries/delivery-002/tasks/` -- the proposal file is superseded by the task files), "installed copy
  (resync)", or "history, left as is".
- In a delta section, list:
  - every difference from the spec's own statements;
  - every suite assigned to two tasks that do not depend on each other, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-020: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-020`.
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
- [ ] Each of P1-P10 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] The P1 count and the P2 and P3 matches are compared with the spec's statements ("55 lines"; "every file (b) matches is in Files and layout"; "(d) matches exactly the continuation lines listed"). Each difference is listed with its owner.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0. Every suite assigned to two independent tasks is listed, with the order to run them.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden: the spec fixes the searches, so there are no alternatives to compare, and the recorded commands are the sources. The test step runs no suite, because every change lies under `.aid/works/` (its work-folder-only rule).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
