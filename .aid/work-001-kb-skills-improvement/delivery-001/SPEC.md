# Delivery SPEC -- delivery-001: Essence Core

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-001/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Deliver the 'Relative bus' capability end-to-end: the substrate that lets `/aid-discover` capture
a project's *essence* (its ubiquitous language and native concepts) instead of cataloging generic
structure, and certify that capture before exit. This delivery establishes the shared frontmatter
vocabulary (the `sources:` keystone primitive), the concern-derived KB document model, the
generation-time essence engine (mechanical coined-term harvest + non-lexical conceptual-synthesis
channel -> grounded concept spine -> bounded comprehension/closure loop), and the multi-mandate
review panel with teach-back closure as the keystone hard gate. It is scoped as one delivery
because these four features form one indivisible capability -- the harvest/spine/closure engine
(f004) consumes f001's `sources:` and f003's concern-model spine designation, and the panel (f005)
grades f004's output; none is independently shippable. After delivery-001, discovery captures
essence and the gate certifies it.

## Scope

In scope -- the four features that compose the essence engine:

- **feature-001 -- Frontmatter & `sources:` primitive.** The shared frontmatter schema
  (`objective`/`summary`/`sources`/`tags`/`see_also`/`owner`/`audience`/`approved_at_commit`), the
  `extract_list` parser helper in `build-kb-index.sh`, the deterministic `lint-frontmatter.sh`
  (soft-skip on day one), and the render plumbing carrying the fields to all 5 host trees.
- **feature-003 -- KB document model.** The canonical `concern-model.md` (the ~8 universal
  concerns + the concern->doc default mapping reframing the 15-doc seed byte-compatibly), the
  three-force boundary rule, expectations-as-open-questions, and the `aid-summarize` alignment.
- **feature-004 -- Essence-capture research engine.** The `harvest-coined-terms.sh` +
  `coined-term-denylist.txt`, the `closure-check.sh` single coverage oracle (3 outputs), the
  conceptual-synthesis channel, the concept-spine upgrade of `domain-glossary.md`, the bounded
  closure loop (`discovery.closure` settings + Step 5b cap-override interface), the can't-explain
  tripwire, and FR-32 human escalation.
- **feature-005 -- Review panel & rubric.** The five mandates (Correctness / Anatomy-Coverage /
  Concept-closure / Teach-back / Calibration) as a parallel panel aggregated to one ledger, the
  teach-back keystone hard gate (per-term + non-lexical engine-narration limbs), the Calibration
  rubric dimension, the `kb-teachback-questions.sh` helper, and the f005-owned injectable
  ledger-`<scope>` + doc-set seam (consumed later by delivery-007's `aid-update-kb`).

**Out of scope:** the INDEX routing-table render (delivery-002, f002); migrating AID's own KB onto
the new schema and flipping the lint hard (delivery-003, f011); recon triage + path scaling of the
panel/closure-loop (delivery-004, f006); the validation fixtures + threshold calibration
(delivery-005, f012); per-doc freshness (delivery-006, f007); the skill rename/add + propagation
(delivery-007, f008/f009); the housekeep<->update-kb boundary + standing closure (delivery-008,
f010); the greenfield branch (delivery-009).

## Gate Criteria

- [ ] Every KB doc can declare `objective:`/`summary:`/`tags:`/`see_also:`/`owner:`/`audience:`/`sources:`
  and the schema validates them; every doc declares `sources:`; the new fields are parsed, validated,
  and carried through the canonical->render generator with render-drift and KB-hygiene CI green. *(f001)*
- [ ] The doc set is derived from the universal concern set (not a project-type enumeration) and
  proposed->confirmed; each doc follows the summary+pointer model; audience/ownership informs
  boundaries; per-doc expectations are phrased as open questions; `aid-summarize` renders the concept
  spine, summary+pointer, and audience. *(f003)*
- [ ] The mechanical harvest scans all source types and emits a candidate-concept list
  (project-coined x recurring x cross-source); a grounded concept spine is built before the per-concern
  docs and shared with every researcher; a fresh agent with only the KB can answer "what is X?" for the
  native concepts AND narrate how the project works end-to-end (the closure/teach-back loop); any
  ungrounded project-specific term is a mandatory investigation; research reads all source types; the
  concept spine is persisted as a first-class KB doc the INDEX routes to; an ungroundable concept is
  escalated as a human Q&A. *(f004)*
- [ ] On a planted 'Relative bus'-style fixture the engine captures and defines the concept (the
  mechanical harvest half + closure self-containment). *(f004 mechanical half; full end-to-end is
  delivery-005)*
- [ ] The review panel applies all five mandates (invariant across paths, full panel as the default);
  teach-back closure is the keystone exit criterion (not severity distribution); calibration grades
  transcription/hollowness/coverage-vs-source against mechanically-generated evidence lists; the
  injectable ledger-`<scope>` + doc-set seam is exposed for downstream reuse. *(f005)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-002, delivery-003, delivery-004, delivery-005, delivery-006, delivery-007, delivery-008, delivery-009

## Notes

This is the foundation delivery. Several downstream features depend on contracts established here:
the `sources:` schema + `lint-frontmatter.sh` soft-skip (f001); the concern-model spine designation
(f003); f004's `closure-check.sh` 3-output oracle + `candidate-concepts.md` + `discovery.closure`
cap-override interface; and f005's full-panel default + injectable-scope seam. Provide-before-consume
sequencing is satisfied by landing all four together. Open SPIKEs (f001 SPIKE-1/3/4, f003 SPIKE-1/2/3,
f004 SPIKE-H1..H6, f005 SPIKE-C1..C5) are resolved during aid-specify/detail; the calibration-floor
SPIKEs (f004 H2, f005 C1) are pinned by delivery-005's fixtures (consume-after-define is preserved
because delivery-001 ships the *shape*, delivery-005 tunes the *floor*).
