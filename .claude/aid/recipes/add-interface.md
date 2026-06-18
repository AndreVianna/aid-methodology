---
name: add-interface
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a new interface/contract/abstract type.
---

## spec

# Add interface: {{interface-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-interface` via /aid-interview lite path
**Status:** Active

## Goal

Define a new interface `{{interface-name}}` to establish the contract described
below and create the initial implementation.

## Context

Contract description: {{contract-description}}

Initial implementor: {{initial-implementor}}

Placement notes: {{placement-notes}}

## Acceptance Criteria

- [ ] Interface `{{interface-name}}` is defined with the contract described above.
- [ ] `{{initial-implementor}}` implements `{{interface-name}}` correctly.
- [ ] Unit tests cover the contract expectations of `{{interface-name}}`.
- [ ] No regression in existing tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Define {{interface-name}} and implement in {{initial-implementor}} |

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
| (auto-filled) | Created from recipe `add-interface` | /aid-interview lite path |

## tasks

### task-001 — Define {{interface-name}} and implement in {{initial-implementor}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define interface `{{interface-name}}` with the contract:
  {{contract-description}}. Implement the interface in `{{initial-implementor}}`.
  Placement notes: {{placement-notes}}. Add unit tests covering the contract.
- Acceptance Criteria:
  - [ ] Interface `{{interface-name}}` is defined with the contract described above.
  - [ ] `{{initial-implementor}}` implements `{{interface-name}}` correctly.
  - [ ] Unit tests cover the contract expectations of `{{interface-name}}`.
  - [ ] No regression in existing tests.
