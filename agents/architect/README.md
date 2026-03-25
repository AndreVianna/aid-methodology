# Architect

**Core Agent — present in every AID pipeline**

The Architect transforms understanding into structure. It takes requirements and knowledge and produces designs — specifications, plans, task decompositions. It is the bridge between "what we need" and "how we'll build it."

## What It Does

The Architect is the design-thinking specialist. It reads REQUIREMENTS.md, the Knowledge Base, and any existing project context, then produces the structural artifacts that guide implementation: SPEC.md, PLAN.md, DETAIL.md, and TASK files.

The Architect doesn't write code and doesn't evaluate code. It *designs* — choosing patterns, defining interfaces, scoping deliverables, decomposing work into executable tasks with clear acceptance criteria.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Specify** | Transforms REQUIREMENTS.md + KB into a grounded SPEC.md |
| **Plan** | Defines MVP scope, modules, deliverables, test scenarios → PLAN.md |
| **Detail** | Decomposes plan into user stories, tasks, precedence order → DETAIL.md + TASK files |

Typically invoked by the **Orchestrator** after the Interview phase completes. May be re-invoked when GAP.md artifacts trigger re-specification or re-planning.

## What It Produces

- **SPEC.md** — formal specification grounded in KB reality, not generic templates
- **PLAN.md** — strategic roadmap: MVP scope, modules, delivery order, test scenarios
- **DETAIL.md** — tactical breakdown: user stories, task list, precedence graph, delivery groupings
- **task-{id}.md** — individual task files with acceptance criteria, relevant KB references, and constraints

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Researcher** | Researcher discovers *what exists*. Architect decides *what to build*. |
| **Developer** | Developer *implements* the design. Architect *creates* the design. |
| **Critic** | Critic evaluates *after the fact*. Architect designs *before the fact*. |

The Architect's output is the contract that the Developer follows and the Critic reviews against. Bad architecture means bad everything downstream.

## Tools

- **Read, Glob, Grep** — for consuming KB, requirements, existing code structure
- **Write, Edit** — for producing specs, plans, and task files
- **Bash** — for exploring project structure, running analysis commands

## Model

**Opus** — complex reasoning. The Architect makes decisions that cascade through the entire project. Trade-off analysis, pattern selection, and scope management require deep thinking.

## Examples

- *"REQUIREMENTS.md is complete. Create the spec."* → Architect produces SPEC.md grounded in KB
- *"We need to plan the MVP."* → Architect defines modules, delivery order, test scenarios
- *"Break this plan into tasks."* → Architect creates DETAIL.md with user stories and TASK files
- *"The spec says use REST but the KB shows the codebase uses GraphQL."* → Architect resolves the conflict, documents the decision

## Key Behaviors

- **Grounded in KB.** Every design decision references existing architecture, not abstract best practices.
- **Specs are hypotheses.** The Architect expects specs to be revised when implementation reveals new truths.
- **Clear acceptance criteria.** Every task has measurable, testable criteria — not vague "implement feature X."
- **Scope discipline.** Pushes back on scope creep. Defers nice-to-haves to future deliveries.

## Escalation

- **Requirements ambiguous** → creates GAP.md with `type: ambiguity`, routes to Interviewer
- **KB insufficient** → creates GAP.md with `type: discovery-needed`, routes to Researcher
- **Contradictory constraints** → creates GAP.md with `type: contradiction`, flags for human decision
