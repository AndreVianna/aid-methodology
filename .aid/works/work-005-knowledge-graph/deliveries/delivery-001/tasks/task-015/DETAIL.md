# task-015: Conform the accessible table view to feature-009's D1-D4

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-015/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** IMPLEMENT

**Source:** feature-009-accessible-table-view -> delivery-001 (Wave 2)

**Depends on:** task-013

**Scope:**
- **PROVISIONAL — size unknown until a conformance read.**
  `canonical/aid/templates/knowledge-graph/graph-table.js` ships at ~44 KB and may already satisfy
  all four design decisions, but nothing on disk mounts it into anything, so it has never been
  exercised. The first step is to read it against D1-D4 and record what conforms; if all four hold,
  this task collapses into task-016 and its number is retired rather than padded with invented work.
- Conform to: D1 (`RowOrder.order` is a **permutation**, never a selection), D2 (the sort contract's
  value space and why the order is **total**), D3 (ten columns, matching the file), D4 (the
  unlisted-nodes set derived with **no new `ViewModel` field**).
- Mount into task-013's shell as the table half — first and unconditional.
- **Depends on task-013 because this is BLUEPRINT edge 5** — feature-007 before feature-009: the
  table mounts into its shell and consumes its view model.

**Acceptance Criteria:**
- [ ] The conformance read against D1-D4 is recorded, decision by decision, before any edit is made
- [ ] `RowOrder.order` is a permutation of the row set — a projection that drops a row is a defect,
      not a filter
- [ ] The sort order is **total**: no two distinct rows compare equal under any admitted `sort` value
- [ ] Ten columns, matching `relationships.md` exactly — same names, same order
- [ ] The unlisted-nodes set is derived; **no new `ViewModel` field is introduced** (D4)
- [ ] The table renders and is fully usable with **no drawing context at all** — it is the conforming
      alternate version NFR-2 rests AA on
- [ ] Nothing here re-derives membership, emphasis, grouping or folding; all of it is read from
      `project()`'s output (NFR-3)
- [ ] All section-6 quality gates pass
