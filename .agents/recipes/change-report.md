---
name: change-report
applies-to: refactor
slot-count: 4
task-count: 1
summary: Update an existing report/analysis artifact.
---

## spec

# Change report: {{report-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-report` via /aid-interview lite path
**Status:** Active

## Goal

Update the existing report or analysis artifact `{{report-title}}` to reflect new
data, revised findings, or changed requirements.

## Context

Report location: {{report-location}}

Changes required: {{changes-required}}

Review criteria (how the reviewer will confirm the update is correct): {{review-criteria}}

## Acceptance Criteria

- [ ] `{{report-title}}` is updated to reflect: {{changes-required}}.
- [ ] Data sources, metrics, or findings are accurate after the update.
- [ ] A reviewer has confirmed the updated report satisfies: {{review-criteria}}.
- [ ] No other reports or dependent artifacts are inadvertently broken.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Update {{report-title}} |

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
| (auto-filled) | Created from recipe `change-report` | /aid-interview lite path |

## tasks

### task-001 — Update {{report-title}}

- Type: DOCUMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the report or analysis artifact `{{report-title}}` located at
  `{{report-location}}`. Apply the required changes: {{changes-required}}.
  Verify that data sources, metrics, or referenced findings are accurate after
  the update. The reviewer will confirm correctness using: {{review-criteria}}.
- Acceptance Criteria:
  - [ ] Report updated to incorporate: {{changes-required}}.
  - [ ] Data sources, metrics, or referenced findings are accurate and current.
  - [ ] A reviewer has confirmed the updated report satisfies the review criteria.
  - [ ] No dependent artifacts or linked reports are inadvertently broken.
