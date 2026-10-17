# task-289: The kind catalog, version 2: actions, the new fields and the new kinds

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 289 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-20, AC-30

**Depends on:** --

**Scope:**
- `canonical/aid/templates/kind-catalog.yml` becomes `version: 2` (REQUIREMENTS.md § 11 Feature 009 `##### 3. The catalog`), block style, every
  value one line, lists inside a value as one comma-separated string:
  - an `actions` list: `create` (new capability), `update` (change), `fix` (bug fix), `refactor` (refactor),
    `document` (document), each `next: Specification`; `test` and `prototype` (investigation, `next: own`); each
    with its `about` and `rules`;
  - every kind gains `taken_by`, and the fields `ask`, `design`, `tasks`, `checks`, `tests` and `update` where
    the spec's table gives them; `shape` and `then` stay on the kinds `brainstorm` takes;
  - the new kinds, by the spec's "Taken by" table: removal, deprecation, migration; defect, regression, incident,
    vulnerability; general, decision, guideline, standard, runbook, tutorial, changelog, diagram; functional,
    security, performance, data-quality, model-evaluation, experiment;
  - the `actions` entries (`about`, `rules`) name no software term (AS-10, which delivery-013 adds; proposal S12):
    "something" or "a work product", never `code`, `codebase`, `repository`, `commit`, `branch` or `pull request`;
    software-specific rules live in the software kinds;
  - the content comes from today's scaffolding files: `create.md`'s slots, conditional sections and task chains
    become `ask`, `design` and `tasks`; `change-refactor.md` becomes the `update` notes and the change kinds;
    `fix.md`, `document.md`, `prototype.md` and `test-experiment.md` become their kinds' fields.
- Not in this task: the `ticket` kind (delivery-012, with the TICKET step), `domain` and the reserved fields
  (delivery-013). No kind that names a KB document, and not `document`, is taken by `create` or `update`.
- Suites to update in this same task: `test-idea-shaping.sh` ID-04, which now asks `shape` and `then` only of the
  kinds `brainstorm` takes (Feature 009 § 6, the row owed to Feature 003), and any suite the findings' Z2 assigns
  here.
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
  the run starts, Q139) assigns to `task-289`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-289.base`, which `/aid-execute` BUILD records on the
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-289`.
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
- [ ] `python3 -c "import yaml,sys; d=yaml.safe_load(open('canonical/aid/templates/kind-catalog.yml')); sys.exit(0 if d['version']==2 else 1)"` exits 0; the file holds the seven actions, each with `action`, `reading`, `about`, `next` and `rules`, and every kind of the spec's table except `ticket`.
- [ ] A check run from this task's scratch area (the AS-03 rule ahead of its suite) finds every `kind` unique and of lowercase letters, digits and hyphens, every kind with `about` and `taken_by` naming only `brainstorm` or an existing action skill, and no KB kind and not `document` taken by `create` or `update`.
- [ ] Over the `actions` entries, `grep -niwE 'code|codebase|repository|commit|branch|pull request'` prints nothing.
- [ ] `test-idea-shaping.sh` passes where the test step puts it.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
