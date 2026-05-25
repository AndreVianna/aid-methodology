# task-018: End-to-end lite path TEST

**Type:** TEST

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-013, task-014, task-015, task-016, task-017

**Scope:**
- Run `/aid-interview` against 4 sample workTypes (bug-fix, single-doc, small-refactor, small-new-feature); verify each routes to lite + selects the right sub-path.
- Verify each sub-path produces execution-ready output (work-root SPEC.md + tasks/).
- Verify `/aid-execute task-001` runs successfully against each sub-path's emitted output.
- Verify user override (LITE-BUG-FIX → LITE-FEATURE) takes effect immediately.
- Verify lite → full escalation (mid-sub-path) preserves captured slot values.
- Capture results in `.aid/work-001-aid-lite/test-reports/task-018-lite-path-e2e.md`.

**Acceptance Criteria:**
- [x] All 4 sub-paths exercised end-to-end with positive results.
- [x] User override exercised end-to-end with the right Sub-path / Sub-path (auto) / Override fields recorded.
- [x] Escalation exercised end-to-end with full-path resumption + carried info.
- [x] All AC1-4 from feature-005 § Acceptance Criteria and AC1-4 from § Type-aware extension verified.
- [x] Tests deterministic + clean setup/teardown.
- [x] All §6 quality gates pass.
