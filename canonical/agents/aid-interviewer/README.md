> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`AGENT.md`](AGENT.md) in this folder.

# aid-interviewer

**Core Agent — present in every AID pipeline**

The Interviewer conducts adaptive one-question-at-a-time stakeholder dialogue to capture requirements. It is the only agent that talks to humans about what they want — every other agent works with artifacts the interview produced.

## What It Does

The Interviewer is the conversational requirements specialist. It reads the Knowledge Base (when available) to pre-fill technical context, then engages the stakeholder in an adaptive dialogue — one question at a time, tailored to their previous answers. It tracks a three-state knowledge model (KNOWN / UNKNOWN / ASSUMED) and surfaces all assumptions for explicit confirmation.

The result is a structured REQUIREMENTS.md that the Architect can immediately use to produce a grounded SPEC.md.

## When It's Invoked

| Phase | Purpose |
|-------|---------|
| **Interview** | Initial requirements gathering: FIRST-RUN, TRIAGE, CONDENSED-INTAKE, Q-AND-A, CONTINUE, COMPLETION states |
| **Specify / Detail** | Clarification of specific ambiguities surfaced by Q&A entries in the work STATE file |

Typically invoked by the **aid-describe** skill. May be re-invoked when downstream phases surface gaps that require stakeholder input.

## What It Produces

- **REQUIREMENTS.md** — structured functional, non-functional, and constraint requirements, tagged STATED / INFERRED / ASSUMED per item
- **Q&A clarifications** — targeted answers to specific ambiguity entries in the work STATE file

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **aid-architect** | Interviewer captures what stakeholders want. Architect decides how to build it. |
| **aid-researcher** | Researcher investigates code and docs. Interviewer talks to humans. |
| **aid-reviewer** | Reviewer grades artifacts. Interviewer gathers requirements. |

## Tools

- **Read, Glob, Grep** — reading KB docs and existing REQUIREMENTS.md for context
- **Bash** — read-only exploration (project structure, existing requirements)
- No Write or Edit — the Interviewer does not produce files directly; it returns to the skill, which writes the REQUIREMENTS.md

## Tier

**Large tier** — open-ended multi-turn elicitation requires deep reasoning to adapt questions based on evolving context, surface implicit assumptions, and recognize when a stakeholder's stated desire contradicts earlier statements. Conversational reasoning across many turns is the most context-intensive mode in the pipeline.

## Examples

- *"Start a new interview for a brownfield project."* → Interviewer pre-fills technical context from KB, conducts focused business-requirements dialogue
- *"The Architect flagged OQ-7: unclear non-functional requirements for latency."* → Interviewer asks one targeted question to resolve OQ-7
- *"TRIAGE: categorize an incoming change request."* → Interviewer asks one question to classify the request type

## Key Behaviors

- **One question per turn.** Always. No bullet lists of questions, no "and also…".
- **Knowledge-model discipline.** Explicitly distinguishes what it knows, what it assumed, and what it still needs to ask.
- **Empathetic pacing.** Adapts tone and depth to the stakeholder's familiarity with the domain.
- **Assumption surfacing.** Every inference must be confirmed explicitly before REQUIREMENTS.md is finalized.

## Escalation

- **Stakeholder unavailable** → reports to Orchestrator, pauses the interview state
- **Contradictory requirements** → flags both versions, asks stakeholder to resolve explicitly
- **Scope creep** → redirects gently, documents the broader wish for a future delivery
- **Technical question beyond requirements** → writes a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section
