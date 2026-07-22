# Plan -- Scan Directory Exclusions And User-Configurable Prune Set

> **Work:** work-022-scan-exclusions
> **Created:** 2026-07-22

---

## Deliverables

- **Delivery:** delivery-001 -- Expanded scan prune sets + user-configurable exclusions
- **What it delivers:** `aid projects scan` no longer registers false-positive projects
  from tool-cache/build/IDE/OS directories, and users can extend the prune set via a
  machine-level `scan-config.yml`.
- **Features:** feature-001-scan-exclusions   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002, task-003 |
