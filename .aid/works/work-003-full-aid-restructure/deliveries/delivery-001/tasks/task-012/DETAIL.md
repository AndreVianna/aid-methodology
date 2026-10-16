# task-012: KB decisions, backlog and record documents for plain requests

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

**Type:** DOCUMENT

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-23, AC-24, AC-29

**Depends on:** task-007, task-009

**Scope:**
- Edit these documents under `.aid/knowledge/`, as REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration`
  (KB, and Release notes) says:
  - `decisions.md`: a new decision, "the host agent orchestrates".
    - It supersedes D21 and D25's change-request route to `/aid-triage`. Both are marked Superseded in
      the summary table and in their sections.
    - It amends D14 (its pointer to D21) and D15 (the agent count).
  - `backlog.md` § Next Release: the old -> new rows for `/aid-triage` and the `aid-orchestrator` agent
    (AC-24).
  - `tech-debt.md`: row W1-6 (the `aid-triage` roster entry).
  - `infrastructure.md`: its `ticket_ref` traceability sentence.
  - `artifact-schemas.md`: the Pipeline State, Delivery Lifecycle and Task State rows lose `ticket_ref`,
    and `intent:`, `sources:` and `write_backs:` are added.
  - `integration-map.md`: `intent:` and `sources:`.
- Name no work and no work folder. Follow the `kb-doc` criteria of `.aid/knowledge/authoring-conventions.md`.
- Suites to update in this same task: any suite the findings' S6 lists that reads these documents.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-012`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-012: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-012`.
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
- [ ] `.aid/knowledge/backlog.md` § Next Release has the `/aid-triage` and `aid-orchestrator` rows, with the New text of Feature 001 `##### 5. Migration` (AC-24, the G0 item).
- [ ] D21 and D25 read Superseded in both places, and D14 and D15 are amended (AC-23). `git grep -n ticket_ref -- .aid/knowledge/artifact-schemas.md .aid/knowledge/infrastructure.md` finds nothing (AC-29).
- [ ] `git grep -n -E 'work-[0-9]{3}'` over the six documents finds nothing. `bash .aid/runtime/scripts/kb/kb-citation-lint.sh` and `bash .aid/runtime/scripts/kb/lint-frontmatter.sh` pass on them.
- [ ] Accuracy: each edited statement matches `canonical/` as task-007 and task-009 leave it.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
