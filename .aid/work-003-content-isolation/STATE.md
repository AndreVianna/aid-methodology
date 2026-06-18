# Work State — work-003-content-isolation

> **Status:** Ready for Execute
> **Phase:** Execute
> **Minimum Grade:** A+ (per user directive for this work)
> **Started:** 2026-06-18
> **User Approved:** pending (plan A+-gated; awaiting go to execute)

Single state file for work-003 (AID/user content isolation). Lite path (LITE-REFACTOR): SPEC.md + tasks/ produced in one pass, A+-gated before execution.

## Pipeline Status

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Execute
- **Active Skill:** none
- **Updated:** 2026-06-18T10:30:00Z
- **Pause Reason:** Lite-path plan A+-gated; awaiting user go to start /aid-execute
- **Block Reason:** —
- **Block Artifact:** —

## Triage

- **Path:** lite
- **Work Type:** refactor
- **Sub-path:** LITE-REFACTOR
- **Sub-path (auto):** LITE-REFACTOR
- **Decision rationale:** Cross-cutting refactor of how AID-delivered content is laid out + updated; clear requirements, no full-interview needed.
- **Override:** no
- **Recipe:** none

## Interview Status

**Status:** Approved · **Grade:** A+ (lite-review, 3 cycles)

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective (cornerstone: AID/user content isolation) | Complete | 2026-06-18 |
| 2 | Scope (4 pillars) | Complete | 2026-06-18 |
| 3 | Acceptance Criteria | Complete | 2026-06-18 |

## Phase Gates (A+ required)

| Phase | Artifact | Grade | Status |
|-------|----------|-------|--------|
| Lite-review (SPEC + tasks) | SPEC.md + tasks/ | A+ | Clean (3 cycles: 7 findings → F8 → clean) |

## Features Status

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| _none yet_ | | | | | lite path — single work-root SPEC.md |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| delivery-001 | Pending | task-001..011 | single delivery (lite path) |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 1 | Nest AID-own dirs: generator chokepoint + dst builders + toml keys | IMPLEMENT | 1 | Pending | — | — | Pillar 1 |
| 2 | Rename committed skills/README.md -> aid-README.md (all profiles) | REFACTOR | 1 | Pending | — | — | Pillar 2 (R2) |
| 3 | Regenerate profiles/ + manifests; verify generated-files.txt; hand-migrate dogfood .claude/ tree (§7a) | CONFIGURE | 2 | Pending | — | — | depends 001,002; owns F8 |
| 4 | Net-new install/update prune (bash) | IMPLEMENT | 3 | Pending | — | — | depends 003 |
| 5 | Net-new install/update prune (PowerShell) — parity | IMPLEMENT | 4 | Pending | — | — | depends 004 |
| 6 | Add AID:BEGIN/END markers to root-agent profiles; nest ledger-schema ref; remove stray .aid-new | REFACTOR | 1 | Pending | — | — | Pillar 3 + F2 |
| 7 | Root-agent in-place region update + migration, no .aid-new (bash) | IMPLEMENT | 2 | Pending | — | — | depends 006 |
| 8 | Root-agent in-place region update + migration (PowerShell) — parity | IMPLEMENT | 3 | Pending | — | — | depends 007 |
| 9 | Record cornerstone in project KB + update stale layout docs + regen INDEX | DOCUMENT | 1 | Pending | — | — | Pillar 4 + F4 |
| 10 | Wire cornerstone into reviewer standing criteria (canonical aid-reviewer) | DOCUMENT | 2 | Pending | — | — | depends 009 |
| 11 | Cross-cutting regressions + path-ref triage + run-all + render-drift + Windows/workflow smokes | TEST | 5 | Pending | — | — | depends 003,004,005,007,008,010 |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | | | | | |

## Lifecycle History

| Date | Event |
|------|-------|
| 2026-06-18 | TRIAGE → lite path (LITE-REFACTOR) |
| 2026-06-18 | CONDENSED-INTAKE / TASK-BREAKDOWN — ANALYSIS.md + SPEC.md + 11 tasks (researcher + architect) |
| 2026-06-18 | LITE-REVIEW — A+ gate, 3 cycles (7 findings fixed → F8 fixed → clean); ready for execute |

## Cross-phase Q&A (Pending)

_none_
