# task-016: Update the in-scope dashboard reader/server suites to the YAML state format

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-016/STATE.md` -- this task's mutable cells live
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

**Type:** TEST

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-004, task-020

**Scope:**
- Update every IN-SCOPE reader/server suite the task-001 change-set enumerates so its fixtures emit
  `STATE.yml` in the `SPEC.md § D-4` shapes and its assertions target the new keys, while asserting
  the SAME model/payload values as before: `dashboard/reader/tests/test_work003_state_schema.py`,
  `test_work001_delivery_layouts.py`, `test_flattened_layout_parity.py`, `test_task014_fixtures.py`,
  `test_integration.py`, `test_reader.py`, `test_derivation.py`,
  `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` (the oracle for the
  `SPEC.md § L-11` write-path property, AC-13b / SP-19b -- see the added assertion below), plus any
  other suite under `dashboard/reader/tests/` or `dashboard/server/tests/` that the task-001 triage
  classified IN-SCOPE (each of those suites builds its own fixtures, so the change is
  fixture-emission plus key-name assertions, not a new harness).
- Suites whose subject is a deleted symbol (`hasTableSep`, `extractLatestHistoryDate`, the six
  deleted per-section line parsers, the prose fallbacks) have those assertions removed and the
  removal recorded against the task-001 change-set -- a deleted symbol's test is not a regression,
  but an unrecorded deletion is.
- Add the assertions the new read path needs in each suite's own idiom: the legacy-`STATE.md`
  detector's warning naming the migration command, the unknown-key and truncated-file degradation
  paths, and the one-read-per-work property (SP-9, SP-10).
- Add the SP-19b write-path assertions to
  `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py`, in its own cross-runtime
  idiom: against a converted work, each of the three write-enabled edit surfaces (task set-notes,
  pipeline `Lifecycle=Completed`, task rename) writes successfully to `STATE.yml` in **both**
  runtimes with identical results, and the raw-state viewer resolves the same source path in both.
  This is the only oracle that can catch a half-retargeted `AID_STATE_FILE`, because the failure is
  a writer `exit 1` on a nonexistent path with no reader-side symptom (`SPEC.md § L-11`, task-020).
- Assertions that reference the out-of-scope `.aid/knowledge/STATE.md` KB ledger -- including any
  covering `SKIP_NAMES` or `join(kbDir, "STATE.md")` -- must keep asserting `STATE.md` there. Do not
  retarget them; they are the guard proving the ledger was not converted.
- OUT of this task: the shared conformance corpus (task-005) and the cross-format characterization
  suite (task-011), which are new suites, not updates; the canonical shell suites (task-015);
  `tests/coverage-baseline.tsv` (task-019).

**Acceptance Criteria:**
- [ ] `python -m pytest dashboard/reader/tests dashboard/server/tests` passes, per pytest's own
      summary line (SP-16, `test-landscape.md § Test Commands`).
- [ ] Every assertion changed or removed corresponds to an entry in the task-001 change-set; any
      change not on that list is added to it with a stated reason before this task closes (SP-16).
- [ ] Each updated suite still asserts the same model/payload values it asserted pre-refactor for
      the equivalent work -- the fixtures change format, the expectations do not (SP-2, SP-8).
- [ ] `test_flattened_layout_parity.py` still asserts that `reader.py` and `reader.mjs` read the
      SAME fixture identically, now over a `STATE.yml` fixture (NFR-1, SP-8).
- [ ] `test_task014_fixtures.py`'s hierarchical fixture covers the full layout's three state-file
      levels in the new format (SP-7, SP-8).
- [ ] New assertions cover the legacy-`STATE.md` detector (warning names the migration command), the
      empty/truncated/unknown-key degradation paths, and one-read-per-work (SP-9, SP-10).
- [ ] `test_write_enabled_cross_runtime_parity.py` asserts the SP-19b property behaviorally against a
      converted work: all three write-enabled edit surfaces succeed against `STATE.yml` in both
      runtimes with identical results, and both resolve the same raw-state source path -- so a
      one-runtime or partial `AID_STATE_FILE` retarget in task-020 fails this suite (SP-19b, C-4).
- [ ] Assertions guarding the out-of-scope KB ledger still assert `STATE.md`, and the diff shows
      they were not retargeted (scope-defect guard).
- [ ] Every suite stays stdlib-only and runs with no third-party package installed (SP-17), is
      deterministic, and cleans up its temp state (`task-type-rules.md § TEST`).
- [ ] A first-run failure is reported as a finding, not hidden; any defect it exposes in
      task-003/task-004's files is fixed there and named in this task's commit message.
- [ ] All section-6 quality gates pass.
