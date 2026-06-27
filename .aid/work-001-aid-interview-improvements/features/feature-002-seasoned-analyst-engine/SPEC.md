# Seasoned-Analyst Elicitation Engine

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-2, §6 NFR-1, §6 NFR-7, §9 AC-3/AC-4, §10 P1 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-2, §6 NFR-1, §6 NFR-7, §9 AC-3 / AC-4, §10 P1

## Description

The shared conversational substrate that makes the skill behave like a seasoned system analyst
rather than a passive transcriber or a rigid one-question machine. It is one reusable component
consumed by greenfield seed authoring and by guided triage. Three behaviors define it. First,
**calibration**: the engine assumes nothing about the user; early on it asks the user's level
and type of knowledge (domain familiarity, software / requirements practice, AID itself) and
then shapes question depth and style to match — lighter confirmation for an expert, heavier
drawing-out for a novice. Second, the **conversational expert advisor** stance: it gracefully
supports "I don't know," "what's your recommendation?," "explain the pros and cons," and
"explain it like I'm a junior"; it guides an unsure user, recommends as a real expert when
asked, explains trade-offs at the right depth, and cordially disagrees with reasons when the
user is mistaken — while still deferring the final decision to the user. Third, the
**suggested-answer-and-rationale contract**: every question the analyst asks carries a concrete
suggested answer plus the rationale behind it, so the user always decides but never from a
blank prompt. Discipline lives in the process (visible state, recorded decisions, one confirmed
decision at a time), not in restricting the dialogue.

## User Stories

- As the work-definer (human) of unknown expertise, I want the analyst to ask my knowledge level
  and adapt so that the questioning matches how much help I actually need.
- As an unsure work-definer, I want to say "I don't know" or "what do you recommend?" and get a
  real expert answer with trade-offs explained at my level so that I can make an informed call.
- As a work-definer who is mistaken, I want the analyst to cordially push back with reasons so
  that I correct course rather than being yes-manned into a bad decision.
- As any work-definer, I want every question to come with a suggested answer and its rationale so
  that I can knowingly agree or disagree instead of starting from a blank prompt.

## Priority

Must

## Acceptance Criteria

- [ ] Given the skill is running, when the analyst asks any question, then that question carries
  a concrete suggested answer plus the rationale behind it (no bare, suggestion-less questions
  ever). *(AC-3)*
- [ ] Given a new session, when the interview begins, then the skill asks the user's knowledge
  level/type and demonstrably adapts subsequent question depth and style. *(AC-4)*
- [ ] Given an unsure or mistaken user, when they respond "I don't know," "what do you
  recommend?," or "explain like a junior" — or assert something incorrect — then the analyst
  guides, recommends, explains at the right depth, and cordially disagrees while still deferring
  the decision to the user. *(AC-4)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
