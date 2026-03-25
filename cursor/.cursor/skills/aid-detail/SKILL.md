---
name: aid-detail
description: >
  Break deliverables into small, sequential, testable tasks — each one a PR.
  The ultimate breakdown. Use when PLAN.md is complete and you need executable tasks.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
argument-hint: "work-001 (required if multiple works)  [--reset] clear tasks/"
---

# Detail — The Ultimate Breakdown

Break each deliverable from PLAN.md into small, sequential, testable tasks.
Each task = one agent session = one PR = one human review.

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    PLAN.md                 ← roadmap with deliverables (read — must exist)
    features/
      feature-NNN-{name}/
        SPEC.md             ← per-feature tech spec (read)
    tasks/                  ← OUTPUT: sequential task files
      task-001.md
      task-002.md
      ...
```

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Detail a specific work. Required if multiple works exist. |
| *(no arg)* | Auto-selects if only one work exists. |
| `--reset` | Delete all files in `tasks/` and regenerate from scratch. |

## Pre-flight

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-interview` first."

### Check 2: Verify PLAN.md Exists

1. Check for `aid-workspace/{work}/PLAN.md`
2. If missing → **STOP.** "No PLAN.md found. Run `/aid-plan` first."

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell user to switch out of Plan Mode.

## Inputs

Read these before generating tasks:

- **PLAN.md** — deliverables, ordering, dependencies
- **Feature SPECs** — all `features/*/SPEC.md` within the work
- **KB (selective)** — `aid-workspace/knowledge/architecture.md`, `module-map.md`, `coding-standards.md`

## The Rules

1. **Always small.** Every task fits one agent session. If it wouldn't, split it.
2. **Sequential within a deliverable.** Tasks execute in order — each builds on the previous.
3. **Each task = one PR.** A human reviews and merges before the next task starts.
4. **No new decisions.** Everything in the task is already defined in PLAN + SPECs. Detail just slices.

## Process

### 1. Read Plan and SPECs

For each deliverable in PLAN.md:
- Identify which features it includes
- Read each feature's SPEC.md (Data Model, Feature Flow, Layers & Components, etc.)
- Understand the technical scope

### 2. Decompose into Tasks

For each deliverable, break the work into sequential tasks.

**How to slice:**
- Start with foundation (schema, models, core types)
- Then build upward (services, handlers, middleware)
- Then integration points (controllers, endpoints, UI)
- End with integration/validation (E2E tests, smoke tests)

Each task gets a file: `aid-workspace/{work}/tasks/task-{id}.md`

### Task File Format

```markdown
# task-{id}: {Title}

**Source:** feature-NNN-{name} → delivery-{x}

**Files:**
- `path/to/File.java` (create)
- `path/to/OtherFile.java` (modify)
- `test/path/to/FileTest.java` (create)

**Acceptance Criteria:**
- [ ] Criterion 1 — concrete, testable
- [ ] Criterion 2 — concrete, testable
- [ ] Criterion 3 — concrete, testable
- [ ] All existing tests still pass
```

That's it. Four sections. Nothing else.

### 3. Verify Sequence

Walk through the task list in order:
- Does each task have what it needs from the previous one?
- Is there a gap where something is used before it's created?
- Could any task be split further? (If >5 files, probably yes.)

### 4. Present to User

```
Here's the task breakdown for {work}:

**delivery-001: {Deliverable Name}**
  1. task-001: {title} — {n} files
  2. task-002: {title} — {n} files
  3. task-003: {title} — {n} files

**delivery-002: {Deliverable Name}**
  4. task-004: {title} — {n} files
  5. task-005: {title} — {n} files

[1] Approve
[2] Adjust — tell me what to split, merge, or reorder
```

### 5. Adjustment Loop

If user chooses [2]:
- **Split** — "task-003 is too big, break it into schema + service"
- **Merge** — "task-004 and task-005 are too small, combine them"
- **Reorder** — "move the test task before the integration task"

Apply changes, renumber, re-present. Loop until approved.

### 6. Write Files

Create all `task-{id}.md` files in `aid-workspace/{work}/tasks/`.
Task numbering is global across all deliverables (task-001 through task-N),
ordered by execution sequence.

## Feedback Loops

- **→ Plan:** Plan too vague to decompose → return to `/aid-plan`
- **→ Specify:** SPEC missing detail needed for file list → write Q&A to feature's `STATE.md`
- **→ Discovery:** KB gap → write Q&A to `aid-workspace/knowledge/DISCOVERY-STATE.md`

## Re-run = Review

If `tasks/` already has files when `/aid-detail` is run, the agent reviews
instead of generating from scratch.

### Step 1: Load Current State

Re-read PLAN.md, all feature SPECs, and all existing task files.

### Step 2: Check for Changes

1. **PLAN.md changed** — deliverables added, removed, or resequenced?
2. **SPECs changed** — feature content updated? (check Change Log dates)
3. **Orphan tasks** — tasks referencing deliverables/features that no longer exist?
4. **Missing tasks** — new deliverables or features with no corresponding tasks?
5. **Sequence invalid** — does the task order still make sense given changes?

### Step 3: Grade

| Grade | Meaning | Action |
|-------|---------|--------|
| **A** | Tasks are current. No changes detected. | Print summary, done. |
| **B** | Minor changes. 1–3 tasks need update. | Present changes, fix inline. |
| **C** | Significant changes. Tasks need reordering or new tasks needed. | Present findings, regenerate affected section. |
| **D** | Major changes. Plan restructured, most tasks orphaned. | Recommend `--reset`. |

### Step 4: Present and Apply

Present findings with specific changes needed. Apply after user approval.
Update affected task files. Renumber if sequence changed.

## Quality Checklist

- [ ] Every deliverable in PLAN.md has corresponding tasks
- [ ] Every task traces to a feature SPEC and deliverable
- [ ] Every task has concrete, testable acceptance criteria
- [ ] Every task has an explicit file list (scope boundary)
- [ ] Tasks are sequential — each builds on the previous
- [ ] No task touches more than ~5 files (split if larger)
- [ ] "All existing tests still pass" is in every task's criteria
- [ ] All task files live inside `aid-workspace/{work}/tasks/`
