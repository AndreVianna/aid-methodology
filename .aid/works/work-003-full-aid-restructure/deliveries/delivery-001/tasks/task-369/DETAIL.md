# task-369: Feature 001 samples, three runs each, and the known issue for what still fails

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 369 --field State.

**Type:** TEST

**Source:** feature-001-plain-language-requests -> delivery-001 -> NFR-T (Q147, Q149; PLAN.md delivery-001 Gate Criteria)

**Depends on:** task-366, task-367, task-368

**Scope:**
- Run all 16 Feature 001 samples 3 times each with the real `claude` CLI, in a scratch copy made as the test step says (its own `run_generator.py`), never in the live tree.
- Classify every failing run: product behaviour, harness, or sample. A harness or sample failure goes back to task-366 or task-368 through a fix round and the sample is re-run.
- What still fails on product behaviour is recorded as one entry in `known-issues.md` naming each sample, its covered AC and its cause; it is re-checked at the full integration run at delivery-014's gate and does not block delivery-001 (Q149).
- Keep the per-sample results table in `analysis/delivery-001-sample-runs.md` (work folder).
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-369.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-369`.
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
- [ ] Every Feature 001 sample has run 3 times with `python3 tests/conversation/run.py --feature 001 --runs 3` in a scratch copy made after its own generator, and the report lists each sample's result per run and the cause of each failure (product, harness, or sample).
- [ ] A failure caused by the harness or a sample is fixed here (or by the owning task through a fix round) and its sample re-run; a sample that still fails on product behaviour after that is recorded in `known-issues.md` as one known issue that names each sample and its cause, re-checked at the full integration run at delivery-014's gate (Q149).
- [ ] The run folders and the per-sample table are kept in the work folder's `analysis/` (not in `.aid/knowledge/`), with no credential and no maintainer identity in them.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
