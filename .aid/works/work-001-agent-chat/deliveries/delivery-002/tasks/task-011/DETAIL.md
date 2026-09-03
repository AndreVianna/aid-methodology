# task-011: Roster with computed availability

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

**Source:** feature-002-node-and-message-plane -> delivery-002 -> AC-27

**Depends on:** task-008

**Scope:**
- A roster answering, for each session this hub knows: name, host tool, declared capabilities, liveness, and whether it is **available**.
- `available` computed at read time from registration, the stale threshold, and `channel_id IS NULL` -- never stored.

**Acceptance Criteria:**
- [ ] A registered session in no channel appears as available to every other agent.
- [ ] A session in a channel appears as unavailable.
- [ ] A session quiet past the stale threshold appears as unavailable, and its channel stays open.
- [ ] No `available` column exists; verified by reading the schema back -- a stored flag would desynchronise on a missed heartbeat.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
