# task-008: Author the event/queue/message + rule + docs + integration recipe families (12 new)

**Type:** DOCUMENT

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-001

**Scope:**
- Author from the feature-003 SPEC Catalog Manifest + the fully-worked `add-api-endpoint` exemplar (which specify every slot/task/`summary:`/`applies-to:` authoritatively); **do not depend on the migrated files** — author each recipe fresh per the manifest. Each is a single flat `<name>.md` under `canonical/recipes/` with five-field front-matter (`name`, `applies-to`, `slot-count`, `task-count`, `summary`), a `## spec` block, and a `## tasks` block, conforming to the Recipe Authoring Contract.
- Author these **12 new** recipes (`add-docs`/`add-report` are migrated by task-005 and are NOT authored here; their `change-` partners ARE authored here):
  - **event handler / consumer (6):** `add-event-handler` (new-feature, 5 slots / 2 tasks), `change-event-handler` (refactor, 5/1), `add-queue` (new-feature, 4/2), `change-queue` (refactor, 5/1), `add-message` (new-feature, 4/1), `change-message` (refactor, 5/1).
  - **validation / business rule (2):** `add-rule` (new-feature, 4/1), `change-rule` (refactor, 5/1).
  - **documentation / report (2):** `change-docs` (refactor, 4/1), `change-report` (refactor, 4/1).
  - **integration / external client (2):** `add-integration` (new-feature, 5/2), `change-integration` (refactor, 5/1).
- Note: with task-005's `add-docs`/`add-report`, the documentation/report family reaches its full 4 recipes; this task authors only the two `change-` partners.
- Front-matter slot/task counts MUST match the authored body; where a body genuinely needs a different count, adjust the front-matter to match (the two must agree). `summary:` is one-line and discriminative per recipe.

**Acceptance Criteria:**
- [ ] All 12 listed recipe files exist under `canonical/recipes/` with the exact names above; `name:` equals the basename in each.
- [ ] Each recipe carries five-field front-matter (incl. a one-line `summary:`), a `## spec` block (work-root schema), and a `## tasks` block with the stated number of `### task-NNN` headings.
- [ ] `bash canonical/scripts/interview/parse-recipe.sh --validate` prints `OK: all checks passed` with no `WARN` on each of the 12 recipes.
- [ ] No recipe in this task carries an old enum token (`small-new-feature`, `small-refactor`, `single-doc`).
- [ ] All §6 quality gates pass.
