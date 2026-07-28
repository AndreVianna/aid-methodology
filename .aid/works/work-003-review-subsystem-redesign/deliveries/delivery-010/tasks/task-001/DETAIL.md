# task-001: The boilerplate split, alone

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** REFACTOR

**Source:** work-003-review-subsystem-redesign -> delivery-010

**Depends on:** --

**Scope:**
- `agent-discipline-boilerplate.md` carrying the self-review discipline block; `agent-boilerplate.md` reduced to the heartbeat protocol
- Two `{{include:}}` tokens on consecutive lines in each of the nine existing agents
- Nothing else -- the screener is a separate task so this task's diff can be empty

**Acceptance Criteria:**
- [ ] Re-rendering all seven trees produces a **byte-empty** diff; any diff at all means the split changed a rendered body
- [ ] `agent-boilerplate.md` keeps its name, so the KB citation of it stays valid
- [ ] All section-6 quality gates pass
