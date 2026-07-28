# task-005: AGENT.md: the gap outcome

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-007

**Depends on:** task-002, task-003

**Scope:**
- The gap-record contract and the criteria-gap escalation route in the body
- The inline-check-enumeration licence in `reviewer-dispatch.md`, retired
- The interim `OOS` rule-citation exemption, deleted from the helper's validation

**Acceptance Criteria:**
- [ ] The body states that a missing criterion produces a gap row, and that the calling skill promotes it
- [ ] An ungrounded finding is unwritable at every status, including `OOS`
- [ ] Regions in `canonical/agents/aid-reviewer/AGENT.md` are declared as **quoted strings, not line numbers** -- the SPEC inventory is valid only against the pre-delivery-003 base
- [ ] `git diff` on the file touches only this delivery's declared regions
- [ ] All section-6 quality gates pass
