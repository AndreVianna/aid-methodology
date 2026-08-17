# task-015: FL19 gains a checked-count assertion

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

**Depends on:** task-013

**Scope:**
- `tests/canonical/test-frontmatter-lint.sh`: assert the lint's printed checked-count, so a run that examines nothing cannot report clean.
- Correct the stale suite title and the matching CI step name.

**Acceptance Criteria:**
- [ ] A root where every document is skipped now FAILS the suite; today it passes with exit `0` and zero findings, which is the vacuity being closed.
- [ ] The live run's checked, skipped and findings counts are asserted, with the command recorded.
- [ ] Baseline failure count unchanged.
- [ ] All section-6 quality gates pass
