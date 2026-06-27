# task-057: domain-doc-matrix.md artifact (schema + common-domain rows)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-057/STATE.md.

**Type:** DESIGN

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-056

**Scope:**
- Create `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` — a curated, structured
  data artifact mapping `domain -> [doc: filename | spine-dimension | owner | presence]`.
- Seed rows for the **common digital-work domains** (e.g. software-cli, software-web,
  data/ML, content, research, design, ops, methodology/tooling). Each row's docs are mapped
  to the task-056 spine dimensions.
- The software row's **required** docs **reproduce today's 15-doc seed exactly** (reuse the
  `synth_default_seed` ownership map), so existing behavior is preserved as one cached row;
  any new **conditional** dimension (e.g. Decisions -> `decisions.md`) is an **additive
  conditional entry**, NOT part of the byte-stable seed.
- Document the **provenance** field (`curated` vs `auto-researched`) and the **hybrid
  composition rule** (union of relevant domain rows over the single spine; dedupe by
  dimension; never exclusive buckets).

**Acceptance Criteria:**
- [ ] `domain-doc-matrix.md` exists with a documented schema and rows for the common domains. *(FR-39)*
- [ ] The software row's **required** docs reproduce the 15-doc seed exactly (each ->
  spine-dimension + owner + presence; byte-consistent with `synth_default_seed`); conditional
  dimensions are **additive** entries, not part of the byte-stable seed. *(FR-39)*
- [ ] Provenance field + hybrid composition rule documented. *(FR-39, FR-40)*
- [ ] All section-6 quality gates pass.
