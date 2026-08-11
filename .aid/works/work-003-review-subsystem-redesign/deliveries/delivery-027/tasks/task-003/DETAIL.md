# task-003: FR-H3's regression print

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

**Source:** work-003-review-subsystem-redesign -> delivery-027

**Depends on:** task-002

**Scope:**
- The comparison `FR-H3` needs: the new figure printed beside that rule set's prior runs from the series
- Nothing that decides anything -- `FR-H3` is a review obligation with no specified threshold, and a reviewer judges

**Acceptance Criteria:**
- [ ] For each rule set, the new figure is printed alongside its prior runs, so a drop is visible without being computed against a bar
- [ ] **No threshold exists anywhere in the script** -- not a default, not a flag. `FR-H3` deliberately specifies none, and inventing one here would be a second arithmetic
- [ ] The print does not gate: the script's exit status does not depend on whether a figure fell
- [ ] A rule set with no prior run prints the new figure and says there is nothing to compare against -- not a zero, and not silence
- [ ] All section-6 quality gates pass
