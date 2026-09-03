# task-030: Integration tests for directed messages, retention and visibility

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

**Source:** feature-005-directed-retention-visibility -> delivery-005 -> AC-11, AC-14, AC-17, AC-18

**Depends on:** task-029

**Scope:**
- The four criteria end to end, plus the whisper-absent-from-audit property and the reap-plus-close atomicity.

**Acceptance Criteria:**
- [ ] Each of the four criteria has a test naming its id.
- [ ] A test asserts a whisper is absent from **history** for a non-target, not merely absent on delivery.
- [ ] A test asserts the whisper body is absent from the operator's audit output.
- [ ] A test interrupts between reaping and channel close and asserts no zero-member channel survives.
- [ ] Tests are deterministic, with clean setup and teardown.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
