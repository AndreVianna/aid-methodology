# task-002: Reduce the six former hosts to pointers

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

**Source:** work-003-review-subsystem-redesign -> delivery-003

**Depends on:** task-001

**Scope:**
- The six files that currently carry a rival severity definition, reduced to pointers
- `.aid/knowledge/quality-gates.md`'s prose severity definition, which no heading-based sweep catches

**Acceptance Criteria:**
- [ ] A sweep for rival definition tables returns only pointers (AC-1), asserted over a closed enumeration of the six former hosts plus a drift check for new ones
- [ ] `quality-gates.md`'s prose definition is gone, asserted by a targeted check rather than a heading grep
- [ ] `grep` for "established best practice" as a criterion source returns nothing (AC-2)
- [ ] All section-6 quality gates pass
