---
name: change-schema
applies-to: refactor
slot-count: 5
task-count: 2
summary: Change an existing DB schema with a forward + rollback migration.
---

## spec

# Change schema: {{entity-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-schema` via /aid-describe lite path
**Status:** Active

## Goal

Change the database schema for `{{entity-name}}` as described, providing both
a forward migration and a rollback migration.

## Context

Current schema shape: {{current-shape}}

Target schema shape: {{target-shape}}

Rationale: {{rationale}}

Persistence layer notes: {{persistence-layer-notes}}

## Acceptance Criteria

- [ ] Forward migration transforms the schema from the current shape to the target shape.
- [ ] Rollback migration restores the schema to the current shape cleanly.
- [ ] Application code that reads or writes `{{entity-name}}` is updated to match the target schema.
- [ ] All existing tests that depend on `{{entity-name}}` are updated and pass.
- [ ] No regression in other persistence tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Write forward and rollback migrations for {{entity-name}} |
| task-002 | IMPLEMENT | Update application code and tests for schema change |

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
| (auto-filled) | Created from recipe `change-schema` | /aid-describe lite path |

## tasks

### task-001 — Write forward and rollback migrations for {{entity-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Write a forward migration that transforms `{{entity-name}}` from the
  current shape ({{current-shape}}) to the target shape ({{target-shape}}) using
  the persistence layer ({{persistence-layer-notes}}). Write a corresponding
  rollback migration. Rationale: {{rationale}}.
- Acceptance Criteria:
  - [ ] Forward migration runs cleanly on a fresh and an existing database.
  - [ ] Rollback migration restores the schema to the current shape cleanly.
  - [ ] No data loss for existing rows during the forward migration.

### task-002 — Update application code and tests for schema change

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Update all application code (models, repositories, queries) that
  references `{{entity-name}}` to align with the target schema ({{target-shape}}).
  Update affected tests.
- Acceptance Criteria:
  - [ ] All application code referencing `{{entity-name}}` uses the target schema.
  - [ ] Affected tests are updated and pass.
  - [ ] No regression in other persistence or application tests.
