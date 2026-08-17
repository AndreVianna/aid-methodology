# task-044: Observe-only assertions and the zero-row oracle run

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

**Depends on:** task-027, task-043

**Scope:**
- Add assertions for the three new clauses beside the oracle suite's existing set, and record the oracle run that demonstrates the boundary.

**Acceptance Criteria:**
- [ ] The selector-partition oracle exits clean with its undecided and violation counts recorded, and produces **zero ledger rows** from that run — recorded as zero rather than assumed.
- [ ] The existing assertion that pins the ledger's column count still passes, and is now **reachable** for a reviewer-agent-only change because of task-027.
- [ ] Each new assertion fails if its clause is deleted from the schema.
- [ ] Baseline failure count unchanged.
- [ ] All section-6 quality gates pass
