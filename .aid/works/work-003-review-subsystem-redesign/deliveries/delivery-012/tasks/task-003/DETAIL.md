# task-003: aid-deep-review

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

**Source:** work-003-review-subsystem-redesign -> delivery-012

**Depends on:** task-001

**Scope:**
- The skill: intake, resume planning, review, orchestrator reconciliation, the gap gate, grade, route, the FIX loop with its circuit breaker
- The five-field FIX executor spec, including the per-doc fan-out `aid-discover` needs

**Acceptance Criteria:**
- [ ] It does its own gap detection unconditionally, whether or not a light pass ran (FR-A5)
- [ ] The FIX executor is parameterised on agent, tier and fan-out -- a single parameter would silently serialise the parallel case
- [ ] The grade is reachable only after the gap gate exits 0
- [ ] All section-6 quality gates pass
