> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Analyst

**Sub-agent in the `/aid-discover` pipeline — one of four parallel analysts dispatched after the Scout.**

The Analyst mines the internals: how each module is built, what conventions the code actually follows, what the data model looks like.

## What It Does

1. **Maps every module** — purpose, dependencies, size, test coverage estimate.
2. **Mines coding conventions from real code** — naming, error handling, logging, config patterns, file organization. Not from a style guide; from actual files.
3. **Extracts the data model** — schemas, entity relationships, migrations, indexes, validation rules.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 3 | Dispatched in parallel with the 3 other analysts. |

## What It Produces

- **`.aid/knowledge/module-map.md`** — per-module breakdown with dependency graph.
- **`.aid/knowledge/coding-standards.md`** — mined conventions with file-path citations.
- **`.aid/knowledge/schemas.md`** — schema, relationships, migration history.

## Tools

Read, Glob, Grep, Bash, Write. Runs with `permissionMode: bypassPermissions` (background).

## Tier

**Large** — high-volume code reading with synthesis into KB structure.

## How It Differs from Other Discovery Agents

| Agent | Owns |
|---|---|
| Discovery Architect | Macro shape — patterns, layers, stack |
| **Discovery Analyst** (this) | Module internals — conventions, schemas, file organization |
| Discovery Integrator | External surface — APIs, integrations, domain terms |
| Discovery Quality | Cross-cutting concerns — tests, security, tech debt |

## Key Behaviors

- **Code over docs.** Conventions come from `grep`/`Glob` over real code, not from CONTRIBUTING.md. The two often disagree; the code wins.
- **Path-cited.** Every convention claim cites a durable anchor — file path + grep-recoverable symbol/heading, never a bare line number.
- **Volume-tolerant.** May delegate mechanical extraction to `simple-extractor` for large codebases; synthesis stays at the Analyst tier.
