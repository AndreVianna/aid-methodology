---
name: change-interface
applies-to: refactor
slot-count: 5
task-count: 1
summary: Change an existing interface/contract and update its implementors.
---

## spec

# Change interface: {{interface-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-interface` via /aid-describe lite path
**Status:** Active

## Goal

Change interface `{{interface-name}}` from its current contract to the intended
contract and update all known implementors.

## Context

Rationale: {{change-rationale}}

Current contract: {{current-contract}}

Target contract: {{target-contract}}

Affected implementors: {{affected-implementors}}

## Acceptance Criteria

- [ ] `{{interface-name}}` matches the target contract described above.
- [ ] All implementors listed in `{{affected-implementors}}` compile and pass tests.
- [ ] No behavioral change to callers that use the interface through its existing contract.
- [ ] No regression in existing tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Update {{interface-name}} contract and all implementors |

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
| (auto-filled) | Created from recipe `change-interface` | /aid-describe lite path |

## tasks

### task-001 — Update {{interface-name}} contract and all implementors

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update interface `{{interface-name}}` from its current contract
  ({{current-contract}}) to the target contract ({{target-contract}}).
  Rationale: {{change-rationale}}. Update all implementors listed in
  {{affected-implementors}} to satisfy the new contract. Ensure no observable
  behavior change for callers.
- Acceptance Criteria:
  - [ ] `{{interface-name}}` matches the target contract described above.
  - [ ] All implementors listed in `{{affected-implementors}}` compile and pass tests.
  - [ ] No behavioral change to callers that use the interface through its existing contract.
  - [ ] No regression in existing tests.
