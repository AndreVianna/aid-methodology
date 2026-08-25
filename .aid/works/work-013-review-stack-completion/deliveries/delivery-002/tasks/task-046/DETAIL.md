# task-046: The cost meter counts a path once and attributes a region to its file

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

**Depends on:** task-045

**Scope:**
- `tests/review-cost-meter.sh`: count a path once per cycle even when both lists name it, and attribute a heading-qualified entry to its file.
- Forward-only — existing rows keep their meaning.

**Acceptance Criteria:**
- [ ] The double count is closed: the recorded surface for a brief naming one path twice halves, with the extractor's before-output recorded showing the same path emitted twice.
- [ ] **A heading-qualified entry is attributed to its file rather than dropped.** Measured today the extractor drops it and records zero, which means writing a region into a brief would make the "no longer twice the file size" figure pass **for the wrong reason** — this criterion is what makes the number mean what it says.
- [ ] A brief naming no parseable path warns rather than silently recording zero.
- [ ] The change is recorded as a measurement-tool change, with the forward-only rule stated so old rows are not silently re-interpreted.
- [ ] All section-6 quality gates pass
