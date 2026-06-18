---
name: improve-performance
applies-to: refactor
slot-count: 5
task-count: 2
summary: Improve performance of a hot path against a measured baseline, with no behavior change.
---

## spec

# Improve performance: {{hot-path}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `improve-performance` via /aid-interview lite path
**Status:** Active

## Goal

Improve the performance of `{{hot-path}}` against the measured baseline, with no
change to observable behavior.

## Context

Baseline measurement: {{baseline-measurement}}

Performance target: {{performance-target}}

Bottleneck description: {{bottleneck-description}}

Constraints: {{constraints}}

## Acceptance Criteria

- [ ] Performance of `{{hot-path}}` meets or exceeds `{{performance-target}}` in a
  reproducible benchmark.
- [ ] Observable behavior is unchanged (all existing tests pass).
- [ ] Benchmark results are recorded and compared against the baseline.
- [ ] No regression in adjacent code paths.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Apply performance improvements to {{hot-path}} |
| task-002 | TEST | Benchmark and verify performance gain for {{hot-path}} |

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
| (auto-filled) | Created from recipe `improve-performance` | /aid-interview lite path |

## tasks

### task-001 — Apply performance improvements to {{hot-path}}

- Type: REFACTOR
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Refactor `{{hot-path}}` to eliminate the performance bottleneck identified
  in the baseline measurement ({{baseline-measurement}}). Bottleneck: {{bottleneck-description}}.
  Respect constraints: {{constraints}}. Observable behavior must remain unchanged.
- Acceptance Criteria:
  - [ ] Code changes applied with no change to observable behavior.
  - [ ] All existing tests for `{{hot-path}}` still pass.
  - [ ] Code review confirms correctness and no hidden behavior change.

### task-002 — Benchmark and verify performance gain for {{hot-path}}

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Run a reproducible benchmark of `{{hot-path}}` and compare results to
  the baseline ({{baseline-measurement}}). Verify the performance target
  ({{performance-target}}) is met.
- Acceptance Criteria:
  - [ ] Benchmark results meet or exceed `{{performance-target}}`.
  - [ ] Results are recorded and compared against the baseline.
  - [ ] No regression in adjacent code paths.
