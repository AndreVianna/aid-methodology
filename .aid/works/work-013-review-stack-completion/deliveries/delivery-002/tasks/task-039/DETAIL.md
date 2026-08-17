# task-039: review-recall.sh — the record subcommand and its run-id pair

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

**Depends on:** task-038

**Scope:**
- The `record` subcommand and the data-plus-provenance pair the SPEC's data model specifies, including the refusal when the pair's run ids disagree.
- A data-path override so no live data is touched during testing.

**Acceptance Criteria:**
- [ ] **This task ships only if task-036's measurement justifies it.** No gate criterion in this delivery requires `record`; only the SPEC's data model does. If the justification is absent, the task is closed as **`Canceled`** — the closed-enum value for explicitly abandoned work — with task-036's measurement quoted as the reason in its `notes`. It is never left `Pending` and never silently dropped; naming it as its own task is what makes the decision visible.
- [ ] If it ships: a mismatched pair is refused rather than silently reconciled, and the refusal names both run ids.
- [ ] If it ships: the header cites its own measured re-derivation, distinct from the report subcommand's.
- [ ] Two consecutive runs are byte-identical.
- [ ] All section-6 quality gates pass
