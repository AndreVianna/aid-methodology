# Plan -- KB Index Routing-Table Restructure

> **Work:** work-010-refactor
> **Created:** 2026-08-12

---

## Deliverables

<!-- ONE entry -- the work's single, implicit delivery (synthesized delivery-001). The full
     delivery definition (objective/scope/GATE CRITERIA/tasks) lives in the sibling BLUEPRINT.md. -->

- **Delivery:** delivery-001 -- KB Index Routing-Table Restructure
- **What it delivers:** A KB routing table an agent can actually scan -- the index generator emits
  its columns as `Document | Audience | Tags | See-instead | Objective | Summary` (short
  discriminating fields first, the two long free-text fields last) and folds the provenance-based
  `Extension` section's rows into the single alphabetical `Primary` table, dropping that heading.
  Only the generator's rendering changes: no row is added or dropped, no cell is recomposed, no
  frontmatter field changes meaning, and `kb-category: extension` stays valid everywhere else.
- **Features:** feature-001-kb-index-routing-table-restructure   (the single feature; no `features/` folder)
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

<!-- Top-level heading; no `### delivery-NNN` wrapper (flattened single-delivery layout). -->

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
