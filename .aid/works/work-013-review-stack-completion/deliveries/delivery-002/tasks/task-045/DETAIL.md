# task-045: A coverage unit that is a region rather than a file

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

**Depends on:** task-031

**Scope:**
- `reviewer-dispatch.md`: a coverage unit may be a path or a path with a heading anchor, and the trigger is stated — when the verify and hunt lists would name the same path, the hunt list names regions.
- A worklist unit is written as the ledger row number or the criterion id.
- Re-run the generator in the same commit.

**Acceptance Criteria:**
- [ ] No new notation is introduced: the anchor form is the citation form the KB already mandates, and it is cited rather than restated.
- [ ] The measured insufficiency is recorded as the trigger — the re-read ratio and the exact doubling that produced it.
- [ ] The verify set's derivation from the ledger's document column is untouched.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
