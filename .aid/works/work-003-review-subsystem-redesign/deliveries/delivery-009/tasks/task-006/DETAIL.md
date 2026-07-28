# task-006: The resume oracle

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** task-001, task-005

**Scope:**
- A suite covering all three interruption types and the grade-invariance control

**Acceptance Criteria:**
- [ ] A review killed mid-unit re-examines only the interrupted unit, with a negative control forbidding invalidate-everything (AC-7)
- [ ] Resume never moves the grade: the `--explain` breakdown is byte-identical before and after applying a plan
- [ ] All section-6 quality gates pass
