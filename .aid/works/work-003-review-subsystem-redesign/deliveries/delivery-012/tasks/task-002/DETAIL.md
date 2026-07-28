# task-002: aid-light-review

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

**Source:** work-003-review-subsystem-redesign -> delivery-012

**Depends on:** task-001

**Scope:**
- The skill: intake with the artifact threshold, one screener dispatch, the skill writing the returned rows, the gap batch, the report
- No grade call and no gap gate -- there is no grade to gate

**Acceptance Criteria:**
- [ ] It computes no grade and writes **no coverage rows**, so a clean pass leaves nothing a deep pass could mistake for clearance (FR-A4, made structural)
- [ ] It never chains into deep review
- [ ] Below the configured threshold it skips the screen and records that it did
- [ ] All section-6 quality gates pass
