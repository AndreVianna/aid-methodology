# task-008: TaskModel.display_name reader twins + task.rename & pipeline.rename op argv-builders

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

**Depends on:** task-003, task-004, task-007

**Scope:**
- Surface the mutable `display_name` cell task-007 writes -- add `TaskModel.display_name` to both reader twins (nested frontmatter + flat `### Tasks lifecycle` column + serializers) -- register the concrete `task.rename` op (arg-schema + argv-builder with empty -> `--` sentinel) on the OP_TABLE, AND finalize the pre-seeded `pipeline.rename` argv-builder (arg-schema + empty -> `*(pending)*` sentinel). Both feature-005 server-side rename argv-builders are owned here (feature-005 SPEC §Layers component 1 -- "this feature supplies two OP_TABLE rows ... and their argv-builders/arg-schemas"); the rename UI (client controls) is task-009.
- Models: add `TaskModel.display_name: Optional[str] = None` (`models.py`, beside `short_name` L253).
- Read nested: from `parse_task_state_md` (per-task STATE frontmatter, `parsers.py:1354`), joined into `TaskModel` at `reader.py:1265/1290-1293`.
- Read flat: `parse_tasks_lifecycle_md` (`parsers.py:1712`, currently `_col(0..4)` L1765-1773) gains the trailing `Name` column as `_col(5)`; joined at `reader.py:983/1036-1039`. A legacy 5-column row yields `_col(5) == None -> display_name None -> fallback`.
- Node twin mirrors each site: flat `parseTasksLifecycleMd` (`reader.mjs:3486/3535`) gains the `Name` column; the flat join (`reader.mjs:3699/3749-3765`); task serialize (`reader.mjs:4357-4358`).
- Serializers: emit `display_name` beside `notes`/`short_name` in `server.py:613-614` and `reader.mjs:4357-4358`, both twins in lockstep; golden fixtures regenerate together. No `schema_version` bump (feature-001 owns the envelope version).
- `task.rename` OP_TABLE row (feature-001 listed this op as owned by feature-005): writer `writeback-state.sh --task-id <t> [--delivery-id <d>] --field Name --value <v>`, env `AID_STATE_FILE=<resolved-work-dir>/STATE.md` + `AID_WORK_DIR=<resolved-work-dir>` from `resolve_work_dir` (WT-1). Arg-schema (both twins): `target.work_id` required (`^work-[0-9]+`); `target.task_id` required (`^\d{1,3}$`, or prefixed `task-NNN` normalized to bare numeric); `target.delivery_id` optional (`^\d{1,3}$`, forwarded to `--delivery-id` when the model's `TaskModel.delivery` is set, omitted for flat); `args.value` single-line, length-capped, rejects `\n`/`|`. Empty `args.value` -> substitute the `--` null sentinel before spawn (`writeback-state.sh` dies exit 5 on a literally empty `--value`, L403).
- `pipeline.rename` argv-builder (FINALIZE the row feature-001 pre-seeded in task-004 -- the writer + scope + default map already exist; this task supplies the concrete arg-schema + argv-builder): writer `write-requirement.sh --field Name --value <v>` (built by task-003), env `AID_REQUIREMENTS_FILE=<resolved-work-dir>/REQUIREMENTS.md` from `resolve_work_dir` (WT-1). Arg-schema (both twins): `target.work_id` required (`^work-[0-9]+`), no `task_id`/`delivery_id`; `args.value` single-line, length-capped, rejects `\n`/`|`. Empty `args.value` -> substitute the `*(pending)*` null sentinel before spawn -- `write-requirement.sh` needs a non-empty bullet, and `*(pending)*` is the value the reader's `_re_name` maps to `title None` (`parsers.py:664/691`) -> `home.html` de-slug fallback. This is the feature-005 SPEC §Feature Flow / §API Contracts empty-clear behavior (AC2), symmetric with the `task.rename` `--` sentinel above; task-009 supplies only the client control that posts an empty `args.value` when the title is cleared, and depends on this argv-builder.

**Acceptance Criteria:**
- [ ] `TaskModel.display_name` (Optional, default `None`) is read from the nested per-task STATE frontmatter and from the flat `### Tasks lifecycle` trailing `Name` column (`_col(5)`), and emitted in the task serialization; a legacy 5-column row yields `display_name None`.
- [ ] The parser/serializer change is applied identically to `parsers.py`/`reader.py` and `reader.mjs` (flat parse, join, and serialize sites), fixtures regenerated in lockstep, parity suites green (AC4).
- [ ] The `task.rename` row is registered on the OP_TABLE in both twins: writer `writeback-state.sh --task-id ... [--delivery-id ...] --field Name --value <v>`, env from `resolve_work_dir` (WT-1).
- [ ] The `task.rename` arg-schema validates `work_id`/`task_id`/`delivery_id`/`value` (single-line, no `|`/newline), and the argv-builder substitutes the `--` null sentinel for an empty `args.value` (so an empty clear never hits `writeback-state.sh`'s exit-5 empty-value die).
- [ ] The pre-seeded `pipeline.rename` argv-builder is finalized here on the OP_TABLE in both twins: writer `write-requirement.sh --field Name --value <v>` (env `AID_REQUIREMENTS_FILE` from `resolve_work_dir`, WT-1); arg-schema validates `work_id`/`value` (single-line, no `|`/newline); the argv-builder substitutes the `*(pending)*` null sentinel for an empty `args.value` (so an empty clear renders `title None` -> folder-slug fallback, AC2), symmetric with the `task.rename` `--` sentinel.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
