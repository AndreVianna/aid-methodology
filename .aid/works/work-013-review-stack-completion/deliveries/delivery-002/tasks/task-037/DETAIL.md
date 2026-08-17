# task-037: The seeded-defect corpus and its catalogue

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

**Depends on:** task-036

**Scope:**
- A catalogue file plus one fixture per row, at the fixtures location the KB already documents.
- Two fixtures deliberately share a class and a signature, so the class sweep has a genuine second instance to find.

**Acceptance Criteria:**
- [ ] Every row's signature appears in its fixture and **nowhere else in the repository**, asserted per row rather than spot-checked — a signature that also matches real content makes both the recall figure and the sweep wrong.
- [ ] No cell contains a delimiter, the absent marker is used consistently, and every defect id is unique.
- [ ] Exactly one pair shares a class and signature, and only one of the two is named by any ledger row — otherwise the sweep has nothing left to find.
- [ ] The corpus never touches the reviewed tree: nothing is seeded into `canonical/`.
- [ ] The row count equals what task-036 decided, citing that decision.
- [ ] All section-6 quality gates pass
