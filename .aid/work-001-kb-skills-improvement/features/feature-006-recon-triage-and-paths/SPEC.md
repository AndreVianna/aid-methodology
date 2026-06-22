# Recon Triage & The Three Paths

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-20, FR-21, FR-22) | /aid-interview |

## Source

- REQUIREMENTS.md §5.E (FR-20, FR-21, FR-22)
- REQUIREMENTS.md §1.5 (the method, the three paths, triage = lifecycle), §2.7 (P7)
- §4 S5, §10 (brownfield Must; greenfield Could)

## Description

This feature makes discovery **adapt to project shape** through one method with
three recon-selected paths: **greenfield**, **brownfield-small**, and
**brownfield-large**. A **recon pre-pass** measures source-availability and
complexity and **proposes** a path (human-confirmed) — the path is *measured, not
declared* from a static `project.type`. Each path configures the same method
differently per the agreed matrix: concept acquisition (extract vs elicit),
generation shape (forward-authored / single pass / parallel fan-out), closure
depth, panel size, source-of-truth, and exit — while **teach-back closure remains
the invariant exit** across all paths.

The path is **re-triaged every run**, so the three paths are *stages a project
passes through*: a greenfield's thin intent-KB becomes the spec the code is built
against, and as code lands the **greenfield→brownfield transition** is handled —
`aid-update-kb` verifies intent vs as-built and fills anatomy, and crossing the
complexity threshold triggers a brownfield-large consolidation. Per §10, the
brownfield-small and brownfield-large paths are **Must**; the **greenfield branch**
(elicit mode + the greenfield→brownfield transition) is **Could** (highest-risk /
most speculative).

## User Stories

- As an **AID adopter (brownfield)**, I want recon to measure my repo and propose
  the right path so that effort is scaled to my project — small repos stay cheap,
  large repos get the full machinery.
- As an **AID adopter (greenfield)**, I want a forward-authoring path so that I can
  discover a project that has nothing to extract yet (intent + vocabulary + design).
- As an **AID maintainer**, I want the path re-triaged every run and the
  greenfield→brownfield transition handled so that the KB persists and is
  progressively verified/enriched across the project lifecycle.

## Priority

Must (brownfield-small + brownfield-large paths) · Could (greenfield branch + transition)

## Acceptance Criteria

- [ ] Given a project, when the recon pre-pass runs, then it measures
  source-availability/complexity and proposes a path (greenfield / brownfield-small
  / brownfield-large), human-confirmed — measured, not declared. *(FR-20, AC7)*
- [ ] Given a proposed path, when discovery runs, then it configures the method per
  the agreed matrix and reaches teach-back closure (the invariant exit across all
  paths). *(FR-21, AC7)*
- [ ] Given a re-run, when triage executes, then the path is re-triaged and the
  greenfield→brownfield transition is handled (`aid-update-kb` verifies intent vs
  as-built and fills anatomy). *(FR-22)*
- [ ] Given greenfield / brownfield-small / brownfield-large fixtures, when triage
  runs, then it proposes the correct path on each and each path reaches teach-back
  closure. *(AC7 — fixtures from f012; greenfield branch is Could)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — triage depth
> by salience, cost scaling with project size (greenfield/brownfield-small cheap),
> deterministic threshold measurement. Path fixtures are provided by f012.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
