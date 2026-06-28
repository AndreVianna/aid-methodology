---
name: change-integration
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing external-service integration.
---

## spec

# Change integration: {{service-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-integration` via /aid-describe lite path
**Status:** Active

## Goal

Modify the existing `{{service-name}}` integration to reflect changed API contracts,
updated credentials, or revised behavior, without breaking production traffic.

## Context

Current integration behavior: {{current-behavior}}

Intended integration behavior: {{intended-behavior}}

API changes or credential updates: {{api-changes}}

Rationale: {{rationale}}

## Acceptance Criteria

- [ ] The `{{service-name}}` integration reflects the intended behavior:
  {{intended-behavior}}.
- [ ] API contract and credentials are updated per: {{api-changes}}.
- [ ] Existing integration tests are updated or extended.
- [ ] No regression in other integrations or downstream consumers.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Update {{service-name}} integration |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `change-integration` | /aid-describe lite path |

## tasks

### task-001 — Update {{service-name}} integration

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Modify the `{{service-name}}` integration. Current behavior:
  {{current-behavior}}. Apply changes to achieve: {{intended-behavior}}.
  Apply API changes and credential updates: {{api-changes}}. Rationale:
  {{rationale}}. Update API client calls, auth handling, and deserialization
  logic. Update existing integration tests to cover the new behavior.
- Acceptance Criteria:
  - [ ] Integration updated to reflect the intended behavior.
  - [ ] API contract and auth/credentials updated as specified.
  - [ ] Integration tests updated and pass for both new and existing scenarios.
  - [ ] No regression in other integrations or downstream consumers.
