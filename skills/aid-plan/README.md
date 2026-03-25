# aid-plan

Sequence features into deliverables — each one a functional MVP that builds on the previous.

Plan answers ONE question: **"In what order do we deliver, and does each delivery stand on its own?"**

## The Universal Loop

Each deliverable follows the same cycle:

```
1. PROPOSE  → agent maps dependencies, proposes deliverable grouping
2. DISCUSS  → developer negotiates (move, reorder, split, merge, defer)
3. WRITE    → save agreed deliverable to PLAN.md
4. REVIEW   → grade against SPECs/KB — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing PLAN.md.**

## Usage

```
/aid-plan work-001
/aid-plan                   # auto-selects when single work
/aid-plan work-001 --reset
```

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
```

## How It Works

### First Run

1. **Map dependencies** — for each feature: what it needs, enables, and touches
2. **Propose first deliverable** — must be functional on its own, testable, foundation-first
3. **Discuss** — move features, split, merge, reorder, defer, change priority. Agent checks dependencies on every adjustment.
4. **Write and review** — save to PLAN.md, verify standalone-functional with dependencies satisfied. Grade A/B/C.
5. **Next deliverable** — same loop until all features assigned or deferred
6. **Cross-cutting risks** (if any) — risks spanning features (fragile shared modules, sequencing, integration)
7. **Summary**

### Re-run (Review)

When PLAN.md exists, re-run enters the loop at step 4:
- Checks for new/removed features, changed SPECs, priority shifts, dependency changes
- Grades A–D overall
- Re-enters the loop for affected deliverables

## What Plan Does NOT Do

Already covered by Specify:
- Module mapping → Layers & Components in SPEC
- Test scenarios → Acceptance Criteria / BDD in SPEC
- Per-feature risks → trade-offs and spikes in SPEC
- Technical details → SPEC handles all of this

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

### delivery-002: ...

## Cross-Cutting Risks (optional)
## Deferred (optional)
```

## Feedback Loops

- **→ Discovery:** KB insufficient → Q&A to DISCOVERY-STATE.md
- **→ Specify:** SPEC ambiguous → Q&A to feature's STATE.md
- **→ Interview:** Priority unclear → Q&A to INTERVIEW-STATE.md
