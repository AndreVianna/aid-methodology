# task-001: Delivery-001 site search and reconciled edit list

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-6, AC-21, AC-23, AC-29

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md`. Touch nothing else.
- Re-run the spec's stated searches at this task's base commit, and record the base commit in the file.
  The path set is `canonical/`, `site/`, `docs/`, `examples/`, `README.md`, `.aid/knowledge/`,
  `.aid/design/`, `tests/`, `dashboard/`, `bin/`, `lib/` and `.claude/skills/generate-profile/`.
  - **S1 Triage:** `aid-triage`, `/aid-triage` and "triage router". The anchor is REQUIREMENTS.md § 11
    Feature 001, `##### 5. Migration`, "Triage sites", and its final search.
  - **S2 Orchestrator:** `aid-orchestrator`, and "orchestrator" where it names that agent ("Orchestrator
    sites").
  - **S3 `ticket_ref`:** "`ticket_ref` sites".
  - **S4 `skill-routing.md`.**
  - **S5 Rules text:** the suites that assert the rules text, meaning the summary markers, the summary
    wording and the rules headings. The anchor is "Suites that assert the rules text".
  - **S6 The Q106 map.** For every file on this delivery's edit list, find the suites that read it by path
    or assert its text, in `tests/`, `site/scripts/__tests__/` and the dashboard tests.
  - **S7 Count checks:** the suites that derive counts from `canonical/skills/` or `canonical/agents/`
    (`tests/canonical/test-doc-counts.sh`, `site/scripts/__tests__/skill-counts.test.mjs`), with the
    phrases they assert.
  - **S8 Description checks:** the suites and site tests that read a `SKILL.md` `description:`, and the
    `description = (` template in `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`.
  - **S9 The SG-04 exempt list.** List every skill whose deletion or rename a later feature's
    `##### 1. Files and layout` states, each with that anchor. Skills that keep their name are not exempt,
    and that includes the ones a later feature rebuilds (Q134, D4).
  - **S10 Site page classes.** Class each site hit as generated (`gen-skills.mjs`, `gen-reference.mjs`),
    synced (`sync-docs.mjs`) or hand-written.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
  `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
  renames it, which fixes the entry in the same task (AD14).
- **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
  skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
- Give each hit exactly one owner:
  - a task of delivery-001 (task-002 to task-019; see the task files under
    `.aid/works/work-003-full-aid-restructure/deliveries/delivery-001/tasks/` for what each owns);
  - "installed copy (resync)", for `.claude/skills/aid-*`, `.agents/`, `.aid/runtime/`, `profiles/`,
    `.claude/agents/`, `.cursor/agents/` and `.aid/.aid-manifest.json`;
  - "history, left as is", for `.aid/knowledge/release-tracking.md`, `tests/coverage-accepted-removals.tsv`
    and `.aid/knowledge/kb.html`.
- Add a delta section listing:
  - each hit the spec's lists omit;
  - each spec-listed path with no hit;
  - each suite assigned to two tasks that do not depend on each other, with the order to run them.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-001: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-001`.
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
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] Each of S1-S10 shows its exact command. Re-running each command at the base commit named in the file reproduces its hit list line for line.
- [ ] Every hit row has exactly one owner from the classes above. The count of rows with an empty owner cell is 0.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] The delta section lists every hit the spec omits and every spec-listed path with no hit, each with its owner, plus any suite assigned to two independent tasks, with the order to run them.
- [ ] The S9 exempt list names, per row, the skill and the anchor of the later feature that deletes or renames it. No skill that keeps its name through v4.0.0 appears in it.
- [ ] RESEARCH defaults overridden: the spec fixes the searches, so there are no alternatives to compare. The recorded commands are the cited sources. The test step runs no suite, because every change lies under `.aid/works/` (its work-folder-only rule).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
