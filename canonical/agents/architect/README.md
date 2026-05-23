> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Architect

**Core Agent — present in every AID pipeline**

The Architect transforms understanding into structure. It takes requirements and knowledge and produces designs — specifications, plans, task decompositions. It is the bridge between "what we need" and "how we'll build it."

## What It Does

The Architect is the design-thinking specialist. It reads REQUIREMENTS.md, the Knowledge Base, and any existing project context, then produces the structural artifacts that guide implementation: SPEC.md, PLAN.md, and task-NNN.md files (with an execution graph appended to PLAN.md).

The Architect doesn't write code and doesn't evaluate code. It *designs* — choosing patterns, defining interfaces, scoping deliverables, decomposing work into executable tasks with clear acceptance criteria.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Specify** | Transforms REQUIREMENTS.md + KB into a grounded SPEC.md |
| **Plan** | Defines MVP scope, modules, deliverables, test scenarios → PLAN.md |
| **Detail** | Decomposes plan into typed task files (task-NNN.md) plus an execution graph in PLAN.md |

Typically invoked by the **Orchestrator** after the Interview phase completes. May be re-invoked when Q&A entries in a STATE file trigger re-specification or re-planning.

## What It Produces

- **SPEC.md** — formal specification grounded in KB reality, not generic templates
- **PLAN.md** — strategic roadmap: MVP scope, modules, delivery order, test scenarios, plus the execution graph from the Detail phase
- **task-NNN.md** — individual task files with acceptance criteria, relevant KB references, and constraints

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Researcher** | Researcher discovers *what exists*. Architect decides *what to build*. |
| **Developer** | Developer *implements* the design. Architect *creates* the design. |
| **Reviewer** | Reviewer evaluates *after the fact*. Architect designs *before the fact*. |

The Architect's output is the contract that the Developer follows and the Reviewer reviews against. Bad architecture means bad everything downstream.

## Tools

- **Read, Glob, Grep** — for consuming KB, requirements, existing code structure
- **Write, Edit** — for producing specs, plans, and task files
- **Bash** — for exploring project structure, running analysis commands

## Tier

**Large tier** — complex reasoning. The Architect makes decisions that cascade through the entire project. Trade-off analysis, pattern selection, and scope management require deep thinking that downstream phases cannot easily correct.

## Examples

- *"REQUIREMENTS.md is complete. Create the spec."* → Architect produces SPEC.md grounded in KB
- *"We need to plan the MVP."* → Architect defines modules, delivery order, test scenarios
- *"Break this plan into tasks."* → Architect creates typed task-NNN.md files and appends the execution graph to PLAN.md
- *"The spec says use REST but the KB shows the codebase uses GraphQL."* → Architect resolves the conflict, documents the decision

## Key Behaviors

- **Grounded in KB.** Every design decision references existing architecture, not abstract best practices.
- **Specs are hypotheses.** The Architect expects specs to be revised when implementation reveals new truths.
- **Clear acceptance criteria.** Every task has measurable, testable criteria — not vague "implement feature X."
- **Scope discipline.** Pushes back on scope creep. Defers nice-to-haves to future deliveries.

## Escalation

- **Requirements ambiguous** → writes a Q&A entry to the work's `STATE.md` `## Cross-phase Q&A` section, routes to Interviewer
- **KB insufficient** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section, routes to Researcher
- **Contradictory constraints** → writes a Q&A entry to the relevant STATE file and flags it for human decision
