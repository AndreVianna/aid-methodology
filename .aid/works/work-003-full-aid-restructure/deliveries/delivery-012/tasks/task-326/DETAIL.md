# task-326: The shortcut catalog retired, with its counting suites

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 326 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-20, AC-31

**Depends on:** task-321, task-322, task-324, task-325

**Scope:**
- Delete `canonical/aid/templates/shortcut-catalog.yml` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`).
- Suites to update in this same task (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Suites; `##### 6`, the rows owed by Features 003 and
  004):
  - `test-deploy-monitor-repurpose.sh`: DMR00e and DMR30-DMR35 retired; DMR24 re-pointed (the two skills carry no
    `GENERATED` marker), DMR33 re-pointed (no `canonical/skills/*/SKILL.md` carries one), DMR36 re-pointed (every
    skill folder has a skill-guide line, as SG-02 does);
  - `test-catalog-dirs-parity.sh` retired;
  - `test-doc-counts.sh` rewritten: counts from `canonical/skills/`, not catalog rows;
  - `test-kb-skills.sh` KB-01 and `test-idea-shaping.sh` ID-03, which name the catalog only while it exists;
  - `test-connector-skills-structural.sh`: its check that the connector skills have no catalog row retires;
  - `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py`: Leg 3 (every catalog row has a key) and
    its control `test_p1b` retire; Legs 1, 2 and 4 stay;
  - any suite the findings' B4 assigns here.
- **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
  build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
  list does not come from the findings' map alone. Every suite it finds is updated in this same task
  (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
  criterion is scoped so it holds without the row.
  - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
    `installer-tests.yml` in this same task, and its assertions get their rows in
    `tests/coverage-accepted-removals.tsv`.
  - For a skill folder it also searches the skill's bare name (`git grep -nE "'<name>'" -- site/scripts/__tests__
    site/src/lib/__tests__`): a site test that loads the skill's body as a fixture by name is re-pointed here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-326`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-326.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-326`.
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
- [ ] `test -e canonical/aid/templates/shortcut-catalog.yml` fails, and over `tests/canonical/*.sh` and `site/scripts/` `git grep -n 'shortcut-catalog'` finds nothing (the dashboard comments and docstrings are task-328's, and the baselines are re-recorded at the gate).
- [ ] `test-deploy-monitor-repurpose.sh`, `test-kb-skills.sh`, `test-idea-shaping.sh` and `test-connector-skills-structural.sh` pass where the test step puts them, `test-doc-counts.sh` passes live, and `python3 -m pytest dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` passes.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
