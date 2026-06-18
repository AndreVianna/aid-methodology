---
name: change-cli-command
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing CLI command's flags/behavior.
---

## spec

# Change CLI command: {{command-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-cli-command` via /aid-interview lite path
**Status:** Active

## Goal

Change the flags or behavior of the existing CLI command `{{command-name}}`
under `{{parent-command}}` as described, without breaking callers that depend
on the unchanged contract.

## Context

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Rationale: {{rationale}}

## Acceptance Criteria

- [ ] `{{command-name}}` exhibits the intended behavior after the change.
- [ ] Existing callers that depend on unchanged flags/output are unaffected.
- [ ] Help text is updated to reflect any flag changes.
- [ ] Unit tests are updated and pass.
- [ ] No regression in other CLI commands.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{command-name}} flags and behavior |

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
| (auto-filled) | Created from recipe `change-cli-command` | /aid-interview lite path |

## tasks

### task-001 — Update {{command-name}} flags and behavior

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update `{{command-name}}` under `{{parent-command}}` from its current
  behavior ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{rationale}}. Update argument validation, help text, and any
  affected tests.
- Acceptance Criteria:
  - [ ] `{{command-name}}` exhibits the intended behavior.
  - [ ] Help text reflects all changes.
  - [ ] Unchanged flags and outputs are unaffected.
  - [ ] All existing tests covering `{{command-name}}` are updated and pass.
  - [ ] No regression in other CLI commands.
