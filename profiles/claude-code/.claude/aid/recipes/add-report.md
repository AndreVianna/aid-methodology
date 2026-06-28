---
name: add-report
applies-to: new-feature
slot-count: 4
task-count: 1
summary: Author a new report/analysis artifact.
---

## spec

# Add report: {{report-title}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-report` via /aid-describe lite path
**Status:** Active

## Goal

Research, analyze, and author a new report artifact on the subject of
{{report-title}} for {{report-audience}}.

## Context

Report purpose: {{report-purpose}}

Report scope: {{report-scope}}

## Acceptance Criteria

- [ ] The report artifact `{{report-title}}` exists and addresses the stated purpose.
- [ ] Report covers the defined scope without gaps.
- [ ] Findings and recommendations are clearly supported by evidence.
- [ ] Document reviewed and approved before distribution.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Research, write, and review the report for {{report-title}} |

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
| (auto-filled) | Created from recipe `add-report` | /aid-describe lite path |

## tasks

### task-001 — Research, write, and review the report for {{report-title}}

- Type: DOCUMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Conduct research and analysis for {{report-title}} targeting
  {{report-audience}}. Document the findings covering: purpose
  ({{report-purpose}}) and scope ({{report-scope}}). Include supporting evidence,
  key findings, and actionable recommendations.
- Acceptance Criteria:
  - [ ] Report artifact exists addressing the stated purpose.
  - [ ] Report covers the defined scope without gaps.
  - [ ] Findings and recommendations are clearly supported by evidence.
  - [ ] Document reviewed and approved before distribution.
