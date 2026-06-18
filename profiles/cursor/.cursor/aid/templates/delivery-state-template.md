# Delivery State -- delivery-NNN

[!NOTE]
This is the DELIVERY-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single writer = this delivery's branch) --
      Delivery Lifecycle, Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).

<!-- DELIVERY LIFECYCLE ENUM (SD-8 -- authored, not derived -- SD-9)

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

SD-9 NOTE: This authored state is NOT a derivation of child task states. A delivery may be
Pending-Spec with ZERO tasks (e.g. a SPIKE delivery that defines a sibling delivery which
then waits for aid-specify). A pure task-rollup cannot express a task-less in-flight delivery,
so the delivery lifecycle MUST be independently authored.
-->

> **Delivery:** delivery-NNN
> **Work:** work-NNN-{name}
> **Branch:** aid/work-NNN-delivery-NNN

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. Written by aid-plan, aid-specify,
     aid-execute across the delivery pipeline. Never derived from task rollup (SD-9). -->

- **State:** Pending-Spec | Specified | Executing | Gated | Done | Blocked
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Block Reason:** {short text} | --     (present only when State = Blocked)
- **Block Artifact:** {relative path} | --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Written via `writeback-state.sh --delivery-id NNN --block ...`.
     Distinct from per-task quick-check findings -- the gate aggregates those deferred [HIGH]
     rows (via delivery-NNN-issues.md) and runs a full grade.sh pass.
     Instances of the deferred-[HIGH] log live at `.aid/work-NNN/delivery-NNN-issues.md`;
     see `.cursor/aid/templates/delivery-issues.md` for the template. -->

- **Reviewer Tier:** Small | Medium | Large
- **Grade:** {grade or Pending}
- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     Per SD-5: delivery-gate SPEC Q&A is written here, NOT into the shared work-level STATE.md,
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
     Most-advanced State wins per SD-2 ordering when the same task appears on multiple worktrees. -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
