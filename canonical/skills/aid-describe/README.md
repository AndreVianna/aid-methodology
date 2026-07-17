> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# Conversational Requirements Gathering

Gather and validate requirements through adaptive conversation with a human stakeholder. Produces an approved REQUIREMENTS.md ready for feature decomposition by `/aid-define`.

## Core Principle

**One question at a time.** Humans think better with focused prompts. Each answer shapes the next question. Nothing gets assumed silently — if KB has an answer, present it for confirmation. If the stakeholder didn't say it, we don't spec it.

## Workspace

Each interview creates a *work* — a self-contained unit of scope:

```
.aid/
  knowledge/                    <- shared KB (from Discovery)
  works/
    work-NNN-{name}/              <- one work per interview
      work `STATE.md` `## Interview State`           <- process (section status, Q&A, grade, review history)
      REQUIREMENTS.md             <- product (stakeholder requirements)
      features/
        feature-NNN-{name}/
          SPEC.md                 <- requirements side (from Interview) + tech spec (from Specify)
```

Multiple works can coexist — a client requests auth now, reporting later. Each work has its own requirements and features, sharing the same KB.

## When to Use

- **New work:** No works exist or user wants a new one. Creates `work-001-{name}/`.
- **Continue existing:** Incomplete work in progress. Resumes where it left off.
- **Targeted re-interview:** A Q&A entry from a downstream phase (Specify, Plan) needs stakeholder input.

After requirements are approved, run `/aid-define {work}` to decompose into features.

## Inputs

- `.aid/knowledge/` directory (if brownfield — pre-fills technical fields and informs questions).
- Project description or brief (if greenfield).
- For targeted interview: Q&A entries in work `STATE.md` `## Interview State` from downstream phases.

## REQUIREMENTS.md Structure

10 sections plus a mandatory Change Log:

1. **Objective** — What are we building and why? In the stakeholder's words.
2. **Problem Statement** — What problem does this solve? What's the current pain?
3. **Users & Stakeholders** — Who uses this? Who cares about the outcome?
4. **Scope** — What's In Scope and what's explicitly Out of Scope.
5. **Functional Requirements** — What the system must do. Specific enough to implement.
6. **Non-Functional Requirements** — Performance, security, reliability, scalability. Measurable.
7. **Constraints** — Timeline, budget, team, compliance, technical limitations.
8. **Assumptions & Dependencies** — What we're assuming. External dependencies.
9. **Acceptance Criteria** — How do we know it's done? Testable conditions.
10. **Priority** — Feature/requirement priority ordering. Must/Should/Could or numbered.

## The States

### States 1–4: Conversational Interview

Walk through the 10 sections organically — start broad (Objective, Problem Statement), get specific (Constraints, Acceptance Criteria). Each answer shapes the next question.

**Opening (Sections 1–3):** Establish context and users.
- "What are we building, and why now?"
- "What problem does this solve? What's the current pain?"
- "Who are the users? Walk me through who interacts with this."

**Scoping (Sections 4–6):** Define boundaries and capabilities.
- "What's the most important thing this system must do?"
- "What's explicitly NOT part of this project?"
- "Any performance or security targets?"

**Completion (Sections 7–10):** Practical limits and success criteria.
- "Timeline — hard deadline or preferred pace?"
- "How do we know this is done? What does success look like?"
- "What's most important to ship first?"

**KB-Informed Questions:** When the KB already has an answer, present it with source for confirmation:
```
Our codebase analysis found you're using PostgreSQL 16 with 3 REST API integrations.
[From: .aid/knowledge/technology-stack.md]

[1] Accept  [2] Skip  [3] Custom answer
```

Never silently infer. The stakeholder must confirm, skip, or override every KB-derived answer.

**Approval Gate:** After all sections are addressed, present a structured summary. Only finalize REQUIREMENTS.md after explicit approval. On approval, run `/aid-define {work}` to decompose into features.

## Interview Behaviors

### Adaptive Questioning

Each answer may:
- **Answer the question** → mark section addressed, move to next gap.
- **Reveal something unexpected** → add follow-up questions, adjust direction.
- **Contradict the KB** → flag the contradiction, trigger targeted discovery.
- **Be vague** → ask a follow-up. Don't accept "it depends" without knowing what it depends on.

### Tone

Conversational, not interrogative. Show understanding: "Got it — so the core problem is X, and you need Y to solve it." Ask naturally: "When you say 'reports,' what does that look like? PDF? Dashboard? Email?"

### Question Design Principles

- Open questions early → specific questions later.
- One question at a time.
- Don't ask what the KB already answered without presenting the KB answer.
- Don't assume requirements the stakeholder didn't state.
- Don't use jargon the stakeholder hasn't used.
- Don't make it feel like a form. Make it feel like a conversation.

### Downstream Loopback

Downstream phases (Specify, Plan, Detail) can inject Q&A entries into work `STATE.md` `## Interview State`'s `## Pending Q&A`. The next `/aid-describe` run picks these up — in Q&A state if requirements are already approved, or woven into the ongoing interview if still in progress.

## Brownfield vs Greenfield

- **Greenfield interviews are longer** — everything starts unknown.
- **Brownfield interviews are shorter** — KB pre-fills technical context. Many questions become confirmations.
- **Returning works** can reuse prior REQUIREMENTS.md — run `/aid-define {work}` for cross-reference validation.

## Output

- `.aid/works/{work}/REQUIREMENTS.md` — structured requirements with Change Log, 10 sections.
- `.aid/works/{work}/work `STATE.md` `## Interview State`` — process tracking (section status, Q&A, grade, review history).

Hand-off: run `/aid-define {work}` after requirements are approved.

## Feedback Loops

### → Discovery

An answer reveals the KB is wrong or incomplete. Pause, trigger targeted discovery, resume with corrected understanding.

### ← Specify / Plan / Detail

Downstream phases find requirements are wrong, incomplete, or contradictory. They write Q&A entries to work `STATE.md` `## Interview State`. Next `/aid-describe` run picks them up.

## Quality Checklist

- [ ] All 10 sections addressed (or explicitly N/A).
- [ ] Change Log has an entry for every modification.
- [ ] Objective and Problem Statement use stakeholder language, not jargon.
- [ ] Scope has both In Scope and Out of Scope.
- [ ] Assumptions are explicit — nothing silently inferred.
- [ ] Technical context consistent with KB (if brownfield).
- [ ] Every KB-suggested answer was confirmed, skipped, or overridden.
- [ ] Acceptance Criteria are testable.
- [ ] Priority ordering is clear.
- [ ] Approval gate passed (State 4).

## Related Phases

- **Previous:** [Discover](../aid-discover/) — provides KB context that shortens the interview
- **Next:** [Define](../aid-define/) — decomposes approved requirements into features
- **Triggered by:** Q&A entries from Specify, Plan, or Detail

## See Also

- [AID Methodology](../../docs/aid-methodology.md) — The complete methodology.
