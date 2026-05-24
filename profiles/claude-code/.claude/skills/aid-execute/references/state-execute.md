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
   `**Max Parallel Tasks:** N` (default `5` if the field is absent).

2. **Detect host capability.** If the Agent tool's `run_in_background` parameter
   is not supported on this host (test by issuing a no-op probe dispatch):
   - Log: `[degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1`
   - Set effective `MaxConcurrent` to `1` (graceful degradation — not an error,
     no Impediment raised).
   - Continue with `MaxConcurrent=1`; the algorithm below still operates correctly
     in serial mode — "fill pool" always dispatches exactly one task at a time.

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

Execute task-{NNN} using the aid-execute skill (single-task mode — Step 1 only).
Read task-{NNN}.md from .aid/{work}/tasks/. Follow the type-specific executor
rules from references/task-type-rules.md. On completion, commit to the delivery
branch in the worktree. Report: DONE or FAILED with reason.
```

### PD-3: Wait for One Completion

**Block until any one in-flight agent returns** (completion notification from
the Agent tool's `run_in_background` dispatch). This is a **one-event wait**,
not a join — the pool reacts to each completion independently.

While waiting, service L2 timers (per the Dispatch Protocol in `SKILL.md`):
- Fire timer 1 at ETA/2 — read heartbeat files for each in-flight task and emit
  `[from heartbeat] task-{NNN}: <state> · <progress> · <activity>`.
- Fire timer 2 at ETA — same.
- Fire timer 3 at 1.5×ETA — emit `⚠️ task-{NNN} EXCEEDED estimate`.

When a completion notification arrives for `task-{NNN}` → proceed to **PD-4**.

### PD-4: On Completion

Remove `task-{NNN}` from the in-flight set.

**If the task completed successfully (DONE):**

1. **Cherry-pick the worktree commits** onto the shared delivery branch:
   ```bash
   git -C .aid/.worktrees/task-{NNN}/ log --oneline origin/{delivery-branch}..HEAD \
       | awk '{print $1}' | tac | xargs git cherry-pick
   ```
   (If the worktree was on the same branch and committed directly, this step
   is a no-op — the commits are already on the branch.)

2. **Update STATUS via writeback-task-status.sh:**
   ```bash
   writeback-task-status.sh --task-id NNN --field Status --value "In Review"
   ```
   _(The per-task quick check for this task runs as part of Step 1 → REVIEW
   inside the dispatched sub-agent; by the time DONE is reported, it has already
   passed. Update to "Done" once the sub-agent's own REVIEW completes.)_

3. **Update STATUS to Done:**
   ```bash
   writeback-task-status.sh --task-id NNN --field Status --value "Done"
   ```

4. **Update the ready set:** for every Pending task whose `Depends On` set is
   now entirely `Done`, add that task to the ready set.

5. Emit `✓ <executor> done for task-{NNN} in <actual>`.
   Append to work `STATE.md ## Calibration Log`:
   `| YYYY-MM-DD | <executor> | task-{NNN} | <ETA-band> | <actual> | pool-dispatch |`

6. Delete the worktree: `git worktree remove .aid/.worktrees/task-{NNN}/`.
   Delete heartbeat file.

7. Re-render EXECUTE-WAVE snapshot with `task-{NNN}` now `✓ done`.

8. **Go to PD-2** (fill pool — immediately dispatch newly-ready tasks).

**If the task Failed (IMPEDIMENT raised, unresolved):**

1. Emit `✗ <executor> FAILED for task-{NNN} after <elapsed>`.

2. Update status:
   ```bash
   writeback-task-status.sh --task-id NNN --field Status --value "Failed"
   ```

3. **Compute transitive descendant set** — every task that transitively depends
   on `task-{NNN}` in the Dependency Map. For each descendant `task-DDD`:
   ```bash
   writeback-task-status.sh --task-id DDD --field Status --value "Blocked"
   ```
   Remove descendants from the ready set (if present) and add them to the
   blocked set. They will never be dispatched.

