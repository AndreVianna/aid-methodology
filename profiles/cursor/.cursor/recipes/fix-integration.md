---
name: fix-integration
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix a defect in an external-service integration and add a regression test.
---

## spec

# Fix integration defect: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-integration` via /aid-interview lite path
**Status:** Active

## Goal

Fix the defect in the external-service integration described below and add a regression
test to prevent recurrence.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the defect.
- [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
- [ ] Integration behaves as described in the intended behavior.
- [ ] No regression in other integration or contract tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix integration defect and add regression test: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-integration` | /aid-interview lite path |

## tasks

### task-001 — Fix integration defect and add regression test: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}. Add a regression test covering the fixed
  integration behavior (mocked or contract-level as appropriate for the external service).
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the defect.
  - [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
  - [ ] Integration behaves as described in the intended behavior.
  - [ ] No regression in other integration or contract tests.
