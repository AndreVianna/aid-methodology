---
name: aid-discover
description: Brownfield codebase analysis. Produces a structured Knowledge Base (knowledge/ directory). Use for new brownfield projects (full discovery) or when a downstream phase generates a GAP.md with discovery-needed (targeted discovery).
---

# Brownfield Codebase Discovery

Analyze an existing codebase and produce a structured `knowledge/` directory.

## Inputs

- Codebase access (local path, git URL, or archive)
- For targeted discovery: GAP.md or IMPEDIMENT.md that triggered re-entry

## Process

### 1. Structure Scan
Detect project type, map folder structure, count by language. Record in `knowledge/codebase-overview.md`.

### 2. Architecture Analysis
Identify patterns (MVVM, CQRS, Clean Architecture, etc.), module boundaries, data flow, DI registration. Record in `knowledge/architecture.md`.

### 3. Stack Inventory
Catalog languages, frameworks, versions, package managers, runtime. Record in `knowledge/technology-stack.md`.

### 4. Convention Mining
Infer coding standards from code (not docs): naming, error handling, logging, config, file organization. Mark as "⚠️ Inferred from code — needs confirmation". Record in `knowledge/coding-standards.md`.

### 5. Module Mapping
For each module: purpose, dependencies, size, test coverage. Record in `knowledge/module-map.md`.

### 6. Data Model Extraction
Schema, relationships, migrations, indexes. Record in `knowledge/data-model.md`.

### 7. Integration Surface
APIs consumed/exposed, message queues, caches, third-party services. Record in `knowledge/api-contracts.md` and `knowledge/integration-map.md`.

### 8. Test Landscape
Frameworks, test types, coverage, CI/CD. Record in `knowledge/test-landscape.md`.

### 9. Tech Debt Audit
Large files, circular deps, missing tests, outdated packages, TODO/FIXME density. Record in `knowledge/tech-debt.md` with risk ratings.

### 10. Gap Identification
What can't be determined from code alone. Record in `knowledge/open-questions.md`.

### 11. KB Index
Create `knowledge/README.md` with completeness tracking table. Initialize `knowledge/revision-log.md`.

## Targeted Discovery (Re-entry)

1. Read the GAP/IMPEDIMENT to understand exactly what's missing
2. Focus analysis ONLY on the identified area
3. Update specific KB document(s)
4. Add entry to `knowledge/revision-log.md`
5. Update `knowledge/README.md` status

## Output

`knowledge/` directory with up to 16 documents: README.md, codebase-overview, architecture, module-map, technology-stack, coding-standards, data-model, api-contracts, integration-map, domain-glossary, flow-diagrams, test-landscape, security-model, tech-debt, infrastructure, open-questions, revision-log.

## Quality Checklist

- [ ] No overlap between KB documents
- [ ] Claims grounded in code evidence (file paths, line numbers)
- [ ] Inferred info marked as inferred
- [ ] open-questions.md captures everything needing human input
- [ ] README.md reflects completeness status
- [ ] revision-log.md has initial discovery entry
