# task-001: The attributed-quote check

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

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** --

**Scope:**
- The check: a string presented as verbatim from a named file must appear in that file
- Emphasis normalisation on both sides before comparison -- mandatory
- Advisory handling for an unattributed quote and for an elided one
- Its test suite

**Acceptance Criteria:**
- [ ] A quote present passes; absent fails; **differing only in markdown emphasis passes** -- without the third the check ships with false positives on this repository's own specs
- [ ] An unattributed quote is advisory and does not change the exit code, so the coverage boundary is reported rather than hidden
- [ ] All section-6 quality gates pass
