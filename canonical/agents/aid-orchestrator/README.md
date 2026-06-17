> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-orchestrator

**Core Agent — present in every AID pipeline**

The Orchestrator coordinates the AID pipeline: routes work to agents, manages phase transitions with human gates, handles feedback artifacts, and dispatches with context. It never produces primary artifacts — it decides who does.

## What It Does

The Orchestrator reads pipeline state (STATE files, IMPEDIMENT.md, MONITOR-STATE artifacts), determines the next action, prepares context for the target agent, and dispatches. It enforces the human-gate rule at every phase boundary: no phase advances without explicit human approval. In the monitor cycle it interprets pipeline findings and routes them to the appropriate remediation path.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Monitor** | ROUTE state: interprets findings, decides next action, dispatches with context |

The Orchestrator is the default executor for the **aid-monitor** skill. Note: in all other skills "the orchestrator" in prose refers to the coordinating *skill* itself, not this agent — only `aid-monitor ROUTE` dispatches the Orchestrator agent.

## What It Produces

- **Phase transition recommendations** with justification
- **Agent dispatch instructions** — who, what context, success criteria
- **Pipeline status reports** for human oversight

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **All other agents** | Every other agent produces a primary artifact (code, spec, KB doc, review ledger). The Orchestrator routes and coordinates; it never produces primary content. |

## Feedback Routing

| Feedback signal | Routes To |
|-----------------|-----------|
| Q&A entry (requirements-tagged) | aid-interviewer |
| Q&A entry in knowledge STATE | aid-researcher |
| Q&A entry (spec-tagged) | aid-architect |
| IMPEDIMENT.md | aid-architect |
| Monitor BUG | aid-developer |
| Monitor CR | aid-discover (new cycle) |

## Tools

- **Read, Glob, Grep** — reading state files, IMPEDIMENT.md, monitor artifacts
- **Bash** — checking pipeline state, running status commands

## Tier

**Medium tier** — routing decisions require judgment but not deep reasoning. The Orchestrator's skill is in reading pipeline state correctly and dispatching with the right context, not in solving the problems it routes.

## Examples

- *"Monitor cycle found a regression."* → Orchestrator classifies as BUG, prepares root-cause context, dispatches Developer
- *"IMPEDIMENT.md raised by Developer."* → Orchestrator routes to Architect with the IMPEDIMENT as context
- *"Interview phase complete."* → Orchestrator surfaces the human gate, waits for approval, then dispatches Architect

## Key Behaviors

- **Human gates are sacred.** No phase advances without explicit human approval. Pauses cleanly if the human is unavailable.
- **Context preparation.** Never dispatches without assembling the relevant KB docs, spec sections, and task files.
- **Never implements directly.** Its power is knowing who to call.

## Escalation

- **Human unavailable** → pauses, reports status
- **Conflicting feedback artifacts** → prioritizes, presents to human
- **Agent failure** → retries once, then escalates to human
