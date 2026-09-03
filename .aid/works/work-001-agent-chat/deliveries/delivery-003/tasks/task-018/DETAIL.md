# task-018: Rendered chat skill

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

**Source:** feature-003-the-wake -> delivery-003 -> AC-15

**Depends on:** task-017

**Scope:**
- One canonical skill rendered into all five host dialects by the pipeline this repository already has -- no per-host hand authoring.
- It describes `send` / `inbox` / `ack`, the session's own channel, and the hub verbs; it carries no logic and holds no state.
- It describes no administrative operation and no `wait`, and the product writes no host configuration.

**Acceptance Criteria:**
- [ ] The skill renders into all five profiles through the existing generator, with no hand-authored per-host variant.
- [ ] Its verb list is exactly what FR-7.3 permits and contains nothing FR-7.3 forbids; verified by diffing the two lists.
- [ ] It documents no `wait` verb.
- [ ] An operation performed by following the skill and the same operation invoked directly on the CLI produce the same result against the same store.
- [ ] All existing tests pass; build passes.
- [ ] All section-6 quality gates pass
