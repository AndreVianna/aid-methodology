# FIRST-RUN — Propose, Discuss, Write, Review

No task files exist yet. Begin proposing task breakdown per deliverable.

Load `references/task-decomposition.md` for task type rules, file format, and quality criteria.

---

## FIRST RUN — The Loop

### Step 1: Propose Tasks for First Deliverable

Read the first deliverable from PLAN.md. Identify its features, read their SPECs.
Propose a sequential task breakdown:

```
**delivery-001: {Name}**

I'm proposing {n} tasks:

1. **task-001: {title}** [RESEARCH]
   Scope: {brief description}
   Criteria: {brief summary}

2. **task-002: {title}** [DESIGN]
   Scope: {brief description}
   Criteria: {brief summary}

3. **task-003: {title}** [IMPLEMENT]
   Scope: {brief description}
   Criteria: {brief summary}

4. **task-004: {title}** [TEST]
   Scope: {brief description}
   Criteria: {brief summary}

What do you think? We can discuss:
- **Type** — should any task be a different type? Am I mixing types?
- **Size** — is any task too big or too small?
- **Scope** — should something move between tasks?
- **Dependencies** — are the dependencies right? Can anything run in parallel?
- **Criteria** — are the acceptance criteria concrete enough?
```

### Step 2: Discuss

The user may:
- **Retype** → "task-002 should be MIGRATE not IMPLEMENT"
- **Split** → "task-002 is too big, separate the migration from the model"
- **Merge** → "003 and 004 are tiny, combine them" (only if SAME type)
- **Reorder** → "swap 002 and 003 — need the service first"
- **Scope change** → "task-001 should also include the config file"
- **Criteria change** → "add index creation to task-001's criteria"
- **Approve** → "looks good"

⚠️ **Merge rule:** only merge tasks of the same type. Never merge across types.

Respond to each concern, re-present affected tasks. Loop until approved.

### Step 3: Write and Review

Once approved:
1. Write task files to `.aid/{work}/tasks/`
2. **Review immediately:** Do the tasks hold up?
   - Does each task have what it needs from the previous?
   - Any gap where something is used before it's created?
   - Scope aligned with what the SPECs actually say?
   - Criteria concrete enough to verify?

**Agent:** Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-architect`). The aid-reviewer must run with clean context — it grades against KB/codebase reality without seeing the aid-architect's working notes.

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `per-deliverable`
- `{{ARTIFACTS}}` = the task files just written for delivery-NNN + the Execution Graph section just appended to PLAN.md (if present)
- `{{CONTEXT}}` = `Tasks for delivery-NNN of work-NNN; feature SPECs: feature-NNN-{name}, ...`

Include in the prompt:
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/detail.md`. Read the existing file first if it exists.
  Output per `.github/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Print before dispatch: `[Review] Dispatching aid-reviewer for task list validation (per-deliverable scope).`

▶ aid-reviewer starting (~1–2 min)
After writing, **review immediately:** Do the tasks hold up?
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}

After aid-reviewer returns, run grade.sh:

```bash
bash .github/scripts/grade.sh --explain .aid/.temp/review-pending/detail.md
```

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from `bash .github/scripts/config/read-setting.sh --skill detail --key minimum_grade --default A`) | Move to next deliverable. |
| Grade < minimum, fixable | Back to Propose with findings. |

```
✅ delivery-001 tasks written and verified — sequence holds, criteria testable.
Moving to delivery-002.
```

### Step 4: Next Deliverable

Move to next deliverable → same loop (steps 1–3). Task numbering is global
across all deliverables (task-001 through task-N).

### Step 5: Build Execution Graph

Load `references/execution-graph-generation.md` for the full procedure.

After ALL deliverables are detailed, build the execution graph for each delivery
and write it to PLAN.md under the corresponding delivery.

### Step 6: Final Summary

```
All tasks written:

delivery-001: {Name} → tasks 001–004
delivery-002: {Name} → tasks 005–008

Total: {n} tasks in {m} deliverables.
Execution graphs written to PLAN.md.
```

[State: FIRST-RUN] complete.

**Advance:** **CHAIN** → [State: REVIEW] (continue inline).
