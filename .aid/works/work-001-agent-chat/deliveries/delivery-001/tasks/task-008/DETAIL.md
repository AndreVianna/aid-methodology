# task-008: The two positions: contiguous prefix, cursor override and the ack bound

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-6, AC-32

**Depends on:** task-007

**Scope:**
- `inbox` returning after the caller's baseline -- `acked_seq` by default, or the `cursor` override.
- `delivered_seq` advanced to the **contiguous prefix**: one below the first held-back message, or the highest `arrival_seq` examined when nothing was held back -- including when every message in the window was filtered.
- `cursor` as a read-only override that moves neither position and confers no right to acknowledge.
- `ack` refusing a cursor ahead of `delivered_seq`.

**Acceptance Criteria:**
- [ ] With no subscriber armed, a message is readable at the session's next turn.
- [ ] Where a message is held back, `delivered_seq` stops **below** it, and that message is delivered on a later read rather than stranded.
- [ ] A window in which every message was filtered still advances `delivered_seq`.
- [ ] A `cursor` override moves neither position, and acknowledging a message seen only under an override fails with `ack_ahead_of_delivered`.
- [ ] A message delivered but never acknowledged is returned again after an interruption, and is identifiable as a repeat by its key.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
