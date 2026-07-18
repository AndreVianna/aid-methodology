# task-033: Execution-control op round-trips + parity

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

**Type:** TEST

**Source:** feature-008-execution-control -> delivery-005

**Depends on:** task-028, task-029, task-030

**Scope:**
- **`pipeline.finish` round-trip (AC-EC1, AC2, AC3).** Assert the op dispatches
  `writeback-state.sh --pipeline --field Lifecycle --value Completed`, persists `lifecycle = Completed`
  to the work `STATE.md` frontmatter (durable; no DERIVED section hand-written), and a post-op
  `/r/<id>/api/model` read shows `Completed`.
- **`task.stop` / `task.resume` round-trips (AC-EC1, AC2).** Assert `task.stop` creates
  `.aid/.control/<work_id>/task-<NNN>.stop` and `task.resume` removes it (via `write-control-signal.sh`),
  that `stop_requested` re-derives `true` then `false` on the next model read, and that re-stop /
  re-resume are idempotent.
- **`stop_requested` twin parity (AC4).** Assert the Python `_ser_task` and Node `_buildTaskModel`
  serializers produce byte-identical output including `stop_requested`, using regenerated golden
  fixtures, under the cross-runtime parity suites.
- **AC6 visibility gate.** Assert the control-gate inputs (`task.status === 'In Progress'` &&
  `write_enabled`) yield a control, and that every OTHER status (`Pending`/`Blocked`/`Done`/`Failed`/
  `Canceled`/`In Review`) yields NONE -- verified against the serialized model flags feeding the UI
  gate (no rerun/start affordance).
- **WT-1 coverage.** Assert the `.stop` file is created relative to `AID_WORK_DIR` (feature-001
  `resolve_work_dir` output) and that the reader stats the same walked-tree path -- never a
  reconstructed `<served-root>/.aid/.control/<work_id>/` path.
- Tests live under the canonical suite (`tests/canonical/`), NOT in the work folder; align with the
  existing dashboard parity + writer test harnesses.

**Acceptance Criteria:**
- [ ] A test exercises `pipeline.finish` end-to-end and asserts `lifecycle = Completed` is persisted
      via `writeback-state.sh` (no DERIVED hand-write) and reflected on the post-op model read
      (AC-EC1, AC2, AC3).
- [ ] A test exercises `task.stop` then `task.resume` and asserts the control file is created then
      removed, `stop_requested` re-derives `true` then `false`, and both ops are idempotent (AC-EC1,
      AC2).
- [ ] A parity test asserts `stop_requested` is byte-identical across the Python and Node reader
      twins with regenerated golden fixtures (AC4).
- [ ] A test asserts the AC6 gate: `task.status === 'In Progress'` && `write_enabled` yields a
      control; every other status (incl. `In Review`) yields none.
- [ ] WT-1 is covered: the signal path is derived from `AID_WORK_DIR` / the walked work dir, not a
      reconstructed served-tree path.
- [ ] All new tests live under `tests/canonical/` (not the work folder) and pass.
- [ ] Tests are deterministic
- [ ] Clean setup/teardown
- [ ] All acceptance criteria from source feature covered
- [ ] All section-6 quality gates pass
