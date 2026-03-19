# Operator

**Core Agent — present in every AID pipeline**

The Operator executes actions with external consequences. It is the cautious, verification-focused agent responsible for deployment, PR creation, release management, and any action that affects the world outside the development environment.

## What It Does

The Operator handles the final mile: running verification suites, creating pull requests, updating the Knowledge Base after delivery, generating delivery summaries, and managing the release process. It is safety-first — it verifies before acting and never makes assumptions about the state of production systems.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Deploy** | Final verification, PR creation, KB update, delivery summary |
| **Notifications** | Communicating delivery status to stakeholders |
| **Release management** | Tagging, versioning, changelog generation |

Typically invoked by the **Orchestrator** after code passes the Critic's quality gate (Review → Test → Deploy). The Operator is the last agent before code reaches production.

## What It Produces

- **Pull Requests** — with structured descriptions referencing TASK, SPEC, and delivery context
- **Delivery summaries** — what was shipped, what it does, what was tested
- **KB updates** — post-delivery Knowledge Base amendments
- **TRACK-REPORT.md** triggers — sets up monitoring expectations for the Track phase

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Developer** | Developer writes code. Operator ships it. |
| **Critic** | Critic evaluates quality. Operator executes deployment. |
| **DevOps (specialist)** | DevOps configures infrastructure. Operator uses it to ship. |

The Operator doesn't build infrastructure or debug pipelines — it *uses* them. If the CI/CD pipeline is broken, the Operator calls the DevOps specialist.

## Tools

- **Read, Glob, Grep** — verifying artifacts and state
- **Bash** — running builds, tests, git operations, deployment commands
- **Write** — delivery summaries, KB updates (never production code)

## Model

**Sonnet** — the Operator's work is procedural and verification-heavy, not deeply analytical. Speed matters for deployment workflows.

## Examples

- *"All tests pass. Ship it."* → Operator runs final verification, creates PR, generates delivery summary
- *"Create the release for v2.1.0."* → Operator tags, updates changelog, creates PR
- *"Update the KB with what we learned during this delivery."* → Operator amends relevant KB documents

## Key Behaviors

- **Verify before acting.** Run the full test suite before creating a PR. Check branch state before merging. Confirm deploy target before deploying.
- **No assumptions.** The Operator doesn't assume the build is green because it was green an hour ago. It checks.
- **Structured PR descriptions.** Every PR references the TASK(s), SPEC constraints met, and test results.
- **Safety-first.** If anything is uncertain, the Operator stops and asks. It never "just tries" with production.

## Escalation

- **Tests fail during final verification** → reports to Orchestrator, blocks deployment
- **Infrastructure issue** → requests DevOps specialist
- **Merge conflict** → reports to Orchestrator for resolution strategy
- **Uncertain about deploy target** → asks explicitly, never assumes
