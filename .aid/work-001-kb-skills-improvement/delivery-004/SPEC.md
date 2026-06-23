# Delivery SPEC -- delivery-004: Adaptive Paths (brownfield)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-004/STATE.md.

> **Delivery:** delivery-004
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Make discovery adapt to project shape. A **recon pre-pass** measures source-availability and
complexity and **proposes** a path (human-confirmed) -- the path is *measured, not declared* from a
static `project.type`. Each path configures the same essence method differently per the agreed
matrix (concept acquisition, generation shape, closure depth, panel size, source-of-truth, exit),
scaling the closure engine (delivery-001's f004 cap-override interface) and the review panel
(delivery-001's f005 full-panel default, collapsed for small projects) to project size -- while
teach-back closure remains the invariant exit. This delivery is the **brownfield** scope:
brownfield-small and brownfield-large. The greenfield branch is carved to delivery-009.

## Scope

In scope -- **feature-006, BROWNFIELD scope only**:

- The recon classifier (`recon-classify.sh` + triage references): measures source-availability /
  complexity and proposes a path, human-confirmed.
- **Classifier completeness (whole/indivisible):** D4 builds the **full ordered classifier rule
  including the greenfield-proposing branch** -- `recon-classify.sh` is a single ordered awk rule
  whose first branch proposes GREENFIELD, so the rule cannot be split. The greenfield-proposing
  *code* is attributed to D4; D9 consumes the classifier as-built and validates the greenfield arm,
  delivering the greenfield *path behavior + gate*. D4's gate stays scoped to brownfield path
  outcomes.
- The **brownfield-small** path: single understand-pass closure (`max_rounds: 1`), collapsed panel.
- The **brownfield-large** path: full batched closure loop (default caps), full parallel panel.
- Wiring the per-path closure caps through f004's Step-5b cap-override interface
  (`--max-clean-passes`/`--max-rounds`/`--token-budget`) and the per-path panel-size collapse
  through f005's per-mandate dispatch list.

**Out of scope (carved to delivery-009):** the **greenfield** path (elicit mode via
`aid-interview`/`aid-specify`) and the **greenfield->brownfield transition**. **Out of scope
(elsewhere):** the closure cap-override *interface* and the full-panel default themselves
(delivery-001, f004/f005 -- consumed here as final); the path **fixtures** that prove correct
classification + teach-back closure (delivery-005, f012).

## Gate Criteria

- [ ] The recon pre-pass measures source-availability/complexity and proposes a path
  (brownfield-small / brownfield-large), human-confirmed -- measured, not declared. *(f006, AC7)*
- [ ] Given a proposed brownfield path, discovery configures the method per the agreed matrix and
  reaches teach-back closure (the invariant exit). *(f006, AC7)*
- [ ] Given a re-run, the path is re-triaged. *(f006; the greenfield->brownfield transition limb is
  delivery-009)*
- [ ] The per-path closure caps are supplied through f004's Step-5b cap-override interface and the
  per-path panel size through f005's dispatch list (brownfield-large = full; brownfield-small =
  collapsed). *(f006 wiring of delivery-001 seams)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-005, delivery-009

## Notes

**Scope-split (Cross-Cutting Risk R1):** feature-006 is split brownfield-here / greenfield-in-
delivery-009. The brownfield ACs (AC7 brownfield-small/large) are owned here; the greenfield branch
+ transition ACs are explicitly out-of-scope and owned by delivery-009, so no AC is unowned or
double-owned. Consumes delivery-001's f004 cap-override interface (provide-before-consume) and
f005's full-panel default (the unit f006 collapses). The brownfield path fixtures that prove this
delivery's behavior are delivered by delivery-005 (f012).
