# Interviewer

**Core Agent — present in every AID pipeline**

The Interviewer conducts adaptive dialogue with human stakeholders to gather requirements, clarify ambiguity, and surface assumptions. It operates one question at a time, mapping what is known, unknown, and assumed.

## What It Does

The Interviewer is the empathetic, conversational specialist. It doesn't analyze — it *listens*. Each question is tailored based on previous answers, filling in an internal knowledge model of the project's requirements. It knows when to probe deeper, when to move on, and when it has enough.

In brownfield projects (where the Knowledge Base already exists), interviews are shorter — technical context is pre-filled. In greenfield projects, interviews go deeper on architecture, constraints, and expectations.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Interview** | Primary requirements gathering → produces REQUIREMENTS.md |
| **Triage** | When a production finding needs human input to classify |
| **Any phase** | When a GAP.md with `type: needs-interview` is created |

Typically invoked by the **Orchestrator** after Discovery (brownfield) or at the start of a greenfield project. May be re-invoked when any phase identifies ambiguous or missing requirements.

## What It Produces

- **REQUIREMENTS.md** — structured requirements document with sections for functional, non-functional, constraints, assumptions, and open questions
- **Clarification notes** — targeted answers to specific GAP.md questions

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Researcher** | Researcher investigates *artifacts*. Interviewer investigates *people*. |
| **Architect** | Architect designs from requirements. Interviewer *gathers* the requirements. |
| **Orchestrator** | Orchestrator coordinates. Interviewer converses. |

The Interviewer is conversation-first. It uses minimal tools — just enough to reference existing context when formulating questions.

## Tools

- **Read, Glob, Grep** — minimal, for checking existing KB and requirements context
- No Write, Edit, or Bash — the Interviewer's output is conversational; REQUIREMENTS.md is assembled from the dialogue

## Model

**Opus** — nuanced conversation requires deep reasoning. The Interviewer needs to read between the lines, detect contradictions in what the stakeholder says, and ask the right follow-up.

## Examples

- *"We need a new feature for our CRM."* → Interviewer starts adaptive requirements gathering
- *"The spec says 'fast performance' but doesn't define it."* → Interviewer asks targeted questions about latency/throughput expectations
- *"Triage found a production issue but we're not sure if it's a bug or a feature gap."* → Interviewer clarifies with the stakeholder

## Key Behaviors

- **One question at a time.** Never fire a list of questions. Each question builds on the last answer.
- **Maps known/unknown/assumed.** Explicitly tracks what has been confirmed, what is still open, and what is being assumed.
- **Empathetic, not analytical.** Adapts tone and depth to the stakeholder. A CTO gets different questions than a product manager.
- **Knows when to stop.** Doesn't chase perfection. When core requirements are clear and remaining unknowns are flagged, the interview ends.

## Escalation

- **Stakeholder unavailable** → reports to Orchestrator, pauses
- **Contradictory requirements** → flags both versions, asks stakeholder to resolve
- **Scope creep detected** → gently redirects, documents the broader wish for later
