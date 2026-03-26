---
name: aid-implement
description: >
  Implement a task with built-in code review. Follows the universal loop:
  code → review (spawn reviewer) → fix → re-review → done when A-.
  Creates a branch per delivery for isolation. Use when a task is ready.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: developer
argument-hint: "task-001 (required)  [work-001 if multiple works]"
---

# Implement Task

Code it. Review it. Fix it. Ship it.

## Universal Loop

Same DNA as every other AID design skill:

```
Code → Review → Fix → Re-review → Done (when grade ≥ A-)
```

Review is NOT a separate step. It's built into implement.

## Workspace

```
.aid/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    PLAN.md                 ← delivery context
    known-issues.md         ← issues to watch for
    tasks/
      task-NNN.md           ← PRIMARY INPUT
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

### Check 4: Branch Isolation

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

### Check 5: Determine State

| Condition | State |
|-----------|-------|
| No changes for this task yet | **IMPLEMENT** |
| CORRECTION.md exists for this task | **FIX** |
| Changes exist, no CORRECTION.md | **REVIEW** (re-run mode) |

---

## Inputs

**Always load:**
- `.aid/{work}/tasks/task-NNN.md` — primary prompt
- Feature SPEC: `.aid/{work}/features/{feature}/SPEC.md` — Technical Specification
  sections from the task's Source feature
- `.aid/knowledge/INDEX.md` — KB index for self-service lookup
- `.aid/knowledge/coding-standards.md` — mandatory
- `.aid/knowledge/architecture.md` — mandatory

**Load from INDEX.md based on task scope** (read INDEX, pull what's relevant):
- `technology-stack.md` — build commands, lint commands, dev tooling
- `test-landscape.md` — test commands, test patterns, coverage
- `data-model.md` — DB migrations, schema changes
- `api-contracts.md` — API endpoints
- `integration-map.md` — external service calls
- `ui-architecture.md` — frontend components

**Load if exists:**
- `.aid/{work}/known-issues.md` — issues in code the task touches

---

## Step 1: IMPLEMENT (Code)

Spawn a coding agent with assembled context:

**Agent receives:**
1. Task content (full task-NNN.md)
2. Feature SPEC Technical Specification sections
3. Coding standards + architecture (always)
4. INDEX.md — use it to find and load KB docs relevant to the task scope
5. known-issues.md if relevant

**Agent rules:**
```
RULES:
- YAGNI — implement exactly what the task specifies. Nothing more.
  No "while I'm here" extras, no speculative abstractions, no future-proofing.
- Follow coding-standards.md exactly (naming, patterns, error handling)
- Write clean code regardless of what coding-standards.md covers:
  · Meaningful names (variables, methods, classes) — self-documenting
  · Small methods — single responsibility, one level of abstraction
  · No deep nesting — extract early returns, guard clauses
  · DRY — but don't over-abstract; duplication is better than wrong abstraction
  · Clear error handling — no silent swallows, no generic catches
  · Minimal comments — code explains itself; comments explain WHY, not WHAT
  · No magic numbers or strings — use named constants
- Match interface contracts from feature SPEC
- Write unit tests for all new code AND update existing tests affected by changes
- Before reporting done, verify ALL THREE gates pass using the **exact commands
  from the KB** (look them up via INDEX.md — do NOT guess):
  1. **Build** — find and run the project's build command
  2. **Lint** — find and run the project's lint command
  3. **Unit tests** — find and run the project's test command
- If you find a contradiction between SPEC and codebase → STOP and report
  as IMPEDIMENT. Do NOT silently work around it.
