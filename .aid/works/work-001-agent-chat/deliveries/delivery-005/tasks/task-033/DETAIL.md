# task-033: The reaping schedule and its atomic channel close

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

**Source:** feature-005-directed-retention-visibility -> delivery-005 -> AC-11

**Depends on:** task-032

**Scope:**
- The periodic reaping job -- the schedule the channel-lifecycle task deliberately left to this delivery -- running on the configured threshold.
- Deleting the session row and, when it was the last member, closing its channel **in one transaction**, using the close-on-reap path already built.
- The threshold read from settings; nothing hardcoded.

**Acceptance Criteria:**
- [ ] A member quiet past the reap threshold is reaped by the job with no manual trigger.
- [ ] Reaping the last member and closing its channel is atomic; verified by interrupting between the two and asserting no channel with zero members survives.
- [ ] A reaped member stops counting toward its channel's trim point; verified by reading the trim point before and after.
- [ ] The threshold is settable and takes effect with no code change.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
