# task-003: AC-13 cost baseline

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** RESEARCH

**Source:** work-003-review-subsystem-redesign -> delivery-001

**Depends on:** task-002

**Scope:**
- One fixture artifact taken through a full gate passage, before any review-path edit
- Record from `## Dispatch Log` telemetry: total dispatch count, per-dispatch agent and tier, FIX-cycle count

**Acceptance Criteria:**
- [ ] All three numbers are recorded for the named fixture, with the commands that read them
- [ ] The tier-weighted dispatch cost is stated, so delivery-012 and delivery-014 can compare against it
- [ ] All section-6 quality gates pass
