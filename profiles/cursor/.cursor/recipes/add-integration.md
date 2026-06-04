---
name: add-integration
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a client/adapter for an external service.
---

## spec

# Add integration: {{service-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-integration` via /aid-interview lite path
**Status:** Active

## Goal

Implement a client or adapter for the `{{service-name}}` external service, wire it
into the application, and cover it with integration tests (using a stub or sandbox).

## Context

Service API: {{service-api}}

Integration purpose: {{integration-purpose}}

Auth/credentials approach: {{auth-approach}}

Error handling strategy: {{error-handling}}

## Acceptance Criteria

- [ ] A client/adapter for `{{service-name}}` is implemented and injectable.
- [ ] The integration performs its purpose: {{integration-purpose}}.
- [ ] Auth/credentials are handled securely per: {{auth-approach}}.
- [ ] Errors are handled per the strategy: {{error-handling}}.
- [ ] Integration tests (stub or sandbox) cover the happy path and at least one
  error path (e.g., service unavailable, auth failure).
- [ ] No regression in existing integration tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{service-name}} client/adapter |
| task-002 | TEST | Integration tests for {{service-name}} client |

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
| (auto-filled) | Created from recipe `add-integration` | /aid-interview lite path |

## tasks

### task-001 — Implement {{service-name}} client/adapter

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Implement a client or adapter for `{{service-name}}` targeting the API:
  {{service-api}}. Integration purpose: {{integration-purpose}}. Handle
  auth/credentials per: {{auth-approach}}. Apply the error handling strategy:
  {{error-handling}}. Make the client injectable/mockable for testing.
- Acceptance Criteria:
  - [ ] Client/adapter for `{{service-name}}` is implemented and follows the API contract.
  - [ ] Auth/credentials are handled securely (no hard-coded secrets).
  - [ ] Errors handled per the specified strategy.
  - [ ] Client is injectable or mockable to support unit and integration tests.

### task-002 — Integration tests for {{service-name}} client

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write integration tests for the `{{service-name}}` client using a stub,
  mock server, or sandbox environment. Cover the happy path and at least one error
  path (e.g., service unavailable, auth failure, malformed response).
- Acceptance Criteria:
  - [ ] Happy-path test passes for the primary integration purpose.
  - [ ] At least one error-path test (e.g., unavailable service, auth failure).
  - [ ] No regression in existing integration tests.
