# task-023: End-to-end two-tier review TEST

**Type:** TEST

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** task-021, task-022

**Scope:**
- Run `/aid-execute` against a sample delivery with 3+ tasks (one task seeded with a `[CRITICAL]`, one with a `[HIGH]`, one clean).
- Verify quick-check fires once per task, surfaces only `[CRITICAL]`+`[HIGH]`, applies one critical fix.
- Verify deferred-`[HIGH]` logged to `delivery-NNN-issues.md`.
- Verify per-delivery gate runs once at the end, produces deterministic grade.
- Run a variant where one task fails — verify gate does NOT fire (FR6 interlock).
- Capture results in `.aid/work-001-aid-lite/test-reports/task-023-two-tier-e2e.md`.

**Acceptance Criteria:**
- [ ] Quick-check fires exactly once per task; gate fires exactly once per delivery.
- [ ] Critical fix applied on the spot; major-and-below deferred to `delivery-NNN-issues.md`.
- [ ] Gate's deterministic grade matches `grade.sh` standalone invocation on the same issue list.
- [ ] FR6 interlock verified: gate does not fire when any task is Failed/Blocked.
- [ ] All 5 ACs from feature-004 § Acceptance Criteria verified.
- [ ] Tests deterministic + clean setup/teardown.
- [ ] All §6 quality gates pass.
