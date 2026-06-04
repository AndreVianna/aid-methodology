# EXECUTE-WAVE Drill-down (per-in-flight-task detail)

> Snapshot-rendering spec for the EXECUTE-WAVE pool — extracted from
> [`state-execute.md`](state-execute.md) `## EXECUTE-WAVE Drill-down` to keep that
> state file navigable. This is the authoritative spec referenced from
> `aid-execute/SKILL.md`.

> **Feature:** task-035 — extends the pool snapshot with per-task detail rows
> for every in-flight task, enabling the user to see agent type, heartbeat state,
> elapsed time, and ETA at a glance without leaving the execution session.
>
> **When to use:** automatically on every sub-unit transition (PD-2 / PD-4) and
> on explicit user "status" request during a long-running pool wait (PD-3).

### Icon Vocabulary (complete set — no glyph replacements)

FR1's existing icons are **reused verbatim**. Task-035 adds only `⊘ blocked`.

| Icon | Meaning |
|------|---------|
| `✓ done` | Task completed and passed review |
| `● running` | Task currently dispatched (EXECUTE → REVIEW cycles in progress) |
| `✗ failed` | Task raised an unresolved Impediment |
| `(queued)` | Task in the ready set, waiting for a pool slot to free |
| `⊘ blocked` | Task downstream of a Failed ancestor; will never be dispatched |

### Snapshot Format — Summary View

Rendered on every sub-unit transition (PD-2 dispatch, PD-4 completion/failure):

```
Wave ∞ (pool) · {K}/{T} done

| Task | Type | Status | Time |
|------|------|--------|------|
| task-001 | IMPLEMENT | ✓ done    | 4m 12s   |
| task-002 | RESEARCH  | ● running | ~3–8 min |
| task-003 | DOCUMENT  | ● running | ~1–3 min |
| task-004 | TEST      | (queued)  | —        |
| task-005 | IMPLEMENT | ⊘ blocked | —        |

Done: {D}  In-flight: {I}  Queued: {Q}  Blocked: {B}  Failed: {F}
```

**Counts summary line** appears at the bottom of every snapshot. Values:
- `Done` — tasks with Status `Done`
- `In-flight` — tasks in the in-flight set (Status `In Progress`)
- `Queued` — tasks in the ready set waiting for a pool slot
- `Blocked` — tasks in the blocked set (Status `Blocked`)
- `Failed` — tasks with Status `Failed`

### Snapshot Format — Drill-down View (per-in-flight-task detail)

Rendered when: (a) any `● running` row is present AND context warrants detail
(long-running pool wait at timer-1 or timer-2 fire), OR (b) user explicitly
requests status during a pool wait.

The drill-down **extends** the summary table — each `● running` task gains a
sub-row with per-agent detail:

```
Wave ∞ (pool) · {K}/{T} done

| Task | Type | Status | Time |
|------|------|--------|------|
| task-001 | IMPLEMENT | ✓ done    | 4m 12s        |
| task-002 | RESEARCH  | ● running | 6m 40s (↑ ~8m)|
|          |           | agent: aid-researcher · heartbeat: RUNNING · elapsed: 6m 40s · ETA: ~8 min |
| task-003 | DOCUMENT  | ● running | 1m 15s (↑ ~3m)|
|          |           | agent: aid-tech-writer · heartbeat: REVIEW · elapsed: 1m 15s · ETA: ~3 min |
| task-004 | TEST      | (queued)  | —             |
| task-005 | IMPLEMENT | ⊘ blocked | —             |

Done: {D}  In-flight: {I}  Queued: {Q}  Blocked: {B}  Failed: {F}
```

**Per-task drill-down row fields:**

