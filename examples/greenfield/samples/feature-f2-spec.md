# SPEC — F2: Task CRUD
<!-- Sample output from /aid-specify for feature F2. Illustrative only. -->

**Work:** work-001-tasktracker-api
**Feature:** F2 — Task CRUD
**Produced by:** aid-specify
**Date:** 2026-06-10
**Status:** Confirmed

---

## 1. Summary

Implement the four core CRUD operations for tasks. Tasks are owned by the creating
user; ownership is enforced at the service layer (not just the query layer).

## 2. Data Model

**Table: `tasks`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, default gen_random_uuid() |
| `user_id` | UUID | FK → users.id NOT NULL |
| `title` | VARCHAR(255) | NOT NULL |
| `description` | TEXT | nullable |
| `status` | VARCHAR(20) | NOT NULL, default 'open', CHECK IN ('open','in-progress','done','deleted') |
| `due_date` | DATE | nullable |
| `created_at` | TIMESTAMPTZ | NOT NULL, default now() |
| `updated_at` | TIMESTAMPTZ | NOT NULL, default now() |

Index: `(user_id, status)` — covers the list + filter query in F3.

## 3. API Endpoints

### POST /tasks

Creates a new task for the authenticated user.

**Request body:**
```json
{
  "title": "Write unit tests",
  "description": "Cover the auth middleware",
  "due_date": "2026-06-20",
  "status": "open"
}
```

**Response 201:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "...",
  "title": "Write unit tests",
  "description": "Cover the auth middleware",
  "status": "open",
  "due_date": "2026-06-20",
  "created_at": "2026-06-10T09:00:00Z",
  "updated_at": "2026-06-10T09:00:00Z"
}
```

**Error responses:**
- 400 `VALIDATION_ERROR` — title missing or blank; status not a valid enum value
- 401 `UNAUTHORIZED` — no valid JWT

### GET /tasks/:id

Returns a single task. Returns 404 (not 403) if the task belongs to another user —
this avoids leaking existence information.

**Response 200:** Same shape as POST 201 response.

**Error responses:**
- 401 `UNAUTHORIZED`
- 404 `NOT_FOUND` — task does not exist or belongs to another user

### PATCH /tasks/:id

Partial update. Only provided fields are updated. `user_id` and `id` are not
patchable — return 400 if either is provided.

**Request body (all fields optional):**
```json
{
  "title": "Write unit tests for auth middleware",
  "status": "in-progress"
}
```

**Response 200:** Updated task object.

### DELETE /tasks/:id

Soft-delete: sets `status = 'deleted'` and updates `updated_at`. Does not remove
the row. Returns 204 No Content.

**Error responses:**
- 401 `UNAUTHORIZED`
- 404 `NOT_FOUND` — as above

## 4. Service Layer Rules

- Ownership check: `WHERE id = :id AND user_id = :userId` — never `WHERE id = :id` alone.
- Soft-delete means `status = 'deleted'` rows are excluded from all list queries
  (F3) but can still be retrieved by ID (GET /tasks/:id). This allows clients to
  handle 404 vs. deleted differently if needed.
- `updated_at` must be set to `now()` on every PATCH and DELETE.

## 5. Acceptance Criteria

- [ ] All four endpoints return the correct HTTP status codes for success and all error cases.
- [ ] A user cannot read, update, or delete another user's task (returns 404, not 403).
- [ ] Soft-delete sets status to `deleted`; row is NOT removed from the DB.
- [ ] PATCH with `user_id` or `id` field returns 400.
- [ ] Integration tests cover: create, read own, read other's (404), update, soft-delete,
      read after soft-delete (still 200 with status=deleted).

## 6. Dependencies

- F1 (Authentication) must be complete: the JWT middleware must be in place before
  these endpoints can enforce ownership.
- DB migration from task-001 (users table) must be applied before the tasks migration.
