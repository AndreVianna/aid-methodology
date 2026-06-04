# task-006: Author the Objects/Models + API + UI recipe families (12 new)

**Type:** DOCUMENT

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-001

**Scope:**
- Author from the feature-003 SPEC Catalog Manifest + the fully-worked `add-api-endpoint` exemplar (which specify every slot/task/`summary:`/`applies-to:` authoritatively); **do not depend on the migrated files** — author each recipe fresh per the manifest. Each is a single flat `<name>.md` under `canonical/recipes/` with five-field front-matter (`name`, `applies-to`, `slot-count`, `task-count`, `summary`), a `## spec` block, and a `## tasks` block, conforming to the Recipe Authoring Contract.
- Author these **12 new** recipes (the in-place renames `change-member` and `add-api-endpoint` are task-005 and are NOT authored here):
  - **Objects / Models (3):** `add-member` (new-feature, 4 slots / 1 task), `add-interface` (new-feature, 4/1), `change-interface` (refactor, 5/1).
  - **API (3):** `change-api-endpoint` (refactor, 6/2), `add-api-middleware` (new-feature, 4/2), `change-api-middleware` (refactor, 5/1).
  - **UI (6):** `add-ui-endpoint` (new-feature, 5/2), `change-ui-endpoint` (refactor, 5/1), `add-ui-component` (new-feature, 5/2), `change-ui-component` (refactor, 5/1), `add-ui-style` (new-feature, 4/1), `change-ui-style` (refactor, 4/1).
- Front-matter slot/task counts MUST match the authored body; where a body genuinely needs a different count, adjust the front-matter to match (the two must agree). `summary:` is one-line and discriminative per recipe.

**Acceptance Criteria:**
- [ ] All 12 listed recipe files exist under `canonical/recipes/` with the exact names above; `name:` equals the basename in each.
- [ ] Each recipe carries five-field front-matter (incl. a one-line `summary:`), a `## spec` block (work-root schema), and a `## tasks` block with the stated number of `### task-NNN` headings.
- [ ] `bash canonical/scripts/interview/parse-recipe.sh --validate` prints `OK: all checks passed` with no `WARN` on each of the 12 recipes.
- [ ] No recipe in this task carries an old enum token (`small-new-feature`, `small-refactor`, `single-doc`).
- [ ] All §6 quality gates pass.
