---
name: change-member
applies-to: refactor
slot-count: 5
task-count: 1
summary: Refactor an existing member of an object or model without changing observable behavior.
---

## spec

# Refactor: {{class-name}}.{{method-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-member` via /aid-interview lite path
**Status:** Active

## Goal

Refactor `{{method-name}}` in `{{class-name}}` to improve clarity, structure,
or performance without changing observable behavior.

## Context

Rationale: {{refactor-rationale}}

Current shape: {{before-shape}}

Target shape: {{after-shape}}

## Acceptance Criteria

- [ ] `{{class-name}}.{{method-name}}` matches the target shape described above.
- [ ] All existing tests for `{{class-name}}` pass without modification.
- [ ] New or updated tests cover any edge cases exposed by the refactor.
- [ ] No behavioral change observable from outside the class.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Refactor {{class-name}}.{{method-name}} and update tests |

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
| (auto-filled) | Created from recipe `change-member` | /aid-interview lite path |

## tasks

### task-001 — Refactor {{class-name}}.{{method-name}} and update tests

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Refactor `{{method-name}}` in `{{class-name}}`. Transform the
  implementation from its current shape ({{before-shape}}) to the target shape
  ({{after-shape}}). Rationale: {{refactor-rationale}}. Update or add unit tests
  so that all edge cases remain covered after the change.
- Acceptance Criteria:
  - [ ] `{{class-name}}.{{method-name}}` matches the target shape described above.
  - [ ] All existing tests for `{{class-name}}` pass without modification.
  - [ ] New or updated tests cover any edge cases exposed by the refactor.
  - [ ] No behavioral change observable from outside the class.
