---
name: change-docs
applies-to: refactor
slot-count: 4
task-count: 1
summary: Update an existing documentation artifact.
---

## spec

# Change docs: {{doc-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `change-docs` via /aid-describe lite path
**Status:** Active

## Goal

Update the existing documentation artifact `{{doc-title}}` to reflect the changes
described, ensuring the artifact is accurate, complete, and consistent with the
current system state.

## Context

Document location: {{doc-location}}

Changes required: {{changes-required}}

Review criteria (how the reviewer will confirm the update is correct): {{review-criteria}}

## Acceptance Criteria

- [ ] `{{doc-title}}` is updated to reflect: {{changes-required}}.
- [ ] All cross-references and links within the artifact remain valid.
- [ ] A reviewer has confirmed the updated artifact satisfies: {{review-criteria}}.
- [ ] No other documentation artifacts are inadvertently broken.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Update {{doc-title}} |

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
| (auto-filled) | Created from recipe `change-docs` | /aid-describe lite path |

## tasks

### task-001 — Update {{doc-title}}

- Type: DOCUMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Update the documentation artifact `{{doc-title}}` located at
  `{{doc-location}}`. Apply the required changes: {{changes-required}}.
  Ensure all cross-references and links remain valid after the update.
  The reviewer will confirm correctness using: {{review-criteria}}.
- Acceptance Criteria:
  - [ ] Document updated to incorporate: {{changes-required}}.
  - [ ] All internal links and cross-references validated and corrected if needed.
  - [ ] A reviewer has confirmed the updated content satisfies the review criteria.
  - [ ] No adjacent documentation artifacts are inadvertently broken.
