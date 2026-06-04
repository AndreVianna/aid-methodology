---
name: fix-api
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix an API-layer defect (status, contract, payload) and add a regression test.
---

## spec

# Fix API defect: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-api` via /aid-interview lite path
**Status:** Active

## Goal

Fix the API-layer defect described below (incorrect status code, contract violation,
or malformed payload) and add a regression test to prevent recurrence.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the defect.
- [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
- [ ] API contract (status codes, response shape) matches the intended behavior.
- [ ] No regression in existing API endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix API defect and add regression test: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-api` | /aid-interview lite path |

## tasks

### task-001 — Fix API defect and add regression test: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}. Add a regression test covering the fixed
  endpoint behavior.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the defect.
  - [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
  - [ ] API contract (status codes, response shape) matches the intended behavior.
  - [ ] No regression in existing API endpoint tests.
