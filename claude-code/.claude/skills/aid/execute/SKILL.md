---
name: execute
description: >
  Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST,
  DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type.
  State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum.
  Branch per delivery for isolation.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: developer
argument-hint: "task-001 (required)  [work-001 if multiple works]"
---

# Execute Task

Read the type. Do the work. Review it. Fix it. Ship it.

## State Machine

```
EXECUTE → REVIEW → [present all issues] → FIX → back to REVIEW
                                        → DONE when grade ≥ minimum
```

Review is a separate step with its own agent (clean context).
Fix is a separate step. Reviewer NEVER fixes — only grades and lists issues.

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

## Grading

Read `../../../templates/grading-rubric.md` for the universal grading scale.
Read minimum grade from `.aid/knowledge/DISCOVERY-STATE.md` field `**Minimum Grade:**`.

## Workspace

```
.aid/
  knowledge/                ← shared KB (via INDEX.md)
    DISCOVERY-STATE.md      ← minimum grade
  work-NNN-{name}/
    PLAN.md                 ← delivery context
    known-issues.md         ← issues to watch for
    tasks/
      task-NNN.md           ← PRIMARY INPUT (has Type field)
      task-NNN-STATE.md     ← execution state (created here)
    features/
      feature-NNN-{name}/
        SPEC.md             ← architectural constraints
```

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN` | Required. Which task to execute. |
| `work-NNN` | Required if multiple works exist. |

## Pre-flight

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
Check that all tasks listed in `Depends on:` have Status `Done` in their STATE files.
If any dependency is not Done → **STOP.** List which dependencies are pending.

### Check 3: Read Minimum Grade

Read `.aid/knowledge/DISCOVERY-STATE.md` → extract `**Minimum Grade:**` value.
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

Read `task-NNN-STATE.md` if it exists.

| Condition | State |
|-----------|-------|
| No STATE file exists | **EXECUTE** (Step 1) |
| Status: `In Progress`, no issues pending | **EXECUTE** (Step 1 — resume) |
| Status: `In Review`, issues listed | **FIX** (Step 3) |
| Status: `Done` | **RE-RUN** (see Re-run below) |

---

## Re-run (Status: Done)

When the task is already `Done` and the user runs `/aid:execute task-NNN` again:

1. Ask: _"This task is marked Done. Do you want to reopen it for review?
   Is there something specific you want to re-examine?"_
2. If user confirms → set Status to `In Review` in STATE.md, proceed to Step 2 (REVIEW)
3. If user has a specific concern → record it as context for the reviewer

---

## Inputs

**KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`. Use summaries to decide which
KB docs are relevant to this task, then load them. Let the INDEX guide you.

**Always load (not KB):**
- `.aid/{work}/tasks/task-NNN.md` — primary prompt
- Feature SPEC: `.aid/{work}/features/{feature}/SPEC.md` — Technical Specification
- `.aid/{work}/PLAN.md` — delivery context and **Execution Graph** (dependencies and parallelism)

**Load if exists:**
- `.aid/{work}/known-issues.md` — issues in code the task touches

---

## Step 1: EXECUTE (Do the Work)

Create `task-NNN-STATE.md` from template (`../../../templates/implementation-state.md`).
Set Status to `In Progress`.

Dispatch a coding/working agent with assembled context.
The agent's behavior depends on the task Type.

Read `references/task-type-rules.md` — load the section matching the task's Type for the full agent instructions.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
When execution passes → update STATE.md Status to `In Review` → proceed to Step 2.

---

## Step 2: REVIEW (Grade)

Dispatch a **separate reviewer agent** with clean context (no execution knowledge).

**Reviewer receives:**
- All changes/artifacts produced by the task
- task-NNN.md — acceptance criteria and scope
- Feature SPEC — expected behavior
- KB docs via INDEX.md (as relevant to the type)
- Grading rubric (`../../../templates/grading-rubric.md`)

Read `references/reviewer-guide.md` for severity/source classifications and type-specific review checklists.

**Grade is CALCULATED, not judged.** Count issues per severity, apply rubric.
Worst issue dominates.

