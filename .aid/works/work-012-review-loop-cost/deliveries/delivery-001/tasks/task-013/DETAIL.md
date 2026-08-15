# task-013: Scoping guards: seeded-defect verification

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml.

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

**Type:** TEST

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-009, task-010, task-011, task-012

**Scope:**
- A canonical suite proving the three guards actually hold, using seeded defects rather than inspection.
- Fixtures build their own corpora and ledgers.

**Acceptance Criteria:**
- [ ] AC-2: a defect seeded in a section that REFERENCES a changed section is found by a scoped cycle
- [ ] AC-3: a defect seeded outside the scoped surface, and missed by a scoped cycle, is caught by the final full pass
- [ ] AC-4: a `Fixed` row that regresses outside the scoped surface is still demoted to `Recurred`, including for a `Doc: --` row
- [ ] AC-13: across a phase whose gate runs 2+ cycles over more than one feature, the contradiction pass executes exactly ONCE, and a contradiction spanning two features is still caught -- both halves asserted
- [ ] Tests are deterministic with clean setup/teardown
- [ ] All REQUIREMENTS.md §6 quality gates pass
