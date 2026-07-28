# task-001: Catalog skeleton and routing

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

**Source:** work-003-review-subsystem-redesign -> delivery-004

**Depends on:** --

**Scope:**
- `canonical/aid/templates/review-rubrics/INDEX.md`: the rule-row schema, the Rule ID format, the nine artifact classes, the six families, and the routing table
- The universal defect taxonomy, declared once and inherited by every class

**Acceptance Criteria:**
- [ ] Every artifact class routes to exactly one rule set
- [ ] The Rule ID format is stated and every class token can express an ID under it
- [ ] All section-6 quality gates pass
