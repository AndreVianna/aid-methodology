---
name: aid-detail
description: >
  Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit.
  The ultimate breakdown. Detects task types (RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) from SPEC signals. One type per task.
  Builds execution graph per delivery with explicit dependencies and parallelism.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
argument-hint: "work-001 (required if multiple works)  [--reset] clear tasks/"
---

# Detail — The Ultimate Breakdown

Break each deliverable from PLAN.md into small, sequential, testable tasks.
Each task = one agent session = one reviewable unit = one human review.

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

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

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
2. **Dependency-driven.** Tasks declare what they depend on. Independent tasks can run in parallel.
3. **Each task = one reviewable unit.** Human reviews and approves before next task starts.
4. **No new decisions.** Everything is already in PLAN + SPECs. Detail just slices.

## Task Types

Every task has exactly ONE type. Never mix types in a single task.

| Type | What it produces | When Detail creates it |
|------|-----------------|----------------------|
| **RESEARCH** | Findings document, comparison, recommendation | Feature has `Spike Needed` in STATE.md, or unknowns need investigation |
| **DESIGN** | Mockups, wireframes, interaction flows | Feature has UI Specs in SPEC.md |
| **IMPLEMENT** | Code + unit tests | Feature has Data Model / Feature Flow / Layers in SPEC.md |
| **TEST** | Integration/E2E/UI/load tests + results | Feature has integration points or testable acceptance criteria |
| **DOCUMENT** | ADRs, API docs, runbooks, diagrams | Significant architectural decision or complex setup |
| **MIGRATE** | Migration scripts + rollback + runbook | Feature has data model changes affecting existing data |
| **REFACTOR** | Restructured code, same behavior | Feature requires restructuring before implementation |
| **CONFIGURE** | Config files, CI/CD, infra-as-code | Feature requires environment or infrastructure setup |

### Type Detection Rules

When proposing tasks, the agent reads the feature SPEC and automatically detects types:

1. **Spike Needed** in feature STATE.md → RESEARCH task first
2. **UI Specs** section in SPEC.md → DESIGN task before IMPLEMENT
3. **Data Model / Feature Flow / Layers & Components** → IMPLEMENT task(s)
4. **Integration points / acceptance criteria** → TEST task(s) after IMPLEMENT
5. **Major architectural decision** → DOCUMENT task (ADR)
6. **Data model changes to existing tables/collections** → MIGRATE task before IMPLEMENT
7. **Code restructuring needed before feature work** → REFACTOR task first
8. **Environment/config setup required** → CONFIGURE task early in sequence

### Type Separation Rule

**One task = one type. No exceptions.**

If the agent proposes a task that mixes types, it must split:
- ❌ "Build login form + write E2E tests" → split into IMPLEMENT + TEST
- ❌ "Research auth + implement auth" → split into RESEARCH + IMPLEMENT
- ❌ "Migrate schema + update code" → split into MIGRATE + IMPLEMENT

### Natural Ordering Within a Delivery

Default sequence (the agent proposes this, user can reorder):

```
RESEARCH → DESIGN → CONFIGURE → MIGRATE → REFACTOR → IMPLEMENT → TEST → DOCUMENT
```

Not rigid. Not all types appear in every delivery. The user adjusts during discussion.

## Task File Format

```markdown
# task-{id}: {Title}

**Type:** RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE

**Source:** feature-NNN-{name} → delivery-{x}

**Depends on:** task-{id} [, task-{id}] | — (none)

**Scope:**
- {what to produce or modify — depends on type}

**Acceptance Criteria:**
- [ ] Criterion 1 — concrete, testable
- [ ] Criterion 2 — concrete, testable
```

Six sections. Nothing else.

**Quality gate cascade:** Every task inherits:
1. **Project baseline** from REQUIREMENTS.md §6 (unit test minimum, linting standard)
2. **Feature-specific requirements** from the SPEC.md quality sections (if any)

