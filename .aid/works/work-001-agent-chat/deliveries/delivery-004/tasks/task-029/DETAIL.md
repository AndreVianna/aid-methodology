# task-029: Federated roster with an explicit partial answer

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

**Depends on:** task-028

**Scope:**
- The roster fetched from each reachable peer and merged for the answer, **never stored**.
- An answer given while a peer is unreachable naming that peer explicitly rather than omitting its agents silently.
- The cross-machine half of `FR-2.2`: the same short session name registered on two machines is two distinct sessions, told apart by machine, and a name is still never a destination.

**Acceptance Criteria:**
- [ ] An agent on one machine sees agents on another in its roster.
- [ ] A roster answered while a peer is unreachable returns the agents it could reach **plus an explicit list of those it could not**, and does not fail outright.
- [ ] No remote agent is stored; verified by reading the schema back and finding no table of remote sessions.
- [ ] The same short name registered on both machines yields two valid registrations distinguishable by machine; verified by reading both full ids.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
