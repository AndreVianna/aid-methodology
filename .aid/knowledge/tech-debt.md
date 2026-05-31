---
kb-category: primary
source: hand-authored
intent: |
  Known technical debt items in the AID methodology repo: items that work but
  carry future-cost or fragility risk. Each entry has severity (CRITICAL / HIGH /
  MEDIUM / LOW), evidence (file:line), impact, and a resolution roadmap.
  Read when planning the next refactor cycle or scoping a new work-NNN.
contracts: []
changelog:
  - 2026-05-31: Inventory current — 1 open item (L6). Per the documentation rule, resolved tech-debt records are removed from this doc entirely once closed; git history is the audit trail.
---

# Tech Debt

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-31

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Low**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 18-suite canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29); the inventory holds **one Low item** (L6, an FR-P0-4 follow-up). There are **zero open Critical, High, or Medium** items. Resolved items are removed from this doc entirely once closed — git history is the only retained record.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 0 | — |
| Low | 1 | L6 |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from this doc entirely once closed; git history is the only retained record. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

| ID | Severity | Title | Evidence | Effort | Priority |
|----|----------|-------|----------|--------|----------|
| L6 | LOW | FR-P0-4 residual fixed-doc-count literals outside the de-hardcode scope | `reviewer-prompt.md:64` ("16 primary documents"), `reviewer-brief.md:26` ("outside canonical 16"), discover `README.md:168` ("these 16 documents"), root `README.md:115` ("fixed shape — 14 standard documents") | S | P3 |

## Detailed Debt Items

### [LOW] L6 — FR-P0-4 residual fixed-doc-count literals

**Type:** Methodology / consistency
**Evidence:**
- `canonical/skills/aid-discover/references/reviewer-prompt.md:64` — "16 primary documents"
- `canonical/skills/aid-discover/references/reviewer-brief.md:26` — "outside canonical 16"
- `canonical/skills/aid-discover/README.md:168` — "subset of these 16 documents"
- root `README.md:115` — "fixed shape — 14 standard documents" (user-facing pitch)

**Impact:** work-001 delivery-002 removed the fixed doc-count assumption from the five
GENERATE/REVIEW de-hardcode targets enumerated in feature-004 SPEC §2.3, but a few reviewer/
README sites outside that scope still phrase the doc-set as a fixed "14"/"16" set. The shipped
behavior is correct (the doc-set is now declared/variable); these are stale *descriptions* that
contradict the new mechanism. Low impact (prose only, no behavior), but worth tidying so the
narrative is consistent with FR-P0-4's intent.

**Fix recipe (estimated S effort):**
1. Reword the three canonical reviewer/discover references to count-agnostic phrasing ("the
   declared doc-set" / "the default seed set").
2. Soften the root `README.md` pitch from "fixed shape — 14 standard documents" to describe the
   declared/derived doc-set (default seed for software-dev projects).
3. Re-render; confirm render-drift clean.

**Owner suggestion:** maintainer; a quick follow-up to work-001 (surfaced by its delivery-002 gate review).

---

## Metrics

- **TODO/FIXME count:** net **0 unresolved code TODOs** — all occurrences in `canonical/` are template-explanatory mentions ("fill in TODO sections"), not unresolved code TODOs.
- **Files > 500 lines:** ~9 (the methodology spec, several test suites + helper scripts, and detailed state-reference docs — all appropriately sized for their type)
- **Files > 1,000 lines:** 1 (`methodology/aid-methodology.md`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **18** canonical suites under `tests/canonical/` (including the 3 F4 doc-set suites from delivery-002), plus the shared `tests/lib/assert.sh` lib and the `tests/run-all.sh` glob-discovering aggregator. The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here; recount with `ls tests/canonical/test-*.sh | wc -l`).
- **Open PRs:** none representing tracked debt.
