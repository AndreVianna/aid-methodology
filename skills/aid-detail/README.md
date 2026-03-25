# Detail the Execution Plan

Take the delivery roadmap (PLAN.md) and decompose it into sprint-ready user stories, executable tasks, precedence ordering, and delivery breakdown. This is where strategy becomes tactics.

## Core Principle

**Plan defines WHAT to deliver and in what order. Detail defines HOW to build it and WHO does what.** Plan sequences features into deliverables. Detail decomposes deliverables into user stories and tasks that agents can execute. A plan without detail is a wishlist. Detail without a plan is busywork.

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    REQUIREMENTS.md         ← read
    PLAN.md                 ← read (deliverable sequence — must exist)
    DETAIL.md               ← OUTPUT: user stories, waves, precedence
    tasks/                  ← OUTPUT: individual task files
      TASK-001.md
      TASK-002.md
    features/
      feature-NNN-{name}/
        SPEC.md             ← read (requirements + tech spec)
```

## When to Use

- **Primary:** After Plan has sequenced features into deliverables.
- **Re-entry:** When Implement or Review reveals the detail was wrong (task too large, wrong dependencies, missing task).

## Inputs

- **PLAN.md** — deliverable sequence with features per deliverable.
- **Feature SPECs** — all `aid-workspace/{work}/features/*/SPEC.md` — requirements + technical specification.
- **KB (selective):** architecture.md, module-map.md, tech-debt.md, test-landscape.md, coding-standards.md.

## Process

### Step 1: User Story Decomposition

For each deliverable in PLAN.md, generate user stories:

```markdown
### US-{id}: {Title}
**As a** {user role}
**I want** {capability}
**So that** {benefit}

**Acceptance Criteria:**
- [ ] {Concrete, testable criterion}
- [ ] {Edge case handling}

**Source:** PLAN deliverable D-{x}, feature SPEC F-{y}
```

Each user story must trace back to a PLAN deliverable AND a feature SPEC.

**Good user stories:**
- Map to a single user-visible behavior.
- Have testable acceptance criteria.
- Are small enough for one delivery increment.

Technical enablers (database setup, CI pipeline, auth infrastructure) are tasks, not user stories.

### Step 2: Task Decomposition

For each user story, generate executable `TASK-{id}.md` files:

```markdown
# TASK-{id}: {Title}

## Objective
{What this task accomplishes}

## Source
- User Story: US-{x}
- Feature: feature-NNN-{name}
- Deliverable: D-{z}

## Interface Contracts
{APIs, events, data contracts this task must respect}

## Architecture Notes
{Where this fits — reference KB docs and feature SPEC}

## Files to Touch
{Files to create/modify with brief description}

## Acceptance Criteria
{Concrete, testable — from user story + feature SPEC}

## Test Requirements
{What tests to write — reference test-landscape.md}

## Complexity
{S/M/L/XL with justification}

## Dependencies
- Depends on: TASK-{x} (reason)
- Blocks: TASK-{y}
```

**Well-sized tasks:** Clear start/end, verifiable, fits one agent session (<10 files, <500 lines new code), defined interfaces.

### Step 3: Precedence Analysis

Map dependencies between tasks:
- For each: depends-on, blocks, parallel candidates.
- Produce precedence graph (mermaid or text).
- Verify DAG (no cycles).

### Step 4: Complexity Estimation

| Size | Scope | Example |
|------|-------|---------|
| **S** | Single file, isolated change | Add a field, fix a bug |
| **M** | 2–5 files, one module | New endpoint, new component |
| **L** | 5–10 files, may cross modules | New feature flow, migration |
| **XL** | 10+ files, multiple modules | New subsystem, major refactor |

Adjust using KB: tech-debt flags → bump up, zero coverage → add test effort.

### Step 5: Delivery Breakdown

Group tasks into delivery increments aligned with PLAN deliverables:
- User stories covered
- Tasks included
- Estimated effort (sum of complexity)
- Success criteria (from feature SPEC acceptance criteria)
- Dependencies on other increments

### Step 6: Execution Plan (Waves)

Organize into waves for parallel execution. Tasks in the same wave have no shared dependencies:

```markdown
## Wave 1: Foundation
- TASK-001 (S) — Database schema
- TASK-002 (M) — Core domain models
  → Can run in parallel

## Wave 2: Core Features
- TASK-003 (L) — API endpoints [depends: TASK-001, TASK-002]
- TASK-004 (M) — Event handlers [depends: TASK-002]
  → Can run in parallel
```

## Feedback Loops

### → Plan

Plan too vague for detailing → document what's missing, return to `/aid-plan` for revision.

### → Discovery

KB gap → write Q&A entry to `aid-workspace/knowledge/DISCOVERY-STATE.md`.

### → Specify

SPEC ambiguous → write Q&A entry to feature's `STATE.md`.

### ← Implement / Review

Detail was wrong (task too large, missing dependencies, missing task) → receive feedback, revise affected tasks and waves.

## Output

- `aid-workspace/{work}/DETAIL.md` — user stories, task list, precedence graph, delivery breakdown, wave plan.
- `aid-workspace/{work}/tasks/TASK-{id}.md` files — one per executable task.

## Quality Checklist

- [ ] Every PLAN deliverable has user stories.
- [ ] Every user story has executable tasks.
- [ ] Every TASK has concrete acceptance criteria.
- [ ] Every TASK traces back to a feature SPEC.
- [ ] Dependencies form valid DAG (no cycles).
- [ ] Complexity estimates reference KB data.
- [ ] Parallel execution opportunities identified (waves).
- [ ] Delivery breakdown has measurable success criteria.
- [ ] All output files live inside the work directory.

## Why This Phase Exists

AI coding agents need precise, bounded tasks — not vague feature requests. Detail transforms the delivery roadmap into task-level specs that an agent can implement in a single session: clear objective, files to touch, interface contracts, acceptance criteria.

The precedence graph and wave plan enable parallel execution: multiple coding agents working on independent tasks simultaneously, with merge order defined upfront.

## Related Phases

- **Previous:** [Plan](../aid-plan/) — provides the delivery roadmap
- **Next:** [Implement](../aid-implement/) — executes TASK files
- **Triggered by:** Feedback from Implement/Review when Detail needs revision

## See Also

- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
