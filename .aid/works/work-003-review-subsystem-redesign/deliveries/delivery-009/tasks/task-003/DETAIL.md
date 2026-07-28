# task-003: AGENT.md and README: cycles and resume

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

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** task-001

**Scope:**
- The status-reconciliation clause deleted from the body
- A cycles-and-resume section: the two modes, and the paired `In Progress` / `Examined` checkpoint
- The README counterpart

**Acceptance Criteria:**
- [ ] The body states that the reviewer never reconciles Status
- [ ] The paired checkpoint is stated, with `In Progress` written **before** the unit's work -- without it an involuntary death has no signature (AC-7)
- [ ] Regions in `canonical/agents/aid-reviewer/AGENT.md` are declared as **quoted strings, not line numbers** -- the SPEC inventory is valid only against the pre-delivery-003 base
- [ ] `git diff` on the file touches only this delivery's declared regions
- [ ] All section-6 quality gates pass
