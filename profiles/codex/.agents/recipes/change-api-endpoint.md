---
name: change-api-endpoint
applies-to: refactor
slot-count: 6
task-count: 2
summary: Change an existing API endpoint's contract/behavior without breaking clients.
---

## spec

# Change API endpoint: {{endpoint-path}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-api-endpoint` via /aid-interview lite path
**Status:** Active

## Goal

Change the contract or behavior of the `{{endpoint-path}}` API endpoint from its
current shape to the intended shape without breaking existing clients.

## Context

Rationale: {{change-rationale}}

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Backward-compatibility notes: {{compatibility-notes}}

Security notes: {{security-notes}}

## Acceptance Criteria

- [ ] `{{endpoint-path}}` behaves as described in the intended behavior above.
- [ ] Existing clients are not broken (backward-compatibility notes satisfied).
- [ ] Updated integration tests cover the new behavior.
- [ ] Security controls specified in the security notes are enforced.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{endpoint-path}} handler and contract |
| task-002 | TEST | Integration tests for updated {{endpoint-path}} behavior |

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
| (auto-filled) | Created from recipe `change-api-endpoint` | /aid-interview lite path |

## tasks

### task-001 — Update {{endpoint-path}} handler and contract

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the handler for `{{endpoint-path}}` from its current behavior
  ({{current-behavior}}) to the intended behavior ({{intended-behavior}}).
  Rationale: {{change-rationale}}. Preserve backward compatibility per
  {{compatibility-notes}}. Enforce security controls: {{security-notes}}.
- Acceptance Criteria:
  - [ ] `{{endpoint-path}}` behaves as described in the intended behavior above.
  - [ ] Existing clients are not broken (backward-compatibility notes satisfied).
  - [ ] Security controls from the security notes are enforced.

### task-002 — Integration tests for updated {{endpoint-path}} behavior

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Update or add integration tests for `{{endpoint-path}}` covering the
  new behavior, happy-path and at least one error path.
- Acceptance Criteria:
  - [ ] Integration tests cover the new behavior of `{{endpoint-path}}`.
  - [ ] At least one error-path test per changed operation.
  - [ ] No regression in existing endpoint tests.
