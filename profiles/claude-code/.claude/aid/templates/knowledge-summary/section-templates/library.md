---
profile: library
target_diagrams: 5
notes: "Libraries and SDKs — type hierarchy and consumer registry replace UI and request-flow diagrams."
---

# Section Template — `library` Profile

For libraries / SDKs that export an API but don't have a UI runtime.
Slimmer than web-app: no UI section, no service-mesh diagram.

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | STATE.md, project-structure.md, technology-stack.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Packages / Modules | | module-map.md |
| 4 | Data Model & Types | ★ | schemas.md |
| 5 | Public API | | pipeline-contracts.md |
| 6 | Consumers & Integrations | | integration-map.md |
| 7 | Features / Capabilities | ★ | feature-inventory.md |
| 8 | Security Considerations | | coding-standards.md |
| 9 | Test Landscape | | test-landscape.md |
| 10 | Tech Debt | | tech-debt.md |
| 11 | Build & Distribution | | infrastructure.md, technology-stack.md |
| 12 | Concept Spine | | domain-glossary.md |
| 13 | Knowledge Base Index | | INDEX.md |

## Diagrams

| Fig | Type | Subject |
|-----|------|---------|
| 1 | flowchart TB | Stack: consumer apps → this library → its dependencies |
| 2 | graph TD | Internal package dependency graph |
| 3 | erDiagram (or `classDiagram`) | Type hierarchy / data structures |
| 4 | flowchart LR | Typical usage flow (call → return) |
| 5 | flowchart LR | Consumer registry (who uses this library) |

## Section content guidance

### §3 Packages / Modules
Card per package/module: purpose, exported symbols count, dependency on others.

### §4 Data Model & Types
For libraries this is more about the **type system** than persistent entities.
Use `classDiagram` if the library exposes class hierarchies; `erDiagram` if
it's primarily data structures.

### §5 Public API
Replaces the "REST endpoints" table with an exported symbols table:
- Symbol name
- Category (function / class / interface / type / constant)
- Stability (stable / experimental / deprecated)
- Source file

### §6 Consumers & Integrations
Who uses this library? List downstream consumers (if known from KB), package
managers it's published to, version pinning policies.

### §7 Features
Capabilities the library provides, status badges, links to docs.

### §11 Build & Distribution
Build commands + publication targets (npm, PyPI, Maven Central, etc.) +
version policy.

### §12 Concept Spine

The project's native vocabulary — the coined and domain-specific terms a library consumer
must understand to use the API correctly. Drawn from `domain-glossary.md` (the C4 doc).

For a library, include: any coined type names or abstractions whose meaning is specific to
this library (not derivable from the general language/framework), the design patterns the
library enforces by name (e.g. "builder", "flyweight", "registry" if project-specific), and
any non-standard error or lifecycle terms. Render as a scannable definition list:

- **{term}** — {one-line definition in this library's API context}

If `domain-glossary.md` is absent or empty, render a minimal placeholder; do not omit the
section. Wrap type/symbol names in `<code>`.

## Skipped sections (vs web-app)

- ✗ Frontend Architecture (no UI)
- ✗ HTTP Request Flow diagram (no server)
- ✗ Integration Hub diagram (replaced by Consumer Registry)

## Differences in cards / palette

- Replace "Plugins" / "OSGi components" terminology with "Packages" / "Modules".
- "Features" framing → "Capabilities" or "Public API surface area".
