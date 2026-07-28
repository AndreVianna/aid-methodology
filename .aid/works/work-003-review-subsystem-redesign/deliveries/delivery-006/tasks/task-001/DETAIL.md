# task-001: writeback-ledger.sh

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

**Source:** work-003-review-subsystem-redesign -> delivery-006

**Depends on:** --

**Scope:**
- `canonical/aid/scripts/review/writeback-ledger.sh`: append-finding, append-unit, append-gap, set-status, get-status
- Script-assigned row IDs, the sentinel lock, CRLF and trailing-newline invariance, pipe escaping, default-on grade verification
- Rejection of a finding row carrying no rule ID -- the mechanical AC-3 enforcement point
- `tests/canonical/test-writeback-ledger.sh`

**Acceptance Criteria:**
- [ ] `--set-status` leaves every other row byte-identical and never renumbers
- [ ] A finding row with no rule ID is rejected; the interim `OOS` exemption is honoured until delivery-007 retires it
- [ ] `--append-gap` is idempotent on its key and increments a recurrence counter
- [ ] CRLF and no-trailing-newline fixtures pass, since ledgers are written on Windows
- [ ] All section-6 quality gates pass
