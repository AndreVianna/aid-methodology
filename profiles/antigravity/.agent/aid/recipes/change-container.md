---
name: change-container
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing storage container's config/structure.
---

## spec

# Change container: {{container-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-container` via /aid-describe lite path
**Status:** Active

## Goal

Change the configuration or structure of the existing storage container
`{{container-name}}` from its current state to the intended state.

## Context

Current configuration: {{current-shape}}

Intended configuration: {{target-shape}}

Rationale: {{rationale}}

Access policy changes: {{access-policy}}

## Acceptance Criteria

- [ ] Container `{{container-name}}` reflects the intended configuration after the change.
- [ ] Access policy is updated and enforced.
- [ ] No data loss during the configuration change.
- [ ] Application code referencing the container is updated if needed.
- [ ] Basic read-write connectivity is re-verified.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{container-name}} configuration and access policy |

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
| (auto-filled) | Created from recipe `change-container` | /aid-describe lite path |

## tasks

### task-001 — Update {{container-name}} configuration and access policy

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the storage container `{{container-name}}` from its current
  configuration ({{current-shape}}) to the intended configuration ({{target-shape}}).
  Rationale: {{rationale}}. Apply access policy changes ({{access-policy}}).
  Update any application code that references container-specific settings, and
  re-verify basic read-write connectivity.
- Acceptance Criteria:
  - [ ] Container reflects the intended configuration.
  - [ ] Access policy changes are applied and enforced.
  - [ ] No data loss during the change.
  - [ ] Application code is updated where needed.
  - [ ] Basic read-write connectivity is verified.
