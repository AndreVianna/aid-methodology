---
name: fix-ui
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix a UI-layer defect (rendering, interaction, state) and add a regression test.
---

## spec

# Fix UI defect: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-ui` via /aid-interview lite path
**Status:** Active

## Goal

Fix the UI-layer defect described below (incorrect rendering, broken interaction,
or wrong state) and add a regression test to prevent recurrence.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the defect.
- [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
- [ ] UI renders and behaves as described in the intended behavior.
- [ ] No regression in existing UI component or page tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix UI defect and add regression test: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-ui` | /aid-interview lite path |

## tasks

### task-001 — Fix UI defect and add regression test: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}. Add a regression test covering the fixed
  UI behavior (rendering, interaction, or state as appropriate).
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the defect.
  - [ ] A regression test exists that fails on the pre-fix code and passes post-fix.
  - [ ] UI renders and behaves as described in the intended behavior.
  - [ ] No regression in existing UI component or page tests.
