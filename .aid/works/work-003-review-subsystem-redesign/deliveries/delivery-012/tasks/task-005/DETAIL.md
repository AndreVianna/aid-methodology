# task-005: Migrate nine callers

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** MIGRATE

**Source:** work-003-review-subsystem-redesign -> delivery-012

**Depends on:** task-002, task-003

**Scope:**
- The eight dispatch owners, each writing a manifest and handing off
- `aid-review`, whose meta-review VERIFY loop is deliberately retained; `aid-audit` needs no edit
- The terminal hand-off line under CHAIN's use list -- a new use of an existing advance type
- The `aid-triage` routing row sending human review requests to `/aid-review`

**Acceptance Criteria:**
- [ ] No caller retains its own ledger, grade call or FIX loop
- [ ] The Lite path's shortcut engine is migrated too
- [ ] No fifth advance type is introduced; the no-new-pattern rule is untouched
- [ ] All section-6 quality gates pass
