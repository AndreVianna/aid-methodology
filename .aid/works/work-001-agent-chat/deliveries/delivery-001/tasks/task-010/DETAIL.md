# task-010: Integration tests for the hub that holds a conversation

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

**Depends on:** task-009

**Scope:**
- End-to-end tests over the real node and the real CLI for each of this delivery's thirteen criteria.
- Explicit coverage of node-restart durability, the two-member direct message, per-speaker ordering, and delivered-versus-acknowledged redelivery.
- **Creation of `chat-node/tests/MANUAL-PROCEDURES.md`** -- the record every later TEST task appends to. It exists because a criterion that defers to an enumerable list of manual checks is only falsifiable if the list is a real file with a known owner.

**Acceptance Criteria:**
- [ ] Each of the thirteen criteria has at least one test naming its id; the mapping is checkable by grepping the suite for the ids.
- [ ] Restarting the **node** preserves unacknowledged messages and every member's positions.
- [ ] `AC-13` is verified on this machine only; its cross-machine clause is delivery-004's and is asserted nowhere here.
- [ ] A test asserts that two members observing two speakers in different relative orders is a **pass**.
- [ ] Every automated test here is deterministic: run three times in succession it gives the same result. Any check needing a live host session or a real network is **not** automated -- it is recorded by name, with its steps, in `chat-node/tests/MANUAL-PROCEDURES.md`, so the set of non-automated checks is enumerable rather than implied.
- [ ] That record is created by this task, and every entry names the check, its steps, and what a pass looks like.
- [ ] Clean setup and teardown: the suite leaves no store, no process and no channel behind, verified by running it twice in the same working directory.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
