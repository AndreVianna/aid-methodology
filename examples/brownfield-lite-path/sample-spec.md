> **Sample output** — This file illustrates the work-root SPEC.md that
> `aid-describe` produces at the end of CONDENSED-INTAKE. It is not a real
> project file. The sections and structure below match the actual AID template.

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

## Acceptance Criteria

- [ ] Given an order updated to `"fulfilled"`, when the order-status endpoint
      is called within 30 minutes of the update, then the response reflects the
      updated status (not the cached stale value).
- [ ] Regression test added that would have caught this bug: unit test mocks
      `OrdersCache` and asserts `cache.invalidate` is called with `order_id`
      as the only argument on every `update_order()` execution.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Add cache invalidation call to `update_order()` + unit test |
| task-002 | TEST | Integration test — update → read cycle confirms fresh data |

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

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Initial lite-path SPEC created | /aid-describe LITE-BUG-FIX |
