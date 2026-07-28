# task-003: Roster nine to ten

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

**Source:** work-003-review-subsystem-redesign -> delivery-010

**Depends on:** task-002

**Scope:**
- The tiering table row for the screener, with its never-escalates clause
- The 21 count assertions across 13 user-facing surfaces
- The two hardcoded agent-count literals in the site reference test, derived from the directory listing rather than bumped

**Acceptance Criteria:**
- [ ] The doc-count gate passes with the agent count at 10
- [ ] The count literals are derived, so they cannot drift again
- [ ] All section-6 quality gates pass
