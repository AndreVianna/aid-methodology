# task-022: Prototype family scaffold test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-021

**Scope:**
- Fixture: invoking `aid-prototype-ui` on a representative description produces a flattened Lite work -- `REQUIREMENTS.md` + `SPEC.md` (with `### UI Specs` activated, Data Model "no schema changes") + `PLAN.md` + `tasks/task-001/` typed `DESIGN` -- and halts pre-Execute (FR-10). Proves the binding drives the correct DESIGN-typed shape.

**Acceptance Criteria:**
- [ ] prototype-ui -> DESIGN `task-001` + `### UI Specs`; Data Model "no schema changes"; halts pre-Execute.
- [ ] Test is deterministic with clean setup/teardown; covers feature-005 ACs.
- [ ] All §6 quality gates pass.
