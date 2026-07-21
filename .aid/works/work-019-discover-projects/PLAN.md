# Plan -- Machine Scan to Discover and Register AID Projects

[!NOTE]
This is the FLATTENED single-delivery `PLAN.md`: one feature, one delivery (no `features/`
folder, no `deliveries/`/`delivery-NNN/` wrapper). It carries the single `## Deliverables`
entry plus a top-level `## Execution Graph`. The delivery's objective, scope, GATE CRITERIA,
and task listing live in the sibling `BLUEPRINT.md`. Zero `### delivery-NNN` subsection
headings by design.

> **Work:** work-019-discover-projects
> **Created:** 2026-07-21

---

## Deliverables

- **Delivery:** delivery-001 -- Machine Scan to Discover and Register AID Projects
- **What it delivers:** A new `aid` CLI subcommand (working name `aid projects scan`) that
  crawls a chosen scope — the user's home directory by default, a specific folder with
  `--path`, or the whole machine with `--all` — registers every `.aid/` project it finds
  (register-only, idempotent, guardrailed), and reports each project's version — implemented in
  both CLI twins with parity and guardrail test coverage and updated help text.
- **Features:** feature-001-discover-projects   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001, task-002 |
| task-004 | task-003 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
| 4 | task-004 |
