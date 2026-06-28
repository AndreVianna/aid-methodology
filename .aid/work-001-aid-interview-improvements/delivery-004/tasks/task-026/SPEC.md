# task-026: Full generator render + 5-profile/.claude propagation + DBI

**Type:** CONFIGURE

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** task-019, task-020, task-022, task-023, task-024, task-025

**Scope:**
- After ALL delivery-004 canonical edits are merged -- the marker edits under `canonical/aid/`
  (`kb-freshness-check.sh` task-019; `frontmatter-schema.md` + `lint-frontmatter.sh` + `build-kb-index.sh`
  task-020), the review-subsystem edits under `canonical/skills/aid-discover/references/`
  (`document-expectations.md` task-022; `reviewer-brief.md` + `state-review.md` task-023), and the
  aid-interview edits (`coherence-check.md` task-024; the seed-authoring state + spine wiring task-025) --
  run the FULL generator ONCE to propagate them to the host trees and keep the build green. This is the
  single consolidated render for the delivery (not per-task).
- Run `python .claude/skills/generate-profile/scripts/run_generator.py` (the FULL generator, NOT
  per-script renderers -- per the render-drift lesson) so the 5 profile copies AND the `.claude/` dogfood
  mirror are regenerated and the emission manifests are updated.
- If a NEW reference file requires emission-manifest / `EMISSION-MANIFEST.md` registration for the
  generator to pick it up (the new `coherence-check.md` and the new seed-authoring state doc under
  `aid-interview`), add it. The marker scripts/templates under `canonical/aid/` are existing tracked files.
- Verify render-drift CI stays clean (re-running the generator yields NO diff -- idempotent/deterministic)
  and DBI byte-identity holds across the profile copies + the `.claude/` mirror.
- ASCII-only preserved through the render; no plaintext secrets introduced.
- **Out of scope:** authoring/altering any canonical CONTENT (tasks 019-025 own that -- this task only
  propagates); the verification run (task-027).

**Acceptance Criteria:**
- [ ] FULL `run_generator.py` executed: the 5 profile copies + the `.claude/` mirror reflect all delivery-004 canonical edits (marker scripts/schema, review-subsystem docs, coherence-check doc, seed-authoring state + spine wiring); emission manifests updated and any new reference files registered. *(gate criterion 5)*
- [ ] Render is idempotent/deterministic -- re-running the generator produces NO diff (render-drift CI clean). *(CONFIGURE idempotent default)*
- [ ] DBI byte-identity holds across the profile copies and the `.claude/` mirror. *(DBI gate)*
- [ ] Configuration is idempotent; no plaintext secrets; shipped content stays ASCII-only through the render. *(CONFIGURE defaults)*
- [ ] All REQUIREMENTS.md §6 quality gates pass (master-only heavy gates exercised at task-027).
