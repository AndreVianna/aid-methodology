# task-004: AC-11 re-certification

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

**Source:** work-003-review-subsystem-redesign -> delivery-014

**Depends on:** task-002, task-003

**Scope:**
- The AC-11 re-measure after this feature's own edits

**Acceptance Criteria:**
- [ ] `C` is re-measured against the delivery-001 baseline and still falls
- [ ] The per-caller decrease excludes the specify per-section file, which delivery-018 deliberately adds lines to
- [ ] All section-6 quality gates pass
