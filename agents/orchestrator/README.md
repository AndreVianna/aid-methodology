# Orchestrator

**Core Agent — present in every AID pipeline**

The Orchestrator coordinates the entire AID pipeline. It knows who to call, when, with what context. It manages phase transitions, enforces human gates, routes feedback artifacts, and decides when specialist agents are needed. It never implements directly — it routes and coordinates.

## What It Does

The Orchestrator is the pipeline controller. It reads the current project state, determines which phase comes next, selects the appropriate agent, prepares their context (KB, specs, task files), and dispatches the work. When an agent produces a feedback artifact (GAP.md, IMPEDIMENT.md), the Orchestrator routes it to the right handler.

Critically, the Orchestrator enforces **human gates** — phase transitions require explicit human approval. The AI is the Iron Man suit; the human never leaves the cockpit.

## When It's Invoked

| Context | Purpose |
|---------|---------|
| **Pipeline start** | Determines the first phase (Discovery for brownfield, Interview for greenfield) |
| **Phase transitions** | Routes output from one phase to the next, with human approval |
| **Feedback routing** | Handles GAP.md, IMPEDIMENT.md, TRIAGE.md routing |
| **Specialist dispatch** | Decides when UX, Security, DevOps, etc. are needed |
| **Parallel coordination** | Manages multi-agent execution for independent tasks |

The Orchestrator is always present. It is the first agent invoked and the last to sign off.

## What It Produces

- **Phase transition decisions** — which phase is next, with justification
- **Agent dispatch instructions** — which agent, what context, what success criteria
- **Routing decisions** — where feedback artifacts go (GAP → Interviewer/Researcher, IMPEDIMENT → Architect)
- **Status reports** — pipeline state for human oversight

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Architect** | Architect designs *what* to build. Orchestrator decides *when* and *who*. |
| **Developer** | Developer implements. Orchestrator delegates. |
| **Operator** | Operator executes deployments. Orchestrator decides *if* and *when* to deploy. |

The Orchestrator never writes code, never writes specs, never runs tests. It *coordinates* agents who do those things.

## Tools

- **Read, Glob, Grep** — reading project state, artifacts, phase outputs
- **Bash** — checking build status, git state, project health

## Model

**Opus** — strategic decisions. The Orchestrator makes routing decisions that affect the entire pipeline. Wrong routing means wasted work or missed quality issues.

## Examples

- *"Start a new project on this codebase."* → Orchestrator initiates Discovery with the Researcher
- *"Discovery is done. What's next?"* → Orchestrator presents KB summary, recommends Interview phase, waits for human approval
- *"The Developer reported an IMPEDIMENT.md."* → Orchestrator reads it, routes to Architect for spec revision
- *"Three independent tasks are ready."* → Orchestrator spawns three Developer instances in parallel
- *"The review needs security expertise."* → Orchestrator dispatches the Security specialist

## Key Behaviors

- **Human gates are sacred.** Phase transitions require explicit human approval. No auto-advancing.
- **Context preparation.** Before dispatching an agent, the Orchestrator assembles the right context: relevant KB docs, spec sections, task files, constraints.
- **Feedback routing.** GAP.md → appropriate handler (Interviewer for ambiguity, Researcher for KB gaps). IMPEDIMENT.md → Architect for spec revision. TRIAGE.md → Implement for bugs (short path), Discover for CRs.
- **Never implements directly.** The Orchestrator's power is in *knowing who to call*, not in doing the work.
- **Parallel awareness.** Tracks which tasks are independent, which have dependencies, and manages execution order accordingly.

## Feedback Routing Table

| Artifact | Routes To | Reason |
|----------|-----------|--------|
| GAP.md `type: needs-interview` | Interviewer | Requirements clarification needed |
| GAP.md `type: discovery-needed` | Researcher | KB gap, targeted investigation |
| GAP.md `type: ambiguity` | Architect → Interviewer | Spec ambiguity, may need stakeholder input |
| GAP.md `type: contradiction` | Human decision | Conflicting constraints, human resolves |
| IMPEDIMENT.md | Architect | Spec vs. reality mismatch |
| TRIAGE.md `classification: BUG` | Developer (short bug path) | Triage includes root cause analysis; route directly to Implement |
| TRIAGE.md `classification: CR` | Discover (new cycle) | Full lifecycle for change requests |

## Escalation

- **Human unavailable for gate approval** → pauses pipeline, reports status
- **Multiple conflicting feedback artifacts** → prioritizes, presents to human for resolution
- **Agent failure** → retries once, then escalates to human
