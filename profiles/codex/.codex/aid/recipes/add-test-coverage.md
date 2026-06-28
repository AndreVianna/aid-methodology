---
name: add-test-coverage
applies-to: "*"
slot-count: 4
task-count: 1
summary: Add test coverage for any work type (bug fix, refactor, or new feature).
---

## spec

# Add unit test: {{target-class}}.{{target-method}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-test-coverage` via /aid-describe lite path
**Status:** Active

## Goal

Write a unit test for `{{target-method}}` in `{{target-class}}` that verifies
the specified behavior using {{test-framework}}.

## Context

The behavior under test: {{behavior-under-test}}

If this test is associated with a bug fix, verify that the test fails on the
pre-fix code and passes after the fix is applied.

## Acceptance Criteria

- [ ] A test for `{{target-class}}.{{target-method}}` exists in the {{test-framework}}
  test suite.
- [ ] The test verifies: {{behavior-under-test}}.
- [ ] If applicable: the test fails before the fix and passes after.
- [ ] No existing tests are broken by the new test file.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | TEST | Write unit test for {{target-class}}.{{target-method}} |

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
| (auto-filled) | Created from recipe `add-test-coverage` | /aid-describe lite path |

## tasks

### task-001 — Write unit test for {{target-class}}.{{target-method}}

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Using {{test-framework}}, write a unit test for `{{target-method}}` in
  `{{target-class}}` that verifies: {{behavior-under-test}}. If this task
  accompanies a bug fix, run the test before applying the fix to confirm it fails,
  then run it again after the fix to confirm it passes.
- Acceptance Criteria:
  - [ ] Test exists in the {{test-framework}} suite targeting
    `{{target-class}}.{{target-method}}`.
  - [ ] Test verifies the specified behavior: {{behavior-under-test}}.
  - [ ] If applicable: test fails pre-fix and passes post-fix.
  - [ ] No existing tests are broken by the new test file.
