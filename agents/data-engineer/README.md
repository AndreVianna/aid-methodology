# Data Engineer

**Specialist Agent — invoked ad-hoc**

The Data Engineer provides expertise in schema design, database migrations, query optimization, ETL patterns, and data modeling. It is called when the pipeline encounters data-layer decisions.

## What It Does

The Data Engineer designs database schemas, writes and reviews migrations, optimizes queries, plans ETL pipelines, and evaluates data modeling decisions. It understands both relational and non-relational paradigms and can advise on the right tool for the job.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Architect** | During Plan — data model design, schema decisions |
| **Developer** | During Implement — migration creation, query optimization |
| **Critic** | During Review — evaluating data access patterns |
| **Orchestrator** | When any phase needs data expertise |

This agent is not part of the standard pipeline flow. It is called on demand when data-layer expertise is needed.

## What It Produces

- **Schema designs** — ERD descriptions, table definitions, index strategies
- **Migration files** — database migration scripts with up/down paths
- **Query optimizations** — EXPLAIN analysis, index recommendations, query rewrites
- **ETL pipeline designs** — extraction, transformation, and loading patterns
- **Data model reviews** — normalization analysis, relationship validation, performance implications

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Architect** | Architect designs the *system*. Data Engineer designs the *data layer*. |
| **Developer** | Developer writes application code that *uses* data. Data Engineer designs how data is *stored and accessed*. |
| **Performance** | Performance optimizes *overall system*. Data Engineer optimizes *data operations specifically*. |

## Tools

- **Read, Glob, Grep** — reviewing existing schemas, migrations, queries
- **Write, Edit** — creating migration files, schema documentation
- **Bash** — running database tools, EXPLAIN queries, migration validation

## Model

**Sonnet** — data engineering is largely pattern-based, applying known normalization rules, indexing strategies, and migration patterns.

## Examples

- *"Design the schema for the new notification system."* → ERD, table definitions, index strategy
- *"This query takes 3 seconds. Why?"* → EXPLAIN analysis, index recommendation, rewrite
- *"We're migrating from MySQL to PostgreSQL."* → Migration plan, compatibility analysis, data type mapping
- *"Review the data model for the new feature."* → Normalization check, relationship validation, performance analysis
