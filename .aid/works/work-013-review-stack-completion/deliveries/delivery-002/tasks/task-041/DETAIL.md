# task-041: The class sweep recorded as part of closing a FIX

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-026

**Scope:**
- `canonical/skills/aid-execute/references/state-fix.md`: the sweep is already instructed; add the record that makes it checkable — the sweep's class, its command, and its residue, carried as commit trailers.
- State that a verifying reviewer re-runs the recorded command.
- Re-run the generator in the same commit.

**Acceptance Criteria:**
- [ ] The three trailer fields and the re-run rule both resolve by grep.
- [ ] A sweep whose recorded command no longer reproduces its recorded residue is stated to be a recurrence, not a bookkeeping nit.
- [ ] The record lives in the commit trailer and **nothing is added to the per-task findings structure**, whose field set is closed — verified by diffing the artifact schema, which must show no change.
- [ ] The fixer is still forbidden from writing the ledger; this task adds a record, not an authority.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
