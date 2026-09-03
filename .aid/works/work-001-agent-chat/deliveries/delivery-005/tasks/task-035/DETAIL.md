# task-035: Operator visibility and the audit log

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

**Source:** feature-005-directed-retention-visibility -> delivery-005 -> AC-14

**Depends on:** task-034

**Scope:**
- The CLI showing machines and sessions, this hub's open channels and their members, each member's unread depth **and idle time**, and the audit log.
- Whisper bodies excluded from the audit log, while the fact of a whisper and its parties are recorded.
- Retention policy settable through the CLI.
- Eviction: removing a session from its channel.

**Acceptance Criteria:**
- [ ] The listing shows all of: machines, sessions, open channels with members, per-member unread depth, per-member idle time, and the audit log.
- [ ] The audit log records that a whisper was sent and between whom, and does **not** contain its body; verified by sending a whisper containing a unique string and grepping the audit output for it.
- [ ] Evicting a session removes it from its channel and it stops receiving that channel's messages.
- [ ] Retention parameters are settable through the CLI and take effect with no code change.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
