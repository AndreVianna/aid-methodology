# task-017: Three fixtures proving the kb.html check fires

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

**Type:** TEST

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-016

**Scope:**
- Three fixtures: a `kb.html` whose project claims contradict the KB, one that agrees, and one from which no claim can be extracted.

**Acceptance Criteria:**
- [ ] The contradicting fixture yields a finding; the agreeing fixture yields none.
- [ ] The zero-claims fixture fails rather than passing quietly.
- [ ] Deterministic, fixtures cleaned up, baseline unchanged.
- [ ] All section-6 quality gates pass
