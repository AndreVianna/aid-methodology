# task-002: Three row kinds

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

**Source:** work-003-review-subsystem-redesign -> delivery-006

**Depends on:** task-001

**Scope:**
- The findings / `U-NNN` coverage / `G-NNN` gap row kinds in the schema, with per-kind status vocabularies
- The coverage row's `art=` and `rs=` digests, helper-generated

**Acceptance Criteria:**
- [ ] Adding coverage and gap rows does not change the grade, nor the `--explain` breakdown, for the same findings (AC-9)
- [ ] A coverage row whose status collides with a grade-bearing status is still ignored -- the negative control proving the severity gate carries the inertness
- [ ] All section-6 quality gates pass
