---
name: add-ui-component
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a reusable UI component.
---

## spec

# Add UI component: {{component-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-ui-component` via /aid-interview lite path
**Status:** Active

## Goal

Add a reusable UI component `{{component-name}}` that supports the described
props and visual contract.

## Context

Component purpose: {{component-purpose}}

Props and API: {{props-description}}

Visual specification: {{visual-spec}}

Usage context: {{usage-context}}

## Acceptance Criteria

- [ ] `{{component-name}}` is implemented with the props defined in the description above.
- [ ] The component renders correctly per the visual specification.
- [ ] The component is used in at least one location per the usage context.
- [ ] Unit tests cover rendering and prop variations.
- [ ] No regression in existing UI tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{component-name}} component |
| task-002 | TEST | Unit tests for {{component-name}} component |

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
| (auto-filled) | Created from recipe `add-ui-component` | /aid-interview lite path |

## tasks

### task-001 — Implement {{component-name}} component

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Build `{{component-name}}` with the following props and API:
  {{props-description}}. Visual specification: {{visual-spec}}. Integrate
  the component in the usage context: {{usage-context}}.
  Component purpose: {{component-purpose}}.
- Acceptance Criteria:
  - [ ] `{{component-name}}` accepts the defined props and renders correctly.
  - [ ] The component renders per the visual specification.
  - [ ] The component is used correctly in `{{usage-context}}`.

### task-002 — Unit tests for {{component-name}} component

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit tests for `{{component-name}}` covering default rendering,
  prop variations, and edge cases (e.g., empty/error states).
- Acceptance Criteria:
  - [ ] Default render test passes.
  - [ ] Tests cover the main prop variations from `{{props-description}}`.
  - [ ] At least one edge-case scenario is tested.
  - [ ] No regression in existing UI tests.
