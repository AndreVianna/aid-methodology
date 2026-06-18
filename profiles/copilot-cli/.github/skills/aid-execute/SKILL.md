---
name: aid-execute
description: >
  Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type.
  State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum.
  Branch per delivery for isolation.
allowed-tools: Read, Glob, Grep, Write, Edit, shell
argument-hint: "work-001 (required if multiple works)  task-001 (required)"
---

# Execute Task

Read the type. Do the work. Review it. Fix it. Ship it.

## ⚠️ Pre-flight Checks

### Check 1: Locate Work and Task

1. Read first arg: if it starts with `work-` → use that work directory; if it starts with `task-` → treat as shorthand (single-work auto-select below)
2. If work arg not provided (or shorthand): if single work exists → auto-select; if multiple works → list them, ask user to choose
3. Read second arg (or first arg when shorthand): the `task-NNN` identifier
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

Run `bash .github/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A` to resolve the minimum grade for this skill (`.aid/settings.yml` is the source).
This is the exit criterion for the review loop.

### Check 4: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

### Check 5: Branch Isolation

**One branch per delivery. All tasks in a delivery share the same branch.**

1. Extract `delivery-NNN` from the task's Source field
2. Branch name: `aid/{work}-delivery-NNN` (e.g., `aid/{work}-delivery-001`)
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
| REVIEW | `references/state-review.md` | `aid-reviewer` (Small tier, quick-check only — no grade loop per FR2) | → DONE |
| FIX | `references/state-fix.md` | _(same type as EXECUTE)_ | → REVIEW |
| DONE | _(inline — task complete)_ | `inline` | → halt |
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |
| DELIVERY-GATE | `references/state-delivery-gate.md` | `aid-reviewer` (tier = complexity score) | → halt (grade ≥ min) / → FIX (grade < min) |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

## Dispatch Protocol

This skill follows the L1+L2+L3 subagent-visibility protocol (work-003 traceability —
heartbeats, ETA timers, calibration). The full checklist lives in
`.github/aid/templates/dispatch-protocol-checklist.md`; read it before any subagent
dispatch in this skill.

## Workspace

```
.aid/
  knowledge/                ← shared KB (via INDEX.md)
    STATE.md                ← Q&A, Review History (settings → .aid/settings.yml)
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
create branch aid/{work}-delivery-001
  → /aid-execute work-001 task-001 [RESEARCH]      ← investigate → review → ✅
  → /aid-execute work-001 task-002 [DESIGN]        ← mockup → review → ✅
  → /aid-execute work-001 task-003 [IMPLEMENT]  ┐
  → /aid-execute work-001 task-004 [IMPLEMENT]  ┘  ← parallel (both depend on task-002)
  → /aid-execute work-001 task-005 [TEST]          ← waits for task-003 + task-004
  → /aid-execute work-001 task-006 [DOCUMENT]      ← ADR → review → ✅
  → merge to main
```

All tasks in a delivery accumulate on the same branch.
RESEARCH and DOCUMENT tasks that produce only `.aid/` artifacts may skip branching.

**Delivery-mode pool dispatch (FR6):** When `/aid-execute` is invoked for a
delivery (not a single task), a continuous pool dispatcher replaces the serial
loop. Full pool dispatch spec — including the `run_in_background` capability
probe and graceful degradation — lives in
`references/state-execute.md § EXECUTE-WAVE: Pool Dispatch (PD-0 through PD-6)`.

**Graceful degradation:** On hosts where the Agent tool's `run_in_background`
parameter is not supported, `aid-execute` detects this via a capability probe
(PD-0 step 2 in `references/state-execute.md`) and automatically falls back to
effective `MaxConcurrent=1`. A user-visible notice is printed:

```
[degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
```

The degradation event is also appended to the work `STATE.md ## Calibration Log`.
The pool algorithm runs identically at pool size 1 — no behavioral difference
other than one task in flight at a time (sequential execution).

### EXECUTE-WAVE: AC4 Sub-unit Drill-down

When executing a delivery wave, render a sub-unit snapshot after each sub-unit transition.

> **Authoritative spec:** `references/state-execute-drilldown.md`
> contains the full snapshot format, status-icon vocabulary, re-render trigger
> rules (1-second coalescing), serial-task fallback semantics, and failure
> tolerance. This SKILL.md section is a brief router-level pointer; do not
> duplicate the spec here — read it from state-execute-drilldown.md so the two
> stay in sync.

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
- Grade ≥ minimum grade (from `bash .github/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`)
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
