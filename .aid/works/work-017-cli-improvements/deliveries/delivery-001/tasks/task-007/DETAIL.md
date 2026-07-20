# task-007: writeback-state.sh Name->display_name task-field extension

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Source:** feature-005-display-rename -> delivery-001

**Depends on:** task-003

**Scope:**
- Extend the single writer `writeback-state.sh` with a `Name` -> `display_name` task field in BOTH layouts (nested frontmatter via `fm_key` indirection; flat `### Tasks lifecycle` table via a col-7 awk), and seed the flat-table `Name` header/separator column in `work-state-template.md` so authored tables match the data the writer emits. The reader/serializer + `task.rename` op row are task-008; the rename UI is task-009.
- Nested/full layout (`mode_field`): add `name` to the closed task-field allowlist (`case "$field_lower" in state|review|elapsed|notes)`, `writeback-state.sh:745-748`) AND introduce the `fm_key` indirection that `mode_gate_field` already uses (`field_lower` -> `fm_key`, e.g. `tier|grade|timestamp -> gate_*`, L1116-1123): map `name -> display_name`, route BOTH the write (`wb_set_frontmatter ... "$fm_key"`, L790) and the verify (`wb_frontmatter_verify ... "$fm_key"`, L792) through the mapped key, and update the "field_lower IS the frontmatter key verbatim, no name mapping needed" comment (L785-787) to record the `name` exception. (Writing a literal `name:` key -- as adding `name` to the allowlist alone would -- is a silent AC1/AC2 failure: no reader reads it; the reader key is `display_name`, `models.py:253`.)
- Flat/Lite layout (`write_task_field_flat`): add `name) col_idx=7` to the `case "$field_lower"` col map (L830-836); extend the `new_row()` / row-rewrite awk that currently emits columns 3-6 (L853-924) to also emit trailing column 7, so the flat path writes the `Name` DATA cell. The awk prints the header row (L899) and the separator row (L894) byte-verbatim (no column-count reconciliation), so it does NOT create the header column -- that ships in the template (below).
- `work-state-template.md` seed `### Tasks lifecycle` header AND separator (currently the 5-column `| Task | State | Review | Elapsed | Notes |` / `|------|...|`, `work-state-template.md:214-216`): add the trailing `Name` column to BOTH rows so a newly seeded flat/Lite work has a 6-column AUTHORED header/separator matching the data rows the extended `write_task_field_flat` emits. (This is the structural Migration follow-up, required to avoid a permanently header/data-mismatched authored table -- not doc polish.)
- The existing `|`/newline rejection (`mode_field`, L733-740) is unchanged; the change is single-sourced in `canonical/aid/scripts/execute/writeback-state.sh` and propagates via the render + co-vendor path established in task-003 (no new `dashboard/MANIFEST` edit -- the writer is already listed).

**Acceptance Criteria:**
- [ ] Nested layout: `writeback-state.sh --task-id <t> --field Name --value <v>` writes the `display_name` frontmatter key (NOT a literal `name:` key) via `fm_key` indirection, and the verify checks `display_name`; the "no name mapping needed" comment is updated to record the `name` exception.
- [ ] Flat/Lite layout: the same call writes the trailing col-7 `Name` DATA cell (`col_idx=7`); `new_row()` / the row-rewrite awk emits column 7; the header + separator rows are printed byte-verbatim (no column-count reconciliation).
- [ ] `work-state-template.md`'s `### Tasks lifecycle` header AND separator gain the trailing `Name` column (a 6-column AUTHORED table matching the emitted data rows).
- [ ] `|`/newline in `--value` is still rejected (exit 4); the write remains a surgical single-writer STATE edit (C1) byte-indistinguishable from an agent edit, and `DETAIL.md` is untouched (AC5).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
