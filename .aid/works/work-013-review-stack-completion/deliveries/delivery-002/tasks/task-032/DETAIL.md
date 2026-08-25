# task-032: The ledger path parameterised across the six brief templates

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-031

**Scope:**
- All six per-skill `references/reviewer-brief.md` files take the ledger path as a parameter rather than naming one.
- One of the six names a fully literal path today; the rest carry a skill-local placeholder.

**Acceptance Criteria:**
- [ ] Each of the six briefs names exactly one ledger path, and it is the parameter.
- [ ] The count of fully literal ledger paths across the six falls to zero, measured before the change.
- [ ] Every occurrence site measured beforehand is accounted for — converted, or kept and classified as documentation.
- [ ] The substitution mechanism is the one the dispatch protocol already documents for its other placeholders; no second mechanism is introduced.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
