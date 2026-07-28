# task-003: De-score the manual checklist

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** REFACTOR

**Source:** work-003-review-subsystem-redesign -> delivery-015

**Depends on:** task-001

**Scope:**
- The scoring functions and score keys removed; the script becomes an answer recorder
- An unanswered checklist producing a pause rather than a grade of F

**Acceptance Criteria:**
- [ ] An unanswered checklist produces no grade at all -- the conflation of unanswered with failed is gone
- [ ] The checklist artifact gates approval by existing, not by scoring
- [ ] All section-6 quality gates pass
