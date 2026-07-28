# task-001: The canonical severity scale

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

**Source:** work-003-review-subsystem-redesign -> delivery-003

**Depends on:** --

**Scope:**
- `canonical/aid/templates/grading-rubric.md`: the two-step scale -- modality, then blast radius x reversibility -- as the single definition in the tree

**Acceptance Criteria:**
- [ ] The scale is stated once, with both steps and every band
- [ ] A reviewer can reach a severity by lookup without a judgment call at any step
- [ ] All section-6 quality gates pass
