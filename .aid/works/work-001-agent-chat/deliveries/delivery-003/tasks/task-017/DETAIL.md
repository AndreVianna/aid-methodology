# task-017: CLI subscriber and the host-timeout bound

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

**Depends on:** task-016

**Scope:**
- `aid chat subscribe` as a CLI invocation holding the wait against the **local** hub, on both twins.
- `--host-timeout <seconds>` and the block bound `min(long_poll_default, host_timeout - margin)`, with the documented fallback when the flag is absent.
- Re-arm after each return.

**Acceptance Criteria:**
- [ ] Messages arriving while the subscriber is between arms are all delivered, in order, on the next arm.
- [ ] With `--host-timeout 20` the block is 15 s; with 60 it is 30 s; verified by timing the call.
- [ ] With the flag absent the block is short enough to be safe under the shortest platform default known, and the value used is reported so it is observable rather than implicit.
- [ ] The wait costs no model tokens: it runs as a process with no model call in its path, verified by inspecting the invocation.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
