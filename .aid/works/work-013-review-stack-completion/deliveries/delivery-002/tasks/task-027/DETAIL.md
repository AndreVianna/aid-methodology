# task-027: The two missing COVERS headers, so both NFR-1 canaries are selectable

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

**Depends on:** task-026

**Scope:**
- Add the missing `# COVERS:` entry to `tests/canonical/test-criterion-oracles.sh` for the reviewer agent file it asserts against, and to `tests/canonical/test-scoped-review-cycles.sh` for the grading script it runs.
- Two header lines. No assertion logic is touched.
- Record the residual instances of the same class that this task does not fix, with their route.

**Acceptance Criteria:**
- [ ] The suite selector now returns the oracle suite for a change to the reviewer agent file alone, measured at zero before — which is why the guard could be skipped by exactly the change that breaks it.
- [ ] The selector likewise returns the scoped-cycle suite for a change to the grading script, measured at zero before.
- [ ] The control case still resolves, so the fix did not simply widen the selector into always-true.
- [ ] Both suites still pass with their assertion counts unchanged.
- [ ] The remaining incomplete-header instances are recorded as a non-zero sweep residue with their route — the class is reported, not quietly narrowed to the two fixed here.
- [ ] All section-6 quality gates pass
