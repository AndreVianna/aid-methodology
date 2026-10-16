# task-316: Site generator: the skill list from canonical/skills/

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 316 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-31

**Depends on:** task-311

**Scope:**
- REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Site and its check-by-check list, the `skills/` part:
  - `site/scripts/skills/catalog.mjs` is rewritten: the skill list comes from `canonical/skills/*/SKILL.md`, never
    from `shortcut-catalog.yml`;
  - `groups.mjs` and `curated-roster.mjs`: groups in the skill guide's order (while `<kind>` lines exist, a folder the
    guide reaches only through one is grouped under that line); no "unassignable skill" for a skill that is not a
    catalog row;
  - `skill-counts.mjs`: counts from the folders; no catalog-row or doorway count;
  - `discover.mjs`, `paths.mjs`, `render-index.mjs`, `gen-skills.mjs` (`INDEX_SRC` and the generated-from strings name
    `canonical/skills/*/SKILL.md` only);
  - `gen-reference.mjs`: the engine and catalog rows go, and the skills page no longer reads either file;
  - their tests: `skills-catalog.test.mjs`, `skills-groups.test.mjs`, `skill-counts.test.mjs`, `gen-skills.test.mjs`,
    `gen-skills-index.test.mjs`, `gen-reference.test.mjs`, `skills-paths.test.mjs`, `skills-body.test.mjs`,
    `skills-render-index.test.mjs`, `skills-render-page.test.mjs`.
- After this task no site module reads `shortcut-catalog.yml` or `shortcut-engine.md` for the skill list or the
  reference pages (the flow-graph modules are task-317).
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-316`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-316.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-316`.
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
- [ ] Over `site/scripts/skills/` and `site/scripts/gen-reference.mjs`, `git grep -nE 'shortcut-catalog|shortcut-engine'` finds nothing.
- [ ] `(cd site && npm test)` passes, and `npm run gen:skills && npm run gen:reference` regenerates the pages with every skill folder on disk listed.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
