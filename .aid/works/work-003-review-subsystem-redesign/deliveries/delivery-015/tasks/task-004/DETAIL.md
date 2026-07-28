# task-004: Retire the binary verdicts

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

**Source:** work-003-review-subsystem-redesign -> delivery-015

**Depends on:** task-001

**Scope:**
- The two coverage-ratio verdict conditions, retired in favour of the conservative rules beside them
- The verdict derivations re-pointed at the Rule column instead of Description substrings
- The visual gate split three ways, with the non-functional flag reserved for nothing-usable

**Acceptance Criteria:**
- [ ] No coverage-ratio condition survives
- [ ] The derivations key on a closed enum rather than a substring
- [ ] The non-functional flag is used only where the artifact produces nothing usable
- [ ] All section-6 quality gates pass
