# task-033: Implement pool dispatch in aid-execute (Agent tool + run_in_background)

**Type:** IMPLEMENT

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-009, task-019, task-031

**Scope:**
- Replace aid-execute's sequential per-task dispatch with a continuous pool model.
- Pool primitive: Agent tool with `run_in_background: true` + completion-notification handling (IQ6 resolution).
- Pool loop: (1) read MaxConcurrent from STATE.md metadata; (2) compute initial ready set (tasks with no Pending deps); (3) fill pool up to MaxConcurrent via FIFO admission from ready set; (4) wait for any one completion notification; (5) update task Status via `writeback-task-status.sh`; (6) recompute ready set (newly unblocked tasks); (7) goto step 3 until fixed point.
- Per-task dispatch reads task definition from `tasks/task-NNN.md` (6-section flat); reads/writes per-task Status via work `STATE.md ## Tasks Status` row.

**Acceptance Criteria:**
- [ ] Pool admits up to MaxConcurrent tasks simultaneously.
- [ ] FIFO admission from ready set when multiple tasks ready at once.
- [ ] On any completion: newly unblocked tasks (deps all `Done`) are added to ready set and dispatched immediately when slot frees.
- [ ] No wave-barrier — pool reacts to each completion independently.
- [ ] Pool reaches fixed point when ready set + in-flight set both empty.
- [ ] Per-task Status writes go through `writeback-task-status.sh` (single-writer per task by construction).
- [ ] Unit tests for the pool loop with synthetic ready-set scenarios (2-task chain; diamond; fan-out).
- [ ] Integration test: dispatch 5 trivial parallel tasks; verify they run concurrently (timestamps overlap).
- [ ] All §6 quality gates pass.
