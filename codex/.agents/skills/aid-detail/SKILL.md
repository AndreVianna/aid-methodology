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

## The Loop

Each deliverable follows the same cycle:

```
1. PROPOSE  → agent proposes task breakdown for a deliverable
2. DISCUSS  → developer and agent refine (size, scope, sequence, criteria)
3. WRITE    → save agreed tasks to files
4. REVIEW   → grade tasks against SPEC/PLAN — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing tasks.**

## Workspace

```
.aid/
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

1. Check for `.aid/{work}/PLAN.md`
2. If missing → **STOP.** "No PLAN.md found. Run `/aid-plan` first."


### Check 4: Detect State

- `tasks/` empty or missing → **FIRST RUN** (Step 1)
- `tasks/` has files → **REVIEW** (enter loop at step 4)

## Inputs

- **PLAN.md** — deliverables, ordering, dependencies
- **Feature SPECs** — all `features/*/SPEC.md` within the work
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, use summaries to pull
  relevant docs (typically architecture, module-map, coding-standards — but let the INDEX guide you)

## The Rules

1. **Always small.** Every task fits one agent session. If it doesn't, split it.
2. **Sequential within a deliverable.** Each builds on the previous.
3. **Each task = one PR.** Human reviews and merges before next task starts.
4. **No new decisions.** Everything is already in PLAN + SPECs. Detail just slices.

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
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes (zero errors, zero warnings)
- [ ] Lint passes (zero violations)
```

Four sections. Nothing else.

**Quality gate cascade:** Every task inherits:
1. **Project baseline** from REQUIREMENTS.md §6 (unit test minimum, linting standard)
2. **Feature-specific requirements** from the SPEC.md quality sections (if any)

Include these in Acceptance Criteria when writing tasks. Don't repeat the
full baseline — reference it: "All §6 quality gates pass." Add feature-specific
criteria explicitly when the SPEC calls for them (e.g., "explicit tests for
all 5 auth edge cases per SPEC").

---

## FIRST RUN — The Loop

### Step 1: Propose Tasks for First Deliverable

Read the first deliverable from PLAN.md. Identify its features, read their SPECs.
Propose a sequential task breakdown:

```
**delivery-001: {Name}**

I'm proposing {n} tasks:

1. **task-001: {title}**
   Scope: {brief description}
   Criteria: {brief summary}

2. **task-002: {title}**
   Scope: {brief description}
   Criteria: {brief summary}

What do you think? We can discuss:
- **Size** — is any task too big or too small?
- **Scope** — should something move between tasks?
- **Sequence** — is the order right?
- **Criteria** — are the acceptance criteria concrete enough?
```

### Step 2: Discuss

The developer may:
- **Split** → "task-002 is too big, separate the migration from the model"
- **Merge** → "003 and 004 are tiny, combine them"
- **Reorder** → "swap 002 and 003 — need the service first"
- **Scope change** → "task-001 should also include the config file"
- **Criteria change** → "add index creation to task-001's criteria"
- **Approve** → "looks good"

Respond to each concern, re-present affected tasks. Loop until approved.

### Step 3: Write and Review

Once approved:
1. Write task files to `.aid/{work}/tasks/`
2. **Review immediately:** Do the tasks hold up?
   - Does each task have what it needs from the previous?
   - Any gap where something is used before it's created?
   - Scope aligned with what the SPECs actually say?
   - Criteria concrete enough to verify?

Use the universal rubric (`../templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from DISCOVERY-STATE.md) | Move to next deliverable. |
| Grade < minimum, fixable | Back to Propose with findings. |

```
✅ delivery-001 tasks written and verified — sequence holds, criteria testable.
Moving to delivery-002.
```

### Step 4: Next Deliverable

Move to next deliverable → same loop (steps 1–3). Task numbering is global
across all deliverables (task-001 through task-N).

### Step 5: Final Summary

```
All tasks written:

delivery-001: {Name} → tasks 001–004
delivery-002: {Name} → tasks 005–008

Total: {n} tasks in {m} deliverables.
```

---

## REVIEW (re-run on existing tasks)

`tasks/` has files. Enter **the same loop at step 4** — review tasks against
current PLAN.md and SPECs.

### Load Current State

Re-read PLAN.md, all feature SPECs, all existing task files.

### Review Each Deliverable's Tasks

For each deliverable, check its corresponding tasks:

1. **PLAN.md changed** — deliverables added, removed, resequenced?
2. **SPECs changed** — feature content updated since tasks were written?
3. **Orphan tasks** — tasks referencing deliverables/features that no longer exist?
4. **Missing tasks** — new deliverables/features with no corresponding tasks?
5. **Sequence broken** — task order invalid given changes?

### Grade Overall

Use the universal rubric (`../templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

Compare to minimum grade from DISCOVERY-STATE.md.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. |
| Grade < minimum, tasks fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, most tasks orphaned | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.
Update task files, create new ones, delete orphans, renumber if needed.

---

## Feedback Loops

- **→ Plan:** Plan too vague to decompose → return to `/aid-plan`
- **→ Specify:** SPEC missing detail for scope → write Q&A to feature's `STATE.md`
- **→ Discovery:** KB gap → write Q&A to `.aid/knowledge/DISCOVERY-STATE.md`

## Quality Checklist

- [ ] Every deliverable in PLAN.md has corresponding tasks
- [ ] Every task traces to a feature SPEC and deliverable
- [ ] Every task has concrete, testable acceptance criteria
- [ ] Every task has an explicit scope boundary
- [ ] Tasks are sequential within each deliverable
- [ ] Each task is small enough for one agent session
- [ ] "All existing tests still pass" is in every task's criteria
- [ ] Each deliverable's tasks were reviewed after writing (step 4)
- [ ] All task files in `.aid/{work}/tasks/`
