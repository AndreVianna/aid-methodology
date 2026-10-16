# task-311: Delivery-012 site search and reconciled edit list

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 311 --field State.

**Type:** RESEARCH

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-20, AC-31

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 8. Migration`):
  - **B1** both `git grep` commands of REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Suites, verbatim, read hit by hit, each hit with
    the class the spec gives it (retired, rewritten, re-pointed, unchanged, dashboard, site);
  - **B2** the re-pointing sites: every kept file under `canonical/`, `.claude/skills/generate-profile/`,
    `scripts/checks/`, `bin/aid`, `bin/aid.ps1` and `dashboard/` that names a skill this delivery retires, the engine,
    the shortcut catalog, a scaffolding file, `build-shortcut-skills.py` or `IMPEDIMENT.md` (the spec's list of sites
    is the minimum, not the whole). `aid-config` hits are delivery-013's, and `canonical/aid/scripts/migrate/` is
    exempt;
  - **B3** the full list of skill folders this delivery deletes, from `ls -d canonical/skills/aid-*/`: every
    remaining `aid-create-*`, `aid-update-*`, `aid-document-*` and `aid-test-*`, and `aid-prototype-ui`,
    `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`; each with whether it is a generated doorway or
    hand-authored, and the task that deletes it (task-318, task-319 or task-320);
  - **B4** for each file this delivery deletes (the folders of B3, `shortcut-engine.md`, `shortcut-catalog.yml`,
    `shortcut-scaffolding/`, `feedback-artifacts/`, `build-shortcut-skills.py`, the site's engine, sibling and doorway
    modules), every reader in `tests/`, `site/`, `dashboard/`, `.github/` and `scripts/`, and the clause or check
    that reads it;
  - **B5** the rows of `tests/conversation/deferred.tsv`, `tests/canonical/skill-steps-exempt.tsv`, the SG-04
    description exempt list and the `SUITES` list of `installer-tests.yml` that name a retired skill, a retired
    suite or the engine;
  - **B6** the format-6 conversion rows in `bin/aid` and `bin/aid.ps1` that name a retired skill (Feature 003's
    initiator rows, Feature 006's type and document rows), which the markers must wrap;
  - **B7** the impediment sites of `aid-research`, `aid-review` and `aid-report`, and every suite that asserts them.
- Give each hit exactly one owner:
  - a task of delivery-012 (task-312 to task-337; see the task files under
    `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
  - delivery-013, for a hit on `aid-config`, `.aid/kinds/`, the `domain` field, the identity statement or the kind
    hooks of `aid-review`, `aid-research` and `aid-report`;
  - delivery-014, for a hit under `docs/`, `site/src/content/docs/` (outside the generated skill pages),
    `README.md` (outside the counted phrases) or `examples/`;
  - "installed copy (resync)";
  - "history, left as is";
  - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
    site pages generated from `.aid/settings.yml` (`reference/settings.md`), which the resync could change (G8).
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-311.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-311`.
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
- [ ] Each of B1-B7 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0; B3 lists every folder `ls -d canonical/skills/aid-{create,update,document,test}-*/ canonical/skills/aid-{prototype-ui,remove,deprecate,migrate,experiment}/` prints at the base.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
