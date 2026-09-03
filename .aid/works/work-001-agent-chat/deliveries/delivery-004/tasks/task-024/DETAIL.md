# task-024: Federated roster and the cross-machine connect relay

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-34

**Depends on:** task-023

**Scope:**
- The roster fetched from each reachable peer and merged for the answer, **never stored**.
- An answer given while a peer is unreachable naming that peer explicitly rather than omitting its agents silently.
- Connect requests relayed and answered against the target hub's state at the moment the relay arrives.
- An unreachable peer **failing** the request rather than queueing it.
- A hub asked for a channel name it has never seen creating its local replica and joining its agent.

**Acceptance Criteria:**
- [ ] An agent on one machine sees agents on another in its roster.
- [ ] A roster answered while a peer is unreachable returns the agents it could reach **plus an explicit list of those it could not**, and does not fail outright.
- [ ] A relayed request returns the same outcomes as a local one.
- [ ] An unreachable peer makes the request fail rather than queue; verified by taking a peer down and asking.
- [ ] A hub that has never seen the named channel creates its replica and joins its agent.
- [ ] A relayed request whose asker left before it arrived leaves the target alone in a channel, which then closes when the target leaves or is reaped.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
