# State: EXECUTE

Task work is dispatched to the type-appropriate executor agent to produce deliverables; state is entered when no prior execution exists or when resuming an in-progress task.

## MANDATORY: State-Write Protocol -- read this before doing anything else

> **A task's `State` field MUST be written to disk THE MOMENT it changes -- not
> batched, not deferred, not "I'll do it at the end." This is not a formality:
> it is the entire mechanism that makes the dashboard show live progress
> instead of a task sitting at `Pending` for its whole execution and then
> jumping straight to `Done`.**

**Full runnable form (every row below is an abbreviation of this):**
`writeback-state.sh [--delivery-id NNN] --task-id NNN --field State --value "VALUE"`
(`--delivery-id` is optional -- it is resolved from the task's own `Source`
line when omitted; the layout, full or flat, is auto-detected either way.)

| Transition | When | Write (abbreviated -- see full runnable form above) |
|---|---|---|
| -> `In Progress` | BEFORE any work begins (EXECUTE entry, Step 1 below) | `... --field State --value "In Progress"` |
| -> `In Review` | At EXECUTE-complete, BEFORE dispatching the reviewer | `... --field State --value "In Review"` |
| -> `Done` | At the per-task REVIEW quick-check's terminal chain (`references/state-review.md`) -- written by the executing agent itself, whether that is the main/orchestrator agent (single-task invocation) or a dispatched sub-agent (single-task dispatch OR a pool-dispatch worker running its own per-task pipeline, per `PD-2a` below) | `... --field State --value "Done"` |
| -> `Failed` | The moment this task raises an unresolved IMPEDIMENT (single-task path -- `SKILL.md § Impediments`; quick-check CRITICAL-persists path -- `state-review.md`) -- same "whoever is executing writes it" rule as `Done` above | `... --field State --value "Failed"` |
| -> `Done` / `Failed` (pool dispatch, orchestrator side) | PD-4 on completion/failure (`## EXECUTE-WAVE: Pool Dispatch` below) -- a belt-and-suspenders backstop for AFTER the sub-agent reports back, not a substitute for the sub-agent's own write above | same abbreviated form, `--task-id` from the pool loop |

**Why this matters:** the dashboard (and every downstream dependency check --
`SKILL.md § Check 2b`) reads this field LIVE, straight off disk. An unwritten
transition is not a cosmetic gap -- it is an INVISIBLE or MISLEADING task: the
dashboard shows `Pending` while real work is already underway, a dependent
task cannot distinguish "not started yet" from "actually running," and a
stalled task never surfaces as `Failed` for anyone watching the board.

**Who this binds -- NO EXCEPTIONS:**
- The **main/orchestrator agent** executing a task **directly** (no dispatched
  sub-agent) MUST perform every write above itself, at the same points, as
  part of its own inline execution. "I'm doing this myself, not delegating
  it" is NOT a reason to skip a write -- the write is not paperwork attached
  to the work, it IS part of the work of making a transition.
- A **dispatched sub-agent** (single-task dispatch OR a pool-dispatch worker
  running its own full per-task pipeline, per `PD-2a` below) MUST perform
  these writes itself, at the same points, as it executes.
- **Neither may bypass, batch, or defer these writes** -- not "to save a
  round-trip," not "because the task will finish soon anyway." A transition
  that happened but was never written is, from the dashboard's point of view,
  indistinguishable from a transition that never happened at all.

**Both layouts, no special-casing:** `writeback-state.sh --delivery-id DDD
--task-id NNN --field State --value V` auto-detects the layout -- **full
layout** writes the per-task `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`
frontmatter; **flat layout** (feature-001) writes the SAME task's row in the
work-root `STATE.md § ### Tasks lifecycle` table instead. Same command, same
call sites, no branching in the instructions above -- the script handles the
layout difference so the executing agent does not have to.

