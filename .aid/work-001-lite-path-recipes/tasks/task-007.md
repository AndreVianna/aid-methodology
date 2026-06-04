# task-007: Author the CLI + DB/Storage + config/feature-flag + job recipe families (12 new)

**Type:** DOCUMENT

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-001

**Scope:**
- Author from the feature-003 SPEC Catalog Manifest + the fully-worked `add-api-endpoint` exemplar (which specify every slot/task/`summary:`/`applies-to:` authoritatively); **do not depend on the migrated files** — author each recipe fresh per the manifest. Each is a single flat `<name>.md` under `canonical/recipes/` with five-field front-matter (`name`, `applies-to`, `slot-count`, `task-count`, `summary`), a `## spec` block, and a `## tasks` block, conforming to the Recipe Authoring Contract.
- Author these **12 new** recipes:
  - **CLI command (2):** `add-cli-command` (new-feature, 5 slots / 2 tasks), `change-cli-command` (refactor, 5/1).
  - **DB / Storage (4):** `add-entity` (new-feature, 5/2), `change-schema` (refactor, 5/2), `add-container` (new-feature, 4/1), `change-container` (refactor, 5/1).
  - **config / feature flag (4):** `add-config-option` (new-feature, 4/1), `change-config-option` (refactor, 5/1), `add-feature-flag` (new-feature, 4/1), `change-feature-flag` (refactor, 4/1).
  - **job (2):** `add-job` (new-feature, 5/2), `change-job` (refactor, 5/1).
- Front-matter slot/task counts MUST match the authored body; where a body genuinely needs a different count, adjust the front-matter to match (the two must agree). `summary:` is one-line and discriminative per recipe.

**Acceptance Criteria:**
- [ ] All 12 listed recipe files exist under `canonical/recipes/` with the exact names above; `name:` equals the basename in each.
- [ ] Each recipe carries five-field front-matter (incl. a one-line `summary:`), a `## spec` block (work-root schema), and a `## tasks` block with the stated number of `### task-NNN` headings.
- [ ] `bash canonical/scripts/interview/parse-recipe.sh --validate` prints `OK: all checks passed` with no `WARN` on each of the 12 recipes.
- [ ] No recipe in this task carries an old enum token (`small-new-feature`, `small-refactor`, `single-doc`).
- [ ] All §6 quality gates pass.
