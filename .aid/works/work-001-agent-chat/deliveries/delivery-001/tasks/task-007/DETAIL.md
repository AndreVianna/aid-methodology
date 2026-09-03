# task-007: Read path: per-speaker order, gap grace, the contiguous prefix and ack

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-6, AC-31, AC-32

**Depends on:** task-006

**Scope:**
- `inbox` returning messages after the caller's baseline -- `acked_seq`, or the `cursor` override.
- Reorder within each sender by `sender_seq`, holding back a message whose immediate predecessor has not arrived; nothing held back across senders.
- A gap older than `gap_grace` declared permanent: the successor released and the skip recorded in the audit log.
- The point at which the whisper filter applies reserved, and stated to run **after** ordering so a filtered message never creates a gap.
- `delivered_seq` advanced to the **contiguous prefix**, including when everything in the window was filtered; nothing moved under a `cursor` override.
- `ack` refusing a cursor ahead of `delivered_seq`.

**Acceptance Criteria:**
- [ ] With no subscriber armed, a message is readable at the session's next turn.
- [ ] One speaker's messages are returned in that speaker's order even when they arrived interleaved with another's.
- [ ] A message whose `sender_seq` predecessor is absent is withheld and `delivered_seq` stops **below** it; when the predecessor arrives, both are returned in order.
- [ ] A gap older than `gap_grace` releases the successor and writes a skip to the audit log -- a speaker is never stalled forever, and never silently.
- [ ] A window in which every message was filtered still advances `delivered_seq`.
- [ ] A `cursor` override moves neither position, and acknowledging a message seen only under an override fails with `ack_ahead_of_delivered`.
- [ ] A message delivered but never acknowledged is returned again after an interruption, and is identifiable as a repeat by its key.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
