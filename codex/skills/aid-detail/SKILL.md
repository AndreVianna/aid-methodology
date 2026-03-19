---
name: aid-detail
description: >
  Decompose PLAN.md into sprint-ready user stories, executable tasks, precedence
  ordering, and delivery breakdown. Tactics, not strategy. Use when PLAN.md is
  complete and you need executable work items.
metadata:
  short-description: Task decomposition and sprint planning
---

# Detail the Execution Plan

Decompose PLAN.md into user stories, tasks, precedence graph, and execution waves.

## Inputs

- `PLAN.md` — modules, deliverables, test scenarios
- `SPEC.md` — constraints, feature specs
- `knowledge/`: architecture.md, module-map.md, tech-debt.md, test-landscape.md, coding-standards.md

## Process

### 1. User Story Decomposition
Per deliverable, generate user stories:
```
### US-{id}: {Title}
**As a** {role} **I want** {capability} **So that** {benefit}
**Acceptance Criteria:** testable, concrete
**Source:** PLAN deliverable + SPEC feature ref
```

### 2. Task Decomposition
Per user story, generate TASK-{id}.md files. Well-sized tasks: clear start/end, verifiable, fits one agent session (<10 files, <500 lines new code), defined interfaces.

### 3. Precedence Analysis
Map dependencies between tasks. For each: depends-on, blocks, parallel candidates. Produce precedence graph (text or mermaid).

### 4. Complexity Estimation
S (single file) | M (2-5 files, one module) | L (5-10 files, may cross modules) | XL (10+ files, multiple modules). Adjust using KB: tech-debt flags → bump up, zero coverage → add test effort.

### 5. Delivery Breakdown
Group tasks into delivery increments with: user stories, tasks, estimated effort, success criteria.

### 6. Execution Plan
Organize into waves for parallel execution. Tasks in same wave have no shared dependencies.

### 7. Identify Spikes
Time-boxed research for uncertain tasks. Output is knowledge (KB update), not code.

## Feedback Loops

- **→ Plan:** Plan too vague → document gap, return to aid-plan
- **→ Discovery:** KB gap → GAP.md with `discovery-needed`
- **→ Specify:** Spec ambiguous → GAP.md with `ambiguity`
- **← Implement/Review:** Detail wrong → receive feedback, revise

## Output

- `DETAIL.md` — user stories, task list, precedence graph, delivery breakdown, wave plan
- `TASK-{id}.md` files — objective, interface contracts, architecture notes, acceptance criteria, test requirements, files to touch

## Quality Checklist

- [ ] Every deliverable has user stories
- [ ] Every user story has executable tasks
- [ ] Every TASK has concrete acceptance criteria
- [ ] Dependencies form valid DAG (no cycles)
- [ ] Complexity estimates reference KB data
- [ ] Parallel execution opportunities identified
- [ ] Spikes identified for uncertain areas
- [ ] Delivery breakdown has measurable success criteria
