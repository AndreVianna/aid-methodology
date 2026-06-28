---
name: fix-regression
applies-to: bug-fix
slot-count: 5
task-count: 1
summary: Fix a regression: bisect to the introducing change, fix, and lock with a test.
---

## spec

# Fix regression: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-regression` via /aid-describe lite path
**Status:** Active

## Goal

Fix the regression described below by identifying the introducing change, applying
the fix, and locking the correct behavior with a regression test.

## Context

{{bug-description-one-sentence}}

Introducing change: {{introducing-change}}

## Acceptance Criteria

- [ ] The introducing change is identified and documented.
- [ ] The reproduction steps no longer produce the regression.
- [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
- [ ] No further regression introduced by the fix.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix regression and lock with test: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-regression` | /aid-describe lite path |

## tasks

### task-001 — Fix regression and lock with test: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Introducing change: {{introducing-change}}.
  Reproduction: {{reproduction-steps}}. Intended behavior: {{intended-behavior}}.
  Add a regression test that locks the correct behavior.
- Acceptance Criteria:
  - [ ] The introducing change is identified and documented.
  - [ ] The reproduction steps no longer produce the regression.
  - [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
  - [ ] No further regression introduced by the fix.
