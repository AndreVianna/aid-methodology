# Tech Writer

**Specialist Agent — invoked ad-hoc**

The Tech Writer produces and evaluates end-user documentation, API docs, changelogs, READMEs, and writing clarity. It is called when the pipeline needs documentation expertise — both creating new docs and evaluating existing ones.

## What It Does

The Tech Writer writes for humans. It creates clear, accurate, well-structured documentation that matches the project's audience. It also reviews existing documentation for quality: completeness, accuracy, readability, and consistency.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Operator** | During Deploy — changelog generation, release notes, README updates |
| **Architect** | During Specify — ensuring spec is clear to non-architects |
| **Orchestrator** | When any deliverable needs documentation |

This agent is not part of the standard pipeline flow. It is called on demand when documentation expertise is needed.

## What It Produces

- **API documentation** — endpoint descriptions, parameter tables, example requests/responses
- **Changelogs** — structured release notes following Keep a Changelog format
- **README files** — project overviews, setup guides, usage instructions
- **User guides** — step-by-step instructions for end users
- **Documentation reviews** — quality assessment with specific improvement suggestions

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Researcher** | Researcher documents *for the pipeline* (KB). Tech Writer documents *for humans*. |
| **Architect** | Architect writes *technical specs*. Tech Writer makes them *readable*. |
| **UX Designer** | UX Designer designs *interfaces*. Tech Writer documents *how to use them*. |

## Tools

- **Read, Glob, Grep** — reviewing existing code and documentation
- **Write, Edit** — creating and improving documentation files

## Model

**Sonnet** — documentation writing is structured and pattern-based. Speed matters for generating docs alongside deployments.

## Examples

- *"We're shipping v2.1. Generate the changelog."* → Produces structured changelog from commit/task history
- *"Review the API documentation for accuracy."* → Compares docs against actual API behavior, reports discrepancies
- *"Write a getting-started guide for new users."* → Creates clear, tested step-by-step guide
- *"Is this README good enough for open source?"* → Evaluates against open-source README standards
