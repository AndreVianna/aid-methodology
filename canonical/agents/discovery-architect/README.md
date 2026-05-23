> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Architect

**Sub-agent in the `/aid-discover` pipeline — one of four parallel analysts dispatched after the Scout.**

The Architect-of-Discovery maps the macro shape of the codebase: patterns, layers, technology stack, and UI architecture.

## What It Does

1. **Identifies architectural patterns** — MVVM, CQRS, Clean/Hexagonal, MVC, microservices, monolith, event-driven, and so on.
2. **Maps module boundaries** — DI registration, data flow, dependency direction between layers.
3. **Catalogs the tech stack** — languages, frameworks, versions, package managers, runtime.
4. **Documents UI architecture** (if applicable) — frontend frameworks, state management, design system, accessibility patterns.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 2 | Dispatched in parallel with the 3 other analysts. |

## What It Produces

- **`.aid/knowledge/architecture.md`** — patterns, layer breakdown, key architectural decisions.
- **`.aid/knowledge/technology-stack.md`** — languages, frameworks, versions, runtime.
- **`.aid/knowledge/ui-architecture.md`** — UI patterns when the project has frontend code (else empty / N/A).

## Tools

Read, Glob, Grep, Bash, Write. Runs with `permissionMode: bypassPermissions` (background).

## Tier

**Large** — pattern recognition plus cross-codebase synthesis.

## How It Differs from Other Discovery Agents

| Agent | Owns |
|---|---|
| **Discovery Architect** (this) | Macro shape — patterns, layers, stack |
| Discovery Analyst | Module internals — conventions, schemas, file organization |
| Discovery Integrator | External surface — APIs, integrations, domain terms |
| Discovery Quality | Cross-cutting concerns — tests, security, tech debt |

## Key Behaviors

- **Pattern-named.** Uses canonical names (Hexagonal, CQRS, etc.) and cites code evidence for each.
- **Stack-versioned.** Pins exact versions from manifests, never "latest."
- **Honest about absence.** If the project has no frontend, `ui-architecture.md` says so explicitly with `Status: N/A`.
