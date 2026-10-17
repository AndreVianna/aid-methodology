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

**Depends on:** task-084, task-087, task-088, task-090, task-091, task-092, task-096

**Scope:**
- Delete `canonical/skills/aid-describe/`. Its parts are already placed (REQUIREMENTS.md § 11 Feature 003 `##### 5. Components`).
- `canonical/aid/rules.md` § Skill guide: the `/aid-describe` line goes.
- **No legacy row proposes the deleted skill.** In `canonical/aid/templates/work-initiation-gate.md` § 3b,
  the old phase row `Describe -> /aid-describe` (inside the `legacy-phase-map` block; about line 139 at the
  base) goes. task-088's third row already sends every phase-`Describe` work to its initiator's skill, so
  nothing is re-pointed in its place. `aid-describe` stays in the block only as an initiator a row matches
  (task-088's second row). The suites asserting the removed row (`test-work-initiation-gate.sh`, and any
  suite the G6 grep below finds) change in this same task (G6, G3).
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
- **KB `sources:` citations (G17).** Every `.aid/knowledge/` document whose frontmatter `sources:` cites a file or
  folder this task deletes, moves or renames is fixed in this same task (`git grep -n -e '<path>' -e '<folder>/' --
  .aid/knowledge/` at this task's base): the entry follows a moved file, and goes when the file is gone. Only the
  `sources:` entries change here; the prose stays for the delivery's DOCUMENT task. So `test-artifact-discipline.sh`
  AD14 (every `sources:` citation resolves) holds at this task's end. The KB lines are committed as the delivery
  commits KB paths (through `kb-commit.sh` once it exists, as Feature 007's BUILD requires).
- **The retired skill's site pages (G18).** Before regenerating, `git rm` what the generators no longer produce for each
  skill folder this task deletes or renames away: its page under `site/src/content/docs/skills/` and its
  `site/src/data/skill-flows/<name>.flow.json` (the generators never delete; `gen-skills.mjs`'s drift check names any
  orphan with its `git rm` remedy). Then the site regeneration below.
- **Site generator sources (G19).** Every site script source outside `__tests__` that hard-codes the name of a skill
  this task retires or renames (`git grep -nE 'aid-<name>([^a-z-]|$)' -- site/scripts/ ':!site/scripts/__tests__'`,
  for example the settings-page intro in `gen-reference.mjs` or a name list in `lib/flow-graph/extract-residual.mjs`)
  is fixed in this same task, before it regenerates: the name follows the rename, or the retired skill's mention
  goes. A generated page is never edited by hand to hide a stale generator.
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
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
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
- [ ] Inside the `legacy-phase-map` block, no row's proposed skill or step names `aid-describe`: the only lines naming it match it as an old `pipeline.initiator`. Walking the block's first-match order by hand, recorded in the report: an `aid-research` work at `phase: Describe` -> `/aid-research`; an `aid-describe` work at `phase: Describe` -> `/aid-specify`. `test-work-initiation-gate.sh` passes live.
- [ ] DT-01, SG-04 and `test-skill-steps.sh` pass where the test step puts them, and `test-doc-counts.sh` passes live.
- [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` and the site `npm test` pass.
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] No page under `site/src/content/docs/skills/` and no `site/src/data/skill-flows/*.flow.json` is left for a skill folder this task deletes or renames away, and `npm run gen:skills` reports no orphan (G18).
- [ ] Over `site/scripts/` outside `__tests__`, no source names a skill this task retires, and none names a renamed skill by its old name (G19).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
