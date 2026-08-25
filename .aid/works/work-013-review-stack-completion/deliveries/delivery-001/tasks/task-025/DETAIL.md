# task-025: Delivery evidence — render parity, the base diff, and the twelve criteria

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-010, task-011, task-012, task-013, task-014, task-015, task-016, task-017, task-018, task-019, task-020, task-021, task-022, task-023, task-024

**Scope:**
- Run the full generator, the deterministic verifier, and both site generators; record the render diff over all five generated regions.
- Run the base-commit diff for the counting-logic and column-shape check, using the base recorded by task-001.
- Record the history sweep, the VERIFY/HUNT brief greps, the cost-meter row from the first post-T1 dispatch, and the FR-B6 decline.
- Confirm every count in the delivery record re-derives.

**Acceptance Criteria:**
- [ ] `verify_deterministic.py` reports PASS, and the render diff over the five generated regions contains only generator-written paths — no hand-edit.
- [ ] `git diff <recorded-base> HEAD` over the grading script and the ledger schema touches neither counting logic nor column shape, using the base from task-001 rather than a moving branch.
- [ ] The history sweep returns only the classified keep rows, and the generated site data's remaining hits are the rule text that forbids a history section — verified by regeneration drift, not by assertion.
- [ ] Every cycle-2 or later brief carries the two labelled artifact lists and every cycle-1 brief the single unlabelled list; a `review-cost.tsv` row matches the brief from the first dispatch that ran after the last feature-001 task reached Done.
- [ ] FR-B6 is recorded as **declined by owner decision**, with its two measured reasons — not omitted, and not silently skipped.
- [ ] Every count in the delivery record carries its command and reproduces when re-run.
- [ ] The test suite's failure count matches the baseline measured at the start of this delivery.
- [ ] All section-6 quality gates pass
