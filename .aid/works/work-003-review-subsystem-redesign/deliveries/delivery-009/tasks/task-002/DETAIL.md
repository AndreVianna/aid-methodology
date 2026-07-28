# task-002: Scratch ledgers and the two modes

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

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** task-001

**Scope:**
- The per-attempt scratch ledger versus the durable canonical ledger
- Mode selection by one `test -f`; the `{{RESUME_MODE}}` declaration
- The inherited ledger-schema lifecycle rewrite -- the debt feature-003 handed over in writing

**Acceptance Criteria:**
- [ ] A new cycle is never told the canonical path, so contamination is structural rather than instructional
- [ ] The orphaned lifecycle strings no longer survive, asserted by content anchor rather than line number
- [ ] A replacement statement naming the orchestrator as reconciler is present
- [ ] All section-6 quality gates pass
