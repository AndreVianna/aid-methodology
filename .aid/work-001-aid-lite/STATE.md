# Work State — work-001-aid-lite

> **Status:** Specifying
> **Phase:** Specify
> **Minimum Grade:** A
> **Started:** 2026-05-22
> **User Approved:** yes (Interview)

This is the single state file for `work-001-aid-lite` — speed-focused AID-Lite reform (lite path + two-tier review + thin-router + parallel-by-default). Consolidates what used to be `INTERVIEW-STATE.md` + per-feature `STATE.md` × 4.

## Interview Status

**Status:** Approved · **Grade:** A

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-05-22 |
| 2 | Problem Statement | Complete | 2026-05-22 |
| 3 | Users & Stakeholders | Complete | 2026-05-22 |
| 4 | Scope | Complete | 2026-05-22 |
| 5 | Functional Requirements | Complete | 2026-05-22 |
| 6 | Non-Functional Requirements | Complete | 2026-05-22 |
| 7 | Constraints | Complete | 2026-05-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-05-22 |
| 9 | Acceptance Criteria | Complete | 2026-05-22 |
| 10 | Priority | Complete | 2026-05-22 |

## Features Status

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 002 | `feature-002-skill-footprint-refactor` | Ready | A | 0 open | FR3 thin-router (M1 only, M4 folded in as authoring discipline). Owns CR6 (state-id format: UPPERCASE-with-hyphens) + CR7 (two-zone task-template — superseded by FR2's area-STATE rule). Soft dep from `work-003/feature-001` AC4. |
| 004 | `feature-004-two-tier-review` | Ready | A | 0 open | FR2 review pattern: per-task quick check (major/critical only) + per-delivery A-grade gate. |
| 005 | `feature-005-lite-path` | Ready | A | 0 open | FR1 lite path: triage fork in /aid-interview; consolidated work-root SPEC.md for small work; no feature folders / no PLAN.md when lite. |
| 009 | `feature-009-parallel-task-execution` | Ready | A | 0 open | FR6 parallel-by-default in /aid-execute. Wave-based execution. Soft-coupling target for `work-003/feature-001` AC4 sub-unit drill-down. |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| _none yet_ | — | — | `/aid-plan` not yet run for this work |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | — | — | — | — | — | — | `/aid-detail` not yet run for this work |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | — | — | — | — | — |

## Cross-phase Q&A (Pending)

*(none — all 5 historical IQs resolved during /aid-interview cross-reference cycles; see Resolved Q&A below for audit trail)*

### Resolved Q&A (historical audit trail)

| # | Topic | Resolution |
|---|-------|------------|
| IQ1 | FR3-M3 native skill chaining unsupported by host tools | **Answered** — Redefined as hook-driven/user-confirmed auto-advance; ultimately dropped in fresh-eyes reshape (M3 fights the platform). |
| IQ2 | KB stale across ~14 docs (pre-cleanup artifact model) | **Answered** — KB re-synced in place; 12 docs corrected; DISCOVERY-STATE Q181 resolved. |
| IQ3 | FR5 must subsume/fix Codex installer bug (H6) | **Answered** — Acknowledged; H6 retired by work-002. |
| IQ4 | §2 benchmark evidence trail clarity | **Answered** — §2 rewritten with the 3-group comparison. |
| IQ5 | feature-008 "bonus/stretch" wording | **Answered** — feature-008 confirmed Should; later dropped entirely in the reshape. |

## Lifecycle History

| # | Date | Phase Transition / Gate | Grade | Notes |
|---|------|------------------------|-------|-------|
| 1 | 2026-05-22 | /aid-interview complete — all 10 sections approved | — | Initial interview, 10 sections, user-approved scope |
| 2 | 2026-05-22 | Feature Decomposition — 10 features created | — | feature-001 through feature-010 (per original FR-decomposition) |
| 3 | 2026-05-22 | Cross-Reference (first pass) | C (resolved) | 8 findings (2 MEDIUM, 3 LOW, 2 MINOR, 1 no-defect); all resolved via IQ1–IQ5 + 3 direct fixes. KB re-synced. |
| 4 | 2026-05-22 | Cross-Reference (re-run) | A | Three independent reviewer passes C → B → A; cleared for /aid-specify. |
| 5 | 2026-05-22 | Fresh-eyes reshape (option B) | — | Independent critique flagged scope creep (4 pain points → 10 features + 8 CRs). Reshape: 5 features survive (002 / 004 / 005 / 007 / 009); feature-001 (FR5) moved to **`work-002-canonical-generator`** (sequenced first); features 003 / 006 / 008 / 010 deleted. CR1–CR6 and CR8 retired; CR7 retained (later superseded by FR2). |
| 6 | 2026-05-23 | Split — `work-003-traceability` extracted | A (carried) | FR4 (progress traceability), pain-point #4, and `feature-007` moved to dedicated `work-003-traceability`. work-001 reduced to 4 features (FR1 + FR2 + FR3 + FR6) on grade A. |
| 7 | 2026-05-23 | CW4: state files migrated to area-STATE shape | — | INTERVIEW-STATE.md + 4 feature STATE.md absorbed into this STATE.md per the new FR2 rule from work-003. Spec contents (SPEC.md, REQUIREMENTS.md) unchanged. |
