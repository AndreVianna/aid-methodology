# task-022: Implement per-delivery quality gate (closing step of aid-execute) + FR6 interlock

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** task-019, task-020, task-021

**Scope:**
- Insert per-delivery quality gate as the closing step of aid-execute, after all tasks reach `Done` (gate does NOT run while any task is `Failed` or `Blocked` — FR6 interlock).
- Step 0 (AGGREGATE): read `delivery-NNN-issues.md` (deferred-`[HIGH]` log accumulated from quick-checks).
- Step 1 (REVIEW): dispatch a proportional-tier reviewer (tier computed from delivery complexity score — number of tasks, code surface, integration count).
- Step 2 (FIX): apply review fixes; run review→fix→review loop.
- Step 3 (GRADE): invoke `grade.sh` on the aggregated severity-tagged issue list; compare to project minimum grade.
- Step 4 (WRITE): write final grade + issue list to `## Delivery Gates` block in work `STATE.md` via `writeback-task-status.sh --delivery-id NNN --block ...` (note: despite the helper's name implying task-only scope, the helper is general per task-019 — it handles row updates, quick-check findings, delivery gate blocks, AND deferred-issue file appends via different `--` arg modes).
- Step 5 (HANDOFF): if grade >= minimum → delivery complete; else → loopback to fix.

**Acceptance Criteria:**
- [ ] Gate runs exactly once per delivery (after all tasks done; not while any task Failed/Blocked).
- [ ] Reviewer tier scales with complexity (verified via 3 sample deliveries of varying size).
- [ ] AGGREGATE step correctly reads deferred-`[HIGH]` log + merges with fresh gate findings.
- [ ] `grade.sh` runs deterministically + produces grade letter.
- [ ] `## Delivery Gates` block written correctly via the helper.
- [ ] Loopback on grade < minimum loops to fix without re-running quick-checks.
- [ ] FR6 interlock verified: with one task Failed, gate does not fire.
- [ ] Unit tests for AGGREGATE + grade-output + loopback.
- [ ] All §6 quality gates pass.
