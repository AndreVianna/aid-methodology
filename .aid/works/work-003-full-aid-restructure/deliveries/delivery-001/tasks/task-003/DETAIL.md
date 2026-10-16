# task-003: Work-state templates with intent and sources, without ticket_ref

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-29

**Depends on:** task-001

**Scope:**
- Edit `canonical/aid/templates/work-state-template.yml`.
  - Add `intent:` with `request`, `reading`, `reason`, `depth`, `phases` (a block list) and `changes: []`.
  - Add `sources: []` and `write_backs: []` (Q134, D7).
  - Comment the new keys in the template's `[W]` style, following REQUIREMENTS.md § 11 Feature 001
    `##### 1. Files and layout` and `##### 4. External sources`.
  - Remove `ticket_ref` and its note.
- `canonical/aid/templates/delivery-state-template.yml` and `canonical/aid/templates/task-state-template.yml`:
  remove `ticket_ref` and its notes.
- `canonical/aid/templates/requirements/requirements-template.md`: remove the feature `**Ticket:**` line
  and its `ticket_ref` comment.
- Suites to update in this same task:
  - `tests/canonical/test-work-state-template.sh`;
  - `tests/canonical/test-ticket-retirement-structural.sh` T087-T089;
  - the template assertions of `tests/canonical/test-connector-consumption-linkage.sh`;
  - `dashboard/server/tests/test_task033_execution_control_round_trips.py`;
  - any suite the findings' S3 or S6 assigns here.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-003`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-003: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-003`.
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
     - Run `(cd site && npm test)` when this task changes `canonical/skills/`,
       `canonical/aid/templates/shortcut-catalog.yml`, `docs/` or `site/`. Run `npm ci` there first if
       `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `git grep -n ticket_ref` over the four edited templates finds nothing, and `git grep -n '\*\*Ticket:\*\*' canonical/aid/templates/requirements/requirements-template.md` finds nothing. This is the template clause of the gate's AC-29 criterion, which task-007 completes.
- [ ] `intent:` holds the six keys in block style, and `sources: []` and `write_backs: []` are top-level keys. `grep -nE '^[^#]*:[[:space:]]*[[{][^]}]' canonical/aid/templates/work-state-template.yml` finds nothing (no flow collection but `[]` or `{}`), and no key sits deeper than three levels (KI-002).
- [ ] Both dashboard readers, `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs`, parse the edited template with no warning; the command used is in the report. `tests/canonical/test-dashboard-reader.sh` and `tests/canonical/test-dashboard-parity.sh` pass.
- [ ] `test-work-state-template.sh` and `test-ticket-retirement-structural.sh` pass in the scratch copy. `test-connector-consumption-linkage.sh` and `test_task033_execution_control_round_trips.py` pass live.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
