# Plan -- Numbered `aid projects` List with Remove-by-Number

> **Work:** work-018-projects-numbering
> **Created:** 2026-07-16

---

## Deliverables

- **Delivery:** delivery-001 -- Numbered `aid projects` List with Remove-by-Number
- **What it delivers:** Numbers `aid projects list` from 1 and lets `aid projects remove <N>` unregister the Nth listed project, while preserving `aid projects remove <path>` and leaving `aid projects add` untouched. Spans the Bash and PowerShell CLI twins (`bin/aid`, `bin/aid.ps1`) and their `projects` usage/help text + top-of-file synopsis; the npm/pypi packages regenerate their vendored copies from `bin/` at build time (no manual re-sync).
- **Features:** feature-001-projects-numbering   (the single feature; no `features/` folder)
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
