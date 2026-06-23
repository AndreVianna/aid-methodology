---
kb-category: primary
source: hand-authored
objective: Registry of external documentation, vendor specs, and reference URLs the project depends on.
summary: Read this before fetching documentation that may already be cataloged here.
sources:
  - https://example.vendor.com/docs   # replace with actual external URLs this doc summarizes
  # NOTE: sources: here are the EXTERNAL URLs/docs cataloged in this registry,
  # not repo-relative paths. This is the one template where sources: are external URLs.
tags: [external-docs, vendor-specs, references]
see_also: [integration-map.md]
owner: architect
audience: [developer, architect]
intent: |
  Registry of external documentation, vendor specs, and reference URLs the project depends on. Read this before fetching documentation that may already be cataloged.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# External Sources

> **Source:** aid-discover (Phase 1 — Pre-scan)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ No External Sources}
> **Last Updated:** {date}

---

## Sources

> List all external documentation provided by the user. If none were provided, state that
> explicitly — do not leave this section empty.

{If no external sources were provided:}

No external documentation was provided during discovery. All knowledge was derived from
repository content only. If external documentation becomes available, re-run discovery
or add paths during Q&A.

{If external sources were provided:}

| # | Path | Type | Accessible | Key Content |
|---|------|------|------------|-------------|
| 1 | {/path/to/docs} | {directory} | {✅/❌} | {Brief inventory of what's there} |
| 2 | {/path/to/spec.pdf} | {file} | {✅/❌} | {What the doc covers} |

---

## Content Inventory

> For each external source, list significant documents with their topics and key findings.

### Source 1: {path}

| Document | Topic | Key Findings | Referenced By |
|----------|-------|-------------|---------------|
| {filename} | {topic} | {what was found} | {which KB docs cite this} |

---

## Discrepancies

> Where external documentation disagrees with code reality. These are valuable findings.

| Source | Claim | Code Reality | Impact |
|--------|-------|-------------|--------|
| {doc path} | {what the doc says} | {what the code shows} | {High/Medium/Low} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial external source analysis |
