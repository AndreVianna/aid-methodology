---
name: fix-security
applies-to: bug-fix
slot-count: 5
task-count: 1
summary: Fix a security vulnerability and add a test proving the exploit is closed.
---

## spec

# Fix security vulnerability: {{bug-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `fix-security` via /aid-interview lite path
**Status:** Active

## Goal

Fix the security vulnerability described below and add a test that proves the exploit
is closed, preventing the vulnerability from recurring undetected.

## Context

{{bug-description-one-sentence}}

Vulnerability type: {{vulnerability-type}}

## Acceptance Criteria

- [ ] The reproduction steps no longer demonstrate the vulnerability.
- [ ] A test exists that proves the exploit path is closed.
- [ ] No regression in existing security controls or adjacent tests.
- [ ] Fix is reviewed for correctness against the vulnerability type.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Fix security vulnerability and add exploit-closed test: {{bug-title}} |

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
| (auto-filled) | Created from recipe `fix-security` | /aid-interview lite path |

## tasks

### task-001 — Fix security vulnerability and add exploit-closed test: {{bug-title}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}} ({{vulnerability-type}}). Reproduction:
  {{reproduction-steps}}. Intended behavior: {{intended-behavior}}. Add a test
  that proves the exploit path is closed after the fix.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer demonstrate the vulnerability.
  - [ ] A test exists that proves the exploit path is closed.
  - [ ] No regression in existing security controls or adjacent tests.
  - [ ] Fix is reviewed for correctness against the vulnerability type.
