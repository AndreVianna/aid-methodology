---
name: add-ui-style
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a new style/theme rule or design token.
---

## spec

# Add UI style: {{style-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-ui-style` via /aid-describe lite path
**Status:** Active

## Goal

Add the style rule or design token `{{style-name}}` to the UI styling system.

## Context

Style description: {{style-description}}

Visual specification: {{visual-spec}}

Affected components: {{affected-components}}

## Acceptance Criteria

- [ ] `{{style-name}}` is defined in the styling system per the visual specification.
- [ ] Affected components in `{{affected-components}}` apply the new style correctly.
- [ ] No unintended layout or visual regression in the UI.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Add {{style-name}} style rule and apply to affected components |

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
| (auto-filled) | Created from recipe `add-ui-style` | /aid-describe lite path |

## tasks

### task-001 — Add {{style-name}} style rule and apply to affected components

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define `{{style-name}}` in the styling system. Style description:
  {{style-description}}. Visual specification: {{visual-spec}}. Apply the
  new style to all affected components listed in {{affected-components}}.
- Acceptance Criteria:
  - [ ] `{{style-name}}` is defined and consistent with the visual specification.
  - [ ] Affected components in `{{affected-components}}` render with the new style.
  - [ ] No unintended layout or visual regression in the UI.
