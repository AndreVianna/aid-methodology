---
name: add-feature-flag
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Add a feature flag gating new behavior.
---

## spec

# Add feature flag: {{flag-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-feature-flag` via /aid-interview lite path
**Status:** Active

## Goal

Add a feature flag `{{flag-name}}` that gates the described new behavior,
defaulting to off and wired to the relevant code paths.

## Context

Gated behavior: {{gated-behavior}}

Default state and rollout plan: {{default-and-rollout}}

Flag evaluation scope: {{flag-scope}}

## Acceptance Criteria

- [ ] `{{flag-name}}` is registered and defaults to off.
- [ ] The gated behavior is only active when the flag is enabled.
- [ ] Flag evaluation scope is enforced (e.g., per-user, per-environment).
- [ ] Disabling the flag restores the previous behavior with no side effects.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Add {{flag-name}} feature flag and gate behavior |

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
| (auto-filled) | Created from recipe `add-feature-flag` | /aid-interview lite path |

## tasks

### task-001 — Add {{flag-name}} feature flag and gate behavior

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Register the feature flag `{{flag-name}}` with default state and rollout
  plan ({{default-and-rollout}}) in scope ({{flag-scope}}). Wrap the gated
  behavior ({{gated-behavior}}) behind the flag check. Verify the flag defaults
  to off and that enabling/disabling it switches behavior correctly.
- Acceptance Criteria:
  - [ ] Flag is registered and defaults to off.
  - [ ] Gated behavior is only active when the flag is enabled.
  - [ ] Flag evaluation scope is correctly enforced.
  - [ ] Disabling the flag cleanly restores the prior behavior.