4. Re-render EXECUTE-WAVE snapshot: `task-{NNN}` → `✗ failed`;
   each blocked descendant → `⊘ blocked`.

5. Surface the IMPEDIMENT: read `.aid/{work}/IMPEDIMENT-task-{NNN}.md` and
   print it. The pool **continues operating** on unrelated chains — do NOT stop.

6. Delete the worktree and heartbeat file.

7. **Go to PD-2** (pool continues with remaining ready tasks).

### PD-5: Fixed Point

The pool has reached **fixed point** when BOTH conditions are met:

- `|in-flight| = 0` (no tasks currently executing)
- `|ready set| = 0` (no tasks waiting for a pool slot)

At fixed point, print the final EXECUTE-WAVE snapshot and then evaluate:

**Case A — Fully successful (no failed, no blocked tasks):**

```
Pool fixed point reached. All tasks Done.
Done: {N}  In-flight: 0  Queued: 0  Blocked: 0  Failed: 0

Proceeding to per-delivery quality gate.
```

Proceed to the per-delivery REVIEW gate (see `references/state-review.md` —
dispatched once for the delivery, not per task).

**Case B — Partial (some tasks Failed or Blocked):**

```
Pool fixed point reached — partial completion.
Done: {D}  In-flight: 0  Queued: 0  Blocked: {B}  Failed: {F}

Failed tasks:
  task-{NNN} — see .aid/{work}/IMPEDIMENT-task-{NNN}.md

Blocked tasks (transitive descendants of failed ancestors):
  task-{DDD} — blocked by task-{NNN}
  ...

Per-delivery quality gate will NOT run while tasks are Failed/Blocked.
Resolve the failure(s), then re-invoke /aid-execute to resume.
```

**STOP.** Do not proceed to the delivery gate. The user resolves failures and
re-invokes `aid-execute`; on re-invoke, the pool reloads STATE and resumes from
the remaining un-Done tasks (newly-unblocked tasks become ready again once their
ancestors are fixed and Done).

### PD-6: Graceful Degradation (MaxConcurrent = 1)

When effective `MaxConcurrent` is `1` (either user-configured or host-degraded):

- Pool fill (PD-2) dispatches exactly one task at a time.
- PD-3 waits for that single task.
- PD-4 processes its result.
- PD-2 dispatches the next ready task.

This produces **serial execution** — the algorithm is identical to the general
case but with pool size 1. The EXECUTE-WAVE snapshot still renders after each
transition. The user sees:

```
[degradation] MaxConcurrent=1 — running tasks serially.
```

_(If caused by host capability, the fuller message was already printed at PD-0.)_

Serial-mode tasks share the delivery branch without coordination overhead —
each commit lands before the next task starts, so no cherry-pick step is needed;
the worktree is still provisioned (for isolation) but the commit is sequential.

---

## Step 1: EXECUTE (Do the Work)

Update work `STATE.md` `## Tasks Status` table: set this task's row Status to `In Progress`.

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH → `researcher`, DESIGN → `ux-designer`, IMPLEMENT/TEST/REFACTOR → `developer`, DOCUMENT → `tech-writer`, MIGRATE → `data-engineer`, CONFIGURE → `devops`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor — this overrides the skill's default `agent: developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: ux-designer`; an IMPLEMENT task uses `subagent_type: developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task → subagent_type={executor}` (substituting actual values).

Also update the task's row in work `STATE.md` `## Dispatches` sub-column (always — mandatory per work-003 traceability, not conditional): `| 1 | {executor} | EXECUTE Type={Type} | {cycle} |`.

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
✓ {executor} done (record actual time) — or ✗ {executor} failed: {reason}
When execution passes → update work `STATE.md` `## Tasks Status` row Status to `In Review` → proceed to Step 2 (REVIEW).

**Advance:** Next state is `REVIEW` — when this state's work completes, router prints `Next: [State: REVIEW] — run /aid-execute again` and exits.
