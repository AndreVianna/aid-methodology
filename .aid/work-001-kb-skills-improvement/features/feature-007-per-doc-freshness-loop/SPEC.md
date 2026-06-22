# Per-Doc Freshness Loop

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-5, FR-6, FR-7) | /aid-interview |

## Source

- REQUIREMENTS.md §5.B (FR-5, FR-6, FR-7)
- REQUIREMENTS.md §1.8 (freshness loop's three holes + closers), §2.5 (P5)
- §4 S2, S8, §10 (Should)

## Description

This feature closes the KB freshness loop at per-document granularity. Building on
the `sources:` primitive (f001), it adds a **deterministic per-doc staleness
check** that compares each doc's `sources:` last-changed commit against that doc's
approval commit and marks drifted docs *suspect* — replacing today's single coarse
whole-KB tip-date judgment sweep that nobody runs. Source changes **trigger**
per-doc suspect flagging, and the dashboard **surfaces per-doc freshness**
(replacing the single coarse whole-KB badge) so doc owners get an actionable
signal: which doc their change made suspect.

The governing principle is **auto-detect/flag, never auto-apply** — detection is
automatic and deterministic, but every change to KB content remains human-gated.
This gives doc owners precision and a trigger without surrendering the human gate.

## User Stories

- As a **doc owner / maintainer**, I want a per-doc, source-keyed staleness signal
  so that I know exactly which doc my change made suspect instead of getting a
  whole-KB coarse alarm I ignore.
- As a **doc owner**, I want source changes to trigger suspect flagging and the
  dashboard to surface it so that drift is detected automatically rather than from
  human memory.
- As an **AID adopter (incl. AI-skeptic)**, I want freshness to flag but never
  auto-apply so that the KB stays trustworthy and human-gated.

## Priority

Should

## Acceptance Criteria

- [ ] Given a doc with `sources:`, when the staleness check runs, then it compares
  each source's last-changed commit against the doc's approval commit and marks
  drifted docs suspect (deterministic). *(FR-5, AC5)*
- [ ] Given a source change, when it lands, then per-doc suspect flagging is
  triggered and the dashboard surfaces per-doc freshness (replacing the coarse
  whole-KB badge). *(FR-6, AC5)*
- [ ] Given a suspect doc, when freshness runs, then it auto-detects/flags but never
  auto-applies — the update remains human-gated. *(FR-7)*

> Cross-cutting note: depends on the `sources:` primitive (f001). The staleness
> check is deterministic and CI-able (FR-23 / NFR-3).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
