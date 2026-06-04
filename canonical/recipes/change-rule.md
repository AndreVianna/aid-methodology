---
name: change-rule
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing validation/business rule.
---

## spec

# Change rule: {{rule-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-rule` via /aid-interview lite path
**Status:** Active

## Goal

Modify the `{{rule-name}}` rule to reflect updated business requirements, ensuring
the enforcement point and all tests are updated consistently.

## Context

Current rule behavior: {{current-behavior}}

Intended rule behavior: {{intended-behavior}}

Enforcement point: {{enforcement-point}}

Rationale: {{rationale}}

## Acceptance Criteria

- [ ] The `{{rule-name}}` rule at `{{enforcement-point}}` now enforces:
  {{intended-behavior}}.
- [ ] Unit tests are updated or added to cover the new behavior.
- [ ] No regression in adjacent validation or business-logic tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Update {{rule-name}} rule logic and tests |

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
| (auto-filled) | Created from recipe `change-rule` | /aid-interview lite path |

## tasks

### task-001 — Update {{rule-name}} rule logic and tests

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the `{{rule-name}}` rule at `{{enforcement-point}}`. Current
  behavior: {{current-behavior}}. Apply the change to implement:
  {{intended-behavior}}. Rationale: {{rationale}}. Update existing unit tests
  and add new ones as needed to cover the changed logic.
- Acceptance Criteria:
  - [ ] Rule logic updated to match the intended behavior at the enforcement point.
  - [ ] Previous rule behavior tests updated to reflect the new expectation.
  - [ ] New test cases added if the rule change introduces new passing/failing cases.
  - [ ] No regression in adjacent validation tests.
