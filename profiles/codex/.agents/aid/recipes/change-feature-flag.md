---
name: change-feature-flag
applies-to: refactor
slot-count: 4
task-count: 1
summary: Change or retire an existing feature flag.
---

## spec

# Change feature flag: {{flag-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-feature-flag` via /aid-interview lite path
**Status:** Active

## Goal

Change or retire the existing feature flag `{{flag-name}}` — updating its
default, evaluation scope, or removing the flag and hard-coding the gated behavior.

## Context

Current behavior: {{current-behavior}}

Intended behavior: {{intended-behavior}}

Rationale: {{rationale}}

## Acceptance Criteria

- [ ] `{{flag-name}}` is updated or removed as described.
- [ ] If the flag is retired, the gated behavior is hard-coded and the flag check is removed.
- [ ] If the flag is kept, the new default/scope is applied and tested.
- [ ] No regression in flag-dependent behavior.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update or retire {{flag-name}} feature flag |

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
| (auto-filled) | Created from recipe `change-feature-flag` | /aid-interview lite path |

## tasks

### task-001 — Update or retire {{flag-name}} feature flag

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Change the feature flag `{{flag-name}}` from its current state
  ({{current-behavior}}) to the intended state ({{intended-behavior}}).
  Rationale: {{rationale}}. If retiring the flag, remove all flag checks,
  hard-code the enabled behavior, and clean up any flag registration code.
  If updating the flag, adjust the default value, evaluation scope, or gated
  code path as needed.
- Acceptance Criteria:
  - [ ] Flag is updated or removed as described.
  - [ ] All flag-check code paths are updated to reflect the change.
  - [ ] No dead code or stale flag references remain.
  - [ ] No regression in flag-dependent behavior.
