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
| `--reset` | Delete all files in `tasks/` and start fresh. |

## Pre-flight

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-interview` first."

### Check 2: Verify PLAN.md Exists

1. Check for `aid-workspace/{work}/PLAN.md`
2. If missing → **STOP.** "No PLAN.md found. Run `/aid-plan` first."

### Check 3: Detect State

- If `tasks/` is empty or doesn't exist → **FIRST RUN** (Step 1)
- If `tasks/` has files → **REVIEW** (Step 5)

## Inputs

Read before starting:

- **PLAN.md** — deliverables, ordering, dependencies
- **Feature SPECs** — all `features/*/SPEC.md` within the work
- **KB (selective)** — `aid-workspace/knowledge/architecture.md`, `module-map.md`, `coding-standards.md`

## The Rules

1. **Always small.** Every task fits one agent session. If it doesn't, split it.
2. **Sequential within a deliverable.** Tasks execute in order — each builds on the previous.
3. **Each task = one PR.** A human reviews and merges before the next task starts.
4. **No new decisions.** Everything in the task is already defined in PLAN + SPECs. Detail just slices.

## Task File Format

```markdown
# task-{id}: {Title}

**Source:** feature-NNN-{name} → delivery-{x}

**Scope:**
- `path/to/File.java` (create)
- `path/to/OtherFile.java` (modify)
- `test/path/to/FileTest.java` (create)

**Acceptance Criteria:**
- [ ] Criterion 1 — concrete, testable
- [ ] Criterion 2 — concrete, testable
- [ ] All existing tests still pass
```

Four sections. Nothing else.

---

## FIRST RUN — Steps 1–4

### Step 1: Propose Tasks for First Deliverable

Read the first deliverable from PLAN.md. Identify its features and read their SPECs.
Propose a sequential task breakdown:

```
**delivery-001: {Name}**

I'm proposing {n} tasks:

1. **task-001: {title}**
   Scope: {brief scope description}
   Criteria: {brief criteria summary}

2. **task-002: {title}**
   Scope: {brief scope description}
   Criteria: {brief criteria summary}

3. ...

What do you think? We can discuss:
- **Size** — is any task too big or too small?
- **Scope** — should something move between tasks?
- **Sequence** — is the order right?
- **Criteria** — are the acceptance criteria concrete enough?
```

### Step 2: Discussion Loop

The user discusses. They might say:
- "task-002 is too big, split the migration from the model"
- "merge 003 and 004, they're tiny"
- "the criteria for task-001 should include index creation"
- "swap 002 and 003 — we need the service before the migration"
- "looks good" / "approve"

Respond to each concern:
- **Split** → break the task, re-present the affected tasks
- **Merge** → combine, re-present
- **Reorder** → move, explain dependency impact if any
- **Criteria change** → update, re-present the task
- **Scope change** → adjust, re-present

Keep discussing until the user approves the deliverable's tasks.

### Step 3: Write and Continue

Once approved for a deliverable:
1. Write the task files to `aid-workspace/{work}/tasks/`
2. Move to the next deliverable → back to Step 1

Task numbering is global (task-001 through task-N across all deliverables).

### Step 4: Final Summary

After all deliverables are detailed:

```
All tasks written:

delivery-001: {Name} → tasks 001–004
delivery-002: {Name} → tasks 005–008
delivery-003: {Name} → tasks 009–011

Total: {n} tasks in {m} deliverables.
```

---

## REVIEW — Steps 5–7

When `tasks/` already has files, the agent reviews instead of starting from scratch.

### Step 5: Compare and Grade

Re-read PLAN.md, all feature SPECs, and all existing task files. Check:

1. **PLAN.md changed** — deliverables added, removed, or resequenced?
2. **SPECs changed** — feature content updated?
3. **Orphan tasks** — tasks referencing deliverables/features that no longer exist?
4. **Missing tasks** — new deliverables or features with no corresponding tasks?
5. **Sequence broken** — does the task order still hold given changes?

Grade:

| Grade | Meaning |
|-------|---------|
| **A** | Tasks are current. Nothing to change. |
| **B** | Minor drift. 1–3 tasks need updating. |
| **C** | Significant changes. New tasks needed or reordering required. |
| **D** | Major restructuring. Recommend `--reset`. |

### Step 6: Present Findings

```
Review of {work} tasks: Grade **{X}**

**What changed:**
- {finding 1}
- {finding 2}

**Proposed updates:**
- task-003: update scope (SPEC added new field)
- task-007: remove (delivery-003 was dropped)
- NEW task-008: {title} (new delivery-003 feature)

Let's discuss.
```

### Step 7: Discussion Loop

Same as Step 2 — discuss size, scope, sequence, criteria until the user approves.
Apply changes: update affected task files, create new ones, delete orphans, renumber if needed.

---

## Feedback Loops

- **→ Plan:** Plan too vague to decompose → return to `/aid-plan`
- **→ Specify:** SPEC missing detail needed for scope → write Q&A to feature's `STATE.md`
- **→ Discovery:** KB gap → write Q&A to `aid-workspace/knowledge/DISCOVERY-STATE.md`

## Quality Checklist

- [ ] Every deliverable in PLAN.md has corresponding tasks
- [ ] Every task traces to a feature SPEC and deliverable
- [ ] Every task has concrete, testable acceptance criteria
- [ ] Every task has an explicit scope boundary
- [ ] Tasks are sequential within each deliverable
- [ ] Each task is small enough for one agent session
- [ ] "All existing tests still pass" is in every task's criteria
- [ ] All task files live inside `aid-workspace/{work}/tasks/`
