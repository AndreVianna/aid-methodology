---
name: aid-execute
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

Read `task-NNN.md`. It has 5 sections:
- **Title** — what this task does
- **Type** — RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE
- **Source** — `feature-NNN-{name} → delivery-NNN` (which feature and deliverable)
- **Scope** — what to produce or modify (files, tests, docs, configs — depends on type)
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

When the task is already `Done` and the user runs `/aid-execute task-NNN` again:

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

**Load if exists:**
- `.aid/{work}/known-issues.md` — issues in code the task touches

---

## Step 1: EXECUTE (Do the Work)

Create `task-NNN-STATE.md` from template (`../templates/implementation-state.md`).
Set Status to `In Progress`.

Dispatch a coding/working agent with assembled context.
The agent's behavior depends on the task Type.

### Type-Specific Execution

#### IMPLEMENT
```
RULES:
- YAGNI — implement exactly what the task specifies. Nothing more.
- Follow coding-standards from KB exactly (naming, patterns, error handling)
- Write clean code:
  · Meaningful names · Small methods · Guard clauses · DRY without over-abstraction
  · Clear error handling · Minimal comments (WHY not WHAT) · No magic numbers
- Match interface contracts from feature SPEC
- Write unit tests for all new code AND update existing tests
- Verify gates pass (from KB — technology-stack.md § Commands via INDEX):
  1. Build — ALWAYS
  2. Lint — IF CONFIGURED
  3. Unit tests — IF CONFIGURED
- Contradiction between SPEC and codebase → STOP, report as IMPEDIMENT
- Commit: "task-NNN: {description}"
```

#### TEST
```
RULES:
- Write integration/E2E/UI/load tests as specified in the task scope
- Use the testing framework and patterns from KB (test-landscape.md via INDEX)
- Each test must trace to a specific acceptance criterion
- Tests must be deterministic — no timing dependencies, no external state leaks
- Clean up test data after runs (teardown/cleanup hooks)
- Run the test suite and report results
- If tests FAIL on first run, that's a finding — document it, don't hide it
- Test environment setup: verify prerequisites before running
- Commit: "task-NNN: {description}"
```

#### RESEARCH
```
RULES:
- Investigate the question/topic defined in the task scope
- Compare at least 2 alternatives (unless task specifies otherwise)
- Cite sources — URLs, documentation references, code examples
- Document trade-offs explicitly (pros/cons, not just recommendation)
- End with a clear, actionable recommendation
- Write findings to the path specified in task Scope
- No code changes to the project — research produces documents only
```

#### DESIGN
```
RULES:
- Create design artifacts as specified in task scope (mockups, wireframes, flows)
- Follow ui-architecture.md from KB (design system, tokens, component patterns)
- Reference REQUIREMENTS.md for user stories and personas
- Show responsive behavior if specified in SPEC
- Note accessibility considerations
- Write artifacts to paths specified in task Scope
```

#### DOCUMENT
```
RULES:
- Write documentation as specified in task scope (ADRs, API docs, runbooks, diagrams)
- Verify accuracy against current codebase and KB
- Match the project's existing documentation style (check KB)
- ADRs follow: Context → Decision → Consequences format
- Diagrams use Mermaid or the project's standard (check KB)
- Commit: "task-NNN: {description}"
```

#### MIGRATE
```
RULES:
- Write migration scripts as specified in task scope
- Migration MUST be reversible (include rollback script)
- Migration MUST be idempotent (safe to run twice)
- Verify data integrity — before/after counts, referential integrity
- Document the migration steps in a runbook
- Test with realistic data volume (not just empty/trivial)
- Commit: "task-NNN: {description}"
```

#### REFACTOR
```
RULES:
- Restructure code as specified — NO behavior changes
- Run full test suite BEFORE refactoring (baseline)
- Run full test suite AFTER refactoring (must match baseline — same pass/fail)
- If tests change, justify why (test was testing implementation, not behavior)
- Measurable improvement: fewer lines, lower complexity, better naming, clearer structure
- Commit: "task-NNN: {description}"
```

