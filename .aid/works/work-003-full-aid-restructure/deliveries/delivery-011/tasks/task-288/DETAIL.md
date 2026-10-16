# task-288: Delivery-011 site search and reconciled edit list

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 288 --field State.

**Type:** RESEARCH

**Source:** feature-009-one-skill-per-need -> delivery-011 -> AC-20, AC-30

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-011-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 8. Migration`, Suites):
  - **Z1** the second, targeted search of REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration` ("Suites over the files this feature
    rewrites"), verbatim, read hit by hit: which hit asserts text that a delivery-011 rewrite changes (the action
    skills, `action-start.md`, the kind catalog, `close.md`, `cleanup-classify.sh`, `close-work.sh`);
  - **Z2** every reader and suite of `kind-catalog.yml` and its v1 fields (`test-idea-shaping.sh` ID-03 and ID-04,
    `check-intent.md`'s kind hook, `aid-brainstorm`'s `start.md`, the dashboard), with what each needs from v2;
  - **Z3** every suite, site module and document that counts `shortcut-catalog.yml` rows or doorways, or reads the
    `GENERATED` marker: `test-deploy-monitor-repurpose.sh` (DMR24, DMR30-DMR36), `test-shortcut-builder-invariants.sh`,
    `test-catalog-dirs-parity.sh`, `test-doc-counts.sh` and the phrases it asserts in `README.md` and `docs/`,
    `site/scripts/skills/` (`skill-counts.mjs`, `groups.mjs`, `curated-roster.mjs`, `catalog.mjs`),
    `site/scripts/gen-reference.mjs`, `site/scripts/lib/flow-graph/classify.mjs`, and
    `.claude/skills/generate-profile/SKILL.md`; each count with its value at the base and its value once the rows of
    `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` are gone;
  - **Z4** the writer's `--create`, `--reroute` and `--reading` options and their readers (tests, both dashboard
    readers, `dashboard/scripts/writeback-state.sh`), and the work-state template's `intent` block and `initiator`
    comment;
  - **Z5** the assertions of the six family-scaffold suites and of `test-deploy-monitor-repurpose.sh` on
    `aid-create`, `aid-update`, `aid-fix`, `aid-refactor`, `aid-document`, `aid-test` and `aid-prototype`: which
    one a delivery-011 rewrite breaks (owned here), and which waits for its file's deletion (delivery-012);
  - **Z6** `test-work-initiation-gate.sh` Group G (its starter list, `STARTER_ALLOC_ANCHOR`, `STARTER_COVERAGE_ID`,
    the GG00 count) and its reconciliation group's `aid-prototype` checks;
  - **Z7** the rows of `tests/conversation/deferred.tsv`, the SG-04 description exempt list and
    `tests/canonical/skill-steps-exempt.tsv` that name an action skill or a generated doorway, and how SS-09 covers
    each of the seven action skills at the base;
  - **Z8** the `canonical/aid/rules.md` § Skill guide lines of the seven action skills, and the `<kind>` lines
    (which stay until delivery-012);
  - **Z9** the catalog readers of REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Who reads the catalog, as they stand at the base
    (`aid-specify`, `aid-plan`, `aid-execute`, `aid-brainstorm`), each with the field AS-09 needs it to cite.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
  `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
  renames it, which fixes the entry in the same task (AD14).
- Give each hit exactly one owner:
  - a task of delivery-011 (task-289 to task-310; see the task files under
    `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
  - delivery-012, for a hit on a file it deletes or on the TICKET step (the wrappers, `shortcut-engine.md`,
    `shortcut-catalog.yml`, the scaffolding, `IMPEDIMENT.md`, the builder, the ticket skills);
  - delivery-013, for a hit on `aid-config`, `.aid/kinds/`, the `domain` field, or the kind hooks of
    `aid-review`, `aid-research` and `aid-report`;
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
  `BASE` is this task's `base` (`tasks_lifecycle.task-288.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-288`.
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
- [ ] Each of Z1-Z9 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
