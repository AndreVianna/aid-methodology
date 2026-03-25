# Knowledge Base Templates

The Knowledge Base (`.aid/knowledge/`) is the gravitational center of every AID project. Every phase reads from it. Any phase can trigger updates to it. It outlives the project.

## Documents

| Template | Purpose | Source |
|----------|---------|--------|
| INDEX.md | Lightweight context map — 2-3 line summaries per doc, included in every task | aid-discover |
| [architecture.md](architecture.md) | Patterns, layers, module boundaries, data flow | aid-discover |
| [module-map.md](module-map.md) | Every module: purpose, dependencies, size, coverage | aid-discover |
| [technology-stack.md](technology-stack.md) | Languages, frameworks, versions, runtime | aid-discover |
| [coding-standards.md](coding-standards.md) | Naming conventions, error handling, patterns | aid-discover |
| [data-model.md](data-model.md) | Schema, entities, relationships, migrations | aid-discover |
| [api-contracts.md](api-contracts.md) | APIs consumed/exposed, auth models, rate limits | aid-discover + aid-interview |
| [integration-map.md](integration-map.md) | Message queues, caches, third-party services | aid-discover + aid-interview |
| [domain-glossary.md](domain-glossary.md) | Business terms, domain language, entity definitions | aid-interview |
| [test-landscape.md](test-landscape.md) | Test frameworks, coverage, CI/CD pipeline | aid-discover |
| [security-model.md](security-model.md) | Auth/authz, secrets, compliance | aid-interview + aid-discover |
| [tech-debt.md](tech-debt.md) | Known debt items with file refs and risk ratings | aid-discover |
| [infrastructure.md](infrastructure.md) | Hosting, networking, environments, deployment | aid-discover + aid-interview |
| [additional-info.md](additional-info.md) | Structured Q&A — gaps, assumptions, clarifications with impact tracking | aid-discover |

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
| architecture.md | ✅ Complete | {date} | aid-discover |
| module-map.md | ✅ Complete | {date} | aid-discover |
| technology-stack.md | ✅ Complete | {date} | aid-discover |
| coding-standards.md | ⚠️ Partial | {date} | aid-discover (inferred) |
| data-model.md | ✅ Complete | {date} | aid-discover |
| api-contracts.md | ❌ Missing | — | Needs interview |
| integration-map.md | ❌ Missing | — | Needs interview |
| domain-glossary.md | ❌ Missing | — | Needs interview |
| test-landscape.md | ✅ Complete | {date} | aid-discover |
| security-model.md | ❌ Missing | — | Needs interview |
| tech-debt.md | ✅ Complete | {date} | aid-discover |
| infrastructure.md | ❌ Missing | — | Needs interview |
| additional-info.md | ✅ Complete | {date} | aid-discover |

**Status key:** ✅ Complete | ⚠️ Partial | ❌ Missing
```

## Not Every Document Is Required

- **Simple CLI tool:** 4-5 documents (architecture, tech-stack, coding-standards, additional-info)
- **Greenfield project:** Start with technology-stack, coding-standards, domain-glossary — populated from interview
- **Enterprise monorepo:** All 13 documents, possibly more
- **Data pipeline:** Focus on data-model, integration-map, api-contracts, domain-glossary

The Discovery phase assesses the project and generates what's relevant. Don't create documents for things that don't exist.

## Revision History

Every KB update should be logged in the README.md revision history section:

```markdown
# Revision Log

| Date | Source Phase | Document | Change Description |
|------|------------|----------|-------------------|
| {date} | aid-discover | All | Initial Knowledge Base creation |
| {date} | aid-plan (GAP-001) | module-map.md | Added 8 missing service consumers |
| {date} | aid-implement (IMP-003) | architecture.md | Corrected async model for RecordingService |
```
ected async model for RecordingService |
```
ected async model for RecordingService |
```