| Field | Source | Format |
|-------|--------|--------|
| `agent` | Executor role dispatched for this task (from Agent Selection table) | e.g., `aid-developer`, `aid-researcher` |
| `heartbeat` | Last state written to `.aid/.heartbeat/<executor>-<ts>.txt` | `EXECUTE` / `REVIEW` / `FIX` / `DONE` / `STALE` / `unknown` |
| `elapsed` | Wall time since PD-2 dispatched this task | `Xm Ys` (minutes + seconds) |
| `ETA` | Rough band from `canonical/templates/rough-time-hints.md` for the executor + task type | `~LOW–HIGH min` |

**Heartbeat states:**
- `EXECUTE` — sub-agent is currently running the executor
- `REVIEW` — sub-agent is running the reviewer
- `FIX` — sub-agent is applying fixes
- `DONE` — sub-agent reported done (race with completion notification)
- `STALE` — heartbeat file exists but last write was > 2× HEARTBEAT_INTERVAL ago
- `unknown` — heartbeat file absent or unreadable

### Re-render Trigger Rules

Render a fresh snapshot block on these events — **never** render more often
than once per coalescing window (see below):

| Event | Trigger type | Snapshot type |
|-------|--------------|---------------|
| Task moves from ready set → in-flight (PD-2 dispatch) | Sub-unit transition | Summary |
| Task completes successfully (PD-4 DONE path) | Sub-unit transition | Summary |
| Task fails with Impediment (PD-4 FAILED path) | Sub-unit transition | Summary |
| Descendant marked `⊘ blocked` (PD-4 failure cascade) | Sub-unit transition | Summary |
| L2 timer-1 fires (ETA/2 elapsed for longest in-flight task) | Long-run check-in | Drill-down |
| L2 timer-2 fires (ETA elapsed for longest in-flight task) | Long-run check-in | Drill-down |
| User types "status" during pool wait (PD-3) | On-demand | Drill-down |

**1-second coalescing:** when multiple sub-unit transitions occur within the
same second (e.g., pool fills 3 tasks simultaneously on startup), emit a single
merged snapshot after all transitions settle. Do not emit one snapshot per event.

**Drill-down on timer fire:** when an L2 timer fires during PD-3 (waiting for
completion), read all in-flight heartbeat files and emit the drill-down view.
If a heartbeat file is absent or unreadable, use `unknown` for that task's
heartbeat field — do not fail the render.

### Failure Tolerance

> **Invariant:** snapshot rendering must NEVER block or abort task execution.

Apply these failure-tolerance rules unconditionally:

- **Missing data:** if a task row is missing Type, Status, or Time information,
  render the available fields and leave the unknown field as `—`.
- **Malformed heartbeat file:** treat as `unknown` heartbeat state; do not parse
  further; do not raise an error.
- **Stale heartbeat file** (last write > 2× HEARTBEAT_INTERVAL ago): render
  heartbeat state as `STALE` with the last-known state appended in parentheses,
  e.g., `STALE (REVIEW)`. Continue rendering.
- **Render exception** (any unexpected error during snapshot construction):
  swallow the error silently. Print nothing for this snapshot event. Execution
  continues unaffected. Log the error to `STATE.md ## Calibration Log` as
  `| YYYY-MM-DD | snapshot-render | <error-one-line> | — | — | swallowed |`
  only if that log section already exists (do not create it solely for this).
- **Empty in-flight set:** summary-only view; skip the per-task drill-down rows.

### Snapshot Rendering — Decision Tree

```
On every snapshot event:
  try:
    1. Read pool sets (in-flight, ready, blocked) from current in-memory state.
    2. Read task metadata (id, type) from task files.
    3. For each in-flight task:
       a. Compute elapsed = now - dispatch_time.
       b. Read heartbeat file → parse state; if absent/unreadable → "unknown".
       c. Read ETA band from rough-time-hints.md for (executor, task-type).
    4. Render summary table rows (all tasks, all statuses).
    5. Append counts summary line.
    6. If event = drill-down trigger (timer fire or on-demand):
       append per-task detail sub-rows for each ● running task.
    7. Emit rendered block.
  except any error:
    swallow silently; continue execution.
```
