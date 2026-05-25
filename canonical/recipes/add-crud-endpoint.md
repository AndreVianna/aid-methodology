---
name: add-crud-endpoint
applies-to: small-new-feature
slot-count: 6
task-count: 3
---

## spec

# Add CRUD endpoint: {{resource-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-crud-endpoint` via /aid-interview lite path
**Status:** Active

## Goal

Implement a full CRUD REST endpoint for the `{{resource-name}}` resource at
`{{endpoint-path}}`, backed by the persistence layer, and covered by integration
tests.

## Context

Request schema: {{request-schema}}

Response schema: {{response-schema}}

Persistence layer notes: {{persistence-layer-notes}}

Security notes: {{security-notes}}

## Acceptance Criteria

- [ ] GET / POST / PUT / DELETE endpoints exist under `{{endpoint-path}}`.
- [ ] Request and response schemas match the definitions above.
- [ ] All four operations are covered by integration tests (happy path + at least
  one error path per operation).
- [ ] Persistence layer correctly stores and retrieves `{{resource-name}}` records.
- [ ] Security controls specified in the security notes are enforced.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Define schema and migration for {{resource-name}} |
| task-002 | IMPLEMENT | Implement handler and persistence for {{resource-name}} |
| task-003 | TEST | Integration tests for {{resource-name}} endpoints |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `add-crud-endpoint` | /aid-interview lite path |

## tasks

### task-001 — Define schema and migration for {{resource-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define the data model for `{{resource-name}}` using the persistence layer
  ({{persistence-layer-notes}}). Create any required schema migrations. Request
  schema: {{request-schema}}. Response schema: {{response-schema}}.
- Acceptance Criteria:
  - [ ] Data model for `{{resource-name}}` is defined and matches the request/response
    schemas.
  - [ ] Migration runs cleanly on a fresh database and on an existing one.
  - [ ] Model is unit-tested (validation rules, constraints).

### task-002 — Implement handler and persistence for {{resource-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Implement GET / POST / PUT / DELETE handlers at `{{endpoint-path}}`.
  Wire handlers to the persistence layer. Enforce security controls:
  {{security-notes}}.
- Acceptance Criteria:
  - [ ] All four HTTP methods respond correctly with the defined schemas.
  - [ ] Security controls from the security notes are enforced on all operations.
  - [ ] Error responses follow the existing API error shape.

### task-003 — Integration tests for {{resource-name}} endpoints

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-002
- Scope: Write integration tests for all four CRUD operations at `{{endpoint-path}}`,
  covering happy-path and at least one error-path scenario per operation.
- Acceptance Criteria:
  - [ ] Happy-path tests pass for GET, POST, PUT, and DELETE.
  - [ ] At least one error-path test per operation (e.g., not-found, invalid input,
    unauthorized).
  - [ ] No regression in existing endpoint tests.
