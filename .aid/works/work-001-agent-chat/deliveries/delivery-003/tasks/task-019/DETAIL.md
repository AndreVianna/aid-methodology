# task-019: Integration tests for the wake, on both proving hosts

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

**Source:** feature-003-the-wake -> delivery-003 -> AC-1, AC-12, AC-23, AC-24, AC-25, AC-26

**Depends on:** task-018

**Scope:**
- The cross-tool same-machine exchange, the re-arm window, no-loop, no-human-in-the-path, no-orphan, and byte-order-mark tolerance.
- The connect-outcome-through-wake case, which the plan carries as its own gate criterion because no section-9 criterion covers it.

**Acceptance Criteria:**
- [ ] AC-1 passes with a Cursor session and a Claude Code session on one machine, in different repositories.
- [ ] A connect outcome reaches an **idle** target through the wake, with the target having called nothing first.
- [ ] Orphan absence is verified by process and connection count, not by absence of error.
- [ ] Each of the six criteria has a test naming its id.
- [ ] Tests are deterministic where they can be; any test requiring a live host session is marked manual and its procedure recorded so it is repeatable.
- [ ] All section-6 quality gates pass
