# task-003: AC-13 cost baseline

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** RESEARCH

**Source:** work-003-review-subsystem-redesign -> delivery-001

**Depends on:** task-002

**Scope:**
- One fixture artifact taken through a full gate passage, before any review-path edit
- Record total dispatch count and FIX-cycle count. ~~per-dispatch agent and tier~~ **Amended at execution** -- the per-dispatch tier is dropped: the `## Dispatch Log` telemetry AC-13 was written against is never actually written (49 dispatches, zero rows), so tier was unrecoverable and its weighting was never defined. Populating that log is now a prerequisite of AC-13, not an input to it. See REQUIREMENTS.md AC-13 and BASELINE-ac13.md.

**Acceptance Criteria:**
- [ ] Dispatch count and FIX-cycle count are recorded for the named fixture, each traceable to
      the session record or a runnable command
- [ ] The measure's limits are stated explicitly: what the baseline can support (count
      comparison) and what it cannot (tier weighting, wall-clock, Execute-phase reviews)
- [ ] ~~The tier-weighted dispatch cost is stated~~ -- **cut**, per the AC-13 amendment
- [ ] All section-6 quality gates pass
