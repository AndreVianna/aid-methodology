# Plan -- Bulk CLI Update Across Registered Projects

> **Work:** work-001-update-all
> **Created:** 2026-07-20

---

## Deliverables

- **Delivery:** delivery-001 -- Bulk CLI Update Across Registered Projects
- **What it delivers:** A bulk update capability on `aid update`: a single invocation that walks every registered AID project and brings each to the target version, downloading the tool package(s) exactly once into a shared cache and applying that cache to each project through the existing `--from-bundle` path. Failures are isolated (reported, not fatal) and an end-of-run summary reports updated / skipped / failed counts. Delivered in both the bash (`bin/aid`) and PowerShell (`bin/aid.ps1`) twins with behavior parity. Existing single-project `aid update`, `aid update self`, and `--dry-run` behavior are unchanged.
- **Features:** feature-001-update-all   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

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
