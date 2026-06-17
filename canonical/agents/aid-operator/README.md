> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-operator

**Core Agent — present in every AID pipeline**

The Operator handles the release-gated ship: final verification, PR creation, release management, and KB updates after delivery. It is the last quality gate before work reaches production.

## What It Does

The Operator runs the full test suite, creates structured pull requests, generates delivery summaries, manages releases (tagging, versioning, changelogs), and updates the KB to reflect what shipped. Every action it takes has external consequences — PRs, tags, deployments — so it defaults to verification before action.

The Operator is distinct from the Developer: the Developer does per-task build verification; the Operator runs release-gated verification that confirms the entire delivery is ready to ship. The Operator absorbed the devops deploy-consult side: validating that CI/CD pipelines and deployment strategies are release-ready is part of the release owner's responsibility.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Deploy** | All states — IDLE, SELECTING, VERIFYING, PACKAGING: release verification, PR creation, tagging, KB update |

Default executor for the **aid-deploy** skill.

## What It Produces

- **Pull requests** with structured descriptions: TASK references, SPEC constraints met, test results
- **Delivery summaries** — what shipped, what it does, verification results
- **KB updates** — targeted amendments to `.aid/knowledge/` documents reflecting the shipped state
- **Release artifacts** — tags, changelog entries, version bumps

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-developer** | Developer verifies per-task builds. Operator runs release-gated final verification before shipping. |
| **aid-reviewer** | Reviewer grades work for quality issues. Operator verifies the build is green and the release is coherent. |
| **aid-tech-writer** | Tech Writer authors changelogs and release notes. Operator manages the release mechanics (tagging, PR, versioning). |

## Tools

- **Read, Glob, Grep** — reading task files, specs, test results
- **Bash** — running test suites, git operations, release scripts
- **Write** — delivery summaries, KB amendments

## Tier

**Medium tier** — release orchestration follows a defined procedure; deep reasoning is not required. The Operator's skill is in meticulous verification discipline, not in problem-solving.

## Examples

- *"Create the PR for delivery-003."* → Operator runs tests, verifies green, creates PR with TASK references and test results
- *"Tag and release v1.2.0."* → Operator creates tag, updates changelog, validates CI/CD pipeline triggers
- *"Update the KB after delivery."* → Operator amends the relevant KB docs to reflect the shipped feature state

## Key Behaviors

- **Verify before acting.** Full test suite before every PR or deployment action — no exceptions.
- **No assumptions.** Checks current state every time; never relies on memory of prior runs.
- **Structured PRs.** Every PR is a traceable record: TASKs, SPEC constraints, test evidence.
- **Safety-first.** Any uncertainty → stop and ask. Never guesses with production.

## Escalation

- **Tests fail during final verification** → reports to Orchestrator, blocks deployment
- **Infrastructure issue blocking release** → reports to Orchestrator
- **Merge conflict** → reports to Orchestrator
- **Uncertain about deploy target** → asks explicitly, never assumes
