# task-022: The inter-node link: keepalive, reconnect and jittered backoff

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

**Depends on:** task-021

**Scope:**
- One long-lived connection per peer, carrying replication, roster queries and connect relays.
- Keepalive at an interval well under the shortest plausible network idle timeout.
- Reconnect that loses nothing, because everything not yet delivered is in the store rather than in the link.
- Backoff with jitter, so two hubs reconnecting cannot settle into lockstep.

**Acceptance Criteria:**
- [ ] A link left idle long enough for the network to close it is re-established on the next send, and the queued message arrives.
- [ ] After a reconnect the roster reflects who is actually there -- no departed agent shows as available.
- [ ] The link holds no unreplicated state; verified by killing it mid-send and asserting the message is still in `outbox`.
- [ ] The backoff sequence contains jitter; verified by inspecting successive intervals rather than by inspecting the code.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
