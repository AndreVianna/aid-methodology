> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Integrator

**Sub-agent in the `/aid-discover` pipeline — one of four parallel analysts dispatched after the Scout.**

The Integrator maps everything the codebase talks to (or is talked to by) — and the vocabulary it uses internally.

## What It Does

1. **Maps APIs exposed** — endpoints, methods, request/response shapes, auth.
2. **Maps APIs consumed** — external services, SDKs, HTTP/RPC clients, webhooks inbound.
3. **Identifies async surface** — message queues, event buses, caches, third-party integrations.
4. **Builds the domain glossary** — terminology mined from class names, method names, constants, and comments that encode business concepts.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 4 | Dispatched in parallel with the 3 other analysts. |

## What It Produces

- **`.aid/knowledge/pipeline-contracts.md`** — exposed plus consumed pipelines/APIs, breaking-change risk per contract.
- **`.aid/knowledge/integration-map.md`** — external systems, sync/async surface, integration topology.
- **`.aid/knowledge/domain-glossary.md`** — alphabetized vocabulary with `[[wikilinks]]`.

## Tools

Read, Glob, Grep, Bash, Write. Runs with `permissionMode: bypassPermissions` (background).

## Tier

**Large** — surface-area mapping plus naming synthesis.

## How It Differs from Other Discovery Agents

| Agent | Owns |
|---|---|
| Discovery Architect | Macro shape — patterns, layers, stack |
| Discovery Analyst | Module internals — conventions, schemas, file organization |
| **Discovery Integrator** (this) | External surface — APIs, integrations, domain terms |
| Discovery Quality | Cross-cutting concerns — tests, security, tech debt |

## Key Behaviors

- **Both sides of every integration.** For each external system: how we call it AND how it calls us (if applicable).
- **Domain over generic.** Glossary surfaces business concepts (Tenant, Invoice, Audit Trail) — not framework terms.
- **Honest about emptiness.** If there is no HTTP/pipeline surface, `pipeline-contracts.md` says so plainly rather than padding with template text.
