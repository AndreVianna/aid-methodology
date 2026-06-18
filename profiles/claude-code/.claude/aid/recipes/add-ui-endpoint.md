---
name: add-ui-endpoint
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a new UI page/route.
---

## spec

# Add UI endpoint: {{route-path}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-ui-endpoint` via /aid-interview lite path
**Status:** Active

## Goal

Add a new UI page at `{{route-path}}` that delivers the described user experience.

## Context

Page purpose: {{page-purpose}}

Layout description: {{layout-description}}

API dependencies: {{api-dependencies}}

Navigation placement: {{navigation-placement}}

## Acceptance Criteria

- [ ] The route `{{route-path}}` renders the page as described in the layout.
- [ ] The page integrates with the API dependencies listed above.
- [ ] Navigation to/from the page works as specified in the placement notes.
- [ ] The page is covered by UI tests (render + interaction).
- [ ] No regression in existing UI tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Build the {{route-path}} page and wire API dependencies |
| task-002 | TEST | UI tests for {{route-path}} page |

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
| (auto-filled) | Created from recipe `add-ui-endpoint` | /aid-interview lite path |

## tasks

### task-001 — Build the {{route-path}} page and wire API dependencies

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Create the UI page at `{{route-path}}`. Page purpose: {{page-purpose}}.
  Layout: {{layout-description}}. Wire the page to {{api-dependencies}}.
  Add navigation as described in {{navigation-placement}}.
- Acceptance Criteria:
  - [ ] The route `{{route-path}}` renders the page as described.
  - [ ] The page integrates correctly with the API dependencies.
  - [ ] Navigation to/from the page works as specified.

### task-002 — UI tests for {{route-path}} page

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write UI tests for the `{{route-path}}` page covering render,
  interaction, and at least one error/empty-state scenario.
- Acceptance Criteria:
  - [ ] Render test confirms the page displays correctly.
  - [ ] Interaction tests cover the main user flows.
  - [ ] At least one error/empty-state scenario is tested.
  - [ ] No regression in existing UI tests.
