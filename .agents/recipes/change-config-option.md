---
name: change-config-option
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing config option's default/validation.
---

## spec

# Change config option: {{option-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-config-option` via /aid-interview lite path
**Status:** Active

## Goal

Change the default value, validation rules, or behavior wiring of the existing
configuration option `{{option-name}}`.

## Context

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Rationale: {{rationale}}

Affected application behavior: {{affected-behavior}}

## Acceptance Criteria

- [ ] `{{option-name}}` default and/or validation reflect the intended behavior.
- [ ] Existing deployments with explicit overrides are unaffected.
- [ ] Affected behavior reads the updated value correctly.
- [ ] Documentation is updated to reflect the change.
- [ ] No regression in other config-dependent behavior.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{option-name}} default, validation, and docs |

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
| (auto-filled) | Created from recipe `change-config-option` | /aid-interview lite path |

## tasks

### task-001 — Update {{option-name}} default, validation, and docs

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the configuration option `{{option-name}}` from its current
  behavior ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{rationale}}. Update validation logic, default value, and any
  affected behavior wiring ({{affected-behavior}}). Update documentation.
- Acceptance Criteria:
  - [ ] Option default and validation reflect the intended behavior.
  - [ ] Existing deployments with explicit overrides continue to work.
  - [ ] Affected behavior reads the updated value correctly.
  - [ ] Configuration reference documentation is updated.
  - [ ] No regression in config-dependent tests.
