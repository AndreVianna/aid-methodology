# task-002: Fix commit on the eight SPECs

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

**Source:** work-003-review-subsystem-redesign -> delivery-002

**Depends on:** task-001

**Scope:**
- Every `[UNRESOLVED]` and `[AMBIGUOUS]` citation across the eight feature SPECs
- The false CI claim in `.aid/knowledge/quality-gates.md`, which states the citation lint is blocking for merges to master when it has never run in CI

**Acceptance Criteria:**
- [ ] `--profile resolvable --depth 4` over `features/` exits 1 before this task and 0 after
- [ ] The CI claim is corrected, or the step it claims is shown to exist
- [ ] All section-6 quality gates pass
