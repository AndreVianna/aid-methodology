# task-010: Task Notes card + task.set-notes handler

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

**Source:** feature-006-task-notes -> delivery-001

**Depends on:** task-004, task-006

**Scope:**
- Finalize the concrete `task.set-notes` handler (arg-schema + argv-builder, both twins, empty -> `--`) on the OP_TABLE row feature-001 seeded, and add the write-gated Notes card + inline editor to the `home.html` task drill view. This feature introduces NO new writer, endpoint, gate, envelope key, or reader/parser/serializer change -- all inherited from feature-001.
- `task.set-notes` arg-schema (added identically to both twins): scope per-repo (pipeline-scoped -- `target.work_id` required, resolved via `resolve_work_dir(repo, work_id)` -> 404 if no worktree holds it, WT-1). `target.task_id` `^task-\d{1,3}$` or bare `\d{1,3}$`, normalized to the bare numeric id. `target.delivery_id` optional `^\d{1,3}$` (client sends the rendered `TaskModel.delivery`; omitted -> the writer resolves it). `args.value` string <= 1 KiB, rejects `|`/newline (422 `invalid-value`, mirroring `mode_field` L733/738). An empty string is accepted and mapped to the `--` null sentinel.
- Argv-builder (registered by this task): `value := (args.value == "") ? "--" : args.value`; `argv := [<vendored>/writeback-state.sh, --task-id <numeric>, (--delivery-id <numeric>)?, --field Notes, --value value]`; env `AID_STATE_FILE=<work-dir>/STATE.md`, `AID_WORK_DIR=<work-dir>`, where `<work-dir> = resolve_work_dir(repo, work_id)` (worktree-aware, WT-1 -- never a reconstructed `<repo>/.aid/works/<work_id>` path). No shell string; no path taken from the body.
- UI (`renderTaskView`, `home.html` line 2877): insert a "TASK NOTES" card immediately after the drill-view header (`container.appendChild(headerDiv)`, line 2956) and before the `if (!detail)` first-tick early-return (line 2962), reusing the existing `card` + `kicker` block styling and the `btn-ghost` control. Read state shows `task.notes` or a dimmed "No notes." (`var(--text-dim)`). Edit affordance (only when `model.write_enabled === true`): an "Edit" `btn-ghost` reveals a single-line `<input type="text">` seeded with the current value + Save/Cancel; a client-side `|`/newline pre-check flags a bad value before the request. Save calls a new thin `postOp(op, target, args)` helper (`fetch('./api/op', {method:'POST', headers:{'Content-Type':'application/json'}, body:...})` modeled on `doFetch`, line 1033); buttons disable in-flight. On `{ok:true}` call `doFetch()` immediately (respecting the `fetchPending` guard, line 1034) -> `onSuccess` -> `renderModel` -> `renderTaskView` re-renders the card from disk (AC2, no optimistic mutation). On failure show an inline error (the `detail` string) via the `callout warn` style (line 2891); the input keeps the user's text. Reuse the shared `write_enabled` graft (feature-002/task-006).

**Acceptance Criteria:**
- [ ] The `task.set-notes` arg-schema + argv-builder are added identically to both twins: `task_id` accepts the prefixed or bare form and normalizes to the numeric id; `value` <= 1 KiB rejects `|`/newline (422); an empty `value` -> the `--` sentinel; env `AID_STATE_FILE`/`AID_WORK_DIR` from `resolve_work_dir` (WT-1).
- [ ] The write goes through `writeback-state.sh --field Notes` (single writer, C1); the server has no notes-writing code of its own, and no DERIVED view is written (AC3).
- [ ] The task drill view renders a write-gated "TASK NOTES" card (read state shows `task.notes` or a dimmed empty state); the Edit affordance appears only when `write_enabled === true`.
- [ ] Save posts `task.set-notes` via `postOp`; on `ok` an immediate `doFetch()` re-renders the card from the fresh on-disk model with no drift (AC2); on failure an inline error shows and the input is preserved.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
