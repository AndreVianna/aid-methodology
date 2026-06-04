---
name: rename-symbol
applies-to: refactor
slot-count: 4
task-count: 1
summary: Rename a symbol (class/method/variable) across the codebase with no behavior change.
---

## spec

# Rename symbol: {{old-name}} → {{new-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `rename-symbol` via /aid-interview lite path
**Status:** Active

## Goal

Rename the symbol `{{old-name}}` to `{{new-name}}` across the codebase with no
change to observable behavior.

## Context

Symbol kind: {{symbol-kind}}

Rationale: {{rename-rationale}}

## Acceptance Criteria

- [ ] All occurrences of `{{old-name}}` are renamed to `{{new-name}}` (source, tests, docs).
- [ ] No occurrence of the old name remains in source files (grep confirms).
- [ ] All existing tests pass after the rename.
- [ ] No behavior change introduced by the rename.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Rename {{old-name}} to {{new-name}} across the codebase |

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
| (auto-filled) | Created from recipe `rename-symbol` | /aid-interview lite path |

## tasks

### task-001 — Rename {{old-name}} to {{new-name}} across the codebase

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Rename the {{symbol-kind}} `{{old-name}}` to `{{new-name}}` across all
  source files, tests, and documentation. Rationale: {{rename-rationale}}. Use IDE
  rename or a targeted search-and-replace to ensure completeness.
- Acceptance Criteria:
  - [ ] All occurrences of `{{old-name}}` are renamed to `{{new-name}}`.
  - [ ] No occurrence of the old name remains in source files (grep confirms).
  - [ ] All existing tests pass after the rename.
  - [ ] No behavior change introduced by the rename.
