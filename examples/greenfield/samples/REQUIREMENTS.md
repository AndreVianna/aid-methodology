# REQUIREMENTS — tasktracker-api
<!-- Sample output from /aid-interview. Illustrative only. -->

**Work:** work-001-tasktracker-api
**Path:** full
**Produced by:** aid-interview
**Date:** 2026-06-10

---

## 1. Problem Statement

Development teams using shared task boards lack a lightweight, self-hosted option
that integrates cleanly with their CI pipelines. Existing SaaS tools carry either
vendor lock-in or excessive surface area for small teams.

## 2. Users

| User | Role | Primary need |
|------|------|-------------|
| Team member | API consumer | Create and manage personal tasks via HTTP; integrate from CI scripts |
| Team lead | API consumer | View all team tasks by status; export for reporting |

## 3. Functional Requirements

### F1 — Authentication

- FR1.1: Users can register with email + password. Passwords are stored hashed (bcrypt,
  cost factor ≥ 12).
- FR1.2: Users can log in with email + password and receive a JWT access token (expiry: 15 min)
  and refresh token (expiry: 7 days).
- FR1.3: Protected endpoints reject requests with missing, malformed, or expired tokens
  with HTTP 401.
- FR1.4: Token refresh returns a new access token given a valid refresh token.

### F2 — Task CRUD

- FR2.1: Authenticated users can create tasks (title required; description, due_date,
  status optional; default status: `open`).
- FR2.2: Users can update any field on their own tasks.
- FR2.3: Users can delete their own tasks. Deletion is soft-delete (status set to `deleted`).
- FR2.4: Users can retrieve a single task by ID. Requesting another user's task returns 404.
- FR2.5: Valid statuses: `open`, `in-progress`, `done`, `deleted`.

### F3 — List & Filter

- FR3.1: Users can list their non-deleted tasks. Response is paginated (cursor-based, 50 per page).
- FR3.2: List supports filtering by status (one or more values) and due_date range (from/to).
- FR3.3: List supports sorting by due_date (asc/desc) or created_at (asc/desc).
- FR3.4: Response envelope includes items array, next_cursor (null if last page), and total_count.

## 4. Non-Functional Requirements

- NFR1: P99 response latency ≤ 200 ms under 50 concurrent users (single Postgres instance).
- NFR2: All endpoints must return structured JSON error bodies (`{ "error": "...", "code": "..." }`).
- NFR3: Secrets (JWT signing key, DB password) are never logged or returned in responses.

## 5. Out of Scope

- Team-level task visibility (each user sees only their own tasks in this version)
- Email verification
- Rate limiting (deferred to a future delivery)

## 6. Features

| ID | Name | Depends on |
|----|------|------------|
| F1 | Authentication | — |
| F2 | Task CRUD | F1 |
| F3 | List & Filter | F2 |
