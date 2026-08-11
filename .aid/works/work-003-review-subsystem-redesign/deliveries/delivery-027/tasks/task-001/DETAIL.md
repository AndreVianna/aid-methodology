# task-001: The Lane B join

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

**Source:** work-003-review-subsystem-redesign -> delivery-027

**Depends on:** -- (none)

**Scope:**
- The join at the heart of `canonical/aid/scripts/review/recall-measure.sh`: reported ledger `(Doc, Rule)` pairs against catalogue rows where `enforcement = judgment`
- The denominator rule: **seeded** judgment rows only

**Acceptance Criteria:**
- [ ] The join key is `(Doc, Rule)`, matching `reviewer-ledger-schema.md § Attempts and reconciliation`
- [ ] A catalogue `fixture` value joins a ledger `Doc` with **no path rewriting** -- which is what `SPEC.md § 2` means by byte-identical, and the reason the column is repo-root-relative
- [ ] An exempt row (`fixture = --`) is in no denominator: it has no defect to find
- [ ] A `script` row is never in a Lane B denominator -- Lane A decides it and no agent behaviour can move it
- [ ] The join is computed from the catalogue and the ledger and from nothing else, so the figure is reproducible from two recorded files
- [ ] All section-6 quality gates pass
