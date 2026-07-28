# task-003: Emit the review/ script directory

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-003-review-subsystem-redesign -> delivery-006

**Depends on:** task-001

**Scope:**
- The emission path for the new `canonical/aid/scripts/review/` directory across all five profiles

**Acceptance Criteria:**
- [ ] The directory and its scripts are emitted and executable under every tool root, **confirmed by rendering** rather than by assuming the directory mapping is live
- [ ] The helper's relative `grade.sh` resolution works from each rendered location
- [ ] All section-6 quality gates pass
