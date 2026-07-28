# task-001: SUMMARY rule rows

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

**Source:** work-003-review-subsystem-redesign -> delivery-015

**Depends on:** --

**Scope:**
- The 14 scored checks re-expressed as `SUMMARY` rule rows with severity anchors
- The two unconditionally-passing checks deleted rather than migrated -- a check that cannot fail is not a rule

**Acceptance Criteria:**
- [ ] Every former scored check maps to a rule row or is deliberately deleted, with the deletion justified
- [ ] The coverage rule fires one row per unreferenced doc, which is where the former partial credit went
- [ ] All section-6 quality gates pass
