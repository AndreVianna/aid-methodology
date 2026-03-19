
# Adaptive Requirements Gathering

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time conversation. Produce a structured REQUIREMENTS.md.

## Core Principle

**One question at a time.** Humans think better with focused prompts. Each answer shapes the next question. Nothing gets assumed — if they don't say it, we don't spec it.

## When to Use

- **Full interview:** New project. No REQUIREMENTS.md exists.
- **Targeted interview:** A GAP.md from aid-plan, aid-detail, or aid-specify identifies a `needs-interview` requirement gap. Ask only about the specific gap.

## Inputs

- `knowledge/` directory (if brownfield — pre-fills technical fields).
- Project description or brief (if greenfield).
- For targeted interview: the GAP.md that triggered re-entry.

## The Knowledge Model

The interview is driven by a structured map of what a complete REQUIREMENTS.md needs. Each field is tracked as:

- **known** — answered by the stakeholder or confirmed from KB.
- **unknown** — not yet asked. Determines the next question.
- **assumed** — inferred from KB or context. Needs confirmation.

```
Field                   Status      Source
─────────────────────────────────────────────────
business.type           unknown     → ask in Phase 1
business.problem        unknown     → ask in Phase 1
users.roles             unknown     → ask in Phase 1
users.primary_needs     unknown     → blocked until users.roles known
features.priority_list  unknown     → ask in Phase 2
features.must_have      unknown     → blocked until features.priority_list
technical.platform      known       KB technology-stack.md (brownfield)
technical.integrations  assumed     KB found 3 APIs → confirm
technical.data          known       KB data-model.md (brownfield)
constraints.timeline    unknown     → ask in Phase 4
constraints.budget      unknown     → ask in Phase 4
constraints.compliance  unknown     → ask in Phase 4
scope.excluded          unknown     → ask in Phase 5
```

### Question Selection Algorithm

1. Scan for `unknown` fields.
2. Prioritize by dependency: fields that unblock other fields go first.
3. Batch efficiency: confirm `assumed` fields alongside new questions when natural.
4. Open questions early → specific questions later.
5. Never ask what the KB already answered. Mark as `known (from discovery)`. Flag critical items for confirmation.

### Implications

- **Greenfield interviews are longer** — everything starts as `unknown`.
- **Brownfield interviews are shorter** — KB pre-fills technical fields.
- **Returning clients** can reuse prior REQUIREMENTS.md as starting state.

## Interview Protocol

### Phase 1: Context (3-5 questions)

Establish business domain and problem space.

Example questions (adapt to context):
- "What does your business do?" / "Tell me about your company."
- "Who are the users of this system?"
- "What problem are we solving? In your own words."

Goal: Build domain understanding. Populate `business.*` and `users.*` fields.

### Phase 2: Scope (3-5 questions)

Establish boundaries and priorities.

Example questions:
- "What's the most important feature? If you could only ship one thing, what would it be?"
- "What does success look like for this project?"
- "What's the timeline? Is there a hard deadline?"

Goal: Populate `features.*` and establish priority ordering.

### Phase 3: Technical (adapted to answers)

Only ask what's relevant and not already known from KB.

Example questions:
- "What platforms do you need to support?"
- "Do you have existing infrastructure we'll be working with?"
- "Any integrations required — third-party APIs, data sources, services?"

**Brownfield shortcut:** If KB exists, present what was discovered and ask for confirmation: "Our analysis shows you're using PostgreSQL 14 with Redis caching. Is that current?" This replaces 3-5 questions with one confirmation.

Goal: Populate `technical.*` fields. Confirm `assumed` fields from KB.

### Phase 4: Constraints (2-3 questions)

Practical limits that shape the solution.

Example questions:
- "Budget range — fixed price, hourly, or range?"
- "Who's available on your team to collaborate?"
- "Any compliance requirements — HIPAA, GDPR, SOC2, industry-specific?"

Goal: Populate `constraints.*` fields.

### Phase 5: Verification

Summarize understanding back to the stakeholder.

"Here's what I understand so far. Did I get this right? Anything I missed?"

Present a structured summary matching the REQUIREMENTS.md format. Let them correct, add, or clarify.

Goal: Move all remaining `assumed` fields to `known`. Catch misunderstandings before specification.

## Interview Behaviors

### Adaptive Questioning

Each answer may:
- **Answer the question** → mark field as `known`, select next `unknown` field.
- **Reveal something unexpected** → add new fields to the model, adjust question order.
- **Contradict the KB** → flag the contradiction, trigger aid-discover for targeted update.
- **Be vague** → ask a follow-up to sharpen the answer. Don't accept "it depends" without knowing what it depends on.

### Tone

- Conversational, not interrogative. You're learning about their business, not deposing a witness.
- Show understanding: "Got it — so the core problem is X, and you need Y to solve it."
- Ask clarifying questions naturally: "When you say 'reports,' what does that look like? PDF? Dashboard? Email?"

### What NOT to Do

- Don't dump 10 questions at once. One at a time.
- Don't ask technical questions the KB already answered.
- Don't assume requirements the stakeholder didn't state.
- Don't use jargon the stakeholder hasn't used.
- Don't make it feel like a form. Make it feel like a conversation.

## Output: REQUIREMENTS.md

Generate using the template in [references/requirements-template.md](references/requirements-template.md).

Key sections:
- **Problem Statement** — in the stakeholder's words, not yours.
- **Users** — roles, descriptions, primary needs.
- **Features** — priority-ordered (Must/Should/Could).
- **Technical Context** — existing systems, integrations, platform, data.
- **Constraints** — timeline, budget, team, compliance.
- **Assumptions** — stated explicitly, must be verified.
- **Out of Scope** — explicitly excluded to prevent scope creep.

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
4. Report completion to the calling phase so it can resume.

## Quality Checklist

- [ ] Every Must feature has clear acceptance criteria (even if informal).
- [ ] Problem Statement uses the stakeholder's language, not technical jargon.
- [ ] Assumptions are explicit — nothing is silently assumed.
- [ ] Out of Scope is defined — prevents scope creep.
- [ ] Technical context is consistent with KB (if brownfield).
- [ ] All `assumed` fields were confirmed or corrected during verification.

## See Also

- [Requirements Template](references/requirements-template.md) — Full REQUIREMENTS.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
