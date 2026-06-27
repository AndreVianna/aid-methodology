# Elicitation Research Spike

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-1, §8 D-2/A-1, §9 AC-1, §10 P0 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-1 (spike scope), §8 D-2 / A-1, §9 AC-1, §10 P0

## Description

Before any elicitation design begins, run a RESEARCH spike to ground the work in proven
practice rather than guesswork. The spike surveys established Requirements Elicitation and
Domain Discovery techniques (candidates such as Domain-Driven Design / ubiquitous language,
Event Storming, User-Story Mapping, the Volere / requirements-engineering process, context
and domain modeling, JAD-style facilitation, and "five whys" / laddering) and maps each to
two questions: what a minimal-but-sufficient KB seed should contain, and how the analyst
should drive the conversation to extract it. It also runs a comparative analysis of the
web-trending "grill-me" question-driven elicitation approach (and similar variants) for
general requirements gathering — not only greenfield — assessing its strengths and weaknesses
against AID's seasoned-analyst elicitation and distilling what to adopt versus avoid. The
spike's findings gate the entire elicitation design: the seed-content set, the analyst
calibration behavior, and the guided-triage conversation all depend on its recommendations.

## User Stories

- As a downstream AID maintainer designing the elicitation engine, I want a findings report
  that recommends a proven seed-content set and analyst conversation design so that I build on
  established elicitation practice instead of guessing.
- As the work-definer (human) who will later run the skill, I want the questioning approach
  grounded in real analyst techniques so that the interview genuinely draws out the right
  information.
- As an AID maintainer evaluating "grill-me," I want a strengths/weaknesses/adopt-vs-avoid
  comparison so that we reuse good ideas in AID's own idiom and consciously avoid the bad ones.

## Priority

Must

## Acceptance Criteria

- [ ] Given the work has started, when the spike completes, then it produces a findings report
  covering classic elicitation / domain-discovery techniques. *(AC-1)*
- [ ] Given the spike's research, when the report is delivered, then it includes the "grill-me"
  comparative (strengths / weaknesses / adopt-vs-avoid). *(AC-1)*
- [ ] Given the surveyed techniques, when the report concludes, then it recommends a specific
  seed-content set and an analyst conversation design that ground FR-1 impl, FR-2 calibration,
  and FR-5 guided triage. *(AC-1)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
