> **Sample output** — This file illustrates the work-root `REQUIREMENTS.md` a
> shortcut produces on the Lite path. It is not a real project file. The sections
> and structure below match the actual AID template.
>
> The Lite path writes exactly two artifact types: this document and one
> `tasks/task-NNN/DETAIL.md` per task. There is no `SPEC.md` — the feature's
> technical specification is a section of this file — and no `PLAN.md`, because
> one feature and one delivery leaves no sequencing decision to record.

---

# Stale cache on order update

- **Work:** work-001-fix-stale-cache
- **Created:** 2026-06-03
- **Source:** /aid-describe lite path — LITE-BUG-FIX
- **Status:** Draft

## Goal

The order-status endpoint in `orders-api` occasionally returns stale data after
an order is updated. `order_repository.update_order()` writes the new state to
the database but never calls `orders_cache.invalidate(order_id)`, so any
cached entry persists until TTL expiry (30 minutes). During that window reads
return an outdated status — for example `"processing"` when the database holds
`"fulfilled"`.

## Context

**Bug report:** After a surge in order volume, the order-status endpoint
returns stale data. Investigation confirms the in-memory cache is never
invalidated when an order is updated.

**Reproduction steps:**
1. Update an order's status to `"fulfilled"` via the API.
2. Within 30 minutes, read the same order via the order-status endpoint.
3. The response shows `"processing"` instead of `"fulfilled"`.

**Intended behavior:** Immediately after a successful database write,
`orders_cache.invalidate(order_id)` is called. Subsequent reads re-fetch from
the database and re-populate the cache with the updated status.

`OrdersCache.invalidate()` already exists and is tested — this is a call-site
omission in `order_repository.py`, not a missing feature.

## 9. Acceptance Criteria

Each criterion carries a stable `AC-N` id. Tasks cite these ids in their
`**Source:**` line, which is what makes a task's requirements slice derivable.

- **AC-1** Given an order updated to `"fulfilled"`, when the order-status endpoint
  is called within 30 minutes of the update, the response reflects the updated
  status rather than the cached stale value.
- **AC-2** A regression test that would have caught this bug exists: a unit test
  mocks `OrdersCache` and asserts `cache.invalidate` is called with `order_id` as
  the only argument on every `update_order()` execution.
- **AC-3** All applicable quality gates pass (per `.aid/settings.yml`).

## 11. Features

### Feature 001 — Order-status cache invalidation

- **Criteria:** AC-1, AC-2, AC-3

#### Technical Specification

`update_order()` calls `OrdersCache.invalidate(order_id)` after the write commits,
inside the same transaction boundary, so a failed write leaves the cache untouched.

## Tasks and execution graph — DERIVED, not stored

Neither is written into this file. The task set is the `tasks/task-NNN/DETAIL.md`
folders on disk, and the graph is each task's `**Depends on:**` field:

```
bash canonical/aid/scripts/execute/derive-waves.sh --from-tasks .aid/works/{work}
```

For this work that prints `task-001` in wave 1 and `task-002` in wave 2, derived from
task-002's `**Depends on:** task-001`. A stored copy could disagree with the DETAILs it
came from, which is why there is none.
