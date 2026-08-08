# task-002: Grade the BLUEPRINT

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

**Source:** work-003-review-subsystem-redesign -> delivery-018

**Depends on:** task-001

**Scope:**
- The BLUEPRINT added to the artifact set of the reviews that already run. Two of the four sites already name it -- `aid-plan/references/first-run-loop.md` and `review-deliverables.md` both read `artifacts: PLAN.md and every delivery BLUEPRINT.md`, rewritten to that form by delivery-012 -- so the edit lands on the two `aid-detail` sites (`first-run.md`, `review.md`), which still read `every tasks/task-NNN/DETAIL.md on disk`. The inherited "all four" premise predates that rewrite
- `## Tasks` scoped out at Plan and in at Detail
- The two stale claims in the blueprint template

**Acceptance Criteria:**
- [ ] The BLUEPRINT appears in all four artifact sets
- [ ] The legitimately-empty Tasks table is not flagged at Plan
- [ ] The template no longer names a skill that never writes it, nor calls gate criteria a rubric
- [ ] All section-6 quality gates pass
