# task-007: Per-speaker ordering on read, and the gap-grace rule

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-31

**Depends on:** task-006

**Scope:**
- Reorder within each sender by `sender_seq`, holding back a message whose immediate predecessor has not arrived; nothing held back across senders.
- A gap older than `gap_grace` declared permanent: the successor released and the skip written to the audit log.
- The whisper filter's position in the pipeline fixed as **after** ordering, so a message the caller cannot see never creates a gap for that sender.

**Acceptance Criteria:**
- [ ] One speaker's messages are returned in that speaker's order even when they arrived interleaved with another's.
- [ ] A message whose `sender_seq` predecessor is absent is withheld; when the predecessor arrives, both are returned in that speaker's order.
- [ ] A gap older than `gap_grace` releases the successor and writes a skip to the audit log -- a speaker is never stalled forever, and never silently.
- [ ] A message filtered out for this caller does not stall that sender's later messages; verified by filtering one and asserting the next is returned.
- [ ] Two callers observing two speakers in different relative orders is a **pass**, asserted as such by a test.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
