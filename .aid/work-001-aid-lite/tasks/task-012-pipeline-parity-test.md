# task-012: End-to-end pipeline parity TEST

**Type:** TEST

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010, task-011

**Scope:**
- Run the full AID pipeline against a sample work: `/aid-init` → `/aid-discover` → `/aid-interview` → `/aid-specify` → `/aid-plan` → `/aid-detail` → `/aid-execute` (one trivial task) → `/aid-deploy` → `/aid-monitor` smoke.
- Run the same pipeline against the pre-refactor snapshot (recorded artifacts from a known-good prior run).
- Diff the state-machine transitions, the artifacts produced, the feedback loops triggered.
- Capture a 1-page parity report in `.aid/work-001-aid-lite/test-reports/task-012-pipeline-parity.md`.

**Acceptance Criteria:**
- [ ] Every state transition observed pre-refactor is observed post-refactor (same state names, same order).
- [ ] Every artifact produced pre-refactor is produced post-refactor (same paths, same shape).
- [ ] Every feedback loop firing pre-refactor fires post-refactor.
- [ ] No new errors, warnings, or methodology violations in the post-refactor run.
- [ ] Parity report committed.
- [ ] Tests are deterministic + clean setup/teardown.
