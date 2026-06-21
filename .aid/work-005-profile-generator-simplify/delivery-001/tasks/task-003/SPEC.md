# task-003: canonical/aid/ reshape

**Type:** REFACTOR

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-002

**Scope:**
- Pre-nest `canonical/{scripts,templates,recipes}/` under a new `canonical/aid/` directory so the AID-own trees live at `canonical/aid/{scripts,templates,recipes}/` (feature-002 A4 — the new home for the AID-own trees so the copy is a literal `canonical/aid/ → {root}/aid/` mirror with zero path computation).
- **Structural move only** — no content change to any moved file.
- Re-point existing generator references (in `.claude/skills/generate-profile/scripts/*` — e.g. `render_templates.py`, `render_recipes.py`, `render_canonical_scripts.py`, and any path constants in `render_lib.py`/`aid_profile.py`/`run_generator.py`) to the new nested `canonical/aid/...` paths so the **current** renderer still emits **byte-identical** `profiles/*` output (render-drift clean).
- **Boundary:** this task only relocates `canonical/scripts|templates|recipes/` and re-points path references; it does NOT collapse the generator, delete format branches, build `render.py`, or change emitted content. The copy-generator build is task-005; the re-render is task-006.

**Acceptance Criteria:**
- [ ] `canonical/aid/{scripts,templates,recipes}` exists and contains the relocated trees (no copies left at the old `canonical/{scripts,templates,recipes}/` locations).
- [ ] No moved file's content is edited — the move is purely structural (byte-identical file contents at the new paths).
- [ ] The current generator re-points to the nested paths and re-renders `profiles/*` byte-identically (render-drift: `git diff --exit-code -- profiles/` is clean).
- [ ] REFACTOR defaults: all tests pass before AND after the move; no behavior change (output trees unchanged).
- [ ] All §6 quality gates pass.
