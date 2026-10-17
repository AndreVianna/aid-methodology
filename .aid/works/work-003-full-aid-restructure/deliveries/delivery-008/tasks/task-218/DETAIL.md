# task-218: KB test landscape for the plan suites, the regenerated index and the view

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

**Source:** feature-006-planning -> delivery-008 -> AC-19, AC-25

**Depends on:** task-207, task-208, task-209, task-211, task-214, task-215, task-216, task-217

**Scope:**
- `.aid/knowledge/test-landscape.md`: `test-plan.sh` and `test-work-state-migration.sh` and their lane; the new
  cases of `test-writeback-state.sh`, `test-derive-waves.sh` and `test-slice-requirements.sh`; the dashboard
  cases.
- Then regenerate `INDEX.md` and render `kb.html` with the installed `render-kb-view.sh` (G0). This delivery's
  resync migrates this work's state, not the KB.
- Name no work and no work folder.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md` assigns to `task-218`.
- **Gate-session steps (not built by this task).** Listed here so whoever runs the resync and the gate reads
  them from a task file (PLAN.md, The resync rule, item 6; G13). None is a task step, and none is resync-relevant
  except the resync itself.
  1. **Resync session -- the migration of this work's live state, the riskiest step of the plan:**
     1. **Dry run first.** Make a scratch copy as PLAN.md "How the copy is made" says (its own `run_generator.py`
        runs `aid update` there, migrating the copy's `work-003`). Run
        `bash tests/canonical/lib/check-migrated-work.sh <copy>/.aid/works/work-003-full-aid-restructure <the live, not yet migrated STATE.yml>`
        (task-201). On any difference, stop: no live resync until it is fixed.
     2. The resync (`delivery-008: resync`), committed alone: `aid update` installs the new writer and
        `derive-waves.sh`, removes `aid-detail` and the deleted templates, and runs the format-6 work-state step on
        this work (Q129). Run `check-migrated-work.sh` again on the live work. The pre-migration state is in git
        (the commit before the resync), so a bad migration is reverted (`git revert` of the resync commit) and
        re-run after the fix. Then the session ends.
  2. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan` renders this work's `PLAN.md`
     checklists, replacing each `### delivery-NNN Execution Graph` section and its `wave-map`; committed as a
     work-folder change. Then `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated page (`reference/settings.md`
    from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB is not changed by this resync.
  3. **The gate:** the stanza's criteria (no `deliveries/delivery-*/STATE.yml`; every task with
     `tasks/task-NNN/DETAIL.md` and one `tasks_lifecycle` entry; `derive-waves.sh --plan --check` exits 0), the
     samples, G0 with the baselines, and the tracking proof for task-185 to task-218.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-218: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-218`.
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
- [ ] `test-landscape.md` names both new suites and their lane.
- [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
