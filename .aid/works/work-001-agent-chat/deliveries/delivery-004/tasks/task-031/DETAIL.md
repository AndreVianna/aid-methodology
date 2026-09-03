# task-031: Integration tests for federation, including the idle-link validation

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-2, AC-4, AC-5, AC-16, AC-34

**Depends on:** task-030

**Scope:**
- The target case across two machines; discovery by the guaranteed path alone; delivery to a hub that was offline; version refusal; the cross-machine connect cases.
- A **real** long-idle link followed by a send -- the property nothing upstream has measured.
- **This task also verifies the cross-machine clause of `AC-13`** -- "on whichever machine each member sits" -- which delivery-001 built fan-out for but could not verify with one machine. `AC-13` stays owned by delivery-001; the criterion below covers only the half that needs a peer.

**Acceptance Criteria:**
- [ ] `AC-2` passes with the two sessions on different machines on the same network.
- [ ] Each of the five criteria has a test naming its id.
- [ ] The idle-link check runs against a real network left idle long enough for a connection to be closed, and records its duration and outcome; a simulated close does **not** satisfy it.
- [ ] Fan-out reaches members on both machines, completing `AC-13`'s cross-machine clause.
- [ ] Every automated test here is deterministic: run three times in succession it gives the same result. Any check needing a live host session or a real network is **not** automated -- it is recorded by name, with its steps, in `chat-node/tests/MANUAL-PROCEDURES.md`, so the set of non-automated checks is enumerable rather than implied.
- [ ] This task appends its own non-automated checks to `chat-node/tests/MANUAL-PROCEDURES.md`, and every entry names the check, its steps, and what a pass looks like.
- [ ] Clean setup and teardown: the suite leaves no store, no process and no channel behind, verified by running it twice in the same working directory.
- [ ] All existing tests still pass.
- [ ] All section-6 quality gates pass
