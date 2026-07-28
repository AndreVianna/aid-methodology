# task-001: The gap register

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

**Source:** work-003-review-subsystem-redesign -> delivery-007

**Depends on:** --

**Scope:**
- The `## Criteria Gaps` section and its eight-column schema in the work and discovery state templates
- The companion `Impact: Required` Q&A entry convention for KB scope

**Acceptance Criteria:**
- [ ] The register schema is defined in both templates, with the gap-key format and its stability rule
- [ ] Neither register file is gitignored, so the record survives the halt and the ledger's deletion
- [ ] All section-6 quality gates pass
