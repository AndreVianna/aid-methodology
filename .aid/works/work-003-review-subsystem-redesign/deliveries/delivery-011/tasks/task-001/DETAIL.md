# task-001: The FR-A10 residual rewrite

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

**Source:** work-003-review-subsystem-redesign -> delivery-011

**Depends on:** --

**Scope:**
- The opening role statement, rewritten for a two-agent world
- The `## Tasks State` write-target defect -- a renamed, DERIVED section the body still instructs writing
- The source-authority and cross-reference lines, re-anchored to the catalog
- The severity-tagging instruction that still tells the reviewer to assign severity
- A new depth-and-division-of-labour section

**Acceptance Criteria:**
- [ ] The body names the deep/screen division and states this agent is the graded one
- [ ] No instruction to write a DERIVED section remains
- [ ] No instruction to assign severity remains -- severity comes from the rule
- [ ] Regions in `canonical/agents/aid-reviewer/AGENT.md` are declared as **quoted strings, not line numbers** -- the SPEC inventory is valid only against the pre-delivery-003 base
- [ ] All section-6 quality gates pass
