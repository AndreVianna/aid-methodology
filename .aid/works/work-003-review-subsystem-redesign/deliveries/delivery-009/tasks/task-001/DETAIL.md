# task-001: plan-resume.sh and --list-units

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

**Source:** work-003-review-subsystem-redesign -> delivery-009

**Depends on:** --

**Scope:**
- `canonical/aid/scripts/review/plan-resume.sh`, read-only, linter exit codes
- `--list-units` and `--remaining` on the ledger helper
- Invalidation on `art=` or `rs=` digest change, or on an `In Progress` status
- Its test suite

**Acceptance Criteria:**
- [ ] The keep/invalidate verdict is a **partition** over all units -- disjoint and total, so it fails in both directions (AC-6)
- [ ] A criterion change invalidates exactly the affected units, with a negative control proving an unrelated file change invalidates nothing (AC-8)
- [ ] The planner never writes; the orchestrator applies the plan
- [ ] All section-6 quality gates pass
