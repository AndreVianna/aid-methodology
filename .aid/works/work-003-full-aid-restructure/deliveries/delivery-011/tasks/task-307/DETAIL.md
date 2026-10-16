# task-307: Samples 009-05, 009-07, 009-13 and 009-17, and the deferred rows

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 307 --field State.

**Type:** TEST

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-14, AC-15, AC-28, AC-30, AC-36

**Depends on:** task-297, task-300, task-301, task-302, task-306

**Scope:**
- Create `009-05-refactor-typed-and-plain`, `009-07-security-test-typed-and-plain` (each with both openings),
  `009-13-kb-kind-is-not-an-action` and `009-17-update-asks-the-kind` under `tests/conversation/samples/feature-009/`,
  with the checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`.
- Update `tests/conversation/deferred.tsv` (Feature 009 § 8, Lists; DT-01, SS-09):
  - the temporary `skill:` rows of task-294 and task-295 go (covered by `009-01`, `009-02`, `009-04` and `009-05`);
  - `skill:aid-test` goes (covered by `009-07`, whose typed run passes at this gate);
  - one row each for `009-01`, `009-02` and `009-07`, `waiting_for` Feature 009 part b, naming the plain run (Q121;
    PLAN.md delivery-011 Notes); `009-05` runs both forms at this gate and gets no row;
  - `skill:aid-prototype` and `skill:aid-document` stay until delivery-012's samples.
- Smoke run (Q134 D8): `009-13`, `009-17`, both forms of `009-05`, and the typed form of `009-07`, once each, in a
  scratch copy.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md` assigns to `task-307`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-307.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-307`.
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
- [ ] There are four new files; DT-01 and SS-09 pass with no `skill:aid-test` row and no temporary row of task-294 or task-295 left, and the three plain-run rows (`009-01`, `009-02`, `009-07`) present.
- [ ] Each smoke run has its result reported.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
