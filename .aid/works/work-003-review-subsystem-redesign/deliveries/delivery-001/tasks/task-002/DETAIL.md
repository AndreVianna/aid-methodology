# task-002: AC-11 baseline

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** RESEARCH

**Source:** work-003-review-subsystem-redesign -> delivery-001

**Depends on:** --

**Scope:**
- Measure and record `B`, the shared review-asset line budget
- Measure and record the nine-row per-caller `C` table, using the fixed pattern feature-006's SPEC declares

**Acceptance Criteria:**
- [ ] Both numbers are recorded with the exact command that produced each
- [ ] The numbers are transcribed into the feature-006 SPEC as literals with the producing command in a comment, so they survive this work folder being pruned
- [ ] All section-6 quality gates pass
