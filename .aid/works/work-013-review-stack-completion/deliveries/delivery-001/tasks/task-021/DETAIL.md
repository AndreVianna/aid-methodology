# task-021: Work artifacts given a registry home for citation and quote criteria

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

**Depends on:** task-006, task-020

**Scope:**
- Add the registry row and criteria so work artifacts resolve to a type and inherit citation and quote-accuracy criteria, using ids drawn from the ledger.
- Re-check the partition after the change.

**Acceptance Criteria:**
- [ ] Every in-scope markdown file still resolves to exactly one type: the oracle is recorded before and after, and its undecided and violation counts are stated both times.
- [ ] The new ids collide with nothing in the namespace.
- [ ] The quote-accuracy rule is stated as a criterion with a severity and a why, not as prose.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
