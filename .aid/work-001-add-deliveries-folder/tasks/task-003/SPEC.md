# task-003: Fixtures + tests for both delivery-folder layouts

**Type:** TEST

**Source:** work-001-add-deliveries-folder → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Add new dashboard fixtures for **both** layouts (shared by the Python and Node suites):
  - Lite-flat: `work-NNN/tasks/task-NNN/…` with the single gate/Q&A in the work-root `STATE.md`.
  - Full-nested: `work-NNN/deliveries/delivery-NNN/tasks/task-NNN/…`.
- Update existing dashboard/parse tests **and the execute-phase script tests that embed flat
  delivery fixtures** (`tests/canonical/test-writeback-state.sh`, `test-delivery-gate-aggregate.sh`,
  and any `complexity-score`/`compute-block-radius` tests) — plus any other fixtures that assumed a
  flat delivery folder.
- Run both reader twins against the new fixtures and assert byte-parity outputs for both layouts.
- Run the full existing suite (dashboard reader tests, parse tests, byte-parity) — all pass, no
  behavior regression.
- Final repo-wide grep-clean verification: zero lingering old flat `work-NNN/delivery-NNN/`
  folder-location references (excluding the legitimate `delivery-NNN-issues.md` sibling file).

**Acceptance Criteria:**
- [ ] New fixtures for BOTH layouts (lite-flat + full-nested) exist and pass in BOTH reader twins with byte-parity output. *(SPEC AC 6)*
- [ ] Final repo-wide grep-clean sweep confirms no lingering old flat `work-NNN/delivery-NNN/` references. *(SPEC AC 10)*
- [ ] All existing tests pass — no behavior regression; full suite green. *(SPEC AC 11)*
- [ ] All project quality gates pass. *(SPEC AC 12)*
