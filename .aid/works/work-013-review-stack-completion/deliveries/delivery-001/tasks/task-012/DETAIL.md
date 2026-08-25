# task-012: test-settings-schema-check.sh — five fixtures including the vacuity case

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

**Depends on:** task-011

**Scope:**
- New suite with five fixtures: missing `format_version`, an unemittable `minimum_grade`, an undocumented key, a valid file, and a file with zero keys.

**Acceptance Criteria:**
- [ ] Each fixture's expected exit code is asserted, not merely its output text.
- [ ] The zero-keys fixture asserts exit `1`; a suite that let it pass would be the exact vacuity this gate exists to forbid.
- [ ] Deterministic across runs, fixtures cleaned up, baseline failure count unchanged.
- [ ] All section-6 quality gates pass
