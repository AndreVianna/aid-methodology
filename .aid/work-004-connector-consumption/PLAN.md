# Plan -- work-004-connector-consumption

<!-- FLATTENED single-delivery PLAN.md. One `## Deliverables` entry + a top-level
     `## Execution Graph`. ZERO `### delivery-NNN` subsection headings by design — both
     compute-block-radius.sh and complexity-score.sh key off that heading's absence to stay on
     their no-`--delivery-id` path. The single delivery is carried only by each task's
     `**Source:** ... -> delivery-001` field in its tasks/task-NNN/DETAIL.md. The delivery's
     objective/scope/GATE CRITERIA/task listing live in the sibling BLUEPRINT.md. -->

> **Work:** work-004-connector-consumption
> **Created:** 2026-07-11

---

## Deliverables

- **Delivery:** delivery-001 -- Connector Lifecycle + MCP-First Consumption
- **What it delivers:** two on-demand skills to manage the connector catalog incrementally — `aid-set-connector` (upsert) and `aid-unset-connector` (remove) — so a connector can be added/updated/removed without re-running `aid-discover`; plus pipeline wiring so AID skills/agents consume host-provided MCP connectors at defined lifecycle seams (multi-level `ticket_ref` linkage). Orchestration over existing connector plumbing — no new scripts.
- **Features:** feature-001-connector-consumption   (the single feature; no `features/` folder)
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
| task-004 | — (none) |
| task-005 | — (none) |
| task-006 | task-002, task-003, task-004 |
| task-007 | task-005, task-006 |

### Can Be Done In Parallel

<!-- task-001 (reconcile extraction), task-004 (consumption protocol + seams + ticket_ref schema)
     and task-005 (profile context files) share no dependency and open wave 1. The two lifecycle
     skills (002 set, 003 unset) both reuse reconcile.md, so they wait on task-001. task-006
     (register + /generate-profile) renders every canonical edit (001/002/003/004), so it waits on
     the three canonical-authoring tasks that feed it. task-007 (tests) validates the rendered
     skills (via 006) and the hand-maintained context files (005). -->

| Wave | Tasks |
|------|-------|
| 1 | task-001, task-004, task-005 |
| 2 | task-002, task-003 |
| 3 | task-006 |
| 4 | task-007 |
