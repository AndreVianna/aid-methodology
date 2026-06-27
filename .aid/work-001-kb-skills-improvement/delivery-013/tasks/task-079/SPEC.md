# task-079: Assert every matrix doc resolves a non-empty depth contract + DBI

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-079/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-013

**Depends on:** task-078

**Scope:**
- Prove feature-016 **Change 1 (FR-52)** closed the **36-doc dangling-anchor gap** and is
  byte-identity-clean. TEST only — no skill behavior changes here.
- **The closes-the-gap assertion (the core test):** assert that **every** doc the domain->doc-set
  matrix can emit (all 58 matrix-emittable filenames across software, data-ml, content, research,
  design, ops, methodology-tooling — incl. the shared `glossary.md`/`tooling-stack.md`) resolves to
  a **non-empty, work-actionable depth contract via its spine dimension** — i.e. each
  matrix-emittable doc maps to a dimension that has an authored standard, with **zero** docs left at
  a dangling `### <filename>` anchor (the 36 that dangle today are now covered). Extend
  `tests/canonical/test-domain-doc-matrix.sh` (or add a focused `tests/canonical/`
  expectations-coverage suite) per the lower-churn form; keep the suite small + per-concern (the
  split-big-TEST-tasks lesson).
- **Optional-refinement non-regression:** assert an existing `### <filename>` entry still resolves
  (layers on its dimension standard; does not break).
- **DBI / render-parity:** run the **canonical -> `.claude` render-parity** check (this delivery
  edits only `canonical/` skill/template sources, **not** AID's own `.aid/knowledge/*` doc content —
  the doc-content DBI sync is delivery-016's); confirm the full `run_generator.py` emission is clean
  (no render drift).
- ASCII-only + WinPS-5.1 lint applies only if a script changed; this task adds no shipped script.

**Acceptance Criteria:**
- [ ] A test asserts **every** matrix-emittable doc (all domains, incl. shared
  `glossary.md`/`tooling-stack.md`) resolves to a **non-empty depth contract via its spine
  dimension** — **zero** dangling `### <filename>` anchors, covering the **36** that dangle today.
  *(FR-52)*
- [ ] A non-regression check confirms existing per-filename `### <filename>` entries still resolve
  as optional additive refinements. *(FR-52)*
- [ ] **DBI green:** canonical -> `.claude` render-parity holds after the full `run_generator.py`
  regen; no render drift. *(section-6)*
- [ ] The affected canonical suites (matrix, the expectations/authoring-standard coverage suite)
  re-run green. *(section-6)*
- [ ] All section-6 quality gates pass.
