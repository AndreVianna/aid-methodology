# task-026: Outbox and the drain on reconnect

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-004-lan-federation -> delivery-004 -> AC-5

**Depends on:** task-025

**Scope:**
- The `outbox` table and its drain: queued items replayed to a peer on reconnect, oldest first.
- Queueing only where a peer is unreachable; immediate delivery where it is not.
- Attempt counting, so a peer that never returns does not hide a growing queue from the operator.

**Acceptance Criteria:**
- [ ] An item queued while a peer is unreachable is delivered on reconnect, and the queue is empty afterwards.
- [ ] Items drain oldest-first; verified by queueing three and asserting arrival order.
- [ ] A peer that never returns leaves a queue whose depth is visible to the operator; verified by listing it.
- [ ] The drain is idempotent: interrupting it mid-way and re-running delivers each item exactly once, verified by the receiving hub's row count.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
