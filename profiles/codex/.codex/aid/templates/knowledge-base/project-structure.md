---
kb-category: primary
source: hand-authored
objective: Repository layout, top-level directory purposes, and file-inventory shape for {project}.
summary: Read this to understand the on-disk organization of the project before navigating any subtree.
sources:
  - .                           # repository root layout (tree-level structure)
tags: [C1, structure, layout, directories, files]
see_also: [module-map.md, architecture.md]
owner: architect
audience: [developer, architect]
intent: |
  Repository layout, top-level directory purposes, and file-inventory shape. Read this to understand the on-disk organization of the project.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# Project Structure

> **Source:** aid-discover (Phase 1 -- Pre-scan)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

## Contents

- [Repository Overview](#repository-overview)
- [Directory Tree](#directory-tree)
- [Key Files](#key-files)
- [Detected Technologies](#detected-technologies)
- [Documentation Found in Repository](#documentation-found-in-repository)
- [Change Log](#change-log)

---

## Repository Overview

| Property | Value |
|----------|-------|
| **Root directory** | {path} |
| **Primary language(s)** | {languages, most-used first} |
| **Build system** | {npm/maven/dotnet/cargo/etc.} |

---

## Directory Tree

> Top 3-4 levels with annotations. Describe each major directory's purpose (file counts drift — let the reader run `find`).

```
project-root/
├── src/                    # Main source code
│   ├── {module-a}/         # {purpose}
│   ├── {module-b}/         # {purpose}
│   └── {shared}/           # {purpose}
├── tests/                  # Test suites
├── docs/                   # Documentation
├── {config-dir}/           # Configuration
└── {other}/                # {purpose}
```

---

## Key Files

| File | Purpose |
|------|---------|
| {entry point} | {Main entry point / startup} |
| {build config} | {Build configuration (package.json, .csproj, pom.xml, etc.)} |
| {CI config} | {CI/CD pipeline definition} |
| {docker config} | {Container configuration} |
| {test config} | {Test framework configuration} |

---

## Detected Technologies

| Category | Technology | Evidence |
|----------|-----------|----------|
| Language | {e.g., TypeScript 5.3} | {package.json, tsconfig.json} |
| Framework | {e.g., Next.js 14} | {package.json} |
| Database | {e.g., PostgreSQL} | {docker-compose.yml, .env.example} |
| Testing | {e.g., Jest, Playwright} | {jest.config.ts, playwright.config.ts} |

---

## Documentation Found in Repository

| File/Directory | Content |
|----------------|---------|
| {README.md} | {brief description} |
| {docs/} | {what's in there} |
| {CONTRIBUTING.md} | {exists/missing} |

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial pre-scan |
