# task-003: Wire the settings gate

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-003-review-subsystem-redesign -> delivery-014

**Depends on:** task-001

**Scope:**
- Three sites: the config skill's completion, the KB generate state, and `aid-deep-review` INTAKE
- The config skill's prose validation table, replaced by the lint

**Acceptance Criteria:**
- [ ] All three sites invoke the lint
- [ ] The INTAKE site catches a later hand-edit at the moment it would loosen a gate -- affordable only because delivery-012 collapsed the minimum-grade reads into one place
- [ ] The resolved bar is printed at every gate site, which is how the loosening criterion is satisfied
- [ ] All section-6 quality gates pass
