# Delivery SPEC -- delivery-004: Adaptive Paths (brownfield + greenfield detect/signpost)

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
teach-back closure remains the invariant exit. This delivery delivers the two **brownfield**
generation paths (brownfield-small and brownfield-large) PLUS **greenfield detect + signpost**:
recon DETECTS greenfield (RM1/RM2), and on a greenfield verdict aid-discover prints a signpost
and HALTS. There is **no greenfield generation engine** (greenfield de-scoped 2026-06-23; the defunct
pre-act-back greenfield-path delivery-009 was deleted -- NOT the current live delivery-009
Governance) -- forward-authoring a KB-seed from intent is a future interview-side work.

## Scope

In scope -- **feature-006, brownfield generation paths + greenfield detect/signpost**:

- The recon classifier (`recon-classify.sh` + triage references): measures source-availability /
  complexity and proposes a path, human-confirmed.
- **Classifier completeness (whole/indivisible):** D4 builds the **full ordered classifier rule
  including the greenfield-DETECTING branch** -- `recon-classify.sh` is a single ordered awk rule
  whose first branch proposes GREENFIELD. The greenfield DETECTION stays. There is **no greenfield
  generation path behavior** -- on a confirmed greenfield verdict, aid-discover prints the signpost
  and HALTS (detect + signpost in this work; no greenfield generation engine).
- The **brownfield-small** path: single understand-pass closure (`max_rounds: 1`), collapsed panel.
- The **brownfield-large** path: full batched closure loop (default caps), full parallel panel.
- **Greenfield detect + signpost:** on a greenfield verdict, aid-discover prints "Nothing to
  discover yet -- run `/aid-interview` to define the project; the KB fills in as you build, via
  re-triage once code lands" and HALTS (no fan-out, no closure, no panel).
- Wiring the per-path closure caps through f004's Step-5b cap-override interface
  (`--max-clean-passes`/`--max-rounds`/`--token-budget`) and the per-path panel-size collapse
  through f005's per-mandate dispatch list.

**Out of scope (future interview-side work):** the **greenfield generation path** -- forward-
authoring a thin KB-seed from intent (elicit via `aid-interview`/`aid-specify`). No greenfield
generation engine / greenfield closure / greenfield panel-collapse is built here. **Out of scope
(elsewhere):** the closure cap-override *interface* and the full-panel default themselves
(delivery-001, f004/f005 -- consumed here as final); the path **fixtures** that prove correct
classification + teach-back closure (delivery-005, f012).

## Gate Criteria

- [ ] The recon pre-pass measures source-availability/complexity and proposes a path (greenfield /
  brownfield-small / brownfield-large), human-confirmed -- measured, not declared. *(f006, AC7)*
- [ ] Given a confirmed greenfield verdict, aid-discover prints the signpost ("Nothing to discover
  yet -- run `/aid-interview` ...") and HALTS -- no fan-out, no closure, no panel (detect+signpost,
  not a generation path). *(f006, AC7)*
- [ ] Given a confirmed brownfield path, discovery configures the method per the agreed matrix and
  reaches teach-back closure (the invariant exit). *(f006, AC7)*
- [ ] Given a re-run, the path is re-triaged; once a greenfield project's source lands, re-triage
  re-routes it to a brownfield path. *(f006)*
- [ ] The per-path closure caps are supplied through f004's Step-5b cap-override interface and the
  per-path panel size through f005's dispatch list (brownfield-large = full; brownfield-small =
  collapsed; greenfield never reaches the panel -- it halts at the signpost). *(f006 wiring of
  delivery-001 seams)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-005

## Notes

**Greenfield de-scope (2026-06-23):** greenfield is now **detect + signpost** only -- the defunct
pre-act-back greenfield-path delivery-009 (NOT the current live delivery-009 Governance) is
**deleted**. recon DETECTS greenfield (the classifier's first
branch, built in task-023) and on a greenfield verdict aid-discover prints a signpost and HALTS;
there is no greenfield generation engine, no elicit-via-`aid-interview`/`aid-specify` path, no
greenfield closure, and no greenfield panel-collapse. All of feature-006's ACs are now owned here
(no AC is carved out or double-owned): the brownfield generation paths (AC7 brownfield-small/large)
and the greenfield detect+signpost outcome. Forward-authoring a thin KB-seed from intent is a future
interview-side work, out of scope. Consumes delivery-001's f004 cap-override interface (provide-
before-consume) and f005's full-panel default (the unit f006 collapses for brownfield-small). The
brownfield path fixtures that prove this delivery's behavior are delivered by delivery-005 (f012).
