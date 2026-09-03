# task-018: Claude Code waker adapter

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

**Source:** feature-003-the-wake -> delivery-003 -> AC-23, AC-24, AC-25, AC-26

**Depends on:** task-017

**Scope:**
- Read the host's stop payload, decoding with `utf-8-sig`.
- Re-entry via `stop_hook_active` **plus the adapter's own count**, because this host's `loop_limit` is documented `null` and therefore uncapped.
- Emit this host's documented shape, carrying the message body as the text the model reads.
- Forward-slash paths that survive bash; the interpreter resolved from the running process, never from `PATH`.

**Acceptance Criteria:**
- [ ] A woken session runs one turn and settles; the stop event that ends the woken turn does not start another wait.
- [ ] From arrival to the session having acted, no approval prompt is raised.
- [ ] After a block that would exceed the configured hook timeout, no adapter process survives and the node's waiter count returns to its prior value; verified by process and connection count rather than by absence of error.
- [ ] A stop payload prefixed with a UTF-8 byte-order mark is parsed and acted on.
- [ ] The emitted command contains no backslash and no `PATH` lookup; verified by reading the emitted string.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
