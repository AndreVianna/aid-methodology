# task-030: Finish + Stop/Resume UI

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

**Depends on:** task-029, task-004 (delivery-001)

**Scope:**
- **Pipeline Finish (FR-PL2).** Add a "Finish" action to the work / pipeline card (the same card
  carrying `makeLifecycleBadge`, `home.html` line ~2651). Render it ONLY when
  `work.lifecycle === 'Running'` AND `model.write_enabled === true`. It posts
  `{op:"pipeline.finish", target:{work_id}}`. Because Finish is terminal, use a LIGHTWEIGHT confirm
  ("Finish this pipeline? This marks it Completed and stops any running work.") -- a plain confirm,
  distinct from FR-PL3 Delete's strong destructive guard (feature-009). On success, re-fetch
  `/r/<id>/api/model`; the card then shows the Done lifecycle badge (`LIFECYCLE_MAP['Completed']`,
  line ~2656).
- **Task Stop/Resume (FR-T3, AC6).** Add a single toggle control to the task chip (`makeTaskChip`,
  `home.html` line ~2590) AND mirror it on the task drill view (SEAM-2 route
  `#/work/<id>/task/<tid>`, line ~2600) for discoverability. **AC6 visibility gate:** render the
  control IFF `task.status === 'In Progress'` AND `write_enabled`. For `Pending`, `Blocked`, `Done`,
  `Failed`, `Canceled`, AND `In Review` tasks, render NO control (no rerun/start affordance
  anywhere). `In Review` is deliberately excluded (its executor has already finished; a reviewer is
  what runs), narrowing the gate below the chip's existing "active" set on purpose.
- **Label / action flip on `task.stop_requested`:** `false` ⇒ "Stop" -> posts `task.stop`; `true` ⇒
  "Resume" -> posts `task.resume`. A paused (`stop_requested === true`) chip ALSO shows a small
  decorative "paused" pill (a glyph badge in the `makeTaskStatusBadge` family, line ~2673) so the
  state is legible at a glance WITHOUT changing the status badge itself. On op success the client
  re-fetches and re-derives `stop_requested` from disk (AC2).
- **Defense-in-depth gating.** When `write_enabled === false`, render no Finish/Stop/Resume control
  at all; the server independently refuses the op (403 `read-only`), so a hand-crafted request under
  `--remote` without `--allow-writes` still fails closed.

**Acceptance Criteria:**
- [ ] The Finish control renders ONLY when `work.lifecycle === 'Running'` && `write_enabled`; it
      posts `{op:"pipeline.finish", target:{work_id}}` behind a lightweight confirm; on success the
      client re-fetches `/r/<id>/api/model` and the card shows the `Completed` (Done) lifecycle badge.
- [ ] The Stop/Resume control renders IFF `task.status === 'In Progress'` && `write_enabled`, on BOTH
      the task chip and the task drill view; it renders NO control for `Pending`/`Blocked`/`Done`/
      `Failed`/`Canceled`/`In Review` (AC6 -- no rerun/start affordance).
- [ ] The label/action flips on `stop_requested`: `false` -> "Stop" posts `task.stop`; `true` ->
      "Resume" posts `task.resume`; a paused chip shows the decorative "paused" pill without altering
      the status badge.
- [ ] After every op the client re-fetches `/r/<id>/api/model` and re-renders from disk (Finish ->
      `Completed`; Stop/Resume -> re-derived `stop_requested`) with no drift (AC2).
- [ ] When `write_enabled === false`, no Finish/Stop/Resume control is rendered (defense-in-depth
      against the server's own 403).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
