# task-004: Miss attribution

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

**Depends on:** task-002, task-003

**Scope:**
- The attribution element of the report: for each **missed** seeded defect, the coverage worklist item that should have caught it
- The lookup that makes it possible: a coverage row whose unit is the **claim**, which is what `FR-D10` specifies and `delivery-026` ships
- **Why `task-003` is a dependency even though no data flows from it:** both tasks modify
  `canonical/aid/scripts/review/recall-measure.sh`, and the ready set is computed from `Depends on`
  alone with no wave barrier at runtime (`aid-execute/references/state-execute.md`, PD-1). Without the
  edge both could be dispatched to concurrent agents editing one file. Do not remove it as redundant
- Reported **alongside** the miss, not folded into either `FR-H2` term -- the two lane terms stay exactly as `task-002` produces them

**Acceptance Criteria:**
- [ ] For every missed seeded defect, the report names the coverage worklist item that should have caught it -- which is `delivery-027`'s gate criterion 5, and it is discharged here rather than only asserted downstream
- [ ] A miss whose worklist item cannot be identified says so **explicitly**, naming the defect and that no item covers it. Silence would make an unattributable miss indistinguishable from an attributed one, which is the whole diagnostic value at stake
- [ ] Neither `FR-H2` term changes shape: the per-rule-set and OVERALL lines still carry exactly the two terms, and attribution is additional output rather than a third term
- [ ] `FR-F6` holds -- attribution produces no grade, no score and no threshold
- [ ] The task is **executable only after `delivery-026` lands**, and says so rather than silently assuming per-claim coverage rows exist. `SPEC.md § 3` states *"attribution needs `FR-D10`"*; this task is where that dependency becomes concrete
- [ ] All section-6 quality gates pass
