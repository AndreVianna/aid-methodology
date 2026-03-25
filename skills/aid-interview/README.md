# Adaptive Requirements Gathering

Gather and validate requirements through adaptive conversation with a human stakeholder. Decompose approved requirements into features. Produces REQUIREMENTS.md and per-feature SPEC.md stubs.

## Core Principle

**One question at a time.** Humans think better with focused prompts. Each answer shapes the next question. Nothing gets assumed silently — if KB has an answer, present it for confirmation. If the stakeholder didn't say it, we don't spec it.

## Workspace

Each interview creates a *work* — a self-contained unit of scope:

```
.aid/
  knowledge/                    ← shared KB (from Discovery)
  work-NNN-{name}/              ← one work per interview
    INTERVIEW-STATE.md          ← process (section status, Q&A, grade, review history)
    REQUIREMENTS.md             ← product (stakeholder requirements)
    features/
      feature-NNN-{name}/
        SPEC.md                 ← requirements side (from Interview) + tech spec (from Specify)
```

Multiple works can coexist — a client requests auth now, reporting later. Each work has its own requirements and features, sharing the same KB.

## When to Use

- **New work:** No works exist or user wants a new one. Creates `work-001-{name}/`.
- **Continue existing:** Incomplete work in progress. Resumes where it left off.
- **Cross-reference:** REQUIREMENTS.md exists and is approved. Validates against current KB.
- **Targeted re-interview:** A Q&A entry from a downstream phase (Specify, Plan) needs stakeholder input.

## Inputs

- `.aid/knowledge/` directory (if brownfield — pre-fills technical fields and informs questions).
- Project description or brief (if greenfield).
- For targeted interview: Q&A entries in INTERVIEW-STATE.md from downstream phases.
- For cross-reference: existing REQUIREMENTS.md + full KB.

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

## The Six States

The interview skill advances one state per run:

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

**Approval Gate:** After all sections are addressed, present a structured summary. Only finalize REQUIREMENTS.md after explicit approval.

### State 5: Feature Decomposition

After REQUIREMENTS.md is approved, the agent proposes a feature breakdown from §5 Functional Requirements:

1. Analyze functional requirements for natural feature boundaries.
2. Propose a feature list with names, descriptions, and priorities (Must/Should/Could).
3. User approves, adjusts, or adds features.
4. For each approved feature, create a folder (`feature-NNN-{name}/`) with SPEC.md containing:
   - Description (stakeholder perspective)
   - User stories
   - Priority
   - Acceptance criteria
   - Source references to REQUIREMENTS.md sections
   - Empty `## Technical Specification` section (Specify fills this)

### State 6: Cross-Reference

Validates REQUIREMENTS.md against the full KB and codebase:

| Grade | Questions | Meaning |
|-------|-----------|---------|
| A | 0 | Fully consistent, no questions |
| B | 1–3 | Small gaps or minor inconsistencies |
| C | 4–7 | Significant gaps need attention |
| D | 8+ | Serious problems, major rework |

The grade is a snapshot at run start — does NOT change after answering questions. Run again for updated grade.

Questions are presented one at a time. Answers update REQUIREMENTS.md immediately with Change Log entries.

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

Downstream phases (Specify, Plan, Detail) can inject Q&A entries into INTERVIEW-STATE.md's `## Pending Q&A`. The next Interview run picks these up — in Q&A state if requirements are already approved, or woven into the ongoing interview if still in progress.

## Brownfield vs Greenfield

- **Greenfield interviews are longer** — everything starts unknown.
- **Brownfield interviews are shorter** — KB pre-fills technical context. Many questions become confirmations.
- **Returning works** can reuse prior REQUIREMENTS.md — cross-reference validates against current KB.

## Output

- `.aid/{work}/REQUIREMENTS.md` — structured requirements with Change Log, 10 sections.
- `.aid/{work}/INTERVIEW-STATE.md` — process tracking (section status, Q&A, grade, review history).
- `.aid/{work}/features/feature-NNN-{name}/SPEC.md` — per-feature requirements side (description, user stories, priority, acceptance criteria).

## Feedback Loops

### → Discovery

An answer reveals the KB is wrong or incomplete. Pause, trigger targeted discovery, resume with corrected understanding.

### ← Specify / Plan / Detail

Downstream phases find requirements are wrong, incomplete, or contradictory. They write Q&A entries to INTERVIEW-STATE.md. Next Interview run picks them up.

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
- [ ] Features decomposed from approved requirements (State 5).
- [ ] Approval gate passed (State 4) or grade assigned (State 6).

## Related Phases

- **Previous:** [Discover](../aid-discover/) — provides KB context that shortens the interview
- **Next:** [Specify](../aid-specify/) — technical refinement per feature
- **Triggered by:** Q&A entries from Specify, Plan, or Detail

## See Also

- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
