---
name: change-queue
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing queue's config or routing.
---

## spec

# Change queue: {{queue-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-queue` via /aid-interview lite path
**Status:** Active

## Goal

Modify the configuration or routing of the existing `{{queue-name}}` queue/topic
without disrupting active producers or consumers.

## Context

Current configuration: {{current-config}}

Target configuration: {{target-config}}

Rationale: {{rationale}}

Affected consumers or producers: {{affected-consumers}}

## Acceptance Criteria

- [ ] `{{queue-name}}` queue/topic reflects the target configuration: {{target-config}}.
- [ ] All active producers and consumers (`{{affected-consumers}}`) continue to
  function without interruption.
- [ ] Infrastructure-as-code or configuration files are updated.
- [ ] No regression in existing messaging tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Apply {{queue-name}} configuration change |

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
| (auto-filled) | Created from recipe `change-queue` | /aid-interview lite path |

## tasks

### task-001 — Apply {{queue-name}} configuration change

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the `{{queue-name}}` queue/topic from current configuration
  ({{current-config}}) to target configuration ({{target-config}}).
  Rationale: {{rationale}}. Verify that affected consumers and producers
  ({{affected-consumers}}) are unaffected. Update infrastructure-as-code, routing
  rules, and any dependent configuration.
- Acceptance Criteria:
  - [ ] Queue/topic configuration matches the target.
  - [ ] No message loss or routing disruption during the change.
  - [ ] Affected consumers and producers continue to function correctly.
  - [ ] Infrastructure-as-code updated and applied cleanly.
  - [ ] Existing messaging tests pass without modification.
