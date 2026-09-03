# task-015: Subscriber: the token-free held wait

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

**Source:** feature-003-the-wake -> delivery-003 -> AC-12

**Depends on:** task-014

**Scope:**
- `aid chat subscribe` as a CLI invocation holding a long-poll against the **local** hub.
- The wait returning on an arriving message, on an arriving connect outcome, or on timeout; re-arm after each.
- `--host-timeout <seconds>` and the block bound `min(long_poll_default, host_timeout - margin)`, with the documented fallback when the flag is absent.
- The node's waiter registry treated as a hint about who is listening, never a fact about who exists.

**Acceptance Criteria:**
- [ ] Messages arriving while the subscriber is between arms are all delivered, in order, on the next arm.
- [ ] The wait returns on a connect outcome as well as on a message, and the two are distinguishable by the caller.
- [ ] With `--host-timeout 20` the block is 15 s; with 60 it is 30 s; with the flag absent it is short enough to be safe under the shortest platform default known.
- [ ] The wait costs no model tokens: it runs as a process outside the model, verified by there being no model call in its path.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
