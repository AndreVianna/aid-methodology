# task-056: Generic-core dimension spine + standards-grounded concern-model generalization

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-056/STATE.md.

**Type:** DESIGN

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** -- (none intra-delivery; builds on delivery-001 f003/f004 base)

**Scope:**
- Generalize `canonical/aid/templates/kb-authoring/concern-model.md` to define a
  **domain-agnostic dimension spine** (the universal questions any digital deliverable must
  answer about itself), with the existing **C0-C9 concern list documented as its software
  rendering**.
- Add **standards citations** (arc42, C4, IEEE 1016, ISO/IEC/IEEE 42010, ADR) mapping each
  spine dimension to the standards that attest it.
- Add a **"Why product-concerns, not governance-artifacts"** note: PMBOK/PRINCE2/Scrum
  artifacts are the governance layer -> AID pipeline artifacts (REQUIREMENTS/SPEC/PLAN/
  tracking), NOT the KB.
- **Resolve the Decisions-concern decision** (delivery-010 STATE Q2): promote **Decisions**
  (arc42 §9 / ADR / ISO 42010) to an 11th spine dimension **realized as a CONDITIONAL doc**
  (`decisions.md` / ADR-log) -- so the byte-stable software **seed** (the 15 docs) stays
  **unchanged** and FR-37's covered-or-conditional holds -- unless the user/gate declines;
  record the decision. **If promoted, update `concern-model.md`'s T2 cardinality contract in
  lockstep** (the "exactly 10" / "## The 10 universal concerns" wording -> 11; the
  seed-coverage check notes Decisions is **conditional**, not one of the 15 seed docs) so the
  doc is not self-contradictory.
- Keep the **T2 cardinality contract** coherent: the spine is fixed; per-project adaptivity
  is in *doc realization*, not the dimension list.

**Acceptance Criteria:**
- [ ] `concern-model.md` presents the domain-agnostic spine + a software-rendering mapping
  table with **standards citations**. *(FR-37)*
- [ ] The governance->pipeline boundary is documented (PM frameworks are not KB docs). *(FR-37)*
- [ ] The Decisions-concern decision is recorded and applied; **if promoted, the T2
  cardinality contract is updated in lockstep** (10->11 wording + the "## The 10 universal
  concerns" heading + the seed-coverage note that Decisions is conditional, not a seed doc) so
  `concern-model.md` is internally consistent, and the byte-stable 15-doc software seed is
  unchanged. *(FR-37; reconciles delivery-010 Q2)*
- [ ] No change to the doc-set TSV machine shape (concern stays documentation-only, three
  fields: `filename<TAB>owner<TAB>presence`).
- [ ] All section-6 quality gates pass.
