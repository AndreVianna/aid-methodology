---
name: change-event-handler
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing event handler's behavior.
---

## spec

# Change event handler: {{event-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-event-handler` via /aid-interview lite path
**Status:** Active

## Goal

Modify the existing `{{event-name}}` handler to change its behavior as described,
without altering the event contract or breaking downstream consumers.

## Context

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Rationale: {{rationale}}

Affected consumers or downstream systems: {{affected-consumers}}

## Acceptance Criteria

- [ ] The `{{event-name}}` handler exhibits the intended behavior: {{intended-behavior}}.
- [ ] The event contract (schema, topic, routing) is unchanged.
- [ ] Affected consumers (`{{affected-consumers}}`) are not broken by the change.
- [ ] Existing unit tests are updated or extended to cover the new behavior.
- [ ] No regression in adjacent event-handling tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Update {{event-name}} handler behavior |

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
| (auto-filled) | Created from recipe `change-event-handler` | /aid-interview lite path |

## tasks

### task-001 — Update {{event-name}} handler behavior

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Modify the `{{event-name}}` handler. Current behavior: {{current-behavior}}.
  Apply the change to achieve: {{intended-behavior}}. Rationale: {{rationale}}.
  Verify that affected consumers (`{{affected-consumers}}`) continue to function.
  Update existing tests to cover the new behavior.
- Acceptance Criteria:
  - [ ] Handler now exhibits the intended behavior.
  - [ ] Event contract (schema, topic, routing key) is unchanged.
  - [ ] Affected consumers are unbroken by the change.
  - [ ] Unit tests updated or added to cover the changed behavior.
  - [ ] No regression in existing event handler tests.
