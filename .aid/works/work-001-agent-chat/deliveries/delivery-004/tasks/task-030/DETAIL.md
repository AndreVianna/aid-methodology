# task-030: The cross-machine connect relay

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

**Depends on:** task-029

**Scope:**
- Connect requests relayed to the target's hub and answered against **that hub's state at the moment the relay arrives**.
- An unreachable peer **failing** the request rather than queueing it -- the deliberate asymmetry with messages, which do queue.
- A hub asked for a channel name it has never seen creating its local replica and joining its agent, because a channel is a name and there is no authority to consult.

**Acceptance Criteria:**
- [ ] A relayed request returns the same outcomes as a local one, for each of available, busy, stale and unknown.
- [ ] An unreachable peer makes the request fail rather than queue; verified by taking a peer down and asking.
- [ ] A hub that has never seen the named channel creates its replica and joins its agent.
- [ ] A relayed request whose asker left before it arrived leaves the target alone in a channel, which then closes when the target leaves or is reaped.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
