# task-003: Gate rows and the citation convention

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** task-001

**Scope:**
- The mechanical-gate row and validation-command line in `quality-gates.md`
- The durable-citation convention in the authoring principles, scoping the ban to the KB and stating the work-artifact rule
- The guidance that a quote which must survive the check should be a short fragment from a single source line

**Acceptance Criteria:**
- [ ] The gate rows describe gates that actually run
- [ ] The convention distinguishes evidence citations from ownership claims, so region-ownership inventories keep their line numbers
- [ ] All section-6 quality gates pass
