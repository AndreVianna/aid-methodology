# Delivery BLUEPRINT -- delivery-005: Interactive Graph

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-005
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery is the drawing itself: the interactive graph canvas that turns the relationship
table into a picture a reader can move around in, mounted inside delivery-004's shell and drawn by
whatever approach delivery-001's rendering research recommended. Nodes are laid out so structure
is visible rather than tangled; the reader regroups them, thins the density, zooms and pans. Three
presentational obligations are not negotiable: a reader who has asked for reduced motion gets a
settled graph, meaning is never carried by colour alone, and every navigation action has a
keyboard equivalent.

It is scoped as a distinct unit for one reason that runs through the whole plan: feature-008 is
the **only** feature feature-002 blocks, and its size swings substantially on the answer — a
vendored library makes it small and pushes obligations onto feature-012, while hand-rolling the
layout makes it considerably larger. Keeping it separate is what allows everything else to
proceed while the rendering research runs, and it is why §10 can promise that a stalled rendering
research still ships `relationships.md` and the gap ledger.

This is also where two cross-delivery acceptance criteria finally close: **AC-9 and AC-15**.

## Scope

**In scope:**

- **feature-008-interactive-graph-canvas** — the layout, the grouping/density/zoom/pan behaviour
  on the drawing surface, reduced-motion settling, keyboard-equivalent zoom and pan, non-colour
  encoding of node type and provenance by shape and/or label, the Coverage-lens highlighting that
  must match the ledger exactly, and the declaration to feature-007 of whatever runtime
  prerequisites the chosen renderer introduces.

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
choosing the rendering approach (feature-002, delivery-001 — this feature implements it, it does
not decide it); the shell, the data loader and the lens view-model (feature-007, delivery-004);
the peer table rendering and the overall accessibility bar (feature-009, delivery-004); the
ledger itself (feature-006, delivery-003); and the ship-time documentation, suites and Knowledge
Base updates (feature-013, delivery-006).

## Gate Criteria

- [ ] **AC-9 closes overall in this delivery.** Its reduced-motion clause is owned here: a reader
      whose environment requests reduced motion gets layout animation disabled and the graph
      rendered already settled. **feature-009 owns AC-9 overall from delivery-004** (WCAG AA
      structural and accessibility checks, keyboard-navigable and screen-reader-usable table);
      neither owner may consider the criterion met alone, so the gate must verify both halves
      before recording AC-9 as closed.
- [ ] **AC-15 closes overall in this delivery.** Its graph side is owned here: with the Coverage
      lens applied, the graph highlights **exactly** the gaps the ledger records. **feature-006
      owns the criterion from delivery-003 and feature-007 owns the view side from delivery-004**;
      all three SPECs state that neither owner may consider it met alone, so the gate must verify
      all three contributions before recording AC-15 as closed. The equality binds the `int:`
      class only — unbacked `kb:` nodes remain a lens-only signal with no ledger row.
- [ ] **AC-7's graph half** — with each of the four lenses applied, the graph interprets the lens
      identically to the table rendering, satisfying its half of NFR-3. **feature-007 owns AC-7
      and it closed in delivery-004**; this is the parity obligation feature-008 must not break,
      and interpreting a lens differently from the table is an explicit violation of NFR-3 and
      AC-7.
- [ ] **NFR-5** — node type and provenance are each conveyed by shape and/or label in addition to
      colour; colour is never the sole carrier of meaning.
- [ ] **NFR-6** — zoom and pan are both achievable through keyboard equivalents, with no action
      reserved for a mouse.
- [ ] **FR-6** — grouping by relation category (from delivery-001's vocabulary) regroups the graph
      accordingly; and **FR-2** — the density and zoom controls respond, with the graph remaining
      legible across the range at this project's node counts (A-5: hundreds, not tens of
      thousands).
- [ ] Whatever runtime prerequisites the renderer introduces — network fetches, companion assets,
      or a build output — are **declared to feature-007** so they appear in the documented
      prerequisites AC-6 requires, and the renderer's accessibility cost is carried by
      feature-009's peer view rather than left unmet. Because AC-6 closed in delivery-004, this is
      a re-check against the already-documented prerequisites, not a new statement.
- [ ] The implementation is the approach delivery-001 recommended, not a substitute chosen at
      build time; any divergence is raised rather than absorbed silently, because the decision
      record's licence, attribution, payload and update commitments were made against a named
      approach.
- [ ] If the recommendation adopted a third-party dependency, feature-012's packaging criterion
      from delivery-002 still holds against what actually shipped — private and unpublished,
      exactly pinned with a committed lockfile, covered by dependency monitoring, licence-recorded,
      and absent from both published wrapper manifests.
- [ ] The reused validators still behave as feature-011 parameterised them: `kb.html` keeps every
      check unchanged, and any exemption the live drawing surface needs (`validate-visuals.mjs`
      T2 for an SVG surface; `S2` under CDN packaging) is per-artifact and parameterised, never a
      weakening of the shared script.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/` reaches this repository's resolved `minimum_grade` of **A+**
      (`review.minimum_grade` in `.aid/settings.yml`; this work's `minimum_grade: "A+"`), i.e.
      zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001 (the rendering decision — the only feature feature-002 blocks),
  delivery-004 (the shell and the lens view-model feature-008 mounts into and consumes)
- **Blocks:** delivery-006

## Notes

- **Do not size this delivery before delivery-001 lands.** feature-008's SPEC says so explicitly:
  the feature *boundary* is stable either way, but the effort is uncertain until the
  recommendation is known. `/aid-detail` should break this delivery down after delivery-001, not
  before.
- **The renderer choice prices the accessibility work.** The research dossier's finding is that
  only SVG and the DOM produce accessibility-tree semantics for free, while Canvas and WebGL
  render into an opaque buffer and need a hand-built proxy layer. If delivery-001 recommended a
  Canvas or WebGL surface, the proxy cost lands partly here and partly on feature-009's already
  completed work in delivery-004 — which is a late-arriving cost this gate should look for.
- **`coverageGaps` and `coverageOrigin` arrive as `ViewModel` fields.** feature-008 never calls
  `coverage-predicate.mjs` directly; the shared predicate is reached only through feature-007's
  view-model. Density thinning must not hide a gap — the guarantee rests on the explicit
  `coverageGaps` exemption, not on any degree-based heuristic, because the shared predicate no
  longer reads `node.degree`.
