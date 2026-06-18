---
name: change-ui-endpoint
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing UI page/route's behavior or layout.
---

## spec

# Change UI endpoint: {{route-path}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-ui-endpoint` via /aid-interview lite path
**Status:** Active

## Goal

Change the behavior or layout of the UI page at `{{route-path}}` from its current
state to the intended state without breaking existing navigation or user flows.

## Context

Rationale: {{change-rationale}}

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Affected components: {{affected-components}}

## Acceptance Criteria

- [ ] The page at `{{route-path}}` behaves as described in the intended behavior above.
- [ ] Affected components in `{{affected-components}}` are updated correctly.
- [ ] Updated UI tests verify the new behavior.
- [ ] No regression in existing UI tests or navigation flows.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{route-path}} page behavior and affected components |

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
| (auto-filled) | Created from recipe `change-ui-endpoint` | /aid-interview lite path |

## tasks

### task-001 — Update {{route-path}} page behavior and affected components

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the UI page at `{{route-path}}` from its current behavior
  ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{change-rationale}}. Update affected components:
  {{affected-components}}. Update tests to reflect the new behavior.
- Acceptance Criteria:
  - [ ] The page at `{{route-path}}` behaves as described in the intended behavior above.
  - [ ] Affected components in `{{affected-components}}` are updated correctly.
  - [ ] Updated UI tests verify the new behavior.
  - [ ] No regression in existing UI tests or navigation flows.
