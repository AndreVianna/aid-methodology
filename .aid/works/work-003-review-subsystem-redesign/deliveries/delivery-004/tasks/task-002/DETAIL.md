# task-002: Per-class rule sets

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

**Source:** work-003-review-subsystem-redesign -> delivery-004

**Depends on:** task-001

**Scope:**
- One rule-set file per artifact class
- The `SUMMARY` class carrying **content-truth rows**, not only Presentation-family rows, per feature-007's amendment
- The `Definition` family file, authored **without** FR-G4's count-claim row -- delivery-017 adds it

**Acceptance Criteria:**
- [ ] Every rule row carries an evidence anchor, a severity anchor and a named tag
- [ ] Every rule's `Criterion` resolves: the cited file exists and the quoted anchor is greppable in it
- [ ] `review-rubrics/summary.md` carries content-truth rows
- [ ] All section-6 quality gates pass
