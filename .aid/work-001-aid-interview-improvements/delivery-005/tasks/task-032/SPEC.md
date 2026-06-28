# task-032: Full generator render + 5-profile/.claude propagation + DBI

**Type:** CONFIGURE

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** task-028, task-029, task-030, task-031, task-035

**Scope:**
- After ALL delivery-005 canonical edits are merged -- the extraction edits under
  `canonical/skills/aid-discover/references/` (`agent-prompts.md` + `state-generate.md`, the `output_root`
  parameter, task-028) and the aid-housekeep conformance-lane edits under
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` (the carve task-029 + the extract-and-diff
  sub-step task-030 + the reconciliation flow task-031) -- run the FULL generator ONCE to propagate them to
  the host trees and keep the build green. This is the single consolidated render for the delivery (not
  per-task).
- Run `python .claude/skills/generate-profile/scripts/run_generator.py` (the FULL generator, NOT per-script
  renderers -- per the render-drift lesson) so the 5 profile copies AND the `.claude/` dogfood mirror are
  regenerated and the emission manifests are updated. The edited files are existing tracked references (no
  NEW reference file is introduced by delivery-005), so no new emission-manifest registration is expected;
  confirm the generator picks up the edits.
- Verify render-drift CI stays clean (re-running the generator yields NO diff -- idempotent/deterministic)
  and DBI byte-identity holds across the profile copies + the `.claude/` mirror.
- ASCII-only preserved through the render; no plaintext secrets introduced.
- **Out of scope:** authoring/altering any canonical CONTENT (tasks 028-031 own that -- this task only
  propagates); the verification runs (task-033/034).

**Acceptance Criteria:**
- [ ] FULL `run_generator.py` executed: the 5 profile copies + the `.claude/` mirror reflect all delivery-005 canonical edits (the `output_root` parameter in `agent-prompts.md` + `state-generate.md`; the carve + conformance sub-step + reconciliation flow in `state-kb-delta.md`); emission manifests updated. *(gate criterion 5)*
- [ ] Render is idempotent/deterministic -- re-running the generator produces NO diff (render-drift CI clean). *(CONFIGURE idempotent default)*
- [ ] DBI byte-identity holds across the profile copies and the `.claude/` mirror. *(DBI gate)*
- [ ] Configuration is idempotent; no plaintext secrets; shipped content stays ASCII-only through the render. *(CONFIGURE defaults)*
- [ ] All REQUIREMENTS.md §6 quality gates pass (master-only heavy gates exercised at task-034).