**⚠️ The reviewer NEVER fixes anything.** It only grades and lists issues.

**Output:** Update `task-NNN-STATE.md`:
- Set Cycle number (increment)
- Set Grade
- Write all issues under `### Issues` with severity, source, description
- Append cycle summary to `## Review History`

---

## Step 3: Present and Route

**Present ALL issues to the user** regardless of source.

```
[Review — Cycle {N} — Grade: {grade} — Minimum: {min}]

Issues found:

| # | Severity | Source | Description |
|---|----------|--------|-------------|
| 1 | Medium | CODE | ... |
| 2 | Low | TASK | ... |

{If grade ≥ minimum:}
✅ Grade meets minimum. Marking as Done.

{If grade < minimum:}
Grade below minimum. Next steps:
- CODE issues (#1, #3): I'll fix these automatically.
- TASK issues (#2): This needs a task update. {explain}
- SPEC issues: Would require re-running /aid:specify.
- KB issues: Would require re-running /aid:discover.

Proceed with auto-fix of CODE issues?
```

**Routing:**

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Mark all issues as `Accepted`. Set Status to `Done`. ✅ |
| Grade < minimum | Auto-fix CODE issues (Step 4). Present non-CODE for user decision. |

**Non-CODE issues (TASK, SPEC, KB):**
- **TASK** → Present to user with suggestion. User updates task, re-run.
- **SPEC** → Write Q&A to feature STATE.md → suggest `/aid:specify`
- **KB** → Write Q&A to DISCOVERY-STATE.md → suggest `/aid:discover`

Mark non-CODE issues as `Loopback` in STATE.md with target phase.

**If ONLY non-CODE issues remain:** **STOP.** The work is as good as it can be —
the problem is upstream. Present what needs to change and where.

---

## Step 4: FIX

Dispatch agent with:
- Issues from STATE.md where Source = CODE and Status = Pending
- Original task context

**Agent fixes CODE issues only.** Verifies gates still pass.

When done:
1. Mark fixed issues as `Fixed` in STATE.md
2. → **Back to Step 2 (REVIEW)** — fresh reviewer, clean context

**Loop continues until grade ≥ minimum.**

⚠️ **Circuit breaker:** If grade has not improved after 3 consecutive
cycles (same or worse), **STOP.** Something systemic is wrong.

---

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
- **kb-gap** → targeted `/aid:discover` → update KB → retry
- **architecture-conflict** → `/aid:specify` for the feature
- **missing-dependency** → `/aid:detail` (might need another task first)
- **wrong-assumption** → update task or SPEC, retry

After resolving: delete IMPEDIMENT file, retry from Step 1.

---

## Delivery Lifecycle

Execution follows the **Execution Graph** in PLAN.md. Tasks run in dependency order.
Independent tasks (listed in the "Can Be Done In Parallel" table) can run concurrently.

```
create branch aid/delivery-001
  → /aid:execute task-001 [RESEARCH]      ← investigate → review → ✅
  → /aid:execute task-002 [DESIGN]        ← mockup → review → ✅
  → /aid:execute task-003 [IMPLEMENT]  ┐
  → /aid:execute task-004 [IMPLEMENT]  ┘  ← parallel (both depend on task-002)
  → /aid:execute task-005 [TEST]          ← waits for task-003 + task-004
  → /aid:execute task-006 [DOCUMENT]      ← ADR → review → ✅
  → merge to main
```

All tasks in a delivery accumulate on the same branch.
RESEARCH and DOCUMENT tasks that produce only `.aid/` artifacts may skip branching.

---

## Output

- Artifacts appropriate to the task type (code, tests, docs, configs, research, designs)
- Grade ≥ minimum grade (from DISCOVERY-STATE.md)
- Commit messages reference task-NNN (for types that produce commits)
- `task-NNN-STATE.md` with full review history
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
- [ ] Non-CODE issues marked as Loopback with target phase
- [ ] No silent workarounds — impediments documented
- [ ] Commit messages reference task-NNN (where applicable)
- [ ] STATE.md has full review history
