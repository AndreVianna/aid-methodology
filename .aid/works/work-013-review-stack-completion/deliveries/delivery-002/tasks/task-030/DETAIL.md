# task-030: Recorded NFR-1 verification of the schema edit, three ways

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-028

**Scope:**
- Run and record, at the point the edit lands rather than at the end of the delivery: the grading-script diff against task-026's base; the header-row grep; the enum and status-table comparison; both pinned literals; the scoped-cycle suite's fixture grades individually; and the two selector counts.

**Acceptance Criteria:**
- [ ] `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh` is **empty** — stricter than the acceptance criterion requires, and correct for a file this delivery has no reason to touch.
- [ ] The scoped-cycle suite's three fixture grades are recorded **individually**, because that suite combines its literal check and its grades in one assertion and so reports that something broke without saying which.
- [ ] The schema's non-empty diff is stated line by line against the prohibited set — counting logic and column shape — rather than summarised as safe.
- [ ] The record lists each of the checks above by name with its command and its output, so a reader re-runs the verification rather than trusting the conclusion — and it states the selector count that makes the suite reachable at all, which is the one number a full-suite run triggered by some other file would have hidden.
- [ ] All section-6 quality gates pass
