# task-001: lint-settings.sh

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

**Source:** work-003-review-subsystem-redesign -> delivery-014

**Depends on:** --

**Scope:**
- The gate validating the minimum-grade enum, the config enums, the doc-set row shape and the term exclusions
- The grade alphabet **derived from the rubric**, not restated
- Its test suite

**Acceptance Criteria:**
- [ ] An out-of-enum minimum grade is rejected; the live settings file passes
- [ ] The enum is derived from the rubric, so no sixth grade alphabet appears -- and the two values the existing output-validation regexes wrongly admit are rejected here
- [ ] Coverage is total over a mechanically derived key set
- [ ] All section-6 quality gates pass
