# Build-Time Conformance Lifecycle

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-4, §6 NFR-5, §8 D-4, §9 AC-6, §10 P2 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-4, §6 NFR-5, §8 D-4, §9 AC-6, §10 P2

## Description

In greenfield, the forward-authored seed is the authoritative design contract (design→code), the
opposite of the brownfield default where code is the source of truth and docs describe it. As
code is later written by aid-execute, the job is to verify the code conforms to the design and to
reconcile any divergence deliberately — not to silently replace the design with as-built. This
feature builds a NEW conformance check that detects when as-built code diverges from the design and
flags it for human reconciliation. (Cross-ref: the existing f007 freshness mechanism CANNOT do this
— it is read-only and source→doc directional, detecting "a sources: file changed," not "code diverged
from this doc," and a seed has no file-sources; and nothing auto-overwrites docs today, so the new
work is the check direction + greenfield-origin marking, not riding on f007.) Authority stays
design→code until a human reconciles the drift; all reconciliation is human-gated. This is the P2
lifecycle layer that becomes meaningful only once the greenfield seed model exists.

## User Stories

- As an AID maintainer, I want a greenfield-origin doc's divergence from as-built code flagged for
  human reconciliation rather than auto-overwritten so that the authored design stays the source
  of truth until I deliberately reconcile it.
- As the work-definer (human) whose seed is the design contract, I want authority to stay
  design→code until reconciled so that code is held to conform to my design, not the reverse.
- As an AID maintainer, I want a new conformance check (code→design divergence) — which f007 cannot
  provide, being read-only and source→doc directional — so that a greenfield seed's divergence from
  later as-built code is surfaced for human reconciliation rather than going undetected.

## Priority

Must

## Acceptance Criteria

- [ ] Given a greenfield-origin doc, when its content diverges from the as-built code, then the
  divergence is flagged for human reconciliation and is not auto-overwritten. *(AC-6)*
- [ ] Given detected divergence, when reconciliation occurs, then it is human-gated and authority
  stays design→code until reconciled. *(AC-6, NFR-5)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
