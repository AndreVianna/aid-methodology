# Housekeep ↔ Update-KB Boundary & Standing Closure

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-33, FR-34) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-33, FR-34)
- REQUIREMENTS.md §1.8 (skill topology, freshness loop), §2.8 (P8)
- §4 S7, S8, §10 (Should)

## Description

This feature draws the clean boundary between the two KB-mutating skills and makes
concept-closure a standing invariant. It defines `aid-housekeep` (KB-DELTA) as
**source-driven and global** — a whole-KB reconcile against current source state
(triggered by merge-to-master / major change / periodic), using the FR-5 per-doc
staleness as the shared signal to scope the sweep. It defines `aid-update-kb` as
**prompt-driven and targeted** — a prompt specifies what to update, and the skill
analyzes how best to fold that into the KB via the review/calibration gate. The two
**MUST NOT overlap**; per-doc staleness (FR-5) is the shared signal that
distinguishes them.

It also makes **concept-closure a maintained invariant**, not a discovery-only
check: both `aid-update-kb` and `aid-housekeep` must **re-verify closure** after
they change the KB, so the KB cannot drift into having an undefined
project-specific term after a targeted edit or a reconcile sweep.

## User Stories

- As an **AID maintainer**, I want a clear housekeep-vs-update-kb boundary (global
  source-driven vs targeted prompt-driven) so that I always know which skill to run
  and the two never overlap.
- As a **doc owner**, I want per-doc staleness to scope the housekeep sweep so that
  reconciliation is targeted rather than an expensive whole-KB judgment sweep.
- As an **AI agent** consuming the KB, I want closure re-verified after any KB
  change so that the KB stays self-contained (no undefined native term) over time.

## Priority

Should

## Acceptance Criteria

- [ ] Given the two skills, when each runs, then `aid-housekeep` performs a
  whole-KB source-driven reconcile and `aid-update-kb` performs a prompt-driven
  targeted update, with no overlap and per-doc staleness (FR-5) as the shared
  signal. *(FR-33, AC10)*
- [ ] Given a KB change by `aid-update-kb` or `aid-housekeep`, when it completes,
  then it re-verifies concept-closure (closure is a standing invariant, not
  discovery-only). *(FR-34; supports AC3)*

> Cross-cutting note: depends on f007 (per-doc staleness, FR-5) as the shared
> signal, and on f004's closure check (FR-14) as the invariant re-verified here.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
