# State: EXECUTE

Task work is dispatched to the type-appropriate executor agent to produce deliverables; state is entered when no prior execution exists or when resuming an in-progress task.

## Task Types

| Type | What the agent does | What the reviewer checks |
|------|--------------------|-----------------------|
| **RESEARCH** | Investigate, compare options, document findings | Completeness, bias, sources cited, actionable conclusion |
| **DESIGN** | Mockups, wireframes, UI prototypes, interaction flows | Adherence to requirements, UX consistency, design system |
| **IMPLEMENT** | Write code + unit tests | Code quality, conventions, test coverage, build health |
| **TEST** | Write integration/E2E/UI/load tests, run them, report results | Coverage vs acceptance criteria, test quality, environment |
| **DOCUMENT** | Docs, diagrams, ADRs, API docs, runbooks | Accuracy vs KB and SPECs, completeness, audience clarity |
| **MIGRATE** | Data migration scripts, schema changes, data transformation | Reversibility, data integrity, rollback plan, idempotency |
| **REFACTOR** | Restructure code without changing behavior | Behavior preserved, tests still pass, measurable improvement |
| **CONFIGURE** | Config files, environment setup, CI/CD, infra-as-code | Correctness, security, idempotency, documentation |

## Agent Selection

Each task type dispatches a specific executor agent. The reviewer is always the same role (`reviewer`), separate from the executor for clean context. Specialist consults are dispatched in addition to the reviewer when the task type warrants it.

| Task Type | Executor | Reviewer | Specialist consult |
|-----------|----------|----------|---------------------|
| RESEARCH | `researcher` | `reviewer` | — |
| DESIGN | `ux-designer` | `reviewer` | — |
| IMPLEMENT | `developer` | `reviewer` | `security` if task touches auth/PII; `performance` if hot path |
| TEST | `developer` | `reviewer` | `performance` for load/integration tests |
| DOCUMENT | `tech-writer` | `reviewer` | — |
| MIGRATE | `data-engineer` | `reviewer` | `data-engineer` review (different instance than executor) |
| REFACTOR | `developer` | `reviewer` | — |
| CONFIGURE | `devops` | `reviewer` | `security` if config touches secrets/auth |

**Reviewer ≠ executor invariant.** Even when a task type uses the same agent role for both execution and consult-review (MIGRATE), they run as separate dispatches with clean context. The reviewer never sees the executor's working notes.

**Model override per task type.** Each executor has a default tier from its agent definition (Developer is Medium tier, etc.). For genuinely complex work — REFACTOR over a tangled module, MIGRATE with edge cases, IMPLEMENT touching critical security paths — the orchestrator may dispatch with an explicit higher-tier model in the Task tool's `model` parameter. This is a runtime decision per dispatch, not a skill configuration.

**Mechanical sub-tasks.** Executors may delegate mechanical work (extraction, file enumeration, template filling) to `simple-extractor`, `simple-glob`, `simple-formatter` — Small-tier utility sub-agents. See `agents/simple-*/README.md` for the caller contract.

## EXECUTE-WAVE: Pool Dispatch (delivery-level, FR6)

> **When to use this section:** the orchestrator invoked `aid-execute` for an
> entire delivery (e.g., `/aid-execute delivery-005`) rather than a single task.
> Pool dispatch replaces the serial per-task loop with a continuous agent pool.
> For single-task invocation (`/aid-execute task-NNN`) skip to **Step 1** below.

### PD-0: Read Configuration

1. **Read `MaxConcurrent`** from `.aid/knowledge/STATE.md` top-of-file metadata:
   `bash canonical/scripts/config/read-setting.sh --path execution.max_parallel_tasks --default 5` (default `5` if absent).

