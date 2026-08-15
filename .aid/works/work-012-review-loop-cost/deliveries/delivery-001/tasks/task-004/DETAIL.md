# task-004: Match selector grammar and oracle field in the criteria tables

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

**Type:** IMPLEMENT

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-003

**Scope:**
- `.aid/knowledge/authoring-conventions.md` -- **C-5 authorized, enumerated**.
- Add a `Match` column to the type registry beside the retained prose `Selector`, using the three-clause grammar (`path <glob>`, `fm <key> == <value>`, `name-in <file>`) joined by `AND`, plus the reserved `<inexpressible>` token.
- Populate `Match` for the eight expressible rows; `template-payload` carries `path canonical/aid/templates/** AND <inexpressible>` and `template-own` carries its path bound only.
- Add the `oracle:` field to the criteria-by-level table's documented entry shape.
- Record the editing rule that `Selector` and `Match` are one unit and changing either alone is a defect.
- NOT in scope: changing what any selector MEANS, or any other `.aid/knowledge/` edit.

**Acceptance Criteria:**
- [ ] Eight rows gain a **fully expressible** `Match` cell. `template-payload` carries `path canonical/aid/templates/** AND <inexpressible>` and `template-own` carries its path bound alone -- both have a cell, and neither is fully expressible. The path bound is mandatory, not optional: without it the stop rule would fire for any file exhausting the expressible rows, softening a genuine orphan from `VIOLATION` to `UNDECIDED`
- [ ] The prose `Selector` column is retained unchanged for every row
- [ ] The `Selector`/`Match` co-edit rule is stated in the registry section itself, not left as folklore
- [ ] No selector's MEANING changes -- verified by task-005's oracle classifying the current corpus identically before and after
- [ ] No `.aid/knowledge/` file other than `authoring-conventions.md` is touched
- [ ] All REQUIREMENTS.md §6 quality gates pass
