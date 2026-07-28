# task-002: Seven to eight, tree-wide

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

**Source:** work-003-review-subsystem-redesign -> delivery-005

**Depends on:** task-001

**Scope:**
- Every "7-column" reference in the migration set, including the five `grade.sh` comment lines feature-002 claims

**Acceptance Criteria:**
- [ ] No "7-column" reference survives in the migration set, over a derived file list
- [ ] `grade.sh`'s guard, reads and every branch are byte-unchanged; only comments differ
- [ ] All section-6 quality gates pass
