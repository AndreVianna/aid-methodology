---
name: add-docs
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Author a new documentation artifact (guide, README, release note).
---

## spec

# Add docs: {{release-version}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-docs` via /aid-describe lite path
**Status:** Active

## Goal

Draft and publish a new documentation artifact for {{release-version}}. The
canonical example is a release note; the same pattern applies to any new guide,
README, or reference document.

## Context

Summarize the purpose and scope of the document so readers and operators can
understand what changed, what was added, and how to use or integrate it.

## Acceptance Criteria

- [ ] `release-notes-{{release-version}}.md` (or the equivalent artifact) exists
  and covers all headline changes.
- [ ] Breaking changes section is accurate and complete (or explicitly states "None").
- [ ] Upgrade notes are actionable (step-by-step where relevant).
- [ ] Document reviewed and approved before the release tag is pushed.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Draft and publish the documentation artifact for {{release-version}} |

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
| (auto-filled) | Created from recipe `add-docs` | /aid-describe lite path |

## tasks

### task-001 — Draft and publish the documentation artifact for {{release-version}}

- Type: DOCUMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Author the documentation artifact covering: headline changes
  ({{headline-changes}}), breaking changes ({{breaking-changes}}), and upgrade
  notes ({{upgrade-notes}}). Follow the project's documentation style guide if one
  exists; for release notes use the [Added] / [Changed] / [Fixed] / [Removed] /
  [Security] section structure.
- Acceptance Criteria:
  - [ ] The artifact exists and covers all headline changes.
  - [ ] Breaking changes section is accurate and complete (or explicitly states "None").
  - [ ] Upgrade notes are actionable (step-by-step where relevant).
  - [ ] Document reviewed and approved before publication.
