# task-005: Catalog integrity suite

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

**Source:** work-003-review-subsystem-redesign -> delivery-004

**Depends on:** task-002

**Scope:**
- A suite asserting the catalog's structural invariants across every class file

**Acceptance Criteria:**
- [ ] Exactly one rule set per artifact class, over a derived class list rather than an enumerated one
- [ ] Every row has all three anchors; every `Criterion` resolves and its anchor is greppable
- [ ] A class with no rule set is reported, not silently skipped
- [ ] All section-6 quality gates pass
