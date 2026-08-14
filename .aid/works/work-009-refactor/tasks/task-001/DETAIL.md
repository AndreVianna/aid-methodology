# task-001: Record the pre-refactor test baseline and triage the FR-13 test change-set

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-001/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-009-refactor -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Runs FIRST, on the untouched pre-refactor tree: no file outside this work folder may be
  modified before this task completes, because the baseline it records is the only oracle SP-16
  has for telling an intended format-asserting update from a regression.
- Run and record, from each suite's OWN summary line (never a grep over stdout --
  `test-landscape.md § Test Commands`): `HOME="$(mktemp -d)" bash tests/run-all.sh` and
  `python -m pytest dashboard/reader/tests dashboard/server/tests`.
- Produce the baseline document at `.aid/works/work-009-refactor/test-baseline-pre-refactor.md`:
  per suite, the suite name, its own summary counts, and the per-test pass/fail set. Includes the
  suites already known to be red/skipped pre-refactor, so a pre-existing failure is not later
  mistaken for a regression.
- Triage the `REQUIREMENTS.md` FR-13 candidate inventory (47 files under `tests/`, 37 under the
  `dashboard/**/tests/` trees -- the 51 figure in that inventory is the count for *all* of
  `dashboard/`, not for its test trees) into IN-SCOPE-to-edit vs MUST-NOT-EDIT, taking
  `SPEC.md § L-9` as the settled starting point and extending it to every remaining file: in-scope
  includes `tests/canonical/test-writeback-state.sh`, `test-disjoint-merge.sh`,
  `test-delivery-gate-aggregate.sh`, `test-task-state-transitions.sh`,
  `test-work-state-template.sh`, `test-pipeline-status-walkthrough.sh`, `test-delete-pipeline.sh`,
  `test-shortcut-engine-contract.sh`, `test-housekeep-workfolder-safety.sh`,
  `test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`,
  `test-aid-cli-parity.sh`, the four further template-referencing suites
  `test-connector-consumption-linkage.sh`, `test-ticket-retirement-structural.sh`,
  `test-cutover-no-dangling.sh` and `test-describe-full-only.sh`,
  plus `dashboard/reader/tests/test_work003_state_schema.py`,
  `test_work001_delivery_layouts.py`, `test_flattened_layout_parity.py`,
  `test_task014_fixtures.py`, `test_integration.py`, `test_reader.py`, `test_derivation.py`;
  MUST-NOT-EDIT includes `test-discover-preflight.sh`, `test-summarize-preflight.sh`,
  `test-kb-freshness-check.sh`, `test-grade-summary.sh`, `test-kb-review-surface.sh` (discovery
  ledger only), and `test-migrate-hierarchy.sh` plus
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/` (triaged out by
  `SPEC.md § L-6`).
- Enumerate, per in-scope suite, each individual assertion expected to INVERT or change -- e.g.
  `test-writeback-state.sh` Unit 14's `|` rejection, which inverts under FR-4b -- naming suite +
  unit/test id. This enumerated change-set is what SP-16 compares against, so an *understated*
  enumeration is itself a defect: an assertion that regresses in an unlisted suite is
  indistinguishable from one intentionally updated. `test-work-state-template.sh` is the worked
  example `SPEC.md § L-9` gives -- its index runs WS01-WS20 (16 live; WS06/WS11/WS17/WS18 removed),
  most assertions resolve a renamed `*-state-template.md` path (`:55-57`, `:61`), and eight
  break on content (WS01, WS02's four bold-line field checks, WS05's whole-line `active_skill:`
  assertion, WS08, WS12, WS13, WS15,
  WS16). Enumerate the other in-scope suites to that same depth rather than
  by suite name alone.
- Record the current `tests/coverage-baseline.tsv` / `tests/coverage-baseline.meta` state as the
  pre-refactor marker for the re-bootstrap task-019 performs.
- RESEARCH type-defaults: findings-document only, no code/test/template/doc change. The
  "compare at least 2 alternatives" default is **recorded as overridden** -- this is a measurement
  and inventory task; there is no live alternative to compare (`task-type-rules.md § RESEARCH`).

**Acceptance Criteria:**
- [ ] The baseline document exists at `.aid/works/work-009-refactor/test-baseline-pre-refactor.md`
      and records, for every suite in `tests/run-all.sh` and both pytest directories, the suite
      name, its own summary-line counts, and the per-test pass/fail set (SP-16).
- [ ] Every count in the baseline is quoted from the suite's own summary line; no count is derived
      by grepping stdout, and any suite that timed out or hung is recorded as such rather than
      counted (`test-landscape.md § Test Commands`).
- [ ] Baseline capture happened before any edit: `git status` at capture time shows no modified
      file outside `.aid/works/work-009-refactor/`.
- [ ] Every file in the FR-13 candidate inventory that references a state file is classified
      IN-SCOPE or MUST-NOT-EDIT with a one-line reason; the five discovery-ledger-only suites,
      `test-migrate-hierarchy.sh` and the `work-999-migration-test` fixture tree are classified
      MUST-NOT-EDIT (editing one is itself a scope defect).
- [ ] The change-set enumerates each assertion expected to change, by suite plus unit/test id,
      including `test-writeback-state.sh` Unit 14's inverting `|` rejection.
- [ ] The pre-refactor `tests/coverage-baseline.tsv` row count and `coverage-baseline.meta`
      contents are recorded as the re-bootstrap marker for task-019.
- [ ] No product code, test, template, script or doc is modified: `git diff --name-only` lists
      paths under `.aid/works/work-009-refactor/` only.
- [ ] No permanent artifact (KB doc, test, script, template) cites the baseline document -- it is
      transient work-folder state (`CLAUDE.md § Tracking discipline`).
- [ ] All section-6 quality gates pass.
