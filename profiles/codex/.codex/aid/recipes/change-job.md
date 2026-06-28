---
name: change-job
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing job's schedule or logic.
---

## spec

# Change job: {{job-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-job` via /aid-describe lite path
**Status:** Active

## Goal

Change the schedule or logic of the existing job `{{job-name}}` from its
current behavior to the intended behavior.

## Context

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Rationale: {{rationale}}

Schedule / trigger changes: {{schedule}}

## Acceptance Criteria

- [ ] `{{job-name}}` runs on the updated schedule/trigger.
- [ ] Job logic reflects the intended behavior.
- [ ] Existing tests that cover `{{job-name}}` are updated and pass.
- [ ] No regression in other jobs or scheduler behavior.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{job-name}} schedule and logic |

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
| (auto-filled) | Created from recipe `change-job` | /aid-describe lite path |

## tasks

### task-001 — Update {{job-name}} schedule and logic

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the job `{{job-name}}` from its current behavior
  ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{rationale}}. Apply schedule/trigger changes ({{schedule}}).
  Update job logic, error handling, and any affected tests.
- Acceptance Criteria:
  - [ ] Job runs on the updated schedule/trigger.
  - [ ] Job logic reflects the intended behavior.
  - [ ] All existing tests for `{{job-name}}` are updated and pass.
  - [ ] No regression in other jobs or scheduler behavior.
