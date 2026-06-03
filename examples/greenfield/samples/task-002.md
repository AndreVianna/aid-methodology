# task-002 — POST /auth/register endpoint
<!-- Sample output from /aid-detail. Illustrative only. -->

**Work:** work-001-tasktracker-api
**Delivery:** D1 — Authentication
**Type:** IMPLEMENT
**Produced by:** aid-detail
**Date:** 2026-06-10
**Status:** Pending

---

## 1. What This Task Does

Implement the `POST /auth/register` endpoint. The endpoint accepts email + password,
validates input, hashes the password with bcrypt, inserts a new row into `users`,
and returns the created user record (without the password hash).

## 2. Inputs

- `task-001.md` approved: the `users` table migration has been applied. The `users`
  table is available with columns: `id`, `email`, `password_hash`, `created_at`.
- `src/db/pool.js` exists (created by task-001's migration setup).

## 3. Files to Create or Modify

| Action | File | What to do |
|--------|------|-----------|
| CREATE | `src/auth/register.js` | Route handler: validate → hash → insert → respond |
| CREATE | `src/auth/validate.js` | Input validation helpers (email format, password min length) |
| MODIFY | `src/app.js` | Register the route: `app.post('/auth/register', registerHandler)` |

## 4. Implementation Details

**Validation rules (return 400 `VALIDATION_ERROR` if violated):**
- `email`: required, valid email format (RFC 5322 simplified: local@domain.tld)
- `password`: required, minimum 8 characters

**Duplicate email (return 400 `EMAIL_TAKEN`):**
- Postgres unique constraint on `users.email` — catch error code `23505` and map
  to `{ "error": "Email already registered", "code": "EMAIL_TAKEN" }`.
- Do NOT check for existence first and then insert — race condition. Catch the
  constraint violation.

**Password hashing:**
- Use `bcrypt.hash(password, 12)` — cost factor 12, never lower.
- Never log the plaintext password or the hash.

**Success response (201):**
```json
{
  "id": "550e8400-...",
  "email": "user@example.com",
  "created_at": "2026-06-10T09:00:00Z"
}
```
Do not include `password_hash` in the response.

## 5. Acceptance Criteria

- [ ] POST /auth/register with valid input returns 201 and the user object (no password_hash field).
- [ ] POST /auth/register with missing email returns 400 `VALIDATION_ERROR`.
- [ ] POST /auth/register with invalid email format returns 400 `VALIDATION_ERROR`.
- [ ] POST /auth/register with password < 8 chars returns 400 `VALIDATION_ERROR`.
- [ ] POST /auth/register with a duplicate email returns 400 `EMAIL_TAKEN`.
- [ ] `password_hash` field does NOT appear in the response body or in any log line.
- [ ] bcrypt cost factor is 12 (verifiable in unit test by checking hash prefix `$2b$12$`).

## 6. Dependencies

- task-001 (DB migration: users table) must be approved before this task begins.

## 7. Reviewer Notes

(Populated after review.)
