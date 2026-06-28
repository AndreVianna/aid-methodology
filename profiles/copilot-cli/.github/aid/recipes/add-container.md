---
name: add-container
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a new storage container/bucket/collection.
---

## spec

# Add container: {{container-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-container` via /aid-describe lite path
**Status:** Active

## Goal

Provision a new storage container (bucket, collection, or equivalent)
named `{{container-name}}` with the defined access policy and configuration.

## Context

Container purpose: {{container-purpose}}

Access policy and permissions: {{access-policy}}

Configuration and retention settings: {{container-config}}

## Acceptance Criteria

- [ ] `{{container-name}}` container is provisioned with the defined configuration.
- [ ] Access policy is applied and enforced.
- [ ] Application code that references the container is wired to `{{container-name}}`.
- [ ] Basic connectivity / read-write is verified.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Provision {{container-name}} and wire access |

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
| (auto-filled) | Created from recipe `add-container` | /aid-describe lite path |

## tasks

### task-001 — Provision {{container-name}} and wire access

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Provision the storage container `{{container-name}}` for purpose
  ({{container-purpose}}) with configuration ({{container-config}}) and access
  policy ({{access-policy}}). Wire the application code to reference the new
  container and verify basic read-write connectivity.
- Acceptance Criteria:
  - [ ] Container is provisioned with the specified configuration and retention settings.
  - [ ] Access policy is applied and enforced.
  - [ ] Application references point to `{{container-name}}`.
  - [ ] Basic read-write connectivity is verified.
