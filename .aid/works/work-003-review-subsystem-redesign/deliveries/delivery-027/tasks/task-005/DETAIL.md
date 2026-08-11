# task-005: AC-16 and the FR-F6 boundary

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-003-review-subsystem-redesign -> delivery-027

**Depends on:** task-004

**Scope:**
- The suite asserting `AC-16` over the in-domain set, and asserting that no second grading arithmetic exists
- The attribution check: for each missed seeded defect the report names the coverage worklist item that should have caught it

**Acceptance Criteria:**
- [ ] **Every in-domain rule set reports a figure**, with both terms present and at most one of them `--`. The domain is the predicate `SPEC.md § 2b` defines
- [ ] **No rule set reports zero fixtures**, joined against the catalogue: an in-domain rule set with no fixture **fails** rather than reporting an empty pass
- [ ] The figure describes the merged `/aid-review` that delivery-022 ships, not a skill being replaced
- [ ] A miss is attributable: the report names the coverage worklist item for each missed defect, which is what delivery-026 makes possible
- [ ] `FR-F6` holds: the recall figure is reported **alongside** the grade and never folded into it, and no override channel exists. Asserted by checking the script produces no letter grade at all
- [ ] All section-6 quality gates pass
