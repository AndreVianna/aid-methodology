# task-019: kb-citation-lint.sh gains a depth option and a work-artifact invocation

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-014

**Scope:**
- Add a recursive/depth option to `kb-citation-lint.sh`, defaulting to today's depth-1 behaviour so the Knowledge Base invocation is bit-for-bit unaffected.
- Add the work-artifact invocation that uses it.

**Acceptance Criteria:**
- [ ] Run over a work root, the lint opens every `.md` beneath it, where today it opens only the depth-1 files and silently skips every nested feature SPEC — both counts recorded.
- [ ] **The assertion is the opened count, not the verdict**: a clean verdict is exactly what the current false green already produces.
- [ ] The Knowledge Base invocation's opened count and verdict are byte-identical to before the change.
- [ ] The rule against bare line-number citations in prose is preserved, and a ledger `Line` cell is not treated as a violation.
- [ ] All section-6 quality gates pass
