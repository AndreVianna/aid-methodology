---
name: aid-plan
description: >
  Sequence feature SPECs into deliverables — each one a functional MVP that builds
  on the previous. Strategy, not tactics. Use when feature SPECs are complete and
  you need a delivery roadmap.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
---

# Delivery Roadmap

Produce PLAN.md: sequence features into deliverables where each deliverable is a
functional MVP that works on its own.

## Core Principle

Plan answers ONE question: **"In what order do we deliver, and does each delivery
stand on its own?"**

- Each deliverable is a shippable increment — it works without the next one.
- Features within a deliverable ship together.
- Deliverables are ordered by dependency, then priority.

What Plan does NOT do (already covered by Specify):
- Module mapping → Layers & Components in SPEC
- Test scenarios → Acceptance Criteria / BDD in SPEC
- Per-feature risks → trade-offs and spikes in SPEC
- Technical details → SPEC handles all of this

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    REQUIREMENTS.md         ← read
    PLAN.md                 ← OUTPUT
    features/
      feature-NNN-{name}/
        SPEC.md             ← read (requirements + tech spec)
        STATE.md            ← read (check Ready status)
```

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Plan a specific work. Required if multiple works exist. |
| *(no arg)* | Auto-selects if only one work exists. |

## Pre-flight

### Check 1: Locate Work

1. If arg provided → use that work directory
2. If single work exists → auto-select
3. If multiple works → list them, ask user to choose
4. If no works → **STOP.** "No works found. Run `/aid-interview` first."

### Check 2: Verify Feature SPECs

1. Scan `aid-workspace/{work}/features/*/SPEC.md`
2. For each, check `STATE.md` — status should be `Ready`
3. If **no features exist** → **STOP.** "No features found. Run `/aid-interview` then `/aid-specify`."
4. If **some features not Ready** → warn:
   ```
   ⚠️ {N} of {M} features have incomplete SPECs:
   - feature-002-reporting: In Discussion
   - feature-004-auth: Spike Needed

   [1] Plan with completed features only (defer incomplete ones)
   [2] Wait — go finish SPECs first
   ```

### Check 3: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell user to switch out of Plan Mode.

## Inputs

Read these before planning:

- **All feature SPECs** (`aid-workspace/{work}/features/*/SPEC.md`) — requirements, tech spec, priority, acceptance criteria
- **REQUIREMENTS.md** — scope boundaries, constraints, overall priority (§10)
- **KB (selective):** `aid-workspace/knowledge/architecture.md`, `module-map.md`, `tech-debt.md` — for understanding cross-feature dependencies and fragile areas

## Process

### 1. Map Dependencies

For each feature, determine:
- **What it needs** — does it depend on another feature's output? (data model, API, service)
- **What it enables** — which features depend on this one?
- **What it touches** — which modules/areas of the codebase (from SPEC Layers & Components)

Build a dependency graph. Features that share no dependencies can be in any order.
Features with dependencies must be sequenced.

### 2. Group into Deliverables

Cluster features into deliverables. Each deliverable MUST be:
- **Functional on its own** — a user can use it without the next deliverable
- **Testable independently** — acceptance criteria from the included SPECs can all be verified
- **Buildable in order** — its dependencies are satisfied by earlier deliverables

Grouping heuristics:
- Must-have features first, then Should, then Could
- Foundation features (auth, data model setup) in D-1
- Features with shared dependencies go together
- Small independent features can be bundled into one deliverable
- Large features that are independently valuable can be a deliverable alone

### 3. Identify Cross-Cutting Risks (if any)

These are risks that Specify couldn't see because they span features:
- Multiple features touching the same fragile module (from tech-debt.md)
- Sequencing risks — if D-1 slips, D-2 through D-N all slip
- Resource contention — two features needing the same person/expertise simultaneously
- Integration risks — features that work alone but might conflict when combined

**Only include this section if cross-cutting risks actually exist.** Don't manufacture risks.

### 4. Present to User

```
Here's the delivery sequence for {work}:

**D-1: {Name}** — {what this delivers to the user}
  Features: feature-001-{name}, feature-003-{name}
  Depends on: — (foundation)
  Priority: Must

**D-2: {Name}** — {what this adds}
  Features: feature-002-{name}
  Depends on: D-1
  Priority: Must

**D-3: {Name}** — {what this adds}
  Features: feature-004-{name}, feature-005-{name}
  Depends on: D-1
  Priority: Should

{If cross-cutting risks exist:}
**Cross-Cutting Risks:**
- {risk}: {impact} — {mitigation}

Does this sequence make sense?

[1] Approve
[2] Adjust — tell me what to change
```

Wait for response. If [2], adjust and present again.

## Feedback Loops

- **→ Discovery:** KB insufficient for dependency analysis → Q&A to `aid-workspace/knowledge/DISCOVERY-STATE.md`
- **→ Specify:** SPEC ambiguous about what a feature needs/enables → Q&A to feature's `STATE.md`
- **→ Interview:** Requirements priority unclear → Q&A to work's `INTERVIEW-STATE.md`

## Output

`aid-workspace/{work}/PLAN.md`:

```markdown
# Plan — {Work Name}

## Deliverables

### D-1: {Name}
- **What it delivers:** {user-facing value — one sentence}
- **Features:** feature-001-{name}, feature-003-{name}
- **Depends on:** — (foundation)
- **Priority:** Must

### D-2: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-002-{name}
- **Depends on:** D-1
- **Priority:** Must

### D-3: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-004-{name}, feature-005-{name}
- **Depends on:** D-1
- **Priority:** Should

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | {description} | {High/Medium/Low} | {what to do about it} |

*(Omit this section if no cross-cutting risks exist.)*

## Deferred

| Feature | Reason | Revisit When |
|---------|--------|--------------|
| feature-006-{name} | Could-have, low priority | After D-3 feedback |

*(Omit this section if all features are included.)*
```

## Quality Checklist

- [ ] Every Ready feature assigned to a deliverable or explicitly deferred
- [ ] Each deliverable works as a standalone MVP
- [ ] Dependencies between deliverables flow one direction (no cycles)
- [ ] Deliverable order follows Must → Should → Could priority
- [ ] Cross-cutting risks only included if they actually exist
- [ ] User approved the sequence
- [ ] PLAN.md lives inside the work directory
