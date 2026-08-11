# task-002: The sweep obligation in state-fix.md

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

**Source:** work-003-review-subsystem-redesign -> delivery-025

**Depends on:** task-001

**Scope:**
- `canonical/skills/aid-execute/references/state-fix.md`: the class-sweep step written as a step with an output, not as advice
- The record's home: the fixer writes the phrase and every site into the task `STATE.md` `notes` field, which `writeback-state.sh` already writes
- The phrase rule: it must be a **substring of the text the fix changed**

**Acceptance Criteria:**
- [ ] `state-fix.md` states that the fixer runs `class-sweep.sh` and **records its output in the task `STATE.md` `notes` field**, and that a fix is **not complete until it has**
- [ ] **No ledger write is involved.** `SPEC.md § 5` records that an earlier draft routed the output into the reconciled row's `Evidence` and that the `writeback-ledger.sh` mode, schema extension and `RECONCILE` step it needed were all deleted
- [ ] The phrase is specified as a substring of the correction, **not** as something derived from the ledger row -- an `Evidence` cell commonly quotes several strings, so *"the string the row quotes"* names nothing
- [ ] A deletion sweeps like a correction: if the corrected claim was restated elsewhere, the restatement goes too
- [ ] No new artifact is introduced -- which is what `STATE.md` Q29 requires
- [ ] All section-6 quality gates pass
