# task-002: README corrections

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-003-review-subsystem-redesign -> delivery-011

**Depends on:** --

**Scope:**
- The tier claim contradicting the canonical frontmatter
- The assertion that the discipline block is present uniformly, false once the screener exists

**Acceptance Criteria:**
- [ ] The README tier matches the canonical frontmatter
- [ ] The uniformity claim is corrected
- [ ] All section-6 quality gates pass
