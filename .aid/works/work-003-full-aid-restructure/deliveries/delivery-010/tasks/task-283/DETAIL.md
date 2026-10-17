# task-283: Samples 008-15 to 008-18, and the deferred rows

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 283 --field State.

**Type:** TEST

**Source:** feature-008-cicd-integration-monitoring -> delivery-010 -> AC-13, AC-27, AC-35, AC-36, AC-42

**Depends on:** task-262, task-266, task-282

**Scope:**
- Create `008-15-live-hosts`, `008-16`, `008-17` and `008-18` under `tests/conversation/samples/feature-008/`, with the
  checks of REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`.
- Update `tests/conversation/deferred.tsv`: the `skill:aid-monitor-pipeline` row task-266 added goes; the rows of
  `002-10` and `007-13` go (they run at this gate); `008-15` gets a row waiting for the integration run before
  release (delivery-014).
- Smoke run (Q134 D8): `008-16` to `008-18`, `002-10`, `007-13` and `001-16` once each, in a scratch copy.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-010-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-283`.
- **Checks and judgments (task-004's grammar).** A `## Checks` line is a file check on the fixture (`exists`,
  `absent`, `contains`, `no-new-dir`, `no-push`) or a transcript check (`tool-called`, `tool-not-called`). How the
  conversation went -- the order and count of questions, what the agent says, that nothing is written before a
  yes -- is an `## Expected outcome` or `## Must not` item, which the judge rules on. This task does not extend
  `run.py`.
- **Re-run samples of this gate.** `001-16` passes again at this gate (PLAN.md delivery-010 Gate Criteria;
  REQUIREMENTS.md § 11 Feature 008 `##### 8. Testing`). It is read against the flow this delivery changes -- its
  answer sheet, `## Expected outcome`, `## Must not` and `## Checks` -- and brought in line in this same task where
  the flow moved; then it gets one smoke run with the others.
  `001-16`'s fixture has no git remote, so the close now passes through `/aid-monitor-pipeline` START's *No remote*
  branch: `connect.md` offers to add a remote, then the *no pull request yet* question (Q94). Its answer sheet
  declines the remote and answers *no pull request* (CLOSE, mode `no-pr`: the work is marked done); its checks
  stay `contains` `lifecycle: Completed` and `no-push`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-283.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-283`.
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
- [ ] There are four new files; `008-15` has its `deferred.tsv` row; DT-01 and SS-09 pass with no `skill:aid-monitor-pipeline`, `002-10` or `007-13` row left.
- [ ] Each smoke run has its result reported.
- [ ] `001-16`'s answer sheet answers the remote offer and the create question, its checks are `lifecycle: Completed` and `no-push`, `python3 tests/conversation/run.py --validate --feature 001` exits 0, and its smoke run is reported.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
