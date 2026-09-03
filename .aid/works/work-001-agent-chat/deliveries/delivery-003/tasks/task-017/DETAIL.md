# task-017: Cursor waker adapter

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

**Depends on:** task-015

**Scope:**
- The same contract in this host's shapes: `followup_message` on output, `loop_count` for re-entry.
- `utf-8-sig` decoding, because this host prefixes its stdin payload with a byte-order mark.
- Unquoted paths, which are correct in PowerShell as well as bash; host-specific quoting **only** where a path contains a space.
- `decision: block` deliberately not used, though it works: it is absent from this host's schema and can change without notice.

**Acceptance Criteria:**
- [ ] A woken session runs one turn and settles; the stop event ending it does not start another wait.
- [ ] From arrival to the session having acted, no approval prompt is raised -- or, where the design requires pre-authorisation, the operator step that satisfies it is performed and named.
- [ ] After a block exceeding the configured hook timeout, no adapter process survives and the waiter count returns to its prior value.
- [ ] A payload prefixed with a byte-order mark is parsed and acted on.
- [ ] The command emitted for the woken turn is accepted by PowerShell; verified by executing it there. Where a path contains a space, the quoted form is used and is also accepted.
- [ ] `decision: block` appears nowhere in this adapter; verified by grep.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
