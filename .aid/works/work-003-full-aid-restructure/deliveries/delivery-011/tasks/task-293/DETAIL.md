# task-293: action-start.md: the one START of every action skill

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 293 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-30

**Depends on:** task-289, task-290, task-291, task-292

**Scope:**
- Create `canonical/aid/templates/action-start.md`, type `template-own`, at most 120 lines (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`,
  START, steps 1-6): the words (a bare command asks "What do you want to <action>?", an intake question); the kind
  (typed first word when it names a kind that this action takes, else `check-intent.md`'s kind hook called with the
  skill's own name; several fit, one question with a recommendation; none, `--`; a typed kind is a hint, checked like
  any reading); the reading (the action's `reading`, checked by `check-intent.md`, a different checked reading said
  in one line and recorded); the work (the gate's § 3a with the words, the skill's name, step `START`, the reading,
  `--kind` and the depth from `size-and-route.md`; § 3b on continuation); every catalog read (the action's `reading`,
  the kinds this action takes, a typed kind) goes through `check-intent.md` § The merged catalog, which it cites; next by the recorded reading (knowledge
  update, operational, investigation, a problem not clear yet, otherwise `aid-specify`), with the exact `--handoff`
  lines of the spec; a resume skips each step whose answer the record holds.
- The ticket branch (step 4) is delivery-012's, with the TICKET step.
- The action layer names no software term (AS-10 lands in delivery-013; write it so now): "something" or "a work
  product", never `code`, `codebase`, `repository`, `commit`, `branch` or `pull request`.
- Suites to update in this same task: `test-work-initiation-gate.sh` Group G gains
  `canonical/aid/templates/action-start.md` under its own coverage ID (`-consults` names `work-initiation-gate.md`;
  `-create-mention` names the gate's § 3a; the § 3a line comes before its first `writeback-state.sh` line); the
  count assertions (G, GG00) take the new list's length; any suite the findings' Z6 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-293`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-293.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-293`.
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
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] `action-start.md` exists, at most 120 lines, and names `--kind`, `intent.kind`, `check-intent.md`, `The merged catalog`, `aid-specify`, `aid-brainstorm` and `aid-kb-update` (AS-04's `action-start.md` clause; AS-09's "every other reader cites that section").
- [ ] Over `action-start.md`, `grep -niwE 'code|codebase|repository|commit|branch|pull request'` prints nothing.
- [ ] `test-work-initiation-gate.sh` passes where the test step puts it, with the new Group G entry.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
