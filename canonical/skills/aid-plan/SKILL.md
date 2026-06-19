---
name: aid-plan
description: >
  Sequence feature SPECs into deliverables — each one a functional MVP that builds
  on the previous. Strategy, not tactics. Use when feature SPECs are complete and
  you need a delivery roadmap.
  State machine: FIRST-RUN → REVIEW → DONE.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
argument-hint: "work-001 (required if multiple works)  [--reset] clear PLAN.md and restart"
---

# Delivery Roadmap

Sequence features into deliverables where each is a functional MVP that works on its own.

## Core Principle

Plan answers ONE question: **"In what order do we deliver, and does each delivery
stand on its own?"**

What Plan does NOT do (already covered by Specify):
- Module mapping, test scenarios, per-feature risks, technical details — all in SPEC.

## The Loop

Each deliverable follows the same cycle:

```
1. PROPOSE  → agent proposes deliverable grouping and sequence
2. DISCUSS  → the user and the agent negotiate (move, reorder, split, merge, defer)
3. WRITE    → save agreed deliverable to PLAN.md
4. REVIEW   → grade against SPECs/KB — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing PLAN.md.**

## Workspace

```
.aid/
  knowledge/                <- shared KB (read)
    STATE.md                <- minimum grade
  work-NNN-{name}/
    STATE.md                <- Pipeline State (authored); Plan/Deliveries is DERIVED (never written here)
    REQUIREMENTS.md         <- read
    PLAN.md                 <- OUTPUT: execution graph (delivery stanzas)
    delivery-NNN/           <- CREATED by aid-plan per delivery approved in PLAN.md
      SPEC.md               <- OUTPUT: delivery definition (scope, gate criteria, tasks, dependencies)
      STATE.md              <- OUTPUT: delivery lifecycle (initial State: Pending-Spec) + gate slot + Q&A slot
    features/
      feature-NNN-{name}/
        SPEC.md             <- read (check Features State in work STATE.md)
```

> Note: `delivery-NNN/` must exist before `aid-detail` nests `tasks/task-NNN/` under it.
> The work `STATE.md` `## Plan / Deliveries` section is a DERIVED read-only view assembled
> at read time from `delivery-NNN/STATE.md` files. `aid-plan` does NOT write delivery rows
> into the work `STATE.md`.

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Plan a specific work. Required if multiple works exist. |
| *(no arg)* | Auto-selects if only one work exists. |
| `--reset` | Delete PLAN.md and start fresh. |

