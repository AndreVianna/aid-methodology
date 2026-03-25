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

### 4. Present & Negotiate

Present the proposed sequence clearly:

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

Does this sequence make sense? You can:
[1] Approve
[2] Adjust — tell me what to change (move features, reorder, split, merge, defer)
```

### 5. Adjustment Loop

If user chooses [2] or describes a change in natural language, enter the adjustment loop.

**Supported adjustments:**
- **Move feature** — "move feature-004 from D-3 to D-2"
- **Reorder deliverables** — "swap D-2 and D-3" or "I want SSO before self-service"
- **Split deliverable** — "D-1 is too big, split login and roles"
- **Merge deliverables** — "combine D-2 and D-3 into one"
- **Defer feature** — "push feature-005 out of scope for now"
- **Change priority** — "OAuth is actually a Must, not a Should"

**For every adjustment:**
1. **Check dependencies** — does the change break the dependency graph?
   - If yes → warn the user: "Moving feature-004 to D-1 would break a dependency: it needs the auth middleware from feature-001 which is also in D-1. That's fine (same deliverable), but feature-004 needs feature-002's API which is in D-2. Options: (a) move feature-002 to D-1 as well, (b) keep feature-004 in D-3."
   - If no → apply the change
2. **Re-present the updated sequence** — show the full plan again, not just the diff
3. **Ask again** — approve or adjust?

**Loop until approved.** No limit on iterations — the user drives the sequence.

**Natural language:** Users won't always say "move feature-004 from D-3 to D-2." They'll say
"I want OAuth before password reset" or "clients are asking for SSO first." Interpret intent,
map it to deliverable changes, confirm understanding before applying.

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

## Re-run = Review

If PLAN.md already exists when `/aid-plan` is run, the agent reviews it instead of
starting from scratch.

### Step 1: Load Current State

Re-read all feature SPECs, REQUIREMENTS.md, and relevant KB docs (same as initial run).

### Step 2: Check for Changes

Compare the current state against what PLAN.md was based on:
1. **New features** — features added since PLAN.md was written (not assigned to any deliverable)
2. **Removed features** — features in PLAN.md that no longer exist
3. **Changed SPECs** — features whose SPEC.md changed (compare Change Log dates vs PLAN.md date)
4. **Priority shifts** — feature priorities that changed in REQUIREMENTS.md
5. **New cross-cutting risks** — risks that emerged from new features or SPEC changes
6. **Dependency changes** — features whose dependencies changed (new shared modules, removed APIs)

### Step 3: Grade

| Grade | Meaning | Action |
|-------|---------|--------|
| **A** | Plan is current. No changes detected. | Print summary, no changes needed. |
| **B** | Minor changes. 1–2 features shifted, no structural impact. | Present changes, adjust inline. |
| **C** | Significant changes. Deliverable restructuring needed. | Present findings, re-run grouping for affected deliverables. |
| **D** | Major changes. New features or removed features invalidate the sequence. | Recommend `--reset` and re-plan. |

### Step 4: Present Findings

```
Reviewing {work} plan against current feature SPECs...

**Grade: {grade}**

{If A:}
✅ Plan is current. All deliverables still valid.

{If B/C:}
**Changes detected:**
1. {what changed} — {impact on plan}
2. {what changed} — {impact on plan}
...

[1] Apply changes — update PLAN.md
[2] Re-plan from scratch — regenerate deliverable sequence
[3] Skip — keep current plan
```

Process response and update PLAN.md accordingly. Add Change Log entry.

## Quality Checklist

- [ ] Every Ready feature assigned to a deliverable or explicitly deferred
- [ ] Each deliverable works as a standalone MVP
- [ ] Dependencies between deliverables flow one direction (no cycles)
- [ ] Deliverable order follows Must → Should → Could priority
- [ ] Cross-cutting risks only included if they actually exist
- [ ] User approved the sequence
- [ ] PLAN.md lives inside the work directory
