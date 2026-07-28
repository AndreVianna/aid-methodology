# task-005: Retire the heredoc write

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

**Source:** work-003-review-subsystem-redesign -> delivery-006

**Depends on:** task-002

**Scope:**
- The schema, the KB authoring conventions and `quality-gates.md`, migrated to the helper
- The `aid-discover` merge rule excluding coverage and gap rows from the panel merge

**Acceptance Criteria:**
- [ ] A sweep for a heredoc write co-located with a ledger path returns nothing
- [ ] The helper is named where the mechanism is taught, in each of the three teaching documents
- [ ] All section-6 quality gates pass
