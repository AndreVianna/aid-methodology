# task-009: Recorded closing audit — the FR-A5 evidence for AC-1 and AC-8

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

**Type:** TEST

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-002, task-006, task-007, task-008

**Scope:**
- Run, and paste into the delivery record beside each command: the audit and its exit code; the two `ls` globs as a regression check; the `rubric catalog` and `review-rubrics` greps; the three-spelling 7-column greps; the cascade-only grep in the reviewer agent; `gh pr view 185 --json state`; and `git rev-parse work-003`.
- Record whether gate criterion 2 is met, and if not, name the owner action that would meet it.

**Acceptance Criteria:**
- [ ] Every output is recorded beside the command that produced it, and re-running any of them reproduces what is recorded.
- [ ] `git rev-parse work-003` still resolves after the migration has landed, so the migration source is not orphaned.
- [ ] If `gh pr view 185 --json state` is not `CLOSED`, the record states gate criterion 2 as unmet and names closing the pull request as an owner action — this task performs no pull-request write of any kind.
- [ ] All section-6 quality gates pass
