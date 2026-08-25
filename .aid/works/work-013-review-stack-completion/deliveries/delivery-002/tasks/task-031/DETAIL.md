# task-031: Cycle preflight and the ledger-path parameter in the dispatch protocol

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

**Depends on:** task-026

**Scope:**
- `canonical/aid/templates/reviewer-dispatch.md` § Brief generation gains a preflight step ahead of the render: resolve the ledger path for the scope, assert no file exists at it on cycle 1, and assert one does exist from cycle 2.
- The render, the cost-meter record and the dispatch are unchanged.
- Re-run the generator in the same commit.

**Acceptance Criteria:**
- [ ] The preflight is an addition ahead of the metering step, never a substitution for it: all three components of the dispatch mandate still resolve by grep.
- [ ] The cycle-1 case **fails loudly and names the leftover file** — a warning would leave the leak the requirement exists to close.
- [ ] The worked example and the path table keep their literal paths, because they are documentation rather than instruction, and the task states that distinction as the test it applied.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
