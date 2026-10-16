# task-104: Delivery-005 site search and reconciled edit list

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

**Type:** RESEARCH

**Source:** feature-004-kb-management -> delivery-005 -> AC-15, AC-25

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`):
  - **K1** the retired names `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize` and
    `aid-housekeep`, over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`,
    `.github/` and `.aid/knowledge/`;
  - **K2** the moved references by their old paths: `aid-discover/references/...`,
    `aid-update-kb/references/...` and `aid-ask/`;
  - **K3** `.aid/knowledge/STATE.md`, and the KB `STATE.md` vocabulary (`summary_approved`,
    `kb_baseline`, `## Q&A (Pending)`, `## Summarization History`);
  - **K4** `AID_SUPPORTED_FORMAT`, `AidSupportedFormat` and `format_version: 5`, plus every suite that
    asserts format 5;
  - **K5** the readers of `knowledge.source`, `knowledge.last_update` and KB state in `complexity-score.sh`;
  - **K6** the summarize and housekeep scripts, suites and CI steps (`test.yml`, `release.yml`, the root
    `package.json`, `.github/dependabot.yml`);
  - **K7** the Q106 suite map for every file on the edit list, including the dashboard KB tests and
    fixtures and the site's skill lists;
  - **K8** the rows of `deferred.tsv`, the SG-04 exempt list and `test-never-merges.sh` (NM-03) that
    name a retiring or moving skill.
- Give each hit exactly one owner:
  - a task of delivery-005 (task-105 to task-139; see the task files under
    `.aid/works/work-003-full-aid-restructure/deliveries/delivery-005/tasks/`);
  - delivery-006 (the KB `create`/`update` skills, `design-lifecycle.md`);
  - "installed copy (resync)";
  - "history, left as is";
  - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html` and
    `.aid/knowledge/INDEX.md`, and in the site pages generated from `.aid/settings.yml`
    (`reference/settings.md`), which the resync changes (G8).
- **K9** every `git commit` and `git push` under `canonical/skills/aid-discover/`,
  `canonical/skills/aid-update-kb/` and `canonical/aid/scripts/housekeep/`. Each gets its owner: the task
  that writes the file in which it stands, and that task removes it. The build commits once, at FINISH,
  through `kb-commit.sh`, and pushes nothing (F004 Flows step 6).
- **Content owner of every moved file (G7).** A table with one row per file under `aid-discover/`,
  `aid-update-kb/` and `aid-ask/` at the base. Each row names its new path and the one task that owns its
  content: task-116 or task-123 for `aid-kb-build`, task-117 or task-124 for `aid-kb-update`, task-119 for
  `aid-kb-query`, and task-129 for the references that no skill task rewrites (for example
  `agent-prompts.md`, `doc-set-resolve.md`, `path-config.md`, `reviewer-prompt.md` and `reviewer-prompt-*.md`).
- In a delta section, list each suite assigned to two independent tasks, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-104: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-104`.
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
- [ ] Each of K1-K9 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0. The content-owner table has one row per moved file at the base (its count equals `git ls-files canonical/skills/aid-discover canonical/skills/aid-update-kb canonical/skills/aid-ask | wc -l`), each with exactly one owner.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
