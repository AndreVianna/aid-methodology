# task-016: Meter invocation wired into the dispatch step

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml.

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

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-015

**Scope:**
- `canonical/aid/templates/reviewer-dispatch.md`: make rendering the brief TO A FILE a required step of dispatch, and make the `review-cost-meter.sh record` call part of that same step.
- Every `canonical/skills/*/references/reviewer-brief.md` the glob returns: the render-then-record sequence, so no skill carries a dispatch path that skips it.
- The path is `.aid/works/{work}/briefs/<scope>-cycle-<N>.md`, which also satisfies the protocol's existing inspectability requirement that a rendered brief be logged with its dispatch record.
- NOT in scope: changing what a brief CONTAINS, or the meter itself.

**Acceptance Criteria:**
- [ ] The brief is rendered to a file before dispatch, and the `record` call reads that same file -- one step, not two, so there is no ordering an agent can get wrong
- [ ] **A dispatch that skips the record call is DETECTABLE**: the brief file's absence is the signal, because the same step produces both. The previous design mandated a call that an agent could satisfy by doing nothing, which is precisely the W5-5 shape this task exists to close
- [ ] The instruction appears in `reviewer-dispatch.md` and in every brief the glob returns, with the count edited reported
- [ ] No new executable surface: this is authored instruction plus a call to the meter that already exists
- [ ] The existing inspectability requirement is satisfied by the same artifact rather than by a second one
- [ ] All REQUIREMENTS.md §6 quality gates pass
