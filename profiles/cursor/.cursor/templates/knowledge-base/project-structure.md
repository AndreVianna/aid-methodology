# Project Structure

> **Source:** aid-discover (Phase 1 — Pre-scan)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Repository Overview

| Property | Value |
|----------|-------|
| **Root directory** | {path} |
| **Total files** | {count} |
| **Primary language(s)** | {languages with approximate %} |
| **Build system** | {npm/maven/dotnet/cargo/etc.} |

---

## Directory Tree

> Top 3-4 levels with annotations. Include file counts per major directory.

```
project-root/
├── src/                    # ({N} files) Main source code
│   ├── {module-a}/         # ({N} files) {purpose}
│   ├── {module-b}/         # ({N} files) {purpose}
│   └── {shared}/           # ({N} files) {purpose}
├── tests/                  # ({N} files) Test suites
├── docs/                   # ({N} files) Documentation
├── {config-dir}/           # ({N} files) Configuration
└── {other}/                # ({N} files) {purpose}
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

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial pre-scan |
