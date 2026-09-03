# task-016: Node-side subscribe endpoint and the waiter registry

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

**Source:** feature-003-the-wake -> delivery-003 -> AC-12

**Depends on:** task-014

**Scope:**
- The node's held-wait route: a connection the node holds open and resolves on arrival, with the long-poll timeout from `§6`.
- The in-memory waiter registry -- channel to held responses, plus per-session pending connect outcomes -- rebuilt from nothing on restart.
- The registry treated as a **hint** about who is listening, never a fact about who exists, because a host that abandons a hook leaves a waiter nobody reads.
- Resolution on either event kind, each tagged so a client can tell them apart.

**Acceptance Criteria:**
- [ ] A message arriving while a wait is held resolves that wait, and the message is also in the store -- verified by reading it again afterwards.
- [ ] A wait that times out returns without an error and without consuming the message.
- [ ] Restarting the node loses the registry and costs a waiting client one timeout, and **no message**; verified by sending during the restart window and reading afterwards.
- [ ] A connect outcome resolves a held wait, and is distinguishable from a message by its tag.
- [ ] Killing a client mid-wait leaves no permanently held response; verified by the registry count returning to its prior value.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
