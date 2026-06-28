---
name: add-member
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a field/property/method to an existing object or model.
---

## spec

# Add member: {{member-name}} to {{class-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-member` via /aid-describe lite path
**Status:** Active

## Goal

Add `{{member-name}}` to `{{class-name}}` to support the described use case.

## Context

Member kind and description: {{member-description}}

Placement notes: {{placement-notes}}

## Acceptance Criteria

- [ ] `{{class-name}}` has the new member `{{member-name}}` as described.
- [ ] Existing tests for `{{class-name}}` continue to pass.
- [ ] New or updated tests cover `{{member-name}}` behavior.
- [ ] No behavioral change to existing members of `{{class-name}}`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Add {{member-name}} to {{class-name}} and update tests |

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
| (auto-filled) | Created from recipe `add-member` | /aid-describe lite path |

## tasks

### task-001 — Add {{member-name}} to {{class-name}} and update tests

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Add `{{member-name}}` to `{{class-name}}`. Member kind and description:
  {{member-description}}. Placement notes: {{placement-notes}}. Update or add
  unit tests so the new member is covered.
- Acceptance Criteria:
  - [ ] `{{class-name}}` has the new member `{{member-name}}` as described.
  - [ ] Existing tests for `{{class-name}}` continue to pass.
  - [ ] New or updated tests cover `{{member-name}}` behavior.
  - [ ] No behavioral change to existing members of `{{class-name}}`.
