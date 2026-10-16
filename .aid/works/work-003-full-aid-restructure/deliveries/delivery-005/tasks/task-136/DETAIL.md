# task-136: KB decisions, schemas, glossary, quality gates, tech debt and backlog for the KB skills

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

**Type:** DOCUMENT

**Source:** feature-004-kb-management -> delivery-005 -> AC-15, AC-24

**Depends on:** task-110, task-118, task-131, task-132

**Scope:**
- Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, KB and Release notes), for
  this delivery's part:
  - `decisions.md`: the new decision "the Knowledge Base keeps itself current: four skills, writes only
    inside works, a script-rendered view". It amends D18 and D28's consequence, both marked;
  - `artifact-schemas.md`: the KB state file, `kb_updates` and the view;
  - `domain-glossary.md`: Preparation, KB build, update, query, show, web view and drift; summarize,
    housekeep and the KB `STATE.md` vocabulary go;
  - `quality-gates.md`: the two-grade view rubric goes;
  - `tech-debt.md`: L6, SY-7, the index half of W4-5 (timestamps in `INDEX.md`) and the view half of W1-11
    are resolved (G-03). W4-5's baseline half stays open until delivery-006's format-6 baselines step
    (task-158 resolves it). SY-1 moves with
    `cleanup-classify.sh`;
  - `backlog.md` § Next Release: the old -> new rows for `/aid-discover`, `/aid-ask`, `/aid-update-kb`,
    `/aid-summarize` and `/aid-housekeep` (AC-24).
- The `create`/`update` rows, `roadmap.md` and the `authoring-conventions.md` `state` row are
  delivery-006's (proposal S6).
- Name no work and no work folder.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md` assigns to `task-136`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-136: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-136`.
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
- [ ] The five backlog rows carry the spec's New text, and D18 and D28 are marked in the summary table and in their sections.
- [ ] L6 and SY-7 leave no trace, and W4-5 states only its baseline half (no KB document carries `approved_at_commit:`). No work id, and the citation and frontmatter lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
