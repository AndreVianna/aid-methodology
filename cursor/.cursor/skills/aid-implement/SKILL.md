---
name: aid-implement
description: >
  Implement a task with built-in code review. State machine:
  IMPLEMENT → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum.
  Creates a branch per delivery for isolation. Use when a task is ready.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: developer
argument-hint: "task-001 (required)  [work-001 if multiple works]"
---

# Implement Task

Code it. Review it. Fix it. Ship it.

## State Machine

```
IMPLEMENT → REVIEW → [present all issues] → FIX (CODE) → back to REVIEW
                                          → DONE when grade ≥ minimum
```

Review is a separate step with its own agent (clean context).
Fix is a separate step. Reviewer NEVER fixes — only grades and lists issues.

## Grading

Read `../templates/grading-rubric.md` for the universal grading scale.
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
      task-NNN.md           ← PRIMARY INPUT
      task-NNN-STATE.md     ← implementation state (created here)
    features/
      feature-NNN-{name}/
        SPEC.md             ← architectural constraints
```

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN` | Required. Which task to implement. |
| `work-NNN` | Required if multiple works exist. |

## Pre-flight

### Check 1: Locate Work and Task

1. If work arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. Find `task-NNN.md` in `.aid/{work}/tasks/`
5. Task not found → **STOP.** List available tasks.

### Check 2: Read Task

Read `task-NNN.md`. It has 4 sections:
- **Title** — what this task does
- **Source** — `feature-NNN-{name} → delivery-NNN` (which feature and deliverable)
- **Scope** — files/endpoints/migrations/config to create or modify
- **Acceptance Criteria** — concrete, testable conditions

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
   to determine the correct branch/commit commands. Examples:
   - Git: `git checkout -b aid/delivery-NNN` / `git checkout aid/delivery-NNN`
   - SVN: `svn copy` to create branch, `svn switch` to switch
   - Use whatever the project's VCS provides — do NOT assume Git.

| Situation | Action |
|-----------|--------|
| Branch doesn't exist | Create it from current HEAD using VCS branch command |
| Branch exists, not checked out | Switch to it using VCS checkout/switch command |
| Branch exists, already checked out | Continue |

⚠️ **Before creating a new branch:** verify working tree is clean.
If dirty → **STOP.** Ask user to commit or stash first.

### Check 6: Determine State

Read `task-NNN-STATE.md` if it exists.

| Condition | State |
|-----------|-------|
| No STATE file exists | **IMPLEMENT** (Step 1) |
| Status: `In Progress`, no issues pending | **IMPLEMENT** (Step 1 — resume) |
| Status: `In Review`, issues listed | **FIX** (Step 2) |
| Status: `Done` | **RE-RUN** (see Re-run below) |

---

## Re-run (Status: Done)

When the task is already `Done` and the user runs `/aid-implement task-NNN` again:

1. Ask: _"This task is marked Done. Do you want to reopen it for review? Is there something specific you want to re-examine?"_
2. If user confirms → set Status to `In Review` in STATE.md, proceed to Step 2 (REVIEW)
3. If user has a specific concern → record it as context for the reviewer

This pattern is consistent across all AID phases.

---

## Inputs

**KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`. Use summaries to decide which
KB docs are relevant to this task, then load them. At minimum you'll almost always
need coding-standards and architecture, but let the INDEX guide you — don't guess.

**Always load (not KB):**
- `.aid/{work}/tasks/task-NNN.md` — primary prompt
- Feature SPEC: `.aid/{work}/features/{feature}/SPEC.md` — Technical Specification

**Load if exists:**
- `.aid/{work}/known-issues.md` — issues in code the task touches

---

## Step 1: IMPLEMENT (Code)

Create `task-NNN-STATE.md` from template (`../templates/implementation-state.md`).
Set Status to `In Progress`.

Dispatch a coding agent with assembled context.

**Agent receives:**
1. Task content (full task-NNN.md)
2. Feature SPEC Technical Specification sections
3. KB docs loaded via INDEX.md
4. known-issues.md if relevant

**Agent rules:**
```
RULES:
- YAGNI — implement exactly what the task specifies. Nothing more.
  No "while I'm here" extras, no speculative abstractions, no future-proofing.
