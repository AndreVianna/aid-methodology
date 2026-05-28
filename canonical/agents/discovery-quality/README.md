> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Quality

**Sub-agent in the `/aid-discover` pipeline — one of four parallel analysts dispatched after the Scout.**

The Quality agent owns the cross-cutting concerns that no single feature owns: testing, security, tech debt, infrastructure quality.

## What It Does

1. **Assesses the test landscape** — frameworks, test types (unit / integration / E2E), coverage tooling, CI/CD integration, gaps.
2. **Evaluates security** — auth/authz patterns, secrets management, OWASP concerns, dependency risk, severity-tagged findings.
3. **Audits tech debt** — large files, circular dependencies, missing tests, outdated packages, TODO/FIXME density, dead-code indicators. Severity-tagged with Resolution Roadmap.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 5 | Dispatched in parallel with the 3 other analysts. |

## What It Produces

- **`.aid/knowledge/test-landscape.md`** — test stack, coverage, gaps.
- **`.aid/knowledge/tech-debt.md`** — severity-tagged debt items, plus a Resolution Roadmap.

## Tools

Read, Glob, Grep, Bash, Write. Runs with `permissionMode: bypassPermissions` (background).

## Tier

**Large** — wide-ranging assessment requiring judgment on severity.

## How It Differs from Other Discovery Agents

| Agent | Owns |
|---|---|
| Discovery Architect | Macro shape — patterns, layers, stack |
| Discovery Analyst | Module internals — conventions, schemas, file organization |
| Discovery Integrator | External surface — APIs, integrations, domain terms |
| **Discovery Quality** (this) | Cross-cutting concerns — tests, security, tech debt |

## Key Behaviors

- **Severity-tagged.** Every finding is CRITICAL / HIGH / MEDIUM / LOW / INFO. No untagged claims.
- **Evidence-cited.** Each finding points to a file path or pattern. "No tests" requires evidence; "few tests" requires a count.
- **Constructive on debt.** Tech-debt findings map to Resolution Roadmap items the team can plan against.
