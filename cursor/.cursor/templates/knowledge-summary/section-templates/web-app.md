# Section Template — `web-app` Profile

For backend + frontend monoliths (like MAM Modules). Most comprehensive layout
with 13 sections and 8 diagrams.

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | DISCOVERY-STATE.md, project-structure.md, technology-stack.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Modules / Plugins | | module-map.md |
| 4 | Data Model | ★ | data-model.md |
| 5 | API Surface | | api-contracts.md |
| 6 | Integrations | | integration-map.md |
| 7 | Frontend Architecture | | ui-architecture.md |
| 8 | Features | ★ | feature-inventory.md |
| 9 | Security Model | | security-model.md |
| 10 | Test Landscape | | test-landscape.md |
| 11 | Tech Debt | | tech-debt.md |
| 12 | Infrastructure & Build | | infrastructure.md, technology-stack.md |
| 13 | Knowledge Base Index | | INDEX.md |

## Diagrams

| Fig | Type | Subject |
|-----|------|---------|
| 1 | flowchart TB | Stack layers (downstream → project → platform → runtime) |
| 2 | graph TD | Module/plugin dependency DAG |
| 3 | flowchart LR | HTTP request flow (client → server → service → repo → DB) |
| 4 | erDiagram | Entity relationships with cardinality, PK/FK/UK markers |
| 5 | flowchart LR | Integration hub (inbound peers ← project → outbound peers) |
| 6 | flowchart TD | A key business workflow (e.g. ingest, signup, checkout) |
| 7 | flowchart LR | Async event flow (if project uses message bus) |
| 8 | flowchart LR | Frontend layered pattern |

## Section content guidance

### §1 At a Glance
4×2 card grid: modules count, entities, features, tests, components, namespaces,
jobs (or whichever metrics the project surfaces), plus 1 "downstream consumer"
card if applicable. Add a short "What this is" callout.

### §2 Architecture
3 diagrams + a 2×2 grid of intent-vs-reality cards (Documented intent,
Implementation reality, Technology choices, DI/wiring style).

### §3 Modules / Plugins
Card per module showing: purpose, file counts, key entities, exported API status,
test counts. Use `card.plugin` style with `<dl>` metadata.

### §4 Data Model
ER diagram + a full entity table with columns: Plugin, Entity, Mapping
(JPA/hbm.xml/etc), Versioning, Key Fields, Notes. Plus 4 callouts for known
data-model gotchas (no version on aggregate, cross-plugin refs, dialect-only
upgrades, doc-vs-code drift).

### §5 API Surface
Namespace table + auth callout + OpenAPI/spec callout + version-skew warning if
applicable. Optional accordion with key request schemas.

### §6 Integrations
Integration hub diagram + workflow diagram + event-flow diagram + summary table
of all peers (direction, peer, protocol, status badge).

### §7 Frontend Architecture
Layered pattern diagram + per-package version table + 4 callouts (drift, state
split rule, code conventions, version skew with build).

### §8 Features
Accordion per bounded context with feature rows: ID, name, description, status
badge. Open by default for featured profile.

### §9 Security Model
4-up card grid (auth delegation, authz tier, gap callouts, defenses) + 4
specific callout boxes for known security gaps.

### §10 Test Landscape
Numbers card grid + per-module test table + a "pipeline truth" callout that
exposes any claims-vs-reality mismatches.

### §11 Tech Debt
Severity-grouped accordions (Critical / High / Medium / Low / Inherited). Each
debt item: ID, title, evidence, effort.

### §12 Infrastructure & Build
CLI command table with status badges (works / broken / no-op) + 4 cards (CI,
artifact, backend build, frontend build).

### §13 Knowledge Base Index
Full table of every `.aid/knowledge/*.md` with one-line summaries and links.

## Theme palette mapping (per-section accent)

- §1 — neutral cards
- §2, §4, §8 (featured) — `--accent` highlight, `★` indicator
- §11 — severity colors (`--err`, `--warn`, `--info`, `--text-dim`)
- §10 — `--ok` for passing, `--err` for failing checks
