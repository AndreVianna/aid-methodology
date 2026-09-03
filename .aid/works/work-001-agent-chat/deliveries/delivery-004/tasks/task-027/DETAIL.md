# task-027: Membership replication

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-13

**Depends on:** task-026

**Scope:**
- The `channel_member` table, holding **remote** members only -- local membership stays `session.channel_id`, so there is no second copy to drift.
- A join, a leave, and a channel close replicated as membership records.
- The two things this makes computable: which peers to replicate a message to, and whether a sender is alone in its channel.
- **This task completes the cross-machine clause of `AC-13`** -- "on whichever machine each member sits" -- which delivery-001 built fan-out for but could not verify with one machine. `AC-13` stays owned by delivery-001.

**Acceptance Criteria:**
- [ ] A member joining on one hub appears in the other hub's `channel_member` for that channel.
- [ ] A member leaving is removed from the other hub's view; verified by reading the table.
- [ ] A sender alone on its own hub but not alone in the channel **can** send -- the solo check counts remote members.
- [ ] Local members appear in `session.channel_id` and **not** in `channel_member`; verified by reading both.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
