# task-006: Reviewer instruction: run the oracle rather than re-read the criterion

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

**Depends on:** task-003

**Scope:**
- `canonical/agents/aid-reviewer/AGENT.md` and **every** `canonical/skills/*/references/reviewer-brief.md`, enumerated from disk at execution rather than from a list here. Six exist at authoring time.
- During criteria resolution, a `validate` criterion carrying an `oracle:` is decided by RUNNING it under a 60-second timeout; one without is judged by reading, exactly as today.
- One finding per `VIOLATION` line: criterion `id` as a `Description` prefix, invocation and output in `Evidence`.
- `UNDECIDED` files are judged by reading; a degraded oracle degrades the whole criterion to reading and the degradation is reported.
- Authored instruction only -- this task adds no executable surface.

**Acceptance Criteria:**
- [ ] The run-don't-read rule and the degradation rule are stated in `aid-reviewer/AGENT.md` and in **every** brief the glob returns, with the count edited reported
- [ ] The ledger stays 7 columns; no new column is introduced anywhere (C-3, AC-16)
- [ ] Absence of an `oracle:` key produces no finding and no behavioural change (AC-5)
- [ ] `UNDECIDED` handling is distinguished from degradation -- partial coverage is normal, not a failure
- [ ] No script, validator, gate or CI step is added by this task
- [ ] All REQUIREMENTS.md §6 quality gates pass
