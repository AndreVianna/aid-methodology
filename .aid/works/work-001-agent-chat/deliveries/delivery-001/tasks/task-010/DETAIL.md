# task-010: ADR: positions index the hub's own arrival order

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

**Type:** DOCUMENT

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-31, AC-32

**Depends on:** task-007

**Scope:**
- A decision record for the least obvious choice in the design: a member's position is a scalar into **this hub's** `arrival_seq`, not into any global order.
- The rejected alternatives -- vector clocks, and a per-channel sequencer -- and why each fails here.
- The two properties that make a scalar sufficient: a session reads only its own hub, and a session never moves machines.
- The consequence that per-speaker order is produced on read rather than stored.

**Acceptance Criteria:**
- [ ] The record follows the repository's existing decision-record shape and sits where the KB's conventions place one.
- [ ] It names both rejected alternatives with the reason each fails, not merely that they were considered.
- [ ] It states the two properties the design depends on, so that a future change to either is recognisable as invalidating this decision.
- [ ] Accuracy verified against the schema and read path **as built**, not against this task's description.
- [ ] All section-6 quality gates pass
