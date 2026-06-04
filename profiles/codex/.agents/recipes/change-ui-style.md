---
name: change-ui-style
applies-to: refactor
slot-count: 4
task-count: 1
summary: Change an existing style/theme rule without breaking layout.
---

## spec

# Change UI style: {{style-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-ui-style` via /aid-interview lite path
**Status:** Active

## Goal

Change the style rule or design token `{{style-name}}` from its current definition
to the intended definition without breaking layout or visual consistency.

## Context

Rationale: {{change-rationale}}

Current definition: {{current-definition}}

Intended definition: {{intended-definition}}

## Acceptance Criteria

- [ ] `{{style-name}}` is updated to the intended definition above.
- [ ] No unintended layout or visual regression across the UI.
- [ ] Affected components render correctly with the updated style.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{style-name}} style definition and verify layout |

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
| (auto-filled) | Created from recipe `change-ui-style` | /aid-interview lite path |

## tasks

### task-001 — Update {{style-name}} style definition and verify layout

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update `{{style-name}}` from its current definition
  ({{current-definition}}) to the intended definition ({{intended-definition}}).
  Rationale: {{change-rationale}}. Verify that the UI renders without layout
  or visual regression across affected components.
- Acceptance Criteria:
  - [ ] `{{style-name}}` matches the intended definition above.
  - [ ] No unintended layout or visual regression across the UI.
  - [ ] Affected components render correctly with the updated style.
