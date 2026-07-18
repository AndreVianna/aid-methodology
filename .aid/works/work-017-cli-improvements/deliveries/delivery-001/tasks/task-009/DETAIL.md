# task-009: Pipeline + task rename UI

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

**Depends on:** task-004, task-006, task-008

**Scope:**
- Add the write-gated rename controls to `home.html` -- an inline pencil for the pipeline title (`pipeline.rename`) and for the task name (`task.rename`) -- and switch the task label precedence to `display_name -> short_name -> task_id`, with the truthful re-fetch/re-render on success.
- Pipeline rename (FR-PL1): add a small inline pencil affordance next to `#overview-title` in the drilled-in work header (`renderWorkHeader`, `home.html:1922-1939`; card `<h3>` render at 1490-1503). Click reveals a text input prefilled with `work.title` (empty when unset); Save -> `POST /r/<id>/api/op {op:"pipeline.rename", target:{work_id}, args:{value}}`; Cancel restores. On `ok`, re-fetch `/r/<id>/api/model` -- the existing title/de-slug fallback code then renders the new title (or the folder slug when cleared). The display switch + fallback RENDERING already exist, so this task adds only the edit control (which posts an empty `args.value` when the title is cleared). The server-side empty-value -> `*(pending)*` substitution that makes an empty clear resolve to `title None` -> slug fallback is NOT built here: it is owned by task-008's finalized `pipeline.rename` argv-builder (this task's dependency). AC2 for the pipeline half is therefore satisfied by existing render code plus task-008's substitution, not by this task alone.
- Task rename (FR-T1): add the same pencil affordance next to the task name in the task drill view (`renderTaskView`, `home.html:2939-2942`; card fallback at 2636-2640) prefilled with the current display value; Save -> `POST /r/<id>/api/op {op:"task.rename", target:{work_id, delivery_id?, task_id}, args:{value}}`; on `ok`, re-fetch `/r/<id>/api/model` and re-render. Change the label precedence to `task.display_name || task.short_name || task.task_id` at BOTH render sites, in lockstep with the reader emitting `display_name` (task-008).
- Gate: the pencil affordances render only when `model.write_enabled === true` (reuse the shared `write_enabled` graft introduced in task-006); when false they are not rendered at all (defense-in-depth -- even if forced, the server 403s the op). No new page/route; no `index.html` change.

**Acceptance Criteria:**
- [ ] A write-gated pencil next to `#overview-title` posts `pipeline.rename {target:{work_id}, args:{value}}` (empty `args.value` when the title is cleared); on `ok` the header re-fetches `/r/<id>/api/model` and re-renders the new title, falling back to the folder slug when cleared -- the empty-value -> `*(pending)*` substitution that produces that fallback is task-008's `pipeline.rename` argv-builder (this task's dependency), not built here (AC1/AC2).
- [ ] A write-gated pencil next to the task name posts `task.rename {target:{work_id, delivery_id?, task_id}, args:{value}}`; on `ok` it re-fetches `/r/<id>/api/model` and re-renders.
- [ ] Task label precedence is `display_name -> short_name -> task_id` at both render sites (task card + drill view), in lockstep with task-008's `display_name`.
- [ ] The rename controls render only when `write_enabled === true` (not rendered at all otherwise); there is no new page/route and no `index.html` change (AC8 UI half; AC5 -- display only, non-destructive).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
