# task-006: AC-11 and AC-12

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-003-review-subsystem-redesign -> delivery-012

**Depends on:** task-004, task-005

**Scope:**
- A suite carrying the delivery-001 baselines as literals with their producing commands in comments

**Acceptance Criteria:**
- [ ] Every migrated caller's review-mechanics count strictly decreases
- [ ] The shared-asset budget plus the new shared assets is below the pre-migration budget -- the anti-gaming clause, without which shorter is achieved by moving lines
- [ ] Aggregate count falls by at least 40% (AC-11, provisional -- delivery-014 re-certifies)
- [ ] Identical review behaviour on all five profiles (AC-12); this delivery owns the criterion of record
- [ ] All section-6 quality gates pass
