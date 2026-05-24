# task-025: Author `recipe-template.md` meta-template + `canonical/recipes/README.md`

**Type:** DOCUMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** —

**Scope:**
- Create `canonical/templates/recipe-template.md` (the meta-template recipe authors copy).
- Meta-template contents: YAML front-matter (name/applies-to/slot-count/task-count), body with `## spec` + `## tasks` blocks, slot syntax (`{{slot-name}}`) and escape syntax (`{!{` for literal `{{`).
- Include inline documentation explaining each field, slot-name lexical rule (`[a-z][a-z0-9-]*`), and the `## spec` lowercase rationale.
- Create `canonical/recipes/README.md` documenting: catalog purpose, recipe shape, the seed catalog (5 recipes), how to author a new recipe, soft conventions (e.g., reserve `applies-to: *` for genuinely cross-type patterns).

**Acceptance Criteria:**
- [ ] `canonical/templates/recipe-template.md` exists with the documented schema.
- [ ] Meta-template includes example slot tokens AND an example of the `{!{` escape.
- [ ] `canonical/recipes/README.md` exists with documented catalog conventions.
- [ ] Both files validate against the feature-011 SPEC's Data Model schema (manual cross-check noted in commit).
- [ ] Documentation accuracy verified by spot-reading: every YAML field claim and every slot-syntax claim traces to the SPEC.
- [ ] All §6 quality gates pass.
