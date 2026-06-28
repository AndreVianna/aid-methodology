# Delivery SPEC -- delivery-004: Greenfield Seed Authoring

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-004
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Give AID a greenfield on-ramp: when a project has no code yet, forward-author a minimal-but-sufficient
KB seed from the user's intent (elicited by the delivery-003 engine), so the downstream phases have
the knowledge they need before any code exists. This inverts the brownfield model -- the authored
design docs ARE the source of truth and code is later built to conform. It is the work's primary
greenfield driver and the input that delivery-005 (conformance) checks against.

## Scope

feature-003-greenfield-seed-authoring: the 5-element seed-content model (concept-spine,
architecture, conventions, tech-stack, decisions) each mapped to its KB doc + `kb-category`; the new
`source: forward-authored` frontmatter marker (the one C-1 schema addition) + its schema / lint /
index / freshness edits; the greenfield-mode review gate (a flag on the existing
`document-expectations.md`, not a fork; the panel-exclusion carve so the seed review reaches the full
panel); the layered seed<->requirements coherence check (concrete-example probe + structural
cross-check); the domain-adaptive seed shape; and the zero-KB-gap-loopback sufficiency bar.

**Out of scope:** the engine itself (delivery-003 -- consumed here); the conformance check
(delivery-005); the skill split (delivery-006). No brownfield behavior change (the marker scopes the
new gate/freshness behavior to forward-authored docs only).

## Gate Criteria

- [ ] A code-less project yields a forward-authored KB seed that passes the greenfield-mode review gate at the work minimum grade (A+) and is sufficient for a downstream aid-specify run with ZERO KB-gap loopbacks (AC-2 / NFR-4).
- [ ] The `source: forward-authored` marker exists end-to-end (schema enum row + lint in-scope + index pass-through + freshness short-circuit to `current`); brownfield docs are unaffected.
- [ ] The layered seed<->requirements coherence check runs at authoring time and surfaces injected conflicts for human resolution before proceeding (AC-5).
- [ ] The seed contains the minimum needed (the 5 elements + domain extensions), NOT the full brownfield doc-set; the as-built docs are correctly excluded.
- [ ] All section-6 quality gates pass (incl. the master-only heavy gates).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-019 | IMPLEMENT | Forward-authored freshness short-circuit in kb-freshness-check.sh |
| task-020 | DOCUMENT | Forward-authored marker schema row + lint/index pass-through notes |
| task-021 | TEST | Marker fixture-through-three-scripts test + brownfield-intact regression |
| task-022 | IMPLEMENT | Greenfield-mode parameterization block in document-expectations.md |
| task-023 | IMPLEMENT | Thread greenfield review param + reconcile state-review.md panel exclusion |
| task-024 | IMPLEMENT | Layered seed<->requirements coherence-check reference doc |
| task-025 | IMPLEMENT | Seed-authoring state (aid-describe step) -- 5-element model + domain-adaptive shape + gate wiring |
| task-026 | CONFIGURE | Full generator render + 5-profile/.claude propagation + DBI |
| task-027 | TEST | Delivery-004 verification -- greenfield gate + zero-loopback sufficiency + coherence + brownfield-intact |

## Dependencies

- **Depends on:** delivery-003 (the seasoned-analyst engine elicits the seed)
- **Blocks:** delivery-005 (the seed model + marker is what conformance checks), delivery-006 (the split operates on the final content)

## Notes

In-place edits to `canonical/skills/aid-interview/` (the seed-authoring state lands on the
aid-describe side per D3) + the KB-authoring schema/scripts + aid-discover's review subsystem
(greenfield-mode flag). Strictly sequential with delivery-003/006 (shared skill dir).
