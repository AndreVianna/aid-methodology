# Adaptive Requirements Gathering

Gather and validate requirements through adaptive conversation with a human stakeholder. Produces a structured REQUIREMENTS.md in `knowledge/`.

## Core Principle

**One question at a time.** Humans think better with focused prompts. Each answer shapes the next question. Nothing gets assumed silently — if KB has an answer, present it for confirmation. If the stakeholder didn't say it, we don't spec it.

## Two Flows

The interview skill operates in two distinct modes depending on whether REQUIREMENTS.md already exists:

### Flow 1: Initial Interview (No REQUIREMENTS.md)

Full conversational interview. Walk through all 10 sections one question at a time. End with an approval gate.

### Flow 2: Cross-Reference (REQUIREMENTS.md exists)

Cross-reference existing REQUIREMENTS.md against the full Knowledge Base and codebase. Look for:
- **Contradictions** — requirements that conflict with what the code actually does
- **Gaps** — sections marked *(pending)* or too vague to implement
- **Missing evidence** — requirements that reference things not found in KB
- **Staleness** — requirements overtaken by implementation changes

Produce a grade and targeted questions. Update REQUIREMENTS.md with answers.

## When to Use

- **Initial interview:** New project. No REQUIREMENTS.md exists in `knowledge/`.
- **Cross-reference:** REQUIREMENTS.md exists. Run again to validate against current KB.
- **Targeted interview:** A GAP.md from aid-plan, aid-detail, or aid-specify identifies a `needs-interview` requirement gap. Ask only about the specific gap.

## Inputs

- `knowledge/` directory (if brownfield — pre-fills technical fields and informs questions).
- Project description or brief (if greenfield).
- For targeted interview: the GAP.md that triggered re-entry.
- For cross-reference: existing `knowledge/REQUIREMENTS.md` + full KB.

## REQUIREMENTS.md Structure

The output is a first-class methodology artifact saved as `knowledge/REQUIREMENTS.md` (uppercase). It contains 10 sections plus a mandatory Change Log:

### Change Log
Every modification to REQUIREMENTS.md gets an entry — initial creation, cross-reference updates, targeted re-interviews. Tracked with Date, Change, and Source columns.

### The 10 Sections

1. **Objective** — What are we building and why? In the stakeholder's words.
2. **Problem Statement** — What problem does this solve? What's the current pain?
3. **Users & Stakeholders** — Who uses this? Who cares about the outcome?
4. **Scope** — What's In Scope and what's explicitly Out of Scope.
5. **Functional Requirements** — What the system must do. Specific enough to implement.
6. **Non-Functional Requirements** — Performance, security, reliability, scalability. Measurable where possible.
7. **Constraints** — Timeline, budget, team, compliance, technical limitations.
8. **Assumptions & Dependencies** — What we're assuming to be true. External dependencies.
9. **Acceptance Criteria** — How do we know it's done? Testable conditions.
10. **Priority** — Feature/requirement priority ordering. Must/Should/Could or numbered.

## Interview Protocol (Flow 1)

The interview is adaptive, not rigidly phased. Move through the 10 sections organically based on the stakeholder's answers. Start broad (Objective, Problem Statement) and get specific (Constraints, Acceptance Criteria) as understanding builds.

### Opening Questions (Sections 1-3)

Establish context and users.

Example questions (adapt to context):
- "What are we building, and why now?"
- "What problem does this solve? What's the current pain?"
- "Who are the users? Walk me through who interacts with this."

Goal: Populate Objective, Problem Statement, and Users & Stakeholders.

### Scoping and Features (Sections 4-6)

Define boundaries and what the system does.

Example questions:
- "What's the most important thing this system must do?"
- "What's explicitly NOT part of this project?"
- "Any performance or security targets? Response times, uptime, data sensitivity?"

**Brownfield shortcut:** If KB exists, present what was discovered and ask for confirmation: "Our analysis shows you're using PostgreSQL 14 with Redis caching. Is that current?" This replaces multiple questions with one confirmation.

Goal: Populate Scope, Functional Requirements, and Non-Functional Requirements.

### Constraints and Completion (Sections 7-10)

Practical limits and success criteria.

Example questions:
- "Timeline — hard deadline or preferred pace?"
- "Budget range — fixed price, hourly, or range?"
- "How do we know this is done? What does success look like?"
- "What's most important to ship first?"

Goal: Populate Constraints, Assumptions & Dependencies, Acceptance Criteria, and Priority.

### KB-Informed Questions

When the Knowledge Base already has an answer to a question, **still ask it** — but present the suggested answer with its source:

```
Our codebase analysis found you're using PostgreSQL 16 with 3 REST API integrations.
[From: knowledge/technology-stack.md]

[1] Accept  [2] Skip  [3] Custom answer
```

**Never silently infer.** The stakeholder must confirm, skip, or override every KB-derived answer. This prevents stale or incorrect KB data from contaminating requirements.

### Approval Gate

