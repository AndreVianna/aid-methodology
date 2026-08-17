# task-042: The four sweep steps, including a residue of one

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

**Type:** TEST

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-027, task-037, task-041

**Scope:**
- Extend `tests/canonical/test-scoped-review-cycles.sh`, which already declares both templates this delivery edits, with the four sweep steps.
- Its existing seeded-defect harness builds a temporary git repository; the corpus this task sweeps is the recall catalogue task-037 creates, which is a different fixture set. Add the corpus handling rather than assuming the harness already covers it.
- The steps: a ledger row names the first instance only; the recorded sweep command over a temporary copy of the corpus finds both; after fixing only the first the residue is one; after both, zero.

**Acceptance Criteria:**
- [ ] The residue-of-one step is asserted, so a sweep that finds nothing cannot pass as a sweep that ran — that vacuous pass is the whole failure mode.
- [ ] The temporary copy is mutated and the source is asserted byte-identical afterwards.
- [ ] The suite's pre-existing assertions all still pass, including the one that pins the ledger's column count.
- [ ] Baseline failure count unchanged.
- [ ] All section-6 quality gates pass
