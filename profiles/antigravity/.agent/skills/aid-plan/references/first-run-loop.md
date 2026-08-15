# State: FIRST-RUN

No PLAN.md found; begin dependency mapping and deliverable sequencing.

## FIRST RUN — The Loop

### Step 0: Emit pipeline phase

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Plan
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-plan
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

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

**First deliverable:** Create `.aid/works/{work}/PLAN.md` with the header and first deliverable:
```markdown
# Plan -- {Work Name}

## Deliverables

### delivery-001: {Name}
- **What it delivers:** {user-facing value}
- **Features:** feature-001-{name}, feature-003-{name}
- **Depends on:** --
- **Priority:** Must
```

**Subsequent deliverables:** Append to the existing PLAN.md.

WARNING: **DO NOT continue to the next deliverable without writing this one first.**
WARNING: **DO NOT accumulate multiple deliverables "in your head" -- write each one immediately.**

The stanza IS the delivery definition. Alongside the `**What it delivers:**` /
`**Features:**` / `**Depends on:**` / `**Priority:**` fields, write into the SAME stanza:

- `**Objective:**` = the "What it delivers" value, expanded to one paragraph
- `**Scope:**` = features assigned to this delivery; `**Out of scope:**` = features
  explicitly deferred
- `**Gate Criteria**` = concrete acceptance criteria, each naming an observable (derive
  from the feature's section in `REQUIREMENTS.md § 11`, citing its `AC-N` ids; always
  include "All section-6 quality gates pass"). Leave placeholders if criteria will be
  refined by aid-specify.
- `**Notes:**` = constraints not captured by the gate criteria; omit when there are none

Do NOT write a task listing or a Blocks field into the stanza. Both are DERIVED: the task
listing from each task's `**Source:** ... -> delivery-NNN` field, and the reverse edges
from the `**Depends on:**` fields across stanzas. Storing either creates a second copy that
can disagree with the first.

A delivery with ZERO tasks (e.g. a SPIKE delivery that defines a sibling delivery) is
valid and still gets a full stanza -- the objective and gate criteria are what make it a
delivery, and neither depends on tasks existing.

**Immediately after writing the PLAN.md stanza,** create the delivery folder:

**4a. Create `deliveries/delivery-NNN/STATE.yml`** (seed from `.agent/aid/templates/delivery-state-template.yml`):

`Delivery:` / `Work:` / `Branch:` are INFERRED from the folder path and git worktree --
never authored here. Fill in the template's own keys:
- `delivery_state: Pending-Spec`     (SD-8: authored independent lifecycle, NOT derived from tasks)
- `delivery_lifecycle` key:
  - `updated:` = current UTC timestamp ($(date -u +%Y-%m-%dT%H:%M:%SZ))
  - `block_reason:` = --
  - `block_artifact:` = --
- `gate_tier` / `gate_grade` / `gate_timestamp` and `delivery_gate.issue_list`: leave at template placeholders
- `qa` key: leave as template placeholder (`[]`)
- Tasks State: nothing to write -- it is DERIVED at read time from `tasks/task-NNN/STATE.yml`
  files, which do not exist yet for a new delivery

> SD-9 NOTE: A delivery created with ZERO tasks renders correctly at `Pending-Spec` with an
> empty DERIVED Tasks State. This is the canonical SPIKE-defines-sibling scenario.
> The delivery lifecycle is authored independently -- it does NOT derive from the task rollup.
> The Plan/Deliveries view in the WORK STATE.yml is DERIVED at read time from these
> deliveries/delivery-NNN/STATE.yml files. `aid-plan` does NOT write any rows into the work STATE.yml.

**4c. Connector awareness — record this delivery's `ticket_ref` (optional).** If this deliverable
corresponds to (or the user names) an external tracker item, fetch it by invoking `/aid-read-ticket
[<connector>:]<ticket-id>` — the connector resolution and host-MCP fetch live there (feature-001);
no direct-fetch recipe is re-implemented here — and record `ticket_ref: <stem>:<external-id>` in
the delivery's `STATE.yml` frontmatter just written above (4a). Skip silently when no such ticket
applies or no matching connector is catalogued; the delegated read is non-destructive, so no extra
confirm is added. If instead the team wants a new tracker item filed for this deliverable, aid-plan
does not file one itself. If a catalogued `issue-tracker` connector exists in `.aid/connectors/` →
print a suggestion: "to file a tracker item for this deliverable, run `/aid-create-ticket`, then
re-record its ref," and continue without one. Optional, user-initiated, never auto-invoked;
silent (no output) if no issue-tracker connector is catalogued.

**Agent:** Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-architect`) **at Large tier** — the executor is the Large `aid-architect`, so reviewer tier >= executor tier (`.agent/aid/templates/agent-dispatch-tiering.md`). The aid-reviewer must run with clean context — it grades against KB/codebase reality without seeing the aid-architect's working notes.

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `per-deliverable`
- `{{ARTIFACTS}}` = the deliverable section just appended to `PLAN.md` + the SPECs of the features it assigns
- `{{CONTEXT}}` = `delivery-NNN of work-NNN just written; preceding deliveries: delivery-NNN..MMM (titles).`

Include in the prompt:
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/plan.md`. Read the existing file first if it exists.
  Output per `.agent/aid/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Print before dispatch: `[Review] Dispatching aid-reviewer for PLAN validation (per-deliverable scope).`

▶ aid-reviewer starting (~1–2 min)
After writing, **review immediately:** Does it hold up?
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}
- All included features' dependencies satisfied by prior deliverables?
- Actually standalone-functional?
- Consistent with KB architecture?

After aid-reviewer returns, run grade.sh:

```bash
bash .agent/aid/scripts/grade.sh --explain .aid/.temp/review-pending/plan.md
```

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from `bash .agent/aid/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`) | Move to next deliverable. |
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

**Before printing the summary, verify PLAN.md and delivery folders are complete:**
1. Read `.aid/works/{work}/PLAN.md` from disk
2. Confirm every agreed deliverable is written
3. If any deliverable is missing → write it NOW
4. If Cross-Cutting Risks or Deferred sections apply → append them NOW
5. For each delivery-NNN in PLAN.md, confirm its stanza carries an objective, scope and gate
   criteria, and that `deliveries/delivery-NNN/STATE.yml` exists under `.aid/works/{work}/`.
   If either is missing -> write it NOW
   (seed from the templates; replace the top-level `delivery_state` placeholder with
   `delivery_state: Pending-Spec` -- the scalar lives at the top of the file per
   `delivery-state-template.yml`, task-001/004; direct field edit, same scaffold-time
   convention as `state-first-run.md § 1b-ii`).

Then print:
```
Plan complete for {work}:

delivery-001: {Name} -- features 001, 003
delivery-002: {Name} -- features 002
delivery-003: {Name} -- features 004, 005

{If deferred:}
Deferred: feature-006 (Could-have, revisit after delivery-003 feedback)

{If cross-cutting risks:}
Cross-cutting risks: {count} identified (see PLAN.md)

PLAN.md written to: .aid/works/{work}/PLAN.md
Delivery folders created:
  .aid/works/{work}/deliveries/delivery-001/STATE.yml (delivery_state: Pending-Spec)
  .aid/works/{work}/deliveries/delivery-002/STATE.yml (delivery_state: Pending-Spec)
  ...
```

**Advance:** **CHAIN** -> [State: REVIEW] when PLAN.md is written, delivery folders are created,
and the final summary is printed (continue inline).
