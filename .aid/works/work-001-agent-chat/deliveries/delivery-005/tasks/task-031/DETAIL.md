# task-031: Mention and whisper

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

**Source:** feature-005-directed-retention-visibility -> delivery-005 -> AC-17, AC-18

**Depends on:** task-030

**Scope:**
- The two reserved columns filled; the two options mutually exclusive on one message.
- `whisper_to` validated as naming a **current member**, refused otherwise; `mention` of a non-member warned rather than refused.
- The whisper filter applied identically to delivery and to history, through **one** query path with no bypass anywhere -- the operator's views included.

**Acceptance Criteria:**
- [ ] In a channel of three or more, a whispered message reaches only its target and its sender, **on delivery and in history**.
- [ ] A mentioned message reaches every member, and the mentioned member can tell it was aimed at them.
- [ ] Both options set on one message is refused with `mention_and_whisper`.
- [ ] A whisper naming a non-member is refused; a mention naming one succeeds at exit 0 with `mention_unknown` and the names on stderr.
- [ ] There is exactly one read path for messages; verified by enumerating every message-select site and asserting the filter applies at each.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
