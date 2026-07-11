> **Sample output** — This file illustrates the task file that `aid-describe`
> produces during TASK-BREAKDOWN (via the `architect` agent). It is not a real
> project file. The six sections and structure match the actual AID task template.

---

# task-001: Add cache invalidation call to `update_order()` + unit test

**Type:** IMPLEMENT

**Source:** work-001-fix-stale-cache → delivery-001

**Depends on:** (none)

## Scope

In `orders_api/order_repository.py`, function `update_order(order_id, data)`:

1. After the successful `db.execute()` call (line ~47), add:
   ```python
   self.cache.invalidate(order_id)
   ```
2. `self.cache` is already injected via `__init__` — no constructor changes needed.

In `tests/unit/test_order_repository.py`:

3. Add a test `test_update_order_invalidates_cache` that:
   - Creates `OrderRepository` with a `MagicMock()` for `cache`.
   - Calls `update_order("order-123", {"status": "fulfilled"})`.
   - Asserts `mock_cache.invalidate.assert_called_once_with("order-123")`.

## Acceptance Criteria

- [ ] `update_order()` calls `self.cache.invalidate(order_id)` immediately after
      a successful database write.
- [ ] The call uses `order_id` as the only argument (no extra kwargs).
- [ ] Unit test `test_update_order_invalidates_cache` passes.
- [ ] All existing unit tests in `tests/unit/test_order_repository.py` remain green.
- [ ] No changes to the `OrdersCache` public interface.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
