---
name: aid-execute
description: >
  Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type.
  State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum.
  Branch per delivery for isolation.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
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

Read the task's row in work `STATE.md` `## Tasks Status` table if it exists.

| Condition | State |
|-----------|-------|
| No row in Tasks Status (or row absent) | **EXECUTE** (Step 1) |
| Status: `In Progress`, no issues pending | **EXECUTE** (Step 1 — resume) |
| Status: `In Review`, issues listed | **FIX** (Step 3) |
| Status: `Done` | **RE-RUN** (see Re-run below) |

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

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** The state is determined by reading
the task's row in work `STATE.md` `## Tasks Status` (see Check 6 above). Never
assume or infer state from conversation history.

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
| EXECUTE | `references/state-execute.md` | _(type-specific — see state file)_ | → REVIEW |
| REVIEW | `references/state-review.md` | `reviewer` | → FIX (grade < min) / → DONE (grade ≥ min) |
| FIX | `references/state-fix.md` | _(same type as EXECUTE)_ | → REVIEW |
| DONE | _(inline — task complete)_ | `inline` | → halt |
| RE-RUN | `references/state-re-run.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, print `Next: [State: {NEXT}] — run /aid-execute again` and exit.
For DONE and RE-RUN (Advance: → halt), print the appropriate halt/summary message and exit.

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
