---
name: aid-detail
description: >
  Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit.
  The ultimate breakdown. Detects task types (RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) from SPEC signals. One type per task.
  Builds execution graph per delivery with explicit dependencies and parallelism.
  State machine: FIRST-RUN → REVIEW → DONE.
allowed-tools: Read, Glob, Grep, Write, Edit, Terminal
argument-hint: "work-001 (required if multiple works)  [--reset] clear deliveries/delivery-NNN/tasks/"
---

# Detail — The Ultimate Breakdown

Break each deliverable from PLAN.md into small, sequential, testable tasks.
Each task = one agent session = one reviewable unit = one human review.

## ⚠️ Pre-flight Checks

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-describe` first."

### Check 2: Verify PLAN.md Exists

1. Check for `.aid/{work}/PLAN.md`
2. If missing → **STOP.** "No PLAN.md found. Run `/aid-plan` first."

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Always read actual files on disk.

- No `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` exists under `.aid/{work}/` → **FIRST-RUN**
- At least one `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` exists → **REVIEW**
- Tasks complete and grade ≥ minimum → **DONE**

Print the state-entry line and "you are here" map:

**FIRST-RUN:**
```
[State: FIRST-RUN] — No task files yet; begin proposing task breakdown per deliverable.
aid-detail  ▸ you are here
  [● FIRST-RUN ] → [ REVIEW ] → [ DONE ]
```

**REVIEW:**
```
[State: REVIEW] — Existing tasks found; re-review against current PLAN.md and SPECs.
aid-detail  ▸ you are here
  [✓ FIRST-RUN ] → [● REVIEW ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Task list approved and meets minimum grade.
aid-detail  ▸ you are here
  [✓ FIRST-RUN ] → [✓ REVIEW ] → [● DONE ]
```

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FIRST-RUN | `references/first-run.md` | `aid-architect` | `→ REVIEW` |
| REVIEW | `references/review.md` | `aid-reviewer` | `→ DONE` |
| DONE | — | `inline` | `→ halt` |

Load the `Detail` file for the detected state and execute it.

On state completion, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit (DONE prints the task summary).
