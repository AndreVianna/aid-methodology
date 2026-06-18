---
name: add-entity
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a new persisted entity/table with a migration.
---

## spec

# Add entity: {{entity-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-entity` via /aid-interview lite path
**Status:** Active

## Goal

Add a new persisted entity `{{entity-name}}` with a schema migration, a
repository layer, and unit tests covering the model and persistence logic.

## Context

Entity fields / schema: {{entity-schema}}

Persistence layer notes: {{persistence-layer-notes}}

Relationships and constraints: {{relationships}}

Validation rules: {{validation-rules}}

## Acceptance Criteria

- [ ] `{{entity-name}}` entity is defined with the fields in the schema above.
- [ ] Migration runs cleanly on a fresh database and on an existing one.
- [ ] Repository CRUD methods are implemented and unit-tested.
- [ ] Validation rules are enforced and tested.
- [ ] No regression in existing persistence tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Define schema and migration for {{entity-name}} |
| task-002 | TEST | Unit tests for {{entity-name}} model and repository |

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
| (auto-filled) | Created from recipe `add-entity` | /aid-interview lite path |

## tasks

### task-001 — Define schema and migration for {{entity-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define the `{{entity-name}}` entity with fields ({{entity-schema}}),
  relationships and constraints ({{relationships}}), and validation rules
  ({{validation-rules}}). Create and apply a migration using the persistence
  layer ({{persistence-layer-notes}}).
- Acceptance Criteria:
  - [ ] Entity is defined with all specified fields and constraints.
  - [ ] Migration runs cleanly on a fresh and an existing database.
  - [ ] Validation rules are enforced at the model layer.

### task-002 — Unit tests for {{entity-name}} model and repository

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit tests for the `{{entity-name}}` model covering validation
  rules, constraints, and CRUD repository operations against the persistence
  layer ({{persistence-layer-notes}}).
- Acceptance Criteria:
  - [ ] All validation rules have passing unit tests.
  - [ ] Repository CRUD methods are unit-tested (create, read, update, delete).
  - [ ] No regression in existing persistence tests.