- Follow coding-standards from KB exactly (naming, patterns, error handling)
- Write clean code regardless of what coding-standards covers:
  · Meaningful names (variables, methods, classes) — self-documenting
  · Small methods — single responsibility, one level of abstraction
  · No deep nesting — extract early returns, guard clauses
  · DRY — but don't over-abstract; duplication is better than wrong abstraction
  · Clear error handling — no silent swallows, no generic catches
  · Minimal comments — code explains itself; comments explain WHY, not WHAT
  · No magic numbers or strings — use named constants
- Match interface contracts from feature SPEC
- Write unit tests for all new code AND update existing tests affected by changes
- Before reporting done, verify gates pass using the commands from KB
  (look up via INDEX.md — technology-stack.md § Commands):
  1. **Build** — ALWAYS. Find and run the project's build command.
  2. **Lint** — IF CONFIGURED. Find and run the project's lint command.
  3. **Unit tests** — IF CONFIGURED. Find and run the project's test command.
  If lint or test commands are not in KB, skip that gate.
- If you find a contradiction between SPEC and codebase → STOP and report
  as IMPEDIMENT. Do NOT silently work around it.
- Commit messages: "task-NNN: {description}"
```

**When agent reports done:** verify build passes (and lint + tests if configured).
If any configured gate fails, send agent back to fix before proceeding to Review.

When implementation passes gates → update STATE.md Status to `In Review` → proceed to Step 2.

---

## Step 2: REVIEW (Grade)

Dispatch a **separate reviewer agent** with clean context (no implementation knowledge).

**Reviewer receives:**
- VCS diff (all changes on the delivery branch for this task)
- task-NNN.md — acceptance criteria and scope
- Feature SPEC — expected behavior
- KB docs via INDEX.md (typically coding-standards, architecture, test-landscape)
- Grading rubric (`../templates/grading-rubric.md`)

**Reviewer classifies every issue with a severity and a source:**

| Severity | Meaning |
|----------|---------|
| **Minor** | Cosmetic, style, trivial. Does not affect functionality. |
| **Low** | Convention deviation, could be better but works correctly. |
| **Medium** | Incorrect behavior (non-critical), missing edge case, incomplete coverage. |
| **High** | Blocks functionality, security risk, data integrity concern. |
| **Critical** | System failure, data loss, security breach, fundamentally wrong approach. |

| Source | Meaning |
|--------|---------|
| **CODE** | Implementation bug or style issue |
| **TASK** | Task spec is wrong or incomplete |
| **SPEC** | Feature SPEC is wrong or missing |
| **KB** | Convention not documented |

**Reviewer checks:**

1. **Specification Compliance** — every acceptance criterion met?
2. **Architecture Compliance** — patterns, module boundaries, dependency direction?
3. **Convention Compliance** — naming, error handling, logging, file organization?
4. **Code Quality** — clean code? Small methods? Meaningful names? No deep nesting,
   no magic numbers? YAGNI — no over-engineering?
5. **Test Coverage** — unit tests for new code? Existing tests updated?
   Edge cases covered? Tests test behavior, not implementation details?
6. **Build Health** — build clean? Lint clean (if configured)? All tests green (if configured)?

**Grade is CALCULATED, not judged.** Count issues at each severity level,
apply the rubric. The worst issue dominates.

**⚠️ The reviewer NEVER fixes code.** It only grades and lists issues.
Fix is a separate step.

**Output:** Update `task-NNN-STATE.md`:
- Set Cycle number (increment from previous)
- Set Grade
- Write all issues under `### Issues` with severity, source, and description
- Append cycle summary to `## Review History`

### Issue Format in STATE.md

```markdown
### Issues

| # | Severity | Source | Description | Status |
|---|----------|--------|-------------|--------|
| 1 | Medium | CODE | Missing null check in UserService.getById() | Pending |
| 2 | Low | TASK | Acceptance criteria doesn't cover admin role | Pending |
| 3 | Minor | CODE | Inconsistent spacing in imports | Pending |
```

---

## Step 3: Present and Route

**Present ALL issues to the user** regardless of source. The user sees the full picture.

