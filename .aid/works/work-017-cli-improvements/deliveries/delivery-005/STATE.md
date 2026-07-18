---
delivery_state: Specified
gate_tier: Small | Medium | Large
gate_grade: "{grade or Pending}"
gate_timestamp: "{YYYY-MM-DDTHH:MM:SSZ}"
ticket_ref: "--"
---

# Delivery State -- delivery-005

[!NOTE]
This is the DELIVERY-LEVEL STATE.md template -- FULL PATH ONLY. It lives at
`.aid/works/work-NNN-{name}/deliveries/delivery-NNN/STATE.md`. (A lite work has exactly one
delivery and no `deliveries/` folder at all -- its Delivery Lifecycle / Delivery Gate /
Cross-phase Q&A are AUTHORED directly in the work-root `STATE.md` instead; see
`work-state-template.md`.) It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref` (the YAML block above).
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block (Updated/Block Reason/
      Block Artifact/Issue List), Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)

The delivery's lifecycle state is INDEPENDENTLY AUTHORED across the pipeline:
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated (gate running) -> Done
                 or to Blocked on an impediment

Enum members:
  Pending-Spec   -- delivery folder created; awaiting aid-specify
  Specified      -- aid-specify complete; tasks defined
  Executing      -- aid-execute in progress (at least one task dispatched)
  Gated          -- delivery gate running
  Done           -- gate passed; delivery complete
  Blocked        -- impediment raised; awaiting resolution

NOTE: This authored state is NOT a derivation of child task states. A delivery may be
Pending-Spec with ZERO tasks (e.g. a SPIKE delivery that defines a sibling delivery which
then waits for aid-specify). A pure task-rollup cannot express a task-less in-flight delivery,
so the delivery lifecycle MUST be independently authored.
-->

> **Delivery:** delivery-005
> **Work:** work-017-cli-improvements
> **Branch:** aid/work-017-delivery-005

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. Written by aid-plan, aid-specify,
     aid-execute across the delivery pipeline. Never derived from task rollup.
     The **State** scalar lives in the YAML frontmatter block at the top of this file
     (`delivery_state`). Updated/Block Reason/Block Artifact stay here as markdown body. -->

- **Updated:** 2026-07-18T02:41:14Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Written via `writeback-state.sh --delivery-id NNN --block ...`.
     Distinct from per-task quick-check findings -- the gate aggregates those deferred [HIGH]
     rows (via delivery-NNN-issues.md) and runs a full grade.sh pass.
     Instances of the deferred-[HIGH] log live at `.aid/works/work-NNN/delivery-NNN-issues.md`;
     see `.claude/aid/templates/delivery-issues.md` for the template.
     Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block at the top of this
     file (`gate_tier`, `gate_grade`, `gate_timestamp`). Issue List stays here as markdown
     body (a variable-length inline list doesn't fit a flat frontmatter scalar). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     delivery-gate SPEC Q&A is written here, NOT into the shared work-level STATE.md,
     to preserve the disjoint-write property (two delivery branches cannot collide on this file).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. KB Q&A targets .aid/knowledge/STATE.md (separate file). -->

### Q{N}

- **Category:** {category, e.g., Architecture, Requirements, Security}
- **Impact:** High | Medium | Low | Required
- **State:** Pending | Answered | Skipped
- **Context:** {why this matters; what the downstream phase observed; cite phase/skill, e.g., "Surfaced by /aid-specify feature-001"}
- **Suggested:** {answer if inferrable, or --}
- **Answer:** {filled when State is Answered}
- **Applied to:** {artifact(s) the answer was applied to}

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder).
     It is NEVER written directly into this file.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     Never written here. The dashboard reader derives this view when rendering the delivery.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     Most-advanced State wins per the ordering when the same task appears on multiple worktrees. -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
