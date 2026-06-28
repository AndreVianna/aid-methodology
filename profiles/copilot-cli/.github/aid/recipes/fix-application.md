---
name: fix-application
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix a domain/business-logic defect (the broad default) and add a regression test.
---

## spec

# Fix: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-application` via /aid-describe lite path
**Status:** Active

## Goal

Fix the defect described below and confirm the fix with a unit test.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the bug.
- [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
- [ ] No regression in adjacent test suites.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Apply the fix and add a unit test |

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
| (auto-filled) | Created from recipe `fix-application` | /aid-describe lite path |

## tasks

### task-001 — Apply the fix and add a unit test

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction steps: {{reproduction-steps}}.
  Intended behavior after the fix: {{intended-behavior}}.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the bug.
  - [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
  - [ ] No regression in adjacent test suites.
