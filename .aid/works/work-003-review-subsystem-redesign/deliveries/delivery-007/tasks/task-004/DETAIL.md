# task-004: Gap semantics and routing

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-007

**Depends on:** task-002, task-003

**Scope:**
- Type 1 / Type 2 findings and the three `[GAP:*]` discriminators
- Routing (canon vs one-time), the batched ask, the halt, restricted mode and the depth limit of 2
- The greenfield criteria-versus-evidence split -- one behavioural change only, at the coding-standards declaration clause

**Acceptance Criteria:**
- [ ] An artifact whose standard is undefined produces a Type 2 gap and halts before grading, never an invented finding (AC-4)
- [ ] A "no" answer is recorded durably with both follow-ups, and a re-run does not re-ask (AC-5)
- [ ] The depth cap demotes rather than discards, and an update run cannot route to itself
- [ ] Every greenfield relaxation is classified as evidence-substitution or a halting criteria gap, with the single behavioural change named
- [ ] All section-6 quality gates pass
