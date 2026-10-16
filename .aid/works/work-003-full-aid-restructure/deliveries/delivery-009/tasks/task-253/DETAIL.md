# task-253: KB test landscape for the building suites, the regenerated index and the view

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

**Source:** feature-007-building -> delivery-009 -> AC-25, AC-26

**Depends on:** task-241, task-243, task-244, task-245, task-249, task-250, task-251, task-252

**Scope:**
- `.aid/knowledge/test-landscape.md`: `test-execute.sh` and `test-simplify-guard.sh` and their lane; the new
  cases of `test-writeback-state.sh`, `test-derive-waves.sh`, `test-complexity-score.sh`,
  `test-compute-block-radius.sh` and `test-work-state-migration.sh`; the retired `test-delivery-gate-aggregate.sh`
  and `test-disjoint-merge.sh` go.
- Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync
  migrates this work's state, not the KB.
- Name no work and no work folder.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-009-sites.md` assigns to `task-253`.
- **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
  them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
  except the resync itself.
  1. **Resync session:** the resync (`delivery-009: resync`), committed alone: it installs the new `/aid-execute`,
     the Feature 007 writer and `simplify-guard.sh`, and runs format 6's building part on this work (every delivery's
     gate grade into its `verify`). Then the session ends.
  2. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
     `--plan` when it reports stale; then `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated page (`reference/settings.md`
    from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB is not changed by this resync.
  3. **The gate:** the stanza's criteria, the samples, G0 with the baselines, and the tracking proof for task-219
     to task-253 (the work `STATE.yml`'s state-only commits and its `reviews`). A fix after this resync records its
     grade with `--delivery-id 009 --field Verify`; no lifecycle is written.
  4. **The switch** (Q123, Q124): `--check`, then `--repair --skill aid-execute --name START --reading change`;
     `Verify` and `Commit` for deliveries 001-009 with `--delivery-id NNN --field`; then the one approval through
     `--ask` and `--answer`, `covers: delivery delivery-001; ...; delivery delivery-009; confirmation before
     building`, `commit` the head.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-253: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-253`.
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
- [ ] `test-landscape.md` names both new suites and their lane, and neither retired suite.
- [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
