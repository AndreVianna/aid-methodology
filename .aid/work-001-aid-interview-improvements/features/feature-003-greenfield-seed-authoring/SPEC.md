# Greenfield KB-Seed Authoring

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-1 (impl), §5 FR-3, §6 NFR-3/NFR-4, §9 AC-2/AC-5, §10 P1 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-1 (impl), §5 FR-3, §6 NFR-3 / NFR-4, §9 AC-2 / AC-5, §10 P1

## Description

When a project has no code yet, the skill forward-authors a minimal-but-sufficient Knowledge-Base
seed by eliciting it from the user the way a seasoned analyst would — the inverse of the
brownfield extraction model, where the authored design docs ARE the source of truth and the code
is later built to conform to them. Grounded in the research spike, the seed's keystone is the
declared concept-spine / ubiquitous language, plus intended architecture, conventions and
standards, and technology stack — explicitly not the full brownfield doc-set (no module-map or
test-landscape, since there is no code). Like brownfield discovery, the seed's exact shape adapts
to the project's domain rather than being a fixed list. The sufficiency bar is the minimum needed
for the downstream phases (aid-specify / aid-plan / aid-execute) to act — no more, no bloat. As
part of authoring, the analyst runs an interview-time coherence check: it validates that the
forward-authored seed and the gathered requirements are mutually coherent (same work, no
contradictions) and surfaces any gaps or conflicts to the user for resolution before the work
proceeds. The finished seed must pass the same KB review / calibration gate (grade ≥ A) as an
extracted KB.

## User Stories

- As the work-definer (human) starting a from-scratch project, I want the skill to draw out and
  author a minimal KB seed from my intent so that the downstream phases have the knowledge they
  need even though no code exists yet.
- As a downstream AI agent (aid-specify / aid-plan / aid-execute), I want a seed that conforms to
  the existing KB contract and is sufficient to act on so that I can proceed without KB-gap
  loopbacks.
- As the work-definer, I want the analyst to check the seed and my requirements for coherence and
  flag conflicts so that contradictions are resolved before the work moves forward.

## Priority

Must

## Acceptance Criteria

- [ ] Given a code-less project, when the skill is run, then it yields a forward-authored KB seed
  that passes the KB review gate (≥ A) and is sufficient for aid-specify to proceed — measured by
  a clean aid-specify run with zero KB-gap loopbacks. *(AC-2)*
- [ ] Given a forward-authored seed and gathered requirements, when authoring completes, then the
  skill validates seed ↔ requirements coherence and surfaces any conflicts before proceeding.
  *(AC-5)*
- [ ] Given the sufficiency bar, when the seed is authored, then it contains the minimum needed
  for the downstream phases — not the full brownfield doc-set. *(AC-2, NFR-4)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
