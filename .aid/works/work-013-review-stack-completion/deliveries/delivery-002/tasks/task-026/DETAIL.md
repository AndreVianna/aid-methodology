# task-026: Delivery base commit, measured baselines, and the evidence record

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

**Type:** CONFIGURE

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** -- (none)

**Scope:**
- Record `git rev-parse HEAD`, run at execution time, as this delivery's own base — before any task edits a file. This delivery branches from delivery-001's merged state, so it has its own base, not delivery-001's.
- Create the recorded-output section the ten gate criteria paste into.
- Re-measure, never copy, the baselines this delivery is graded against: the why-line screen on whatever real ledger exists at that moment, the suite count and pass/fail totals, and the selector and literal-path counts.

**Acceptance Criteria:**
- [ ] The base commit equals `git rev-parse HEAD` at the moment this task ran, and is never a value copied from a document — the SPEC's recorded head is already stale.
- [ ] Every baseline is captured by running its command now, with the command recorded beside the number. A baseline quoted from the SPEC is a defect: the SPEC's own why-line provenance figure has already changed since approval.
- [ ] The suite baseline records both the suite count and the current pass/fail totals, so a later comparison is against a measured starting point rather than an assumed clean tree.
- [ ] This task edits nothing under `canonical/` — `git diff --name-only canonical/` is empty for its commit.
- [ ] All section-6 quality gates pass
