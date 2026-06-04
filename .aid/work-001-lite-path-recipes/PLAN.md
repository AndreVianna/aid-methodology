# Plan — lite-path-recipes

> Delivery roadmap for work-001-lite-path-recipes. Written by /aid-plan (FIRST-RUN).
> One atomic delivery: the lite-path taxonomy redesign is a definition→consumer→instances
> triad whose enum rename is a clean break, so the three features ship together to avoid an
> inconsistent intermediate lite path.

## Deliverables

### delivery-001: Lite-Path Taxonomy Redesign + Recipe Catalog
- **What it delivers:** A redesigned lite path — the internal work-type taxonomy collapsed
  4→3 (`bug-fix`, `new-feature`, `refactor`; `single-doc` eliminated), a description-first
  TRIAGE that infers type + recipe from a free-form work description (user confirms in one
  turn), and a ~51-recipe catalog (5 migrated with no loss + ~46 new) — all consistent and
  re-rendered byte-identical to the 5 install trees.
- **Features:** feature-001-taxonomy-and-recipe-schema, feature-002-description-first-triage,
  feature-003-recipe-catalog
- **Depends on:** — (foundation)
- **Priority:** Must
- **Internal implementation order (for /aid-detail + /aid-execute):** feature-001 first (the
  enum/`summary:` schema definition), then feature-002 (TRIAGE consumer — needs `summary:` +
  new enum) and feature-003 (recipe instances — need new enum, carry `summary:`) which can
  proceed in parallel after feature-001. The work-level AC1 "zero old enum tokens across all
  canonical files" sweep and the `/aid-generate` byte-identical render run **once at the end**,
  after all three features' edits land.

### Execution Graph

> Written by /aid-detail. 11 tasks across 5 waves. Critical path:
> task-001 → {a recipe authoring/migration task} → task-010 → task-011.

**Task Dependencies**

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001, task-002 |
| task-005 | task-001 |
| task-006 | task-001 |
| task-007 | task-001 |
| task-008 | task-001 |
| task-009 | task-001 |
| task-010 | task-005, task-006, task-007, task-008, task-009 |
| task-011 | task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010 |

**Waves**

| Wave | Tasks |
|------|-------|
| W1 | task-001 |
| W2 | task-002, task-003, task-005, task-006, task-007, task-008, task-009 |
| W3 | task-004 |
| W4 | task-010 |
| W5 | task-011 |

task-004 is held to W3 (not W2) because it serializes after task-002 — both edit `domain-glossary.md` and `schemas.md` at different lines.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Shared-file edits** — feature-001 and feature-003 both edit `tests/canonical/test-parse-recipe.sh` (enum fixtures lines 145/205 vs Units 15–19 recipe-filename refs); feature-001 and feature-003 both edit `canonical/recipes/README.md` (schema/field tables vs Seed Catalog table). | M | One atomic delivery (chosen) removes any cross-branch merge risk — all edits land together. Within the delivery, the per-feature SPECs document the exact non-overlapping line ranges. |
| 2 | **Clean-break enum rename** leaves an inconsistent lite path until ALL three features land (TRIAGE emits old values / recipes carry old `applies-to`). | M | Atomic delivery: nothing ships until the triad is complete. AC1 sweep + smoke test + byte-identical render are the delivery's exit gate, run after all edits. |
| 3 | **Scale of feature-003** — 47 new recipe files authored in one delivery (46 new names; `write-release-note` splits into 2 files). | M | feature-003 SPEC provides a fully-worked exemplar + a complete 51-row manifest + a `parse-recipe.sh --validate` loop, so /aid-detail can fan the authoring into uniform, independently-verifiable tasks. |
| 4 | **In-flight lite works on the old enum** would break (no alias/shim — REQUIREMENTS §7). | L | Per REQUIREMENTS §8, no in-flight lite work currently uses the old enum; any that appears is reset and re-triaged. |

*(No Deferred section — all Ready features are in delivery-001; the merge-by-similarity consolidation is already scoped out as a separate follow-up work.)*
