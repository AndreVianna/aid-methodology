# task-002: gap-register.sh

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
- `--promote`, `--resolved-keys`, `--depth`, following `writeback-state.sh`'s exit-code alphabet
- Its test suite

**Acceptance Criteria:**
- [ ] Promoting twice yields a byte-identical register -- idempotent on gap key
- [ ] A declined key is reported by `--resolved-keys`, so the batch subtraction works (AC-5)
- [ ] A still-pending gap re-raised does not increment the recurrence count -- the negative control that stops AC-10 firing on the happy path
- [ ] All section-6 quality gates pass
