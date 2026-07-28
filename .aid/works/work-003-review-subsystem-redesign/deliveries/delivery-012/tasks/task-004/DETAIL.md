# task-004: Shrink the six briefs

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

**Source:** work-003-review-subsystem-redesign -> delivery-012

**Depends on:** task-002, task-003

**Scope:**
- Each of the six per-skill briefs reduced to its two genuinely per-skill sections, **at the same paths**

**Acceptance Criteria:**
- [ ] The six files still exist at their paths, so the inherited mode-declaration oracle does not pass vacuously on an empty glob
- [ ] The gap-policy assertion is inverted: the section lives once in the shared template and the six do not restate it
- [ ] The mode-declaration surface is re-pointed from 12 files to 7
- [ ] All section-6 quality gates pass
