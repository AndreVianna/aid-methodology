# Section Template — `library` Profile

For libraries / SDKs that export an API but don't have a UI runtime.
Slimmer than web-app: no UI section, no service-mesh diagram.

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | DISCOVERY-STATE.md, project-structure.md, technology-stack.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Packages / Modules | | module-map.md |
| 4 | Data Model & Types | ★ | data-model.md |
| 5 | Public API | | api-contracts.md |
| 6 | Consumers & Integrations | | integration-map.md |
| 7 | Features / Capabilities | ★ | feature-inventory.md |
| 8 | Security Considerations | | security-model.md |
| 9 | Test Landscape | | test-landscape.md |
| 10 | Tech Debt | | tech-debt.md |
| 11 | Build & Distribution | | infrastructure.md, technology-stack.md |
| 12 | Knowledge Base Index | | INDEX.md |

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

## Skipped sections (vs web-app)

- ✗ Frontend Architecture (no UI)
- ✗ HTTP Request Flow diagram (no server)
- ✗ Integration Hub diagram (replaced by Consumer Registry)

## Differences in cards / palette

- Replace "Plugins" / "OSGi components" terminology with "Packages" / "Modules".
- "Features" framing → "Capabilities" or "Public API surface area".
