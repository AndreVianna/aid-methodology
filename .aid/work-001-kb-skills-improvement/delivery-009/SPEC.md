# Delivery SPEC -- delivery-009: Greenfield Path

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-009/STATE.md.

> **Delivery:** delivery-009
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Deliver the forward-authoring **greenfield** path -- discovering a project that has nothing to
extract yet (intent + vocabulary + design) -- plus the greenfield->brownfield transition, as a
self-contained Could slice. Greenfield elicits its concept spine by **reusing the existing
`aid-interview` / `aid-specify` skills** (no bespoke greenfield engine): a greenfield's thin
intent-KB becomes the spec the code is built against. As code lands, the greenfield->brownfield
transition is handled -- re-triage re-routes to the standard brownfield engine (delivery-004), which
captures the now-extractable anatomy, and crossing the complexity threshold triggers a
brownfield-large consolidation. This is the highest-risk / most speculative branch, scoped Could and
deferred to last so the Must/Should backbone ships independently of it. Its validation fixture (the
greenfield path fixture) ships here too.

## Scope

In scope:

- **feature-006 -- GREENFIELD scope:** the greenfield path (elicit mode -- concept acquisition via
  `aid-interview`/`aid-specify`, forward-authored generation shape, "intent coherent + vocab set"
  closure, teach-back as the invariant exit) and the greenfield->brownfield transition (re-triage
  re-routes to the brownfield engine; threshold crossing triggers brownfield-large consolidation).
- **feature-012 -- GREENFIELD scope:** the AC7 greenfield path fixture -- a greenfield fixture that
  triage classifies correctly and that reaches teach-back closure via the elicit path.

**Out of scope (owned elsewhere):** the recon classifier + brownfield-small/large paths
(delivery-004, f006 brownfield -- consumed; greenfield re-triage re-routes INTO the brownfield
engine); the brownfield + engine fixtures (delivery-005, f012 engine+brownfield -- consumed as the
regression backbone); all of delivery-001's essence substrate.

## Gate Criteria

- [ ] The recon pre-pass proposes the **greenfield** path (measured, not declared), human-confirmed.
  *(f006 greenfield, AC7)*
- [ ] Given the greenfield path, discovery elicits intent + vocabulary + design by reusing
  `aid-interview`/`aid-specify` (no bespoke engine) and reaches teach-back closure (the invariant
  exit). *(f006 greenfield, AC7)*
- [ ] Given a re-run after code lands, the greenfield->brownfield transition is handled: re-triage
  re-routes to the brownfield engine which captures the now-extractable anatomy; crossing the
  complexity threshold triggers a brownfield-large consolidation. *(f006 greenfield, FR-22)*
- [ ] Given a greenfield fixture, triage classifies it correctly and the greenfield path reaches
  teach-back closure. *(f012 greenfield, AC7)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-004, delivery-005
- **Blocks:** -- (none)

## Notes

**Scope-split (Cross-Cutting Risk R1):** this delivery owns the **greenfield** scope of feature-006
and feature-012; the brownfield scope of both is owned by delivery-004 / delivery-005 and listed
out-of-scope above, so no AC is unowned or double-owned. Scoped **Could** and sequenced last because
it is the highest-risk / most speculative branch -- the Must/Should backbone (delivery-001..008)
ships and delivers value independently if this slice slips. Greenfield deliberately reuses
`aid-interview`/`aid-specify` rather than building a bespoke engine; the greenfield->brownfield
transition re-routes into delivery-004's brownfield engine, which is why this delivery depends on it.