- Commit messages: "task-NNN: {description}"
```

**When agent reports done:** verify build + lint + ALL unit tests pass.
If any fail, send agent back to fix. Only proceed to Review when all
three gates are green.

---

## Step 2: REVIEW (Grade)

Spawn a **separate reviewer agent** (clean context, no implementation knowledge):

**Reviewer receives:**
- Git diff (all changes on the delivery branch for this task)
- task-NNN.md — acceptance criteria and scope
- Feature SPEC — expected behavior
- coding-standards.md — convention reference
- architecture.md — pattern reference
- INDEX.md — for looking up additional KB docs as needed

**Reviewer checks:**

1. **Specification Compliance** — every acceptance criterion met?
2. **Architecture Compliance** — patterns, module boundaries, dependency direction?
3. **Convention Compliance** — naming, error handling, logging, file organization?
4. **Code Quality** — clean code independent of project conventions?
   Small methods? Meaningful names? Single responsibility? No god classes,
   no deep nesting, no magic numbers? YAGNI — no over-engineering?
5. **Test Coverage** — unit tests for new code? Existing tests updated?
   Edge cases covered? Tests actually test behavior, not implementation details?
6. **Build Health** — find and run the project's build, lint, and test commands
   (look up via INDEX.md if not already loaded). Build clean? Lint clean? All tests green?

**Issue Classification:**

Every issue gets a **source** and **severity**:

| Source | Meaning | Resolution |
|--------|---------|------------|
| CODE | Implementation bug or style | Fix this cycle |
| TASK | Task spec wrong or incomplete | Update task → re-implement |
| SPEC | Feature SPEC wrong or missing | Loopback → `/aid-specify` |
| KB | Convention not documented | Loopback → `/aid-discover` |

| Severity | Meaning |
|----------|---------|
| P1 | Blocks functionality or security risk |
| P2 | Incorrect behavior, non-critical |
| P3 | Style, minor convention deviation |
| P4 | Suggestion for improvement |

**Grading:**

| Grade | Meaning |
|-------|---------|
| A+ | Exemplary — beyond requirements |
| A  | Clean — minor P3-P4 only |
| A- | Ship-ready — few P3, all criteria met |
| B+ | Close — 1-2 P2 CODE issues |
| B  | Multiple P2 fixes needed |
| C  | Major rework — missing criteria or wrong approach |
| D  | Doesn't meet requirements |
| F  | Doesn't build or test |

**Auto-fix:** Reviewer fixes P1/P2 CODE issues directly. Verify build+tests
still green after each fix. Document what was changed.

---

## Step 3: Evaluate Grade

| Grade | Action |
|-------|--------|
| **≥ A-** | ✅ **DONE.** Task complete. Move to next task. |
| **B+ to B** | → Step 4 (FIX) with CORRECTION.md |
| **C to F** | → Step 4 (FIX) with CORRECTION.md. If D or F, ask user first. |

### Non-CODE Issues

If reviewer found TASK/SPEC/KB issues:
- **TASK issues** → present to user → update task → re-implement
- **SPEC issues** → write Q&A to feature's STATE.md → suggest `/aid-specify`
- **KB issues** → write Q&A to DISCOVERY-STATE.md → suggest `/aid-discover`

These are loopbacks. Don't fix them at the code level.

---

## Step 4: FIX

When grade < A-, reviewer produces `.aid/{work}/CORRECTION-task-NNN.md`:

```markdown
# Correction — task-NNN

## Issues

| # | Severity | Source | Description | File:Line |
|---|----------|--------|-------------|-----------|
| 1 | P2 | CODE | {description} | src/auth.ts:42 |

## Auto-Fixed (already applied by reviewer)

| # | Description | Fix Applied |
|---|-------------|-------------|
| 1 | {description} | {what was changed} |

## Remaining (needs developer)

| # | Severity | Description | File:Line |
|---|----------|-------------|-----------|
| 2 | P2 | {description} | src/user.ts:15 |

## Grade: {grade}
```

**Fix process:**
1. Spawn coding agent with CORRECTION.md + original task context
2. Agent fixes remaining issues
3. Verify build + tests green
4. Delete CORRECTION.md
5. → **Back to Step 2 (REVIEW)** — fresh reviewer, clean context

**Loop continues until grade ≥ A-.**

⚠️ **Circuit breaker:** If 3 review cycles pass without reaching A-,
**STOP.** Present the pattern to the user — something systemic is wrong.

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
- Build: green. Tests: green.
- Grade ≥ A- from reviewer
- Commit messages reference task-NNN
- IMPEDIMENT-task-NNN.md if blocked

## Quality Checklist

- [ ] On correct delivery branch (`aid/delivery-NNN`)
- [ ] Agent received task + feature SPEC + INDEX.md + relevant KB docs
- [ ] YAGNI — no code beyond what the task specifies
- [ ] Clean code — small methods, meaningful names, no deep nesting, no magic numbers
- [ ] Build passes (zero errors, zero warnings)
- [ ] Lint passes (zero violations)
- [ ] All unit tests pass (new and existing)
- [ ] Unit tests written for new code AND existing tests updated where affected
- [ ] Files changed match task Scope
- [ ] Reviewer graded ≥ A- (separate agent, clean context)
- [ ] No silent workarounds — impediments documented
- [ ] Commit messages reference task-NNN
- [ ] Coding standards followed
- [ ] CORRECTION.md deleted after fixes applied
