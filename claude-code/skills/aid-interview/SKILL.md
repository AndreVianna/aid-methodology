---
name: aid-interview
description: >
  Adaptive requirements gathering through one-question-at-a-time conversation.
  Produces REQUIREMENTS.md. Use for new projects (full interview) or when a
  GAP.md specifies needs-interview (targeted interview).
allowed-tools: Read, Glob, Grep
context: fork
agent: interviewer
---

# Adaptive Requirements Gathering

Gather requirements from a human stakeholder through adaptive conversation. One question at a time.

## Inputs

- `knowledge/` directory (if brownfield — pre-fills technical fields)
- Project description or brief (if greenfield)
- For targeted interview: GAP.md that triggered re-entry

## Knowledge Model

Track each field as: **known** (answered), **unknown** (not yet asked), **assumed** (from KB, needs confirmation).

Question selection: prioritize by dependency (fields that unblock others go first), batch assumed confirmations naturally, open questions early → specific later.

## Interview Protocol

### Phase 1: Context (3-5 questions)
Business domain, users, problem statement. Populate `business.*` and `users.*`.

### Phase 2: Scope (3-5 questions)
Features, priorities, success criteria, timeline. Populate `features.*`.

### Phase 3: Technical (adapted)
Only ask what KB doesn't already answer. For brownfield: present findings and confirm. Populate `technical.*`.

### Phase 4: Constraints (2-3 questions)
Budget, team, compliance. Populate `constraints.*`.

### Phase 5: Verification
Summarize understanding back. Move `assumed` → `known`. Catch misunderstandings.

## Behaviors

- One question at a time — never dump multiple questions
- Show understanding: "Got it — so the core problem is X"
- Don't ask what KB already answered
- Don't assume requirements the stakeholder didn't state
- Don't use jargon the stakeholder hasn't used
- If answer contradicts KB → flag, trigger targeted aid-discover

## Targeted Interview (Re-entry)

1. Read GAP.md for what's missing
2. Ask only about the specific gap
3. Update REQUIREMENTS.md
4. Report completion

## Output

`REQUIREMENTS.md` with: Problem Statement (stakeholder's words), Users, Features (Must/Should/Could), Technical Context, Constraints, Assumptions, Out of Scope.

## Quality Checklist

- [ ] Every Must feature has acceptance criteria
- [ ] Problem Statement uses stakeholder language
- [ ] Assumptions are explicit
- [ ] Out of Scope is defined
- [ ] Technical context consistent with KB (if brownfield)
- [ ] All assumed fields confirmed or corrected
