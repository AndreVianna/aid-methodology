---
name: add-api-middleware
applies-to: new-feature
slot-count: 4
task-count: 2
summary: Add API middleware (auth, logging, rate-limit) to the request pipeline.
---

## spec

# Add API middleware: {{middleware-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-api-middleware` via /aid-describe lite path
**Status:** Active

## Goal

Add `{{middleware-name}}` to the API request pipeline to provide the described
cross-cutting behavior.

## Context

Middleware purpose: {{middleware-purpose}}

Pipeline placement: {{pipeline-placement}}

Affected routes: {{affected-routes}}

## Acceptance Criteria

- [ ] `{{middleware-name}}` is registered in the API pipeline at the position
  described in the pipeline placement notes.
- [ ] All routes listed in `{{affected-routes}}` are covered by the middleware.
- [ ] Unit and integration tests verify the middleware behavior and error paths.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{middleware-name}} middleware |
| task-002 | TEST | Tests for {{middleware-name}} middleware |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `add-api-middleware` | /aid-describe lite path |

## tasks

### task-001 — Implement {{middleware-name}} middleware

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Implement `{{middleware-name}}` middleware with the purpose:
  {{middleware-purpose}}. Register it in the API pipeline at the position
  described by {{pipeline-placement}}. Apply it to the routes in
  {{affected-routes}}.
- Acceptance Criteria:
  - [ ] `{{middleware-name}}` is implemented and registered at the correct pipeline position.
  - [ ] All routes listed in `{{affected-routes}}` are covered by the middleware.
  - [ ] Error paths are handled and return appropriate responses.

### task-002 — Tests for {{middleware-name}} middleware

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit and integration tests for `{{middleware-name}}` covering
  the happy path and error paths (e.g., rejection, bypass, propagation).
- Acceptance Criteria:
  - [ ] Unit tests cover the core logic of `{{middleware-name}}`.
  - [ ] Integration tests verify the middleware fires on routes in `{{affected-routes}}`.
  - [ ] No regression in existing endpoint tests.
