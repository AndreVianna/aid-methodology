---
kb-category: primary
notes: "Retired as project-type profile selector (feature-015/Change 1). Content recast
        as rendering hints for microservices-domain KB docs, keyed by kb-category tier and
        doc identity — not by project-type. The section set is derived from the resolved
        doc-set + frontmatter, not from this template."
---

# Rendering Hints — Microservices Domain Docs

> **Status:** Retired as a project-type profile selector (feature-015, Change 1).
> Profile-as-project-type auto-detection is replaced by the doc-set/domain-driven
> section derivation in `state-profile.md`. This file is now a **rendering hint
> reference** for GENERATE when the domain facets include `microservices` or `distributed`
> and the resolved doc-set contains the listed docs.

---

## Original section structure (preserved as rendering reference)

The following layout was the microservices profile's fixed section order. It is **not
selected as a template**; it is kept as domain-specific rendering guidance. The resolved
doc-set order (from `state-profile.md` §4) is authoritative.

For repositories with 6+ independently-deployed services. Service mesh,
inter-service contracts, and saga orchestration become central.

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | STATE.md, project-structure.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Service Catalog | ★ | module-map.md |
| 4 | Inter-service Contracts | | pipeline-contracts.md |
| 5 | Data Ownership | ★ | schemas.md |
| 6 | Integration Topology | | integration-map.md |
| 7 | Sagas / Workflows | | feature-inventory.md |
| 8 | Security & Auth | | coding-standards.md |
| 9 | Test Landscape | | test-landscape.md |
| 10 | Tech Debt | | tech-debt.md |
| 11 | Infrastructure & Deployment | | infrastructure.md |
| 12 | Concept Spine | | domain-glossary.md |
| 13 | Knowledge Base Index | | INDEX.md |

## Diagrams

| Fig | Type | Subject |
|-----|------|---------|
| 1 | flowchart TB | Layered architecture: clients → gateway → services → data stores |
| 2 | graph TD | Service dependency graph (call edges) |
| 3 | flowchart LR | Authentication / authorization flow |
| 4 | erDiagram per service | Per-service entity ownership (collapse to table if too many) |
| 5 | flowchart LR | A representative cross-service saga |
| 6 | flowchart TD | Deployment topology (cluster, namespaces, mesh) |

## Section content guidance

### §3 Service Catalog (FEATURED)
Tabular view, one row per service:
- Name
- Purpose (one line)
- Tech stack (language, framework)
- Owns (entities / aggregates)
- Exposes (HTTP / gRPC / messages)
- Consumes (other services / external)
- Deployment (k8s manifest, container image)
- Test coverage
- Status badge

If 10+ services, add a top-level filter by domain or team.

### §4 Inter-service Contracts
Per-service API tables, but emphasize the **contracts** between services:
- Service A → Service B: what does A call on B?
- Versioning policy
- Backwards-compat strategy

### §5 Data Ownership (FEATURED)
Each entity belongs to exactly one service. Surface this clearly:
- Per-service ER mini-diagrams (if practical), OR
- A single global ER diagram with service ownership color-coded.

### §6 Integration Topology
Service mesh diagram + table of inter-service comm protocols (REST, gRPC,
message bus, etc.) and reliability properties (timeouts, retries, circuit
breaker config).

### §7 Sagas / Workflows
Cross-service business workflows. One diagram + narrative per major saga.

### §11 Infrastructure & Deployment
Deployment manifests, cluster topology, observability stack, scaling
strategy.

### §12 Concept Spine

The project's native vocabulary — the domain and system terms that span services and that
every team member must share. Drawn from `domain-glossary.md` (the C4 ubiquitous-language doc).

For microservices, include: the bounded-context names if they are project-coined rather
than industry-standard, aggregate root names, event names (if event-driven and the names
are non-obvious), and any cross-service protocol or pattern terms specific to this system
(e.g. "saga", "outbox", "idempotency key" if the term is used in a project-specific way).
Render as a scannable definition list:

- **{term}** — {one-line definition in this system's domain context}

If `domain-glossary.md` is absent or empty, render a minimal placeholder; do not omit the
section.

## Differences from web-app

- Service catalog (§3) replaces "Modules" with a heavier table format.
- Data Model (§5) emphasizes ownership boundaries.
- Integrations (§6) becomes the largest section (mesh-shaped).
- Sagas section (§7) replaces "Features" framing.

## Special considerations

- **Many services = wide tables.** Use `.tbl-wrap` with `overflow-x: auto`.
- **Diagrams may be too dense.** If service count exceeds ~12, split the
  dependency graph into clusters by domain.
- **Cross-service consistency.** The skill should flag if two services
  contradict each other in their KB docs (deferred to a future enhancement;
  not in v1).
