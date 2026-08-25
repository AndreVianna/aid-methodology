# task-001: Delivery evidence record — base commit and criterion-id ledger

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

**Type:** CONFIGURE

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Record `git rev-parse HEAD`, run at execution time, into the delivery record as this delivery's base commit — BEFORE any other task edits a file.
- Create the recorded-output section of the delivery record that the twelve gate criteria paste their command output into.
- Seed the criterion-id allocation ledger with the existing namespace and the next free number per scope prefix.

**Acceptance Criteria:**
- [ ] The base commit is recorded and equals `git rev-parse HEAD` at the moment this task ran; it is never a value copied from a document.
- [ ] The ledger records the current criteria namespace with the command that produced it (`awk` over the criteria table in `.aid/knowledge/authoring-conventions.md`), and the next free number for each scope prefix.
- [ ] The ledger states the never-reuse-a-catalog-id rule: a migrated row takes a NEW id, because an old catalog id and a current id of the same name mean different things.
- [ ] This task edits nothing under `canonical/` — `git diff --name-only` over `canonical/` is empty for its commit.
- [ ] All section-6 quality gates pass
