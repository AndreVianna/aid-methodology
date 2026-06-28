---
name: change-message
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing message/event schema (versioned, back-compatible).
---

## spec

# Change message: {{message-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-message` via /aid-describe lite path
**Status:** Active

## Goal

Update the `{{message-name}}` message/event schema in a versioned, back-compatible
manner so existing consumers continue to function without modification.

## Context

Current schema: {{current-schema}}

Target schema: {{target-schema}}

Rationale: {{rationale}}

Compatibility notes (consumers that must be preserved): {{compatibility-notes}}

## Acceptance Criteria

- [ ] `{{message-name}}` schema is updated to the target shape: {{target-schema}}.
- [ ] Change is back-compatible: existing consumers handle both old and new shapes
  per: {{compatibility-notes}}.
- [ ] Schema version is incremented or migration notes are documented.
- [ ] Unit tests cover the updated schema and confirm backward compatibility.
- [ ] No regression in adjacent messaging tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Update {{message-name}} schema with back-compatibility |

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
| (auto-filled) | Created from recipe `change-message` | /aid-describe lite path |

## tasks

### task-001 — Update {{message-name}} schema with back-compatibility

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the `{{message-name}}` schema from current shape ({{current-schema}})
  to target shape ({{target-schema}}). Rationale: {{rationale}}. Apply
  versioning or additive-only changes to preserve back-compatibility per
  {{compatibility-notes}}. Update emit logic and any deserialization code. Add
  or update unit tests to verify both old and new schema shapes are handled.
- Acceptance Criteria:
  - [ ] Schema updated to target shape.
  - [ ] Existing consumers can handle messages in both old and new schema shapes.
  - [ ] Schema version incremented or backward-compatibility documented.
  - [ ] Unit tests pass for both old and new schema shapes.
  - [ ] No regression in existing messaging tests.