**Both dispatch modes, no special-casing:** for a **single-task invocation**
the writes above happen inline as the task's own EXECUTE/REVIEW states run
(Step 1 below; `state-review.md`'s terminal chain). For **pool dispatch**
(`## EXECUTE-WAVE: Pool Dispatch` below) the orchestrator's PD-2/PD-4 steps
ALSO write `In Progress`/`Done`/`Failed` for the task it just dispatched or
just reaped, AND each dispatched sub-agent runs the SAME single-task flow
internally (PD-2a's prompt template says so explicitly) -- so `In Progress`,
`In Review`, AND the terminal `Done`/`Failed` are ALL written by the
sub-agent itself too, exactly as if it were a single-task invocation.
Belt-and-suspenders, not either-or: the orchestrator's writes are a backstop,
never a substitute for the executing agent's own -- a redundant write of the
same already-current value is harmless and idempotent; a MISSING write is
the bug this protocol exists to prevent.

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

Each task type dispatches a specific executor agent. The reviewer is always the same role (`aid-reviewer`), separate from the executor for clean context. Specialist consults are dispatched in addition to the reviewer when the task type warrants it.

| Task Type | Executor | Reviewer | Specialist consult |
|-----------|----------|----------|---------------------|
| RESEARCH | `aid-researcher` | `aid-reviewer` | — |
| DESIGN | `aid-architect` | `aid-reviewer` | — |
| IMPLEMENT | `aid-developer` | `aid-reviewer` | `aid-researcher` (analysis) if task touches auth/PII; `aid-researcher` (analysis) if hot path |
| TEST | `aid-developer` | `aid-reviewer` | `aid-researcher` (analysis) for load/integration tests |
| DOCUMENT | `aid-tech-writer` | `aid-reviewer` | — |
| MIGRATE | `aid-developer` | `aid-reviewer` | `aid-developer` review (different instance than executor) |
| REFACTOR | `aid-developer` | `aid-reviewer` | — |
| CONFIGURE | `aid-developer` | `aid-reviewer` | `aid-researcher` (analysis) if config touches secrets/auth |

**Reviewer ≠ executor invariant.** Even when a task type uses the same agent role for both execution and consult-review (MIGRATE), they run as separate dispatches with clean context. The reviewer never sees the executor's working notes.

**Model override per task type.** Each executor has a default tier from its agent definition (Developer is Medium tier, etc.). For genuinely complex work — REFACTOR over a tangled module, MIGRATE with edge cases, IMPLEMENT touching critical security paths — the orchestrator may dispatch with an explicit higher-tier model in the Task tool's `model` parameter. This is a runtime decision per dispatch, not a skill configuration.

**Mechanical sub-tasks.** Executors may delegate mechanical work (extraction, file enumeration, template filling) to `aid-clerk` (with `operation: extract`, `operation: glob`, or `operation: format` respectively) — Small-tier utility sub-agents. See `agents/aid-clerk/README.md` for the caller contract.

## EXECUTE-WAVE: Pool Dispatch (delivery-level, FR6)

> **When to use this section:** the orchestrator invoked `aid-execute` for an
> entire delivery (e.g., `/aid-execute delivery-005`) rather than a single task.
> Pool dispatch replaces the serial per-task loop with a continuous agent pool.
> For single-task invocation (`/aid-execute task-NNN`) skip to **Step 1** below.

### PD-0: Read Configuration

1. **Read `MaxConcurrent`** from `.aid/knowledge/STATE.md` top-of-file metadata:
   `bash .codex/aid/scripts/config/read-setting.sh --path execution.max_parallel_tasks --default 5` (default `5` if absent).

2. **Detect host capability — `run_in_background` probe.**

   Issue a **no-op probe dispatch** to determine whether the host Agent tool
   supports `run_in_background: true`. The probe is a minimal Agent call that
   does nothing but return a fixed string immediately:

   ```
   Agent(
     subagent_type: aid-clerk,
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
   - **Flat path (feature-001, single-delivery)** — detected by: a work-root
     `BLUEPRINT.md` present AND `tasks/task-NNN/DETAIL.md` present directly
     under the work root AND no `deliveries/` wrapper under it → read the
     top-level `## Execution Graph` from the work-root `PLAN.md` (no
     `### delivery-NNN` heading; the single delivery is implicit).
   - **Full path** — otherwise, if `PLAN.md` exists in the work directory → read
     the `#### Execution Graph` block from the delivery's section.
   - Otherwise (lite path) → read the equivalent block from the work-root
     `SPEC.md`.
   - Parse the `| Task | Depends On |` table into an in-memory dependency map.

### PD-1: Initialize State

Compute the **ready set** — every task whose `Depends On` list is `—` (no deps)
or whose every dependency already has `State: Done`:
- **Full path:** in its respective `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`
  `## Task State` section.
- **Flat path:** in the work-root `STATE.md § ### Tasks lifecycle` row for that task.

Mark all other tasks **Pending** (no state write needed — absence of `Done` implies
Pending). The **in-flight set** starts empty. The **blocked set** starts empty.

**Advance delivery lifecycle to Executing** (silent state-write -- fires once when
the first task is dispatched, idempotent if already Executing):
```bash
bash .codex/aid/scripts/execute/writeback-state.sh \
    --delivery-id DDD --lifecycle Executing
```

Print the initial EXECUTE-WAVE snapshot (see **EXECUTE-WAVE Snapshot** in
`SKILL.md`):

```
Wave ∞ (pool) · 0/{T} done

| Task | Type | State | Time |
|------|------|-------|------|
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
   - Branch: same delivery branch (`aid/{work}-delivery-NNN`) — task inherits the
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

5. **MANDATORY (State-Write Protocol above) -- do this BEFORE moving on to
   step 6:** update task State to `In Progress` via:
   ```
   writeback-state.sh --delivery-id DDD --task-id NNN --field State --value "In Progress"
   ```
   This is the orchestrator's own write for the pool path; the dispatched
   sub-agent ALSO writes `In Progress` (and later `In Review`) itself as it
   runs its own per-task EXECUTE state -- both are expected, both are
   idempotent, neither is optional.

6. Pre-create heartbeat file: `.aid/.heartbeat/<executor>-<unix-ts>.txt`
   Include `HEARTBEAT_FILE=<path>` and `HEARTBEAT_INTERVAL=1m` in the prompt.

7. Print `▶ <executor> starting for task-{NNN} (~<ETA-band>)` and re-render
   the EXECUTE-WAVE snapshot with `task-{NNN}` now `● running`.

Repeat until pool is full (`|in-flight| = MaxConcurrent`) or ready set is empty.

#### PD-2a: Per-task Agent Prompt Template

Each dispatched agent receives a prompt that branches on layout exactly as
PD-0 step 3 / PD-1 above (a flat work has no `deliveries/` wrapper and no
per-task `STATE.md`):

**Full path:**

```
TASK: task-{NNN}
DELIVERY: delivery-{DDD}
WORK: .aid/{work}/
WORKTREE: .aid/.worktrees/task-{NNN}/
HEARTBEAT_FILE: .aid/.heartbeat/{executor}-{ts}.txt
HEARTBEAT_INTERVAL: 1m

Execute task-{NNN} using the aid-execute skill in per-task mode -- full pipeline
EXECUTE -> QUICK CHECK -> REVIEW -> cycles until DONE.
Read task definition from .aid/{work}/deliveries/delivery-{DDD}/tasks/task-{NNN}/DETAIL.md.
Read task state from .aid/{work}/deliveries/delivery-{DDD}/tasks/task-{NNN}/STATE.md.
Follow the type-specific executor rules from references/task-type-rules.md.
MANDATORY: write your own State at EVERY transition you run yourself --
In Progress at your own EXECUTE entry, In Review at your own execute-complete,
and your OWN terminal Done/Failed at your own REVIEW quick-check's terminal
chain (state-execute.md's Step 1 + state-review.md's terminal write -- you are
running these states yourself, not just the orchestrator). Do not skip any of
these writes on the theory that "the orchestrator's PD-4 write covers it" --
PD-4's write is a belt-and-suspenders backstop for AFTER you report back, not
a substitute for your own. Writing the same already-current value twice is
expected and idempotent; a MISSING write is the bug this mandate prevents.
On completion, commit to the delivery branch in the worktree.
Report: DONE or FAILED with reason.
```

**Flat path (feature-001, single-delivery)** -- no `deliveries/` wrapper; the
task's mutable state cells live in the work-root `STATE.md`'s `### Tasks
lifecycle` table row, not a per-task `STATE.md`:

```
TASK: task-{NNN}
DELIVERY: delivery-{DDD}
WORK: .aid/{work}/
WORKTREE: .aid/.worktrees/task-{NNN}/
HEARTBEAT_FILE: .aid/.heartbeat/{executor}-{ts}.txt
HEARTBEAT_INTERVAL: 1m

Execute task-{NNN} using the aid-execute skill in per-task mode -- full pipeline
EXECUTE -> QUICK CHECK -> REVIEW -> cycles until DONE.
Read task definition from .aid/{work}/tasks/task-{NNN}/DETAIL.md.
Read task state from the work-root .aid/{work}/STATE.md § ### Tasks lifecycle
(row for task-{NNN}; there is no per-task STATE.md in this layout).
Follow the type-specific executor rules from references/task-type-rules.md.
MANDATORY: write your own State at EVERY transition you run yourself --
In Progress at your own EXECUTE entry, In Review at your own execute-complete,
and your OWN terminal Done/Failed at your own REVIEW quick-check's terminal
chain (state-execute.md's Step 1 + state-review.md's terminal write -- you are
running these states yourself, not just the orchestrator). Do not skip any of
these writes on the theory that "the orchestrator's PD-4 write covers it" --
PD-4's write is a belt-and-suspenders backstop for AFTER you report back, not
a substitute for your own. Writing the same already-current value twice is
expected and idempotent; a MISSING write is the bug this mandate prevents.
On completion, commit to the delivery branch in the worktree.
Report: DONE or FAILED with reason.
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
   each worktree was provisioned on the same `aid/{work}-delivery-NNN` branch (PD-2 step 3)
   and committed directly to it. No cherry-pick is needed — the commits are already
   on the shared delivery branch by construction. This is a no-op verification:
   ```bash
   git -C .aid/.worktrees/task-{NNN}/ log --oneline origin/{delivery-branch}..HEAD
   ```
   (Expected output: the sub-agent's commits, already on the delivery branch.)

2. **MANDATORY (State-Write Protocol above), do NOT skip even though the task
   already reports success -- Update State to Done:**
   ```bash
   writeback-state.sh --delivery-id DDD --task-id NNN --field State --value "Done"
   ```
   _(The per-task full pipeline EXECUTE -> QUICK CHECK -> REVIEW ran inside the
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

2. **MANDATORY (State-Write Protocol above) -- update state before doing
   anything else below** (the failed task must never be left showing
   `In Progress`/`In Review` on the dashboard):
   ```bash
   writeback-state.sh --delivery-id DDD --task-id NNN --field State --value "Failed"
   ```

   Advance delivery lifecycle to Blocked (silent state-write -- no output, no gate):
   ```bash
   bash .codex/aid/scripts/execute/writeback-state.sh --delivery-id DDD --lifecycle Blocked
   ```

   Emit pipeline block signal (silent state-write -- no output, no gate):
   ```bash
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Blocked
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Block Reason" --value "Task failed with unresolved impediment -- task-{NNN}"
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Block Artifact" --value ".aid/{work}/IMPEDIMENT-task-{NNN}.md"
   bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```

3. Emit `[pool] ✗ task-{NNN} FAILED — computing failure-block-radius`.

4. **Compute the failure-block-radius (transitive-descendant BFS):**

   Run `.codex/aid/scripts/execute/compute-block-radius.sh` with the
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
     writeback-state.sh --delivery-id DDD --task-id B --field State --value "Blocked"
     writeback-state.sh --delivery-id DDD --task-id B --field Notes \
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

- Every task in the failed set has `State: Failed` in its per-task state cell (full path:
  `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`; flat layout: its `task-NNN` row in the
  work-root `STATE.md § ### Tasks lifecycle` -- there is no per-task STATE.md in the flat layout).
- Every task in the blocked set has `State: Blocked` in that same per-task state cell (full path:
  `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`; flat layout: its `task-NNN` row in the
  work-root `STATE.md § ### Tasks lifecycle`) with a Notes entry naming its failed ancestor.
- The delivery `STATE.md` `## Delivery Lifecycle` has `State: Blocked`.
- No Blocked task was dispatched (Blocked tasks never enter the ready set).
- Every task NOT in the failed or blocked sets and not already `Done` has
  `State: Pending` -- it was not reached this run because it was not yet ready
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

The snapshot-rendering spec — icon vocabulary, summary + drill-down snapshot
formats, re-render trigger rules, failure-tolerance invariants, and the render
decision tree — lives in its own reference to keep this state file navigable:

> **Authoritative spec:** [`state-execute-drilldown.md`](state-execute-drilldown.md)

---

## Step 1: EXECUTE (Do the Work)

**MANDATORY, first action, before any other work -- per the State-Write
Protocol above:** update the task State to `In Progress` (silent state-write
-- no output). This applies whether YOU (the main/orchestrator agent) are
executing this task directly or you are the dispatched sub-agent running it --
either way, this is the FIRST thing that happens in this state, not something
deferred until "real work" starts:
```bash
bash .codex/aid/scripts/execute/writeback-state.sh \
    --delivery-id DDD --task-id NNN --field State --value "In Progress"
```

Advance delivery lifecycle to Executing (silent state-write -- no output, idempotent):
```bash
bash .codex/aid/scripts/execute/writeback-state.sh \
    --delivery-id DDD --lifecycle Executing
```

Emit pipeline phase (silent state-write only -- no output, no gate):
```
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Execute
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-execute
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH -> `aid-researcher`, DESIGN -> `aid-architect`, IMPLEMENT/TEST/REFACTOR -> `aid-developer`, DOCUMENT -> `aid-tech-writer`, MIGRATE -> `aid-developer`, CONFIGURE -> `aid-developer`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor -- this overrides the skill's default `agent: aid-developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: aid-architect`; an IMPLEMENT task uses `subagent_type: aid-developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task -> subagent_type={executor}` (substituting actual values).

Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule -- always, not conditional).

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests -- as applicable to the type).
✓ {executor} done (record actual time) -- or ✗ {executor} failed: {reason}

**MANDATORY, before dispatching the reviewer -- per the State-Write Protocol
above:** when execution passes → update task State to `In Review`. This write
happens HERE, at EXECUTE-complete -- not after the reviewer has already been
dispatched, not batched together with a later write:
```bash
bash .codex/aid/scripts/execute/writeback-state.sh \
    --delivery-id DDD --task-id NNN --field State --value "In Review"
```
Then proceed to Step 2 (REVIEW).

**If execution instead raises an unresolved IMPEDIMENT** (the agent cannot
proceed -- see `SKILL.md § Impediments`): update task State to `Failed` there,
per the State-Write Protocol above, before writing the IMPEDIMENT file. Do NOT
leave the task's State at `In Progress` while surfacing an impediment -- an
agent stuck mid-task and an agent that has genuinely failed must be
distinguishable on the dashboard.

**Advance:** **CHAIN** -> [State: REVIEW] (continue inline).
