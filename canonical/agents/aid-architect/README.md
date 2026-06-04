> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# aid-architect

**Core Agent — present in every AID pipeline**

The Architect transforms requirements and knowledge into design output — specifications, plans, task breakdowns, and DESIGN-typed execution including UX/flow advice. It is the bridge between "what we need" and "how we'll build it."

## What It Does

The Architect reads REQUIREMENTS.md, the Knowledge Base, and any existing project context, then produces the structural artifacts that guide implementation: SPEC.md, PLAN.md, and task-NNN.md files (with an execution graph in PLAN.md). For DESIGN-typed tasks it proposes user flows, evaluates UX patterns, and advises on component structure and accessibility. It also orchestrates the aid-discover GENERATE phase by coordinating KB doc population across parallel agents.

The Architect absorbed the UX Designer role: UX/flow design is the DESIGN-typed slice of the same design-thinking responsibility, and the UX Designer was purely advisory to the Architect — folding it in eliminates a hand-off while preserving the boundary that architecture decisions rest with the Architect.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Specify** | Transforms REQUIREMENTS.md + KB into a grounded SPEC.md |
| **Plan** | Defines MVP scope, modules, deliverables, test scenarios → PLAN.md |
| **Detail** | Decomposes plan into typed task-NNN.md files and appends execution graph to PLAN.md |
| **Discover** | Orchestrates GENERATE phase; coordinates KB doc population |
| **Execute** | Executes DESIGN-typed tasks (UX flows, component structure, accessibility review) |
| **Housekeep** | Applies KB-DELTA updates when KB docs need structural amendments |
| **Interview** | Produces TASK-BREAKDOWN and FEATURE-DECOMPOSITION outputs from interview-phase input |

## What It Produces

- **SPEC.md** — formal specification grounded in KB reality
- **PLAN.md** — strategic roadmap: MVP scope, modules, delivery order, test scenarios, execution graph
- **task-NNN.md** — individual task files with typed work, acceptance criteria, and KB references
- **DESIGN task output** — structured proposals for user flows, component patterns, accessibility evaluations

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-researcher** | Researcher catalogues *what exists*. Architect decides *what to build*. |
| **aid-developer** | Developer *implements* the design. Architect *creates* the design. |
| **aid-reviewer** | Reviewer evaluates *after the fact*. Architect designs *before the fact*. |
| **aid-interviewer** | Interviewer captures *what stakeholders want*. Architect decides *how to satisfy it*. |

## Tools

- **Read, Glob, Grep** — consuming KB, requirements, existing code structure
- **Write, Edit** — producing specs, plans, and task files
- **Bash** — exploring project structure, running analysis commands

## Tier

**Large tier** — design reasoning that cascades through the entire project. Trade-off analysis, pattern selection, and scope management require deep reasoning that downstream phases cannot easily correct.

## Examples

- *"REQUIREMENTS.md is complete. Create the spec."* → Architect produces SPEC.md grounded in KB
- *"We need to plan the MVP."* → Architect defines modules, delivery order, test scenarios
- *"Break this plan into tasks."* → Architect creates typed task-NNN.md files and appends execution graph to PLAN.md
- *"DESIGN task: design the onboarding flow."* → Architect proposes user flow with rationale and trade-offs

## Key Behaviors

- **Grounded in KB.** Every design decision references existing architecture, not abstract best practices.
- **Specs are hypotheses.** Expects specs to be revised when implementation reveals new truths.
- **Clear acceptance criteria.** Every task has measurable, testable criteria.
- **Scope discipline.** Pushes back on scope creep; defers nice-to-haves to future deliveries.
- **UX is advisory.** Design proposals include a recommended option with rationale; final decisions are documented in the task or spec.

## Escalation

- **Requirements ambiguous** → writes a Q&A entry to the work's `STATE.md` `## Cross-phase Q&A` section
- **KB insufficient** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section
- **Contradictory constraints** → writes a Q&A entry to the relevant STATE file and flags for human decision
