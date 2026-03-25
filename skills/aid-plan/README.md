# Delivery Roadmap

Sequence features into deliverables — each one a functional MVP that builds on the previous.

## Core Principle

**Plan answers ONE question: "In what order do we deliver, and does each delivery stand on its own?"**

Each deliverable is a shippable increment that works without the next one. Features within a deliverable ship together. Deliverables are ordered by dependency, then priority.

## What Plan Does NOT Do

These are already covered by Specify (per feature):

| Concern | Where it lives |
|---------|---------------|
| Module mapping | Layers & Components in each feature's SPEC.md |
| Test scenarios | Acceptance Criteria / BDD in each feature's SPEC.md |
| Per-feature risks | Trade-offs and spikes captured during Specify |
| Technical details | All in SPEC.md |
| Spike identification | Specify's spike handling (State 3) |

Plan only adds the **sequencing** dimension — how features relate to each other in delivery order, and cross-cutting risks that span features.

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    REQUIREMENTS.md         ← read (scope, priorities)
    PLAN.md                 ← OUTPUT
    features/
      feature-NNN-{name}/
        SPEC.md             ← read (requirements + tech spec)
        STATE.md            ← read (check Ready status)
```

## When to Use

- **Primary:** After all features in a work have been specified (STATE.md status: Ready).
- **Re-entry:** When Detail can't decompose deliverables because sequencing is unclear or wrong.

## Inputs

- **Feature SPECs** — all `aid-workspace/{work}/features/*/SPEC.md` with Ready status.
- **REQUIREMENTS.md** — scope boundaries, constraints, overall priority (§10).
- **KB (selective):** architecture.md, module-map.md, tech-debt.md — for understanding cross-feature dependencies and fragile areas.

## Process

### 1. Map Dependencies

For each feature:
- **What it needs** — does it depend on another feature's output? (data model, API, service)
- **What it enables** — which features depend on this one?
- **What it touches** — which modules/areas of the codebase (from SPEC Layers & Components)

Build a dependency graph. Features with no shared dependencies can be in any order.

### 2. Group into Deliverables

Each deliverable MUST be:
- **Functional on its own** — a user can use it without the next deliverable.
- **Testable independently** — acceptance criteria from included SPECs can all be verified.
- **Buildable in order** — dependencies satisfied by earlier deliverables.

Grouping heuristics:
- Must-have features first, then Should, then Could.
- Foundation features (auth, data model setup) in D-1.
- Features with shared dependencies go together.
- Small independent features can be bundled.
- Large independently-valuable features can be a deliverable alone.

### 3. Cross-Cutting Risks (Optional)

Risks that Specify couldn't see because they span features:
- Multiple features touching the same fragile module (from tech-debt.md).
- Sequencing risks — if D-1 slips, D-2 through D-N all slip.
- Integration risks — features that work alone but might conflict when combined.

**Only include if cross-cutting risks actually exist.** Don't manufacture risks.

### 4. Present and Approve

Present the delivery sequence to the user. Wait for approval or adjustments before writing PLAN.md.

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

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|

*(Omit if no cross-cutting risks exist.)*

## Deferred

| Feature | Reason | Revisit When |
|---------|--------|--------------|

*(Omit if all features are included.)*
```

## Feedback Loops

### → Discovery

KB insufficient for dependency analysis → write Q&A entry to `DISCOVERY-STATE.md`.

### → Specify

SPEC ambiguous about what a feature needs or enables → write Q&A entry to feature's `STATE.md`.

### → Interview

Requirements priority unclear → write Q&A entry to work's `INTERVIEW-STATE.md`.

### ← Detail

Plan too vague for task decomposition → receive feedback, revise specific deliverables.

## Quality Checklist

- [ ] Every Ready feature assigned to a deliverable or explicitly deferred.
- [ ] Each deliverable works as a standalone MVP.
- [ ] Dependencies between deliverables flow one direction (no cycles).
- [ ] Deliverable order follows Must → Should → Could priority.
- [ ] Cross-cutting risks only included if they actually exist.
- [ ] User approved the sequence.
- [ ] PLAN.md lives inside the work directory.

## Why This Phase Exists

Features specified in isolation don't tell you what to build first. Plan adds the one thing Specify can't: delivery order. Which features form the foundation? Which can ship independently? Which must wait?

Without Plan, you'd go straight from specs to task decomposition with no intermediate reasoning about what "done" looks like at each stage. Each deliverable is a checkpoint — a working system the user can touch, not just a batch of completed tasks.

## Related Phases

- **Previous:** [Specify](../aid-specify/) — provides per-feature technical specs
- **Next:** [Detail](../aid-detail/) — decomposes deliverables into executable tasks
- **Triggered by:** Feedback from Detail when deliverable boundaries are unclear

## See Also

- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
