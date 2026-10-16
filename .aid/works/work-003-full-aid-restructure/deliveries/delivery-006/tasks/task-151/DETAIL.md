# task-151: The 14 KB create/update skills and design-lifecycle.md retired

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-004-kb-management -> delivery-006 -> AC-39

**Depends on:** task-144, task-145, task-147, task-150

**Scope:**
- Delete the 14 KB `create`/`update` skill folders under `canonical/skills/` (`aid-create-*` and
  `aid-update-*` for `architecture`, `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog` and `mvp`),
  and `canonical/aid/templates/design-lifecycle.md` (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`).
- `canonical/aid/templates/shortcut-catalog.yml`: their 14 rows go, with every comment that names them.
- **Re-pointing** by Feature 004's one rule (`##### 7. Migration`, Re-pointing): every other kept file under
  `canonical/`, and `dashboard/home.html`, that names one of them or `design-lifecycle.md` is re-pointed to
  `/aid-kb-update`, the roadmap or backlog document, or reworded (for example `aid-config`'s `knowledge`
  row). Exempt: the gate's legacy block and `canonical/aid/scripts/migrate/`. The dashboard readers' legacy
  skill maps are Feature 009's (findings' R1).
- **Lists and counts that follow the retired skills**, in this same task:
  - every row of `tests/canonical/skill-steps-exempt.tsv` whose owner is Feature 004 (the 14 skills and
    `design-lifecycle.md`, with their SS and ID codes);
  - their rows in the SG-04 exempt list of `test-skill-guide.sh`;
  - their `skill:` rows in `tests/conversation/deferred.tsv`;
  - the skill guide: the `<kind>` expansion follows the catalog, so SG-02 holds with the folders and the
    rows gone together;
  - the site skill lists and their `__tests__`;
  - the counted phrases and counts (Q134 D5): DMR33, `test-catalog-dirs-parity.sh`, SBI05,
    `test-doc-counts.sh` and the site's skill counts.
- The G6 search below runs for each of the 14 folders and for `design-lifecycle.md`, which
  `test-skill-steps.sh`'s SS-02 clause names.
- **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
  build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
  list does not come from the findings' map alone. Every suite it finds is updated in this same task
  (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
  criterion is scoped so it holds without the row.
- **KB `sources:` citations (G17).** Every `.aid/knowledge/` document whose frontmatter `sources:` cites a file or
  folder this task deletes, moves or renames is fixed in this same task (`git grep -n -e '<path>' -e '<folder>/' --
  .aid/knowledge/` at this task's base): the entry follows a moved file, and goes when the file is gone. Only the
  `sources:` entries change here; the prose stays for the delivery's DOCUMENT task. So `test-artifact-discipline.sh`
  AD14 (every `sources:` citation resolves) holds at this task's end. The KB lines are committed as the delivery
  commits KB paths (through `kb-commit.sh` once it exists, as Feature 007's BUILD requires).
- **The retired skill's site pages (G18).** Before regenerating, `git rm` what the generators no longer produce for each
  skill folder this task deletes or renames away: its page under `site/src/content/docs/skills/` and its
  `site/src/data/skill-flows/<name>.flow.json` (the generators never delete; `gen-skills.mjs`'s drift check names any
  orphan with its `git rm` remedy). Then the site regeneration below.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-006-sites.md` assigns to `task-151`.
- **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
  asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
  synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
  for the final pass (AC-45).
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-151: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-151`.
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
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] None of the 14 folders and no `design-lifecycle.md` exists, and `grep -cE 'aid-(create|update)-(architecture|stack|testing-strategy|cicd|roadmap|backlog|mvp)\b' canonical/aid/templates/shortcut-catalog.yml` prints 0.
- [ ] Over `canonical/` and `dashboard/home.html`, `git grep -nE 'aid-(create|update)-(architecture|stack|testing-strategy|cicd|roadmap|backlog|mvp)\b|design-lifecycle'` finds nothing outside the gate's legacy block and `canonical/aid/scripts/migrate/`.
- [ ] `grep -c 'Feature 004' tests/canonical/skill-steps-exempt.tsv` prints 0. SG-02, SG-04, DT-01 and `test-skill-steps.sh` pass in the scratch copy, `test-doc-counts.sh` passes live, and `build-shortcut-skills.py --check` exits 0.
- [ ] The site `npm test` passes after regeneration.
- [ ] `test-doc-counts.sh` passes live with the derived counts, and the site `npm test` passes after `sync:docs` (its sync-docs drift test included).
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] No page under `site/src/content/docs/skills/` and no `site/src/data/skill-flows/*.flow.json` is left for a skill folder this task deletes or renames away, and `npm run gen:skills` reports no orphan (G18).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
