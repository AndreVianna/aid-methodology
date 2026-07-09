# task-007: shortcut-catalog.yml schema + field contract

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Create `canonical/aid/templates/shortcut-catalog.yml` (single-source manifest): `version: 1` + a `shortcuts:` list, with the documented row field contract -- `name` (required, `aid-` prefixed, == skill directory), `verb`, `artifact` (may be `""`), `alias_of` (null for canonical; the mirrored canonical name for aliases), `default_type` (closed 8-enum: RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE), `group`, `intent`, `repurpose` (optional, default false; true only for the fat pipeline skills aid-deploy/aid-monitor).
- Seed the file with the header + schema/comment contract only; family rows are added by their family tasks (the `aid-fix` row is added by task-013).
- The file renders as verbatim bytes (`.yml` is not in `render.py` `_TEXT_EXTENSIONS`) to `<root>/aid/templates/shortcut-catalog.yml` in all 5 profiles.

**Acceptance Criteria:**
- [ ] `shortcut-catalog.yml` exists with `version` + `shortcuts` and the documented field schema (incl. the `repurpose` field contract).
- [ ] Copied verbatim (byte-identical) to all 5 profiles via `run_generator.py`; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass.
- [ ] All §6 quality gates pass.
