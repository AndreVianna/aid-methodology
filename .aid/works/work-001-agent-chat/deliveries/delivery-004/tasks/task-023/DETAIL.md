# task-023: Replication, the outbox drain and membership

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-5, AC-13

**Depends on:** task-022

**Scope:**
- The `outbox` and `channel_member` tables.
- A send delivered to every peer holding a member of that channel -- immediately where reachable, queued where not, drained oldest-first on reconnect.
- The receiving hub assigning **its own** `arrival_seq` and storing the sender's `sender_seq` **verbatim**.
- Dedupe on the sender-scoped key, which is what absorbs a replay.
- Membership replicated as its own kind, so replication targeting and the solo-send check become computable.
- **This task completes the cross-machine clause of `AC-13`** -- "on whichever machine each member sits" -- which delivery-001 built fan-out for but could not verify with one machine. `AC-13` stays owned by delivery-001; this task answers to the half that needs a peer.

**Acceptance Criteria:**
- [ ] A message sent while a peer is unreachable reaches that peer on reconnect, and its local member reads it.
- [ ] A message replayed after a reconnect is absorbed rather than duplicated -- exactly one row remains.
- [ ] A receiving hub stores the sender's `sender_seq` unchanged; verified by comparing the rows on both hubs.
- [ ] Per-speaker order holds on the receiving hub even when messages arrive out of order across the network.
- [ ] A sender alone on its own hub but not alone in the channel **can** send -- the solo check counts remote members.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
