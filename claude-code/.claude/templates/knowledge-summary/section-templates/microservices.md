# Section Template — `microservices` Profile

For repositories with 6+ independently-deployed services. Service mesh,
inter-service contracts, and saga orchestration become central.

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | DISCOVERY-STATE.md, project-structure.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Service Catalog | ★ | module-map.md |
| 4 | Inter-service Contracts | | api-contracts.md |
| 5 | Data Ownership | ★ | data-model.md |
| 6 | Integration Topology | | integration-map.md |
| 7 | Sagas / Workflows | | feature-inventory.md |
| 8 | Security & Auth | | security-model.md |
| 9 | Test Landscape | | test-landscape.md |
| 10 | Tech Debt | | tech-debt.md |
| 11 | Infrastructure & Deployment | | infrastructure.md |
| 12 | Knowledge Base Index | | INDEX.md |

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
