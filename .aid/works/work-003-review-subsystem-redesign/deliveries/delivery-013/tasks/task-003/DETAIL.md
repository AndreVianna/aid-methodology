# task-003: Back-fill existing modalities

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

**Source:** work-003-review-subsystem-redesign -> delivery-013

**Depends on:** task-001

**Scope:**
- Every existing requirement and acceptance criterion in the tree, tagged

**Acceptance Criteria:**
- [ ] The lint passes over the whole tree
- [ ] No requirement or acceptance criterion is left untagged, over a derived file set
- [ ] All section-6 quality gates pass
