# task-034: Literal ledger paths retired from the REVIEW and DONE sites

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-033

**Scope:**
- Convert the remaining literal ledger paths in the summarize, detail, plan and deploy sites, following the classification pattern task-033 established.

**Acceptance Criteria:**
- [ ] The literal-path canary reaches **zero** fully literal ledger paths across the whole instruction surface, measured against the count recorded in task-026.
- [ ] Each site in this group carries the same instruction-or-documentation classification, applied consistently with task-033's precedent.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
