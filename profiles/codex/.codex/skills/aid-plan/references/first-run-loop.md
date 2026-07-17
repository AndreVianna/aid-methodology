# State: FIRST-RUN

No PLAN.md found; begin dependency mapping and deliverable sequencing.

## FIRST RUN — The Loop

### Step 0: Emit pipeline phase

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Plan
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-plan
bash .codex/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
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

**Immediately after writing the PLAN.md stanza,** create the delivery folder:

**4a. Create `deliveries/delivery-NNN/BLUEPRINT.md`** (seed from `.codex/aid/templates/delivery-blueprint-template.md`):

Fill in from the approved PLAN.md stanza:
- `Delivery:` = delivery-NNN
- `Work:` = work-NNN-{name}
- `Created:` = today's date (YYYY-MM-DD)
- `## Objective` = the delivery's "What it delivers" value, expanded to one paragraph
- `## Scope` = features assigned to this delivery; Out of scope = features explicitly deferred
- `## Gate Criteria` = concrete acceptance criteria (derive from feature SPECs; always include
  "All section-6 quality gates pass"); leave placeholders if criteria will be refined by aid-specify
- `## Tasks` = empty table (`_none yet_`) -- aid-detail will fill this later
- `## Dependencies` = Depends on / Blocks from the PLAN.md stanza

A delivery with ZERO tasks (e.g. a SPIKE delivery that defines a sibling delivery) is valid.
Write the BLUEPRINT with the zero-task table (`_none yet_`) -- do not skip BLUEPRINT creation.

**4b. Create `deliveries/delivery-NNN/STATE.md`** (seed from `.codex/aid/templates/delivery-state-template.md`):

Fill in:
- `Delivery:` = delivery-NNN
- `Work:` = work-NNN-{name}
- `Branch:` = aid/work-NNN-delivery-NNN
- `## Delivery Lifecycle` block:
  - `State: Pending-Spec`     (SD-8: authored independent lifecycle, NOT derived from tasks)
  - `Updated:` = current UTC timestamp ($(date -u +%Y-%m-%dT%H:%M:%SZ))
  - `Block Reason:` = --
  - `Block Artifact:` = --
- `## Delivery Gate` section: leave all fields as template placeholders
- `## Cross-phase Q&A` section: leave as template placeholder
- `## Tasks State` table: `_none yet_` (correct and expected for a new delivery)

> SD-9 NOTE: A delivery created with ZERO tasks renders correctly at `Pending-Spec` with
> `_none yet_` in the Tasks State table. This is the canonical SPIKE-defines-sibling scenario.
> The delivery lifecycle is authored independently -- it does NOT derive from the task rollup.
> The `## Plan / Deliveries` view in the WORK STATE.md is DERIVED at read time from these
> deliveries/delivery-NNN/STATE.md files. `aid-plan` does NOT write any rows into the work STATE.md.

**4c. Connector awareness — record this delivery's `ticket_ref` (optional).** If this deliverable
corresponds to (or the user names) an external tracker item, or the team wants one filed for it,
create/register it via a catalogued issue-tracker connector per
`.codex/aid/templates/connectors/consumption-protocol.md` (scan `.aid/connectors/INDEX.md`; for
a `connection_type: mcp` match, request the connection from the host tool's own MCP — AID resolves
nothing and stores no credential) and record `ticket_ref: <stem>:<external-id>` in the delivery's
`STATE.md` frontmatter just written above (4b). Skip silently when no such ticket applies or no
matching connector is catalogued.

**Agent:** Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-architect`) **at Large tier** — the executor is the Large `aid-architect`, so reviewer tier >= executor tier (`.codex/aid/templates/agent-dispatch-tiering.md`). The aid-reviewer must run with clean context — it grades against KB/codebase reality without seeing the aid-architect's working notes.

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `per-deliverable`
- `{{ARTIFACTS}}` = the deliverable section just appended to `PLAN.md` + the SPECs of the features it assigns
- `{{CONTEXT}}` = `delivery-NNN of work-NNN just written; preceding deliveries: delivery-NNN..MMM (titles).`

Include in the prompt:
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/plan.md`. Read the existing file first if it exists.
  Output per `.codex/aid/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Print before dispatch: `[Review] Dispatching aid-reviewer for PLAN validation (per-deliverable scope).`

▶ aid-reviewer starting (~1–2 min)
After writing, **review immediately:** Does it hold up?
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}
- All included features' dependencies satisfied by prior deliverables?
- Actually standalone-functional?
- Consistent with KB architecture?

After aid-reviewer returns, run grade.sh:

```bash
bash .codex/aid/scripts/grade.sh --explain .aid/.temp/review-pending/plan.md
```

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum (from `bash .codex/aid/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`) | Move to next deliverable. |
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
5. For each delivery-NNN in PLAN.md, confirm both `deliveries/delivery-NNN/BLUEPRINT.md` and
   `deliveries/delivery-NNN/STATE.md` exist under `.aid/works/{work}/`. If either is missing -> create it NOW
   (seed from the templates; replace the frontmatter's `delivery_state` placeholder with
   `delivery_state: Pending-Spec` -- the scalar lives in the leading YAML block per
   `delivery-state-template.md`, task-001/004; direct field edit, same scaffold-time
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
  .aid/works/{work}/deliveries/delivery-001/{BLUEPRINT.md, STATE.md} (State: Pending-Spec)
  .aid/works/{work}/deliveries/delivery-002/{BLUEPRINT.md, STATE.md} (State: Pending-Spec)
  ...
```

**Advance:** **CHAIN** -> [State: REVIEW] when PLAN.md is written, delivery folders are created,
and the final summary is printed (continue inline).
