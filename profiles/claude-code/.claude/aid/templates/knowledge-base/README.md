---
kb-category: meta
source: hand-authored
intent: |
  Knowledge Base completeness table + revision history. Meta-document; not part of the reviewed knowledge surface.
contracts: []
changelog:
  - 2026-05-26: KB Authoring v2 template seed
---

# Knowledge Base Templates

The Knowledge Base (`.aid/knowledge/`) is the gravitational center of every AID project. Every phase reads from it. Any phase can trigger updates to it. It outlives the project.

## Documents

> **Note:** `INDEX.md` is auto-generated at `.aid/knowledge/INDEX.md` by `build-kb-index.sh` from each KB doc's `intent:` frontmatter field. There is no template for it here — adopters should not hand-author it.

| Template | Purpose | Source |
|----------|---------|--------|
| [project-structure.md](project-structure.md) | Top-level folder layout, entry points, key config files | aid-discover |
| [external-sources.md](external-sources.md) | External documentation ingested into the KB | aid-discover |
| [architecture.md](architecture.md) | Patterns, layers, module boundaries, data flow | aid-discover |
| [technology-stack.md](technology-stack.md) | Languages, frameworks, versions, runtime | aid-discover |
| [module-map.md](module-map.md) | Every module: purpose, dependencies, size, coverage | aid-discover |
| [coding-standards.md](coding-standards.md) | Naming conventions, error handling, patterns | aid-discover |
| [schemas.md](schemas.md) | Schema, entities, relationships, migrations | aid-discover |
| [pipeline-contracts.md](pipeline-contracts.md) | Pipelines/APIs consumed/exposed, auth models, rate limits | aid-discover + aid-interview |
| [integration-map.md](integration-map.md) | Message queues, caches, third-party services | aid-discover + aid-interview |
| [domain-glossary.md](domain-glossary.md) | Business terms, domain language, entity definitions | aid-interview |
| [test-landscape.md](test-landscape.md) | Test frameworks, coverage, CI/CD pipeline | aid-discover |
| [tech-debt.md](tech-debt.md) | Known debt items with file refs and risk ratings | aid-discover |
| [infrastructure.md](infrastructure.md) | Hosting, networking, environments, deployment | aid-discover + aid-interview |
| [feature-inventory.md](feature-inventory.md) | Feature list with module, endpoint, and data entity mapping | aid-discover + aid-interview |

## Top-Level README Template

The KB root `README.md` tracks completeness across all documents:

```markdown
# Knowledge Base — {Project Name}

**Created:** {date}
**Last Updated:** {date}
**Source:** aid-discover

## Documents

| Document | Status | Last Updated | Source |
|----------|--------|-------------|--------|
| project-structure.md | ✅ Complete | {date} | aid-discover |
| external-sources.md | ✅ Complete | {date} | aid-discover |
| architecture.md | ✅ Complete | {date} | aid-discover |
| technology-stack.md | ✅ Complete | {date} | aid-discover |
| module-map.md | ✅ Complete | {date} | aid-discover |
| coding-standards.md | ⚠️ Partial | {date} | aid-discover (inferred) |
| schemas.md | ✅ Complete | {date} | aid-discover |
| pipeline-contracts.md | ❌ Missing | — | Needs interview |
| integration-map.md | ❌ Missing | — | Needs interview |
| domain-glossary.md | ❌ Missing | — | Needs interview |
| test-landscape.md | ✅ Complete | {date} | aid-discover |
| tech-debt.md | ✅ Complete | {date} | aid-discover |
| infrastructure.md | ❌ Missing | — | Needs interview |
| feature-inventory.md | ❌ Missing | — | Needs interview |

**Status key:** ✅ Complete | ⚠️ Partial | ❌ Missing
```

## Not Every Document Is Required

- **Simple CLI tool:** 4-5 documents (project-structure, architecture, technology-stack, coding-standards)
- **Greenfield project:** Start with project-structure, technology-stack, coding-standards, domain-glossary — populated from interview
- **Enterprise monorepo:** All standard-seed documents, possibly more
- **Data pipeline:** Focus on schemas, integration-map, pipeline-contracts, domain-glossary

The Discovery phase assesses the project and generates what's relevant. Don't create documents for things that don't exist.

## Revision History

Every KB update should be logged in the README.md revision history section:

```markdown
# Revision Log

| Date | Source Phase | Document | Change Description |
|------|------------|----------|-------------------|
| {date} | aid-discover | All | Initial Knowledge Base creation |
| {date} | aid-plan (Q&A) | module-map.md | Added 8 missing service consumers |
| {date} | aid-execute (IMP-003) | architecture.md | Corrected async model for RecordingService |
```
