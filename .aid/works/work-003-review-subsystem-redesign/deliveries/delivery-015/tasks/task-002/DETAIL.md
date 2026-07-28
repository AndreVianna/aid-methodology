# task-002: emit-summary-findings.sh

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
- `grade-summary.sh` gutted of all grade computation and renamed
- One ledger-row emission per failed check; linter exit codes
- The rewritten test suite, converting scoring assertions to row-emission assertions one for one

**Acceptance Criteria:**
- [ ] No grade function survives in the script
- [ ] The suite reduces no assertion, so coverage parity stays clean
- [ ] The rename is complete: no reference to the old name survives
- [ ] All section-6 quality gates pass
