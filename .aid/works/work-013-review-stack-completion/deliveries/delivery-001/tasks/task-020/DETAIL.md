# task-020: Bound the work-artifact corpus before giving it a registry home

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

**Type:** RESEARCH

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-019

**Scope:**
- Determine which work-folder artifacts should resolve to a registry type: the candidate set is `REQUIREMENTS.md`, `PLAN.md`, `features/*/SPEC.md` and `deliveries/*/BLUEPRINT.md` — not every file a work writes.
- Run the selector-partition oracle against the proposed selector before any row is written, so the blast radius is measured rather than discovered.
- State files are excluded by an existing criterion and must stay excluded.

**Acceptance Criteria:**
- [ ] The proposed corpus is stated as a selector, with the file count it matches and the command that produced it.
- [ ] The oracle is run against the proposed selector and its result recorded, showing whether every in-scope file still resolves to exactly one type.
- [ ] If the proposed selector would break the partition, that is the finding, and the recommendation is to narrow rather than to widen the partition rule.
- [ ] All section-6 quality gates pass
