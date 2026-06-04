---
name: add-rule
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a validation or business rule.
---

## spec

# Add rule: {{rule-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-rule` via /aid-interview lite path
**Status:** Active

## Goal

Implement the `{{rule-name}}` validation or business rule at the specified
enforcement point and cover it with unit tests.

## Context

Rule description: {{rule-description}}

Enforcement point: {{enforcement-point}}

Error response on violation: {{error-response}}

## Acceptance Criteria

- [ ] The `{{rule-name}}` rule is enforced at `{{enforcement-point}}`.
- [ ] Rule logic matches the description: {{rule-description}}.
- [ ] A rule violation returns the expected error response: {{error-response}}.
- [ ] Unit tests cover the passing case and at least one violation case.
- [ ] No regression in adjacent validation or business-logic tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{rule-name}} rule at {{enforcement-point}} |

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
| (auto-filled) | Created from recipe `add-rule` | /aid-interview lite path |

## tasks

### task-001 — Implement {{rule-name}} rule at {{enforcement-point}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Implement the `{{rule-name}}` rule. Rule description: {{rule-description}}.
  Enforce the rule at `{{enforcement-point}}`. On violation, return the error
  response: {{error-response}}. Add unit tests for the passing case and at least
  one violation case.
- Acceptance Criteria:
  - [ ] Rule is implemented and enforced at the specified enforcement point.
  - [ ] Rule logic matches the description.
  - [ ] Unit test for the passing case passes.
  - [ ] Unit test for a rule violation returns the expected error response.
  - [ ] No regression in existing validation tests.
