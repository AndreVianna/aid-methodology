# task-036: Integration tests for directed messages, retention and visibility

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

**Depends on:** task-035

**Scope:**
- The four criteria end to end, plus the whisper-absent-from-audit property, the two-member whisper case, and the reap-plus-close atomicity.

**Acceptance Criteria:**
- [ ] Each of the four criteria has a test naming its id.
- [ ] A test asserts a whisper is absent from **history** for a non-target, not merely absent on delivery.
- [ ] A test asserts the whisper body is absent from the operator's audit output.
- [ ] A test interrupts between reaping and channel close and asserts no zero-member channel survives.
- [ ] Every automated test here is deterministic: run three times in succession it gives the same result. Any check needing a live host session or a real network is **not** automated -- it is recorded by name, with its steps, in `chat-node/tests/MANUAL-PROCEDURES.md`, so the set of non-automated checks is enumerable rather than implied.
- [ ] This task appends its own non-automated checks to `chat-node/tests/MANUAL-PROCEDURES.md`, and every entry names the check, its steps, and what a pass looks like.
- [ ] Clean setup and teardown: the suite leaves no store, no process and no channel behind, verified by running it twice in the same working directory.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
