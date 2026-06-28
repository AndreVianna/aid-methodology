---
name: change-api-middleware
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change existing API middleware behavior or ordering.
---

## spec

# Change API middleware: {{middleware-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-api-middleware` via /aid-describe lite path
**Status:** Active

## Goal

Change `{{middleware-name}}` from its current behavior or ordering to the intended
state without breaking the request pipeline.

## Context

Rationale: {{change-rationale}}

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Affected routes: {{affected-routes}}

## Acceptance Criteria

- [ ] `{{middleware-name}}` behaves as described in the intended behavior above.
- [ ] Affected routes in `{{affected-routes}}` continue to function correctly.
- [ ] Updated tests verify the new middleware behavior.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{middleware-name}} behavior and verify pipeline |

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
| (auto-filled) | Created from recipe `change-api-middleware` | /aid-describe lite path |

## tasks

### task-001 — Update {{middleware-name}} behavior and verify pipeline

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update `{{middleware-name}}` from its current behavior
  ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{change-rationale}}. Verify the pipeline is intact for all routes
  in {{affected-routes}}. Update tests to reflect the new behavior.
- Acceptance Criteria:
  - [ ] `{{middleware-name}}` behaves as described in the intended behavior above.
  - [ ] Affected routes in `{{affected-routes}}` continue to function correctly.
  - [ ] Updated tests verify the new middleware behavior.
  - [ ] No regression in existing endpoint tests.
