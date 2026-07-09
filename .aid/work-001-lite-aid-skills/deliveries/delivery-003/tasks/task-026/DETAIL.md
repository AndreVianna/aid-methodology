# task-026: Analyze/Report family scaffold test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-025

**Scope:**
- Fixture: `aid-report` produces a flattened work whose `tasks/task-001/DETAIL.md` is `RESEARCH`-typed (EDA + recommendation), halting pre-Execute (FR-10) -- proving the non-code default-type mapping and the G4 -> G11 reclassification.
- Fixture: `aid-show-dashboard` asserts an `IMPLEMENT`-typed `task-001` with `### Telemetry & Tracking` activated (AC-4).

**Acceptance Criteria:**
- [ ] report -> RESEARCH `task-001`; show-dashboard -> IMPLEMENT `task-001` + `### Telemetry & Tracking`; both halt pre-Execute.
- [ ] Test is deterministic with clean setup/teardown; covers feature-011 ACs.
- [ ] All §6 quality gates pass.
