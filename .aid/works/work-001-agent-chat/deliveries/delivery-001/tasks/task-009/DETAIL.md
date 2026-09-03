# task-009: Integration tests for the hub that holds a conversation

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-3, AC-6, AC-7, AC-8, AC-9, AC-10, AC-13, AC-22, AC-29, AC-30, AC-31, AC-32, AC-33

**Depends on:** task-008

**Scope:**
- End-to-end tests over the real node and the real CLI for each of this delivery's thirteen criteria.
- Explicit coverage of node-restart durability, the two-member direct message, per-speaker ordering, and delivered-versus-acknowledged redelivery.

**Acceptance Criteria:**
- [ ] Each of the thirteen criteria has at least one test naming its id; the mapping is checkable by grepping the suite for the ids.
- [ ] Restarting the **node** preserves unacknowledged messages and every member's positions.
- [ ] `AC-13` is verified for a channel of two and of more than two **on this machine**; its "on whichever machine each member sits" clause is out of scope here and is verified at delivery-004.
- [ ] A test asserts that two members observing two speakers in different relative orders is a **pass**, so a later reader cannot file per-speaker ordering as a defect.
- [ ] Tests are deterministic, with clean setup and teardown.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
