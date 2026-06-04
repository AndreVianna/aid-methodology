# PLAN — tasktracker-api
<!-- Sample output from /aid-plan. Illustrative only. -->

**Work:** work-001-tasktracker-api
**Produced by:** aid-plan
**Date:** 2026-06-10
**Status:** Confirmed

---

## Delivery Sequence

### Delivery 1 — Authentication (D1)

**Features:** F1
**Rationale:** All other features depend on the JWT middleware that D1 produces.
Nothing else can be built without a working auth layer.

**Gate criteria (all must pass before D1 merges):**
- POST /auth/register returns 201 for valid input; 400 for duplicate email or invalid format
- POST /auth/login returns a valid JWT for correct credentials; 401 for wrong password
- JWT middleware rejects expired tokens and tokens with invalid signatures
- Unit tests for bcrypt hashing pass; JWT round-trip test passes
- No plaintext passwords or signing keys appear in logs

**Estimated tasks:** 6

---

### Delivery 2 — Task CRUD (D2)

**Features:** F2
**Rationale:** Core task operations must be in place before filtering (F3) can be
built or tested.

**Gate criteria:**
- All four endpoints (POST, GET, PATCH, DELETE /tasks) return correct status codes
- Ownership enforcement: request for another user's task returns 404
- Soft-delete: row status is `deleted`, row is not removed from DB
- DB migration applies cleanly on a fresh schema
- Integration tests for create, read-own, read-other, update, soft-delete all pass

**Estimated tasks:** 7

---

### Delivery 3 — List & Filter (D3)

**Features:** F3
**Rationale:** Builds on D2's task table and indexes. Can be developed in parallel
with D2 once the schema (task-001 of D2) is merged.

**Gate criteria:**
- GET /tasks returns paginated list of caller's non-deleted tasks
- Status filter (single value and array) works correctly
- due_date range filter (from/to) works; null due_date tasks excluded when from/to given
- Sorting by due_date and created_at, both asc and desc
- Cursor-based pagination: next_cursor is null on last page; cursor advances correctly
- Edge cases: empty result (total_count: 0, next_cursor: null), invalid filter param (400)

**Estimated tasks:** 5

---

## Dependency Graph

```
D1 (Authentication)
  └─► D2 (Task CRUD)
        └─► D3 (List & Filter)
```

D2 can begin as soon as D1's JWT middleware task (task-004) is approved — the remaining
D1 tasks (tests) can complete in parallel with early D2 implementation tasks.

## Total Estimated Tasks: 18
