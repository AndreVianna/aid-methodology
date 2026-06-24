# task-059: Matrix-or-research doc-set flow (rewire Step 0d) + matrix lifecycle

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-059/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-057, task-058

**Scope:**
- Rewire the doc-set proposal in
  `canonical/skills/aid-discover/references/state-generate.md` (today's Step 0d "default seed
  + deltas") to: **matrix-lookup** (read `domain-doc-matrix.md` for the confirmed domain) ->
  **research-fallback on miss** (a domain-documentation research sub-step that synthesizes a
  doc-set) -> **propose** (diff vs the spine defaults) -> **confirm** (user). Anchor every set
  to the spine; **compose** hybrids per the matrix rule.
- **Matrix lifecycle:** persist the confirmed set to `.aid/settings.yml -> discovery.doc_set`
  (existing mechanism); optionally **emit** `.aid/generated/domain-doc-candidate.md` (proposed
  row + provenance) for manual upstream PR. There MUST be **no automatic install->canonical
  feedback**.
- **Retain `synth_default_seed`** as the matrix's software-row generator (no byte change);
  keep `resolve_doc_set` + the 4 accessors generic (update references in `doc-set-resolve.md`
  only as needed).

**Acceptance Criteria:**
- [ ] Step 0d resolves the doc-set via **matrix hit OR research fallback**, anchored to the
  spine, composable, **proposed->confirmed**. *(FR-39)*
- [ ] The confirmed set **persists locally**; an optional **candidate artifact** may be
  emitted; **no automatic install->canonical path** exists. *(FR-40)*
- [ ] `synth_default_seed` is **byte-stable** (existing `test-doc-set-read.sh` passes). *(FR-39)*
- [ ] Any shipped script ASCII-only. All section-6 quality gates pass.
