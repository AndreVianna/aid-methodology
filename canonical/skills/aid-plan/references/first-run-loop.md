# State: FIRST-RUN

No PLAN.md found; begin dependency mapping and deliverable sequencing.

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

The user may:
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

When the user agrees on a deliverable, **IMMEDIATELY write it to the file.**

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

**Agent:** Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-architect`). The aid-reviewer must run with clean context — it grades against KB/codebase reality without seeing the aid-architect's working notes.

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `per-deliverable`
- `{{ARTIFACTS}}` = the deliverable section just appended to `PLAN.md` + the SPECs of the features it assigns
- `{{CONTEXT}}` = `delivery-NNN of work-NNN just written; preceding deliveries: delivery-NNN..MMM (titles).`

Include in the prompt:
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/plan.md`. Read the existing file first if it exists.
  Output per `canonical/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Print before dispatch: `[Review] Dispatching aid-reviewer for PLAN validation (per-deliverable scope).`

▶ aid-reviewer starting (~1–2 min)
After writing, **review immediately:** Does it hold up?
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}
- All included features' dependencies satisfied by prior deliverables?
- Actually standalone-functional?
- Consistent with KB architecture?

After aid-reviewer returns, run grade.sh:

```bash
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/plan.md
```

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from `bash canonical/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`) | Move to next deliverable. |
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

**Advance:** **CHAIN** → [State: REVIEW] when PLAN.md is written and the final summary is printed (continue inline).
