# task-003: AC-17 asserted in both directions

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-003-review-subsystem-redesign -> delivery-025

**Depends on:** task-002

**Scope:**
- `tests/canonical/fixtures/class-sweep/**`: a claim corrected in one file and restated in **two others** -- `AC-17`'s own wording, not a weaker "sites"
- `tests/canonical/test-class-sweep.sh`, asserting the obligation both ways

**Acceptance Criteria:**
- [ ] A phrase taken from the correction reports **both** other files
- [ ] A phrase absent from the correction reports **no** sites -- which is what makes the substring rule falsifiable rather than decorative
- [ ] The fix is **rejected** until the sweep output naming both files is on the record. Both clauses of `AC-17` bind: *not accepted until*, and *on the record*
- [ ] Verified in both directions: a run with the sweep passes, a run without it fails. A suite that only checks the passing direction cannot fail when the obligation is dropped
- [ ] All section-6 quality gates pass
