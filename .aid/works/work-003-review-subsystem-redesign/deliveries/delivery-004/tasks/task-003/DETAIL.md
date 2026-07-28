# task-003: Relocate the content-isolation rule

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** REFACTOR

**Source:** work-003-review-subsystem-redesign -> delivery-004

**Depends on:** task-002

**Scope:**
- The content-isolation rule moved into the catalog
- The phantom `content-isolation.md` citation, retired wherever it appears

**Acceptance Criteria:**
- [ ] The rule is expressed as a catalog row with a resolving `Criterion`
- [ ] `grep -rn 'content-isolation.md'` returns nothing in the canonical tree
- [ ] All section-6 quality gates pass
