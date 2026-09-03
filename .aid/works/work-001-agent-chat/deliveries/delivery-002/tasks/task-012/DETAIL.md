# task-012: Directed connect request answered from state

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

**Source:** feature-002-node-and-message-plane -> delivery-002 -> AC-28

**Depends on:** task-011

**Scope:**
- A connect request naming exactly one target agent and one channel.
- The asker must already be in the channel it names, and may not name itself.
- An available target joined in the **same transaction** that sets its positions to the channel head and records the outcome as durable per-session state.
- An unavailable target refused at once with a reason; no accept, no decline, no pending record, no expiry.
- Reciprocal-request arbitration falling out of the asker-is-busy property, plus jittered retry so two agents cannot fail each other in lockstep.

**Acceptance Criteria:**
- [ ] A request at an available agent puts it in the named channel at that channel's head, and it learns so on its next call of any kind.
- [ ] A request at an agent already in a channel, stale, or unknown fails at once with `target_unavailable` at exit 8.
- [ ] A request from a session in no channel, or naming itself, is refused with its own reason.
- [ ] After either outcome, **no pending-invitation state exists anywhere**; verified by reading the schema and the store.
- [ ] Two agents that each open a channel and then request the other simultaneously **both fail as busy**; neither ends up in the other's channel.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
