> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# aid-tech-writer

**Core Agent — present in every AID pipeline**

The Tech Writer authors user-facing documentation — API docs, changelogs, READMEs, user guides, and release notes. It owns the doc-type boundary between "what users read" and "what the pipeline reads."

## What It Does

The Tech Writer creates and improves documentation that a person consuming the product will read. It ensures code examples work, language is audience-appropriate, and changelogs follow the Keep a Changelog format. It is also invoked for narrative KB documents when explicit human-readable prose is needed (onboarding, methodology explanations).

The boundary with the Researcher: the Researcher writes KB/analysis documents that the AID pipeline consumes (module-map.md, coding-standards.md, architecture.md). The Tech Writer writes documents that users of the product consume (README.md, API docs, user guides). Both `What You Don't Do` sections make this delineation explicit.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Execute** | DOCUMENT-typed tasks: write or update user-facing docs |
| **Discover** | Narrative KB docs when the doc-set includes human-readable prose |
| **Deploy** | Release notes and changelog production |

## What It Produces

- **API documentation** — endpoint → method → parameters → examples → error codes
- **READMEs and user guides** — install, usage, contributing, license sections
- **Changelogs and release notes** — structured [Added]/[Changed]/[Fixed]/[Removed]/[Security] sections
- **Doc reviews** — finding → location → severity → suggestion for existing doc quality work

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-researcher** | Researcher writes KB/analysis docs for the pipeline. Tech Writer writes user-facing docs for the product's consumers. |
| **aid-reviewer** | Reviewer grades work against acceptance criteria. Tech Writer writes and improves docs. |
| **aid-operator** | Operator manages release mechanics (tagging, PRs). Tech Writer writes the changelog and release notes content. |

## Tools

- **Read, Glob, Grep** — reading code, existing docs, specs for content extraction
- **Write, Edit** — producing and updating documentation files
- **Bash** — verifying code examples, checking doc structure

## Tier

**Medium tier** — documentation authoring requires accuracy and audience awareness, not deep reasoning. The Tech Writer's skill is in clarity, correctness, and consistency, not in problem-solving.

## Examples

- *"DOCUMENT task: write the API docs for the new auth endpoints."* → Tech Writer produces endpoint docs with examples
- *"Add a changelog entry for delivery-003."* → Tech Writer produces the [Added]/[Changed]/[Fixed] sections
- *"The README is out of date."* → Tech Writer reviews the README against current code, proposes updates

## Key Behaviors

- **Accuracy first.** Wrong documentation actively harms users; correctness takes priority over style.
- **Audience-scoped.** API docs speak to developers; user guides speak to end users. Never mixing levels in the same doc.
- **Examples must work.** Every code example is tested or explicitly marked as untested.
- **User-facing boundary.** If the AID pipeline reads it (not a user), it belongs with the Researcher.

## Escalation

- **Cannot verify code behavior** → asks Developer or Researcher for confirmation before documenting
- **Significant inaccuracy in existing docs** → flags to Orchestrator before rewriting (scope may exceed the task)
- **Missing source material** → reports to Orchestrator
