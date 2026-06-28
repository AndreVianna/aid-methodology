---
name: add-message
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a new message/event schema and emit it.
---

## spec

# Add message: {{message-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-message` via /aid-describe lite path
**Status:** Active

## Goal

Define a new message or event schema named `{{message-name}}`, implement the emit
logic at the specified source, and cover it with a unit test.

## Context

Message schema: {{message-schema}}

Emit location: {{emit-location}}

Consumer notes (expected consumers or routing): {{consumer-notes}}

## Acceptance Criteria

- [ ] The `{{message-name}}` schema is defined and documented.
- [ ] The emit logic at `{{emit-location}}` publishes well-formed `{{message-name}}`
  messages.
- [ ] Consumer routing or subscription notes are documented: {{consumer-notes}}.
- [ ] A unit test verifies the emitted message matches the schema.
- [ ] No regression in adjacent messaging tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Define {{message-name}} schema and implement emit logic |

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
| (auto-filled) | Created from recipe `add-message` | /aid-describe lite path |

## tasks

### task-001 — Define {{message-name}} schema and implement emit logic

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define the `{{message-name}}` message/event schema: {{message-schema}}.
  Implement the emit logic at `{{emit-location}}` to publish well-formed
  `{{message-name}}` messages. Document consumer routing per: {{consumer-notes}}.
  Add a unit test verifying the emitted payload matches the schema.
- Acceptance Criteria:
  - [ ] `{{message-name}}` schema is defined (struct, class, or JSON schema).
  - [ ] Emit logic at `{{emit-location}}` produces correctly shaped messages.
  - [ ] Consumer routing or subscription notes are documented.
  - [ ] Unit test asserts the emitted message matches the defined schema.
  - [ ] No regression in existing messaging or event tests.
