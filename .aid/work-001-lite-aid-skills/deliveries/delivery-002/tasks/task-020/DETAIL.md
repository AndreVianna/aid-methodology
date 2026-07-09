# task-020: Test/Experiment family scaffold test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-019

**Scope:**
- Fixture: `aid-test-security` produces a flattened work with `### Security Specs` activated and `tasks/task-001/` typed `TEST` (SAST/DAST plan), halting pre-Execute (FR-10); assert findings route to `aid-fix`.
- Fixture: `aid-experiment` asserts a `RESEARCH`-typed `task-001` (the non-code default-type mapping, AC-4).
- Assert `aid-test` model-eval mode is present (TEST type; model evaluation inside bare `aid-test`).

**Acceptance Criteria:**
- [ ] test-security -> TEST + `### Security Specs`, findings route to `aid-fix`; experiment -> RESEARCH `task-001`; model-eval mode present; halts pre-Execute.
- [ ] Test is deterministic with clean setup/teardown; covers feature-009 ACs.
- [ ] All §6 quality gates pass.
