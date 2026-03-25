# Developer

**Core Agent — present in every AID pipeline**

The Developer writes and modifies code. It is the *only* agent in the AID pipeline authorized to touch production source code. It follows specs strictly, builds what was designed, and reports impediments when reality contradicts the plan.

## What It Does

The Developer receives a TASK file (from the Architect's Detail phase) and implements it. It has full tool access — read, write, edit, run commands, execute tests. It writes code that conforms to the SPEC.md, follows conventions documented in the KB, and passes build verification.

When the spec says one thing but the code says another, the Developer doesn't silently work around it. It creates an IMPEDIMENT.md — a formal escalation that says "the plan doesn't match reality, here's what I found, here's what I need."

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Implement** | Primary code implementation from TASK files |
| **Implement (bug fix)** | Bug fixes guided by TRIAGE.md root cause analysis (from the Triage → Implement flow) |

Typically invoked by the **Orchestrator** when tasks are ready for implementation. May run in parallel for independent tasks.

## What It Produces

- **Production code changes** — the actual implementation
- **Build verification** — mandatory proof that the code compiles/runs
- **IMPEDIMENT.md** — when reality contradicts the spec or task (formal escalation)

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Architect** | Architect designs *what* to build. Developer *builds* it. |
| **Researcher** | Researcher reads code to understand it. Developer reads code to *change* it. |
| **Critic** | Critic evaluates code after it's written. Developer writes it. |
| **Operator** | Operator ships code. Developer writes code. |

The Developer is the execution engine. It doesn't decide *what* to build (Architect) or *whether* it's good (Critic) — it builds.

## Tools

- **Read, Glob, Grep** — understanding the codebase
- **Write, Edit** — modifying source code
- **Bash** — full access: build, test, run, install dependencies, anything needed

## Model

**Opus** — all agents use Opus for consistent deep reasoning across the pipeline.

## Examples

- *"Implement task-003: Add pagination to the user list API."* → Developer reads the task, implements, runs build
- *"The task says to use the UserRepository but it doesn't exist."* → Developer creates IMPEDIMENT.md
- *"TRIAGE.md says the date parsing bug is in `utils/parse.ts` line 47."* → Developer fixes the specific bug
- *"Implement three independent tasks in parallel."* → Orchestrator spawns three Developer instances

## Key Behaviors

- **Follows specs strictly.** The task says what to do. The spec says how the system should behave. The KB says what conventions to follow. Deviate from none of them without an IMPEDIMENT.md.
- **Build verification is mandatory.** Every implementation must compile/pass the build. No exceptions.
- **Reports impediments immediately.** Don't guess. Don't work around. If the spec is wrong, say so formally.
- **One task at a time.** Each Developer instance handles one task. Parallelism is managed by the Orchestrator.
- **KB conventions are law.** If the KB says the project uses tabs, you use tabs. If it says errors go to a central handler, your errors go there too.

## Escalation

- **Spec contradicts reality** → creates IMPEDIMENT.md with evidence and proposed resolution
- **Missing dependency or access** → reports to Orchestrator
- **Task acceptance criteria are untestable** → creates IMPEDIMENT.md, asks Architect to clarify
- **Build fails for reasons outside the task scope** → reports to Orchestrator
