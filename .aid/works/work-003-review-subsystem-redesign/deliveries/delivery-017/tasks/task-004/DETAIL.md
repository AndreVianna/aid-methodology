# task-004: The count-claim rule row

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

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** --

**Scope:**
- FR-G4's count-claim rule row in the Definition family file, which delivery-004 deliberately left out

**Acceptance Criteria:**
- [ ] The row is a judgment-mode rule with a SHOULD modality and a severity anchor matching the catalog's regex
- [ ] Its `Criterion` cites the declaring authoring principle and resolves
- [ ] All section-6 quality gates pass
