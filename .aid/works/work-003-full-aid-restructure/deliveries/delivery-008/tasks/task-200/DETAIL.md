# task-200: Dashboard: the old-layout diagnosis, the server and the page

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

**Source:** feature-006-planning -> delivery-008 -> AC-19, AC-41

**Depends on:** task-188, task-199

**Scope:**
- Both readers, kept equal by the parity tests (REQUIREMENTS.md § 11 Feature 006 `##### 5. Components`, Dashboard): the old parses go --
  `_detect_hierarchy`, `_read_work_hierarchical`, `_detect_flat`, `_declared_work_path`, `parse_task_state_md`, the
  delivery-file parse, the delivery `qa` merge and the `wave-map` parse (`parse_execution_graph`); an old-layout work
  (a `deliveries/` folder, a top-level `delivery_state`, or a `pipeline.path`) is not parsed: `layout_status: old`,
  the detection lines inside `legacy-layout: begin` / `end` markers; `work_path` and `features` go. This runs after
  task-188, so every fixture the writer makes is already single-layout (G12).
- `dashboard/server/server.py` § `_ser_work` and `server.mjs` pass `depth`, `phases` and `layout_status`, and no
  `work_path` or `features` (REQUIREMENTS.md § 11 Feature 006 `##### 5. Components`, Dashboard).
- `dashboard/home.html`: the badge shows the depth ("Full" / "Lite"); the path line becomes "{Full|Lite}: N
  deliveries -> M tasks (K done)", "[planning]" before any task exists, with no feature count; the features
  disclosure goes; an old-layout work's card says "This work uses an older layout: run `aid update` in this
  project". The stage rail stays Feature 002's.
- Suites to update in this same task: the dashboard reader and parity suites and fixtures (hierarchy and
  `wave-map` fixtures among them; an old nested fixture stays where it now checks the diagnosis),
  `test-dashboard-parity-h.sh`, `dashboard/server/tests/test_index_html.py`, the server tests, and any suite the
  findings' L6 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-008-sites.md` assigns to `task-200`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-200: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-200`.
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
- [ ] `home.html` holds the old-layout line verbatim and no `work_path` or features disclosure; `grep -n 'work_path' dashboard/server/server.py dashboard/server/server.mjs dashboard/home.html` prints nothing.
- [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` and the server suites pass.
- [ ] A nested fixture reads `layout_status: old` in both readers, and over `dashboard/reader/*.py` and `dashboard/server/reader.mjs`, `git grep -nE 'deliveries/delivery-|pipeline\.path|work_path|parse_execution_graph'` finds nothing outside the `legacy-layout` markers (PL-04 over these files).
- [ ] The reader, parity and server suites pass where the test step puts them.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
