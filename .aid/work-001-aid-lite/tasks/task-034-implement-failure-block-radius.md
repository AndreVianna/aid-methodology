# task-034: Implement failure-block-radius (transitive descendants Blocked)

**Type:** IMPLEMENT

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-019, task-033

**Scope:**
- When a task Fails (Impediment that survives its one fix-on-spot): remove from in-flight set.
- Compute transitive descendant set in the Depends-On graph (BFS from failed task following reverse deps).
- Mark each descendant with Status `Blocked` via `writeback-task-status.sh`.
- Blocked tasks never enter ready set, never dispatched.
- Pool continues operating on remaining unrelated chains (tasks with no transitive dependency on the failed work).
- Pool reaches fixed point when in-flight set + ready set both empty.
- On fixed-point with any Failed/Blocked: aid-execute reports tasks Done / Failed (with Impediment refs) / Blocked (with failed-ancestor name) and exits without running the per-delivery gate (FR6×FR2 interlock).

**Acceptance Criteria:**
- [ ] Failed task: removed from in-flight; Impediment surfaced via existing mechanism.
- [ ] Transitive descendants marked Blocked (verified via BFS reverse-traversal of dep graph).
- [ ] Unrelated chains continue executing until natural completion.
- [ ] Pool fixed point with Failed/Blocked tasks: aid-execute exits cleanly with a damage-radius report.
- [ ] Per-delivery gate does NOT run when any task is Failed/Blocked (interlock with task-022).
- [ ] Unit tests for BFS transitive computation; integration test with seeded failure.
- [ ] All §6 quality gates pass.
