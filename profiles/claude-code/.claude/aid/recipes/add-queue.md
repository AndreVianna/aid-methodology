---
name: add-queue
applies-to: new-feature
slot-count: 4
task-count: 2
summary: Add a message queue/topic and its producer wiring.
---

## spec

# Add queue: {{queue-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-queue` via /aid-describe lite path
**Status:** Active

## Goal

Provision a new message queue or topic named `{{queue-name}}`, wire a producer to
publish to it, and verify the setup with integration tests.

## Context

Queue purpose: {{queue-purpose}}

Producer location: {{producer-location}}

Delivery semantics (at-least-once, exactly-once, FIFO): {{delivery-semantics}}

## Acceptance Criteria

- [ ] The `{{queue-name}}` queue/topic is provisioned and reachable.
- [ ] The producer at `{{producer-location}}` publishes messages to `{{queue-name}}`.
- [ ] Delivery semantics are configured per: {{delivery-semantics}}.
- [ ] Infrastructure configuration (DLQ, retry policy) is in place.
- [ ] Integration test confirms end-to-end message delivery.
- [ ] No regression in existing messaging tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Provision {{queue-name}} queue and wire producer |
| task-002 | TEST | Integration test for {{queue-name}} end-to-end delivery |

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
| (auto-filled) | Created from recipe `add-queue` | /aid-describe lite path |

## tasks

### task-001 — Provision {{queue-name}} queue and wire producer

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Create the `{{queue-name}}` queue/topic in the messaging infrastructure.
  Purpose: {{queue-purpose}}. Configure delivery semantics: {{delivery-semantics}}.
  Wire the producer at `{{producer-location}}` to publish messages. Add
  dead-letter queue, retry policy, and any required access permissions.
- Acceptance Criteria:
  - [ ] `{{queue-name}}` queue/topic is created and accessible.
  - [ ] Producer successfully publishes to `{{queue-name}}`.
  - [ ] Delivery semantics applied as specified.
  - [ ] Dead-letter queue and retry policy are configured.

### task-002 — Integration test for {{queue-name}} end-to-end delivery

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write an integration test that publishes a message to `{{queue-name}}` and
  confirms delivery (consumed or persisted), plus at least one error-path scenario.
- Acceptance Criteria:
  - [ ] Happy-path test confirms message is published and received.
  - [ ] At least one error-path test (e.g., malformed message, unavailable queue).
  - [ ] No regression in existing messaging tests.
