# task-093: aid-describe retired

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

**Source:** feature-003-work-definition -> delivery-004 -> AC-43

**Depends on:** task-088, task-090, task-091, task-092

**Scope:**
- Delete `canonical/skills/aid-describe/`. Its parts are already placed (REQUIREMENTS.md § 11 Feature 003 `##### 5. Components`).
- `canonical/aid/rules.md` § Skill guide: the `/aid-describe` line goes.
- `dashboard/home.html`'s empty-state steps: "run `/aid-describe`" becomes "tell your AI tool what you
  want to build", with `dashboard/server/tests/test_index_html.py`. The readers' `SHORTCUT_KIND_MAP` and
  `_FULL_PATH_INITIATOR` stay.
- Delete `tests/canonical/test-describe-full-only.sh`, with an accepted-removal row per assertion.
- Update the suites that read files inside the folder: `test-ticket-retirement-structural.sh` (T001-T006,
  `DESCRIBE_COMPLETION`, `DESCRIBE_FIRSTRUN`, and its walk of the folder) and `test-work-state-template.sh`
  (WS19, `FIRST_RUN`).
- Update the suites that name it: `test-work-initiation-gate.sh`, `test-path-fixtures.sh`,
  `test-pipeline-status-walkthrough.sh`, `test-cutover-no-dangling.sh`, `test-deploy-monitor-repurpose.sh`,
  and any suite the findings' R1 or R5 assigns here.
- Update the site skill lists (`site/scripts/skills/`, `site/scripts/lib/flow-graph/`) and their
  `__tests__`.
- **Lists that name the retired skills** leave with them in this task, because DT-01, the shared exempt
  list and SG-04 each fail on a missing folder:
  - their `skill:` rows in `tests/conversation/deferred.tsv`;
  - their rows in `tests/canonical/skill-steps-exempt.tsv`;
  - their rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`.
- **Count re-sync (Q134 D5):** the skill-count phrases that `tests/canonical/test-doc-counts.sh` asserts
  in `README.md` and `docs/` take the derived count, then `(cd site && npm run sync:docs)` runs. Only the
  numbers change; user documentation otherwise waits for the final pass (REQUIREMENTS.md § 11 Feature 003 `##### 6. Migration`).
- **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
  build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
  list does not come from the findings' map alone. Every suite it finds is updated in this same task
  (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
  criterion is scoped so it holds without the row.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-004-sites.md` assigns to `task-093`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-093: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-093`.
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
- [ ] `test -e canonical/skills/aid-describe` fails. Outside the gate's legacy block, nothing under `canonical/` or in `dashboard/home.html` names `aid-describe`, except `design-lifecycle.md` and the KB-writing `aid-create-*` / `aid-update-*` skills, which Feature 004 retires; task-099 adds their ID-02 exemption row (ID-02's rule, scoped to hold at this task's end).
- [ ] DT-01, SG-04 and `test-skill-steps.sh` pass in the scratch copy, and `test-doc-counts.sh` passes live.
- [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` and the site `npm test` pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
