# task-002: RESOLVE gate and CI step

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

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** task-001

**Scope:**
- The gate in `aid-deep-review` **RESOLVE** -- the state that reads the manifest and resolves the artifacts, and the last one before DISPATCH; one site covering every definition skill plus `aid-review` plus the shortcut engine
- The CI step, which does not exist yet: no workflow references the citation lint, so this task **adds** the step rather than making an existing one honest -- the KB claim that it already ran was corrected by delivery-002

**Acceptance Criteria:**
- [ ] The gate runs before any dispatch and blocks it on exit 1, so a citation defect costs no review cycle
- [ ] The lint runs in CI
- [ ] All section-6 quality gates pass
