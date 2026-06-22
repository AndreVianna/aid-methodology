# Validation Fixture

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-35) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-35)
- REQUIREMENTS.md §1.2 (the 'Relative bus' miss — the original complaint), §1.4 (the honest limit), §2.1/§2.2 (P1, P2)
- §10 (Must)

## Description

This feature validates the whole overhaul against the **known failure case** and
guards against regression. It provides a **fixture project containing a planted
'Relative bus'-style coined concept** — a load-bearing native concept of exactly
the kind discovery silently missed before — and a regression test asserting the
method **captures and defines it**, proving the essence-capture gap is closed.

The fixture is also the substrate for the other validation ACs: the planted
calibration fixtures (transcription / hollowness / coverage-vs-source) that the
rubric must flag (f005), and the greenfield / brownfield-small / brownfield-large
fixtures the triage must classify and run to teach-back closure (f006). Together
with the deterministic closure self-containment check, this feature is the
CI-anchored proof that the method works and stays working.

## User Stories

- As an **AID maintainer**, I want a fixture with a planted 'Relative bus'-style
  concept and a regression test so that the original essence-capture failure is
  proven closed and cannot regress.
- As an **AID adopter (incl. AI-skeptic)**, I want the method validated against a
  known failure case in CI so that I can trust the overhaul actually works.
- As an **AID maintainer**, I want calibration and three-path fixtures so that
  f005's rubric and f006's triage have a deterministic test substrate.

## Priority

Must

## Acceptance Criteria

- [ ] Given a fixture project with a planted 'Relative bus'-style coined concept,
  when the method runs, then it captures and defines the concept, and a regression
  test guards it. *(FR-35, FR-12, AC2)*
- [ ] Given the KB produced for the fixture, when the self-containment check runs,
  then no project-specific term is left undefined (concept closure passes). *(AC3,
  with f004)*
- [ ] Given calibration and three-path fixtures, when f005's rubric and f006's
  triage run, then the fixtures exercise transcription/hollowness/coverage flagging
  (AC6) and correct path classification to teach-back closure (AC7). *(supports AC6,
  AC7)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — the fixtures
> and regression tests are deterministic and CI-able (the AC2/AC3/AC11 proof
> substrate). Provides fixtures consumed by f004, f005, and f006.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
