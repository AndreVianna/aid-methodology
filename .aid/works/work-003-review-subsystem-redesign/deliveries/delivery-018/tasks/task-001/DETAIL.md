# task-001: aid-detail writes the Tasks table

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

**Source:** work-003-review-subsystem-redesign -> delivery-018

**Depends on:** --

**Scope:**
- `aid-detail` completing the BLUEPRINT `## Tasks` table, which the Lite path already does
- Without this, grading the BLUEPRINT lands a guaranteed-failing gate

**Acceptance Criteria:**
- [ ] A delivery's BLUEPRINT Tasks table is populated after `aid-detail` runs
- [ ] The Lite and Full paths now agree on who fills that table
- [ ] All section-6 quality gates pass
