# task-026: Integration tests for federation, including the idle-link validation

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

**Depends on:** task-024, task-025

**Scope:**
- The target case across two machines; discovery by the guaranteed path alone; delivery to a hub that was offline; version refusal; the cross-machine connect cases.
- A **real** long-idle link followed by a send -- the property nothing upstream has measured.

**Acceptance Criteria:**
- [ ] AC-2 passes with the two sessions on different machines on the same network.
- [ ] Each of the five criteria has a test naming its id.
- [ ] The idle-link test runs against a real network left idle long enough for a connection to be closed, and records its duration and outcome; a simulated close does **not** satisfy it.
- [ ] Tests are deterministic where they can be; the two-machine and idle-link tests are marked manual with their procedures recorded.
- [ ] All section-6 quality gates pass
