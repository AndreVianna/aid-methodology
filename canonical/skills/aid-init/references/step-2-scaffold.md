# State: SCAFFOLD

Create the `.aid/knowledge/` directory and all 16 KB document templates.

> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [● SCAFFOLD ] → [ META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

▶ Scaffolding Knowledge Base (~5–10 s for 16 template files)

Create `.aid/knowledge/` directory and all 16 KB document templates.

### For Brownfield Projects

Create each file with a header indicating it's pending discovery:

```markdown
# {Document Title}

> **Source:** aid-discover
> **Status:** ❌ Pending Discovery
> **Last Updated:** —

*This document will be populated by `/aid-discover`.*
```

The 16 documents:

| File | Title |
|------|-------|
| `project-structure.md` | Project Structure |
| `external-sources.md` | External Sources |
| `architecture.md` | Architecture |
| `technology-stack.md` | Technology Stack |
| `module-map.md` | Module Map |
| `coding-standards.md` | Coding Standards |
| `data-model.md` | Data Model |
| `api-contracts.md` | API Contracts |
| `integration-map.md` | Integration Map |
| `domain-glossary.md` | Domain Glossary |
| `test-landscape.md` | Test Landscape |
| `security-model.md` | Security Model |
| `tech-debt.md` | Tech Debt |
| `infrastructure.md` | Infrastructure |
| `ui-architecture.md` | UI Architecture |
| `feature-inventory.md` | Feature Inventory |

**Special case — external-sources.md:** If the user provided external paths in Q4, write
them into the file immediately:

```markdown
# External Sources

> **Source:** aid-init
> **Status:** ⚠️ Paths Registered — Pending Discovery
> **Last Updated:** {date}

## Registered Sources

| # | Path | Type | Accessible | Notes |
|---|------|------|------------|-------|
| 1 | /path/to/docs | directory | ✅ | 23 files |
| 2 | /path/to/spec.pdf | file | ✅ | |

*Content analysis will be performed by `/aid-discover` (discovery-scout).*
```

If no external paths: write the standard "no external documentation" message.

✓ Scaffolding Knowledge Base done

### For Greenfield Projects

Create each file with a header indicating it will be filled during interview/specify:

```markdown
# {Document Title}

> **Source:** aid-interview / aid-specify
> **Status:** ❌ Pending
> **Last Updated:** —

*This document will be populated as requirements are gathered and specifications are written.*
```

**Greenfield documents are the same 16 files.** Some will remain sparse (e.g., tech-debt.md
for a new project), and that's expected. The reviewer in later phases understands this.

**Advance:** Next state is `META-DOCS` — when this state's work completes, router prints `Next: [State: META-DOCS] — run /aid-init again` and exits.
