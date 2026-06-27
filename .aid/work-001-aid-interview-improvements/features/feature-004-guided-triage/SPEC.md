# Guided Triage

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-5, §6 NFR-2, §9 AC-7/AC-10, §10 P1 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-5, §6 NFR-2, §9 AC-7 / AC-10, §10 P1

## Description

Triage today leaves the user to self-describe the work with no guidance, so the description is
often insufficient to route correctly. This feature replaces that with analyst-driven triage:
using the same seasoned-analyst elicitation engine, the skill actively draws out from the user
the information needed to choose the right path (full vs lite) and the right recipe, instead of
relying on a raw free-form description. It is KB-context-aware and works in both contexts — when
the project already has a full KB (brownfield, after aid-discover) and when it has only a seed KB
(greenfield) — leveraging whatever KB exists to ask sharper, gap-targeted questions. The existing
brownfield path (aid-discover KB plus the standard interview) must keep working unchanged;
guided triage is additive.

## User Stories

- As the work-definer (human), I want the analyst to draw out the path- and recipe-deciding
  details rather than making me self-describe so that my work is routed to the right path and
  recipe.
- As the work-definer on a project that already has a KB (full or seed), I want triage to use
  that KB as context so that it asks sharper, gap-targeted questions.
- As an AID adopter on an existing brownfield project, I want the established aid-discover plus
  standard interview path to keep working so that the new guided triage is purely additive.

## Priority

Must

## Acceptance Criteria

- [ ] Given a user describing a new work, when triage runs, then the analyst draws out the
  path-deciding information and routes to the right path and recipe. *(AC-7)*
- [ ] Given a project with a full KB or only a seed KB, when triage runs, then it works in both
  contexts and leverages the available KB as context. *(AC-7)*
- [ ] Given the existing brownfield path, when this feature ships, then aid-discover plus the
  standard interview path still passes its tests. *(AC-10, NFR-2)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
