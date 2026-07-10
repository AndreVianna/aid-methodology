# Plan -- work-003-state-schema

<!-- FLATTENED single-delivery PLAN.md. One `## Deliverables` entry + a top-level
     `## Execution Graph`. ZERO `### delivery-NNN` subsection headings by design — both
     compute-block-radius.sh and complexity-score.sh key off that heading's absence to stay on
     their no-`--delivery-id` path. The single delivery is carried only by each task's
     `**Source:** ... -> delivery-001` field in its tasks/task-NNN/DETAIL.md. The delivery's
     objective/scope/GATE CRITERIA/task listing live in the sibling BLUEPRINT.md. -->

> **Work:** work-003-state-schema
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- Structured STATE Frontmatter
- **What it delivers:** the dashboard reads an approved KB as approved (not "Building"), and STATE machine-values are parsed deterministically from YAML frontmatter instead of scraped from free-form markdown — killing the misparse bug class without losing the human-readable ledger
- **Features:** feature-001-state-schema   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-003 |
| task-005 | task-004 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
| 4 | task-004 |
| 5 | task-005 |