2. **Detect host capability — `run_in_background` probe.**

   Issue a **no-op probe dispatch** to determine whether the host Agent tool
   supports `run_in_background: true`. The probe is a minimal Agent call that
   does nothing but return a fixed string immediately:

   ```
   Agent(
     subagent_type: simple-extractor,
     prompt: "Reply with the single word: PROBE_OK. Do nothing else.",
     run_in_background: true
   )
   ```

   **Interpret the result:**

   | Result | Interpretation |
   |--------|---------------|
   | Call returns **immediately** (before the sub-agent finishes) with a background handle | `run_in_background` is **supported** — proceed with configured `MaxConcurrent` |
   | Call **blocks** until the sub-agent replies (synchronous — no handle, just the reply text) | `run_in_background` is **not supported** — apply graceful degradation |
   | Call **errors** (unsupported parameter, tool error, timeout < 5 s) | `run_in_background` is **not supported** — apply graceful degradation |

   **On `run_in_background` not supported — apply graceful degradation:**

   a. Capture the user-configured `MaxConcurrent` value (N) from step 1.

   b. Set effective `MaxConcurrent` to `1`.

   c. **Print user-visible degradation notice** (required — must always appear
      when effective MaxConcurrent is reduced below the configured value):

      ```
      [degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
      ```

      where `{N}` is the configured value read in step 1.

   d. **Append degradation event to work `STATE.md` `## Calibration Log`:**

      ```
      | {YYYY-MM-DD} | probe | background_execution | n/a | n/a | degraded — host capability=sequential; effective MaxConcurrent=1 (configured={N}) |
      ```

      Use the current date for `{YYYY-MM-DD}` and the actual configured value
      for `{N}`. This entry is informational — it records that degradation
      occurred, its reason, and the configured value that was overridden.

   e. Continue with `MaxConcurrent=1`. The pool algorithm below operates
      identically in serial mode — "fill pool" (PD-2) dispatches exactly one
      task at a time, PD-3 waits for it, PD-4 processes it, and PD-2 repeats.
      No Impediment is raised; degradation is not an error.

   **On `run_in_background` supported:** no action needed. Continue with the
   configured `MaxConcurrent` from step 1 as the effective value.

3. **Locate the Execution Graph:**
   - If `PLAN.md` exists in the work directory → read the `#### Execution Graph`
     block from the delivery's section.
   - Otherwise (lite path) → read the equivalent block from the work-root
     `SPEC.md`.
   - Parse the `| Task | Depends On |` table into an in-memory dependency map.

### PD-1: Initialize State

Compute the **ready set** — every task whose `Depends On` list is `—` (no deps)
or whose every dependency already has Status `Done` in the work `STATE.md ## Tasks
Status` table.

Mark all other tasks **Pending** (no state write needed — absence of `Done` implies
Pending). The **in-flight set** starts empty. The **blocked set** starts empty.

Print the initial EXECUTE-WAVE snapshot (see **EXECUTE-WAVE Snapshot** in
`SKILL.md`):

```
Wave ∞ (pool) · 0/{T} done

| Task | Type | Status | Time |
|------|------|--------|------|
| task-001 | IMPLEMENT | (queued) | — |
| task-002 | IMPLEMENT | (queued) | — |
...
```

### PD-2: Fill Pool

While `|in-flight| < MaxConcurrent` and the ready set is non-empty:

1. Pick the **lowest-numbered task** from the ready set (FIFO-by-task-number).
2. Move it from ready set → in-flight set.
3. **Provision an isolated worktree** for this task:
   - Worktree path: `.aid/.worktrees/task-{NNN}/` (create with `git worktree add`)
   - Branch: same delivery branch (`aid/delivery-NNN`) — task inherits the
     shared delivery branch; graph-independence guarantees file-disjointness.
4. **Dispatch via Agent tool with `run_in_background: true`:**

   ```
   Agent(
     subagent_type: <type-specific executor from Agent Selection table>,
     prompt: <per-task prompt — see PD-2a below>,
     run_in_background: true
   )
   ```

   The return handle is stored in `in-flight[task-NNN] = handle`.

   > **Sequential fallback (effective MaxConcurrent=1):** When `run_in_background`
   > is not supported (degraded host — detected in PD-0 step 2), dispatch the
   > Agent call **without** `run_in_background`. The call blocks until the
   > sub-agent returns. Treat the returned result as the completion event and
   > proceed directly to PD-4 for that task, then loop back to PD-2.

5. Update work `STATE.md` row Status to `In Progress` via:
   ```
   writeback-task-status.sh --task-id NNN --field Status --value "In Progress"
   ```

6. Pre-create heartbeat file: `.aid/.heartbeat/<executor>-<unix-ts>.txt`
   Include `HEARTBEAT_FILE=<path>` and `HEARTBEAT_INTERVAL=1m` in the prompt.

7. Print `▶ <executor> starting for task-{NNN} (~<ETA-band>)` and re-render
   the EXECUTE-WAVE snapshot with `task-{NNN}` now `● running`.

Repeat until pool is full (`|in-flight| = MaxConcurrent`) or ready set is empty.

#### PD-2a: Per-task Agent Prompt Template

Each dispatched agent receives:

