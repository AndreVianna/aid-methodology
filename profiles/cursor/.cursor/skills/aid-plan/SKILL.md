---
name: aid-plan
description: >
  Sequence feature SPECs into deliverables — each one a functional MVP that builds
  on the previous. Strategy, not tactics. Use when feature SPECs are complete and
  you need a delivery roadmap.
  State machine: FIRST-RUN → REVIEW → DONE.
allowed-tools: Read, Glob, Grep, Write, Edit, Terminal
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
  knowledge/                ← shared KB (read)
    STATE.md                ← minimum grade
  work-NNN-{name}/
    STATE.md                ← § Plan / Deliveries (written here)
    REQUIREMENTS.md         ← read
    PLAN.md                 ← OUTPUT
    features/
      feature-NNN-{name}/
        SPEC.md             ← read (check Features Status in work STATE.md)
```

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
2. Check work STATE.md `## Features Status` — each feature should be `Ready`
3. No features → **STOP.** "Run `/aid-interview` then `/aid-specify`."
4. Some not Ready → warn, offer to plan with completed only or wait

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

- No PLAN.md → **FIRST-RUN**
- PLAN.md exists, grade below minimum or not yet graded → **REVIEW**
- PLAN.md exists, graded ≥ minimum, work STATE.md `## Plan / Deliveries` updated → **DONE**

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

`.aid/{work}/PLAN.md`:

```markdown
# Plan — {Work Name}

## Deliverables

### delivery-001: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-001-{name}, feature-003-{name}
- **Depends on:** —
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

## Project Management Sync (conditional)

If `infrastructure.md § Project Management` defines a tool:
- When PLAN.md is approved → create Sprint/Iteration entries for each delivery
- Map deliveries to Sprints in the PM tool

If no PM tool → skip.

## Quality Checklist

- [ ] Every Ready feature assigned to a deliverable or explicitly deferred
- [ ] Each deliverable is standalone-functional
- [ ] Dependencies between deliverables flow one direction (no cycles)
- [ ] Deliverables follow Must → Should → Could priority
- [ ] Cross-cutting risks only if real
- [ ] User approved the sequence
- [ ] Each deliverable was reviewed after writing (step 4)
