---
name: aid-execute
description: >
  Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type.
  State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum.
  Branch per delivery for isolation.
allowed-tools: Read, Glob, Grep, Write, Edit, Terminal
argument-hint: "task-001 (required)  [work-001 if multiple works]"
---

# Execute Task

Read the type. Do the work. Review it. Fix it. Ship it.

## ⚠️ Pre-flight Checks

### Check 1: Locate Work and Task

1. If work arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. Find `task-NNN.md` in `.aid/{work}/tasks/`
5. Task not found → **STOP.** List available tasks.

### Check 2: Read Task

Read `task-NNN.md`. It has 6 sections:
- **Title** — what this task does
- **Type** — RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE
- **Source** — `feature-NNN-{name} → delivery-NNN` (which feature and deliverable)
- **Depends on** — which tasks must be complete before this one (or `—` for none)
- **Scope** — what to produce or modify (files, tests, docs, configs — depends on type)
- **Acceptance Criteria** — concrete, testable conditions

### Check 2b: Verify Dependencies Met

Read the Execution Graph from PLAN.md for this task's delivery.
Check that all tasks listed in `Depends on:` have Status `Done` in the work `STATE.md` `## Tasks Status` table.
If any dependency is not Done → **STOP.** List which dependencies are pending.

### Check 3: Read Minimum Grade

Read `.aid/knowledge/STATE.md` → extract `**Minimum Grade:**` value.
This is the exit criterion for the review loop.

### Check 4: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

### Check 5: Branch Isolation

**One branch per delivery. All tasks in a delivery share the same branch.**

1. Extract `delivery-NNN` from the task's Source field
2. Branch name: `aid/delivery-NNN` (e.g., `aid/delivery-001`)
3. **Look up the project's VCS** from `infrastructure.md § Source Control` (via INDEX.md)
   to determine the correct branch/commit commands.

| Situation | Action |
|-----------|--------|
| Branch doesn't exist | Create it from current HEAD using VCS branch command |
| Branch exists, not checked out | Switch to it |
| Branch exists, already checked out | Continue |

⚠️ **Before creating a new branch:** verify working tree is clean.
If dirty → **STOP.** Ask user to commit or stash first.

**Exception:** RESEARCH and DOCUMENT tasks may not need a branch (no code changes).
If the task only produces `.aid/` artifacts, skip branch isolation.

### Check 6: Determine State

Read the task's row in work `STATE.md` `## Tasks Status` table if it exists. Apply the routing table in `## State Detection` below.

Print the state-entry line and "you are here" map:

**EXECUTE:**
```
[State: EXECUTE] — Running the executor agent to produce task deliverables.
aid-execute  ▸ you are here
  [● EXECUTE ] → [ REVIEW ] → [ FIX ] → [ DONE ]
                                ↑______________|
```

**REVIEW:**
```
[State: REVIEW] — Grading task output against acceptance criteria with a clean-context reviewer.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [● REVIEW ] → [ FIX ] → [ DONE ]
                                 ↑______________|
```

**FIX:**
```
[State: FIX] — Applying CODE-issue fixes and returning to REVIEW.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [✓ REVIEW ] → [● FIX ] → [ DONE ]
                                  ↑______________|
```

**DONE:**
```
[State: DONE] — Grade meets minimum; task complete.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [✓ REVIEW ] → [✓ FIX ] → [● DONE ]
```

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Never assume or infer state from
conversation history. Read the task's row in work `STATE.md` `## Tasks Status`:

| Condition | State |
|-----------|-------|
| No row in Tasks Status (or row absent) | **EXECUTE** (Step 1) |
| Status: `In Progress`, no issues pending | **EXECUTE** (Step 1 — resume) |
| Status: `In Review`, issues listed | **FIX** (Step 3) |
| Status: `Done` | **RE-RUN** (see Re-run below) |

## Inputs

**KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`. Use summaries to decide which
KB docs are relevant to this task, then load them. Let the INDEX guide you.

**Always load (not KB):**
- `.aid/{work}/tasks/task-NNN.md` — primary prompt
- Feature SPEC: `.aid/{work}/features/{feature}/SPEC.md` — Technical Specification
- `.aid/{work}/PLAN.md` — delivery context and **Execution Graph** (dependencies and parallelism)

**Load if exists:**
- `.aid/{work}/known-issues.md` — issues in code the task touches

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| EXECUTE | `references/state-execute.md` | _(type-specific — see state file; delivery-mode uses pool dispatch PD-0→PD-6)_ | → REVIEW |
| REVIEW | `references/state-review.md` | `reviewer` | → FIX (grade < min) / → DONE (grade ≥ min) |
| FIX | `references/state-fix.md` | _(same type as EXECUTE)_ | → REVIEW |
| DONE | _(inline — task complete)_ | `inline` | → halt |
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-execute again` and exit.
For DONE and RE-RUN (Advance: → halt), print the appropriate halt/summary message and exit.

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `canonical/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** from `.aid/knowledge/STATE.md` top-of-file
   `**Heartbeat Interval:** N minutes` (default 1; `0` = disabled).
3. **Pre-create heartbeat file** (always — unconditional, per work-003 traceability):
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt with explicit instruction to update during long phases
   - SKIP only if `**Heartbeat Interval:** 0` (user-explicit opt-out in STATE.md)
4. **Arm 3 L2 timers** (always — even for short ETAs use minimums 60s/120s/180s; never gate on ETA):
   - `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time. Append a row to
  the work `STATE.md ## Calibration Log` section (create section if missing) with
  format `| YYYY-MM-DD | <agent> | <task-id/cycle> | <ETA-band> | <actual> | <notes> |`.
  Dispatch metadata is logged via the Calibration Log appendix in STATE.md (per work-003 traceability rule — never optional, never "if tracked").
  Delete heartbeat file.
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

## Quality Checklist

- [ ] Task Type read correctly from task file
- [ ] On correct delivery branch (or skipped for RESEARCH/DOCUMENT-only tasks)
- [ ] KB docs loaded via INDEX.md (not hardcoded)
- [ ] Type-specific rules followed
- [ ] Acceptance criteria from task all met
- [ ] Scope boundary respected (no extra work)
- [ ] Reviewer graded using deterministic rubric (separate agent, clean context)
- [ ] Reviewer did NOT fix anything — only graded and listed issues
- [ ] ALL issues presented to user (not just CODE)
- [ ] Non-CODE issues marked as Loopback with target phase in work STATE.md
- [ ] No silent workarounds — impediments documented
- [ ] Commit messages reference task-NNN (where applicable)
- [ ] Work STATE.md `## Tasks Status` row has full review history
