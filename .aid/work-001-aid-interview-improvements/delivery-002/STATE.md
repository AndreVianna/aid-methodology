# Delivery State -- delivery-002

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

> **Delivery:** delivery-002
> **Work:** work-001-aid-interview-improvements
> **Branch:** aid/work-001-delivery-002

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. Written by aid-plan, aid-specify,
     aid-execute across the delivery pipeline. Never derived from task rollup (SD-9). -->

- **State:** Done
- **Updated:** 2026-06-27T16:30:00Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Written via `writeback-state.sh --delivery-id NNN --block ...`.
     Distinct from per-task quick-check findings -- the gate aggregates those deferred [HIGH]
     rows (via delivery-NNN-issues.md) and runs a full grade.sh pass.
     Instances of the deferred-[HIGH] log live at `.aid/work-NNN/delivery-NNN-issues.md`;
     see `.claude/aid/templates/delivery-issues.md` for the template. -->

- **Reviewer Tier:** Large
- **Grade:** A+
- **Issue List:** none (TOTAL 0 across all 6 tasks). H1/M3/M4/M1 closure met (M4 T4 Playwright-render-proven); R1 (task-009) aid-researcher web tools scoped + propagated (DBI 559, idempotent regen); tasks 004-008 held on re-gate.
- **Timestamp:** 2026-06-27T16:30:00Z

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     Per SD-5: delivery-gate SPEC Q&A is written here, NOT into the shared work-level STATE.md,
     to preserve the disjoint-write property (two delivery branches cannot collide on this file).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. KB Q&A targets .aid/knowledge/STATE.md (separate file). -->

**Q1 -- M1 publish-enablement: defer or close now?**

- **Category:** Release/Infra
- **Impact:** Low
- **State:** Answered
- **Decision (2026-06-27):** Deferred with rationale.
- **Rationale:** `.github/workflows/release.yml` is already OIDC-ready -- no code change is
  needed. The `npm-publish` job is gated `if: vars.NPM_ENABLED == 'true'` (L217) and
  `pypi-publish` is gated `if: vars.PYPI_ENABLED == 'true'` (L284). Closure requires external
  account setup (npm `@aid` scope, PyPI org/Trusted-Publisher, and repo variable flip) that
  only the owner can perform; an agent cannot execute those steps. Per AC-9, this explicit
  deferral-with-rationale satisfies the criterion for this feature item.
- **Owner steps to close:**
  1. **npm:** Create and own the `@aid` npm scope; set repo variable `NPM_ENABLED=true`.
  2. **PyPI:** Create the CasuloAI Labs PyPI org, reserve `aid-installer`, configure a Trusted
     Publisher pointing at `AndreVianna/aid-methodology` + `release.yml`; set `PYPI_ENABLED=true`.
  3. Verify by cutting a release tag and confirming both publish jobs run (not skipped) and
     succeed; confirm via `npm view aid-installer@<v> version` and pip install.

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