After all 10 sections have been addressed, present a structured summary of the full REQUIREMENTS.md and ask:

```
[1] Approved — requirements are complete
[2] Additional consideration — I want to revisit something
```

Only finalize REQUIREMENTS.md after explicit approval.

## Cross-Reference Protocol (Flow 2)

### Grading System

On each cross-reference run, grade the REQUIREMENTS.md at the start:

| Grade | Questions | Meaning |
|-------|-----------|---------|
| A | 0 | Fully consistent with KB, no questions |
| B | 1-3 | Small gaps or minor inconsistencies |
| C | 4-7 | Significant gaps need attention |
| D | 8+ | Serious problems, major rework needed |

**The grade is a snapshot at run start.** Never re-grade after answering questions within the same run. The stakeholder runs the interview again to get an updated grade. This keeps grading honest — you see progress between runs, not within them.

### Cross-Reference Process

1. Read all `knowledge/` documents and scan the codebase.
2. Compare each REQUIREMENTS.md section against KB evidence.
3. Identify contradictions, gaps, missing evidence, and staleness.
4. Present the grade and list all questions.
5. Walk through questions one at a time (same adaptive style as initial interview).
6. Update REQUIREMENTS.md with answers.
7. Add entries to the Change Log with source `/aid-interview (cross-reference)`.

## Interview Behaviors

### Adaptive Questioning

Each answer may:
- **Answer the question** → mark section as addressed, move to next gap.
- **Reveal something unexpected** → add follow-up questions, adjust direction.
- **Contradict the KB** → flag the contradiction, trigger aid-discover for targeted update.
- **Be vague** → ask a follow-up to sharpen the answer. Don't accept "it depends" without knowing what it depends on.

### Tone

- Conversational, not interrogative. You're learning about their business, not deposing a witness.
- Show understanding: "Got it — so the core problem is X, and you need Y to solve it."
- Ask clarifying questions naturally: "When you say 'reports,' what does that look like? PDF? Dashboard? Email?"

### Question Design Principles

- Open questions early → specific questions later.
- Don't dump multiple questions at once. One at a time.
- Don't ask what the KB already answered without presenting the KB answer.
- Don't assume requirements the stakeholder didn't state.
- Don't use jargon the stakeholder hasn't used.
- Don't make it feel like a form. Make it feel like a conversation.

## Brownfield vs Greenfield

- **Greenfield interviews are longer** — everything starts unknown. All 10 sections need full exploration.
- **Brownfield interviews are shorter** — KB pre-fills technical context. Many questions become confirmations via the KB-informed question pattern.
- **Returning projects** can reuse prior REQUIREMENTS.md — the cross-reference flow validates it against current KB state.

## Feedback to Discovery

**Trigger:** An answer reveals the KB is wrong or incomplete.

**Protocol:**
1. Note the discrepancy: "You mentioned Redis caching, but our codebase analysis didn't find it."
2. Pause the interview.
3. Trigger targeted aid-discover on the specific area.
4. KB updated → interview resumes with corrected understanding → better questions from here.

## Targeted Interview (Re-entry)

When triggered by a GAP.md with `needs-interview`:

1. Read the GAP.md to understand exactly what information is missing.
2. Ask only about the specific gap — don't redo the full interview.
3. Update REQUIREMENTS.md with the new information.
4. Add a Change Log entry with source and reason.
5. Report completion to the calling phase so it can resume.

## Quality Checklist

- [ ] All 10 sections addressed (or explicitly marked N/A).
- [ ] Change Log has an entry for every modification.
- [ ] Objective and Problem Statement use the stakeholder's language, not technical jargon.
- [ ] Scope has both In Scope and Out of Scope defined.
- [ ] Assumptions are explicit — nothing is silently inferred.
- [ ] Technical context is consistent with KB (if brownfield).
- [ ] Every KB-suggested answer was explicitly confirmed, skipped, or overridden by the stakeholder.
- [ ] Acceptance Criteria are testable, not vague.
- [ ] Priority ordering is clear — Must/Should/Could or numbered.
- [ ] Approval gate was passed (Flow 1) or grade was assigned (Flow 2).

## Why This Phase Exists

Requirements don't exist until someone asks the right questions. Dumping a questionnaire on a stakeholder produces checkbox answers. Adaptive, one-question-at-a-time dialogue produces understanding — the kind that catches contradictions, surfaces unstated assumptions, and distinguishes "must have" from "nice to have."

For brownfield projects, the KB pre-fills technical context, so the interview focuses on business intent rather than wasting time on questions the code already answers. The cross-reference flow catches drift — when requirements and implementation diverge over time.

## Related Phases

- **Previous:** [Discover](../aid-discover/) — provides KB context that shortens the interview
- **Next:** [Specify](../aid-specify/) — transforms REQUIREMENTS.md into a formal spec
- **Triggered by:** GAP.md with `needs-interview` from any downstream phase

## See Also

- [Requirements Template](../../templates/requirements/requirements-template.md) — REQUIREMENTS.md template with section structure.
- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
