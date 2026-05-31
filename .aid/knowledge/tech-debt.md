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
  - 2026-05-31: Inventory current — 0 open items. Per the documentation rule (kb-authoring P9), resolved tech-debt records are removed from this doc entirely once closed; git history is the audit trail.
---

# Tech Debt

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-31

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Low**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 18-suite canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29); the inventory is **empty** — zero open Critical, High, Medium, or Low items. Resolved items are removed from this doc entirely once closed — git history is the only retained record.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 0 | — |
| Low | 0 | — |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from this doc entirely once closed; git history is the only retained record. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

*(No open items.)*

---

## Metrics

- **TODO/FIXME count:** net **0 unresolved code TODOs** — all occurrences in `canonical/` are template-explanatory mentions ("fill in TODO sections"), not unresolved code TODOs.
- **Files > 500 lines:** ~9 (the methodology spec, several test suites + helper scripts, and detailed state-reference docs — all appropriately sized for their type)
- **Files > 1,000 lines:** 1 (`methodology/aid-methodology.md`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **18** canonical suites under `tests/canonical/` (including the 3 F4 doc-set suites from delivery-002), plus the shared `tests/lib/assert.sh` lib and the `tests/run-all.sh` glob-discovering aggregator. The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here; recount with `ls tests/canonical/test-*.sh | wc -l`).
- **Open PRs:** none representing tracked debt.
