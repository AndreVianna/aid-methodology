---
name: aid-detail
description: >
  Decompose PLAN.md into sprint-ready user stories, executable tasks, precedence
  ordering, and delivery breakdown. Tactics, not strategy. Use when PLAN.md is
  complete and you need executable work items.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
---

# Detail the Execution Plan

Decompose PLAN.md into user stories, tasks, precedence graph, and execution waves.

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  task-NNN-{name}/          ← the task being detailed
    REQUIREMENTS.md         ← stakeholder requirements (read)
    PLAN.md                 ← roadmap (read — must exist)
    DETAIL.md               ← OUTPUT: user stories, waves, precedence
    tasks/                  ← OUTPUT: individual task files
      TASK-001.md
      TASK-002.md
      ...
    features/
      feature-NNN-{name}/
        SPEC.md             ← per-feature tech spec (read)
```

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN` | Detail a specific task. Required if multiple tasks exist. |
| *(no arg)* | Auto-selects if only one task exists. |

## Pre-flight

### Check 1: Locate Task

1. If arg provided → use that task directory
2. If single task exists → auto-select
3. If multiple tasks → list them, ask user to choose
4. If no tasks → **STOP.** "No tasks found. Run `/aid-interview` first."

### Check 2: Verify PLAN.md Exists

1. Check for `aid-workspace/{task}/PLAN.md`
2. If missing → **STOP.** "No PLAN.md found. Run `/aid-plan` first."

## Inputs

- **Plan:** `aid-workspace/{task}/PLAN.md` — modules, deliverables, test scenarios
- **Feature SPECs:** All `aid-workspace/{task}/features/*/SPEC.md` — constraints, feature specs
- **KB (selective):** `aid-workspace/knowledge/` — architecture.md, module-map.md, tech-debt.md, test-landscape.md, coding-standards.md

## Process

### 1. User Story Decomposition

Per deliverable (from PLAN.md), generate user stories:

```markdown
### US-{id}: {Title}
**As a** {role} **I want** {capability} **So that** {benefit}
**Acceptance Criteria:** testable, concrete
**Source:** PLAN deliverable D-{x} + feature SPEC F-{y}
```

Each user story must trace back to a PLAN deliverable AND a feature SPEC.

### 2. Task Decomposition

Per user story, generate `aid-workspace/{task}/tasks/TASK-{id}.md` files:

```markdown
# TASK-{id}: {Title}

## Objective
{What this task accomplishes}

## Source
- User Story: US-{x}
- Feature: F-{y}
- Deliverable: D-{z}

## Interface Contracts
{APIs, events, data contracts this task must respect}

## Architecture Notes
{Where this fits in the system — reference KB docs}

## Files to Touch
{List of files to create/modify with brief description of changes}

## Acceptance Criteria
{Concrete, testable — derived from user story + SPEC}

## Test Requirements
{What tests to write — reference test-landscape.md for patterns}

## Complexity
{S/M/L/XL with justification}

## Dependencies
- Depends on: TASK-{x} (reason)
- Blocks: TASK-{y}
```

**Well-sized tasks:** Clear start/end, verifiable, fits one agent session (<10 files, <500 lines new code), defined interfaces.

### 3. Precedence Analysis

Map dependencies between tasks:
- For each: depends-on, blocks, parallel candidates
- Produce precedence graph (mermaid or text)
- Verify DAG (no cycles)

### 4. Complexity Estimation

| Size | Scope | Example |
|------|-------|---------|
| S | Single file, isolated change | Add a field, fix a bug |
| M | 2-5 files, one module | New endpoint, new component |
| L | 5-10 files, may cross modules | New feature flow, migration |
| XL | 10+ files, multiple modules | New subsystem, major refactor |

Adjust using KB: tech-debt flags → bump up, zero coverage → add test effort, coding-standards complexity → adjust.

### 5. Delivery Breakdown

Group tasks into delivery increments aligned with PLAN deliverables:
- User stories covered
- Tasks included
- Estimated effort (sum of complexity)
- Success criteria (from PLAN test scenarios)
- Dependencies on other increments

### 6. Execution Plan (Waves)

Organize into waves for parallel execution. Tasks in same wave have no shared dependencies.

```markdown
## Wave 1: Foundation
- TASK-001 (S) — Database schema
- TASK-002 (M) — Core domain models
  → Can run in parallel

## Wave 2: Core Features
- TASK-003 (L) — API endpoints [depends: TASK-001, TASK-002]
- TASK-004 (M) — Event handlers [depends: TASK-002]
  → Can run in parallel

## Wave 3: Integration
- TASK-005 (M) — End-to-end flow [depends: TASK-003, TASK-004]
```

### 7. Identify Spikes

Time-boxed research for uncertain tasks. Output is knowledge (KB update), not code.
- Reference PLAN.md spikes section
- Add new spikes discovered during detail decomposition

## Feedback Loops

- **→ Plan:** Plan too vague for detailing → document gap, return to `/aid-plan`
- **→ Discovery:** KB gap → write Q&A entry to `aid-workspace/knowledge/DISCOVERY-STATE.md`
- **→ Specify:** SPEC ambiguous → write Q&A entry to feature's `STATE.md`
- **← Implement/Review:** Detail wrong → receive feedback, revise

## Output

- `aid-workspace/{task}/DETAIL.md` — user stories, task list, precedence graph, delivery breakdown, wave plan
- `aid-workspace/{task}/tasks/TASK-{id}.md` files — one per executable task

## Quality Checklist

- [ ] Every PLAN deliverable has user stories
- [ ] Every user story has executable tasks
- [ ] Every TASK has concrete acceptance criteria
- [ ] Every TASK traces back to a feature SPEC
- [ ] Dependencies form valid DAG (no cycles)
- [ ] Complexity estimates reference KB data
- [ ] Parallel execution opportunities identified (waves)
- [ ] Spikes identified for uncertain areas
- [ ] Delivery breakdown has measurable success criteria
- [ ] All output files live inside the task directory
