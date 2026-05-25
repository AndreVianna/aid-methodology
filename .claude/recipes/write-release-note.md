---
name: write-release-note
applies-to: single-doc
slot-count: 4
task-count: 1
---

## spec

# Release Note: {{release-version}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `write-release-note` via /aid-interview lite path
**Status:** Active

## Goal

Draft and edit the release note document for version {{release-version}}.

## Context

Summarize the changes shipped in this release so users and operators can
understand what changed, what broke, and how to upgrade.

## Acceptance Criteria

- [ ] `release-notes-{{release-version}}.md` exists and covers all headline changes.
- [ ] Breaking changes section is accurate and complete (or explicitly states "None").
- [ ] Upgrade notes are actionable (step-by-step where relevant).
- [ ] Document reviewed and approved before the release tag is pushed.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Draft and edit release-notes-{{release-version}}.md |

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
| (auto-filled) | Created from recipe `write-release-note` | /aid-interview lite path |

## tasks

### task-001 — Draft and edit release-notes-{{release-version}}.md

- Type: DOCUMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Author `release-notes-{{release-version}}.md` covering: headline changes
  ({{headline-changes}}), breaking changes ({{breaking-changes}}), and upgrade
  notes ({{upgrade-notes}}). Follow the project's release-note style guide if one
  exists; otherwise use the [Added] / [Changed] / [Fixed] / [Removed] / [Security]
  section structure.
- Acceptance Criteria:
  - [ ] `release-notes-{{release-version}}.md` exists and covers all headline changes.
  - [ ] Breaking changes section is accurate and complete (or explicitly states "None").
  - [ ] Upgrade notes are actionable (step-by-step where relevant).
  - [ ] Document reviewed and approved before the release tag is pushed.
