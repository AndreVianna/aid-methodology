# task-005: Channel lifecycle and the one-channel bound

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-29, AC-30

**Depends on:** task-004

**Scope:**
- `open` as create-and-join in one step, setting both positions to the channel's head; `join` at head; `leave`.
- A join attempt while already in a channel refused with `already_in_channel`.
- Close when the last member leaves **or is reaped**, deleting the row and cascading its messages away. **The close-on-reap code path is built and triggerable here; the periodic job that decides *when* to reap is task-032** -- FR-2.3 puts tracking with registration and reaping with retention, so this task owns the rule and that one owns the schedule.
- Local channel listing (`FR-3.1` local half).
- A dropped connection is **not** a leave -- it is stale, then reaped.

**Acceptance Criteria:**
- [ ] A session with no channel opens one and is its sole member; a session already in one is refused and succeeds after leaving.
- [ ] A member joining a channel that already carries messages receives only messages sent **after** it joined.
- [ ] A channel whose creator has left while another member remains is still open.
- [ ] A channel whose last member leaves is gone, and its messages are gone with it; verified by querying the store.
- [ ] Reaping the last member **when the reap path is invoked directly** closes the channel; and a channel quiet for any duration with a live member is **not** closed, verified by holding one member heartbeating for longer than the reap threshold.
- [ ] Listing shows the open channels this hub knows and which one the caller is in.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
