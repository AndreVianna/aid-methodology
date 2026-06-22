# Review Panel & Calibration Rubric

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-17, FR-18, FR-19) | /aid-interview |

## Source

- REQUIREMENTS.md §5.D (FR-17, FR-18, FR-19)
- REQUIREMENTS.md §1.4 (review side, the panel, calibration, evidence-anchored grading), §2.2/§2.4 (P2, P4)
- §4 S4

## Description

This feature replaces the single blended reviewer with a **multi-mandate review
panel** and adds the missing rubric dimension so the gate stops selecting for
"shallow-but-true." The panel applies five mandates — **Correctness** (claims true
vs source), **Anatomy/Coverage** (what in the source is unrepresented),
**Concept-closure** (every native term defined; salient-term coverage),
**Teach-back** (using only the KB, explain the engine and answer "what is X?"), and
**Calibration** (summary vs transcription — the sweet spot). The mandates are
**invariant across paths**; the **panel size scales** (full parallel panel for
brownfield-large, collapsing onto fewer reviewers — down to one running the
checklist — for brownfield-small / greenfield).

**Teach-back closure becomes the keystone exit criterion**, displacing "severity
distribution ≥ A+." The new **Calibration** dimension grades transcription (too
fat), hollowness (too thin), coverage-vs-source (a load-bearing fact in the doc's
`sources:` is absent), and deferral-must-point — all graded against
mechanically-generated evidence lists (salient terms, source files), so grading is
evidence-anchored and repeatable rather than pure recall.

## User Stories

- As an **AID adopter (incl. AI-skeptic)**, I want the gate to certify usefulness
  (teach-back) and not just "true + template-complete" so that a green gate actually
  means the KB captured my project.
- As an **AI agent** consuming the KB, I want calibration grading to catch
  transcription and hollowness so that docs sit at the useful altitude (summary +
  pointer), not as fat duplicates or empty link-farms.
- As an **AID maintainer**, I want reviewers graded against mechanically-generated
  evidence lists so that grading is repeatable and CI-anchored, and the panel scales
  by path.

## Priority

Must

## Acceptance Criteria

- [ ] Given a KB under review, when the panel runs, then it applies all five
  mandates (Correctness, Anatomy/Coverage, Concept-closure, Teach-back, Calibration),
  invariant across paths, with panel size scaling by path. *(FR-17)*
- [ ] Given a reviewed KB, when the exit is evaluated, then teach-back closure is the
  keystone exit criterion (not severity distribution). *(FR-18; supports AC1)*
- [ ] Given planted calibration fixtures, when the rubric grades them, then it flags
  transcription (too fat), hollowness (too thin), and coverage-vs-source gaps,
  graded against mechanically-generated evidence lists. *(FR-19, AC6)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — evidence
> lists (salient terms, source files) are mechanically generated; the review panel
> is fully parallel (wall-clock); teach-back is anchored to a fixed question set
> derived from the harvest. The AC6 calibration fixtures are provided by f012.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
