# task-001: lint-modality.sh

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-013

**Depends on:** --

**Scope:**
- The lint rejecting a missing or non-conforming modality tag on a requirement or acceptance criterion
- Its test suite

**Acceptance Criteria:**
- [ ] A requirement with no modality tag is rejected; one with a non-conforming tag is rejected
- [ ] The accepted vocabulary is `MUST | SHOULD | COULD`, cited to where it is declared rather than restated *(amended 2026-08-11: this read "derived from the canonical scale's step 1"; step 1 is retired, and the vocabulary was never the scale's to own -- it is the same three values feature-level `## Priority` already uses)*
- [ ] All section-6 quality gates pass
