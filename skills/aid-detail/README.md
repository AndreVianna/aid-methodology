
# Detail the Execution Plan

Take the high-level plan (PLAN.md) and decompose it into sprint-ready user stories, executable tasks, precedence ordering, and delivery breakdown. This is where strategy becomes tactics.

## Core Principle

**Plan defines WHAT to build and in what order. Detail defines HOW to build it and WHO does what.** Plan is the roadmap — modules, MVPs, deliverables, test scenarios. Detail is the work breakdown — user stories, tasks with acceptance criteria, dependency ordering, parallel execution opportunities. A plan without detail is a wishlist. Detail without a plan is busywork.

## Inputs

- `PLAN.md` — the high-level roadmap. Modules, MVPs, deliverables, test scenarios.
- `SPEC.md` — the specification. Architectural constraints, feature specs.
- `knowledge/` directory — for complexity estimation and dependency analysis. Read at minimum:
  - `architecture.md` — to understand module boundaries.
  - `module-map.md` — to identify affected modules and test coverage.
  - `tech-debt.md` — to anticipate complications.
  - `test-landscape.md` — to plan test requirements.
  - `coding-standards.md` — to specify implementation conventions.

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
- [ ] {Another criterion}
- [ ] {Edge case handling}

**Source:** PLAN.md deliverable {id}, SPEC.md feature {ref}
```

**Good user stories:**
- Map to a single user-visible behavior.
- Have testable acceptance criteria.
- Can be demonstrated to a stakeholder.
- Are small enough for one delivery increment.

**Bad user stories:**
- "Implement the data layer" — not user-visible.
- "The app works" — not testable.
- "Support all file formats" — unbounded scope.

Technical enablers (database setup, CI pipeline, auth infrastructure) are tasks, not user stories. They support stories but aren't stories themselves.

### Step 2: Task Decomposition

For each user story, generate executable tasks. A task is what an agent actually implements.

Each task gets a `TASK-{id}.md` file. See [references/detail-template.md](references/detail-template.md) for the output format.

A well-sized task:
- **Has a clear start and end.** "Implement IRecordingService" — not "work on recording."
- **Can be verified.** Acceptance criteria are testable.
- **Fits in one agent session.** If it touches >10 files or >500 lines of new code, split it.
- **Has defined interfaces.** The task spec includes the public API the implementation must provide.

### Step 3: Precedence Analysis

Map dependencies between tasks and user stories:

```markdown
## Precedence Graph

US-01 → TASK-F1 (data model) → TASK-F2 (repository) → TASK-F4 (API)
                                                      ↗
US-02 → TASK-F3 (auth middleware) ────────────────────

US-03 → TASK-F5 (UI components) ── independent ── parallel with Wave 1
```

For each task, identify:
- **Depends on:** Tasks that must complete before this one starts.
- **Blocks:** Tasks that wait on this one.
- **Parallel candidates:** Tasks with no shared dependencies.

Record dependencies in each TASK-{id}.md and summarize in DETAIL.md.

### Step 4: Complexity Estimation

Estimate each task using KB data:

| Size | Criteria | Typical Scope |
|------|----------|---------------|
| **S** | Single file change, clear pattern to follow | Bug fix, config change, simple addition |
| **M** | 2-5 files, one module, established patterns | New feature within existing architecture |
| **L** | 5-10 files, may cross modules, new patterns needed | Feature requiring new abstractions |
| **XL** | 10+ files, multiple modules, significant new architecture | New subsystem, major refactor |

Adjust based on KB:
- `tech-debt.md` flags in the target area → bump complexity up.
- `test-landscape.md` shows zero coverage → add test-writing effort.
- `coding-standards.md` is marked Partial for the target area → agent may struggle with conventions.

### Step 5: Delivery Breakdown

Group tasks into delivery increments — shippable units of work:

```markdown
## Delivery Breakdown

### DELIVERY-01: Core Recording
**User Stories:** US-01, US-02
**Tasks:** TASK-F1, TASK-F2, TASK-F3, TASK-F4
**Estimated Effort:** 3 waves (see execution plan)
**Success Criteria:**
- [ ] All acceptance criteria from US-01 and US-02 pass
- [ ] Build green, tests green
- [ ] Review grade A- or above

### DELIVERY-02: Transcription
**User Stories:** US-03, US-04
**Tasks:** TASK-F5, TASK-F6, TASK-F7
**Depends on:** DELIVERY-01
```

### Step 6: Execution Plan

Based on the precedence graph, organize tasks into waves for parallel execution:

```markdown
## Execution Plan

### DELIVERY-01

#### Wave 1 (parallel)
- TASK-F1: Data model (S) — no dependencies
- TASK-F5: UI scaffolding (M) — no dependencies

#### Wave 2 (parallel, after Wave 1)
- TASK-F2: Repository layer (M) — depends on F1
- TASK-F3: Auth middleware (M) — independent of F1

#### Wave 3 (sequential)
- TASK-F4: API endpoints (L) — depends on F2, F3
```

### Step 7: Identify Spikes

A spike is a time-boxed research task needed before implementation.

**Generate a spike when:**
- A feature requires technology the team hasn't used before.
- The KB has an open question that blocks task definition.
- The complexity estimate is uncertain (could be M or XL — need to investigate).

Spikes are separate TASK files with `**Type:** Spike` in the header. Their output is knowledge (update KB), not code.

## Output

- `DETAIL.md` — the complete execution plan with user stories, task list, precedence graph, delivery breakdown, and wave plan.
- `TASK-{id}.md` files — one per task. Contains: objective, interface contracts, architecture notes, acceptance criteria, test requirements, files to touch.
- Precedence graph (text or mermaid) showing execution order and parallelism.

## Feedback Loops

### → Plan (Detail reveals plan is too vague)

**Trigger:** The plan doesn't provide enough structure to decompose into tasks. Module boundaries are unclear, deliverables are too large, or test scenarios don't map to features.

**Protocol:**
1. Document what's missing: "PLAN.md defines 'search module' but doesn't specify which search features go in MVP vs. v2."
2. Return to aid-plan for revision with the specific gap identified.
3. Revised PLAN.md → resume detailing.

### → Discovery (KB gaps)

**Trigger:** Detailing reveals the KB is incomplete.

**Protocol:**
1. Generate GAP.md with `discovery-needed`.
2. Trigger targeted aid-discover.
3. KB updated → resume detailing with corrected data.

### → Specify (Spec ambiguity)

**Trigger:** The spec is ambiguous and can't be decomposed into tasks.

**Protocol:**
1. Generate GAP.md with `ambiguity`.
2. Trigger aid-specify revision (possibly with targeted interview).
3. Updated spec → resume detailing.

### ← Implement / Review (Loops from downstream)

If implementation or review reveals the detail was wrong (task too large, wrong dependencies, missing task):

1. Receive IMPEDIMENT.md or review feedback.
2. Re-assess affected tasks.
3. Split, reorder, or add tasks as needed.
4. Update DETAIL.md execution plan.

## Quality Checklist

- [ ] Every deliverable in PLAN.md has user stories.
- [ ] Every user story has executable tasks.
- [ ] Every TASK has concrete acceptance criteria.
- [ ] Dependencies form a valid DAG (no cycles).
- [ ] Complexity estimates reference KB data.
- [ ] Parallel execution opportunities are identified.
- [ ] Spikes are identified for uncertain areas.
- [ ] Delivery breakdown has measurable success criteria.
- [ ] Execution plan has clear wave ordering.

## See Also

- [Detail Template](references/detail-template.md) — Full DETAIL.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
