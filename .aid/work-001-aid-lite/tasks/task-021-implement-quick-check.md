# task-021: Implement per-task quick-check in aid-execute

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** task-009, task-019, task-020

**Scope:**
- Replace the per-task full review loop with a single quick-check pass.
- Dispatch a cheap-tier reviewer with prompt scoped to: surface only `[CRITICAL]` and `[HIGH]` issues; no grade loop.
- On `[CRITICAL]`: apply one immediate fix; on remaining major-and-below: log to `delivery-NNN-issues.md` for the delivery gate.
- Write quick-check results (Reviewer Tier + Findings) into the task's row in work `STATE.md ## Tasks Status` via `writeback-task-status.sh`.
- Write deferred `[HIGH]` entries to `.aid/work-NNN/delivery-NNN-issues.md` (instance file).

**Acceptance Criteria:**
- [ ] Per-task review reduces from N-cycles to exactly 1 pass.
- [ ] Only `[CRITICAL]` + `[HIGH]` surfaced; cheap-tier reviewer used.
- [ ] Critical triggers exactly one immediate fix attempt.
- [ ] Deferred `[HIGH]` entries written to `delivery-NNN-issues.md`.
- [ ] Per-task row in `## Tasks Status` updated correctly via the helper (verified by inspection).
- [ ] Severity vocabulary mapping ('major' → `[HIGH]`, 'critical' → `[CRITICAL]`) preserved.
- [ ] Unit tests for the dispatch + write flow.
- [ ] All §6 quality gates pass.
