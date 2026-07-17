---
kb-category: primary
source: hand-authored
objective: Canonical feature list with status and traceability to work items for {project}.
summary: Read this to understand WHAT the project does at a feature level; status is Shipped / Partial / Deferred.
sources:
  - .aid/works/work-*/SPEC.md   # work-item specs that define features
  - {path/to/product/backlog}   # any external backlog or requirements doc
tags: [C9, features, status, traceability]
see_also: [architecture.md, tech-debt.md]
owner: pm
audience: [pm, developer, architect]
intent: |
  Canonical feature list with status (Shipped / Partial / Deferred), source, and traceability to work items. Read this to understand WHAT the project does at a feature level.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# Feature Inventory

> Maintained by Discovery (generated) + Deploy (delta updates).
> Source: user-provided list enriched with codebase analysis.

**Status value convention** (used by `build-metrics.sh` for the shipped/partial tally): use one of `✅ Shipped`, `⚠️ Partial`, `❌ Missing`, or `📋 Planned` in the Status column. The metrics builder counts `✅ Shipped` and `⚠️ Partial` occurrences. Other conventions (e.g., plain `Shipped` text without emoji) are accepted but will not appear in the auto-tally -- adjust `build-metrics.sh` if your project uses a different convention.

## Contents

- [Feature Table](#feature-table)
- [Change Log](#change-log)

---

## Feature Table

| # | Feature | Description | Status | Modules | Endpoints | Data Entities |
|---|---------|-------------|--------|---------|-----------|---------------|
| | *(populated during Discovery Q&A + FIX)* | | | | | |

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover + aid-describe | Initial feature inventory |
