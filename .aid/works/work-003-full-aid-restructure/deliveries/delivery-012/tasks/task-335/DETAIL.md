# task-335: KB decisions, release notes, quality gates, roadmap and tech debt for one skill per need

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 335 --field State.

**Type:** DOCUMENT

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-20, AC-24, AC-31

**Depends on:** task-326, task-329

**Scope:**
- Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB, and Release notes):
  - `decisions.md` gains "one skill per action, one catalog of kinds: a kind is data the phase skills read, typed or
    said", which supersedes D20 (the shortcut engine) and D22's scaffolding consequence, marked in the summary table
    and their sections;
  - `backlog.md` § Next Release: the old -> new rows for every slash name this delivery retires (the spec's Migration
    table, without `/aid-config`, and the typed command losing its one fast pass) (AC-24);
  - `quality-gates.md`: the "Shortcut / Lite-Path Gate (shortcut engine)" section and the engine in its `sources:`
    go; a `lite` work's quality is Specification's and Planning's graded checks;
  - `roadmap.md`: its shortcut-path sentences describe the action skills (`## Later` is delivery-013's);
  - `tech-debt.md`: W5-6 loses its `shortcut-engine.md` site, and W1-2's doorway split goes.
- Name no work and no work folder.
- **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
  delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
  itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
  it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
  it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
  text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
  commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-335`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-335.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-335`.
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
- [ ] The new decision is in the summary table and its section, with D20 and D22 marked; `backlog.md` § Next Release has a row for each name of the findings' B3 and for each retired family form.
- [ ] Over the edited documents, `git grep -nE 'shortcut-engine|shortcut-catalog|shortcut-scaffolding'` finds nothing outside superseded-decision text; no work id, and the citation and frontmatter lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
