# task-020: Operator install instructions for the stop hook and its timeout

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

**Type:** DOCUMENT

**Source:** feature-003-the-wake -> delivery-003 -> AC-24, AC-25

**Depends on:** task-019

**Scope:**
- Per-host instructions for installing the stop hook that the product will never write itself.
- The `--host-timeout` value to use, and the arithmetic relating it to the long-poll default and the adapter margin.
- What happens when the operator omits it, stated as the observed failure rather than in the abstract.
- The pre-authorisation option, what it buys, and what it costs.
- The instruction never to set fail-closed, and why a hung wait would then freeze the user's session.

**Acceptance Criteria:**
- [ ] The document states an explicit timeout value for each host that ships an adapter, with the arithmetic shown.
- [ ] It states the consequence of omitting it in terms of what the operator will observe -- a wake that never arrives, with nothing reporting why.
- [ ] It says never to set fail-closed, and gives the reason.
- [ ] Accuracy verified by an operator following it on a clean machine and reaching a working wake.
- [ ] All section-6 quality gates pass
