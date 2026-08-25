# task-029: test-severity-why-line.sh — the contract and the escaped-pipe trap

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

**Depends on:** task-028

**Scope:**
- New suite asserting the why-line contract against fixtures, because a live ledger is transient and absent in CI.
- Cases: a compliant row; a row with no consequence clause; a row with no provenance token; and a row whose Description contains an escaped pipe.
- Re-price the same fixture rows through the grading script.

**Acceptance Criteria:**
- [ ] The escaped-pipe row is asserted against the measured field shift — a naive split gives that row more fields than its siblings, so the screen reads the wrong cell unless it masks first.
- [ ] The suite fails when the masking is removed from the screen, which is what proves the assertion is not vacuous.
- [ ] Each fixture row's resulting grade is asserted individually rather than as one aggregate, so a failure says which row moved.
- [ ] Deterministic across runs, fixtures cleaned up, baseline failure count unchanged.
- [ ] All section-6 quality gates pass
