# task-017: Full generator render + 5-profile/.claude propagation

**Type:** CONFIGURE

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-016

**Scope:**
- After all canonical content edits from tasks 010-016 are merged (4 new `references/*.md` engine docs
  + the in-place spine/triage/continue edits in `canonical/skills/aid-interview/`), run the FULL
  generator to propagate them to the host trees and keep the build green. This is the single
  consolidated render for the delivery (one render after all edits, not per-task).
- Run `python .claude/skills/generate-profile/scripts/run_generator.py` (the FULL generator, NOT
  per-script renderers -- per the render-drift lesson) so the 5 profile copies
  (`profiles/*/.../skills/aid-interview/`) AND the `.claude/` dogfood mirror are regenerated and the
  emission manifests are updated.
- Verify render-drift CI stays clean (re-running the generator yields no diff -- the render is
  idempotent / deterministic) and DBI byte-identity holds across the profile copies + mirror.
- If a new `references/*.md` file requires an emission-manifest / `EMISSION-MANIFEST.md` registration
  for the generator to pick it up, add it (the 4 new engine docs are additive files under the
  aid-interview skill dir).
- ASCII-only is preserved through the render (no non-ASCII introduced into shipped skill content).
- **Out of scope:** authoring/altering any skill CONTENT (tasks 010-016 own that -- this task only
  propagates); the verification run (task-018).

**Acceptance Criteria:**
- [ ] FULL `run_generator.py` executed: the 5 `profiles/*/.../skills/aid-interview/` copies + the `.claude/` mirror reflect the 4 new engine reference docs and all in-place edits from tasks 010-016; emission manifests updated. *(gate criterion 6)*
- [ ] Render-drift CI is clean -- re-running the generator produces NO diff (render is idempotent / deterministic). *(CONFIGURE idempotent default)*
- [ ] DBI byte-identity holds across the profile copies and the `.claude/` mirror. *(DBI gate)*
- [ ] No plaintext secrets introduced; shipped skill content stays ASCII-only through the render. *(CONFIGURE no-secrets default)*
- [ ] All REQUIREMENTS.md §6 quality gates pass (incl. the master-only heavy gates exercised at task-018).
