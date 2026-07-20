# task-029: Derived stop_requested reader twin + task.stop/resume ops

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

**Source:** feature-008-execution-control -> delivery-005

**Depends on:** task-028, task-004 (delivery-001)

**Scope:**
- Add an additive DERIVED boolean `stop_requested` to `TaskModel` (`dashboard/reader/models.py`
  line ~233, after `lane`), computed at READ time by a filesystem `stat` of
  `<walked-work-dir>/../../.control/<work_id>/task-<NNN>.stop` -- the `.aid/.control/` sibling
  WITHIN the same worktree copy the reader is already walking (worktree-aware, WT-1; never a
  reconstructed `<served-root>/.aid/.control/<work_id>/`). A missing control directory ⇒ all tasks
  `stop_requested=false` (fail-safe, never throws -- mirrors the reader's forward-compat posture).
- Add the field to the serializer `_ser_task` (`dashboard/server/server.py` line ~604) AND its Node
  twin `_buildTaskModel` (`dashboard/server/reader.mjs` line ~4347). Both twins perform the
  IDENTICAL `stat` (no `STATE.md` parser change), so DM byte-parity (AC4) is preserved by
  construction. `stop_requested` is NEVER parsed from or written to `STATE.md`.
- Regenerate the golden twin-parity fixtures for the affected suites in lockstep. No `schema_version`
  bump -- `stop_requested` is purely additive (feature-001 `write_enabled` / DM-A3 / RC-2 no-bump
  precedent; DM-1 stays 3).
- Register two new `OP_TABLE` rows in BOTH server twins (`server.py` + `server.mjs`):
  `task.stop` -> `write-control-signal.sh --task-id <NNN> --action stop`;
  `task.resume` -> `write-control-signal.sh --task-id <NNN> --action resume`.
  Both are per-repo and pipeline-scoped: require `target.work_id` (validated `^work-[0-9]+` +
  dir-exists per feature-001) and `target.task_id` (`^\d{1,3}$`); `args` is empty (`{}`) -- the
  action is encoded in the op name, so no lifecycle or free string is ever forwarded. Env
  `AID_WORK_DIR` = feature-001 `resolve_work_dir(served_root, work_id)` output (worktree-aware, WT-1).
- Reuse feature-001's router, `write_enabled` gate, and child-process dispatch UNCHANGED (no new
  endpoint / routing branch). Map the writer's exit codes to HTTP exactly as feature-001's table
  does (`4/5 -> 422`, `2 -> 409`, other -> 500).

**Acceptance Criteria:**
- [ ] `stop_requested` is present on `TaskModel` and on both serializers (`_ser_task` +
      `_buildTaskModel`), each computed by an IDENTICAL filesystem `stat` of the control file
      derived relative to the walked work dir (WT-1); a missing control dir yields `false` with no
      throw.
- [ ] No `STATE.md` parser change is made; `stop_requested` is never parsed from or written to
      `STATE.md`.
- [ ] The Python and Node twins produce byte-identical serialized `TaskModel` output including
      `stop_requested`; regenerated golden fixtures pass the cross-runtime parity suites (AC4).
- [ ] `schema_version` is unchanged (DM-1 = 3).
- [ ] `task.stop` and `task.resume` rows exist in BOTH server twins, per-repo + pipeline-scoped with
      the stated `work_id`/`task_id` validation and empty `args`, each declaring writer
      `write-control-signal.sh` with the exact `--task-id <NNN> --action stop|resume` argv, dispatched
      with `AID_WORK_DIR` = `resolve_work_dir` output.
- [ ] The exit-code -> HTTP mapping matches feature-001's table (`4/5 -> 422`, `2 -> 409`, other -> 500);
      no new endpoint or routing branch is introduced.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
