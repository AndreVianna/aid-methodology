# task-004: Column gates and NFR-5

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

**Source:** work-003-review-subsystem-redesign -> delivery-005

**Depends on:** task-002, task-003

**Scope:**
- A suite asserting the new shape works and the old one still reads

**Acceptance Criteria:**
- [ ] An 8-column ledger grades correctly
- [ ] Existing 7-column ledgers remain readable; the fixtures that prove NFR-5 are unchanged
- [ ] `grade.sh` is byte-identical to its pre-delivery state
- [ ] Five-profile render parity holds
- [ ] All section-6 quality gates pass
