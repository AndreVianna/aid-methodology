# task-003: check-gaps.sh

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

**Source:** work-003-review-subsystem-redesign -> delivery-007

**Depends on:** task-001

**Scope:**
- The pre-grade gate, following the linter exit-code alphabet: 0 clean, 1 open criteria gap, 2 usage
- The loop signal on stdout; its test suite

**Acceptance Criteria:**
- [ ] The gate fires on an open criteria gap and only on one: non-blocking and evidence gaps pass
- [ ] The same gap twice raises a loop flag without user intervention (AC-10)
- [ ] It reads across repeated `--ledger` arguments, so parallel-mandate scratch ledgers are covered
- [ ] All section-6 quality gates pass