```
TASK: task-{NNN}
WORK: .aid/{work}/
WORKTREE: .aid/.worktrees/task-{NNN}/
HEARTBEAT_FILE: .aid/.heartbeat/{executor}-{ts}.txt
HEARTBEAT_INTERVAL: 1m

Execute task-{NNN} using the aid-execute skill in per-task mode — full pipeline
EXECUTE → QUICK CHECK → REVIEW → cycles until DONE.
Read task-{NNN}.md from .aid/{work}/tasks/. Follow the type-specific executor
rules from references/task-type-rules.md. On completion, commit to the delivery
branch in the worktree. Report: DONE or FAILED with reason.
```

### PD-3: Wait for One Completion

**Block until any one in-flight agent returns** (completion notification from
the Agent tool's `run_in_background` dispatch). This is a **one-event wait**,
not a join — the pool reacts to each completion independently.

> **Sequential fallback (effective MaxConcurrent=1):** When running in degraded
> mode (no `run_in_background` support), PD-2 blocks synchronously on each
> dispatch. PD-3 is therefore a no-op — the completion is already in hand.
> Skip directly to PD-4.

While waiting, service L2 timers (per the Dispatch Protocol in `SKILL.md`):
- Fire timer 1 at ETA/2 — read heartbeat files for each in-flight task and emit
  `[from heartbeat] task-{NNN}: <state> · <progress> · <activity>`.
- Fire timer 2 at ETA — same.
- Fire timer 3 at 1.5×ETA — emit `⚠️ task-{NNN} EXCEEDED estimate`.

When a completion notification arrives for `task-{NNN}` → proceed to **PD-4**.

### PD-4: On Completion

Remove `task-{NNN}` from the in-flight set.

**If the task completed successfully (DONE):**

1. **Verify worktree HEAD is on delivery branch.** Under the shared-branch model,
   each worktree was provisioned on the same `aid/delivery-NNN` branch (PD-2 step 3)
   and committed directly to it. No cherry-pick is needed — the commits are already
   on the shared delivery branch by construction. This is a no-op verification:
   ```bash
   git -C .aid/.worktrees/task-{NNN}/ log --oneline origin/{delivery-branch}..HEAD
   ```
   (Expected output: the sub-agent's commits, already on the delivery branch.)

2. **Update STATUS to Done:**
   ```bash
   writeback-task-status.sh --task-id NNN --field Status --value "Done"
   ```
   _(The per-task full pipeline EXECUTE → QUICK CHECK → REVIEW ran inside the
   dispatched sub-agent; by the time DONE is reported, the sub-agent has already
   completed its own review cycles.)_

3. **Update the ready set:** for every Pending task whose `Depends On` set is
   now entirely `Done`, add that task to the ready set.

4. Emit `✓ <executor> done for task-{NNN} in <actual>`.
   Append to work `STATE.md ## Calibration Log`:
   `| YYYY-MM-DD | <executor> | task-{NNN} | <ETA-band> | <actual> | pool-dispatch |`

5. Delete the worktree: `git worktree remove .aid/.worktrees/task-{NNN}/`.
   Delete heartbeat file.

6. Re-render EXECUTE-WAVE snapshot with `task-{NNN}` now `✓ done`.

7. **Go to PD-2** (fill pool — immediately dispatch newly-ready tasks).

**If the task Failed (IMPEDIMENT raised, unresolved):**

1. Emit `✗ <executor> FAILED for task-{NNN} after <elapsed>`.

2. Update status:
   ```bash
   writeback-task-status.sh --task-id NNN --field Status --value "Failed"
   ```

3. Emit `[pool] ✗ task-{NNN} FAILED — computing failure-block-radius`.

4. **Compute the failure-block-radius (transitive-descendant BFS):**

   Run `canonical/scripts/execute/compute-block-radius.sh` with the
   failed task and the reverse dependency graph:

   ```bash
   compute-block-radius.sh --failed-task NNN --graph-file <graph-snapshot>
   ```

   The script returns a newline-separated list of task IDs that transitively
   depend on `task-{NNN}` (BFS over the reverse dependency graph). This is the
   **block-radius set** — every task that must be marked Blocked because
   it cannot run without the failed task's output.

   **BFS algorithm (authoritative specification):**

   ```
   Input:  failed_id         — the task-NNN that just failed
           reverse_graph     — map: task-NNN → [tasks that directly depend on it]

   Output: blocked_set       — all transitive descendants of failed_id

   Algorithm:
     queue    ← [failed_id]
     visited  ← {failed_id}
     blocked_set ← {}

     while queue is non-empty:
       current ← dequeue(queue)
       for each dependent D in reverse_graph[current]:
         if D not in visited:
           visited ← visited ∪ {D}
           blocked_set ← blocked_set ∪ {D}
           enqueue(queue, D)

     return blocked_set   // does NOT include failed_id itself
   ```

   **Properties:**
   - The failed task itself is NOT in `blocked_set` (it is already Failed).
   - `blocked_set` is the minimal set: only tasks that cannot run because
     they have a transitive dependency on the failed task.
   - All `Depends On` edges are AND — there are no alternative paths that
     could satisfy a dependency via a non-failed ancestor.
   - If `failed_id` has no dependents, `blocked_set` is empty (no radius).

5. For each task `B` in the block-radius set:

   - Mark it Blocked via:
     ```bash
     writeback-task-status.sh --task-id B --field Status --value "Blocked"
     writeback-task-status.sh --task-id B --field Notes \
       --value "Blocked: transitive dependency on failed task-{NNN}"
     ```
   - Remove `B` from the ready set if present (blocked tasks are never dispatched).
   - Add `B` to the blocked set.
   - Print: `[pool] ⊘ task-{B} blocked (transitive dependency on task-{NNN})`.

6. Re-render EXECUTE-WAVE snapshot: `task-{NNN}` → `✗ failed`;
   each blocked descendant → `⊘ blocked`.

7. Surface the IMPEDIMENT: read `.aid/{work}/IMPEDIMENT-task-{NNN}.md` and
   print it. The pool **continues operating** on unrelated chains — do NOT stop.
   Tasks already in flight at the moment of failure are NOT cancelled — they are
   graph-independent of the failed task. Pending tasks in unrelated chains
   continue to enter the pool normally as their own dependencies clear.

8. Delete the worktree and heartbeat file.

9. **Go to PD-2** (pool continues with remaining ready tasks).

### PD-5: Fixed Point and Diagnostic Report

The pool has reached **fixed point** when BOTH conditions are met:

- `|in-flight| = 0` (no tasks currently executing)
- `|ready set| = 0` (no tasks waiting for a pool slot)

At fixed point, print the final EXECUTE-WAVE snapshot and then evaluate:

**Case A — Fully successful (no failed, no blocked tasks):**

```
[pool] Fixed point — all tasks Done. Running per-delivery quality gate.
Done: {N}  In-flight: 0  Queued: 0  Blocked: 0  Failed: 0
```

Proceed to the per-delivery quality gate (see `references/state-delivery-gate.md` —
dispatched once for the delivery, not per task).

**Case B — Partial (some tasks Failed or Blocked):**

The delivery is **partially complete**. The per-delivery quality gate does
NOT run (FR6 × FR2 interlock: gate fires only after a fully successful fixed
point).

Print the **damage-radius diagnostic report**:

```
[pool] Fixed point — delivery PARTIALLY COMPLETE (delivery failed)

Tasks Done:    {D}
Tasks Failed:  {F}
Tasks Blocked: {B}
Tasks Pending: {P}  (should be 0 at fixed point — verify if non-zero)

Failed tasks (with Impediment references):
  ✗ task-{NNN} — IMPEDIMENT: .aid/{work}/IMPEDIMENT-task-{NNN}.md
  ...

Blocked tasks (transitive descendants of failed ancestors):
  ⊘ task-{B1} — blocked by task-{NNN}
  ⊘ task-{B2} — blocked by task-{NNN}
  ...

Per-delivery quality gate: SKIPPED (tasks Failed/Blocked — interlock active)

Next steps:
  1. Resolve the Impediment(s) listed above.
  2. Re-run the failed task(s): /aid-execute task-{NNN}
  3. Resume the delivery: /aid-execute delivery-{DDD}
     The pool will re-admit blocked tasks whose dependencies become Done.
```

**State invariants at fixed point (Case B):**

- Every task in the failed set has Status `Failed` in work `STATE.md`.
- Every task in the blocked set has Status `Blocked` in work `STATE.md` with
  a Notes entry naming its failed ancestor.
- No Blocked task was dispatched (Blocked tasks never enter the ready set).
- Every task NOT in the failed or blocked sets and not already `Done` has
  Status `Pending` — it was not reached this run because it was not yet ready
  when the pool exhausted all forward progress. This is normal for partially-
  ordered deliveries and is NOT the same as being Blocked.

**Resume semantics:** After the user resolves a failure (fixes and re-runs the
failed task), a fresh `aid-execute delivery-{DDD}` invocation re-initializes
the pool (PD-1). Previously-Done tasks stay Done. The newly-resolved task
becomes Done. Tasks that were Blocked because of the resolved task are reset
to Pending and will be admitted to the pool as their dependencies clear.

**STOP.** Do not proceed to the delivery gate. The user resolves failures and
re-invokes `aid-execute`.

### PD-6: Graceful Degradation (MaxConcurrent = 1)

When effective `MaxConcurrent` is `1` (either user-configured or reduced by the
host-capability probe in PD-0 step 2):

**Algorithm semantics are identical to the general case** — the pool loop (PD-1
through PD-5) runs without modification. The only behavioral difference is:

- Pool fill (PD-2) dispatches exactly **one task at a time** (`|in-flight| ≤ 1`).
- PD-3 waits for that single task. On degraded hosts (no `run_in_background`),
  PD-2's synchronous dispatch already delivers the result; PD-3 is a no-op.
- PD-4 processes the result and updates the ready set.
- PD-2 then dispatches the next ready task.

This produces **serial execution** — the pool loop is not short-circuited,
bypassed, or replaced. It runs exactly as with `MaxConcurrent=5`, just with a
ceiling of 1 in-flight at a time.

**No degenerate behaviors:** The ready-set FIFO ordering, dependency tracking,
failure radius (Blocked propagation), fixed-point detection, and the EXECUTE-WAVE
snapshot all function identically with pool size 1. The snapshot still renders
after each transition, showing at most one task as `● running` at a time — this
is the same serial-task snapshot documented in `SKILL.md`'s **EXECUTE-WAVE**
section as the "Serial-task fallback (current behavior)."

**Degradation message at pool entry** (when `MaxConcurrent=1` due to host
capability — i.e., when PD-0 step 2 applied the probe and detected no support):

The user-visible notice was already printed at PD-0 step 2c. At PD-1
initialization, additionally print the local reminder:

```
[degradation] MaxConcurrent=1 — running tasks serially.
```

If `MaxConcurrent` is `1` because the user *configured* it that way (not because
of host capability), only the local reminder is printed at PD-1 (no "requested N"
prefix — the user intentionally chose 1).

**Calibration Log entry:** The degradation event was appended to
`STATE.md ## Calibration Log` at PD-0 step 2d (on probe failure). No additional
Calibration Log entry is written at PD-6 for the same degradation event. If
`MaxConcurrent=1` is user-configured (no degradation), no Calibration Log entry
is written (not an event — it is the intended configuration).

Serial-mode tasks share the delivery branch without coordination overhead —
each commit lands before the next task starts, so no cherry-pick step is needed;
the worktree is still provisioned (for isolation) but the commit is sequential.

---

## EXECUTE-WAVE Drill-down (per-in-flight-task detail)

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
|          |           | agent: researcher · heartbeat: RUNNING · elapsed: 6m 40s · ETA: ~8 min |
| task-003 | DOCUMENT  | ● running | 1m 15s (↑ ~3m)|
|          |           | agent: tech-writer · heartbeat: REVIEW · elapsed: 1m 15s · ETA: ~3 min |
| task-004 | TEST      | (queued)  | —             |
| task-005 | IMPLEMENT | ⊘ blocked | —             |

Done: {D}  In-flight: {I}  Queued: {Q}  Blocked: {B}  Failed: {F}
```

**Per-task drill-down row fields:**

| Field | Source | Format |
|-------|--------|--------|
| `agent` | Executor role dispatched for this task (from Agent Selection table) | e.g., `developer`, `researcher` |
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

---

## Step 1: EXECUTE (Do the Work)

Update work `STATE.md` `## Tasks Status` table: set this task's row Status to `In Progress`.

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH → `researcher`, DESIGN → `ux-designer`, IMPLEMENT/TEST/REFACTOR → `developer`, DOCUMENT → `tech-writer`, MIGRATE → `data-engineer`, CONFIGURE → `devops`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor — this overrides the skill's default `agent: developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: ux-designer`; an IMPLEMENT task uses `subagent_type: developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task → subagent_type={executor}` (substituting actual values).

Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule — always, not conditional).

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
✓ {executor} done (record actual time) — or ✗ {executor} failed: {reason}
When execution passes → update work `STATE.md` `## Tasks Status` row Status to `In Review` → proceed to Step 2 (REVIEW).

**Advance:** Next state is `REVIEW` — when this state's work completes, router prints `Next: [State: REVIEW] — run /aid-execute again` and exits.
