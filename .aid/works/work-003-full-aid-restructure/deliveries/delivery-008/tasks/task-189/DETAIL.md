# task-189: derive-waves.sh --plan: the generated checklist

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

**Source:** feature-006-planning -> delivery-008 -> AC-19

**Depends on:** task-185

**Scope:**
- `canonical/aid/scripts/execute/derive-waves.sh` (REQUIREMENTS.md § 11 Feature 006 `##### 2. The plan and the task file`, Waves):
  - new `--plan <work-dir>`: reads every task file (id from its folder, delivery from Source, dependencies) and
    the work file's task states, and writes each delivery's checklist between its markers -- wave headings,
    then one line per task: checkbox (`[x]` when Done), `[task-NNN](tasks/task-NNN/DETAIL.md)`, title, type,
    `after:` and its state when neither `Pending` nor `Done` -- through a temporary file renamed into place; a
    byte-identical no-op when nothing changed;
  - the same Kahn sort per delivery; a dependency on an earlier delivery's task is met;
  - exits: 0 written or current; 2 a malformed graph (a cycle, an undefined task, a dependency on a later
    delivery's task) with the plan untouched; 3 no `PLAN.md`. `--plan <dir> --check` writes nothing: 0, 1, 2, 3;
  - a delivery with tasks and no stanza gets a bare `### delivery-NNN` heading and its checklist at the end;
  - **old plans**: on the first run in a stanza with no markers, the stanza's execution-graph section
    (`#### Execution Graph`, a sibling `### delivery-NNN Execution Graph` section, or an old lite plan's
    `## Execution Graph`) and its `wave-map` block are replaced with the checklist; authored lines are never
    rewritten;
  - the `<plan.md> [--write|--check]` table modes go; `--from-tasks` is unchanged; bash and awk only.
- **This work's own plan shape is a case to get right**: this delivery's resync migrates this work, and its
  gate runs `--plan --check` on its `PLAN.md` (PLAN.md delivery-008 gate). Its stanzas are `### delivery-NNN:
  Name`, each followed by a sibling `### delivery-NNN Execution Graph` section with a table and a `wave-map`
  block; its task Sources use the old form `feature-NNN-name -> delivery-NNN -> AC-N`.
- The unit cases are task-208.
- Suites to update in this same task: the existing `test-derive-waves.sh` assertions on the table modes,
  `test-executor-graph-flat-plan.sh`, and any suite the findings' L5 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md` assigns to `task-189`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-189: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-189`.
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
- [ ] On a scratch work with two deliveries, `--plan` writes both checklists, each task line's link resolves to its `DETAIL.md` from the plan's folder, and a second run is byte-identical; a dependency on a later delivery's task exits 2 with `PLAN.md` byte-identical.
- [ ] On a scratch copy of this work's `PLAN.md` and task files laid out at the work root (as the migration leaves them), `--plan` replaces each `### delivery-NNN Execution Graph` section and its `wave-map` with a checklist, keeps every authored stanza line, and `--plan --check` then exits 0.
- [ ] `--from-tasks` output on this work is byte-identical before and after the change, and the listed suites pass where the test step puts them.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
