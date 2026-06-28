---
name: change-ui-component
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing UI component's props or behavior.
---

## spec

# Change UI component: {{component-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-ui-component` via /aid-describe lite path
**Status:** Active

## Goal

Change `{{component-name}}` from its current props/behavior to the intended state
without breaking existing consumers.

## Context

Rationale: {{change-rationale}}

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Affected consumers: {{affected-consumers}}

## Acceptance Criteria

- [ ] `{{component-name}}` behaves as described in the intended behavior above.
- [ ] Consumers listed in `{{affected-consumers}}` are updated and pass tests.
- [ ] Updated unit tests verify the new component behavior.
- [ ] No regression in existing UI tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{component-name}} and affected consumers |

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
| (auto-filled) | Created from recipe `change-ui-component` | /aid-describe lite path |

## tasks

### task-001 — Update {{component-name}} and affected consumers

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update `{{component-name}}` from its current behavior
  ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{change-rationale}}. Update all consumers listed in
  {{affected-consumers}} to use the revised component API. Update tests to
  reflect the new behavior.
- Acceptance Criteria:
  - [ ] `{{component-name}}` behaves as described in the intended behavior above.
  - [ ] Consumers listed in `{{affected-consumers}}` are updated and pass tests.
  - [ ] Updated unit tests verify the new component behavior.
  - [ ] No regression in existing UI tests.
