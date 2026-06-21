---
name: bump-dependency
applies-to: refactor
slot-count: 4
task-count: 2
summary: Upgrade a dependency to a target version and reconcile breaking changes.
---

## spec

# Bump dependency: {{dependency-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `bump-dependency` via /aid-interview lite path
**Status:** Active

## Goal

Upgrade `{{dependency-name}}` from `{{current-version}}` to `{{target-version}}` and
reconcile any breaking changes, leaving the codebase in a clean, tested state.

## Context

Breaking changes / migration notes: {{migration-notes}}

## Acceptance Criteria

- [ ] `{{dependency-name}}` is updated from `{{current-version}}` to `{{target-version}}` in all manifests.
- [ ] All breaking changes listed in the migration notes are reconciled.
- [ ] All existing tests pass after the upgrade.
- [ ] No other dependency versions are inadvertently changed.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Upgrade {{dependency-name}} to {{target-version}} and reconcile breaking changes |
| task-002 | TEST | Verify test suite after {{dependency-name}} upgrade |

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
| (auto-filled) | Created from recipe `bump-dependency` | /aid-interview lite path |

## tasks

### task-001 — Upgrade {{dependency-name}} to {{target-version}} and reconcile breaking changes

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update `{{dependency-name}}` from `{{current-version}}` to `{{target-version}}` in
  all manifests and lock files. Apply code changes required by the migration notes:
  {{migration-notes}}. Resolve any compile or type errors introduced by the upgrade.
- Acceptance Criteria:
  - [ ] `{{dependency-name}}` is at `{{target-version}}` (was `{{current-version}}`) in all manifests and lock files.
  - [ ] All breaking changes from the migration notes are addressed.
  - [ ] Code compiles (or passes linting) with no new errors.

### task-002 — Verify test suite after {{dependency-name}} upgrade

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Run the full test suite against the upgraded `{{dependency-name}}` and confirm
  all tests pass. Investigate and fix any failures introduced by the upgrade.
- Acceptance Criteria:
  - [ ] All existing tests pass after the upgrade.
  - [ ] No other dependency versions were inadvertently changed.
  - [ ] Any test failures caused by the upgrade are resolved and documented.
