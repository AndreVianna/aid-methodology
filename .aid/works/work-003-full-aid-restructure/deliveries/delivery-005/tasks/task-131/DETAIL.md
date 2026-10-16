# task-131: aid-summarize retired, with summarize/ and its suites

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

**Source:** feature-004-kb-management -> delivery-005 -> AC-15

**Depends on:** task-108, task-111, task-123, task-124, task-129, task-130

**Scope:**
- Delete `canonical/skills/aid-summarize/` and `canonical/aid/scripts/summarize/`, including
  `summarize/writeback-state.sh` and its scalars (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`).
  `contrast-check.mjs` moves to `tests/canonical/lib/contrast-check.mjs`.
- `canonical/aid/templates/knowledge-summary/`: `prompt.md`, `grading-rubric.md`,
  `authored-visual-catalog.md` and `section-templates/` go. The renderer's inputs stay.
- Retire the summarize suites, with accepted-removal rows: `test-grade-summary.sh`,
  `test-guardrails-d012.sh`, `test-visual-fidelity.sh`, `test-validator-behavior.sh`,
  `test-summarize-preflight.sh`, `test-assemble-3part.sh`, `test-assemble-3part-ps1.sh`,
  `test-assemble-determinism.sh`, `test-diagram-content.sh`, `test-kb-export.sh`,
  `test-kb-export-pw.mjs`, `test-md-export-embed.sh`, `test-kb-html-claims-check.sh`,
  `test-payload-size.sh` and `test-contrast-check.sh`.
- Lists and counts: its guide line, its rows in `deferred.tsv` and the SG-04 exempt list, and the counted
  phrases (Q134 D5).
- Update the site skill lists and their `__tests__`.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md` assigns to `task-131`.
- **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
  asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
  synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
  for the final pass (AC-45).
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-131: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-131`.
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
- [ ] `test -e canonical/skills/aid-summarize` and `test -e canonical/aid/scripts/summarize` both fail, and `tests/canonical/lib/contrast-check.mjs` exists.
- [ ] None of the 15 retired suites exists, and each of their assertion ids in `tests/coverage-baseline.tsv` has an accepted-removal row.
- [ ] SG-02, DT-01 and `test-doc-counts.sh` pass, and the site `npm test` passes after regeneration.
- [ ] `test-doc-counts.sh` passes live with the derived counts, and the site `npm test` passes after `sync:docs` (its sync-docs drift test included).
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] No page under `site/src/content/docs/skills/` and no `site/src/data/skill-flows/*.flow.json` is left for a skill folder this task deletes or renames away, and `npm run gen:skills` reports no orphan (G18).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
