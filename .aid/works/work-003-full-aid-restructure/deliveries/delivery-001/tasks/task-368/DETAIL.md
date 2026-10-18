# task-368: Feature 001 samples and fixture: the defects the smoke runs found

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 368 --field State.

**Type:** TEST

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-2, AC-5, AC-7, AC-29 (Q147 diagnosis RC-6)

**Depends on:** task-018

**Scope:**
- `tests/conversation/samples/feature-001/001-13-project-source-unattached.md` (`.aid/works/work-003-full-aid-restructure/analysis/delivery-001-sample-diagnosis.md` § 3 fix 5): the Must not item that forbids recording the change in the work's state file goes; the sample still requires the payments ticket to stay out of `sources:`.
- `tests/conversation/fixtures/default/.aid/knowledge/architecture.md` and `001-07-rich-ticket.md` (fix 6): state what is persisted so an export file is no Knowledge Base conflict, and keep 001-07's single approval before building. Keep `fixtures/empty-notes-file/` in step with `default` (its README note).
- `001-03-several-ask.md` and `001-02-several-decide.md` (fix 7): 001-03 accepts one question with valid options and a recommendation; 001-02 accepts any named read-only investigation workflow with its reason.
- Re-read every changed sample for contradictions between Expected outcome, Must not and Checks.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-368.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-368`.
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
- [ ] 001-13's Must not no longer forbids recording the change in the work's state file; it requires the payments ticket to stay out of `sources:` (it is a project source).
- [ ] 001-06 and 001-07 no longer trade against each other: the default fixture's `architecture.md` names what is persisted so that an export file is not a Knowledge Base conflict, and 001-07's single pre-build approval still holds.
- [ ] 001-03 accepts one question with valid options and a recommendation without requiring named workflow kinds; 001-02 accepts any named read-only investigation workflow with its reason.
- [ ] `python3 tests/conversation/run.py --feature 001 --validate` exits 0, and no `## Answer sheet` names a skill.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
