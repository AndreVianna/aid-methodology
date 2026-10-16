# task-119: aid-kb-query and aid-kb-show

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

**Source:** feature-004-kb-management -> delivery-005 -> AC-4, AC-15

**Depends on:** task-110, task-111

**Scope:**
- Move `canonical/skills/aid-ask/` to `canonical/skills/aid-kb-query/` (REQUIREMENTS.md § 11 Feature 004 `##### 3. Flows`):
  - its new name and description;
  - gap capture through the writer (`--ask` in a work; `--ask --kb` otherwise, `category: Knowledge Base`,
    `asked_by: aid-kb-query`), and nothing else written;
  - the update offer, or with no KB the build offer;
  - `allowed-tools: Read Glob Grep Bash Agent`.
- Create `canonical/skills/aid-kb-show/SKILL.md`, at most 60 lines, with `allowed-tools: Read Glob Bash`.
  It runs `render-kb-view.sh --check`, and answers per the spec's exit table (0, 1 and 3, with the
  `Growing` and no-KB cases). Its refresh offer runs `/aid-kb-update` in `refresh` mode.
- **Lists and counts that follow a moved or new skill**, in this same task:
  - its `canonical/aid/rules.md` § Skill guide line, with the spec's text (`##### 5. Components`);
  - its `description:` in the spec's what/when shape (the four KB skills are not SG-04-exempt);
  - the old name's rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`;
  - the old name's `skill:` row in `tests/conversation/deferred.tsv`, which becomes a `skill:` row for
    the new name until task-135's samples land (DT-01, SS-09);
  - the site skill lists and their `__tests__`;
  - the counted phrases, if the skill count changes (Q134 D5).
- Suites to update in this same task: every suite the findings' K1, K2 or K7 assigns to `aid-ask`.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md` assigns to `task-119`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-119: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-119`.
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
- [ ] `test -d canonical/skills/aid-ask` fails. The `allowed-tools` lines of `aid-kb-query` and `aid-kb-show` hold no `Write` and no `Edit` (KB-03's first clause).
- [ ] `aid-kb-show/SKILL.md` is at most 60 lines and covers exits 0, 1 and 3, including the `Growing` message verbatim.
- [ ] SG-02, SG-04, DT-01 and SS-09 pass in the scratch copy, and `test-doc-counts.sh` passes live with the skill count raised by one.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
