# task-006: Send path: refusals, idempotency and the two counters

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-8, AC-13

**Depends on:** task-005

**Scope:**
- `send` with its refusals: `not_registered`, `no_channel`, `solo_channel`, `overflow`, and the mention/whisper exclusivity check.
- **This task owns the overflow *mechanism*** -- the unread-depth bound enforced on send, reading its value from settings. Making that value operator-settable, and the trim job that relieves the condition, belong to delivery-005; the division is stated here because two tasks would otherwise appear to own the same rule.
- The other-member count written to include **remote** members from the start, so it is not quietly wrong the day federation lands.
- Idempotency key minted when the caller omits it, **scoped to the sender**; a collision answered as success returning the existing `arrival_seq`.
- One transaction taking `channel.next_seq` and `session.next_sender_seq` as columns, never a `MAX()` over a trimmed log.
- Fan-out to every member; exit code 8 and the stable stderr tokens.

**Acceptance Criteria:**
- [ ] A send by a channel's only member fails with `solo_channel`; by a session in no channel with `no_channel`; both at exit 8.
- [ ] The same idempotency key sent twice yields **one** message and the same `arrival_seq` from both calls.
- [ ] Two different senders using the same key value both have their messages stored -- neither swallows the other.
- [ ] A local member at the unread bound causes further sends to that channel to be refused with `overflow` rather than dropping anything.
- [ ] A message reaches every member of a two-member channel and of a channel with more than two, **on this machine**; the "on whichever machine each member sits" clause of `AC-13` is delivery-004's and is out of scope here.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
