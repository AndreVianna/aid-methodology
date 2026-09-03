# task-014: Integration tests for the hub plane

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

**Type:** TEST

**Source:** feature-002-node-and-message-plane -> delivery-002 -> AC-27, AC-28

**Depends on:** task-013

**Scope:**
- End-to-end tests over the real node for both criteria and every refusal case reachable from these two verbs.
- The simultaneous reciprocal request, ordered deterministically rather than raced.

**Acceptance Criteria:**
- [ ] Both criteria have tests naming their ids.
- [ ] Every refusal reason reachable from these verbs has a test.
- [ ] The simultaneous reciprocal case is tested **deterministically** -- both requests ordered around an explicit barrier rather than left to a race -- and asserts both fail.
- [ ] Tests are deterministic, with clean setup and teardown.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
