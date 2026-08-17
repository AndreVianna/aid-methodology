# task-022: Dispatch protocol's dated history section and extend-it instruction removed

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-002

**Scope:**
- `canonical/aid/templates/reviewer-dispatch.md`: remove the instruction telling the next author to extend an in-document changelog, and the dated bootstrap-exemption history section beneath it.
- Renumber the surrounding steps cleanly; touch no other section of the file.

**Acceptance Criteria:**
- [ ] The two greps for the changelog instruction and the bootstrap-exemption heading both return `0`, measured at one hit each before.
- [ ] The surrounding step list renumbers without a gap.
- [ ] It is recorded that the anchored history sweep does not catch this heading, because it is not spelled as a history section — and that widening the sweep is out of scope per the owner's answer to Q4.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