## ⚠️ Pre-flight Checks

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-interview` first."

### Check 2: Verify Feature SPECs

1. Scan `.aid/{work}/features/*/SPEC.md`
2. Check work STATE.md `## Features State` — each feature should be `Ready`
3. No features → **STOP.** "Run `/aid-interview` then `/aid-specify`."
4. Some not Ready → warn, offer to plan with completed only or wait

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

## State Detection

WARNING: **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

- No PLAN.md → **FIRST-RUN**
- PLAN.md exists, grade below minimum or not yet graded → **REVIEW**
- PLAN.md exists, graded >= minimum, delivery folders (`delivery-NNN/SPEC.md` + `delivery-NNN/STATE.md`) written for all deliverables -> **DONE**

Print the state-entry line and "you are here" map:

**FIRST-RUN:**
```
[State: FIRST-RUN] — No PLAN.md found; begin dependency mapping and deliverable sequencing.
aid-plan  ▸ you are here
  [● FIRST-RUN ] → [ REVIEW ] → [ DONE ]
```

**REVIEW:**
```
[State: REVIEW] — PLAN.md exists; re-review deliverables against current SPECs and KB.
aid-plan  ▸ you are here
  [✓ FIRST-RUN ] → [● REVIEW ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Plan is complete and meets minimum grade.
aid-plan  ▸ you are here
  [✓ FIRST-RUN ] → [✓ REVIEW ] → [● DONE ]
```

## Inputs

- **All feature SPECs** — requirements, tech spec, priority, acceptance criteria
- **REQUIREMENTS.md** — scope boundaries, overall priority
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, use summaries to pull
  relevant docs (typically architecture, module-map, tech-debt — but let the INDEX guide you)
- **Known Issues** — `.aid/{work}/known-issues.md` (if exists). Issues registered
  by Specify that block or affect features. Plan may create a fix-first deliverable
  or sequence features to address issues before dependent work.

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| FIRST-RUN | `references/first-run-loop.md` | `aid-architect` | → REVIEW |
| REVIEW | `references/review-deliverables.md` | `aid-reviewer` | → DONE |
| DONE | _(inline — plan complete; print summary and exit)_ | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

**DONE (inline):** When DONE is detected, print:

```
[State: DONE] — Plan is complete and meets minimum grade.
aid-plan  ▸ you are here
  [✓ FIRST-RUN ] → [✓ REVIEW ] → [● DONE ]

Plan is approved and up to date. Run /aid-plan again with --reset to restart.
```

---

## Feedback Loops

- **→ Discovery:** KB insufficient → Q&A to `.aid/knowledge/STATE.md` `## Q&A (Pending)`
- **→ Specify:** SPEC ambiguous → Q&A to work STATE.md `## Cross-phase Q&A`
- **→ Interview:** Priority unclear → Q&A to work STATE.md `## Cross-phase Q&A`

## Output

`aid-plan` produces three artifact types when a delivery is approved:

### 1. `.aid/{work}/PLAN.md` (execution graph)

```markdown
# Plan -- {Work Name}

## Deliverables

### delivery-001: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-001-{name}, feature-003-{name}
- **Depends on:** --
- **Priority:** Must

### delivery-002: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-002-{name}
- **Depends on:** delivery-001
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | {description} | {H/M/L} | {mitigation} |

*(Omit if no cross-cutting risks.)*

## Deferred

| Feature | Reason | Revisit When |
|---------|--------|--------------|
| feature-006-{name} | Could-have | After delivery-003 feedback |

*(Omit if all features included.)*
```

### 2. `.aid/{work}/delivery-NNN/SPEC.md` (delivery definition)

Seeded from `canonical/templates/delivery-spec-template.md` with the delivery's
objective, scope, gate criteria, tasks placeholder, and dependencies filled in from
the approved PLAN.md stanza. Written immediately after writing the delivery stanza
to PLAN.md (Step 4 of The Loop). A delivery with zero tasks (e.g. a SPIKE) gets an
empty Tasks table -- the SPEC still records the delivery's objective and gate criteria.

### 3. `.aid/{work}/delivery-NNN/STATE.md` (delivery lifecycle)

Seeded from `canonical/templates/delivery-state-template.md` with:
- `State: Pending-Spec`  (SD-8: delivery's own independent lifecycle; NOT derived from tasks)
- `Updated:` set to the current UTC timestamp
- `Branch:` set to `aid/work-NNN-delivery-NNN`
- Gate and Q&A sections left as placeholders (filled by `aid-execute`)

A delivery created with ZERO tasks still renders correctly at `Pending-Spec`. The
task rollup table in STATE.md shows `_none yet_` -- that is correct and expected until
`aid-specify` (-> Specified) and `aid-detail` (-> tasks created) run.

The work `STATE.md` `## Plan / Deliveries` section is DERIVED (read-only at read time);
`aid-plan` does NOT write delivery rows there.

## Project Management Sync (conditional)

If `infrastructure.md § Project Management` defines a tool:
- When PLAN.md is approved → create Sprint/Iteration entries for each delivery
- Map deliveries to Sprints in the PM tool

If no PM tool → skip.

## Quality Checklist

- [ ] Every Ready feature assigned to a deliverable or explicitly deferred
- [ ] Each deliverable is standalone-functional
- [ ] Dependencies between deliverables flow one direction (no cycles)
- [ ] Deliverables follow Must -> Should -> Could priority
- [ ] Cross-cutting risks only if real
- [ ] User approved the sequence
- [ ] Each deliverable was reviewed after writing (step 4)
- [ ] delivery-NNN/SPEC.md written for every delivery (including zero-task SPIKE deliveries)
- [ ] delivery-NNN/STATE.md written for every delivery with State: Pending-Spec
- [ ] No delivery rows written into the work STATE.md (Plan/Deliveries is DERIVED)
