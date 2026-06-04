---
name: add-job
applies-to: new-feature
slot-count: 5
task-count: 2
summary: Add a scheduled/background job.
---

## spec

# Add job: {{job-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-job` via /aid-interview lite path
**Status:** Active

## Goal

Add a new scheduled or background job `{{job-name}}` with the defined schedule,
logic, and error-handling, covered by unit tests.

## Context

Job purpose: {{job-purpose}}

Schedule / trigger: {{schedule}}

Job logic summary: {{job-logic}}

Error handling and retry policy: {{error-handling}}

## Acceptance Criteria

- [ ] `{{job-name}}` job is registered and runs on the defined schedule/trigger.
- [ ] Job logic executes as described.
- [ ] Errors are caught and handled per the retry policy.
- [ ] Job is unit-tested for happy-path and error-path scenarios.
- [ ] No regression in existing job or scheduler behavior.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{job-name}} job logic and schedule |
| task-002 | TEST | Unit tests for {{job-name}} |

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
| (auto-filled) | Created from recipe `add-job` | /aid-interview lite path |

## tasks

### task-001 — Implement {{job-name}} job logic and schedule

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Implement the job `{{job-name}}` for purpose ({{job-purpose}}).
  Register it with the scheduler using the schedule/trigger ({{schedule}}).
  Implement the job logic ({{job-logic}}) and error handling and retry policy
  ({{error-handling}}).
- Acceptance Criteria:
  - [ ] Job is registered and fires on the defined schedule/trigger.
  - [ ] Job logic executes correctly.
  - [ ] Errors are caught and the retry policy is applied.

### task-002 — Unit tests for {{job-name}}

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Write unit tests for `{{job-name}}` covering the happy-path execution
  and at least one error-path scenario (e.g., transient failure triggering retry,
  permanent failure triggering error handling per {{error-handling}}).
- Acceptance Criteria:
  - [ ] Happy-path execution is tested and passes.
  - [ ] Error-path scenario is tested and retry/error handling behaves correctly.
  - [ ] No regression in existing job or scheduler tests.
