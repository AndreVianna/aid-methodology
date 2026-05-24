# task-013: Extend `work-state-template.md` with `## Triage` + `data-model.md §2.3`

**Type:** CONFIGURE

**Source:** feature-005-lite-path → delivery-002

**Depends on:** —

**Scope:**
- Add a `## Triage` section to `canonical/templates/work-state-template.md` after the metadata block.
- Schema (bullet-list fields): Path, Work Type, Sub-path, Sub-path (auto), Decision rationale, Override, Recipe.
- Update `.aid/knowledge/data-model.md §2.3 Work-area STATE.md schema` to list the new `## Triage` section.
- Section is empty for full-path works (only populated for lite-path).

**Acceptance Criteria:**
- [ ] `canonical/templates/work-state-template.md` contains a `## Triage` section with the 7 schema fields.
- [ ] `.aid/knowledge/data-model.md §2.3` lists `## Triage` among the work STATE.md sections.
- [ ] Generator re-renders the template into all 3 install trees byte-identically.
- [ ] Existing instances of work-area `STATE.md` continue to validate (additive change; no breakage).
- [ ] Configuration is idempotent (re-running the change is a no-op).
- [ ] All §6 quality gates pass.
