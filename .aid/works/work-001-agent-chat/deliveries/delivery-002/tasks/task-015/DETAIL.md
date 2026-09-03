# task-015: Integration tests for the hub plane

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

**Depends on:** task-014

**Scope:**
- End-to-end tests over the real node for both criteria and every refusal case reachable from these two verbs.
- The simultaneous reciprocal request, ordered deterministically rather than raced.

**Acceptance Criteria:**
- [ ] Both criteria have tests naming their ids.
- [ ] Every refusal reason reachable from these verbs has a test.
- [ ] The simultaneous reciprocal case is ordered around an explicit barrier rather than left to a race, and asserts both requests fail.
- [ ] Every automated test here is deterministic: run three times in succession it gives the same result. Any check needing a live host session or a real network is **not** automated -- it is recorded by name, with its steps, in `chat-node/tests/MANUAL-PROCEDURES.md`, so the set of non-automated checks is enumerable rather than implied.
- [ ] This task appends its own non-automated checks to `chat-node/tests/MANUAL-PROCEDURES.md`, and every entry names the check, its steps, and what a pass looks like.
- [ ] Clean setup and teardown: the suite leaves no store, no process and no channel behind, verified by running it twice in the same working directory.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
