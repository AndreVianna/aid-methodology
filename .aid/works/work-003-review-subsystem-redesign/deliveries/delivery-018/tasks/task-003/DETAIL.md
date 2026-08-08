# task-003: The per-section specify review

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

**Source:** work-003-review-subsystem-redesign -> delivery-018

**Depends on:** --

**Scope:**
- The per-section step rebuilt: a screener dispatch, the shared ledger, the gap check, and a `grade.sh` call
- The bare-word severity vocabulary replaced by bracketed tokens
- The review stays inline -- a terminal hand-off cannot serve a step inside a loop

**Acceptance Criteria:**
- [ ] The step writes to the same ledger the final review grades, so it feeds one arithmetic rather than a private one
- [ ] The bare-word vocabulary is gone -- it is the form the grading rubric itself names as producing a silent pass
- [ ] The grade call sits behind the gap gate: the file that gains the `grade.sh` invocation mentions `check-gaps.sh` at an earlier line, so it joins the site set `tests/canonical/test-gap-gate-wiring.sh` derives from disk -- every file invoking `grade.sh` -- and GW02 and GW03 still pass with it added. No ordinal is asserted: the site count moves whenever grading is centralised or a caller is migrated
- [ ] All section-6 quality gates pass
