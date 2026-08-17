# task-047: Cost meter assertions for the dedupe and the attribution

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-046

**Scope:**
- Extend the cost meter's own suite with the dedupe case and the region-attribution case.

**Acceptance Criteria:**
- [ ] A brief naming one path in both lists records that path's size **once**, and the assertion fails if the dedupe is reverted.
- [ ] A region entry is asserted to contribute **its file's byte count, not zero** — the assertion that separates a real fix from the accidental one.
- [ ] A region entry for a path that does not exist is reported rather than silently dropped.
- [ ] Deterministic, fixtures cleaned up, baseline failure count unchanged.
- [ ] All section-6 quality gates pass
