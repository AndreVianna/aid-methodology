# task-028: Message replication with per-hub arrival order

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

**Depends on:** task-027

**Scope:**
- A send delivered to every peer holding a member of that channel, using `channel_member` to decide which.
- The receiving hub assigning **its own** `arrival_seq` and storing the sender's `sender_seq` **verbatim** -- the one field it must not regenerate.
- Dedupe on the sender-scoped key, which is what absorbs a replay after a reconnect.
- Replication attempted only to a peer whose handshake succeeded, so a major-version mismatch never receives a message.
- **This task also answers to the cross-machine clause of `AC-13`** -- "on whichever machine each member sits" -- which delivery-001 built fan-out for but could not verify with one machine. `AC-13` stays owned by delivery-001; this task answers only to the half that needs a peer.

**Acceptance Criteria:**
- [ ] A message sent while a peer is unreachable reaches that peer on reconnect, and its local member reads it.
- [ ] A message replayed after a reconnect is absorbed rather than duplicated -- exactly one row remains on the receiving hub.
- [ ] A receiving hub stores the sender's `sender_seq` unchanged; verified by comparing the rows on both hubs.
- [ ] Per-speaker order holds on the receiving hub even when messages arrive out of order across the network.
- [ ] No message is replicated to a peer whose handshake failed; verified by attempting it against a major-mismatched peer.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
