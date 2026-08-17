# task-033: Literal ledger paths retired from the FIX and DONE loop sites

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

**Depends on:** task-032

**Scope:**
- Convert the literal ledger paths in the discover and update-kb FIX/DONE sites to the parameter.
- Classify each site as instruction or documentation **before** touching it, and record the classification per site — this group carries the deepest reasoning and sets the pattern for the next task.
- The unconditional read at the start of the discover FIX state takes the parameter.
- The update-kb REVIEW-step sites are in scope for this task's classification too, not only its FIX/DONE sites: they render a literal path as the result of substituting a scope into a shared template, so whether they are instruction or documentation is exactly the call this task exists to make. Leaving them unclassified would make task-034's zero-canary unreachable.

**Acceptance Criteria:**
- [ ] Every site in this group is recorded with its instruction-or-documentation classification and the reason.
- [ ] The literal-path count for this group reaches zero in the instruction surface, measured before.
- [ ] Retiring the duplicated FIX loop in update-kb is explicitly **out of scope** and is recorded as a follow-up now that the parameter exists — named, not silently carried.
- [ ] Render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
