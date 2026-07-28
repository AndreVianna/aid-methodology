# task-001: Wire the gate at every grade site

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** MIGRATE

**Source:** work-003-review-subsystem-redesign -> delivery-008

**Depends on:** --

**Scope:**
- `check-gaps.sh` inserted before every `grade.sh` invocation, at all 18 sites
- The Lite path's shortcut engine, whose omission would let every shortcut skill grade over an open gap
- The prose grade call in the ledger schema that the invocation sweep does not see

**Acceptance Criteria:**
- [ ] Every file invoking `grade.sh` mentions `check-gaps.sh` at an earlier line
- [ ] The two machine-validator sites are wired too, so the oracle is total and needs no exclusion list
- [ ] All section-6 quality gates pass
