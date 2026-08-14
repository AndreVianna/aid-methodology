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