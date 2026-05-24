# task-024: Work-002 back-port for recipes asset kind

**Type:** IMPLEMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** —

**Scope:**
- Coordinated change-set against work-002's `feature-001-profile-driven-generator`, attributed to FR8 implementation.
- Add `recipe` asset-kind to work-002's renderer registry. Passthrough renderer (recipes are plain Markdown).
- Add `recipes` kind entry to each profile's `layout` field (claude-code, codex, cursor).
- Extend `canonical/EMISSION-MANIFEST.md` to own paths under `recipes/`.
- Re-run work-002 generator to render the three install trees with `recipes/`.
- Commit the regenerated `EMISSION-MANIFEST.md` alongside the rendered trees (safety-boundary requirement).
- Record a Lifecycle History row in work-002's `STATE.md` documenting this back-port (attribute to work-001 FR8).

**Acceptance Criteria:**
- [ ] work-002 generator renders `canonical/recipes/` into each profile's install tree.
- [ ] `canonical/EMISSION-MANIFEST.md` owns all `recipes/` paths (verifiable by `grep` after generator run).
- [ ] Re-running the generator is idempotent (no spurious diff).
- [ ] Adding a new recipe file to `canonical/recipes/` + re-running generator produces the rendered copy in all 3 trees without manifest manipulation.
- [ ] Removing a recipe + re-running generator deletes the copy from all 3 trees (mirror-deletion safety).
- [ ] work-002 `STATE.md` Lifecycle History row added.
- [ ] All §6 quality gates pass.
