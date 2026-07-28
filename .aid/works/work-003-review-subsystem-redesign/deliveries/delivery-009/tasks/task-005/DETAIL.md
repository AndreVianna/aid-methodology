# task-005: The FR-D5 migration

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

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** task-002

**Scope:**
- The 14 files instructing a cycle-N reviewer to update Status, migrated to orchestrator reconciliation
- The `{{RESUME_MODE}}` slot across the brief surface
- The reconciliation transition table, including the coverage guard

**Acceptance Criteria:**
- [ ] A sweep for the reviewer-updates-Status instruction returns nothing across the derived file set
- [ ] The coverage guard is present: a finding is marked Fixed on absence only when the unit covering it was Examined
- [ ] Every dispatch site declares a review mode, over a glob-derived surface
- [ ] All section-6 quality gates pass
