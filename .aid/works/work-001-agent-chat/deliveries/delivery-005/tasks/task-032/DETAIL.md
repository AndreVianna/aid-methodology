# task-032: Retention: the reaping schedule, the trim job and the unread bound

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

**Source:** feature-005-directed-retention-visibility -> delivery-005 -> AC-11

**Depends on:** task-031

**Scope:**
- The periodic reaping job -- the schedule task-005 deliberately left to this delivery -- deleting the session row and, when it was the last member, closing its channel **in one transaction**.
- The trim job, per hub, over its own live members' acknowledged positions **and** the TTL.
- The unread-depth bound enforced on send.
- `CREATE INDEX message_trim ON message (channel_id, received_at)`, the one index Feature 005 adds, created here because the trim job is its only reader.
- Every parameter resolved through the settings reader; nothing hardcoded.

**Acceptance Criteria:**
- [ ] A message past its TTL that every live local member has acknowledged is removed; one an un-reaped local member has not acknowledged is kept.
- [ ] A reaped member stops counting toward the trim point, after which a message only it never acknowledged becomes removable.
- [ ] Reaping the last member and closing its channel is atomic; verified by interrupting between the two and asserting no channel with zero members survives.
- [ ] When no live member has acknowledged anything, nothing is deleted.
- [ ] `message_trim` exists after this task; verified by reading the schema back.
- [ ] No limit is hardcoded; verified by changing each parameter in settings and observing the behaviour change.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
