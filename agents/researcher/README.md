# Researcher

**Core Agent — present in every AID pipeline**

The Researcher investigates, classifies, and synthesizes information. It is the primary information-gathering agent — the one you send when you need to *understand* something before acting on it.

## What It Does

The Researcher reads code, documentation, logs, APIs, configuration files, and any other information source relevant to the project. It produces structured documents: Knowledge Base entries, analysis reports, dependency maps, convention catalogs. It does not design, implement, or judge — it *discovers and documents*.

Think of it as the project's investigative journalist: relentless about facts, careful about structure, and allergic to assumptions.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Discover** | Full brownfield codebase analysis → produces the 13-document Knowledge Base |
| **Track** | Interprets production telemetry, error patterns, performance metrics |
| **Any phase** | Targeted KB updates when a gap is identified (via GAP.md) |
| **Ad-hoc** | Investigating a specific subsystem, library, API, or integration point |

Typically invoked by the **Orchestrator** at the start of a project (Discovery) or when any phase identifies a knowledge gap. The **Critic** may also request research when reviewing code that touches unfamiliar subsystems.

## What It Produces

- **Knowledge Base documents** (`aid-workspace/knowledge/`) — architecture, conventions, data models, integrations, tech debt, and 8 more
- **Analysis reports** — structured findings with evidence and citations
- **Dependency maps** — what depends on what, and why
- **Convention catalogs** — how the existing codebase does things (not how it *should*)

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Architect** | Architect *designs* based on understanding. Researcher *creates* the understanding. |
| **Critic** | Critic *judges* quality. Researcher *documents* reality without judgment. |
| **Developer** | Developer *modifies* code. Researcher only *reads* it. |

The Researcher is read-heavy by design. It should never modify production code. It writes only to KB documents and analysis artifacts.

## Tools

- **Read, Glob, Grep** — primary investigation tools
- **Bash** — read-heavy commands: `find`, `tree`, `wc`, `rg`, `cat`, `head`, `tail`
- **Write** — only for KB documents and reports (never production code)

## Model

**Opus** — all agents use Opus for consistent deep reasoning across the pipeline.

## Examples

- *"We inherited a Java monorepo. What's in here?"* → Researcher runs full Discovery, produces KB
- *"Deployment is failing. What changed in the last 3 commits?"* → Researcher investigates and reports
- *"The Review found a pattern we don't understand in the auth module."* → Researcher does targeted analysis, updates `aid-workspace/knowledge/authentication.md`
- *"Production latency spiked. What do the logs show?"* → Researcher analyzes telemetry in Track phase

## Escalation

When the Researcher encounters something it cannot resolve through investigation alone:
- **Missing access** → reports to Orchestrator
- **Ambiguous requirements** → creates GAP.md with `type: needs-interview`
- **Contradictory evidence** → documents both sides, flags for human decision
