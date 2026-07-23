# Task Decomposition — Rules, Types, and Format

Shared reference for the FIRST-RUN and REVIEW states. Defines how tasks are typed,
sized, formatted, and quality-gated within a delivery.

---

## Agents Involved

- **Default executor:** `aid-architect` (proposes and refines task breakdown grounded in PLAN/SPEC).
- **Reviewer:** `aid-reviewer` (grades the task list against SPEC/PLAN coherence — runs in clean context).
- **Specialist consults (optional):** `aid-architect` for DESIGN-typed tasks, `aid-developer` for MIGRATE-typed tasks, `aid-researcher` for tasks touching auth/PII.

## The Loop

Each deliverable follows the same cycle:

```
1. PROPOSE  → agent proposes task breakdown for a deliverable
2. DISCUSS  → the user and the agent refine (size, scope, sequence, criteria)
3. WRITE    → save agreed tasks to files
4. REVIEW   → grade tasks against SPEC/PLAN — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing tasks.**

## Workspace

```
.aid/
  knowledge/                ← shared KB (read)
    STATE.md                ← minimum grade
  work-NNN-{name}/
    STATE.md                # work-level state; ## Tasks State is a DERIVED view (not written here)
    PLAN.md                 # roadmap with deliverables (read -- must exist)
    features/
      feature-NNN-{name}/
        SPEC.md             # per-feature tech spec (read)
    deliveries/
      delivery-NNN/           # OUTPUT: per-delivery folder (one per deliverable in PLAN.md)
        tasks/
          task-NNN/           # OUTPUT: per-task folder
            DETAIL.md         # task definition (6-section schema; written by aid-detail)
            STATE.md          # task state, seeded Pending (written by aid-detail; updated by aid-execute)
```

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Detail a specific work. Required if multiple works exist. |
| *(no arg)* | Auto-selects if only one work exists. |
| `--reset` | Delete all task folders under `deliveries/delivery-NNN/tasks/` and start fresh. |

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

1. **Spike Needed** in work STATE.md `## Features State` → RESEARCH task first
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

Each task is a **folder** containing two files:

- **`deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`** — the immutable task definition (6-section
  schema), seeded from `.github/aid/templates/task-detail-template.md`:

```markdown
# task-NNN: {Title}

> **Execution protocol** blockquote note (write State at each transition;
> binds whoever executes -- carried verbatim from task-detail-template.md,
> not shown again here for brevity)

**Type:** RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE

**Source:** work-NNN-{name} -> delivery-NNN

**Depends on:** task-NNN [, task-NNN] | -- (none)

**Scope:**
- {what to produce or modify -- depends on type}

**Acceptance Criteria:**
- [ ] Criterion 1 -- concrete, testable
- [ ] Criterion 2 -- concrete, testable
```

Six sections (Title, Type, Source, Depends on, Scope, Acceptance Criteria) plus
the fixed Execution protocol note carried automatically from the template.
Nothing else.

- **`deliveries/delivery-NNN/tasks/task-NNN/STATE.md`** — seeded from `.github/aid/templates/task-state-template.md`,
  replacing the frontmatter block's placeholder lines with the real opening values
  (`state: Pending`, `review: --`, `elapsed: --`, `notes: --` — task-001/004; the
  leading YAML block is the sole home for these 4 scalars), and the correct
  Task/Delivery/Work header fields. Updated by `aid-execute`
  (`writeback-state.sh --task-id NNN --field ...`); never written by `aid-detail` after seeding.

Do NOT write task rows into the work `STATE.md` `## Tasks State` section. That is a DERIVED
read-only view assembled at read time from the per-task STATE.md files (parent derives, never writes).

**Descriptive-title rule (PF-3):** The `{Title}` on line 1 MUST be a **descriptive short-name** — a
noun phrase naming the deliverable of the task (e.g. `Python thin server + /api/model endpoint`).
It must NOT be a restatement of the task type (e.g. not `IMPLEMENT task-007`) and NOT a bare id
(e.g. not `task-007`). The title is the task's human display name in the dashboard; it is parsed via
`^#\s+task-0*\d+\s*:\s*(.+)$`. `/aid-execute` preserves the title line verbatim on any task-file
update — it does not overwrite it.

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
- [ ] All task files in `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (nested hierarchy)

## Feedback Loops

- **→ Plan:** Plan too vague to decompose → return to `/aid-plan`
- **→ Specify:** SPEC missing detail for scope → write Q&A to `.aid/works/{work}/STATE.md` `## Cross-phase Q&A`
- **→ Discovery:** KB gap → write Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)`

## Ticket Suggestion (conditional)

If a catalogued `issue-tracker` connector exists in `.aid/connectors/` → when tasks are approved,
print a suggestion: consider filing a ticket per task via `/aid-create-ticket`. Optional,
user-initiated, never auto-invoked; silent (no output) if no issue-tracker connector is
catalogued.

**Advance:** **CHAIN** → continue with the parent state's flow.
