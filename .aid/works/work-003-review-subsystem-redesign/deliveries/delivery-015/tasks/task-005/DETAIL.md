# task-005: Remove the two-grade model

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** MIGRATE

**Source:** work-003-review-subsystem-redesign -> delivery-015

**Depends on:** task-002, task-003, task-004

**Scope:**
- The two-grade model removed from 13 surfaces
- The summarize state routing, and the discovery state template's two grade rows collapsed to one

**Acceptance Criteria:**
- [ ] The two-grade model appears on no surface, over a derived file set
- [ ] Historical recorded values are left as history, not back-converted -- re-deriving a letter for un-itemised findings would be fabrication
- [ ] All section-6 quality gates pass
