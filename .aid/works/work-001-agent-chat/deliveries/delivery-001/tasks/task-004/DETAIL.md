# task-004: Session registration, liveness and reattachment

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-3, AC-33

**Depends on:** task-003

**Scope:**
- `register(name, tool, cwd, capabilities)` minting the product's own conversation id; any host-supplied id stored as correlation metadata that nothing keys on.
- Heartbeat; stale derived from `last_heartbeat_at` rather than stored.
- Re-registering reattaches to its channel at `acked_seq` when that channel is still open, and to **no** channel when it closed.
- `next_sender_seq` reset on joining a channel.

**Acceptance Criteria:**
- [ ] Registering while supplying a host conversation id yields a **product-minted** id, and the host value appears only in `host_conversation_id`; verified by reading the row.
- [ ] A session that re-registers while its channel is open resumes at its `acked_seq`, and messages that arrived while it was gone are returned.
- [ ] A session that re-registers after its channel closed is accepted with `channel_id` null.
- [ ] A session quiet past the stale threshold reports stale while keeping its position, and its channel stays open.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
