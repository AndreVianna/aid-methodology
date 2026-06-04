# task-009: Author the bug-fix (6) + refactor-only (3) recipe families (9 new)

**Type:** DOCUMENT

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-001

**Scope:**
- Author from the feature-003 SPEC Catalog Manifest + the fully-worked `add-api-endpoint` exemplar (which specify every slot/task/`summary:`/`applies-to:` authoritatively); **do not depend on the migrated files** — author each recipe fresh per the manifest. Each is a single flat `<name>.md` under `canonical/recipes/` with five-field front-matter (`name`, `applies-to`, `slot-count`, `task-count`, `summary`), a `## spec` block, and a `## tasks` block, conforming to the Recipe Authoring Contract.
- Author these **9 new** recipes (`fix-application` is migrated by task-005 and is NOT authored here):
  - **bug-fix (6), `applies-to: bug-fix`:** `fix-infrastructure` (4 slots / 1 task), `fix-api` (4/1), `fix-ui` (4/1), `fix-integration` (4/1), `fix-regression` (5/1), `fix-security` (5/1).
  - **refactor-only (3), `applies-to: refactor`:** `improve-performance` (5/2), `bump-dependency` (4/2), `rename-symbol` (4/1).
- Front-matter slot/task counts MUST match the authored body; where a body genuinely needs a different count, adjust the front-matter to match (the two must agree). `summary:` is one-line and discriminative per recipe.

**Acceptance Criteria:**
- [ ] All 9 listed recipe files exist under `canonical/recipes/` with the exact names above; `name:` equals the basename in each.
- [ ] Each recipe carries five-field front-matter (incl. a one-line `summary:`), a `## spec` block (work-root schema), and a `## tasks` block with the stated number of `### task-NNN` headings.
- [ ] The 6 `fix-*` recipes carry `applies-to: bug-fix`; the 3 refactor-only recipes carry `applies-to: refactor`.
- [ ] `bash canonical/scripts/interview/parse-recipe.sh --validate` prints `OK: all checks passed` with no `WARN` on each of the 9 recipes.
- [ ] All §6 quality gates pass.
