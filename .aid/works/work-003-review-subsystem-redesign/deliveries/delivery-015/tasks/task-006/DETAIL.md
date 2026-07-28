# task-006: NFR-7: one grade producer

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

**Source:** work-003-review-subsystem-redesign -> delivery-015

**Depends on:** task-005

**Scope:**
- A tree-wide suite asserting exactly one letter-grade producer

**Acceptance Criteria:**
- [ ] Exactly one component produces a letter grade; no second grade function exists anywhere
- [ ] `grade.sh` is byte-identical to its pre-delivery state -- (a) proves the second backend is gone, this proves the first was not touched to achieve it
- [ ] All section-6 quality gates pass
