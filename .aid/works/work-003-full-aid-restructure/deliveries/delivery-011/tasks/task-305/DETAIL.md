# task-305: test-actions.sh group A

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 305 --field State.

**Type:** TEST

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-20, AC-30

**Depends on:** task-289, task-290, task-292, task-293, task-294, task-295, task-296, task-297, task-298, task-299, task-300, task-301

**Scope:**
- Create `tests/canonical/test-actions.sh`, a bash harness on `tests/lib/assert.sh` with `# COVERS:` lines and a group
  filter (T6), holding group A (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`; PLAN.md delivery-011 Scope):
  - AS-03 for the shipped catalog, without its `domain` and reserved-field clauses;
  - AS-04 without its `aid-deploy` / `aid-monitor` clause;
  - AS-05;
  - AS-06 for the findings half;
  - AS-09 without its `.aid/kinds/`, skip-rule and review/research/report clauses.
- Groups B and C are added by deliveries 012 and 013 (Q113).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-305`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-305.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-305`.
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
- [ ] `test-actions.sh` passes where the test step puts it, with a named assertion per check.
- [ ] Each check fails its own mutation in a scratch copy: a duplicate `kind`; a kind taken by `aid-nothing`; `architecture` taken by `create`; an action skill without `action-start.md`; `finish.md` without `--phase CI`; `findings.md` without the main folder; `breakdown.md` without `tasks`; `--kind` added to `aid-brainstorm`'s `start.md`.
- [ ] It is deterministic, reads files only, and finishes within the 300-second budget.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
