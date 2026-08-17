# task-024: Two false grade.sh capability claims corrected

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-009

**Scope:**
- Correct the two aid-summarize references that attribute to `grade.sh` work done by `grade-summary.sh` — reading the manual checklist, and owning the machine point pool.

**Acceptance Criteria:**
- [ ] The four greps are recorded: both claimed capabilities return `0` for `grade.sh` and non-zero for `grade-summary.sh`.
- [ ] `grade-summary.sh` is untouched and its distinct letter count is unchanged — this task is documentation accuracy and explicitly **not** the declined single-backend conversion.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
