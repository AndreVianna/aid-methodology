---
name: add-event-handler
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a handler/consumer for a domain or system event.
---

## spec

# Add event handler: {{event-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-event-handler` via /aid-interview lite path
**Status:** Active

## Goal

Implement a handler/consumer for the `{{event-name}}` event, wiring it into the
event bus or messaging infrastructure and covering it with unit tests.

## Context

Event source: {{event-source}}

Handler behavior: {{handler-behavior}}

Side effects or downstream actions: {{side-effects}}

Idempotency and delivery guarantees: {{idempotency-notes}}

## Acceptance Criteria

- [ ] A handler for `{{event-name}}` is registered with the event bus/messaging layer.
- [ ] The handler performs the specified behavior: {{handler-behavior}}.
- [ ] Idempotency or at-least-once delivery requirements are addressed per:
  {{idempotency-notes}}.
- [ ] Unit tests cover the happy path and at least one error path.
- [ ] No regression in adjacent event-handling tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{event-name}} handler logic |
| task-002 | TEST | Unit tests for {{event-name}} handler |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `add-event-handler` | /aid-interview lite path |

## tasks

### task-001 — Implement {{event-name}} handler logic

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Create a handler/consumer for the `{{event-name}}` event from
  `{{event-source}}`. Implement the handler behavior: {{handler-behavior}}.
  Handle side effects and downstream actions: {{side-effects}}. Address
  idempotency and delivery guarantees: {{idempotency-notes}}.
- Acceptance Criteria:
  - [ ] Handler is registered and receives `{{event-name}}` events.
  - [ ] Handler behavior matches the specification.
  - [ ] Side effects are executed correctly and errors are handled gracefully.
  - [ ] Idempotency requirements are met per the noted guarantees.

### task-002 — Unit tests for {{event-name}} handler

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit tests for the `{{event-name}}` handler covering the happy path
  and at least one error path (e.g., malformed event, downstream failure).
- Acceptance Criteria:
  - [ ] Happy-path test passes for a well-formed `{{event-name}}` event.
  - [ ] At least one error-path test (e.g., malformed payload, idempotency check).
  - [ ] No regression in existing event handler tests.
