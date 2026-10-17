# task-334: Samples 009-11, 009-12, 009-14 and 009-16, the plain runs, and the deferred list

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 334 --field State.

**Type:** TEST

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-1, AC-7, AC-14, AC-28, AC-29, AC-30, AC-36, AC-37

**Depends on:** task-313, task-315, task-318, task-319, task-320, task-327, task-333

**Scope:**
- Create `009-11-ticket-outside-a-work`, `009-12-ticket-write-back-in-a-work` (a scratch tracker reached through the
  tool's own connection), `009-14-old-doorway-work-after-update` and `009-16-research-three-rounds` under
  `tests/conversation/samples/feature-009/`, with the checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`.
- `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Lists): the plain-run rows of `009-01`, `009-02` and
  `009-07` go; every remaining Feature 009 `skill:` row goes (covered by these samples, or gone with their skills);
  `009-11` and `009-12` get rows waiting for the integration run before release (delivery-014; the suite runs with no
  connection, Feature 001).
- Smoke run (Q134 D8): `009-14`, `009-16`, the plain form of `009-01`, `009-02` and `009-07`, and the re-runs
  `001-01`, `001-07`, `003-02` and `008-14`, once each, in a scratch copy.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-334`.
- **Checks and judgments (task-004's grammar).** A `## Checks` line is a file check on the fixture (`exists`,
  `absent`, `contains`, `no-new-dir`, `no-push`) or a transcript check (`tool-called`, `tool-not-called`). How the
  conversation went -- the order and count of questions, what the agent says, that nothing is written before a
  yes -- is an `## Expected outcome` or `## Must not` item, which the judge rules on. This task does not extend
  `run.py`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-334.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-334`.
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
- [ ] There are four new files; DT-01 and SS-09 pass, `deferred.tsv` holds no Feature 009 `skill:` row and no plain-run row, and `009-11` and `009-12` have their integration-run rows.
- [ ] Each smoke run has its result reported.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
