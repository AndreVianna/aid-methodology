---
name: aid-plan
description: >
  Define the high-level roadmap from feature SPECs — MVP scope, module identification,
  deliverable scoping, test scenarios, risk assessment. Strategy, not tactics.
  Use when feature SPECs are complete and you need a roadmap, or when a GAP.md triggers re-planning.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
---

# High-Level Roadmap

Produce PLAN.md: MVP definition, modules, deliverables, test scenarios, risks.

## Core Principle

Plan is strategy. Detail is tactics. Plan answers "what do we build and in what order?" Detail answers "how do we build it?"

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  task-NNN-{name}/          ← the task being planned
    REQUIREMENTS.md         ← stakeholder requirements (read)
    PLAN.md                 ← OUTPUT: this is what we produce
    features/
      feature-NNN-{name}/
        SPEC.md             ← per-feature tech spec (read)
        STATE.md            ← specify process state (read, check all Done)
```

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN` | Plan a specific task. Required if multiple tasks exist. |
| *(no arg)* | Auto-selects if only one task exists. |

## Pre-flight

### Check 1: Locate Task

1. If arg provided → use that task directory
2. If single task exists → auto-select
3. If multiple tasks → list them, ask user to choose
4. If no tasks → **STOP.** "No tasks found. Run `/aid-interview` first."

### Check 2: Verify Feature SPECs

1. Scan `aid-workspace/{task}/features/*/SPEC.md`
2. For each, check the corresponding `STATE.md` — status should be `Done`
3. If **no features exist** → **STOP.** "No features found. Run `/aid-interview` to decompose requirements into features, then `/aid-specify` to write SPECs."
4. If **some features not Done** → warn:
   ```
   ⚠️ {N} of {M} features have incomplete SPECs:
   - feature-002-reporting: status is "In Discussion"
   - feature-004-auth: status is "Spike Needed"

   [1] Plan with completed features only (defer incomplete ones)
   [2] Wait — go finish SPECs first
   ```

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell user to switch out of Plan Mode.

## Inputs

- **Feature SPECs:** All `aid-workspace/{task}/features/*/SPEC.md` files (with Done status)
- **Requirements:** `aid-workspace/{task}/REQUIREMENTS.md`
- **KB (selective):** `aid-workspace/knowledge/` — architecture.md, module-map.md, tech-debt.md, test-landscape.md, infrastructure.md

## Process

### 1. Define MVP

Read all feature SPECs. Each feature already has a priority (Must/Should/Could from REQUIREMENTS → SPEC).

- **MVP = all Must-have features** (minimum viable set)
- List included features with justification (from SPEC priority + business value)
- List deferred features with reasoning (Could-have, or Should-have with high risk)
- If a Must-have depends on an incomplete SPEC → flag as risk

### 2. Identify Modules

Map features to system modules using KB (architecture.md, module-map.md):
- For each module: features contained, existing vs. new code, risk level
- Risk assessment uses: tech-debt.md (known debt in that module), test-landscape.md (coverage gaps), feature SPEC complexity
- Cross-module dependencies (feature A touches module X, feature B also touches module X → sequencing matters)

### 3. Scope Deliverables

Group features into shippable increments. Good boundaries:
- Independent features that can be released together
- Natural progression (foundation → dependent features)
- Testable independently
- Each deliverable: features included, modules touched, dependencies on other deliverables, what it validates

### 4. Define Test Scenarios

Per deliverable: high-level scenarios that prove it works.
- Describe **what to prove**, not how to test
- Format: `TS-{id}: {scenario description}`
- Reference feature acceptance criteria from SPECs
- Include cross-feature integration scenarios where deliverables combine

### 5. Risk Assessment

Table: Risk | Impact | Likelihood | Mitigation | Source

Source references: tech-debt.md, feature SPEC spike flags, infrastructure.md constraints.

### 6. Identify Spikes

Time-boxed research tasks for uncertain areas. Generate when:
- Feature SPEC has status "Spike Needed" or "Spike Info" recorded
- New technology not in technology-stack.md
- Risk needs investigation before planning can be confident
- KB has blocking open question

## Feedback Loops

- **→ Discovery:** KB incomplete for planning → write Q&A entry to `aid-workspace/knowledge/DISCOVERY-STATE.md`
- **→ Specify:** SPEC ambiguous or contradictory → write Q&A entry to feature's `STATE.md`
- **→ Interview:** Requirements unclear for planning → write Q&A entry to task's `INTERVIEW-STATE.md`
- **← Detail:** Plan too vague → receive feedback, revise

## Output

`aid-workspace/{task}/PLAN.md` with:

```markdown
# Plan — {Task Name}

## MVP Definition
### Included Features (Must-Have)
### Deferred Features

## Module Map
### {Module Name}
- Features: F-001, F-003
- Existing code: {description}
- New code needed: {description}
- Risk: {Low/Medium/High} — {reasoning}

## Deliverables

### D-1: {Name}
- **Features:** F-001, F-002
- **Modules:** {list}
- **Depends on:** — (none / D-x)
- **Validates:** {what this proves}
- **Test Scenarios:**
  - TS-001: {description}
  - TS-002: {description}

### D-2: {Name}
...

## Risk Assessment

| # | Risk | Impact | Likelihood | Mitigation | Source |
|---|------|--------|------------|------------|--------|

## Spikes

| # | Topic | Time-Box | Blocking | Source |
|---|-------|----------|----------|--------|
```

## Quality Checklist

- [ ] MVP clearly defined with justification referencing feature priorities
- [ ] Every feature SPEC (with Done status) assigned to a deliverable or explicitly deferred
- [ ] Module boundaries match KB architecture.md
- [ ] Deliverable dependencies are meaningful (not artificial)
- [ ] Test scenarios defined per deliverable, referencing SPEC acceptance criteria
- [ ] Risks assessed with mitigations and sources
- [ ] Spikes identified for uncertain areas (from SPEC spike flags + KB gaps)
- [ ] PLAN.md lives inside the task directory, not project root
