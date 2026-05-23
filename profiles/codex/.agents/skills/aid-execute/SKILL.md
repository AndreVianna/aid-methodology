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

## Grading

The grade is **computed deterministically**, not judged. The reviewer outputs a structured issue list with `[CRITICAL]`/`[HIGH]`/`[MEDIUM]`/`[LOW]`/`[MINOR]` severity tags. The grade follows from the rubric.

- Rubric: `../../templates/grading-rubric.md`
- Script: `../../templates/scripts/grade.sh` — run it on the reviewer's issue list (recorded in the work `STATE.md` `## Tasks Status` table).
- Minimum grade: read from `.aid/knowledge/STATE.md` field `**Minimum Grade:**`

Run the script after the reviewer completes. The script prints the grade. Compare against minimum grade to decide DONE vs FIX.

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

---

## Re-run (Status: Done)

When the task is already `Done` and the user runs `/aid-execute task-NNN` again:

```
[State: RE-RUN] — Task already Done; confirming whether to reopen for review.
aid-execute  ▸ you are here
  [✓ EXECUTE ] → [✓ REVIEW ] → [✓ FIX ] → [✓ DONE ] → [● RE-RUN ]
```

1. Ask: _"This task is marked Done. Do you want to reopen it for review?
   Is there something specific you want to re-examine?"_
2. If user confirms → set Status to `In Review` in work `STATE.md` `## Tasks Status`, proceed to Step 2 (REVIEW)
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

Update work `STATE.md` `## Tasks Status` table: set this task's row Status to `In Progress`.

**Pick the executor by task Type from the Agent Selection table above** (RESEARCH → `researcher`, DESIGN → `ux-designer`, IMPLEMENT/TEST/REFACTOR → `developer`, DOCUMENT → `tech-writer`, MIGRATE → `data-engineer`, CONFIGURE → `devops`).

Dispatch with the Task tool, setting `subagent_type` explicitly to the chosen executor — this overrides the skill's default `agent: developer` from frontmatter. Example: a DESIGN task dispatches with `subagent_type: ux-designer`; an IMPLEMENT task uses `subagent_type: developer` (matches the default).

**Before dispatching, print:** `[Step 1] Dispatching {executor} for {Type} task → subagent_type={executor}` (substituting actual values).

Also update the task's row in work `STATE.md` `## Dispatches` sub-column (if tracked): `| 1 | {executor} | EXECUTE Type={Type} | {cycle} |`.

▶ {executor} starting (~{time band per rough-time-hints})
Load the section matching the task's Type from `references/task-type-rules.md` and pass it to the executor as the type-specific RULES it must follow.

**When agent reports done:** verify relevant gates pass (build, lint, tests — as applicable to the type).
✓ {executor} done (record actual time) — or ✗ {executor} failed: {reason}
When execution passes → update work `STATE.md` `## Tasks Status` row Status to `In Review` → proceed to Step 2.

---

## Step 2: REVIEW (Grade)

Dispatch the `reviewer` agent (Task tool with `subagent_type: reviewer`). Clean context — the reviewer must NOT see the executor's working notes.

**Before dispatching, print:** `[Step 2] Dispatching reviewer for review → subagent_type=reviewer`.

Also update the task's row in work `STATE.md` `## Dispatches` sub-column: `| 2 | reviewer | REVIEW | {cycle} |`.

▶ reviewer starting (~1–2 min)
**Reviewer receives:**
- All changes/artifacts produced by the task
- task-NNN.md — acceptance criteria and scope
- Feature SPEC — expected behavior
- KB docs via INDEX.md (as relevant to the type)
- Grading rubric (`../../templates/grading-rubric.md`)

Read `references/reviewer-guide.md` for severity/source classifications and type-specific review checklists.

**Grade is CALCULATED, not judged.** Count issues per severity, apply rubric.
Worst issue dominates.

**⚠️ The reviewer NEVER fixes anything.** It only grades and lists issues.

✓ reviewer done (record actual time) — or ✗ reviewer failed: {reason}
**Output:** Update work `STATE.md` `## Tasks Status` table row for this task:
- Set Cycle number (increment)
- Set Grade
- Write all issues in the task's issues section with severity, source, description
- Append cycle summary to the task's review history

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
- SPEC issues: Would require re-running /aid-specify.
- KB issues: Would require re-running /aid-discover.

Proceed with auto-fix of CODE issues?
```

**Routing:**

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Mark all issues as `Accepted`. Set Status to `Done`. ✅ |
| Grade < minimum | Auto-fix CODE issues (Step 4). Present non-CODE for user decision. |

**Non-CODE issues (TASK, SPEC, KB):**
- **TASK** → Present to user with suggestion. User updates task, re-run.
- **SPEC** → Write Q&A to `.aid/{work}/STATE.md` `## Cross-phase Q&A` → suggest `/aid-specify`
- **KB** → Write Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)` → suggest `/aid-discover`

Mark non-CODE issues as `Loopback` in work `STATE.md` `## Tasks Status` with target phase.

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
- **kb-gap** → targeted `/aid-discover` → update KB → retry
- **architecture-conflict** → `/aid-specify` for the feature
- **missing-dependency** → `/aid-detail` (might need another task first)
- **wrong-assumption** → update task or SPEC, retry

After resolving: delete IMPEDIMENT file, retry from Step 1.

---

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

---

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
