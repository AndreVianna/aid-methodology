---
name: fix-infrastructure
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix an infrastructure/deployment/config defect and confirm in the target environment.
---

## spec

# Fix infrastructure defect: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-infrastructure` via /aid-describe lite path
**Status:** Active

## Goal

Fix the infrastructure, deployment, or configuration defect described below and confirm
the fix in the target environment.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the defect.
- [ ] The fix is confirmed in the target environment (not just locally).
- [ ] No regression in adjacent infrastructure components.
- [ ] Configuration change (if any) is documented.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix and confirm infrastructure defect: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-infrastructure` | /aid-describe lite path |

## tasks

### task-001 — Fix and confirm infrastructure defect: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}. Confirm the fix in the target environment
  after applying.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the defect.
  - [ ] The fix is confirmed in the target environment.
  - [ ] No regression in adjacent infrastructure components.
  - [ ] Configuration change (if any) is documented.
