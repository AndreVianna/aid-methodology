# task-021: Implement per-task quick-check in aid-execute

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** task-009, task-019, task-020

**Scope:**
- Replace the per-task full review loop with a single quick-check pass.
- Dispatch a cheap-tier reviewer with prompt scoped to: surface only `[CRITICAL]` and `[HIGH]` issues; no grade loop.
- On `[CRITICAL]`: apply one immediate fix; on remaining major-and-below: log to `delivery-NNN-issues.md` for the delivery gate.
- Write quick-check results into work `STATE.md` via `writeback-task-status.sh`. **Decision (/aid-detail resolution of feature-004 SPEC L82-84):** use a **separate `## Quick Check Findings` section** in work `STATE.md`, keyed by task-id, holding the per-task Reviewer Tier + Findings list. The task's row in `## Tasks Status` stores only short status fields (Status / Reviewer Tier / Findings-count); the detailed findings list lives in the keyed `## Quick Check Findings` section. Rationale: a sub-block under the row would clutter the table for scanning; a separate keyed section keeps the row scannable and the findings inspectable.
- Write deferred `[HIGH]` entries to `.aid/work-NNN/delivery-NNN-issues.md` (instance file) via `writeback-task-status.sh --append-issue` mode (task-019 helper extended; single-writer per task by construction). The instance file is initialized from the `delivery-issues.md` template (task-020) on first deferred entry.

**Acceptance Criteria:**
- [ ] Per-task quick-check produces exactly 1 reviewer dispatch per task (verified via dispatch-log count); no grade-loop iteration.
- [ ] Only `[CRITICAL]` + `[HIGH]` surfaced; cheap-tier reviewer used.
- [ ] Critical triggers exactly one immediate fix attempt.
- [ ] Deferred `[HIGH]` entries written to `delivery-NNN-issues.md`.
- [ ] Per-task row in `## Tasks Status` updated correctly via the helper (verified by inspection).
- [ ] Severity vocabulary mapping ('major' → `[HIGH]`, 'critical' → `[CRITICAL]`) preserved.
- [ ] Unit tests for the dispatch + write flow.
- [ ] All §6 quality gates pass.
