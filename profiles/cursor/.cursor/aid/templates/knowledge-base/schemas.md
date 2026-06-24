---
kb-category: primary
source: hand-authored
objective: Data schemas, artifact shapes, dataflow, and cardinality relationships for {project}.
summary: Read this when modeling persistence, designing migrations, or tracing data lineage.
sources:
  - src/                        # schema definitions and data model source
  - {path/to/migrations}        # database migrations
  - {path/to/schema/files}      # e.g., *.prisma, schema.graphql, *.json schema
tags: [C5, schemas, data-model, persistence, migrations]
see_also: [architecture.md, pipeline-contracts.md]
owner: architect
audience: [developer, architect]
intent: |
  Data schemas, artifact shapes, dataflow across the pipeline, and cardinality relationships. Read this when modeling persistence, designing migrations, or tracing data lineage.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# Data Model

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

## Contents

- [Database](#database)
- [Schema](#schema)
- [Relationships](#relationships)
- [Migrations](#migrations)
- [Soft Deletes](#soft-deletes)
- [Notable Data Patterns](#notable-data-patterns)
- [Data Volume](#data-volume)
- [Contracts](#contracts)
- [Change Log](#change-log)

---

## Database

| Property | Value |
|----------|-------|
| **Type** | {PostgreSQL / MySQL / SQLite / SQL Server / MongoDB / DynamoDB / other} |
| **Version** | {version} |
| **ORM / ODM** | {EF Core / Prisma / Hibernate / SQLAlchemy / Mongoose / none} |
| **Connection string location** | {path/to/config or env var name} |
| **Multiple databases?** | {Yes: list them / No} |

---

## Schema

> Document each table/collection. For large schemas, focus on the entities with the most business logic and relationships.

### {TableName / CollectionName}

> Brief description of what this entity represents.

| Column | Type | Nullable | Key | Description |
|--------|------|----------|-----|-------------|
| `id` | {uuid / bigint / ObjectId} | No | PK | Primary key |
| `{column}` | {type} | {Yes/No} | {FK → table.col / UQ / —} | {purpose} |
| `created_at` | {timestamp} | No | — | Record creation time |
| `updated_at` | {timestamp} | Yes | — | Last modification time |

**Indexes:**
- `{index_name}` on `({columns})` — {purpose}

---

## Relationships

> Express relationships in plain text. Per kb-authoring P10, use the text form below
> rather than diagrams (diagrams are not grepped and degrade outside a browser).

```
{Entity A} 1 ---- * {Entity B}       (one A has many B)
{Entity B} * ---- 1 {Entity C}       (many B belong to one C)
{Entity A} * ---- * {Entity D}       (many-to-many via {junction table})
```

**Entity-relationship summary table:**

| Entity | Relates to | Cardinality | Via |
|--------|-----------|-------------|-----|
| {Entity A} | {Entity B} | one-to-many | direct FK |
| {Entity B} | {Entity C} | many-to-one | direct FK |
| {Entity A} | {Entity D} | many-to-many | {junction_table} |

---

## Migrations

| Property | Value |
|----------|-------|
| **Framework** | {EF Core Migrations / Flyway / Alembic / Liquibase / manual} |
| **Location** | {path/to/migrations/} |
| **Naming convention** | {e.g., `{timestamp}_{description}` / `V{n}__{description}`} |
| **Latest migration** | {migration name / number} |
| **Auto-applied on startup?** | {Yes / No — run manually via CI} |

---

## Soft Deletes

| Property | Value |
|----------|-------|
| **Used?** | {Yes: which tables / No} |
| **Mechanism** | {`deleted_at` timestamp / `is_deleted` boolean / other} |
| **Filtered in ORM?** | {Yes — global query filter / No — manual where clause} |

---

## Notable Data Patterns

> Patterns that affect how agents should write queries and migrations.

- {e.g., "All timestamps are stored in UTC. Application converts to local time on display."}
- {e.g., "Audit trail: all inserts/updates to Orders are duplicated in orders_audit."}
- {e.g., "UUIDs used as PKs everywhere — no auto-increment integers."}
- {e.g., "JSON columns used in config table for flexible key-value storage."}

---

## Data Volume

> Rough order of magnitude — important for query design and indexing decisions.

| Table | Rows (approx.) | Growth Rate | Notes |
|-------|---------------|-------------|-------|
| {table} | {100K / 1M / 100M} | {stable / 10K/day / other} | |

---

## Contracts

> The structural shape a data change MUST satisfy -- the schema, the persistence contract, the
> cardinality rule. Without this an agent's change (a new column, a retype, a dropped field)
> breaks persistence or a downstream consumer. State the contract precisely and name the
> compatibility rule and every consumer the schema binds.

- **{Schema / table contract}:** {the canonical shape -- which fields are required, types,
  keys, and which consumers (migrations, ORM models, API DTOs) bind to it}.
- **Compatibility rule:** {e.g. "additive migrations only in a single release: a new column is
  nullable or has a default; dropping/retyping a column is a breaking migration that needs a
  backfill + a deploy-order plan"}.
- **{Cardinality / integrity}:** {e.g. "every Order row MUST reference an existing Customer
  (FK enforced); orphaned rows are an integrity violation"}.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial schema extraction |
