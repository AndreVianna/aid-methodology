# task-040: test-review-recall.sh — the matcher and its two vacuity cases

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

**Depends on:** task-038

**Scope:**
- A suite for the recall script, modelled on the cost meter's own suite: the status-aware matcher, the nothing-seeded rule, the pair refusal, and a row containing an escaped delimiter.

**Acceptance Criteria:**
- [ ] A ledger whose only matching row no longer counts toward a grade yields a found count of zero, and the suite **fails if the status filter is removed** — that is the exact off-by-one the script exists to prevent.
- [ ] A group with nothing seeded is asserted as missing; a suite that accepted a perfect score there would fail.
- [ ] An empty catalogue or an empty ledger is a refusal, not a clean report.
- [ ] The data-path override is used throughout, so no live data is touched.
- [ ] **If no script merged, this task is closed as `Canceled`** — the closed-enum value for explicitly abandoned work — quoting task-038's recorded discharge in its `notes`, rather than being left `Pending`.
- [ ] Deterministic, fixtures cleaned up, baseline failure count unchanged.
- [ ] All section-6 quality gates pass