Include these in Acceptance Criteria when writing tasks. Don't repeat the
full baseline — reference it: "All §6 quality gates pass." Add feature-specific
criteria explicitly when the SPEC calls for them (e.g., "explicit tests for
all 5 auth edge cases per SPEC").

**Type-specific default criteria:** The agent adds these unless the task explicitly overrides:
- IMPLEMENT: "Unit tests for all new public methods/endpoints" + "All existing tests still pass" + "Build passes"
- TEST: "Tests are deterministic" + "Clean setup/teardown" + "All acceptance criteria from source feature covered"
- MIGRATE: "Migration is reversible" + "Migration is idempotent" + "Data integrity verified"
- REFACTOR: "All tests pass before AND after" + "No behavior change"
- CONFIGURE: "Configuration is idempotent" + "No plaintext secrets"
- RESEARCH: "At least 2 alternatives compared" + "Sources cited" + "Actionable recommendation"
- DESIGN: "Design system tokens used" + "Responsive behavior shown (if applicable)"
- DOCUMENT: "Accuracy verified against current codebase"

---

## FIRST RUN — The Loop

### Step 1: Propose Tasks for First Deliverable

Read the first deliverable from PLAN.md. Identify its features, read their SPECs.
Propose a sequential task breakdown:

```
**delivery-001: {Name}**

I'm proposing {n} tasks:

1. **task-001: {title}** [RESEARCH]
   Scope: {brief description}
   Criteria: {brief summary}

2. **task-002: {title}** [DESIGN]
   Scope: {brief description}
   Criteria: {brief summary}

3. **task-003: {title}** [IMPLEMENT]
   Scope: {brief description}
   Criteria: {brief summary}

4. **task-004: {title}** [TEST]
   Scope: {brief description}
   Criteria: {brief summary}

What do you think? We can discuss:
- **Type** — should any task be a different type? Am I mixing types?
- **Size** — is any task too big or too small?
- **Scope** — should something move between tasks?
- **Dependencies** — are the dependencies right? Can anything run in parallel?
- **Criteria** — are the acceptance criteria concrete enough?
```

### Step 2: Discuss

The developer may:
- **Retype** → "task-002 should be MIGRATE not IMPLEMENT"
- **Split** → "task-002 is too big, separate the migration from the model"
- **Merge** → "003 and 004 are tiny, combine them" (only if SAME type)
- **Reorder** → "swap 002 and 003 — need the service first"
- **Scope change** → "task-001 should also include the config file"
- **Criteria change** → "add index creation to task-001's criteria"
- **Approve** → "looks good"

⚠️ **Merge rule:** only merge tasks of the same type. Never merge across types.

Respond to each concern, re-present affected tasks. Loop until approved.

### Step 3: Write and Review

Once approved:
1. Write task files to `.aid/{work}/tasks/`
2. **Review immediately:** Do the tasks hold up?
   - Does each task have what it needs from the previous?
   - Any gap where something is used before it's created?
   - Scope aligned with what the SPECs actually say?
   - Criteria concrete enough to verify?

Use the universal rubric (`../../templates/grading-rubric.md`). Classify each issue
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

### Step 5: Build Execution Graph

After ALL deliverables are detailed, build the execution graph for each delivery.
Write it as a new section in PLAN.md under the corresponding delivery.

For each delivery, produce TWO tables:

```markdown
#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002 |
| task-005 | task-003, task-004 |

| Can Be Done In Parallel |
|------------------------|
| task-003, task-004 |
```

**Dependency rules:**
- Every task except the first MUST have at least one dependency
- Dependencies are determined by what each task needs from previous tasks
  (output files, schema changes, service availability, etc.)
- If two tasks share the same dependencies but don't depend on each other → parallel
- The parallel table lists groups of tasks that can safely run concurrently

**This graph is what `/aid-execute` reads to determine task ordering and parallelism.**

### Step 6: Final Summary

```
All tasks written:

delivery-001: {Name} → tasks 001–004
delivery-002: {Name} → tasks 005–008

Total: {n} tasks in {m} deliverables.
Execution graphs written to PLAN.md.
```

---

## REVIEW (re-run on existing tasks)

`tasks/` has files and were previously completed.

**Ask first:** _"Tasks for this work are already complete. Do you want to reopen for review?
Is there something specific you want to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the review.

Enter **the same loop at step 4** — review tasks against
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

Use the universal rubric (`../../templates/grading-rubric.md`). Classify each issue
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

## Project Management Sync (conditional)

If `infrastructure.md § Project Management` defines a tool:
- When tasks are approved → create Tickets/Work Items in the PM tool
- Link each ticket to the corresponding Sprint (delivery) and Epic (work)

If no PM tool → skip.

## Quality Checklist

- [ ] Every deliverable in PLAN.md has corresponding tasks
- [ ] Every task has exactly ONE type (no mixing)
- [ ] Every task traces to a feature SPEC and deliverable
- [ ] Every task has concrete, testable acceptance criteria
- [ ] Every task has an explicit scope boundary
- [ ] Every task declares its dependencies (or `—` for none)
- [ ] Execution graph written to PLAN.md for each delivery
- [ ] Parallel groups are truly independent (no shared state)
- [ ] Each task is small enough for one agent session
- [ ] Type-specific default criteria included where applicable
- [ ] RESEARCH/DESIGN tasks come before their dependent IMPLEMENT tasks
- [ ] TEST tasks come after their dependent IMPLEMENT tasks
- [ ] Each deliverable's tasks were reviewed after writing (step 4)
- [ ] All task files in `.aid/{work}/tasks/`
