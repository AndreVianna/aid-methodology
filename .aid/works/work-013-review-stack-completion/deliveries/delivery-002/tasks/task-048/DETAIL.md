# task-048: Delivery evidence — the ten gate criteria, render parity, and the base diff

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

**Depends on:** task-029, task-030, task-035, task-040, task-042, task-044, task-047

**Scope:**
- Run and record: the why-line screen on this delivery's own real ledger plus a reading of every residue row by number; the three isolation attempts; the recall report's output; the sweep trailer's command re-run against its recorded residue; the zero-row oracle run; the full generator and the render diff; the base-commit diff; and the NFR-3 discharge.

**Acceptance Criteria:**
- [ ] The why-line screen reports every row carrying one, with both residue lists empty, **and** every flagged row is read and reported by number — the record states which half is the coverage check and which is the substance check.
- [ ] The grading-script diff against task-026's base is empty, and the schema's non-empty diff is shown to touch neither counting logic nor column shape, re-running task-030's three checks.
- [ ] `verify_deterministic.py` reports PASS and the render diff contains only generator-written paths, with no hand-edit in the profile or dogfood trees.
- [ ] The region-coverage demonstration is recorded, **or** its absence is recorded as a SHOULD not demonstrated with the reason — never omitted. A cycle 2 may simply not occur, and saying so is a legitimate discharge.
- [ ] NFR-3 is recorded as satisfied **or** as a recorded non-merge with its measurement.
- [ ] Every count in the delivery record carries its command and reproduces when re-run.
- [ ] The suite failure count matches the baseline task-026 recorded.
- [ ] All section-6 quality gates pass
