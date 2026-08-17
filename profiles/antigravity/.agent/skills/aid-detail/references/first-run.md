# FIRST-RUN — Propose, Discuss, Write

No task files exist yet. Begin proposing task breakdown per deliverable.

Load `references/task-decomposition.md` for task type rules, file format, and quality criteria.

---

## FIRST RUN — The Loop

### Step 0: Emit pipeline phase

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Detail
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-detail
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

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

### Step 3: Write

Once approved:
1. For each task in this delivery, create the nested task folder and seed both files:
   - `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` -- the 6-section task
     definition, seeded from `.agent/aid/templates/task-detail-template.md` (the former flat
     `tasks/task-NNN.md`; same schema, now lives in the task folder).
   - `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/STATE.yml` -- seeded from
     `.agent/aid/templates/task-state-template.yml`, replacing the placeholder
     top-level scalars with the real opening values (`state: Pending`,
     `review: --`, `elapsed: --`, `notes: --` -- task-001/004; direct field edit;
     every key in this file is top-level, no separate frontmatter/body split), and the
     correct Task/Delivery/Work header fields (INFERRED from the folder path, not authored).
   Do NOT write task rows into the work `STATE.yml`'s Tasks State view -- that is a
   DERIVED read-only view assembled at read time from the per-task STATE.yml files.
2. **Self-check before moving on** (the author reading its own output -- no dispatch,
   no grade): does each task have what it needs from the previous one? Any gap where
   something is used before it is created? Scope aligned with what the SPECs say?
   Criteria concrete enough to verify?

```
delivery-001 tasks written. Moving to delivery-002.
```

> **No graded gate here.** FIRST-RUN chains into `[State: REVIEW]`
> (`references/review.md`), which already dispatches `aid-reviewer` at
> `{{SCOPE}} = whole-list` over every delivery's `DETAIL.md` plus the full PLAN.md,
> writing the same `.aid/.temp/review-pending/detail.md` ledger. A per-delivery gate
> here graded the same artifacts a second time, once per delivery, and could not see
> what matters most anyway: a task in delivery-001 contradicting one in
> delivery-003, or the execution graph, which does not exist until Step 5.

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