#### CONFIGURE
```
RULES:
- Create/modify config as specified in task scope
- Configuration MUST be idempotent (applying twice = same result)
- No secrets in plaintext — use environment variables or secret managers
- Document what each config value does (inline comments or companion doc)
- Verify the configuration works (service starts, healthcheck passes)
- Commit: "task-NNN: {description}"
```

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
- Grading rubric (`../templates/grading-rubric.md`)

**Reviewer classifies every issue with a severity and a source:**

| Severity | Meaning |
|----------|---------|
| **Minor** | Cosmetic, style, trivial. Does not affect functionality. |
| **Low** | Convention deviation, could be better but works correctly. |
| **Medium** | Incorrect behavior, missing edge case, incomplete coverage. |
| **High** | Blocks functionality, security risk, data integrity concern. |
| **Critical** | System failure, data loss, security breach, fundamentally wrong. |

| Source | Meaning |
|--------|---------|
| **CODE** | Implementation bug, style, or quality issue (any type's output) |
| **TASK** | Task spec is wrong or incomplete |
| **SPEC** | Feature SPEC is wrong or missing |
| **KB** | Convention not documented |

### Type-Specific Review Focus

#### IMPLEMENT
1. Specification Compliance — every acceptance criterion met?
2. Architecture Compliance — patterns, boundaries, dependencies?
3. Convention Compliance — naming, error handling, logging?
4. Code Quality — clean code? YAGNI? No over-engineering?
5. Test Coverage — unit tests for new code? Edge cases?
6. Build Health — build/lint/tests green?

#### TEST
1. Coverage — every acceptance criterion from source feature has a test?
2. Test Quality — deterministic? Clean setup/teardown? No flaky patterns?
3. Test Results — what passed/failed? Failures documented?
4. Environment — test isolation? No side effects?
5. Gaps — what couldn't be automated? Manual checklist adequate?

#### RESEARCH
1. Completeness — question fully addressed? Alternatives compared?
2. Sources — cited and verifiable?
3. Bias — balanced presentation of trade-offs?
4. Actionability — clear recommendation with reasoning?
5. Relevance — findings applicable to the project context?

#### DESIGN
1. Requirements Adherence — user stories/personas reflected?
2. Design System — tokens, components, patterns from KB used?
3. Responsive — breakpoints handled (if specified)?
4. Accessibility — keyboard, contrast, screen reader considered?
5. Completeness — all states shown (empty, loading, error, success)?

#### DOCUMENT
1. Accuracy — matches current codebase and KB?
2. Completeness — covers what the task specified?
3. Clarity — target audience can follow?
4. Format — matches project conventions?

#### MIGRATE
1. Reversibility — rollback script exists and works?
2. Idempotency — safe to run twice?
3. Data Integrity — counts, references, constraints preserved?
4. Runbook — steps documented clearly?

#### REFACTOR
1. Behavior Preserved — test results identical before/after?
2. Measurable Improvement — complexity/lines/clarity actually better?
3. Test Changes Justified — if any tests changed, why?
4. No Scope Creep — only refactored what the task specified?

#### CONFIGURE
1. Correctness — config values right? Service starts?
2. Idempotency — applying twice = same result?
3. Security — no plaintext secrets? Proper permissions?
4. Documentation — values explained?

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
- **SPEC** → Write Q&A to feature STATE.md → suggest `/aid-specify`
- **KB** → Write Q&A to DISCOVERY-STATE.md → suggest `/aid-discover`

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
- **kb-gap** → targeted `/aid-discover` → update KB → retry
- **architecture-conflict** → `/aid-specify` for the feature
- **missing-dependency** → `/aid-detail` (might need another task first)
- **wrong-assumption** → update task or SPEC, retry

After resolving: delete IMPEDIMENT file, retry from Step 1.

---

## Delivery Lifecycle

```
create branch aid/delivery-001
  → /aid-execute task-001 [RESEARCH]      ← investigate → review → ✅
  → /aid-execute task-002 [DESIGN]        ← mockup → review → ✅
  → /aid-execute task-003 [IMPLEMENT]     ← code → review → fix → ✅
  → /aid-execute task-004 [IMPLEMENT]     ← code → review → fix → ✅
  → /aid-execute task-005 [TEST]          ← E2E → review → ✅
  → /aid-execute task-006 [DOCUMENT]      ← ADR → review → ✅
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
