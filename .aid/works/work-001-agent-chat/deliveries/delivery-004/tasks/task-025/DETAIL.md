# task-025: Protocol version handshake

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-16

**Depends on:** task-024

**Scope:**
- A protocol version number of its own, **never inferred from `VERSION`** -- the node ships in the `aid` payload, so the artifact version moves for reasons the protocol does not.
- Semantic comparison at handshake; minor and patch differences compatible by contract.
- A major difference refusing the connection with an explicit error.

**Acceptance Criteria:**
- [ ] Two hubs differing by patch or by minor interoperate normally.
- [ ] A major difference refuses the connection with a clear error and does not silently half-work; verified by asserting no message crosses after the refusal.
- [ ] The protocol number is independent of `VERSION`; verified by bumping `VERSION` and asserting the handshake outcome is unchanged.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
