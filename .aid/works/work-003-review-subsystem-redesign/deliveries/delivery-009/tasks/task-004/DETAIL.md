# task-004: Generalise the stop signal

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** --

**Scope:**
- `write-control-signal.sh` extended with a review scope, so a review with no task id has a cooperative stop path

**Acceptance Criteria:**
- [ ] A review dispatched by a skill with no task id can be stopped cooperatively
- [ ] The existing task-scoped path is unchanged
- [ ] All section-6 quality gates pass