```
[Review — Cycle {N} — Grade: {grade} — Minimum: {min}]

Issues found:

| # | Severity | Source | Description |
|---|----------|--------|-------------|
| 1 | Medium | CODE | Missing null check in UserService.getById() |
| 2 | Low | TASK | Acceptance criteria doesn't cover admin role |
| 3 | Minor | CODE | Inconsistent spacing in imports |

{If grade ≥ minimum:}
✅ Grade meets minimum. Marking as Done.

{If grade < minimum:}
Grade below minimum. Next steps:
- CODE issues (#1, #3): I'll fix these automatically.
- TASK issues (#2): This needs a task update. {explain what's wrong}
- SPEC issues: Would require re-running /aid-specify.
- KB issues: Would require re-running /aid-discover.

Proceed with auto-fix of CODE issues?
```

**Routing logic:**

| Condition | Action |
|-----------|--------|
| **Grade ≥ minimum** | Mark all issues as `Accepted`. Set Status to `Done`. ✅ |
| **Grade < minimum** | Auto-fix CODE issues (Step 4). Present non-CODE issues for user decision. |

**Non-CODE issues (TASK, SPEC, KB):**
- **TASK** → Present to user with suggestion. User updates the task file, then re-run.
- **SPEC** → Write Q&A entry to feature STATE.md → suggest `/aid-specify`
- **KB** → Write Q&A entry to DISCOVERY-STATE.md → suggest `/aid-discover`

Mark non-CODE issues as `Loopback` in STATE.md with the target phase.

**If ONLY non-CODE issues remain** (all CODE issues fixed, grade still < minimum because
of TASK/SPEC/KB issues): **STOP.** The code is as good as it can be — the problem is upstream.
Present what needs to change and where.

---

## Step 4: FIX

Dispatch coding agent with:
- Issues from STATE.md where Source = CODE and Status = Pending
- Original task context

**Agent fixes CODE issues only.** Verifies gates still pass after fixes.

When done:
1. Mark fixed issues as `Fixed` in STATE.md
2. → **Back to Step 2 (REVIEW)** — fresh reviewer, clean context

**Loop continues until grade ≥ minimum grade.**

⚠️ **Circuit breaker:** If the grade has not improved after 3 consecutive
review cycles (same grade or worse), **STOP.** Present the pattern to the user —
something systemic is wrong that retry won't fix.

---

## Impediments

If the coding agent encounters something it can't resolve:

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

```
create branch aid/delivery-001            ← first task creates the branch (VCS-specific command)
  → /aid-implement task-001               ← code → review → fix → ✅
  → /aid-implement task-002               ← code → review → fix → ✅
  → /aid-implement task-003               ← code → review → fix → ✅
  → /aid-test delivery-001                ← E2E + integration in staging
  → merge to main                         ← or however the project merges
create branch aid/delivery-002
  → ...
```

All tasks in a delivery accumulate on the same branch.
Branch is merged only after `/aid-test` passes.

---

## Output

- Code changes on `aid/delivery-NNN` branch
- Unit tests for all new code
- Build: green. Lint + tests: green (if configured).
- Grade ≥ minimum grade (from DISCOVERY-STATE.md)
- Commit messages reference task-NNN
- `task-NNN-STATE.md` with full review history
- IMPEDIMENT-task-NNN.md if blocked

## Quality Checklist

- [ ] On correct delivery branch (`aid/delivery-NNN`)
- [ ] KB docs loaded via INDEX.md (not hardcoded)
- [ ] YAGNI — no code beyond what the task specifies
- [ ] Clean code — small methods, meaningful names, no deep nesting, no magic numbers
- [ ] Build passes (zero errors)
- [ ] Lint passes (if configured)
- [ ] All unit tests pass (if configured) — new and existing
- [ ] Files changed match task Scope
- [ ] Reviewer graded using deterministic rubric (separate agent, clean context)
- [ ] Reviewer did NOT fix code — only graded and listed issues
- [ ] ALL issues presented to user (not just CODE)
- [ ] Non-CODE issues marked as Loopback with target phase
- [ ] No silent workarounds — impediments documented
- [ ] Commit messages reference task-NNN
- [ ] STATE.md has full review history
