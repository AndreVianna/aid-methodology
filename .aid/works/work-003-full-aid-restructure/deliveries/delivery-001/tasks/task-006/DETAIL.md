# task-006: aid-orchestrate skill and its five references

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-2, AC-3, AC-4, AC-7, AC-14, AC-29

**Depends on:** task-002, task-003, task-007

**Scope:**
- Create `canonical/skills/aid-orchestrate/SKILL.md`, at most 80 lines.
  - `name: aid-orchestrate`, and the description verbatim from REQUIREMENTS.md § 11 Feature 001
    `##### 3. Components`.
  - It runs in the main conversation and dispatches no sub-agent.
- Create `canonical/skills/aid-orchestrate/references/`, each file at most 120 lines (Feature 001
  `##### 2. Orchestration flow`, `##### 3. Components` and `##### 4. External sources`):
  - `start-or-resume.md`: find or create the work by citing `.aid/runtime/scripts/works/enumerate-works.sh`
    and `.aid/runtime/templates/work-initiation-gate.md`, without restating them; read the resume point
    from `STATE.yml`; size the work; record `intent:`;
  - `check-intent.md`: the KB-and-code check, which reads `INDEX.md`, `capability-inventory.md`,
    `module-map.md` and `architecture.md` and classifies by observable effect; triage's question shortcut
    and work-type heuristic, moved from `canonical/skills/aid-triage/SKILL.md`; the kind hook on
    `shortcut-catalog.yml` `intent:`;
  - `size-and-route.md`: the routing rule, the phase table and the depth table; triage's scope
    judgement; the close minimum (`writeback-state.sh --pipeline --field Lifecycle --value Completed`)
    until `/aid-monitor-pipeline` exists;
  - `external-sources.md`: pull in, apply, write back through `/aid-update-ticket` `attachment` (task-007,
    a dependency), tool limits, no credential, and the `sources:` and `write_backs:` entry shapes;
  - `feedback-routing.md`: the routing table, moved from `canonical/agents/aid-orchestrator/AGENT.md`.
- Site placement: `aid-orchestrate` joins the curated roster in the Support group. task-009 later gives it
  `aid-triage`'s first place (Q134, D6).
- Count re-sync (Q134, D5): change the skill-count phrases that `tests/canonical/test-doc-counts.sh`
  asserts in `README.md` and `docs/` to the derived count, then run `(cd site && npm run sync:docs)`.
  Change only the numbers.
- Suites to update in this same task:
  - `tests/canonical/test-deploy-monitor-repurpose.sh`: its standalone, not-a-catalog-row list gains
    `aid-orchestrate`;
  - `test-doc-counts.sh`;
  - the site tests that pin the curated roster or the skill counts;
  - any suite the findings' S6 or S7 assigns here.
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-006`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-006: In Progress` commit. Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-006`.
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
- [ ] `wc -l` prints at most 80 for `SKILL.md` and at most 120 for each reference. The five reference names match the spec, `name:` equals the folder, and `description:` equals the spec's text.
- [ ] `check-intent.md` names the four KB reads and the classify-by-observable-effect rule (AC-1, AC-2, AC-3). `size-and-route.md` holds the routing-rule sentence, the phase table, the depth table and the close-minimum command (AC-7, AC-14). `start-or-resume.md` leads a project question to a KB answer with sources and no work folder (AC-4). `external-sources.md` holds the four procedures and the entry shapes (AC-29). `feedback-routing.md` holds the four routing rows.
- [ ] Every `.aid/runtime/...` pointer in the skill resolves to a file under `canonical/aid/` (SR-01), and no file under `canonical/skills/aid-orchestrate/` names an agent to dispatch.
- [ ] `test-deploy-monitor-repurpose.sh` passes in the scratch copy, `test-doc-counts.sh` passes live, and the site `npm test` passes after regeneration.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
