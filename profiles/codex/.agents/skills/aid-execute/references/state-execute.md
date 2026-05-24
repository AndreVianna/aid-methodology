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

<!-- INSERTION POINT: task-033 (pool dispatch) — when delivery-005 ships, the
     Worker column for EXECUTE will point at a pool-dispatcher sub-agent instead
     of the type-specific agent directly. The pool dispatcher reads the task type
     and routes to the correct executor from an available agent pool. The step
     body below (Step 1) is the natural insertion point for pool-dispatch logic. -->

## Step 1: EXECUTE (Do the Work)

Update work `STATE.md` `## Tasks Status` table: set this task's row Status to `In Progress`.

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH → `researcher`, DESIGN → `ux-designer`, IMPLEMENT/TEST/REFACTOR → `developer`, DOCUMENT → `tech-writer`, MIGRATE → `data-engineer`, CONFIGURE → `devops`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor — this overrides the skill's default `agent: developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: ux-designer`; an IMPLEMENT task uses `subagent_type: developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task → subagent_type={executor}` (substituting actual values).

Also update the task's row in work `STATE.md` `## Dispatches` sub-column (if tracked): `| 1 | {executor} | EXECUTE Type={Type} | {cycle} |`.

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
✓ {executor} done (record actual time) — or ✗ {executor} failed: {reason}
When execution passes → update work `STATE.md` `## Tasks Status` row Status to `In Review` → proceed to Step 2 (REVIEW).

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `canonical/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** from `.aid/knowledge/STATE.md` top-of-file
   `**Heartbeat Interval:** N minutes` (default 1; `0` = disabled).
3. **If ETA LOW > 5 min AND heartbeat enabled:**
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
4. **Arm 3 L2 timers** (via `run_in_background: true`):
   - `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time. Log to
  `STATE.md ## Calibration Log` for L1 calibration. Delete heartbeat file.
- **Failure:** emit `✗ <agent> FAILED after <elapsed> (reason: <one-line>)`.
  Decide whether to re-dispatch, fall back, or surface to user. Delete
  heartbeat file.

**References:**

- `canonical/templates/long-wait-protocol.md` — full L2 spec
- `canonical/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `canonical/templates/rough-time-hints.md` — current measured ETAs
- `canonical/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

## Workspace

```
.aid/
  knowledge/                ← shared KB (via INDEX.md)
    STATE.md                ← minimum grade
  work-NNN-{name}/
    STATE.md                ← § Tasks Status (task rows updated here)
    PLAN.md                 ← delivery context
    known-issues.md         ← issues to watch for
    tasks/
      task-NNN.md           ← PRIMARY INPUT (has Type field)
    features/
      feature-NNN-{name}/
        SPEC.md             ← architectural constraints
```

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN` | Required. Which task to execute. |
| `work-NNN` | Required if multiple works exist. |

## Delivery Lifecycle

Execution follows the **Execution Graph** in PLAN.md. Tasks run in dependency order.
Independent tasks (listed in the "Can Be Done In Parallel" table) can run concurrently.

```
create branch aid/delivery-001
  → /aid-execute task-001 [RESEARCH]      ← investigate → review → ✅
  → /aid-execute task-002 [DESIGN]        ← mockup → review → ✅
  → /aid-execute task-003 [IMPLEMENT]  ┐
  → /aid-execute task-004 [IMPLEMENT]  ┘  ← parallel (both depend on task-002)
  → /aid-execute task-005 [TEST]          ← waits for task-003 + task-004
  → /aid-execute task-006 [DOCUMENT]      ← ADR → review → ✅
  → merge to main
```

All tasks in a delivery accumulate on the same branch.
RESEARCH and DOCUMENT tasks that produce only `.aid/` artifacts may skip branching.

### EXECUTE-WAVE: AC4 Sub-unit Drill-down

When executing a delivery wave (multiple tasks in sequence), render a sub-unit snapshot
immediately after the AC3 state-map on each sub-unit transition. This is the
**AC4 drill-down** for the EXECUTE-WAVE state.

**Snapshot format:**

```
Wave {M} of {N} · {K}/{T} done

| Task | Type | Status | Time |
|------|------|--------|------|
| task-001 | RESEARCH | ✓ done | 4m 12s |
| task-002 | IMPLEMENT | ● running | ~3–8 min |
| task-003 | TEST | (queued) | — |
| task-004 | DOCUMENT | (queued) | — |
```

**Status icons:**
- `✓ done` — task completed and passed review
- `● running` — task currently in EXECUTE or REVIEW
- `✗ failed` — task blocked or errored
- `(queued)` — task not yet started

**Re-render trigger:** render a fresh snapshot block on every sub-unit transition
(queued → running → done / failed). Apply **1-second coalescing** — multiple
transitions within the same second emit a single merged snapshot.

**Serial-task fallback (current behavior):** Until work-001/feature-009 (parallel
execution) ships, tasks run serially — at most 1 task appears as `● running` at a time.
This is documented degradation per the SPEC Migration Plan §1 "AC4 phasing"; it is
not a bug. The snapshot still renders for each serial task transition.

**Failure tolerance:** If snapshot rendering fails for any reason (malformed iteration
source, missing data), swallow the error silently and continue. The snapshot is
informational — it must never block or abort task execution.

## Impediments

If the agent encounters something it can't resolve:

```markdown
# Impediment — task-NNN

**Type:** wrong-assumption | missing-dependency | architecture-conflict | kb-gap
**Description:** What happened and why the agent stopped
**Options:**
1. {Option A} — trade-offs
2. {Option B} — trade-offs
**Recommendation:** Option {N} because {reason}
```

Write to `.aid/{work}/IMPEDIMENT-task-NNN.md`.

Resolution by type:
- **kb-gap** → targeted `/aid-discover` → update KB → retry
- **architecture-conflict** → `/aid-specify` for the feature
- **missing-dependency** → `/aid-detail` (might need another task first)
- **wrong-assumption** → update task or SPEC, retry

After resolving: delete IMPEDIMENT file, retry from Step 1.

## Output

- Artifacts appropriate to the task type (code, tests, docs, configs, research, designs)
- Grade ≥ minimum grade (from `.aid/knowledge/STATE.md` `**Minimum Grade:**`)
- Commit messages reference task-NNN (for types that produce commits)
- Work `STATE.md` `## Tasks Status` row updated with full review history
- IMPEDIMENT-task-NNN.md if blocked

## Project Management Sync (conditional)

If `infrastructure.md § Project Management` defines a tool:
- When starting a task → update corresponding ticket to In Progress
- When task passes review → update ticket to Done
- If loopback needed → add comment to ticket with context

If no PM tool → skip.

**Advance:** Next state is `REVIEW` — when this state's work completes, router prints `Next: [State: REVIEW] — run /aid-execute again` and exits.
