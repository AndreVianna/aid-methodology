---
name: aid-plan
description: >
  Sequence feature SPECs into deliverables — each one a functional MVP that builds
  on the previous. Strategy, not tactics. Use when feature SPECs are complete and
  you need a delivery roadmap.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
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
2. DISCUSS  → developer and agent negotiate (move, reorder, split, merge, defer)
3. WRITE    → save agreed deliverable to PLAN.md
4. REVIEW   → grade against SPECs/KB — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing PLAN.md.**

## Workspace

```
.aid/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    REQUIREMENTS.md         ← read
    PLAN.md                 ← OUTPUT
    features/
      feature-NNN-{name}/
        SPEC.md             ← read
        STATE.md            ← check Ready status
```

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Plan a specific work. Required if multiple works exist. |
| *(no arg)* | Auto-selects if only one work exists. |
| `--reset` | Delete PLAN.md and start fresh. |

## Pre-flight

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-interview` first."

### Check 2: Verify Feature SPECs

1. Scan `.aid/{work}/features/*/SPEC.md`
2. Check each `STATE.md` — should be `Ready`
3. No features → **STOP.** "Run `/aid-interview` then `/aid-specify`."
4. Some not Ready → warn, offer to plan with completed only or wait

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.**

### Check 4: Detect State

- No PLAN.md → **FIRST RUN** (Step 1)
- PLAN.md exists → **REVIEW** (enter loop at step 4)

## Inputs

- **All feature SPECs** — requirements, tech spec, priority, acceptance criteria
- **REQUIREMENTS.md** — scope boundaries, overall priority
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, use summaries to pull
  relevant docs (typically architecture, module-map, tech-debt — but let the INDEX guide you)
- **Known Issues** — `.aid/{work}/known-issues.md` (if exists). Issues registered
  by Specify that block or affect features. Plan may create a fix-first deliverable
  or sequence features to address issues before dependent work.

---

## FIRST RUN — The Loop

### Step 1: Map Dependencies

For each feature:
- What it **needs** (depends on another feature's output?)
- What it **enables** (other features depend on this?)
- What it **touches** (modules/areas from SPEC Layers & Components)
- What **known issues** affect it? (from `known-issues.md` — issues with
  Severity Critical/High that block a feature may need a fix-first deliverable)

Build dependency graph. No-dependency features can be in any order.

### Step 2: Propose First Deliverable

Group features into the first deliverable. It MUST be:
- **Functional on its own** — usable without the next deliverable
- **Testable independently** — acceptance criteria verifiable
- **Foundation first** — dependencies satisfied

```
**delivery-001: {Name}** — {what this delivers to the user}
  Features: feature-001-{name}, feature-003-{name}
  Depends on: — (foundation)
  Priority: Must

This deliverable covers {rationale}. I grouped these because {reason}.

What do you think? We can discuss:
- Which features belong here
- Whether to split or merge
- Priority ordering
```

### Step 3: Discuss

The developer may:
- **Agree** → write and review
- **Move feature** → "put feature-004 here instead"
- **Split** → "too big, separate login from roles"
- **Merge** → "combine these two deliverables"
- **Reorder** → "I want SSO before self-service"
- **Defer** → "push feature-005 out of scope"
- **Change priority** → "OAuth is actually a Must"

For every adjustment:
1. Check dependencies — does it break the graph? Warn if so, offer alternatives.
2. Re-present the updated deliverable
3. Loop until approved

### Step 4: Write and Review

When the developer agrees on a deliverable, **IMMEDIATELY write it to the file.**

**First deliverable:** Create `.aid/{work}/PLAN.md` with the header and first deliverable:
```markdown
# Plan — {Work Name}

## Deliverables

### delivery-001: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-001-{name}, feature-003-{name}
- **Depends on:** —
- **Priority:** Must
```

**Subsequent deliverables:** Append to the existing PLAN.md.

⚠️ **DO NOT continue to the next deliverable without writing this one first.**
⚠️ **DO NOT accumulate multiple deliverables "in your head" — write each one immediately.**

After writing, **review immediately:** Does it hold up?
- All included features' dependencies satisfied by prior deliverables?
- Actually standalone-functional?
- Consistent with KB architecture?

Use the universal rubric (`../../../templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from DISCOVERY-STATE.md) | Move to next deliverable. |
| Grade < minimum, fixable | Back to Propose with findings. |

```
✅ delivery-001 written to PLAN.md and verified — dependencies satisfied,
standalone-functional. Moving to delivery-002.
```

### Step 5: Next Deliverable

Propose the next deliverable → same loop (steps 2–4). Repeat until all features
are assigned to deliverables or explicitly deferred.

### Step 6: Cross-Cutting Risks (if any)

After all deliverables are written, check for risks that span features:
- Multiple features touching same fragile module (from tech-debt.md)
- Sequencing risks — delivery-001 slips, everything slips
- Integration risks — features work alone but might conflict combined

**Only include if real.** Don't manufacture risks.

### Step 7: Final Summary

**Before printing the summary, verify PLAN.md is complete:**
1. Read `.aid/{work}/PLAN.md` from disk
2. Confirm every agreed deliverable is written
3. If any deliverable is missing → write it NOW
4. If Cross-Cutting Risks or Deferred sections apply → append them NOW

Then print:
```
Plan complete for {work}:

delivery-001: {Name} → features 001, 003
delivery-002: {Name} → features 002
delivery-003: {Name} → features 004, 005

{If deferred:}
Deferred: feature-006 (Could-have, revisit after delivery-003 feedback)

{If cross-cutting risks:}
Cross-cutting risks: {count} identified (see PLAN.md)

PLAN.md written to: .aid/{work}/PLAN.md ✅
```

---

## REVIEW (re-run on existing PLAN.md)

PLAN.md exists and was previously completed.

**Ask first:** _"This plan is already complete. Do you want to reopen it for review?
Is there something specific you want to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the review.

Enter **the same loop at step 4** — review each deliverable
against current reality.

### Load Current State

Re-read all feature SPECs, REQUIREMENTS.md, KB docs (same as first run).

### Review Each Deliverable

For each deliverable in PLAN.md, run step 4:

1. **New features** not assigned to any deliverable?
2. **Removed features** still referenced in PLAN.md?
3. **Changed SPECs** since PLAN.md was written?
4. **Priority shifts** in REQUIREMENTS.md?
5. **Dependency changes** from SPEC updates?
6. **Cross-cutting risks** emerged or resolved?

### Grade Overall

Use the universal rubric (`../../../templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

Compare to minimum grade from DISCOVERY-STATE.md.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. |
| Grade < minimum, deliverables fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, sequence invalidated | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.

---

## Feedback Loops

- **→ Discovery:** KB insufficient → Q&A to `.aid/knowledge/DISCOVERY-STATE.md`
- **→ Specify:** SPEC ambiguous → Q&A to feature's `STATE.md`
- **→ Interview:** Priority unclear → Q&A to work's `INTERVIEW-STATE.md`

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
